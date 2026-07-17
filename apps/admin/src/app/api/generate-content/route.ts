import { NextResponse } from 'next/server';

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

export async function POST(req: Request) {
  if (!OPENROUTER_API_KEY) {
    return NextResponse.json({ error: "Missing OPENROUTER_API_KEY environment variable" }, { status: 500 });
  }

  try {
    const { title, section, aiModel } = await req.json();

    if (!title) {
      return NextResponse.json({ error: "Missing title" }, { status: 400 });
    }

    const systemPrompt = `Bạn là một kỹ sư cơ điện lạnh (HVAC) kiêm thợ sửa chữa thiết bị gia dụng gạo cội với hơn 20 năm kinh nghiệm xử lý lỗi thực tế. 
Nhiệm vụ của bạn là hỗ trợ viết tài liệu hướng dẫn kỹ thuật chất lượng cao cho bài viết có tiêu đề: "${title}".

Dựa vào mục yêu cầu "section", hãy viết nội dung tương ứng theo phong cách chuyên nghiệp, thực tế, sử dụng đúng thuật ngữ ngành điện lạnh (ví dụ: máy nén, ga lạnh, van tiết lưu, board mạch điều khiển...) và dễ hiểu cho thợ sửa chữa.

Các mục section bạn cần viết:
- Nếu section = 'all': Trả về một đối tượng JSON chứa cả 3 trường: "causes", "steps", "notes".
- Nếu section = 'causes': Trả về chuỗi văn bản danh sách các nguyên nhân gây ra lỗi này (viết dạng gạch đầu dòng ngắn gọn, đầy đủ các khả năng từ đơn giản đến phức tạp).
- Nếu section = 'steps': Trả về chuỗi văn bản quy trình khắc phục từng bước xử lý lỗi (viết dạng các bước rõ ràng: Bước 1:..., Bước 2:..., Bước 3:...).
- Nếu section = 'notes': Trả về chuỗi văn bản các lưu ý quan trọng về an toàn và kinh nghiệm khi xử lý lỗi này (ví dụ: ngắt điện, chống giật, lưu ý kỹ thuật...).

Yêu cầu BẮT BUỘC:
1. Nếu section = 'all', kết quả trả về phải là một JSON HỢP LỆ, KHÔNG CHỨA TEXT NÀO KHÁC BÊN NGOÀI (Không sử dụng markdown \`\`\`json). Cấu trúc đúng:
{
  "causes": "...",
  "steps": "...",
  "notes": "..."
}
2. Nếu section là 'causes', 'steps' hoặc 'notes', hãy trả về chuỗi văn bản thuần túy (Plain text) của riêng phần đó, KHÔNG BỌC TRONG JSON.
3. Tuyệt đối KHÔNG tự ý chèn thêm ngày, tháng, năm hoặc thông tin thời gian vào nội dung bài viết.`;

    const userPrompt = section === 'all'
      ? `Hãy soạn thảo toàn bộ bài viết bao gồm: 1. Nguyên nhân, 2. Quy trình khắc phục từng bước, 3. Các lưu ý an toàn & kinh nghiệm thực tế cho bài viết có tiêu đề "${title}". Yêu cầu trả về kết quả cấu trúc JSON chứa 3 trường: "causes", "steps", "notes".`
      : `Hãy viết nội dung cho mục "${section === 'causes' ? 'Nguyên nhân' : section === 'steps' ? 'Hướng dẫn khắc phục' : 'Lưu ý'}" của bài viết có tiêu đề "${title}".`;

    const model = aiModel || process.env.OPENROUTER_MODEL || "google/gemini-2.5-flash";

    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:3000", 
        "X-Title": "HVAC Pro Admin"
      },
      body: JSON.stringify({
        model: model,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt }
        ],
        response_format: section === 'all' ? { type: "json_object" } : undefined,
        max_tokens: 3000
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error("OpenRouter API Error:", errorData);
      return NextResponse.json({ error: "Generation API failed" }, { status: response.status });
    }

    const data = await response.json();
    let resultText = data.choices[0].message.content.trim();

    if (section === 'all') {
      try {
        // Locate first '{' and last '}'
        const firstBrace = resultText.indexOf('{');
        const lastBrace = resultText.lastIndexOf('}');
        if (firstBrace === -1 || lastBrace === -1 || lastBrace <= firstBrace) {
          throw new Error("Could not find JSON object in AI response");
        }
        let jsonStr = resultText.substring(firstBrace, lastBrace + 1);

        let parsedJson;
        try {
          parsedJson = JSON.parse(jsonStr);
        } catch (e) {
          // If direct parsing fails (often due to raw newlines inside string values),
          // clean and escape newlines inside double quotes.
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
          parsedJson = JSON.parse(jsonStr);
        }
        return NextResponse.json(parsedJson);
      } catch (parseError: any) {
        console.error("AI response parsing failed. Original response:", resultText);
        return NextResponse.json({ error: "Failed to parse content from AI: " + parseError.message }, { status: 500 });
      }
    } else {
      return NextResponse.json({ text: resultText });
    }
  } catch (error: any) {
    console.error("Error in generate-content route:", error);
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
