import 'package:flutter/material.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/guide/guide_list_screen.dart';
import '../../screens/guide/guide_detail_screen.dart';
import '../../screens/guide/pdf_viewer_screen.dart';
import '../../screens/brand/brand_list_screen.dart';
import '../../models/article.dart';

class AppRoutes {
  static const String initial = '/'; 
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String brandList = '/brand-list';
  static const String guideList = '/guide-list';
  static const String guideDetail = '/guide-detail';
  static const String pdfViewer = '/pdf-viewer';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case brandList:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return _errorRoute(settings.name);
        return MaterialPageRoute(
          builder: (_) => BrandListScreen(
            category: args['category'] as String,
            categoryName: args['categoryName'] as String,
          ),
        );
      case guideList:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return _errorRoute(settings.name);
        return MaterialPageRoute(
          builder: (_) => GuideListScreen(
            category: args['category'] as String,
            categoryTitle: (args['categoryTitle'] ?? args['categoryName'] ?? '') as String,
            brand: args['brand'] as String?,
            brandName: args['brandName'] as String?,
          ),
        );
      case guideDetail:
        final article = settings.arguments as Article?;
        if (article == null) return _errorRoute(settings.name);
        return MaterialPageRoute(
          builder: (_) => GuideDetailScreen(article: article),
        );
      case pdfViewer:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) return _errorRoute(settings.name);
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            pdfUrl: args['pdfUrl'] as String,
            title: args['title'] as String,
          ),
        );
      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Route not found: $name'),
        ),
      ),
    );
  }
}
