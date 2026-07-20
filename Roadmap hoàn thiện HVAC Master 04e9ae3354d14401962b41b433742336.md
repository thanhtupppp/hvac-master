# Roadmap hoàn thiện HVAC Master

<aside>
📌

Checklist tổng hợp từ phân tích mã nguồn repo `thanhtupppp/hvac-master` (Next.js Admin + Flutter Mobile + Firebase). Xếp theo ưu tiên: **P0** = chặn ra mắt / bảo mật, **P1** = cần cho sản phẩm hoàn chỉnh, **P2** = vận hành & tăng trưởng.

</aside>

# 🔴 P0 — Bảo mật & chặn ra mắt

## Vá lỗ hổng bảo mật

- [ ]  **Chặn user tự cấp VIP trong `firestore.rules`** — rule `users/{userId}` đang cho user ghi mọi field. Thêm điều kiện: `request.resource.data.diff(resource.data).affectedKeys().hasAny(['isPremium','premiumExpiry','activeSubscriptionId']) == false`, hoặc tách entitlement sang collection chỉ Admin SDK ghi được, hoặc dùng custom claims.
- [ ]  **Bảo vệ nội dung VIP phía server** — `articles` đang `allow read: if true`, ai cũng đọc được bài premium qua Firestore SDK/REST. Tách phần nội dung premium sang subcollection có rule kiểm tra `isPremium`, hoặc phát nội dung qua API có kiểm tra quyền.
- [ ]  **Đổi xác thực webhook Google Play** — bỏ shared secret trên query string (`?token=`, dễ lộ qua access log), chuyển sang Pub/Sub OIDC push authentication (verify JWT của Google).

## Sửa bug logic thanh toán

- [ ]  **`PATCH /api/users`**: sửa điều kiện `!isPremium` → `isPremium === false` (hiện chỉ đổi `status` cũng xoá mất `premiumExpiry` của user).
- [ ]  **Key payment doc theo `purchaseToken` (hash)** thay vì `latestOrderId` — mỗi kỳ gia hạn Google sinh orderId mới → trùng lặp doc, doc cũ kẹt `active`, thống kê sai.
- [ ]  **Cấp VIP cho giao dịch one-time**: nhánh `inapp` không set `expiryTime` nên điều kiện cấp VIP không bao giờ đúng; webhook one-time cũng chưa **acknowledge** (Google tự refund sau 3 ngày) và chưa cập nhật user.
- [ ]  **Sửa `autoRenewing`**: đọc từ `lineItems[].autoRenewingPlan` thay vì suy từ `subscriptionState === ACTIVE`.
- [ ]  **Fix search sau limit** (users & payments API): đang lấy 100–200 doc mới nhất rồi mới filter → không tìm được bản ghi cũ.

## Luồng mua VIP trên app (chưa tồn tại)

- [ ]  **Màn hình Paywall / mua gói VIP** — `purchases_flutter` đã khai báo nhưng chưa có route/screen nào. Thiết kế màn hình gói + giá, CTA từ nội dung bị khoá.
- [ ]  **Gắn `obfuscatedExternalAccountId = uid`** khi mua để webhook map được giao dịch với user.
- [ ]  **Nút "Khôi phục giao dịch" (Restore purchases)** — Google Play bắt buộc.
- [ ]  **Quyết định kiến trúc thanh toán**: dùng hẳn RevenueCat (đang có sẵn package) *hoặc* tự quản lý qua webhook — hiện tồn tại song song 2 hướng, dễ lệch trạng thái.
- [ ]  **Cron hạ cấp VIP hết hạn** — Cloud Function scheduled quét `premiumExpiry < now` hằng ngày; đối soát refund bằng Voided Purchases API.

## Tuân thủ Google Play

- [ ]  Màn hình / link **Chính sách bảo mật** và **Điều khoản sử dụng**.
- [ ]  **URL xoá tài khoản công khai** (chính sách Play 2024+); sửa `deleteAccount()` để xoá thật dữ liệu Firestore (bookmarks, history) thay vì chỉ đánh dấu `deleted_request`.
- [ ]  Hoàn thiện **file dịch i18n** (`en-US.json`, `vi-VN.json` đang rỗng `{}`) hoặc gỡ easy_localization.

# 🟠 P1 — Tính năng còn thiếu

## App user (Flutter)

