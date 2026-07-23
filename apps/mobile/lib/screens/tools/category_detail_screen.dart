import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tool_item.dart';

class CategoryDetailScreen extends StatelessWidget {
  final ToolCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final tools = category.tools;

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
        title: Text(
          '${category.emoji}  ${category.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: ClipRRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    category.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: category.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Row(
                      children: [
                        Icon(category.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${tools.length} công cụ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: category.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Danh sách công cụ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                return _ToolGridCard(
                  tool: tools[index],
                  accent: category.accent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolGridCard extends StatelessWidget {
  final ToolItem tool;
  final Color accent;

  const _ToolGridCard({required this.tool, required this.accent});

  @override
  Widget build(BuildContext context) {
    final hasRoute = tool.hasRoute;
    final isComingSoon = !tool.isReady;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (hasRoute) {
          Navigator.pushNamed(context, tool.route!);
        } else if (isComingSoon) {
          _showComingSoonDialog(context, tool.title);
        } else {
          // VIP-locked tool (route == null && isReady == true)
          _showComingSoonDialog(context, tool.title);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tool.color.withValues(alpha: 0.18),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tool.color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: tool.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 20),
                ),
                if (isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Sắp ra mắt',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    hasRoute ? Icons.arrow_forward_ios : Icons.lock_outline,
                    size: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              tool.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              tool.desc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (tool.standard != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 10,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    tool.standard!,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
