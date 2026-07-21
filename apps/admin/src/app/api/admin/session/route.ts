import { NextResponse } from "next/server";

/**
 * Sets or clears the admin session HttpOnly cookie.
 *
 * The cookie is HttpOnly + Secure + SameSite=Lax so the JS context
 * (including any XSS payload) cannot read it; only the server can.
 *
 * Body:
 *   { "action": "set", "idToken": "..." }   -> sets 24h HttpOnly cookie
 *   { "action": "clear" }                   -> clears cookie
 *
 * The actual admin authorization check lives on the route handlers
 * that read the cookie. This endpoint only brokers the cookie.
 */
export async function POST(req: Request) {
  let body: any = null;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON body." },
      { status: 400 },
    );
  }

  const action = body?.action;

  if (action === "set") {
    const idToken = body?.idToken;
    if (!idToken || typeof idToken !== "string") {
      return NextResponse.json(
        { error: "Missing idToken." },
        { status: 400 },
      );
    }
    const res = NextResponse.json({ ok: true });
    res.cookies.set("__AdminSession", idToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24, // 24h
    });
    return res;
  }

  if (action === "clear") {
    const res = NextResponse.json({ ok: true });
    res.cookies.set("__AdminSession", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: 0,
    });
    return res;
  }

  return NextResponse.json(
    { error: "Unknown action. Use 'set' or 'clear'." },
    { status: 400 },
  );
}
