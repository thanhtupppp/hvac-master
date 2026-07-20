import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Terms of Service screen — required by Google Play policy.
class TermsScreen extends StatelessWidget {
  static const routeName = '/terms';

  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Điều khoản sử dụng',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: '1. Chấp nhận điều khoản',
              content:
                  'Bằng việc sử dụng ứng dụng HVAC Pro, bạn đồng ý tuân thủ các Điều khoản sử dụng này. '
                  'Nếu bạn không đồng ý, vui lòng không sử dụng ứng dụng.',
            ),
            _Section(
              title: '2. Mô tả dịch vụ',
              content:
                  'HVAC Pro là ứng dụng hỗ trợ kỹ thuật viên điều hòa không khí, cung cấp công cụ tính toán HVAC, '
                  'tra cứu mã lỗi và tài liệu kỹ thuật. Kết quả tính toán chỉ mang tính chất tham khảo.',
            ),
            _Section(
              title: '3. Tài khoản VIP',
              content:
                  'Gói VIP cung cấp quyền truy cập toàn bộ tính năng với phí đăng ký. Bạn có thể hủy bất '
                  'cứ lúc nào qua cài đặt Google Play. Sau khi hủy, quyền truy cập VIP vẫn còn đến hết kỳ '
                  'thanh toán đã thanh toán.',
            ),
            _Section(
              title: '4. Sử dụng hợp pháp',
              content:
                  'Nghiêm cấm sử dụng ứng dụng cho bất kỳ mục đích bất hợp pháp nào. Người dùng phải chịu '
                  'trách nhiệm về việc sử dụng công cụ tính toán đúng cách và theo tiêu chuẩn kỹ thuật '
                  'hiện hành.',
            ),
            _Section(
              title: '5. Từ chối trách nhiệm',
              content:
                  'HVAC Pro không chịu trách nhiệm cho bất kỳ thiệt hại nào phát sinh từ việc sử dụng hoặc '
                  'không thể sử dụng ứng dụng. Kết quả tính toán cần được kiểm chứng bởi kỹ sư có chuyên '
                  'môn trước khi áp dụng thực tế.',
            ),
            _Section(
              title: '6. Thay đổi dịch vụ',
              content:
                  'Chúng tôi có quyền thay đổi hoặc ngừng cung cấp dịch vụ mà không cần thông báo trước. '
                  'Phí đăng ký có thể được điều chỉnh; thông báo sẽ được gửi qua email hoặc thông báo '
                  'trong ứng dụng.',
            ),
            _Section(
              title: '7. Liên hệ',
              content:
                  'Mọi thắc mắc về Điều khoản sử dụng, vui lòng liên hệ: hvacpro@example.com',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
