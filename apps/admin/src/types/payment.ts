export interface Payment {
  id: string;
  userId: string;
  userEmail: string;
  orderId: string;
  purchaseToken: string;
  productId: string;
  purchaseType: "subscription" | "inapp";
  status: "pending" | "active" | "expired" | "cancelled" | "refunded";
  amount: number; // VND
  currency: string;
  autoRenewing?: boolean;
  expiryTime?: any; // Firestore Timestamp
  purchaseTime: any;
  verifiedAt?: any;
  rawNotification?: object;
}

export interface PaymentStats {
  activeSubscribers: number;
  revenueThisMonth: number;
  newThisWeek: number;
  pendingCount: number;
}
