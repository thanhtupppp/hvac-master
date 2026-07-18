export interface LanguageOption {
  code: string;
  name: string;
}

export const SUPPORTED_LANGUAGES: LanguageOption[] = [
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
