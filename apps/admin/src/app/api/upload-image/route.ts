import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { cloudinary } from "@/services/cloudinary";

/**
 * @deprecated Use /api/upload with { type: 'image' } instead.
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

    const { image } = await req.json().catch(() => ({}));

    if (!image) {
      return NextResponse.json({ error: "Missing image data" }, { status: 400 });
    }

    console.log("Uploading image to Cloudinary...");
    const uploadResult = await cloudinary.uploader.upload(image, {
      folder: "articles"
    });

    return NextResponse.json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id
    });
  } catch (error) {
    console.error("Error in upload-image route:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
