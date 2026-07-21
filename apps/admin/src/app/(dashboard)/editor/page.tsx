"use client";

import { useState, useEffect, useRef, Suspense } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { db, auth } from "@/lib/firebase";
import {
  collection,
  addDoc,
  getDocs,
  doc,
  getDoc,
  updateDoc,
  query,
  orderBy,
  serverTimestamp,
} from "firebase/firestore";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Sparkles,
  Wand2,
  Upload,
  X,
  Image as ImageIcon,
  FileText,
  Video,
  Globe,
  Loader2,
} from "lucide-react";
import Image from "next/image";
import { useCloudinaryUpload } from "@/hooks";

interface TranslatedContent {
  title: string;
  causes: string;
  steps: string;
  notes: string;
}

const defaultModels = [
  { id: "google/gemini-2.5-flash", name: "Google: Gemini 2.5 Flash" },
  { id: "google/gemini-2.5-pro", name: "Google: Gemini 2.5 Pro" },
  {
    id: "meta-llama/llama-3.3-70b-instruct:free",
    name: "Meta: Llama 3.3 70B (Free)",
  },
  { id: "meta-llama/llama-3.3-70b-instruct", name: "Meta: Llama 3.3 70B" },
  { id: "deepseek/deepseek-chat", name: "DeepSeek: V3" },
  { id: "openai/gpt-4o-mini", name: "OpenAI: GPT-4o Mini" },
  { id: "anthropic/claude-3-5-haiku", name: "Anthropic: Claude 3.5 Haiku" },
  { id: "qwen/qwen-2.5-72b-instruct", name: "Qwen: 2.5 72B Instruct" },
  { id: "tencent/hy3:free", name: "Tencent: HY3 (Free)" },
  { id: "tencent/hy3", name: "Tencent: HY3" },
  { id: "poolside/laguna-m.1:free", name: "Poolside: Laguna M.1 (Free)" },
  { id: "openai/gpt-oss-20b:free", name: "OpenAI: GPT OSS 20B (Free)" },
];

const editorLanguages = [
  { code: "en", name: "Tiếng Anh" },
  { code: "ko", name: "Tiếng Hàn" },
  { code: "ja", name: "Tiếng Nhật" },
  { code: "zh", name: "Tiếng Trung" },
  { code: "km", name: "Tiếng Khmer" },
  { code: "lo", name: "Tiếng Lào" },
  { code: "hi", name: "Tiếng Hindi" },
  { code: "es", name: "Tiếng Tây Ban Nha" },
  { code: "fr", name: "Tiếng Pháp" },
  { code: "de", name: "Tiếng Đức" },
];

