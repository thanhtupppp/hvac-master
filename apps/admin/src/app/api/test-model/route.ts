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
    "Model ID không đúng định dạng. Ví dụ: provider/model-name hoặc provider/model-name:free"
  );

// Request validation schema
const requestBodySchema = z.object({
  model: MODEL_ID_SCHEMA,
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

    const { model } = parsed.data;

    console.log(`Testing connection for model: ${model}...`);
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": APP_URL,
        "X-OpenRouter-Title": "HVAC Pro Model Test"
      },
      body: JSON.stringify({
        model: model,
        messages: [{ role: "user", content: "Reply with exactly 'OK'" }],
        max_tokens: 5
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`OpenRouter test failed for ${model}:`, errorText);
      return NextResponse.json(
        { error: "Connection to OpenRouter model failed." },
        { status: response.status }
      );
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content || "";

    // If OpenRouter returns 200 and model produces any reply → connection is OK.
    // We show the actual reply so admin can judge model quality, but do NOT
    // require the exact string "OK" — some models (e.g. Chinese, multilingual)
    // may respond differently while still being fully functional.
    return NextResponse.json({
      success: true,
      reply: reply || "(empty response)",
    });
  } catch (error) {
    console.error("Error in test-model route:", error);
    return NextResponse.json(
      { error: "Internal server error occurred during connection testing." },
      { status: 500 }
    );
  }
}
