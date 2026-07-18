/** Default category key → display name mapping */
export const DEFAULT_CATEGORIES: Record<string, string> = {
  ac: "Điều hòa",
  fridge: "Tủ lạnh",
  "washing-machine": "Máy giặt",
  microwave: "Lò vi sóng",
};

/** Get category display name from key, with fallback */
export function getCategoryName(
  catKey: string,
  categoriesMap: Record<string, string> = {}
): string {
  return categoriesMap[catKey] || DEFAULT_CATEGORIES[catKey] || catKey;
}
