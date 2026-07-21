import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { z } from "zod";

function repairJson(raw: string, fields: string[]): Record<string, string> | null {
  // Stage 1: direct parse
  try {
    return JSON.parse(raw);
  } catch {
    // continue
  }

  // Stage 2: strip markdown code fences (```json ... ```)
  const stripped = raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();
  try {
    return JSON.parse(stripped);
  } catch {
    // continue
  }

  // Stage 3: extract first {...} block
  const match = stripped.match(/\{[\s\S]*\}/);
  if (match) {
    try {
      return JSON.parse(match[0]);
    } catch {
      // continue
    }
  }

  // Stage 4: field-by-field regex extraction (last resort)
  const out: Record<string, string> = {};
  let any = false;
  for (const field of fields) {
    const re = new RegExp(
      `"${field}"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"`,
      "s",
    );
    const m = stripped.match(re);
    const value = m ? m[1].replace(/\\n/g, "\n").replace(/\\"/g, '"') : "";
    out[field] = value;
    if (value) any = true;
  }
  return any ? out : null;
}

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const APP_URL = process.env.NEXT_PUBLIC_APP_URL || "https://hvacpro.vn";

// Model ID format: "provider/model-name" or "provider/model-name:variant"
// Accepts any valid OpenRouter model slug — no whitelist enforced.
const MODEL_ID_SCHEMA = z
  .string()
  .trim()
  .min(3, "Model ID quá ngắn.")
  .max(100, "Model ID quá dài.")
  .regex(
    /^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.:-]+$/,
    "Model ID không đúng định dạng."
  );

const LANGUAGE_NAMES: Record<string, string> = {
  en: "Tiếng Anh (English)",
  ko: "Tiếng Hàn Quốc (Korean)",
  ja: "Tiếng Nhật Bản (Japanese)",
  zh: "Tiếng Trung Quốc (Chinese)",
  km: "Tiếng Campuchia/Khmer (Khmer)",
  lo: "Tiếng Lào (Lao)",
  hi: "Tiếng Hindi (Hindi - हिन्दी). Bạn bắt buộc phải dịch sang chữ viết Devanagari chính thức của tiếng Hindi (không dùng bảng chữ cái Latinh hay tiếng Anh).",
  es: "Tiếng Tây Ban Nha (Spanish)",
  fr: "Tiếng Pháp (French)",
  de: "Tiếng Đức (German)",
};

// Request validation schema
const requestBodySchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Tiêu đề không được trống")
    .max(200, "Tiêu đề quá dài (Tối đa 200 ký tự)"),
  causes: z.string().optional().default(""),
  steps: z.string().optional().default(""),
  notes: z.string().optional().default(""),
  aiModel: MODEL_ID_SCHEMA.optional(),
  targetLang: z.enum(["en", "ko", "ja", "zh", "km", "lo", "hi", "es", "fr", "de"]),
});

