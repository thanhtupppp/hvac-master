import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { cloudinary } from "@/services/cloudinary";

/**
 * @deprecated Use /api/upload with { type: 'video' } instead.
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

    const { video } = await req.json().catch(() => ({}));

    if (!video) {
      return NextResponse.json({ error: "Missing video data" }, { status: 400 });
    }

    console.log("Uploading video to Cloudinary...");
    const uploadResult = await cloudinary.uploader.upload(video, {
      folder: "videos",
      resource_type: "video"
    });

    return NextResponse.json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id
    });
  } catch (error) {
    console.error("Error in upload-video route:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
