import { NextResponse } from "next/server";
import { v2 as cloudinary } from "cloudinary";
import { requireAdmin } from "@/lib/firebase-admin";

type UploadType = "image" | "pdf" | "video";

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME as string;
const API_KEY = process.env.CLOUDINARY_API_KEY as string;
const API_SECRET = process.env.CLOUDINARY_API_SECRET as string;

// Fail fast at startup/module load if environment configuration is incomplete
if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
  throw new Error("Required Cloudinary environment variables are missing or misconfigured.");
}

// Configure Cloudinary client
cloudinary.config({
  cloud_name: CLOUD_NAME,
  api_key: API_KEY,
  api_secret: API_SECRET,
});

const UPLOAD_CONFIG: Record<UploadType, { folder: string; resourceType: string }> = {
  image: { folder: "articles", resourceType: "image" },
  pdf: { folder: "documents", resourceType: "auto" },
  video: { folder: "videos", resourceType: "video" },
};

function isUploadType(value: unknown): value is UploadType {
  return value === "image" || value === "pdf" || value === "video";
}

export async function POST(req: Request) {
  try {
    // 1. Authenticate & Authorize request using the centralized helper
    try {
      await requireAdmin(req);
    } catch (authError: any) {
      return NextResponse.json(
        { error: authError.message || "Unauthorized access." },
        { status: authError.status || 401 }
      );
    }

    // 2. Parse and validate request body
    const body = await req.json().catch(() => null);
    const type = body?.type;

    if (!isUploadType(type)) {
      return NextResponse.json(
        { error: "Invalid or unsupported upload type." },
        { status: 400 }
      );
    }

    // 3. Configure folder and parameters
    const config = UPLOAD_CONFIG[type];
    const timestamp = Math.floor(Date.now() / 1000);

    const paramsToSign = {
      folder: config.folder,
      timestamp,
    };

    // 4. Generate security signature
    const signature = cloudinary.utils.api_sign_request(paramsToSign, API_SECRET);

    return NextResponse.json({
      signature,
      timestamp,
      apiKey: API_KEY,
      cloudName: CLOUD_NAME,
      folder: config.folder,
      resourceType: config.resourceType,
    });
  } catch (error) {
    // Log detailed error on the server console for debugging, return generic message to client
    console.error("Error generating Cloudinary signature:", error);
    return NextResponse.json(
      { error: "Unable to generate secure upload signature." },
      { status: 500 }
    );
  }
}
