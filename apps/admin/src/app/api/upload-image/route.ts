import { NextResponse } from 'next/server';
import { v2 as cloudinary } from 'cloudinary';

// Cloudinary Configuration fallback to User credentials
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
    const { image } = await req.json();

    if (!image) {
      return NextResponse.json({ error: "Missing image data" }, { status: 400 });
    }

    // Upload to Cloudinary under the "articles" folder
    console.log("Uploading image to Cloudinary...");
    const uploadResult = await cloudinary.uploader.upload(image, {
      folder: "articles"
    });

    return NextResponse.json({
      secure_url: uploadResult.secure_url,
      public_id: uploadResult.public_id
    });
  } catch (error: any) {
    console.error("Error in upload-image route:", error);
    return NextResponse.json({ error: error.message || "Internal server error" }, { status: 500 });
  }
}
