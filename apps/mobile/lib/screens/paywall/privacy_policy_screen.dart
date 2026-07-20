import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Privacy Policy screen — required by Google Play policy.
class PrivacyPolicyScreen extends StatelessWidget {
  static const routeName = '/privacy-policy';

  const PrivacyPolicyScreen({super.key});

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
          'Chính sách bảo mật',
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
              title: '1. Thu thập dữ liệu',
              content:
                  'HVAC Pro thu thập thông tin tài khoản (email, UID) từ Firebase Authentication và dữ '
                  'liệu sử dụng ứng dụng (bookmarks, lịch sử tính toán) để cung cấp dịch vụ cá nhân hóa và '
                  'lưu trữ dữ liệu người dùng.',
            ),
            _Section(
              title: '2. Sử dụng dữ liệu',
              content:
                  'Dữ liệu được sử dụng để vận hành ứng dụng, xác thực quyền truy cập nội dung VIP, '
                  'cải thiện trải nghiệm người dùng và hỗ trợ kỹ thuật. Chúng tôi không bán dữ liệu cá '
                  'nhân cho bên thứ ba.',
            ),
            _Section(
              title: '3. Lưu trữ và bảo mật',
              content:
                  'Dữ liệu được lưu trữ trên Firebase (Firestore) với bảo mật theo tiêu chuẩn Firebase. '
                  'Thông tin thanh toán được xử lý bởi Google Play và RevenueCat — chúng tôi không lưu trữ '
                  'thông tin thẻ thanh toán.',
            ),
            _Section(
              title: '4. Quyền của người dùng',
              content:
                  'Bạn có quyền truy cập, chỉnh sửa và xóa dữ liệu cá nhân của mình bất cứ lúc nào '
                  'thông qua mục "Xóa tài khoản" trong ứng dụng. Sau khi xóa, dữ liệu sẽ được xóa vĩnh '
                  'viễn trong vòng 30 ngày.',
            ),
            _Section(
              title: '5. Liên hệ',
              content:
                  'Nếu có thắc mắc về Chính sách bảo mật này, vui lòng liên hệ qua email trong ứng dụng '
                  'hoặc tại: hvacpro@example.com',
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
