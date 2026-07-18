import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { cloudinary } from "@/services/cloudinary";
import { z } from "zod";

type UploadType = "image" | "pdf" | "video";

const UPLOAD_CONFIG: Record<UploadType, { folder: string; resourceType: "image" | "auto" | "video"; field: string }> = {
  image: { folder: "articles", resourceType: "image", field: "image" },
  pdf: { folder: "documents", resourceType: "auto", field: "pdf" },
  video: { folder: "videos", resourceType: "video", field: "video" },
};

const requestBodySchema = z.object({
  type: z.enum(["image", "pdf", "video"]).optional().default("image"),
  image: z.string().optional(),
  pdf: z.string().optional(),
  video: z.string().optional(),
  data: z.string().optional(),
});

export async function POST(req: Request) {
  try {
    // 1. Authenticate & Authorize request using requireAdmin helper
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

    const { type, image, pdf, video, data } = parsed.data;
    const config = UPLOAD_CONFIG[type];

    const fileData = (type === "image" ? image : type === "pdf" ? pdf : video) || data;
    if (!fileData) {
      return NextResponse.json({ error: "Missing upload file data." }, { status: 400 });
    }

    console.log(`Uploading ${type} to Cloudinary...`);
    const uploadResult = await cloudinary.uploader.upload(fileData, {
      folder: config.folder,
      resource_type: config.resourceType,
    });

    return NextResponse.json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id,
    });
  } catch (error) {
    console.error("Error in upload route:", error);
    return NextResponse.json(
      { error: "Internal server error occurred during upload." },
      { status: 500 }
    );
  }
}
