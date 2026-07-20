export type PlanInterval = "monthly" | "quarterly" | "yearly" | "lifetime";
export type PlanProvider = "google_play" | "app_store" | "web";

export interface SubscriptionPlan {
  id: string;

  /** RevenueCat entitlement id (e.g. "vip"). Required if any product is bound. */
  entitlementId?: string;

  /** Plan code — stable identifier used by mobile app (e.g. "vip_monthly"). */
  planCode: string;

  /** Display name in Vietnamese. */
  name: string;

  /** Display name in English (optional, for i18n). */
  nameEn?: string;

  /** Short description shown in paywall. */
  description?: string;

  /** Price in VND — the local currency display price. */
  priceVND: number;

  /** Price in USD — for international users / store prices. */
  priceUSD?: number;

  /** Billing interval. */
  interval: PlanInterval;

  /** Number of days the subscription lasts. Required for non-lifetime intervals. */
  durationDays?: number;

  /** Trial period in days (e.g. 7 for free trial). 0 = no trial. */
  trialDays: number;

  /** Product id on the store — must match exactly. */
  productId: string;

  /** Which store / provider sells this plan. */
  provider: PlanProvider;

  /** List of perks shown in the paywall (one per line). */
  features: string[];

  /** Highlight this plan as "Best value" or "Phổ biến nhất" in the paywall. */
  isFeatured: boolean;

  /** Display order in the paywall (lower = first). */
  sortOrder: number;

  /** Whether this plan is currently sellable. */
  isActive: boolean;

  /** Optional badge label (e.g. "Tiết kiệm 30%", "Phổ biến"). */
  badge?: string;

  /** Color theme: blue (default), purple, gold (VIP). */
  theme?: "blue" | "purple" | "gold";

  /** Internal note for admins (not shown on mobile). */
  internalNote?: string;

  createdAt?: any;
  updatedAt?: any;
}

export interface PlanStats {
  total: number;
  active: number;
  inactive: number;
  byProvider: Record<PlanProvider, number>;
  byInterval: Record<PlanInterval, number>;
}
