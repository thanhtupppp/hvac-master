/**
 * Seed default subscription plans.
 *
 * Run via: node apps/admin/scripts/seed-plans.mjs
 *
 * Requires: GOOGLE_APPLICATION_CREDENTIALS env var OR
 *           firebase-admin running in emulator with project ID.
 *
 * Idempotent: only inserts plans whose planCode doesn't exist yet.
 */
import admin from "firebase-admin";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, resolve } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Initialize admin SDK using service account JSON
const serviceAccountPath = resolve(__dirname, "../../service-account.json");
let credential;

try {
  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, "utf8"));
  credential = admin.credential.cert(serviceAccount);
} catch {
  // Fall back to application default credentials
  credential = admin.credential.applicationDefault();
}

if (!admin.apps.length) {
  admin.initializeApp({ credential });
}

const db = admin.firestore();

const DEFAULT_PLANS = [
  {
    planCode: "vip_monthly",
    entitlementId: "vip",
    name: "VIP 1 Tháng",
    nameEn: "VIP Monthly",
    description: "Truy cập toàn bộ nội dung VIP 30 ngày",
    priceVND: 99000,
    priceUSD: 3.99,
    interval: "monthly",
    durationDays: 30,
    trialDays: 0,
    productId: "hvac_vip_monthly",
    provider: "google_play",
    features: [
      "Xem toàn bộ mã lỗi chi tiết",
      "Bài viết premium & hướng dẫn chuyên sâu",
      "Tools tính toán không giới hạn",
      "Lưu bookmark & đọc offline",
    ],
    isFeatured: false,
    sortOrder: 10,
    isActive: true,
    theme: "blue",
  },
  {
    planCode: "vip_quarterly",
    entitlementId: "vip",
    name: "VIP 3 Tháng",
    nameEn: "VIP Quarterly",
    description: "Tiết kiệm 15% so với gói tháng",
    priceVND: 250000,
    priceUSD: 9.99,
    interval: "quarterly",
    durationDays: 90,
    trialDays: 7,
    productId: "hvac_vip_quarterly",
    provider: "google_play",
    features: [
      "Toàn bộ quyền lợi VIP Monthly",
      "🎁 Dùng thử miễn phí 7 ngày",
      "Tiết kiệm 15% chi phí",
      "Hỗ trợ ưu tiên 24/7",
    ],
    isFeatured: false,
    sortOrder: 20,
    isActive: true,
    badge: "Tiết kiệm 15%",
    theme: "purple",
  },
  {
    planCode: "vip_yearly",
    entitlementId: "vip",
    name: "VIP 1 Năm",
    nameEn: "VIP Yearly",
    description: "Tiết kiệm 30% — gói phổ biến nhất",
    priceVND: 799000,
    priceUSD: 29.99,
    interval: "yearly",
    durationDays: 365,
    trialDays: 14,
    productId: "hvac_vip_yearly",
    provider: "google_play",
    features: [
      "Toàn bộ quyền lợi VIP",
      "🎁 Dùng thử miễn phí 14 ngày",
      "Tiết kiệm 30% so với gói tháng",
      "Cập nhật sớm tính năng mới",
      "Hỗ trợ VIP ưu tiên",
    ],
    isFeatured: true,
    sortOrder: 30,
    isActive: true,
    badge: "Phổ biến nhất",
    theme: "gold",
  },
];

async function seed() {
  console.log(`🌱 Seeding ${DEFAULT_PLANS.length} default plans...`);

  for (const plan of DEFAULT_PLANS) {
    const existing = await db
      .collection("subscription_plans")
      .where("planCode", "==", plan.planCode)
      .limit(1)
      .get();

    if (!existing.empty) {
      console.log(`  ⏭️  ${plan.planCode} already exists, skipping`);
      continue;
    }

    await db.collection("subscription_plans").add({
      ...plan,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✅ Created ${plan.planCode}: ${plan.name}`);
  }

  console.log("✅ Done");
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});
