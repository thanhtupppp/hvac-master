import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { z } from "zod";

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

// Request Schema Validation with Zod
const requestBodySchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, "Tiêu đề bài viết không được trống")
    .max(200, "Tiêu đề quá dài (Tối đa 200 ký tự)"),
  section: z.enum(["all", "causes", "steps", "notes"]),
  aiModel: MODEL_ID_SCHEMA.optional(),
});

export async function POST(req: Request) {
  // Fail fast on missing API key configuration
  if (!OPENROUTER_API_KEY) {
    return NextResponse.json(
      { error: "OpenRouter configuration is missing on server." },
      { status: 500 },
    );
  }

  try {
    // 1. Authenticate & Authorize request using requireAdmin
    try {
      await requireAdmin(req);
    } catch (authError: any) {
      return NextResponse.json(
        { error: authError.message || "Unauthorized access." },
        { status: authError.status || 401 },
      );
    }

    // 2. Parse and Validate input payload
    const body = await req.json().catch(() => null);
    const parsed = requestBodySchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        {
          error: "Dữ liệu đầu vào không hợp lệ.",
          details: parsed.error.format(),
        },
        { status: 400 },
      );
    }

    const { title, section, aiModel } = parsed.data;

    // 3. Resolve model choice — env fallback validated by slug format
    let modelFallback = "google/gemini-2.5-flash";
    const envModel = process.env.OPENROUTER_MODEL;
    if (envModel) {
      if (!MODEL_ID_SCHEMA.safeParse(envModel).success) {
        return NextResponse.json(
          { error: "Server model configuration is invalid." },
          { status: 500 },
        );
      }
      modelFallback = envModel;
    }
    const model = aiModel || modelFallback;

    // 4. Build Prompts
    const systemPrompt = `Bạn là một kỹ sư cơ điện lạnh (HVAC) kiêm thợ sửa chữa thiết bị gia dụng gạo cội với hơn 20 năm kinh nghiệm xử lý lỗi thực tế. 
Nhiệm vụ của bạn là hỗ trợ viết tài liệu hướng dẫn kỹ thuật chất lượng cao cho bài viết có tiêu đề: "${title}".

Dựa vào mục yêu cầu "section", hãy viết nội dung tương ứng theo phong cách chuyên nghiệp, thực tế, sử dụng đúng thuật ngữ ngành điện lạnh (ví dụ: máy nén, ga lạnh, van tiết lưu, board mạch điều khiển...) và dễ hiểu cho thợ sửa chữa.

Các mục section bạn cần viết:
- Nếu section = 'all': Trả về một đối tượng JSON chứa cả 3 trường: "causes", "steps", "notes".
- Nếu section = 'causes': Trả về chuỗi văn bản danh sách các nguyên nhân gây ra lỗi này (viết dạng gạch đầu dòng ngắn gọn, đầy đủ các khả năng từ đơn giản đến phức tạp).
- Nếu section = 'steps': Trả về chuỗi văn bản quy trình khắc phục từng bước xử lý lỗi (viết dạng các bước rõ ràng: Bước 1:..., Bước 2:..., Bước 3:...).
- Nếu section = 'notes': Trả về chuỗi văn bản các lưu ý quan trọng về an toàn và kinh nghiệm khi xử lý lỗi này (ví dụ: ngắt điện, chống giật, lưu ý kỹ thuật...).

Yêu cầu BẮT BUỘC:
1. Nếu section = 'all', kết quả trả về phải là một JSON HỢP LỆ khớp với schema được cung cấp.
2. Nếu section là 'causes', 'steps' hoặc 'notes', hãy trả về chuỗi văn bản thuần túy (Plain text) của riêng phần đó, KHÔNG BỌC TRONG JSON.
3. Tuyệt đối KHÔNG tự ý chèn thêm ngày, tháng, năm hoặc thông tin thời gian vào nội dung bài viết.`;

    const userPrompt =
      section === "all"
        ? `Hãy soạn thảo toàn bộ bài viết bao gồm: 1. Nguyên nhân, 2. Quy trình khắc phục từng bước, 3. Các lưu ý an toàn & kinh nghiệm thực tế cho bài viết có tiêu đề "${title}".`
        : `Hãy viết nội dung cho mục "${
            section === "causes"
              ? "Nguyên nhân"
              : section === "steps"
                ? "Hướng dẫn khắc phục"
                : "Lưu ý"
          }" của bài viết có tiêu đề "${title}".`;

    // 5. Query OpenRouter with structured output config if applicable
    const openRouterBody: any = {
      model: model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      max_tokens: 3000,
    };

    if (section === "all") {
      openRouterBody.response_format = {
        type: "json_schema",
        json_schema: {
          name: "hvac_copilot_sections",
          strict: true,
          schema: {
            type: "object",
            properties: {
              causes: {
                type: "string",
                description:
                  "Danh sách nguyên nhân lỗi viết dạng gạch đầu dòng ngắn gọn.",
              },
              steps: {
                type: "string",
                description:
                  "Quy trình từng bước cụ thể để thợ sửa chữa khắc phục mã lỗi.",
              },
              notes: {
                type: "string",
                description:
                  "Lưu ý an toàn kỹ thuật và kinh nghiệm thực tế khi xử lý lỗi.",
              },
            },
            required: ["causes", "steps", "notes"],
            additionalProperties: false,
          },
        },
      };

      // Instruct OpenRouter routing system to only route to providers that support these JSON schema params
      openRouterBody.provider = {
        require_parameters: true,
      };
    }

    const response = await fetch(
      "https://openrouter.ai/api/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": APP_URL,
          "X-OpenRouter-Title": "HVAC Pro Admin",
        },
        body: JSON.stringify(openRouterBody),
      },
    );

    if (!response.ok) {
      const errorData = await response.text();
      console.error("OpenRouter API Error:", errorData);
      return NextResponse.json(
        { error: "Generation API service is temporarily unavailable." },
        { status: response.status },
      );
    }

    const data = await response.json();
    const resultText = data.choices?.[0]?.message?.content?.trim();

    if (!resultText) {
      return NextResponse.json(
        { error: "AI returned an empty response." },
        { status: 500 },
      );
    }

    // 6. Handle JSON output formatting and validation
    if (section === "all") {
      // --- Multi-stage JSON repair pipeline ---
      const repairJson = (raw: string): Record<string, string> | null => {
        // Stage 1: direct parse
        try { return JSON.parse(raw); } catch {}

        // Stage 2: strip markdown code fences (```json ... ```)
        const stripped = raw.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/i, "").trim();
        try { return JSON.parse(stripped); } catch {}

        // Stage 3: extract first {...} block
        const match = stripped.match(/\{[\s\S]*\}/);
        if (match) {
          try { return JSON.parse(match[0]); } catch {}
        }

        // Stage 4: field-by-field regex extraction (last resort)
        const extract = (key: string): string => {
          // Match "key": "value" — value can span multiple lines
          const re = new RegExp(`"${key}"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"`,"s");
          const m = stripped.match(re);
          return m ? m[1].replace(/\\n/g, "\n").replace(/\\"/g, '"') : "";
        };
        const causes = extract("causes");
        const steps  = extract("steps");
        const notes  = extract("notes");
        if (causes || steps || notes) return { causes, steps, notes };

        return null;
      };

      const parsedJson = repairJson(resultText);
      if (parsedJson) {
        return NextResponse.json(parsedJson);
      }

      console.error("AI response JSON repair failed. Raw content:", resultText);
      return NextResponse.json(
        { error: "Failed to parse structured content from AI. Try a different model." },
        { status: 500 },
      );
    } else {
      return NextResponse.json({ text: resultText });
    }
  } catch (error) {
    console.error("Error in generate-content route:", error);
    return NextResponse.json(
      { error: "Internal server error occurred during content generation." },
      { status: 500 },
    );
  }
}