function EditorContent() {
  const [title, setTitle] = useState("");
  const [causes, setCauses] = useState("");
  const [steps, setSteps] = useState("");
  const [notes, setNotes] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [pdfUrl, setPdfUrl] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [categories, setCategories] = useState<{ id: string; name: string }[]>(
    [],
  );
  const [category, setCategory] = useState("");
  const [brands, setBrands] = useState<{ id: string; name: string }[]>([]);
  const [brand, setBrand] = useState("");
  const [isPremium, setIsPremium] = useState(false);
  const [translations, setTranslations] = useState<
    Record<string, TranslatedContent>
  >({});
  const [previewLang, setPreviewLang] = useState("en");
  const [isSaving, setIsSaving] = useState(false);

  const { isUploading: isUploadingImage, uploadFile: uploadImage } =
    useCloudinaryUpload();
  const { isUploading: isUploadingPdf, uploadFile: uploadPdf } =
    useCloudinaryUpload();
  const { isUploading: isUploadingVideo, uploadFile: uploadVideo } =
    useCloudinaryUpload();

  // Textarea Refs for direct cursor insertion
  const causesRef = useRef<HTMLTextAreaElement>(null);
  const stepsRef = useRef<HTMLTextAreaElement>(null);
  const notesRef = useRef<HTMLTextAreaElement>(null);

  const refMap = {
    causes: causesRef,
    steps: stepsRef,
    notes: notesRef,
  };

  // AI Copilot loading states
  const [isGeneratingAll, setIsGeneratingAll] = useState(false);
  const [isGeneratingCauses, setIsGeneratingCauses] = useState(false);
  const [isGeneratingSteps, setIsGeneratingSteps] = useState(false);
  const [isGeneratingNotes, setIsGeneratingNotes] = useState(false);

  const [isLoadingCats, setIsLoadingCats] = useState(true);
  const [isLoadingBrands, setIsLoadingBrands] = useState(true);
  const [statusText, setStatusText] = useState("");
  const [translatingLang, setTranslatingLang] = useState<string | null>(null);

  const [selectedModel, setSelectedModel] = useState("google/gemini-2.5-flash");
  const [modelsList, setModelsList] = useState<{ id: string; name: string }[]>(
    [],
  );
  const [newModelName, setNewModelName] = useState("");
  const [newModelId, setNewModelId] = useState("");
  const [isManagingModels, setIsManagingModels] = useState(false);
  const [testingModelId, setTestingModelId] = useState<string | null>(null);

  const router = useRouter();
  const searchParams = useSearchParams();
  const articleId = searchParams.get("id");

  const handleTestModel = async (modelId: string) => {
    setTestingModelId(modelId);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const res = await fetch("/api/test-model", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({ model: modelId }),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        alert(
          `✅ Kết nối thành công với model ${modelId}!\nAI phản hồi: "${data.reply}"`,
        );
      } else {
        let errMsg = data.error || "Không kết nối được.";
        // If format validation error, show helpful format hint
        if (res.status === 400 && data.details) {
          errMsg = `Model ID "${modelId}" không đúng định dạng.\n\nĐịnh dạng hợp lệ: provider/model-name hoặc provider/model-name:free\nVí dụ: google/gemini-2.5-flash, meta-llama/llama-3.3-70b-instruct:free`;
        } else {
          // Try to parse nested JSON error from OpenRouter
          try {
            const parsed = JSON.parse(errMsg);
            if (parsed.error?.message) errMsg = parsed.error.message;
          } catch (e) {}
        }
        alert(`❌ Kiểm tra thất bại cho model ${modelId}:\n${errMsg}`);
      }
    } catch (err: any) {
      alert("❌ Lỗi kết nối: " + err.message);
    } finally {
      setTestingModelId(null);
    }
  };

  const insertTextAtCursor = (
    field: "causes" | "steps" | "notes",
    textToInsert: string,
  ) => {
    const textarea = refMap[field].current;
    if (!textarea) return;

    textarea.focus();
    const startPos = textarea.selectionStart;
    const endPos = textarea.selectionEnd;
    const currentValue = textarea.value;

    let formattedText = textToInsert;
    // Add newline before image if not at start and previous char is not newline
    if (startPos > 0 && currentValue[startPos - 1] !== "\n") {
      formattedText = "\n" + formattedText;
    }
    // Add newline after image if next char is not newline and not at end
    if (endPos < currentValue.length && currentValue[endPos] !== "\n") {
      formattedText = formattedText + "\n";
    }

    const newValue =
      currentValue.substring(0, startPos) +
      formattedText +
      currentValue.substring(endPos, currentValue.length);

    if (field === "causes") setCauses(newValue);
    if (field === "steps") setSteps(newValue);
    if (field === "notes") setNotes(newValue);

    requestAnimationFrame(() => {
      textarea.focus();
      const newCursorPos = startPos + formattedText.length;
      textarea.setSelectionRange(newCursorPos, newCursorPos);
    });
  };

  // Load AI Model configuration from localStorage on mount
  useEffect(() => {
    if (typeof window !== "undefined") {
      const savedModel = localStorage.getItem("hvac_ai_model:v1");
      const savedList = localStorage.getItem("hvac_ai_models_list:v1");

      if (savedList) {
        try {
          setModelsList(JSON.parse(savedList));
        } catch (e) {
          setModelsList(defaultModels);
        }
      } else {
        setModelsList(defaultModels);
      }

      if (savedModel) setSelectedModel(savedModel);
    }
  }, []);

  const getActiveModel = () => {
    return selectedModel;
  };

  const handleModelChange = (val: string | null) => {
    const value =
      val ||
      (modelsList.length > 0 ? modelsList[0].id : "google/gemini-2.5-flash");
    setSelectedModel(value);
    localStorage.setItem("hvac_ai_model:v1", value);
  };

  const handleAddNewModel = () => {
    if (!newModelName || !newModelId) {
      alert("Vui lòng điền đầy đủ tên hiển thị và slug của model.");
      return;
    }
    const updated = [
      ...modelsList,
      { id: newModelId.trim(), name: newModelName.trim() },
    ];
    setModelsList(updated);
    localStorage.setItem("hvac_ai_models_list:v1", JSON.stringify(updated));
    setNewModelName("");
    setNewModelId("");
  };

  const handleDeleteModel = (idToDelete: string) => {
    const updated = modelsList.filter((m) => m.id !== idToDelete);
    setModelsList(updated);
    localStorage.setItem("hvac_ai_models_list:v1", JSON.stringify(updated));

    if (selectedModel === idToDelete) {
      const nextModel = updated.length > 0 ? updated[0].id : "";
      setSelectedModel(nextModel);
      localStorage.setItem("hvac_ai_model:v1", nextModel);
    }
  };

  const handleResetModels = () => {
    if (confirm("Bạn có chắc chắn muốn khôi phục danh sách model mặc định?")) {
      setModelsList(defaultModels);
      localStorage.setItem(
        "hvac_ai_models_list:v1",
        JSON.stringify(defaultModels),
      );
      setSelectedModel(defaultModels[0].id);
      localStorage.setItem("hvac_ai_model:v1", defaultModels[0].id);
    }
  };

  // Load categories, brands and article details if editing
  useEffect(() => {
    const loadData = async () => {
      try {
        // Load categories
        const catQuery = query(
          collection(db, "categories"),
          orderBy("createdAt", "desc"),
        );
        const catSnapshot = await getDocs(catQuery);
        const catsList: { id: string; name: string }[] = [];
        catSnapshot.forEach((doc) => {
          catsList.push({ id: doc.id, name: doc.data().name || doc.id });
        });
        setCategories(catsList);

        // Load brands
        const brandQuery = query(
          collection(db, "brands"),
          orderBy("createdAt", "desc"),
        );
        const brandSnapshot = await getDocs(brandQuery);
        const brandsList: { id: string; name: string }[] = [];
        brandSnapshot.forEach((doc) => {
          brandsList.push({ id: doc.id, name: doc.data().name || doc.id });
        });
        setBrands(brandsList);

        // Pre-fill categories and brands default select values
        if (catsList.length > 0) setCategory(catsList[0].id);
        if (brandsList.length > 0) setBrand(brandsList[0].id);

        // If in Edit Mode, load article content
        if (articleId) {
          const docRef = doc(db, "articles", articleId);
          const docSnap = await getDoc(docRef);
          if (docSnap.exists()) {
            const data = docSnap.data();
            setTitle(data.title_vi || "");
            setCauses(data.causes_vi || "");
            setSteps(data.steps_vi || "");
            setNotes(data.notes_vi || "");
            setImageUrl(data.imageUrl || "");
            setPdfUrl(data.pdfUrl || "");
            setVideoUrl(data.videoUrl || "");
            setCategory(data.category || "");
            setBrand(data.brand || "");
            setIsPremium(data.isPremium || false);
            setTranslations(data.translations || {});
          } else {
            alert("Không tìm thấy bài viết này!");
            window.location.replace("/articles");
          }
        }
      } catch (error) {
        console.error("Error loading CMS data:", error);
      } finally {
        setIsLoadingCats(false);
        setIsLoadingBrands(false);
      }
    };
    loadData();
  }, [articleId, router]);

  // AI Copilot: Auto-write all sections based on Title
  const handleGenerateAll = async () => {
    if (!title) {
      alert(
        "Vui lòng nhập tiêu đề bài viết trước (Ví dụ: Mã lỗi H11 Điều hòa Panasonic).",
      );
      return;
    }
    setIsGeneratingAll(true);
    setStatusText("AI đang tự động nghiên cứu mã lỗi và soạn thảo toàn bài...");
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const res = await fetch("/api/generate-content", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          title,
          section: "all",
          aiModel: getActiveModel(),
        }),
      });
      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.error || "Sinh nội dung thất bại.");
      }
      const data = await res.json();
      setCauses(data.causes || "");
      setSteps(data.steps || "");
      setNotes(data.notes || "");
    } catch (err: any) {
      console.error(err);
      alert("Lỗi khi sinh nội dung tự động: " + err.message);
    } finally {
      setIsGeneratingAll(false);
      setStatusText("");
    }
  };

  // AI Copilot: Auto-write a single section
  const handleGenerateSection = async (sec: "causes" | "steps" | "notes") => {
    if (!title) {
      alert("Vui lòng nhập tiêu đề bài viết trước.");
      return;
    }
    if (sec === "causes") setIsGeneratingCauses(true);
    if (sec === "steps") setIsGeneratingSteps(true);
    if (sec === "notes") setIsGeneratingNotes(true);

    const displayName =
      sec === "causes"
        ? "Nguyên nhân"
        : sec === "steps"
          ? "Khắc phục"
          : "Lưu ý";
    setStatusText(`AI đang biên soạn nội dung phần ${displayName}...`);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const res = await fetch("/api/generate-content", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          title,
          section: sec,
          aiModel: getActiveModel(),
        }),
      });
      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.error || "Sinh nội dung thất bại.");
      }
      const data = await res.json();
      if (sec === "causes") setCauses(data.text || "");
      if (sec === "steps") setSteps(data.text || "");
      if (sec === "notes") setNotes(data.text || "");
    } catch (err: any) {
      console.error(err);
      alert("Lỗi khi viết hộ phần này: " + err.message);
    } finally {
      if (sec === "causes") setIsGeneratingCauses(false);
      if (sec === "steps") setIsGeneratingSteps(false);
      if (sec === "notes") setIsGeneratingNotes(false);
      setStatusText("");
    }
  };

  // Cloudinary image upload handler
  const handleImageChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setStatusText("Đang tải ảnh lên Cloudinary...");
    try {
      const url = await uploadImage(file, "image");
      setImageUrl(url);
      alert("Tải ảnh lên thành công!");
    } catch (err: any) {
      alert("Lỗi khi tải ảnh lên Cloudinary: " + err.message);
    } finally {
      setStatusText("");
    }
  };

  // Cloudinary PDF upload handler
  const handlePdfChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setStatusText("Đang tải PDF lên Cloudinary...");
    try {
      const url = await uploadPdf(file, "pdf");
      setPdfUrl(url);
      alert("Tải tài liệu PDF thành công!");
    } catch (err: any) {
      alert("Lỗi khi tải PDF lên Cloudinary: " + err.message);
    } finally {
      setStatusText("");
    }
  };

  // Cloudinary Video upload handler
  const handleVideoChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setStatusText("Đang tải video lên Cloudinary...");
    try {
      const url = await uploadVideo(file, "video");
      setVideoUrl(url);
      alert("Tải video thành công!");
    } catch (err: any) {
      alert("Lỗi khi tải video lên Cloudinary: " + err.message);
    } finally {
      setStatusText("");
    }
  };

  const handleSave = async (shouldTranslate: boolean) => {
    if (!title || (!causes && !steps && !notes)) {
      alert(
        "Vui lòng nhập tiêu đề và ít nhất một phần nội dung (Nguyên nhân/Khắc phục/Lưu ý).",
      );
      return;
    }

    if (!category) {
      alert("Vui lòng chọn hoặc tạo chuyên mục trước.");
      return;
    }

    if (!brand) {
      alert("Vui lòng chọn hoặc tạo hãng sản xuất trước.");
      return;
    }

    setIsSaving(true);
    try {
      let updatedTranslations = { ...translations };

      // Re-translate using AI if requested
      if (shouldTranslate) {
        const currentTranslations: Record<string, TranslatedContent> = {};
        setStatusText("Đang bắt đầu dịch thuật đa ngôn ngữ...");

        const chunkSize = 3;
        for (let i = 0; i < languages.length; i += chunkSize) {
          const chunk = languages.slice(i, i + chunkSize);
          const chunkNames = chunk.map((l) => l.name).join(", ");
          setStatusText(
            `Đang dịch sang: ${chunkNames} (${Math.min(i + chunkSize, languages.length)}/${languages.length})...`,
          );

          const promises = chunk.map(async (lang) => {
            const translateRes = await fetch("/api/translate", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                title,
                causes,
                steps,
                notes,
                aiModel: getActiveModel(),
                targetLang: lang.code,
              }),
            });

            const responseData = await translateRes.json().catch(() => ({}));
            if (!translateRes.ok) {
              throw new Error(
                responseData.error || `Dịch thuật sang ${lang.name} thất bại.`,
              );
            }

            return { code: lang.code, data: responseData };
          });

          const results = await Promise.allSettled(promises);

          // Verify if any translation failed
          for (const result of results) {
            if (result.status === "rejected") {
              throw new Error(
                result.reason.message ||
                  "Quá trình dịch thuật song song gặp lỗi.",
              );
            } else {
              const { code, data } = result.value;
              currentTranslations[code] = data;
            }
          }
        }

        updatedTranslations = currentTranslations;
      }

      // Save to Firestore
      setStatusText("Đang lưu vào cơ sở dữ liệu...");
      const articleData = {
        title_vi: title,
        causes_vi: causes,
        steps_vi: steps,
        notes_vi: notes,
        imageUrl: imageUrl,
        pdfUrl: pdfUrl,
        videoUrl: videoUrl,
        translations: updatedTranslations,
        category: category,
        brand: brand,
        isPremium: isPremium,
        updatedAt: serverTimestamp(),
      };

      if (articleId) {
        // Edit existing article
        await updateDoc(doc(db, "articles", articleId), articleData);
        alert("Cập nhật bài viết thành công!");
      } else {
        // Create new article
        const newArticleData = {
          ...articleData,
          status: "active",
          createdAt: serverTimestamp(),
        };
        await addDoc(collection(db, "articles"), newArticleData);
        alert("Tạo bài viết thành công!");
      }

      router.push("/articles");
    } catch (error: any) {
      console.error(error);
      alert("Có lỗi xảy ra: " + error.message);
    } finally {
      setIsSaving(false);
      setStatusText("");
    }
  };

  const translateSingleLanguage = async (
    langCode: string,
    showSuccessAlert = true,
  ) => {
    if (!title || (!causes && !steps && !notes)) {
      alert(
        "Vui lòng nhập tiêu đề và ít nhất một phần nội dung Tiếng Việt trước khi dịch.",
      );
      return false;
    }

    const langName =
      languages.find((l) => l.code === langCode)?.name || langCode;
    setTranslatingLang(langCode);
    setStatusText(`Đang dịch sang ${langName}...`);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const translateRes = await fetch("/api/translate", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify({
          title,
          causes,
          steps,
          notes,
          aiModel: getActiveModel(),
          targetLang: langCode,
        }),
      });

      const responseData = await translateRes.json().catch(() => ({}));
      if (!translateRes.ok) {
        throw new Error(
          responseData.error || `Dịch thuật sang ${langName} thất bại.`,
        );
      }

      // Cập nhật state cục bộ
      const updatedTranslations = {
        ...translations,
        [langCode]: responseData,
      };
      setTranslations(updatedTranslations);

      // Nếu bài viết đã tồn tại trên Firestore (articleId có giá trị), lưu luôn vào DB
      if (articleId) {
        const docRef = doc(db, "articles", articleId);
        await updateDoc(docRef, {
          [`translations.${langCode}`]: responseData,
          updatedAt: serverTimestamp(),
        });
      }

      if (showSuccessAlert) {
        alert(`Dịch sang ${langName} thành công và đã tự động lưu!`);
      }
      return true;
    } catch (err: any) {
      console.error(err);
      alert(`Lỗi khi dịch sang ${langName}: ` + err.message);
      return false;
    } finally {
      setTranslatingLang(null);
      setStatusText("");
    }
  };

  const translateAllLanguages = async (onlyMissing = false) => {
    if (!title || (!causes && !steps && !notes)) {
      alert(
        "Vui lòng nhập tiêu đề và ít nhất một phần nội dung Tiếng Việt trước khi dịch.",
      );
      return;
    }

    const targetLangs = onlyMissing
      ? languages.filter((l) => !translations[l.code])
      : languages;

    if (targetLangs.length === 0) {
      alert("Tất cả các ngôn ngữ đã được dịch.");
      return;
    }

    let successCount = 0;
    let failCount = 0;

    const results = await Promise.all(
      targetLangs.map((lang) => translateSingleLanguage(lang.code, false)),
    );
    for (const success of results) {
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    alert(
      `Hoàn thành tiến trình dịch thuật!\n- Thành công: ${successCount}/${targetLangs.length}\n- Thất bại: ${failCount} (bạn có thể bấm dịch lại riêng các tiếng bị lỗi)`,
    );
  };

  return (
    <>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold tracking-tight">
          {articleId ? "Chỉnh sửa bài viết" : "Tạo bài viết mới"}
        </h1>
        <div className="flex gap-3 items-center">
          {statusText && (
            <span className="text-sm text-blue-600 animate-pulse">
              {statusText}
            </span>
          )}
          <Button
            variant="outline"
            onClick={() => router.push("/articles")}
            disabled={isSaving}
          >
            Hủy bỏ
          </Button>

          <Button
            onClick={() => handleSave(false)}
            disabled={
              isSaving ||
              isGeneratingAll ||
              isUploadingImage ||
              isUploadingPdf ||
              isUploadingVideo ||
              categories.length === 0 ||
              brands.length === 0
            }
          >
            {isSaving ? "Đang xử lý..." : "Lưu bài viết"}
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        <div className="md:col-span-2 space-y-6">
          {/* Vietnamese content */}
          <Card>
            <CardHeader>
              <CardTitle>Nội dung gốc (Tiếng Việt)</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <Label htmlFor="title-vi">Tiêu đề bài viết</Label>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="text-purple-600 border-purple-200 hover:bg-purple-50 dark:text-purple-400 dark:border-purple-900/50 dark:hover:bg-purple-950/20 gap-1.5 h-8 text-xs font-semibold"
                    onClick={handleGenerateAll}
                    disabled={
                      isGeneratingAll ||
                      isSaving ||
                      isUploadingImage ||
                      isUploadingPdf ||
                      isUploadingVideo
                    }
                  >
                    <Sparkles className="h-3.5 w-3.5" />
                    {isGeneratingAll
                      ? "AI đang soạn thảo..."
                      : "AI soạn nhanh toàn bài"}
                  </Button>
                </div>
                <Input
                  id="title-vi"
                  placeholder="Ví dụ: Mã lỗi E1 Điều hòa Daikin"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                />
              </div>

              {/* Causes */}
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <Label
                    htmlFor="causes-vi"
                    className="font-semibold text-orange-600 dark:text-orange-400"
                  >
                    1. Nguyên nhân
                  </Label>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-purple-600 hover:text-purple-800 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-950/20 gap-1 h-7 text-xs font-medium"
                    onClick={() => handleGenerateSection("causes")}
                    disabled={isGeneratingCauses || isSaving || isGeneratingAll}
                  >
                    <Wand2 className="h-3.5 w-3.5" />
                    {isGeneratingCauses ? "Đang viết..." : "AI viết hộ"}
                  </Button>
                </div>
                <textarea
                  ref={causesRef}
                  id="causes-vi"
                  className="w-full h-32 border rounded-md p-4 bg-white dark:bg-gray-950 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
                  placeholder="Nhập các nguyên nhân lỗi vào đây (hoặc click 'AI viết hộ' để sinh tự động)"
                  value={causes}
                  onChange={(e) => setCauses(e.target.value)}
                />
              </div>

              {/* Steps */}
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <Label
                    htmlFor="steps-vi"
                    className="font-semibold text-blue-600 dark:text-blue-400"
                  >
                    2. Hướng dẫn khắc phục (Quy trình sửa chữa)
                  </Label>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-purple-600 hover:text-purple-800 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-950/20 gap-1 h-7 text-xs font-medium"
                    onClick={() => handleGenerateSection("steps")}
                    disabled={isGeneratingSteps || isSaving || isGeneratingAll}
                  >
                    <Wand2 className="h-3.5 w-3.5" />
                    {isGeneratingSteps ? "Đang viết..." : "AI viết hộ"}
                  </Button>
                </div>
                <textarea
                  ref={stepsRef}
                  id="steps-vi"
                  className="w-full h-48 border rounded-md p-4 bg-white dark:bg-gray-950 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
                  placeholder="Nhập quy trình từng bước xử lý lỗi (hoặc click 'AI viết hộ' để sinh tự động)"
                  value={steps}
                  onChange={(e) => setSteps(e.target.value)}
                />
              </div>

              {/* Notes */}
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <Label
                    htmlFor="notes-vi"
                    className="font-semibold text-yellow-600 dark:text-yellow-400"
                  >
                    3. Lưu ý (Cảnh báo & Kinh nghiệm)
                  </Label>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-purple-600 hover:text-purple-800 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-950/20 gap-1 h-7 text-xs font-medium"
                    onClick={() => handleGenerateSection("notes")}
                    disabled={isGeneratingNotes || isSaving || isGeneratingAll}
                  >
                    <Wand2 className="h-3.5 w-3.5" />
                    {isGeneratingNotes ? "Đang viết..." : "AI viết hộ"}
                  </Button>
                </div>
                <textarea
                  ref={notesRef}
                  id="notes-vi"
                  className="w-full h-32 border rounded-md p-4 bg-white dark:bg-gray-950 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
                  placeholder="Nhập các lưu ý an toàn kỹ thuật (hoặc click 'AI viết hộ' để sinh tự động)"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                />
              </div>
            </CardContent>
          </Card>

          {/* Translation Preview Card */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-lg font-bold">
                Xem trước bản dịch đa ngôn ngữ
              </CardTitle>
              <div className="w-45">
                <Select
                  value={previewLang}
                  onValueChange={(val) => setPreviewLang(val || "en")}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Chọn ngôn ngữ" />
                  </SelectTrigger>
                  <SelectContent>
                    {languages.map((lang) => (
                      <SelectItem key={lang.code} value={lang.code}>
                        {lang.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {translations[previewLang] ? (
                <div className="space-y-4">
                  {/* Translated Title */}
                  <div className="space-y-2">
                    <Label>
                      Tiêu đề (
                      {languages.find((l) => l.code === previewLang)?.name})
                    </Label>
                    <Input
                      value={translations[previewLang]?.title || ""}
                      readOnly
                      className="bg-gray-50 dark:bg-gray-800 border-gray-200 font-medium"
                    />
                  </div>

                  {/* Translated Causes */}
                  <div className="space-y-2">
                    <label
                      htmlFor="previewCauses"
                      className="text-sm font-medium text-orange-600 dark:text-orange-400"
                    >
                      Nguyên nhân (
                      {languages.find((l) => l.code === previewLang)?.name})
                    </label>
                    <textarea
                      id="previewCauses"
                      className="w-full h-24 border rounded-md p-4 bg-gray-50 dark:bg-gray-800 border-gray-200 resize-none focus:outline-none font-mono text-sm"
                      value={translations[previewLang]?.causes || ""}
                      readOnly
                    />
                  </div>

                  {/* Translated Steps */}
                  <div className="space-y-2">
                    <label
                      htmlFor="previewSteps"
                      className="text-sm font-medium text-blue-600 dark:text-blue-400"
                    >
                      Khắc phục (
                      {languages.find((l) => l.code === previewLang)?.name})
                    </label>
                    <textarea
                      id="previewSteps"
                      className="w-full h-32 border rounded-md p-4 bg-gray-50 dark:bg-gray-800 border-gray-200 resize-none focus:outline-none font-mono text-sm"
                      value={translations[previewLang]?.steps || ""}
                      readOnly
                    />
                  </div>

                  {/* Translated Notes */}
                  <div className="space-y-2">
                    <label
                      htmlFor="previewNotes"
                      className="text-sm font-medium text-yellow-600 dark:text-yellow-400"
                    >
                      Lưu ý (
                      {languages.find((l) => l.code === previewLang)?.name})
                    </label>
                    <textarea
                      id="previewNotes"
                      className="w-full h-24 border rounded-md p-4 bg-gray-50 dark:bg-gray-800 border-gray-200 resize-none focus:outline-none font-mono text-sm"
                      value={translations[previewLang]?.notes || ""}
                      readOnly
                    />
                  </div>
                </div>
              ) : (
                <div className="py-8 px-4 text-center border-2 border-dashed rounded-md bg-amber-50/20 dark:bg-amber-950/10 border-amber-200 dark:border-amber-900/30 text-amber-600 dark:text-amber-400 text-sm">
                  Chưa có dữ liệu bản dịch cho ngôn ngữ này. Hãy bấm nút{" "}
                  <strong className="text-amber-700 dark:text-amber-500">
                    "Lưu & Dịch lại AI"
                  </strong>{" "}
                  ở trên để tạo bản dịch tự động bằng OpenRouter.
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          {/* AI Model Configuration Card */}
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="flex items-center gap-2 text-md">
                  <Sparkles className="h-5 w-5 text-purple-600 animate-pulse" />
                  Trợ lý AI (OpenRouter)
                </CardTitle>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => setIsManagingModels(!isManagingModels)}
                  className="text-xs text-purple-600 hover:text-purple-700 h-8 px-2"
                >
                  {isManagingModels ? "Đóng cài đặt" : "⚙️ Quản lý danh sách"}
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {isManagingModels ? (
                <div className="space-y-4 border rounded-md p-3 bg-gray-50 dark:bg-gray-950/50 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between border-b pb-2">
                    <span className="text-xs font-bold text-muted-foreground">
                      DANH SÁCH MODEL
                    </span>
                    <Button
                      type="button"
                      variant="link"
                      onClick={handleResetModels}
                      className="text-[10px] text-red-500 hover:text-red-700 h-auto p-0"
                    >
                      Khôi phục mặc định
                    </Button>
                  </div>

                  {/* Models List */}
                  <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                    {modelsList.length === 0 ? (
                      <p className="text-xs text-muted-foreground italic text-center py-2">
                        Chưa có model nào. Hãy thêm ở dưới.
                      </p>
                    ) : (
                      modelsList.map((model) => (
                        <div
                          key={model.id}
                          className="flex items-center justify-between gap-2 bg-white dark:bg-gray-900 border rounded p-2 text-xs"
                        >
                          <div className="overflow-hidden">
                            <span className="font-semibold block truncate">
                              {model.name}
                            </span>
                            <code className="text-[9px] text-muted-foreground block truncate">
                              {model.id}
                            </code>
                          </div>
                          <div className="flex gap-1 shrink-0">
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              disabled={testingModelId !== null}
                              onClick={() => handleTestModel(model.id)}
                              className="text-purple-600 border-purple-200 hover:bg-purple-50 h-7 px-2 text-[10px] font-semibold"
                            >
                              {testingModelId === model.id ? "Test..." : "Test"}
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="sm"
                              onClick={() => handleDeleteModel(model.id)}
                              className="text-red-500 hover:text-red-700 h-7 w-7 p-0 shrink-0"
                            >
                              <X className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </div>
                      ))
                    )}
                  </div>

                  {/* Add New Model Form */}
                  <div className="space-y-2 border-t pt-3">
                    <span className="text-xs font-bold text-muted-foreground block">
                      THÊM MODEL MỚI
                    </span>
                    <div className="space-y-1.5">
                      <Label htmlFor="new-model-name" className="text-[10px]">
                        Tên hiển thị
                      </Label>
                      <Input
                        id="new-model-name"
                        placeholder="Ví dụ: Llama 3.3 Free"
                        value={newModelName}
                        onChange={(e) => setNewModelName(e.target.value)}
                        className="h-8 text-xs"
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="new-model-id" className="text-[10px]">
                        OpenRouter Model ID (Slug)
                      </Label>
                      <Input
                        id="new-model-id"
                        placeholder="Ví dụ: meta-llama/llama-3.3-70b-instruct:free"
                        value={newModelId}
                        onChange={(e) => setNewModelId(e.target.value)}
                        className="h-8 text-xs"
                      />
                    </div>
                    <Button
                      type="button"
                      onClick={handleAddNewModel}
                      className="w-full h-8 text-xs bg-purple-600 hover:bg-purple-700 text-white"
                    >
                      + Thêm vào danh sách
                    </Button>
                  </div>
                </div>
              ) : (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="model-select">Chọn AI Model</Label>
                    <div className="flex gap-2">
                      <Select
                        value={selectedModel}
                        onValueChange={handleModelChange}
                      >
                        <SelectTrigger id="model-select" className="flex-1">
                          <SelectValue placeholder="Chọn AI Model" />
                        </SelectTrigger>
                        <SelectContent>
                          {modelsList.map((model) => (
                            <SelectItem key={model.id} value={model.id}>
                              {model.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => handleTestModel(selectedModel)}
                        disabled={testingModelId !== null}
                        className="px-3 text-xs shrink-0"
                      >
                        {testingModelId === selectedModel
                          ? "Đang test..."
                          : "Test kết nối"}
                      </Button>
                    </div>
                  </div>

                  <div className="text-xs rounded bg-gray-100 dark:bg-gray-850 p-2.5 text-muted-foreground">
                    <span className="font-semibold block text-[11px] mb-0.5">
                      Model đang kích hoạt:
                    </span>
                    <code className="text-[10px] bg-white dark:bg-gray-950 px-1 py-0.5 rounded border border-gray-200 dark:border-gray-800 block truncate font-mono">
                      {getActiveModel()}
                    </code>
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {/* AI Translation Manager Card */}
          <Card className="border-purple-100 dark:border-purple-900/30">
            <CardHeader className="pb-3">
              <CardTitle className="flex items-center gap-2 text-md">
                <Globe className="h-5 w-5 text-purple-600" />
                Quản lý Dịch thuật AI
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => translateAllLanguages(true)}
                  disabled={translatingLang !== null || isSaving}
                  className="text-xs flex-1 h-8 text-purple-600 border-purple-200 hover:bg-purple-50 font-semibold"
                >
                  Dịch tiếng chưa có
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => translateAllLanguages(false)}
                  disabled={translatingLang !== null || isSaving}
                  className="text-xs flex-1 h-8 text-red-600 border-red-200 hover:bg-red-50 font-semibold"
                >
                  Dịch lại toàn bộ
                </Button>
              </div>

              <div className="space-y-1.5 max-h-[300px] overflow-y-auto pr-1 border rounded p-2 bg-gray-50/50 dark:bg-gray-950/20">
                {languages.map((lang) => {
                  const isTranslated = !!translations[lang.code];
                  const isActive = translatingLang === lang.code;

                  return (
                    <div
                      key={lang.code}
                      className="flex items-center justify-between py-1.5 border-b last:border-0 border-gray-100 dark:border-gray-800 text-xs"
                    >
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-gray-700 dark:text-gray-300">
                          {lang.name}
                        </span>
                        {isTranslated ? (
                          <span className="bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 px-1.5 py-0.5 rounded text-[10px] font-bold">
                            Đã dịch
                          </span>
                        ) : (
                          <span className="bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-400 px-1.5 py-0.5 rounded text-[10px] font-semibold">
                            Chưa dịch
                          </span>
                        )}
                      </div>

                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        disabled={translatingLang !== null || isSaving}
                        onClick={() => translateSingleLanguage(lang.code, true)}
                        className={`h-7 px-2.5 text-[11px] font-bold ${
                          isTranslated
                            ? "text-gray-500 hover:text-purple-600 hover:bg-purple-50"
                            : "text-purple-600 hover:bg-purple-50"
                        }`}
                      >
                        {isActive ? (
                          <Loader2 className="h-3 w-3 animate-spin text-purple-600" />
                        ) : isTranslated ? (
                          "Dịch lại"
                        ) : (
                          "Dịch"
                        )}
                      </Button>
                    </div>
                  );
                })}
              </div>

              {translatingLang && (
                <div className="text-[11px] text-blue-600 dark:text-blue-400 animate-pulse text-center font-medium bg-blue-50 dark:bg-blue-950/20 p-2 rounded">
                  Đang xử lý dịch thuật, vui lòng chờ...
                </div>
              )}

              <div className="text-[10px] text-muted-foreground italic leading-relaxed">
                * Lưu ý: Mỗi ngôn ngữ sẽ được dịch và tự động lưu riêng lẻ trực
                tiếp vào cơ sở dữ liệu khi hoàn tất. Nếu một ngôn ngữ bị lỗi,
                tiến trình vẫn tiếp tục và bạn chỉ cần bấm "Dịch lại" ngôn ngữ
                đó mà không bị tốn thêm token của các ngôn ngữ khác.
              </div>
            </CardContent>
          </Card>

          {/* Settings Card */}
          <Card>
            <CardHeader>
              <CardTitle>Cài đặt chung</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Category Selector */}
              <div className="space-y-2">
                <Label>Chuyên mục</Label>
                {isLoadingCats ? (
                  <div className="text-sm text-muted-foreground animate-pulse py-2">
                    Đang tải chuyên mục...
                  </div>
                ) : categories.length === 0 ? (
                  <div className="space-y-2">
                    <p className="text-sm text-red-500 font-medium">
                      Chưa có chuyên mục nào được tạo.
                    </p>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => router.push("/categories")}
                    >
                      Tới trang tạo chuyên mục
                    </Button>
                  </div>
                ) : (
                  <Select
                    value={category}
                    onValueChange={(val) => setCategory(val || "")}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Chọn chuyên mục" />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.map((cat) => (
                        <SelectItem key={cat.id} value={cat.id}>
                          {cat.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              </div>

              {/* Brand Selector */}
              <div className="space-y-2">
                <Label>Hãng sản xuất</Label>
                {isLoadingBrands ? (
                  <div className="text-sm text-muted-foreground animate-pulse py-2">
                    Đang tải hãng sản xuất...
                  </div>
                ) : brands.length === 0 ? (
                  <div className="space-y-2">
                    <p className="text-sm text-red-500 font-medium">
                      Chưa có hãng sản xuất nào được tạo.
                    </p>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => router.push("/brands")}
                    >
                      Tới trang tạo hãng sản xuất
                    </Button>
                  </div>
                ) : (
                  <Select
                    value={brand}
                    onValueChange={(val) => setBrand(val || "")}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Chọn hãng sản xuất" />
                    </SelectTrigger>
                    <SelectContent>
                      {brands.map((b) => (
                        <SelectItem key={b.id} value={b.id}>
                          {b.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              </div>

              <div className="flex flex-row items-start space-x-3 space-y-0 rounded-md border p-4 mt-6 bg-yellow-50 dark:bg-yellow-900/10 border-yellow-200 dark:border-yellow-900">
                <Checkbox
                  id="premium"
                  className="data-[state=checked]:bg-yellow-500 data-[state=checked]:border-yellow-500"
                  checked={isPremium}
                  onCheckedChange={(checked) => setIsPremium(checked === true)}
                />
                <div className="space-y-1 leading-none">
                  <Label
                    htmlFor="premium"
                    className="font-bold text-yellow-700 dark:text-yellow-500"
                  >
                    Nội dung Premium (VIP)
                  </Label>
                  <p className="text-sm text-yellow-600 dark:text-yellow-600/80">
                    Người dùng miễn phí sẽ không thể xem nội dung này.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Image Upload Card */}
          <Card>
            <CardHeader>
              <CardTitle>Hình ảnh sơ đồ / Bảng mã lỗi</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {imageUrl ? (
                <div className="space-y-3">
                  <div className="relative group border rounded-md overflow-hidden bg-white dark:bg-gray-950">
                    <Image
                      src={imageUrl}
                      alt="Uploaded preview"
                      className="w-full h-48 object-cover group-hover:opacity-75 transition-opacity"
                    />
                    <button
                      type="button"
                      onClick={() => setImageUrl("")}
                      className="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full p-1.5 shadow-md focus:outline-none transition-colors"
                      title="Xóa hình ảnh"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>

                  {/* Copy and quick insert controls */}
                  <div className="space-y-2">
                    <p className="text-[10px] text-muted-foreground truncate font-mono bg-gray-100 dark:bg-gray-800 p-2 rounded border border-gray-200 dark:border-gray-700">
                      {imageUrl}
                    </p>
                    <div className="grid grid-cols-2 gap-1.5">
                      <Button
                        type="button"
                        variant="secondary"
                        className="h-7 px-2 text-xs font-semibold col-span-2"
                        onClick={() => {
                          navigator.clipboard.writeText(imageUrl);
                          alert("Đã sao chép link ảnh vào bộ nhớ tạm!");
                        }}
                      >
                        Sao chép link hình ảnh
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-orange-600 border-orange-200 hover:bg-orange-50 hover:text-orange-700"
                        onClick={() =>
                          insertTextAtCursor("causes", `![img](${imageUrl})`)
                        }
                      >
                        + Chèn Nguyên nhân
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-blue-600 border-blue-200 hover:bg-blue-50 hover:text-blue-700"
                        onClick={() =>
                          insertTextAtCursor("steps", `![img](${imageUrl})`)
                        }
                      >
                        + Chèn Khắc phục
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-yellow-600 border-yellow-200 hover:bg-yellow-50 hover:text-yellow-700 col-span-2"
                        onClick={() =>
                          insertTextAtCursor("notes", `![img](${imageUrl})`)
                        }
                      >
                        + Chèn Lưu ý an toàn
                      </Button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-800 rounded-md p-6 bg-white dark:bg-gray-950/50 hover:bg-gray-50 dark:hover:bg-gray-950 transition-colors">
                  <ImageIcon className="h-10 w-10 text-muted-foreground mb-2" />
                  <p className="text-sm font-medium text-muted-foreground mb-1">
                    Kéo thả hoặc chọn ảnh
                  </p>
                  <p className="text-xs text-muted-foreground italic mb-4">
                    PNG, JPG hoặc JPEG (Tối đa 5MB)
                  </p>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageChange}
                    disabled={isUploadingImage || isSaving || isGeneratingAll}
                    className="hidden"
                    id="image-file-input"
                    aria-label="Upload image"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() =>
                      document.getElementById("image-file-input")?.click()
                    }
                    disabled={isUploadingImage || isSaving || isGeneratingAll}
                    className="gap-1.5"
                  >
                    <Upload className="h-3.5 w-3.5" />
                    {isUploadingImage ? "Đang tải lên..." : "Chọn tệp hình ảnh"}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* PDF Document Upload Card */}
          <Card>
            <CardHeader>
              <CardTitle>Tài liệu kỹ thuật (PDF)</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {pdfUrl ? (
                <div className="space-y-3 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between border rounded-md p-3 bg-white dark:bg-gray-950">
                    <div className="flex items-center gap-2 overflow-hidden mr-2">
                      <FileText className="h-8 w-8 text-red-600 shrink-0" />
                      <div className="overflow-hidden">
                        <p className="text-xs font-semibold truncate">
                          Tài liệu đã đính kèm
                        </p>
                        <a
                          href={pdfUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[10px] text-blue-600 hover:underline truncate block"
                        >
                          Xem tài liệu
                        </a>
                      </div>
                    </div>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => setPdfUrl("")}
                      className="text-red-600 hover:text-red-800"
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>

                  {/* Copy and quick insert controls for PDF */}
                  <div className="space-y-2">
                    <div className="grid grid-cols-2 gap-1.5">
                      <Button
                        type="button"
                        variant="secondary"
                        className="h-7 px-2 text-xs font-semibold col-span-2"
                        onClick={() => {
                          navigator.clipboard.writeText(pdfUrl);
                          alert("Đã sao chép link tài liệu vào bộ nhớ tạm!");
                        }}
                      >
                        Sao chép link tài liệu
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-orange-600 border-orange-200 hover:bg-orange-50 hover:text-orange-700"
                        onClick={() =>
                          insertTextAtCursor("causes", `[pdf](${pdfUrl})`)
                        }
                      >
                        + Chèn Nguyên nhân
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-blue-600 border-blue-200 hover:bg-blue-50 hover:text-blue-700"
                        onClick={() =>
                          insertTextAtCursor("steps", `[pdf](${pdfUrl})`)
                        }
                      >
                        + Chèn Khắc phục
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        className="h-7 px-2 text-xs font-medium text-yellow-600 border-yellow-200 hover:bg-yellow-50 hover:text-yellow-700 col-span-2"
                        onClick={() =>
                          insertTextAtCursor("notes", `[pdf](${pdfUrl})`)
                        }
                      >
                        + Chèn Lưu ý an toàn
                      </Button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-800 rounded-md p-6 bg-white dark:bg-gray-950/50 hover:bg-gray-50 dark:hover:bg-gray-950 transition-colors">
                  <FileText className="h-10 w-10 text-muted-foreground mb-2" />
                  <p className="text-sm font-medium text-muted-foreground mb-1">
                    Tải lên tệp PDF của hãng
                  </p>
                  <p className="text-xs text-muted-foreground italic mb-4">
                    Định dạng .pdf (Tối đa 15MB)
                  </p>
                  <input
                    type="file"
                    accept="application/pdf"
                    onChange={handlePdfChange}
                    disabled={isUploadingPdf || isSaving || isGeneratingAll}
                    className="hidden"
                    id="pdf-file-input"
                    aria-label="Upload PDF"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() =>
                      document.getElementById("pdf-file-input")?.click()
                    }
                    disabled={isUploadingPdf || isSaving || isGeneratingAll}
                    className="gap-1.5"
                  >
                    <Upload className="h-3.5 w-3.5" />
                    {isUploadingPdf ? "Đang tải lên..." : "Chọn tệp PDF"}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Video Upload Card */}
          <Card>
            <CardHeader>
              <CardTitle>Video/Clip thực tế (MP4/MOV)</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {videoUrl ? (
                <div className="space-y-3">
                  <div className="relative border rounded-md overflow-hidden bg-black aspect-video flex items-center justify-center">
                    <video
                      src={videoUrl}
                      controls
                      className="w-full h-full object-contain"
                    />
                    <button
                      type="button"
                      onClick={() => setVideoUrl("")}
                      className="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full p-1.5 shadow-md focus:outline-none transition-colors"
                      title="Xóa Video"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                  <p className="text-[10px] text-muted-foreground truncate font-mono bg-gray-100 dark:bg-gray-800 p-2 rounded border">
                    {videoUrl}
                  </p>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center border-2 border-dashed border-gray-300 dark:border-gray-800 rounded-md p-6 bg-white dark:bg-gray-950/50 hover:bg-gray-50 dark:hover:bg-gray-950 transition-colors">
                  <Video className="h-10 w-10 text-muted-foreground mb-2" />
                  <p className="text-sm font-medium text-muted-foreground mb-1">
                    Tải lên video hướng dẫn
                  </p>
                  <p className="text-xs text-muted-foreground italic mb-4">
                    Các định dạng video (Tối đa 30MB)
                  </p>
                  <input
                    type="file"
                    accept="video/*"
                    onChange={handleVideoChange}
                    disabled={isUploadingVideo || isSaving || isGeneratingAll}
                    className="hidden"
                    id="video-file-input"
                    aria-label="Upload video"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() =>
                      document.getElementById("video-file-input")?.click()
                    }
                    disabled={isUploadingVideo || isSaving || isGeneratingAll}
                    className="gap-1.5"
                  >
                    <Upload className="h-3.5 w-3.5" />
                    {isUploadingVideo ? "Đang tải lên..." : "Chọn tệp Video"}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
}

export default function EditorPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-screen w-full items-center justify-center bg-gray-50 dark:bg-gray-900">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      }
    >
      <EditorContent />
    </Suspense>
  );
}
