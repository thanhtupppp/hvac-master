import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/revenuecat_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  /// Route name
  static const routeName = '/paywall';

  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService.instance.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _selectedPackage = RevenueCatService.instance.getDefaultPackage(
        offerings,
      );
      _isLoading = false;
    });
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      await RevenueCatService.instance.purchase(_selectedPackage!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nâng cấp VIP thành công! Cảm ơn bạn.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isCancelled =
          e.code == 'USER_CANCELLED' ||
          e.message?.toLowerCase().contains('cancel') == true;
      if (!isCancelled) {
        setState(() {
          _error = 'Mua hàng thất bại: ${e.message}';
          _isPurchasing = false;
        });
      } else {
        setState(() => _isPurchasing = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Đã xảy ra lỗi: $e';
        _isPurchasing = false;
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);

    final restored = await RevenueCatService.instance.restore();

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khôi phục giao dịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy giao dịch nào để khôi phục.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _openPrivacy() {
    Navigator.pushNamed(context, AppRoutes.privacyPolicy);
  }

  void _openTerms() {
    Navigator.pushNamed(context, AppRoutes.terms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _offerings == null
            ? _buildNoOfferings()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text('Đang tải gói VIP...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildNoOfferings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.amber, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Không tải được gói VIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra kết nối mạng và thử lại.',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() => _isLoading = true);
                _loadOfferings();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final packages = _offerings!.current?.availablePackages ?? [];

    return Column(
      children: [
        // ── Header ────────────────────────────────────────────────────────
        _buildHeader(),

        // ── Benefits ─────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              children: [
                _buildBenefits(),
                const SizedBox(height: 20),

                // ── Package selector ──────────────────────────────────────
                if (packages.isNotEmpty) ...[
                  _buildPackageSelector(packages),
                  const SizedBox(height: 16),
                ],

                // ── Error message ────────────────────────────────────────
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Purchase CTA ───────────────────────────────────────────
                _buildPurchaseButton(),
                const SizedBox(height: 12),

                // ── Restore & legal ───────────────────────────────────────
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // VIP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Text(
                  'VIP PREMIUM',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Mở khóa toàn bộ\ncông cụ kỹ thuật',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          const Text(
            'Truy cập không giới hạn tất cả công cụ, sơ đồ mạch điện và tài liệu kỹ thuật chuyên nghiệp.',
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      _Benefit(
        icon: Icons.construction,
        title: 'Tất cả công cụ chuyên nghiệp',
        desc:
            'Equal Friction, Velocity, Pipe Sizer, Pump Selection, và 40+ công cụ khác',
      ),
      _Benefit(
        icon: Icons.electrical_services,
        title: 'Sơ đồ mạch điện đầy đủ',
        desc: 'Sơ đồ mạch điều hòa các hãng Daikin, Panasonic, LG, Samsung...',
      ),
      _Benefit(
        icon: Icons.download_outlined,
        title: 'Tài liệu kỹ thuật PDF',
        desc: 'Catalog, manual, brochure các dòng điều hòa thông dụng',
      ),
      _Benefit(
        icon: Icons.history,
        title: 'Lịch sử tính toán',
        desc: 'Lưu lại kết quả tính toán để tra cứu nhanh',
      ),
      _Benefit(
        icon: Icons.offline_bolt_outlined,
        title: 'Dùng offline',
        desc: 'Truy cập nội dung đã bookmark không cần mạng',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < benefits.length; i++) ...[
            _BenefitRow(benefit: benefits[i]),
            if (i != benefits.length - 1)
              const Divider(color: AppColors.divider, height: 1, indent: 60),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageSelector(List<Package> packages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn gói VIP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        ...packages.map((pkg) {
          final isSelected = _selectedPackage?.identifier == pkg.identifier;
          final price = pkg.storeProduct.priceString;
          final period = _packagePeriod(pkg.packageType);
          final intro = pkg.storeProduct.introductoryPrice;

          return GestureDetector(
            onTap: () => setState(() => _selectedPackage = pkg),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.amber.withValues(alpha: 0.1)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.amber : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Package info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _packageLabel(pkg.packageType),
                              style: TextStyle(
                                color: isSelected ? Colors.amber : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (intro != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DÙNG THỬ',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          period,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: isSelected ? Colors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (intro != null)
                        Text(
                          intro.priceString,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    final pkg = _selectedPackage;
    final price = pkg?.storeProduct.priceString ?? '';
    final hasIntro = pkg?.storeProduct.introductoryPrice != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _isPurchasing || pkg == null ? null : _purchase,
        child: _isPurchasing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black54,
                ),
              )
            : RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: hasIntro ? 'Dùng thử & Đăng ký  ' : 'Đăng ký VIP  ',
                    ),
                    TextSpan(
                      text: price.isNotEmpty ? '($price)' : '',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Restore purchases
        TextButton.icon(
          onPressed: _isPurchasing ? null : _restore,
          icon: const Icon(Icons.restore, color: Colors.white54, size: 18),
          label: const Text(
            'Khôi phục giao dịch',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),

        const SizedBox(height: 4),

        // Legal links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _openPrivacy,
              child: const Text(
                'Chính sách bảo mật',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
            const Text(
              '  •  ',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
            GestureDetector(
              onTap: _openTerms,
              child: const Text(
                'Điều khoản sử dụng',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Thanh toán qua Google Play. Hủy bất cứ lúc nào trong cài đặt Google Play.',
          style: TextStyle(color: Colors.white24, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _packageLabel(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return 'Gói Tuần';
      case PackageType.monthly:
        return 'Gói Tháng';
      case PackageType.twoMonth:
        return 'Gói 2 Tháng';
      case PackageType.threeMonth:
        return 'Gói 3 Tháng';
      case PackageType.sixMonth:
        return 'Gói 6 Tháng';
      case PackageType.annual:
        return 'Gói Năm';
      case PackageType.lifetime:
        return 'Gói Vĩnh viễn';
      case PackageType.custom:
        return 'Gói Tùy chỉnh';
      case PackageType.unknown:
        return 'Gói';
    }
  }

  String _packagePeriod(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return '7 ngày / tuần';
      case PackageType.monthly:
        return '1 tháng';
      case PackageType.twoMonth:
        return '2 tháng';
      case PackageType.threeMonth:
        return '3 tháng';
      case PackageType.sixMonth:
        return '6 tháng';
      case PackageType.annual:
        return '12 tháng (tiết kiệm nhất)';
      case PackageType.lifetime:
        return 'Vĩnh viễn';
      case PackageType.custom:
      case PackageType.unknown:
        return '';
    }
  }
}

// ─── Benefit row widget ────────────────────────────────────────────────────────

class _Benefit {
  final IconData icon;
  final String title;
  final String desc;

  const _Benefit({required this.icon, required this.title, required this.desc});
}

class _BenefitRow extends StatelessWidget {
  final _Benefit benefit;

  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(benefit.icon, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.desc,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.amber, size: 20),
        ],
      ),
    );
  }
}