export async function POST(req: Request) {
  // Fail fast on missing API key configuration
  if (!OPENROUTER_API_KEY) {
    return NextResponse.json(
      { error: "OpenRouter configuration is missing on server." },
      { status: 500 }
    );
  }

  try {
    // 1. Authenticate & Authorize request using requireAdmin
    try {
      await requireAdmin(req);
    } catch (authError: any) {
      return NextResponse.json(
        { error: authError.message || "Unauthorized access." },
        { status: authError.status || 401 }
      );
    }

    // 2. Parse and Validate input payload
    const body = await req.json().catch(() => null);
    const parsed = requestBodySchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Dữ liệu đầu vào không hợp lệ.", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { title, causes, steps, notes, aiModel, targetLang } = parsed.data;

    // 3. Resolve model choice — env fallback validated by slug format
    let modelFallback = "google/gemini-2.5-flash";
    const envModel = process.env.OPENROUTER_MODEL;
    if (envModel) {
      if (!MODEL_ID_SCHEMA.safeParse(envModel).success) {
        return NextResponse.json(
          { error: "Server model configuration is invalid." },
          { status: 500 }
        );
      }
      modelFallback = envModel;
    }
    const model = aiModel || modelFallback;

    const targetLangName = LANGUAGE_NAMES[targetLang];
    const systemPrompt = `Bạn là một chuyên gia dịch thuật kỹ thuật chuyên nghiệp trong lĩnh vực Cơ điện lạnh (HVAC) và Thiết bị gia dụng. Hãy dịch tiêu đề và các phần nội dung bài viết sang ngôn ngữ: ${targetLangName}.
    
Yêu cầu BẮT BUỘC về ngôn ngữ và kỹ thuật:
1. Sử dụng thuật ngữ chuyên ngành kỹ thuật chính xác, tự nhiên và chuẩn công nghiệp của quốc gia bản địa (ví dụ các bộ phận như: máy nén, board mạch Inverter, cảm biến nhiệt độ NTC, van tiết lưu, dàn nóng, dàn lạnh, môi chất lạnh phải được dịch sang từ chuyên ngành kỹ thuật tương ứng, KHÔNG DỊCH WORD-BY-WORD theo nghĩa thông thường).
2. Văn phong mang tính chất hướng dẫn xử lý kỹ thuật rõ ràng, ngắn gọn và thực tế cho thợ sửa chữa. Giữ nguyên các ký hiệu kỹ thuật viết tắt quốc tế phổ biến (ví dụ: PCB, MCU, AC/DC, NTC, EPROM) và các mã lỗi (ví dụ: E1, H11, F9).
3. Giữ nguyên toàn bộ cấu trúc các thẻ HTML và các thẻ Markdown chèn ảnh/tài liệu đặc biệt như: ![img](url) hoặc [pdf](url) trong các mục nội dung.
4. CHỈ TRẢ VỀ JSON HỢP LỆ, KHÔNG CHỨA TEXT NÀO KHÁC BÊN NGOÀI JSON. Cấu trúc JSON phải khớp với schema được cung cấp.
5. Tuyệt đối KHÔNG tự ý chèn thêm ngày, tháng, năm hoặc thông tin thời gian vào tiêu đề bài viết.`;

    const userPrompt = `Tiêu đề (Tiếng Việt):
${title}

Nguyên nhân (Tiếng Việt):
${causes}

Hướng dẫn khắc phục (Tiếng Việt):
${steps}

Lưu ý kỹ thuật (Tiếng Việt):
${notes}`;

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": APP_URL,
        "X-OpenRouter-Title": "HVAC Pro Admin Translation"
      },
      body: JSON.stringify({
        model: model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "hvac_translation_schema",
            strict: true,
            schema: {
              type: "object",
              properties: {
                title: { 
                  type: "string",
                  description: "Tiêu đề bài viết đã được dịch thuật chính xác."
                },
                causes: { 
                  type: "string",
                  description: "Danh sách nguyên nhân lỗi đã được dịch thuật chính xác."
                },
                steps: { 
                  type: "string",
                  description: "Hướng dẫn các bước khắc phục mã lỗi đã được dịch thuật chính xác."
                },
                notes: { 
                  type: "string",
                  description: "Lưu ý an toàn kỹ thuật và kinh nghiệm thực tế đã được dịch thuật chính xác."
                }
              },
              required: ["title", "causes", "steps", "notes"],
              additionalProperties: false
            }
          }
        },
        provider: {
          require_parameters: true
        },
        max_tokens: 3000
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error(`OpenRouter API Error during translation to ${targetLangName}:`, errorData);
      return NextResponse.json(
        { error: `Translation API service failed for ${targetLangName}.` },
        { status: response.status }
      );
    }

    const data = await response.json();
    const resultText = data.choices?.[0]?.message?.content?.trim();

    if (!resultText) {
      return NextResponse.json(
        { error: "AI returned an empty response during translation." },
        { status: 500 }
      );
    }

    // --- Multi-stage JSON repair pipeline ---
    const translatedContent = repairJson(resultText, ["title", "causes", "steps", "notes"]);
    if (translatedContent) {
      return NextResponse.json(translatedContent);
    }

    console.error("AI response JSON repair failed. Raw content:", resultText);
    return NextResponse.json(
      { error: "Failed to parse structured translation content from AI. Try a different model." },
      { status: 500 }
    );
  } catch (error) {
    console.error("Error in translation route:", error);
    return NextResponse.json(
      { error: "Internal server error occurred during content translation." },
      { status: 500 }
    );
  }
}
