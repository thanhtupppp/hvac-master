import { useState } from 'react';
import { auth } from '@/lib/firebase';

const CLOUDINARY_LIMITS = {
  image: 5 * 1024 * 1024,
  pdf: 15 * 1024 * 1024,
  video: 30 * 1024 * 1024,
};

export function useCloudinaryUpload() {
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const uploadFile = async (file: File, type: 'image' | 'pdf' | 'video'): Promise<string> => {
    setIsUploading(true);
    setError(null);

    try {
      // Validate file size limit
      const limit = CLOUDINARY_LIMITS[type];
      if (file.size > limit) {
        throw new Error(
          `Dung lượng file vượt quá giới hạn cho phép (Tối đa: ${limit / (1024 * 1024)}MB).`
        );
      }

      // Fetch Firebase ID token
      const idToken = await auth.currentUser?.getIdToken();
      if (!idToken) {
        throw new Error("Vui lòng đăng nhập để thực hiện tải tệp.");
      }

      // 1. Fetch Cloudinary signature from server
      const sigRes = await fetch('/api/cloudinary-signature', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${idToken}`
        },
        body: JSON.stringify({ type }),
      });

      if (!sigRes.ok) {
        const errData = await sigRes.json().catch(() => ({}));
        throw new Error(errData.error || 'Không thể tạo chữ ký tải lên bảo mật.');
      }

      const { signature, timestamp, apiKey, cloudName, folder, resourceType } = await sigRes.json();

      // 2. Build FormData and upload directly to Cloudinary API
      const formData = new FormData();
      formData.append('file', file);
      formData.append('api_key', apiKey);
      formData.append('timestamp', timestamp.toString());
      formData.append('signature', signature);
      formData.append('folder', folder);

      const cloudinaryUrl = `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;
      const uploadRes = await fetch(cloudinaryUrl, {
        method: 'POST',
        body: formData,
      });

      if (!uploadRes.ok) {
        const errData = await uploadRes.json().catch(() => ({}));
        throw new Error(errData.error?.message || 'Tải file lên Cloudinary thất bại.');
      }

      const data = await uploadRes.json();
      return data.secure_url;
    } catch (err: any) {
      console.error('Error in useCloudinaryUpload hook:', err);
      const errMsg = err.message || 'Lỗi không xác định trong quá trình tải tệp.';
      setError(errMsg);
      throw new Error(errMsg);
    } finally {
      setIsUploading(false);
    }
  };

  return { isUploading, error, uploadFile };
}
