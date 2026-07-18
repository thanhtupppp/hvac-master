export interface AiModelOption {
  id: string;
  name: string;
}

export const DEFAULT_AI_MODELS: AiModelOption[] = [
  { id: "google/gemini-2.5-flash", name: "Google: Gemini 2.5 Flash" },
  { id: "meta-llama/llama-3.3-70b-instruct:free", name: "Meta: Llama 3.3 70B (Free)" },
  { id: "google/gemini-2.5-pro", name: "Google: Gemini 2.5 Pro" },
  { id: "deepseek/deepseek-chat", name: "DeepSeek: V3" },
];

export const AI_MODELS_STORAGE_KEY = "hvac_ai_models_list";
export const AI_MODEL_SELECTED_KEY = "hvac_ai_model";
