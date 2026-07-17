import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/article.dart';
import '../../providers/article_provider.dart';
import '../../core/routes/app_routes.dart';

class GuideListScreen extends ConsumerWidget {
  final String category;
  final String categoryTitle;
  final String? brand;
  final String? brandName;

  const GuideListScreen({
    super.key,
    required this.category,
    required this.categoryTitle,
    this.brand,
    this.brandName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsyncValue = brand != null && brand!.isNotEmpty
        ? ref.watch(articlesByCategoryAndBrandProvider({
            'category': category,
            'brand': brand!,
          }))
        : ref.watch(articlesByCategoryProvider(category));
    final langCode = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          brandName != null ? '$categoryTitle $brandName' : categoryTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: articlesAsyncValue.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(
              child: Text('Không có tài liệu hoặc hướng dẫn nào.'),
            );
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final Article article = articles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[900],
                      child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                          ? Image.network(
                              article.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.description_outlined,
                              color: Color(0xFF388AF6),
                            ),
                    ),
                  ),
                  title: Text(
                    article.getTitle(langCode),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    article.isPremium ? 'Nội dung VIP (Premium)' : 'Miễn phí',
                    style: TextStyle(
                      color: article.isPremium ? Colors.amber[800] : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (article.isPremium)
                        const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.guideDetail,
                      arguments: article,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text('Lỗi tải dữ liệu: $err'),
        ),
      ),
    );
  }
}
