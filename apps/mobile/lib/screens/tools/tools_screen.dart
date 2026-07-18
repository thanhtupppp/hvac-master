import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/user_provider.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final isPremium = userAsync.asData?.value?.isPremium == true;

    final List<Map<String, dynamic>> tools = [
      {
        'title': 'Bảng tra ga P-T Chart',
        'desc': 'Tra cứu áp suất và nhiệt độ bão hòa môi chất lạnh R22, R32, R410A, v.v.',
        'icon': Icons.thermostat,
        'color': const Color(0xFF388AF6),
        'route': AppRoutes.ptChart,
        'isVipOnly': false,
      },
      {
        'title': 'Tính toán ống gió',
        'desc': 'Thiết kế kích thước ống gió tròn, ống chữ nhật theo lưu lượng CFM.',
        'icon': Icons.air,
        'color': const Color(0xFF00BFA5),
        'route': AppRoutes.ductSizer,
        'isVipOnly': true,
      },
      {
        'title': 'Độ Quá nhiệt & Quá lạnh',
        'desc': 'Tính toán Superheat và Subcooling để chuẩn đoán và nạp ga hệ thống.',
        'icon': Icons.ac_unit,
        'color': const Color(0xFFFF9800),
        'route': AppRoutes.superheat,
        'isVipOnly': true,
      },
      {
        'title': 'Bộ đổi đơn vị HVAC',
        'desc': 'Chuyển đổi BTU/h, HP, kW, Tons, PSI, Bar, °C, °F cực kỳ nhanh chóng.',
        'icon': Icons.swap_horiz,
        'color': const Color(0xFFE91E63),
        'route': AppRoutes.unitConverter,
        'isVipOnly': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Công cụ kỹ thuật',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final showVipBadge = tool['isVipOnly'] as bool;
          final lockAccess = showVipBadge && !isPremium;

          return GestureDetector(
            onTap: () {
              if (lockAccess) {
                _showVipDialog(context);
              } else {
                Navigator.pushNamed(context, tool['route'] as String);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: lockAccess
                      ? Colors.amber.withValues(alpha: 0.1)
                      : (tool['color'] as Color).withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (tool['color'] as Color).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (tool['color'] as Color).withValues(alpha: 0.1),
                      border: Border.all(
                        color: (tool['color'] as Color).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: tool['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              tool['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (showVipBadge) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber, width: 0.5),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.stars, color: Colors.amber, size: 10),
                                    SizedBox(width: 2),
                                    Text(
                                      'VIP',
                                      style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tool['desc'] as String,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    lockAccess ? Icons.lock_outline : Icons.arrow_forward_ios,
                    size: 16,
                    color: lockAccess ? Colors.amber : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Tính năng Premium', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Công cụ này chỉ dành cho tài khoản VIP. Vui lòng nâng cấp Premium để sử dụng trọn bộ công cụ kỹ thuật và sơ đồ mạch điện.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Switch to settings/payment or show premium upgrade
            },
            child: const Text('Nâng cấp ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
