import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/article_provider.dart';

class BrandListScreen extends ConsumerWidget {
  final String category;
  final String categoryName;

  const BrandListScreen({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesByCategoryProvider(category));
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
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
          'Chọn Hãng sản xuất'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: articlesAsync.when(
        data: (articles) {
          return brandsAsync.when(
            data: (brands) {
              // Extract brand IDs that actually have articles in this category
              final existingBrandIds = articles.map((a) => a.brand).toSet();

              // Filter brands list based on existing ones
              final filteredBrands = brands
                  .where((b) => existingBrandIds.contains(b.id))
                  .toList();

              if (filteredBrands.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có hãng nào cho danh mục này'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chọn thương hiệu thiết bị của bạn'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Brand Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: filteredBrands.length,
                      itemBuilder: (context, index) {
                        final brand = filteredBrands[index];
                        return _BrandGridItem(
                          brand: brand,
                          category: category,
                          categoryName: categoryName,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Lỗi tải danh mục hãng'.tr(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
        error: (err, stack) => Center(
          child: Text(
            'Lỗi tải dữ liệu bài viết'.tr(),
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _BrandGridItem extends StatelessWidget {
  final Brand brand;
  final String category;
  final String categoryName;

  const _BrandGridItem({
    required this.brand,
    required this.category,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a nice gradient color based on the brand name/ID
    final List<Color> gradientColors = _getGradientColors(brand.id);

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/guide-list',
          arguments: {
            'category': category,
            'categoryName': categoryName,
            'brand': brand.id,
            'brandName': brand.name,
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Slate 800
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Decorative background gradient circle
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        gradientColors[1].withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Icon / Avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          brand.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Brand Name
                    Text(
                      brand.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String id) {
    switch (id.toLowerCase()) {
      case 'daikin':
        return [const Color(0xFF0284C7), const Color(0xFF0369A1)]; // Sky Blue
      case 'panasonic':
        return [
          const Color(0xFF1E3A8A),
          const Color(0xFF1D4ED8),
        ]; // Dark Royal Blue
      case 'toshiba':
        return [const Color(0xFFDC2626), const Color(0xFFB91C1C)]; // Red
      case 'lg':
        return [
          const Color(0xFFDB2777),
          const Color(0xFFBE185D),
        ]; // Pinkish Red
      case 'electrolux':
        return [const Color(0xFF0F766E), const Color(0xFF115E59)]; // Teal
      case 'samsung':
        return [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]; // Blue
      default:
        return [
          const Color(0xFF4F46E5),
          const Color(0xFF4338CA),
        ]; // Indigo Default
    }
  }
}