- [ ]  **Tìm kiếm toàn văn mã lỗi/bài viết** — tích hợp Algolia/Typesense/Meilisearch (Firestore không hỗ trợ full-text); đây là use-case cốt lõi của thợ điện lạnh.
- [ ]  **Push notification** (`firebase_messaging`): bài mới theo hãng quan tâm, nhắc VIP sắp hết hạn.
- [ ]  **Đọc offline** cho bài đã bookmark (điểm bán VIP tự nhiên — thợ hay làm việc nơi sóng yếu).
- [ ]  **Tương tác nội dung**: đánh giá hữu ích, báo lỗi nội dung, chia sẻ bài viết (deep link).
- [ ]  **Flow tài khoản đầy đủ**: quên mật khẩu, xác minh email, đổi mật khẩu, re-auth trước hành động nhạy cảm.
- [ ]  **Lưu lịch sử/ghi chú tính toán** trong Tools theo công trình.
- [ ]  **iOS IAP** nếu phát hành iOS: App Store Server Notifications hoặc RevenueCat cho cả 2 store.

## Admin (Next.js)

- [ ]  **Quản lý admin trong UI** (thêm/xoá/khoá admin) — hiện phải sửa tay collection `admins` trong Firebase Console.
- [ ]  **Quy trình nội dung**: trạng thái Draft → Review → Published, xem trước trên mobile, lên lịch đăng.
- [ ]  **Dashboard phân tích**: lượt xem theo bài/hãng, tăng trưởng user, doanh thu theo tháng, tỷ lệ chuyển đổi VIP (map giá gói vào `amount` — hiện luôn = 0).
- [ ]  **Phân quyền vai trò** (editor / moderator / super admin) + **audit log** hành động admin (đặc biệt cấp VIP tay).
- [ ]  **Gửi push notification** từ admin theo segment.
- [ ]  **Thư viện media** Cloudinary (xem/xoá/tái sử dụng asset).
- [ ]  **Import/export CSV** cho mã lỗi, backup dữ liệu.
- [ ]  **Hàng đợi xử lý báo lỗi nội dung** từ user.

# 🟡 P2 — Hạ tầng & hiệu năng

## Vận hành

- [ ]  **Crashlytics + Firebase Analytics** (chưa có package nào — bắt buộc cho production).
- [ ]  **Remote Config / force update** phiên bản cũ.
- [ ]  **App Check** chống abuse Firestore/API.
- [ ]  **Email giao dịch**: chào mừng, xác nhận thanh toán, nhắc gia hạn.
- [ ]  **Test + CI/CD** (GitHub Actions: `flutter analyze`, `next lint`, `tsc --noEmit`) + môi trường staging.
- [ ]  **README root** + tài liệu env vars (`FIREBASE_SERVICE_ACCOUNT_KEY`, `GOOGLE_PUBSUB_TOKEN`, `OPENROUTER_API_KEY`, `CLOUDINARY_*`...).

## Hiệu năng

- [ ]  **Stats `/api/payments` dùng aggregation `count()`/`sum()`** thay vì đọc toàn bộ collection mỗi request.
- [ ]  **Custom claims cho admin** — bỏ 1 lần đọc Firestore mỗi API call trong `requireAdmin` và `isAdmin()` của rules.
- [ ]  **Chuyển `libCoolProp.so` (2×24 MB) sang Git LFS**; bổ sung ABI `armeabi-v7a` (thiết bị 32-bit sẽ crash FFI); ship bằng App Bundle để split ABI; cân nhắc bỏ `x86_64` khỏi release.
- [ ]  **Nén ảnh asset**: `logo.png` 742 KB, `google_logo.png` 465 KB → WebP vài chục KB.
- [ ]  **Tách nhỏ component admin**: `editor/page.tsx` 65 KB, `home_screen.dart` 49 KB — tách widget/component, dùng RSC + `dynamic()` import cho editor.
- [ ]  **Xoá shim `coolprop.dart` deprecated** (đang `throw UnimplementedError` — caller cũ sẽ crash runtime).
- [ ]  **Monorepo tooling**: npm/pnpm workspaces + Turborepo.

---

# 📋 Thứ tự triển khai gợi ý

| Sprint | Hạng mục | Kết quả |
| --- | --- | --- |
| 1 | Vá rules VIP + bug thanh toán | Chống thất thoát doanh thu |
| 2 | Paywall + restore + cron hết hạn | Bắt đầu có doanh thu |
| 3 | Pháp lý + i18n + Crashlytics/Analytics | Đủ điều kiện lên Google Play |
| 4 | Tìm kiếm + Push notification | Giá trị cốt lõi & giữ chân |
| 5 | Draft/preview, quản lý admin, audit log | Vận hành nội dung quy mô lớn |
| 6 | Hiệu năng + CI/CD + tài liệu | Nền tảng dài hạn |