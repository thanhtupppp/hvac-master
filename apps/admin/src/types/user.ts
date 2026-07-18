export interface User {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  isPremium: boolean;
  premiumExpiry?: any; // Firestore Timestamp
  activeSubscriptionId?: string;
  status: "active" | "disabled";
  createdAt?: any;
  updatedAt?: any;
}

export interface UserListItem {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  isPremium: boolean;
  premiumExpiry?: any;
  status: "active" | "disabled";
  createdAt?: any;
}
