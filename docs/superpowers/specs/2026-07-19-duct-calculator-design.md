# Đặc Tả Thiết Kế: Module Duct Calculator (Thiết Kế Ống Gió)

Tài liệu này đặc tả chi tiết kiến trúc tái cấu trúc và thiết kế lại module **Duct Calculator** cho ứng dụng di động **HVAC Pro** (Flutter).

---

## 1. Nguyên Tắc Thiết Kế (Design Principles)

1. **Engine-first**: Toàn bộ công thức toán học và vật lý HVAC được đóng gói trong một Engine thuần Dart, độc lập 100% với Flutter và Riverpod.
2. **Single Source of Truth**: Engine chỉ thực hiện tính toán trên một hệ đơn vị nội bộ cố định (Imperial). Lớp Service bên ngoài chịu trách nhiệm quy đổi đơn vị (Metric ↔ Imperial) trước khi đưa vào Engine và sau khi nhận kết quả.
3. **Recommendation over Calculation**: Ứng dụng không chỉ hiển thị kết quả toán học thuần túy mà luôn ưu tiên đề xuất các phương án kích thước thực tế tối ưu cho thi công (Preferred Sizes).
4. **Explainability**: Mọi cảnh báo lỗi hoặc cảnh báo kỹ thuật (vận tốc cao, tỷ lệ Aspect Ratio lớn) đều đi kèm giải thích ngắn và gợi ý hành động xử lý trực quan.
5. **Progressive Disclosure**: Giao diện mặc định chỉ hiển thị các thông tin quan trọng nhất (Hero Card, Top 1 Option); các chi tiết kỹ thuật phụ sẽ được ẩn và mở rộng khi người dùng cần (Expandable Card).

---

## 2. Kiến Trúc Phân Tầng (Clean Architecture)

```text
Presentation (UI)
      │
      ▼
State Layer (Riverpod Notifier)
      │
      ▼
Domain/Service Layer (DuctCalculatorService)
      │
      ▼
Engine Layer (Pure Dart formulas & ranking)
```

### A. Thư Mục Tổ Chức
```text
lib/services/duct/
│
├── models/
│   ├── duct_input.dart
│   ├── duct_result.dart
│   ├── round_result.dart
│   ├── rectangle_option.dart
│   ├── duct_warning.dart
│   └── enums.dart
│
├── engine/
│   ├── formulas.dart
│   ├── standard_sizes.dart
│   ├── preferred_rect_sizes.dart
│   ├── velocity_table.dart
│   ├── rectangle_generator.dart
│   ├── rectangle_ranker.dart
│   └── unit_converter.dart
│
└── services/
    └── duct_calculator_service.dart
```

---

## 3. Chi Tiết Lớp Engine (Engine Layer)

### A. Công Thức Vật Lý HVAC (`formulas.dart`)
- **Vận tốc gió (Velocity):**
  \[V = \frac{Q}{A}\]
  Trong đó: $V$ là vận tốc (fpm hoặc m/s), $Q$ là lưu lượng (CFM hoặc m³/h), $A$ là diện tích mặt cắt ngang ống gió.
- **Đường kính ống tròn tương đương ma sát (Huebscher Equation):**
  \[D_e = 1.30 \times \frac{(a \cdot b)^{0.625}}{(a + b)^{0.25}}\]
  Trong đó: $D_e$ là đường kính ống tròn tương đương (inches), $a$ và $b$ là hai cạnh của ống chữ nhật (inches).
- **Đường kính ống tròn (Equal Friction Approximation):**
  \[D = 2.42 \times \frac{Q^{0.375}}{\Delta h_f^{0.1875}}\]
  Trong đó: $D$ là đường kính ống tròn (inches), $Q$ là lưu lượng (CFM), $\Delta h_f$ là độ tổn thất áp suất ma sát (in.wg/100ft).

### B. Sinh Phương Án & Xếp Hạng
1. **Duct Size Generator (`rectangle_generator.dart`):**
   - Duyệt qua danh sách kích thước tiêu chuẩn (`standard_sizes.dart`).
   - Ghép cặp chiều rộng ($a$) và chiều cao ($b$).
   - Lọc bỏ các phương án có tỷ lệ Aspect Ratio ($a/b$ hoặc $b/a$) vượt quá $4.0$.
