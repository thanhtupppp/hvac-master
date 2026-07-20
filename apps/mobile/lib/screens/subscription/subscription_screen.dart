import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/revenuecat_service.dart';

/// RevenueCat entitlement status derived from the latest customer info.
class EntitlementStatus {
  final bool isActive;
  final bool isInTrial;
  final DateTime? expiryDate;
  final String? productId;
  final String? subscriptionPeriod;
  final bool willRenew;
  final String? latestPurchaseId;

  EntitlementStatus({
    required this.isActive,
    required this.isInTrial,
    this.expiryDate,
    this.productId,
    this.subscriptionPeriod,
    required this.willRenew,
    this.latestPurchaseId,
  });
}

/// Provider that fetches live entitlement status from RevenueCat.
final entitlementStatusProvider = FutureProvider<EntitlementStatus?>((
  ref,
) async {
  try {
    final info = await Purchases.getCustomerInfo();
    final ent = info.entitlements.all[RevenueCatService.entitlementId];
    if (ent == null) return null;

    final productId = ent.productIdentifier;
    final isActive = ent.isActive;
    final willRenew = ent.willRenew;
    final expiryStr = ent.expirationDate;

    DateTime? expiryDate;
    if (expiryStr != null) {
      expiryDate = DateTime.tryParse(expiryStr);
    }

    // Detect trial: entitlement is active but will not renew
    final isInTrial = isActive && !willRenew && expiryDate != null;

    // Determine period label from productId suffix
    String? period;
    if (productId.contains('monthly') || productId.contains('month')) {
      period = '1 tháng';
    } else if (productId.contains('quarterly')) {
      period = '3 tháng';
    } else if (productId.contains('yearly') || productId.contains('annual')) {
      period = '12 tháng';
    } else if (productId.contains('lifetime')) {
      period = 'Vĩnh viễn';
    } else {
      period = null;
    }

    return EntitlementStatus(
      isActive: isActive,
      isInTrial: isInTrial,
      expiryDate: expiryDate,
      productId: productId,
      subscriptionPeriod: period,
      willRenew: willRenew,
      latestPurchaseId: null,
    );
  } catch (e) {
    return null;
  }
});

/// Subscription management screen — shows current plan details and management options.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isRestoring = false;

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);

    final restored = await RevenueCatService.instance.restore();

    if (!mounted) return;
    setState(() => _isRestoring = false);

    // Refresh the entitlement status
    ref.invalidate(entitlementStatusProvider);

    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khôi phục giao dịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy giao dịch nào để khôi phục.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openPlayStoreSubscription() async {
    // Opens Google Play Subscriptions management page
    // This is the recommended way to cancel/manage subscriptions
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=${ref.read(entitlementStatusProvider).value?.productId ?? ''}'
      '&package=com.hvac.pro',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể mở Google Play. Vui lòng quản lý trong ứng dụng Google Play.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(entitlementStatusProvider);

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
          'Quản lý VIP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: statusAsync.when(
        data: (status) => _buildContent(status),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, s) => _buildError(),
      ),
    );
  }

  Widget _buildContent(EntitlementStatus? status) {
    if (status == null || !status.isActive) {
      return _buildNoSubscription();
    }
    return _buildActiveSubscription(status);
  }

  Widget _buildNoSubscription() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_outline,
              color: AppColors.textMuted,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bạn chưa đăng ký VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nâng cấp ngay để mở khóa toàn bộ công cụ kỹ thuật chuyên nghiệp.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.paywall),
              child: const Text(
                'Nâng cấp VIP ngay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _isRestoring ? null : _restorePurchases,
            icon: _isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.restore, color: Colors.white54, size: 18),
            label: const Text(
              'Khôi phục giao dịch',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscription(EntitlementStatus status) {
    final expiryText = status.expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(status.expiryDate!)
        : 'Vĩnh viễn';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // VIP Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'TÀI KHOẢN VIP',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  icon: Icons.calendar_today,
                  label: 'Ngày hết hạn',
                  value: expiryText,
                  valueColor: status.willRenew ? Colors.white : Colors.amber,
                ),
                const Divider(color: AppColors.divider, height: 28),
                _buildStatusRow(
                  icon: Icons.repeat,
                  label: 'Chu kỳ',
                  value: status.subscriptionPeriod ?? '—',
                  valueColor: Colors.white,
                ),
                if (status.isInTrial) ...[
                  const Divider(color: AppColors.divider, height: 28),
                  _buildStatusRow(
                    icon: Icons.hourglass_bottom,
                    label: 'Trạng thái',
                    value: 'Đang dùng thử',
                    valueColor: Colors.greenAccent,
                  ),
                ],
                const Divider(color: AppColors.divider, height: 28),
                _buildStatusRow(
                  icon: status.willRenew ? Icons.autorenew : Icons.pause_circle,
                  label: 'Tự động gia hạn',
                  value: status.willRenew ? 'Bật' : 'Tắt',
                  valueColor: status.willRenew
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Renewal notice
          if (status.willRenew && status.expiryDate != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gói của bạn sẽ tự động gia hạn vào ngày $expiryText.',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!status.willRenew && !status.isInTrial)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orangeAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gói của bạn sẽ không tự động gia hạn. Hãy nâng cấp lên để tiếp tục sử dụng VIP.',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (status.isInTrial)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    color: Colors.lightBlueAccent,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn đang trong thời gian dùng thử. Đăng ký để tiếp tục sử dụng VIP.',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Upgrade / Change plan
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.paywall),
              child: const Text(
                'Đổi sang gói khác',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Manage via Google Play
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _openPlayStoreSubscription,
              icon: const Icon(Icons.settings, size: 18),
              label: const Text(
                'Quản lý qua Google Play',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Restore
          TextButton.icon(
            onPressed: _isRestoring ? null : _restorePurchases,
            icon: _isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.restore, color: Colors.white54, size: 18),
            label: const Text(
              'Khôi phục giao dịch',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),

          const SizedBox(height: 24),

          // Legal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                child: const Text(
                  'Chính sách bảo mật',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
              const Text(
                '  •  ',
                style: TextStyle(color: Color(0x26FFFFFF), fontSize: 12),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                child: const Text(
                  'Điều khoản sử dụng',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thanh toán qua Google Play.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Không tải được thông tin thuê bao',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra kết nối mạng và thử lại.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ref.invalidate(entitlementStatusProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
