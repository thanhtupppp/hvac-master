# Tài liệu Thiết kế: Giao diện Đăng nhập Mobile và Admin

**Dự án:** HVAC Pro  
**Ngày tạo:** 16-07-2026  
**Trạng thái:** Đã phê duyệt bản phác thảo  

Tài liệu này đặc tả thiết kế giao diện đăng nhập cho cả nền tảng Quản trị Web (Next.js) và ứng dụng Di động (Flutter). Cả hai giao diện đều tuân thủ nguyên tắc thiết kế **Tối giản (Minimalist)** kết hợp **Kính mờ (Glassmorphism)**, hỗ trợ đầy đủ chế độ Sáng/Tối (Light/Dark Mode).

---

## 1. Phương thức Xác thực Hỗ trợ

*   **Email & Mật khẩu:** Phương thức cơ bản cho cả hai ứng dụng.
*   **Google Sign-In:** Đăng nhập nhanh qua tài khoản Google trên cả hai nền tảng.
*   **Sinh trắc học (Biometrics - Mobile only):** Xác thực Face ID hoặc Vân tay tích hợp trên điện thoại.

---

## 2. Thiết kế Giao diện Admin Web (Next.js)

### Bố cục & Kiểu dáng
*   **Bố cục:** Chia đôi màn hình (`grid lg:grid-cols-2`).
    *   **Cột bên trái:** Chỉ hiển thị trên Desktop. Nền tối xanh phiến đá (`bg-slate-900` / `dark:bg-slate-950`). Hiển thị hình vẽ SVG cách điệu các đường khí, quạt gió điều hòa (đại diện cho HVAC) phát sáng xanh lá nhẹ, tiêu đề giới thiệu hệ thống quản trị tài liệu.
    *   **Cột bên phải:** Biểu mẫu đăng nhập được căn giữa. Nền tự động thay đổi (`bg-slate-50` / `dark:bg-slate-900`).
*   **Thẻ Đăng nhập (Card):**
    *   Sử dụng component `Card` của shadcn/ui.
    *   Nút "Đăng nhập với Google" nổi bật ở trên cùng với Logo Google chuẩn.
    *   Phần nhập Email/Mật khẩu tối giản với nút icon bật/tắt ẩn/hiện mật khẩu.
    *   Nút hành động "Đăng nhập" chính sử dụng màu xanh lá cây tương phản (`bg-green-600` / `hover:bg-green-500`).

---

## 3. Thiết kế Giao diện Mobile (Flutter)

### Bố cục & Kiểu dáng
*   **Nền màn hình:** Hiệu ứng chuyển sắc Gradient nhẹ nhàng từ trên xuống dưới:
    *   *Light Mode:* Xanh da trời nhạt sang xám trắng (`0xFFE3F2FD` -> `0xFFF5F5F5`).
    *   *Dark Mode:* Xanh Slate tối sang đen sâu (`0xFF0F172A` -> `0xFF020617`).
*   **Thẻ Đăng nhập Kính mờ (Glassmorphism Card):**
    *   Sử dụng `BackdropFilter` với độ mờ `blur` thích hợp.
    *   Đường viền trắng siêu mỏng bán trong suốt tạo cảm giác phản chiếu của kính.
*   **Các thành phần giao diện:**
    *   Logo thương hiệu HVAC Pro dạng icon quạt gió đặt trên cùng.
    *   Input nhập liệu bo tròn góc 12pt, màu nền mờ.
    *   Hàng biểu tượng đăng nhập nhanh gồm:
        *   Nút biểu tượng Google.
        *   Nút biểu tượng Sinh trắc học (Vân tay hoặc Face ID). Khi nhấn vào, hệ thống tự động kích hoạt tính năng quét sinh trắc học hệ điều hành.

---

## 4. Kiến trúc & Luồng dữ liệu (Data Flow)

```
[Người dùng]
     │
     ├─► Chọn Đăng nhập Google ──► Gọi API Firebase Auth ──► Thành công ──► Lưu Context ──► Điều hướng trang chủ
     ├─► Nhập Email/Password  ──► Xác thực Firebase Auth ──► Thành công ──► Lưu Context ──► Điều hướng trang chủ
     └─► Vân tay/Face ID (Mobile) ──► Gọi Local Auth ────► Thành công ──► Xác thực Firebase ──► Điều hướng
```

### Xử lý lỗi (Error Handling)
*   **Lỗi xác thực (sai mật khẩu/email không tồn tại):** Hiển thị Toast (trên Admin Web) hoặc SnackBar màu đỏ (trên Mobile) với nội dung thông báo thân thiện.
*   **Không có kết nối mạng:** Hiển thị cảnh báo trực quan ngăn không cho bấm nút đăng nhập.
*   **Lỗi sinh trắc học:** Nếu quét vân tay/Face ID thất bại, hệ thống cho phép thử lại hoặc tự động chuyển hướng người dùng nhập mật khẩu bình thường.

---

## 5. Kế hoạch xác thực (Verification Plan)

### Kiểm thử Giao diện
*   Kiểm tra sự tương thích của giao diện trên các kích thước màn hình phổ biến (Responsive).
*   Kiểm tra tính năng chuyển đổi chế độ Sáng/Tối tự động dựa trên cài đặt hệ thống.
*   Kiểm thử hành vi nhấn nút (hiệu ứng hover/ripple).

### Kiểm thử chức năng
*   Đăng nhập bằng tài khoản Email/Password hợp lệ và không hợp lệ.
*   Xác minh đăng nhập Google chuyển hướng và nhận diện tài khoản chính xác.
*   (Chỉ dành cho Mobile) Kiểm tra tính năng xác thực sinh trắc học trên các thiết bị hỗ trợ hoặc máy ảo giả lập.
