import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/user_provider.dart';

class _ToolItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String? route;
  final bool isVipOnly;

  const _ToolItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.route,
    this.isVipOnly = false,
  });
}

class _ToolCategory {
  final String name;
  final String emoji;
  final IconData icon;
  final Color accent;
  final List<_ToolItem> tools;

  const _ToolCategory({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.accent,
    required this.tools,
  });
}

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  static final List<_ToolCategory> _categories = [
    _ToolCategory(
      name: 'Air Distribution',
      emoji: '🌬️',
      icon: Icons.air,
      accent: const Color(0xFF00BFA5),
      tools: const [
        _ToolItem(
          title: 'Duct Calculator',
          desc: 'Thiết kế ống gió tròn, chữ nhật theo lưu lượng CFM.',
          icon: Icons.air,
          color: Color(0xFF00BFA5),
          route: AppRoutes.ductSizer,
        ),
        _ToolItem(
          title: 'Duct Pressure Loss',
          desc: 'Tính tổn thất áp suất đường ống gió.',
          icon: Icons.compress,
          color: Color(0xFF26C6DA),
          route: null,
        ),
        _ToolItem(
          title: 'Equal Friction Duct Sizer',
          desc: 'Thiết kế theo phương pháp Equal Friction.',
          icon: Icons.balance,
          color: Color(0xFF00ACC1),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Velocity Duct Sizer',
          desc: 'Thiết kế theo phương pháp Velocity.',
          icon: Icons.speed,
          color: Color(0xFF0097A7),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Duct Fitting Loss',
          desc: 'Tổn thất qua co, cút, tê, van...',
          icon: Icons.turn_right,
          color: Color(0xFF00838F),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Air Velocity Calculator',
          desc: 'Tính vận tốc gió trong ống.',
          icon: Icons.toys,
          color: Color(0xFF006064),
          route: AppRoutes.airVelocityCalculator,
        ),
        _ToolItem(
          title: 'Airflow Calculator',
          desc: 'Tính lưu lượng gió CFM / m³/h.',
          icon: Icons.wind_power,
          color: Color(0xFF00B8D4),
          route: AppRoutes.airflowCalculator,
        ),
        _ToolItem(
          title: 'Air Change Calculator (ACH)',
          desc: 'Số lần thay đổi không khí/giờ.',
          icon: Icons.refresh,
          color: Color(0xFF00BCD4),
          route: AppRoutes.achCalculator,
        ),
        _ToolItem(
          title: 'Diffuser Selector',
          desc: 'Chọn miệng gió phù hợp.',
          icon: Icons.scatter_plot,
          color: Color(0xFF009688),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Grille Selector',
          desc: 'Chọn cửa gió hồi / cấp.',
          icon: Icons.grid_view,
          color: Color(0xFF00897B),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'VAV Box Sizing',
          desc: 'Chọn hộp VAV theo lưu lượng.',
          icon: Icons.dashboard_customize,
          color: Color(0xFF00796B),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Fan Selection',
          desc: 'Chọn quạt theo cột áp và lưu lượng.',
          icon: Icons.toys_outlined,
          color: Color(0xFF00695C),
          route: null,
          isVipOnly: true,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Refrigeration',
      emoji: '❄️',
      icon: Icons.ac_unit,
      accent: const Color(0xFF388AF6),
      tools: const [
        _ToolItem(
          title: 'PT Chart',
          desc: 'Biểu đồ Áp suất – Nhiệt độ các môi chất lạnh.',
          icon: Icons.thermostat,
          color: Color(0xFF388AF6),
          route: AppRoutes.ptChart,
        ),
        _ToolItem(
          title: 'Superheat Calculator',
          desc: 'Tính Superheat để chẩn đoán hệ thống.',
          icon: Icons.trending_up,
          color: Color(0xFFFF9800),
          route: AppRoutes.superheat,
        ),
        _ToolItem(
          title: 'Subcooling Calculator',
          desc: 'Tính Subcooling kiểm tra dàn ngưng.',
          icon: Icons.trending_down,
          color: Color(0xFFFFA726),
          route: AppRoutes.subcoolingCalculator,
        ),
        _ToolItem(
          title: 'Refrigerant Charge Calculator',
          desc: 'Tính lượng gas nạp thêm / bổ sung.',
          icon: Icons.local_gas_station,
          color: Color(0xFFFF7043),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Refrigerant Pipe Sizer',
          desc: 'Chọn kích thước ống môi chất lạnh.',
          icon: Icons.plumbing,
          color: Color(0xFFFF5722),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Pressure Converter',
          desc: 'Chuyển đổi áp suất (PSI, Bar, kPa, MPa, inHg, mmHg).',
          icon: Icons.swap_vert,
          color: Color(0xFF42A5F5),
          route: AppRoutes.pressureConverter,
        ),
        _ToolItem(
          title: 'Saturation Temperature',
          desc: 'Tra nhiệt độ bão hòa theo áp suất.',
          icon: Icons.device_thermostat,
          color: Color(0xFF1E88E5),
          route: AppRoutes.saturationTemperature,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Hydronic',
      emoji: '💧',
      icon: Icons.water_drop,
      accent: const Color(0xFF2196F3),
      tools: const [
        _ToolItem(
          title: 'Pipe Sizer',
          desc: 'Thiết kế đường ống nước theo lưu lượng.',
          icon: Icons.water,
          color: Color(0xFF2196F3),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Water Flow Calculator',
          desc: 'Tính lưu lượng nước qua ống.',
          icon: Icons.waves,
          color: Color(0xFF1E88E5),
          route: null,
        ),
        _ToolItem(
          title: 'Pipe Pressure Loss',
          desc: 'Tổn thất áp suất đường ống nước.',
          icon: Icons.horizontal_rule,
          color: Color(0xFF1976D2),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Pump Head Calculator',
          desc: 'Tính cột áp bơm yêu cầu.',
          icon: Icons.arrow_upward,
          color: Color(0xFF1565C0),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Pump Selection',
          desc: 'Chọn bơm theo lưu lượng và cột áp.',
          icon: Icons.water_damage,
          color: Color(0xFF0D47A1),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Expansion Tank Calculator',
          desc: 'Tính dung tích bình giãn nở.',
          icon: Icons.invert_colors,
          color: Color(0xFF0277BD),
          route: null,
          isVipOnly: true,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Load & Psychrometrics',
      emoji: '🌡️',
      icon: Icons.thermostat_auto,
      accent: const Color(0xFFE91E63),
      tools: const [
        _ToolItem(
          title: 'Cooling Load Calculator',
          desc: 'Tính tải lạnh cho phòng / công trình.',
          icon: Icons.severe_cold,
          color: Color(0xFFE91E63),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Heating Load Calculator',
          desc: 'Tính tải sưởi cho phòng / công trình.',
          icon: Icons.local_fire_department,
          color: Color(0xFFEC407A),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Psychrometric Calculator',
          desc: 'Biểu đồ không khí ẩm tra cứu nhanh.',
          icon: Icons.bubble_chart,
          color: Color(0xFFD81B60),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Dew Point Calculator',
          desc: 'Tính điểm sương theo nhiệt độ & độ ẩm.',
          icon: Icons.water_drop_outlined,
          color: Color(0xFFC2185B),
          route: AppRoutes.dewPointCalculator,
        ),
        _ToolItem(
          title: 'Humidity Calculator',
          desc: 'Tính độ ẩm tương đối / tuyệt đối.',
          icon: Icons.opacity,
          color: Color(0xFFAD1457),
          route: AppRoutes.humidityCalculator,
        ),
        _ToolItem(
          title: 'Enthalpy Calculator',
          desc: 'Tính enthalpy không khí ẩm.',
          icon: Icons.whatshot,
          color: Color(0xFF880E4F),
          route: null,
        ),
        _ToolItem(
          title: 'Fresh Air Calculator',
          desc: 'Tính lưu lượng gió tươi theo người / diện tích.',
          icon: Icons.air_outlined,
          color: Color(0xFFF06292),
          route: null,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Conversion',
      emoji: '🔄',
      icon: Icons.swap_horiz,
      accent: const Color(0xFF9C27B0),
      tools: const [
        _ToolItem(
          title: 'HVAC Unit Converter',
          desc: 'Chuyển đổi đơn vị HVAC: BTU/h, HP, kW, Tons...',
          icon: Icons.swap_horiz,
          color: Color(0xFFE91E63),
          route: AppRoutes.unitConverter,
        ),
        _ToolItem(
          title: 'Temperature Converter',
          desc: 'Chuyển đổi °C, °F, K.',
          icon: Icons.thermostat,
          color: Color(0xFFAB47BC),
          route: null,
        ),
        _ToolItem(
          title: 'Flow Converter',
          desc: 'Chuyển đổi CFM, m³/h, L/s, GPM.',
          icon: Icons.waves,
          color: Color(0xFF8E24AA),
          route: null,
        ),
        _ToolItem(
          title: 'Velocity Converter',
          desc: 'Chuyển đổi m/s, FPM, km/h.',
          icon: Icons.speed,
          color: Color(0xFF7B1FA2),
          route: null,
        ),
        _ToolItem(
          title: 'Power Converter',
          desc: 'Chuyển đổi W, kW, HP, BTU/h.',
          icon: Icons.flash_on,
          color: Color(0xFF6A1B9A),
          route: null,
        ),
        _ToolItem(
          title: 'Length Converter',
          desc: 'Chuyển đổi mm, cm, m, inch, ft.',
          icon: Icons.straighten,
          color: Color(0xFF4A148C),
          route: null,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Electrical',
      emoji: '⚡',
      icon: Icons.electric_bolt,
      accent: const Color(0xFFFFC107),
      tools: const [
        _ToolItem(
          title: 'Motor Current Calculator',
          desc: 'Tính dòng điện động cơ 1 pha / 3 pha.',
          icon: Icons.electrical_services,
          color: Color(0xFFFFB300),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Cable Size Calculator',
          desc: 'Tính tiết diện cáp theo dòng tải.',
          icon: Icons.cable,
          color: Color(0xFFFFA000),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Breaker Selector',
          desc: 'Chọn CB (MCB/MCCB) phù hợp.',
          icon: Icons.toggle_on,
          color: Color(0xFFFF8F00),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Power Calculator',
          desc: 'Tính công suất điện 1 pha / 3 pha.',
          icon: Icons.power,
          color: Color(0xFFFF6F00),
          route: null,
        ),
      ],
    ),
    _ToolCategory(
      name: 'Service & Commissioning',
      emoji: '📋',
      icon: Icons.assignment,
      accent: const Color(0xFF4CAF50),
      tools: const [
        _ToolItem(
          title: 'Service Checklist',
          desc: 'Checklist bảo trì định kỳ hệ thống HVAC.',
          icon: Icons.checklist,
          color: Color(0xFF66BB6A),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Commissioning Report',
          desc: 'Biên bản chạy thử & nghiệm thu hệ thống.',
          icon: Icons.assignment_turned_in,
          color: Color(0xFF4CAF50),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Measurement Logger',
          desc: 'Ghi số liệu đo đạc tại hiện trường.',
          icon: Icons.note_add,
          color: Color(0xFF43A047),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Equipment Database',
          desc: 'Cơ sở dữ liệu thiết bị HVAC.',
          icon: Icons.storage,
          color: Color(0xFF388E3C),
          route: null,
          isVipOnly: true,
        ),
        _ToolItem(
          title: 'Error Code Lookup',
          desc: 'Tra mã lỗi các dòng điều hòa thông dụng.',
          icon: Icons.error_outline,
          color: Color(0xFF2E7D32),
          route: null,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final isPremium = userAsync.asData?.value?.isPremium == true;

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
          'Công cụ kỹ thuật',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategorySection(category: category, isPremium: isPremium);
        },
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final _ToolCategory category;
  final bool isPremium;

  const _CategorySection({required this.category, required this.isPremium});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final tools = category.tools;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: category.accent.withValues(alpha: 0.15),
                      border: Border.all(
                        color: category.accent.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${category.emoji}  ${category.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: category.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tools.length}',
                      style: TextStyle(
                        color: category.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      for (int i = 0; i < tools.length; i++) ...[
                        _ToolCard(tool: tools[i], isPremium: widget.isPremium),
                        if (i != tools.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final bool isPremium;

  const _ToolCard({required this.tool, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final showVipBadge = tool.isVipOnly;
    final lockAccess = showVipBadge && !isPremium;
    final hasRoute = tool.route != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (lockAccess) {
          _showVipDialog(context);
        } else if (hasRoute) {
          Navigator.pushNamed(context, tool.route!);
        } else {
          _showComingSoonDialog(context, tool.title);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lockAccess
                ? Colors.amber.withValues(alpha: 0.18)
                : tool.color.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tool.color.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tool.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: tool.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tool.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showVipBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.amber, width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, color: Colors.amber, size: 9),
                              SizedBox(width: 2),
                              Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tool.desc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              lockAccess
                  ? Icons.lock_outline
                  : (hasRoute ? Icons.arrow_forward_ios : Icons.access_time),
              size: 14,
              color: lockAccess
                  ? Colors.amber
                  : (hasRoute
                        ? AppColors.textMuted
                        : AppColors.textMuted.withValues(alpha: 0.6)),
            ),
          ],
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Nâng cấp ngay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top, color: AppColors.accentBright, size: 24),
            SizedBox(width: 8),
            Text('Sắp ra mắt', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Công cụ "$title" đang được phát triển và sẽ được cập nhật trong phiên bản tiếp theo.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(color: AppColors.accentBright),
            ),
          ),
        ],
      ),
    );
  }
}
