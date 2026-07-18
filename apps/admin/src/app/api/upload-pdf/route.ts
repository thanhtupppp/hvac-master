import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { cloudinary } from "@/services/cloudinary";

/**
 * @deprecated Use /api/upload with { type: 'pdf' } instead.
 * Kept for backward compatibility.
 */
export async function POST(req: Request) {
  try {
    // Authenticate & Authorize request
    try {
      await requireAdmin(req);
    } catch (authError: any) {
      return NextResponse.json(
        { error: authError.message || "Unauthorized access." },
        { status: authError.status || 401 }
      );
    }

    const { pdf } = await req.json().catch(() => ({}));

    if (!pdf) {
      return NextResponse.json({ error: "Missing PDF data" }, { status: 400 });
    }

    console.log("Uploading PDF to Cloudinary...");
    const uploadResult = await cloudinary.uploader.upload(pdf, {
      folder: "documents",
      resource_type: "auto"
    });

    return NextResponse.json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id
    });
  } catch (error) {
    console.error("Error in upload-pdf route:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
