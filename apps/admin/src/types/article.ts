export interface Article {
  id: string;
  title_vi: string;
  title_en?: string;
  category: string;
  brand: string;
  isPremium: boolean;
  causes_vi?: string;
  steps_vi?: string;
  notes_vi?: string;
  imageUrl?: string;
  pdfUrl?: string;
  videoUrl?: string;
  translations?: Record<string, TranslatedContent>;
  views?: number;
  createdAt?: any;
  updatedAt?: any;
}

/** Minimal Article for list views (Dashboard, Articles page) */
export interface ArticleListItem {
  id: string;
  titleVi: string;
  category: string;
  brand: string;
  isPremium: boolean;
  views?: number;
  createdAt?: any;
}

export interface TranslatedContent {
  title: string;
  causes: string;
  steps: string;
  notes: string;
}
