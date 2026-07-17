import { NextResponse } from 'next/server';

const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

export async function POST(req: Request) {
  if (!OPENROUTER_API_KEY) {
    return NextResponse.json({ error: "Missing OPENROUTER_API_KEY environment variable" }, { status: 500 });
  }

  try {
    const { model } = await req.json();

    if (!model) {
      return NextResponse.json({ error: "Missing model ID" }, { status: 400 });
    }

    console.log(`Testing model: ${model}...`);
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost:3000", 
        "X-Title": "HVAC Pro Model Test"
      },
      body: JSON.stringify({
        model: model,
        messages: [
          { role: "user", content: "Reply with exactly 'OK'" }
        ],
        max_tokens: 5
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`OpenRouter test failed for ${model}:`, errorText);
      return NextResponse.json({ error: errorText || "API call failed" }, { status: response.status });
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content?.trim() || "No response";

    return NextResponse.json({
      success: true,
      reply: reply
    });
  } catch (error: any) {
    console.error("Error in test-model route:", error);
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
