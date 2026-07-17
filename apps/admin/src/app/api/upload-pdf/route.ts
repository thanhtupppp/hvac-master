import { NextResponse } from 'next/server';
import { v2 as cloudinary } from 'cloudinary';

const CLOUD_NAME = process.env.CLOUDINARY_CLOUD_NAME || "b7q5vkwp";
const API_KEY = process.env.CLOUDINARY_API_KEY || "355571651725253";
const API_SECRET = process.env.CLOUDINARY_API_SECRET || "niorPDXzVVNEHCKgiHb6mED2v00";

cloudinary.config({
  cloud_name: CLOUD_NAME,
  api_key: API_KEY,
  api_secret: API_SECRET,
  secure: true
});

export async function POST(req: Request) {
  try {
    const { pdf } = await req.json();

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
  } catch (error: any) {
    console.error("Error in upload-pdf route:", error);
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
