# Hướng dẫn cấu hình Google Play IAP

---

## Bước 1 — Lấy `GOOGLE_PLAY_PACKAGE_NAME`

Đây là **Application ID** của Android app, dạng `com.example.app`.

Tìm ở một trong các chỗ sau:

- File `android/app/build.gradle` → trường `applicationId`
- Google Play Console → chọn app → **Xem trong URL**: `https://play.google.com/console/u/0/developers/.../app/**4972349723**/...`
- Hoặc tab **Dashboard** → tên package dưới tên app

```
GOOGLE_PLAY_PACKAGE_NAME=com.hvacpro.app
```

---

## Bước 2 — Tạo Service Account & lấy `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`

### 2a. Tạo Service Account trong Google Cloud Console

1. Truy cập: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Chọn đúng project (cùng project với Firebase)
3. Nhấn **"Create Service Account"**
4. Đặt tên, ví dụ: `hvac-play-billing`
5. Nhấn **Done** (không cần gán role ngay)

### 2b. Tạo JSON Key

1. Click vào service account vừa tạo
2. Tab **"Keys"** → **"Add Key"** → **"Create new key"**
3. Chọn **JSON** → **Create**
4. File `.json` sẽ tự download về máy

### 2c. Cấp quyền trong Google Play Console

1. Vào: https://play.google.com/console/developers
2. **Setup** → **API access** (góc trái dưới)
3. Nếu chưa link Google Cloud project → nhấn **Link to existing project** → chọn đúng project
4. Tìm service account vừa tạo → nhấn **"Grant access"**
5. Cấp quyền: **"View financial data"** + **"Manage orders and subscriptions"**
6. Nhấn **Apply**

> [!IMPORTANT]
> Thay đổi quyền trong Play Console mất đến **24–48 giờ** để có hiệu lực.

### 2d. Điền vào .env.local

Mở file JSON download về, **minify thành 1 dòng** (xóa tất cả xuống dòng), dán vào:

```
GOOGLE_PLAY_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"hvac-master-33635","private_key_id":"abc123","private_key":"-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n","client_email":"hvac-play-billing@hvac-master-33635.iam.gserviceaccount.com","client_id":"...","auth_uri":"...","token_uri":"..."}
```

> [!TIP]
> Để minify nhanh, dùng: https://jsonformatter.org/json-minify
> Hoặc terminal: `cat service-account.json | python -c "import json,sys; print(json.dumps(json.load(sys.stdin)))"`

---

## Bước 3 — Cấu hình `GOOGLE_PUBSUB_TOKEN`

Đây là chuỗi bí mật **tự đặt** dùng để xác thực Pub/Sub push tới webhook của anh.

```
GOOGLE_PUBSUB_TOKEN=hvac-iap-webhook-secret-2024
```

> [!NOTE]
> Đặt chuỗi dài, ngẫu nhiên. Không dùng các chuỗi đơn giản như `123456`.
> Cách tạo nhanh: `openssl rand -hex 32`

---

## Bước 4 — Cấu hình Google Cloud Pub/Sub

### 4a. Tạo Pub/Sub Topic

1. Vào: https://console.cloud.google.com/cloudpubsub/topic
2. **"Create Topic"**
3. Topic ID: `google-play-rtdn`
4. Nhấn **Create**

### 4b. Cấp quyền cho Google Play gửi notification vào topic

Pub/Sub console → chọn topic vừa tạo → tab **"Permissions"** → **"Add principal"**:

```
Principal: google-play-developer-notifications@system.gserviceaccount.com
Role: Pub/Sub Publisher
```

### 4c. Tạo Subscription push

1. Chọn topic `google-play-rtdn` → **"Create subscription"**
2. Delivery type: **Push**
3. Endpoint URL:

```
https://your-domain.com/api/webhooks/google-play?token=hvac-iap-webhook-secret-2024
```

4. Nhấn **Create**

> [!IMPORTANT]
> URL phải là **HTTPS công khai** — không dùng được localhost.
> Khi dev local: dùng `ngrok http 3000` để có URL tạm thời.

### 4d. Kết nối Pub/Sub vào Google Play Console

1. Google Play Console → **Monetize** → **Monetization setup**
2. Mục **"Real-time developer notifications"**
3. Dán **Topic name** (dạng `projects/hvac-master-33635/topics/google-play-rtdn`)
4. Nhấn **Save** → **"Send test notification"** để test

---

## Bước 5 — Cấu hình Android App (BillingFlowParams)

Trong code Android, khi gọi `launchBillingFlow`, **bắt buộc** truyền Firebase UID vào `obfuscatedExternalAccountId` để webhook map đúng user:

```kotlin
// Kotlin (Android)
val billingFlowParams = BillingFlowParams.newBuilder()
    .setProductDetailsParamsList(
        listOf(
            BillingFlowParams.ProductDetailsParams.newBuilder()
                .setProductDetails(productDetails)
                .setOfferToken(selectedOfferToken)
                .build()
        )
    )
    .setObfuscatedAccountId(firebaseUid) // ← Firebase UID của user đang đăng nhập
    .build()

billingClient.launchBillingFlow(activity, billingFlowParams)
```

Lấy Firebase UID:

```kotlin
val firebaseUid = FirebaseAuth.getInstance().currentUser?.uid ?: return
```

> [!WARNING]
> Nếu không set `obfuscatedAccountId`, webhook sẽ không biết gán quyền VIP cho user nào.
> Trong trường hợp đó, admin phải sync thủ công qua trang `/payments`.

---

## Bước 6 — Kiểm tra tích hợp

### Test webhook thủ công (curl)

```bash
curl -X POST "https://your-domain.com/api/webhooks/google-play?token=hvac-iap-webhook-secret-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "data": "eyJwYWNrYWdlTmFtZSI6ImNvbS5odmFjcHJvLmFwcCIsInN1YnNjcmlwdGlvbk5vdGlmaWNhdGlvbiI6eyJzdWJzY3JpcHRpb25JZCI6Imh2YWNfcHJlbWl1bV9tb250aGx5IiwicHVyY2hhc2VUb2tlbiI6InRlc3QtdG9rZW4iLCJub3RpZmljYXRpb25UeXBlIjoxfX0="
    }
  }'
```

### Hoặc dùng trang Admin `/payments`

1. Mở `/payments` trong browser
2. Nhấn **"Sync thủ công"**
3. Nhập `purchaseToken` và `productId` từ Google Play Console (tab **Orders**)
4. Nhấn **Xác nhận Sync** → xem kết quả

---

## Tóm tắt biến môi trường cần điền

```env
GOOGLE_PLAY_PACKAGE_NAME=com.hvacpro.app
GOOGLE_PLAY_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
GOOGLE_PUBSUB_TOKEN=hvac-iap-webhook-secret-2024
```
