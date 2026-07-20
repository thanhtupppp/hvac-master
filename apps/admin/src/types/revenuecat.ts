export interface RevenueCatSubscriber {
  app_user_id: string;
  subscriptions: {
    product_identifier: string;
    auto_expiry_date_ms: number | null;
    purchase_date_ms: number;
    store: string;
    is_sandbox: boolean;
    is_trial_conversion: boolean;
    period_type: string;
    auto_renewing: boolean;
    grace_period_expires_date_ms?: number;
  }[];
  other_purchases: Record<string, any>;
  entitlement_ids: string[];
  first_seen_ms: number;
  last_seen_ms: number;
}

export interface RevenueCatAnalytics {
  activeEntitlements: number;
  mrrCents: number;
  mrrFormatted: string;
  annualRecurringRevenueCents: number;
  arrFormatted: string;
  subscribersCount: number;
  trialCount: number;
  cancelledCount: number;
  gracePeriodCount: number;
  topProducts: { productId: string; count: number; revenueCents: number }[];
  currencyBreakdown: Record<string, number>;
  generatedAt: string;
}
