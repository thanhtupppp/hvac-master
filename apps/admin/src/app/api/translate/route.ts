import { NextResponse } from 'next/server';

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

// Auto-repair truncated JSON strings
function repairJson(jsonStr: string): string {
  jsonStr = jsonStr.trim();
  if (jsonStr.endsWith('}')) {
    return jsonStr;
  }

  // Count double quotes
  let quoteCount = 0;
  for (let i = 0; i < jsonStr.length; i++) {
    if (jsonStr[i] === '"' && (i === 0 || jsonStr[i - 1] !== '\\')) {
      quoteCount++;
    }
  }

  // If quote count is odd, it means we are inside a string. Close the string quote first.
  if (quoteCount % 2 !== 0) {
    jsonStr += '"';
  }

  // Count braces
  let openBraceCount = 0;
  let closeBraceCount = 0;
  for (let i = 0; i < jsonStr.length; i++) {
    if (jsonStr[i] === '{') openBraceCount++;
    if (jsonStr[i] === '}') closeBraceCount++;
  }

  const missingBraces = openBraceCount - closeBraceCount;
  if (missingBraces > 0) {
    jsonStr += '}'.repeat(missingBraces);
  }

  return jsonStr;
}

export async function POST(req: Request) {
  if (!OPENROUTER_API_KEY) {
    return NextResponse.json({ error: "Missing OPENROUTER_API_KEY environment variable" }, { status: 500 });
  }

  try {
    const { title, causes, steps, notes, aiModel, targetLang } = await req.json();

    if (!title || !targetLang) {
      return NextResponse.json({ error: "Missing title or targetLang parameter" }, { status: 400 });
    }

    const languageNames: Record<string, string> = {
      en: "Tiếng Anh (English)",
      ko: "Tiếng Hàn Quốc (Korean)",
      ja: "Tiếng Nhật Bản (Japanese)",
      zh: "Tiếng Trung Quốc (Chinese)",
      km: "Tiếng Campuchia/Khmer (Khmer)",
      lo: "Tiếng Lào (Lao)",
      hi: "Tiếng Hindi (Hindi - हिन्दी). Bạn bắt buộc phải dịch sang chữ viết Devanagari chính thức của tiếng Hindi (không dùng bảng chữ cái Latinh hay tiếng Anh).",
      es: "Tiếng Tây Ban Nha (Spanish)",
      fr: "Tiếng Pháp (French)",
      de: "Tiếng Đức (German)"
    };

    const targetLangName = languageNames[targetLang] || targetLang;

    const systemPrompt = `Bạn là một chuyên gia dịch thuật kỹ thuật chuyên nghiệp trong lĩnh vực Cơ điện lạnh (HVAC) và Thiết bị gia dụng. Hãy dịch tiêu đề và các phần nội dung bài viết sang ngôn ngữ: ${targetLangName}.
    
Yêu cầu BẮT BUỘC về ngôn ngữ và kỹ thuật:
1. Sử dụng thuật ngữ chuyên ngành kỹ thuật chính xác, tự nhiên và chuẩn công nghiệp của quốc gia bản địa (ví dụ các bộ phận như: máy nén, board mạch Inverter, cảm biến nhiệt độ NTC, van tiết lưu, dàn nóng, dàn lạnh, môi chất lạnh phải được dịch sang từ chuyên ngành kỹ thuật tương ứng, KHÔNG DỊCH WORD-BY-WORD theo nghĩa thông thường).
2. Văn phong mang tính chất hướng dẫn xử lý kỹ thuật rõ ràng, ngắn gọn và thực tế cho thợ sửa chữa. Giữ nguyên các ký hiệu kỹ thuật viết tắt quốc tế phổ biến (ví dụ: PCB, MCU, AC/DC, NTC, EPROM) và các mã lỗi (ví dụ: E1, H11, F9).
3. Giữ nguyên toàn bộ cấu trúc các thẻ HTML và các thẻ Markdown chèn ảnh/tài liệu đặc biệt như: ![img](url) hoặc [pdf](url) trong các mục nội dung.
4. CHỈ TRẢ VỀ JSON HỢP LỆ, KHÔNG CHỨA TEXT NÀO KHÁC BÊN NGOÀI JSON (Không dùng markdown \`\`\`json).
5. Cấu trúc JSON phải đúng định dạng như sau:
{
  "title": "...",
  "causes": "...",
  "steps": "...",
  "notes": "..."
}
6. Tuyệt đối KHÔNG tự ý chèn thêm ngày, tháng, năm hoặc thông tin thời gian vào tiêu đề bài viết.`;

    const userPrompt = `Tiêu đề (Tiếng Việt):
${title}

Nguyên nhân (Tiếng Việt):
${causes || ""}

Hướng dẫn khắc phục (Tiếng Việt):
${steps || ""}

Lưu ý kỹ thuật (Tiếng Việt):
${notes || ""}`;

    const model = aiModel || process.env.OPENROUTER_MODEL || "google/gemini-2.5-flash";

    console.log(`Translating article to ${targetLangName} using model ${model}...`);
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:3000", 
        "X-Title": "HVAC Pro Admin Translation"
      },
      body: JSON.stringify({
        model: model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        response_format: { type: "json_object" },
        max_tokens: 3000
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error(`OpenRouter API Error during translation to ${targetLangName}:`, errorData);
      return NextResponse.json({ error: `Translation API failed for ${targetLangName}` }, { status: response.status });
    }

    const data = await response.json();
    let resultText = data.choices[0].message.content.trim();
    
    let translatedContent;
    try {
      const firstBrace = resultText.indexOf('{');
      if (firstBrace === -1) {
        throw new Error("Could not find JSON object start '{' in AI response");
      }
      
      let jsonStr = resultText.substring(firstBrace);
      
      // Auto-repair JSON in case of truncation
      jsonStr = repairJson(jsonStr);

      try {
        translatedContent = JSON.parse(jsonStr);
      } catch (e) {
        let inString = false;
        let chars = jsonStr.split('');
        for (let i = 0; i < chars.length; i++) {
          if (chars[i] === '"' && (i === 0 || chars[i - 1] !== '\\')) {
            inString = !inString;
          } else if (inString && (chars[i] === '\n' || chars[i] === '\r')) {
            if (chars[i] === '\n') {
              chars[i] = '\\n';
            } else if (chars[i] === '\r') {
              chars[i] = '';
            }
          }
        }
        jsonStr = chars.join('');
        translatedContent = JSON.parse(jsonStr);
      }
    } catch (parseError: any) {
      console.error("AI response parsing failed. Original response:", resultText);
      const length = resultText.length;
      const startSnippet = resultText.substring(0, 300);
      const endSnippet = length > 300 ? resultText.substring(length - 200) : "";
      return NextResponse.json({ 
        error: `Invalid JSON returned by AI: ${parseError.message}. Model: ${model}. Length: ${length}. Start: "${startSnippet}" ... End: "${endSnippet}"` 
      }, { status: 500 });
    }

    return NextResponse.json(translatedContent);
  } catch (error: any) {
    console.error("Error in translation route:", error);
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