2. **Weighted Score Ranker (`rectangle_ranker.dart`):**
   Chấm điểm các phương án chữ nhật còn lại trên thang điểm 100 theo trọng số:
   \[\text{Score} = 40\% \cdot \text{Velocity/Friction Error} + 30\% \cdot \text{Aspect Ratio Penalty} + 20\% \cdot \text{Equivalent Diameter Error} + 10\% \cdot \text{Preferred Size Bonus}\]
   - *Velocity/Friction Error:* Sai lệch giữa vận tốc thực tế của ống chữ nhật so với vận tốc mục tiêu (ở chế độ Velocity) hoặc sai lệch giữa đường kính tương đương của ống chữ nhật so với ống tròn (ở chế độ Equal Friction).
   - *Aspect Ratio Penalty:* Phạt điểm tăng dần nếu Aspect Ratio lớn hơn $1.5$.
   - *Preferred Size Bonus:* Cộng thêm $10$ điểm nếu kích thước thuộc danh sách `preferred_rect_sizes.dart` (các kích thước thông dụng trong thi công).
   - *Đổi sang số Sao:*
     - Điểm $\ge 90$: ★★★★★
     - Điểm $80 - 89$: ★★★★☆
     - Điểm $70 - 79$: ★★★☆☆
     - Điểm $< 70$: ★★☆☆☆ hoặc ★☆☆☆☆

---

## 4. Chi Tiết Lớp Service & State (Domain & State)

### A. `DuctCalculatorService` (Stateless)
- Nhận `DuctInput` từ Notifier.
- Sử dụng `UnitConverter` để quy đổi sang Imperial.
- Gọi Engine tính toán và nhận về `DuctResult` (hệ Imperial).
- Quy đổi ngược `DuctResult` về hệ đơn vị hiển thị của UI.
- Thêm `CalculationMetadata` (Thời gian tính, thuật toán).

### B. `DuctCalculatorNotifier` & State (Riverpod)
- **Immutable State:** Quản lý các thuộc tính của form nhập liệu, kết quả hiển thị, `CalculationStatus` (idle, calculating, success, error) và `CalculationError`.
- **Cơ chế Debounce (250ms):** 
  - Khi người dùng gõ số, Notifier sẽ trì hoãn tính toán trong 250ms để tối ưu hiệu năng.
  - Khi người dùng bấm chuyển đổi nhanh (Method, Unit System, Duct Type), Notifier sẽ kích hoạt tính toán lập tức.
- **Dependency Injection:** Nhận `DuctCalculatorService` thông qua `ductCalculatorServiceProvider` để dễ dàng mock test.

---

## 5. Thiết Kế Giao Diện Dashboard (Presentation Layer)

### A. Bố Cục Phân Tầng Dashboard
1. **Header System**: Segmented Control chuyển đổi đơn vị (Imperial/Metric) và phương pháp tính (Velocity/Equal Friction) ở phía trên cùng.
2. **Input Fields Card**: Form nhập liệu trực quan. Duct Type Dropdown hỗ trợ tự động gợi ý vận tốc mục tiêu (nhưng cho phép ghi đè).
3. **Hero Card (Round Result)**: Hiển thị nổi bật kích thước ống tròn tính toán và kích thước quy chuẩn thi công đề xuất (e.g. Ø 250 mm).
4. **Best Rectangle Recommendation**: Hiển thị phương án ống chữ nhật đạt điểm cao nhất (5 sao) nổi bật kèm Badge chỉ dẫn (`✓ COMMON SIZE`, `✓ LOW NOISE`).
5. **More Options List**: Danh sách các phương án ống chữ nhật 3-4 sao dưới dạng thẻ có thể bấm để mở rộng (Expandable Card) hiển thị chi tiết thông số (Area, Aspect Ratio, Equivalent Diameter, v.v.).
6. **Actionable Warnings**: Thanh cảnh báo trạng thái trực quan bằng biểu tượng và văn bản rõ ràng:
   - 🟢 `✓ Recommended`: Vận tốc & Aspect Ratio tối ưu.
   - 🟡 `⚠ Velocity High`: Gợi ý tăng kích thước hoặc giảm lưu lượng.
   - 🔴 `✕ Aspect Ratio > 4`: Yêu cầu đổi kích thước để tránh bẹp ống khi thi công.
7. **Action Bar**: Các nút hành động gồm `Copy`, `Export PDF` (xuất file báo cáo chi tiết kỹ thuật), `Share` và `Save History`.

### B. Chế Độ Landscape & Accessibility
- **Landscape Mode**: Hiển thị dạng chia đôi cột (Input bên trái, Results bên phải) tối ưu trên Máy tính bảng (Tablet).
- **Accessibility**: Không sử dụng màu sắc làm kênh truyền đạt thông tin duy nhất. Luôn đi kèm biểu tượng (check, warning, cross) và văn bản trạng thái.
- **Info Panels**: Nhấp vào các tiêu đề thông số kỹ thuật (như Equivalent Diameter, Aspect Ratio) sẽ mở Bottom Sheet giải thích định nghĩa kỹ thuật ngắn gọn.
