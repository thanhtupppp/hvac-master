import 'package:flutter/material.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/guide/guide_list_screen.dart';
import '../../screens/guide/guide_detail_screen.dart';
import '../../screens/guide/pdf_viewer_screen.dart';
import '../../screens/brand/brand_list_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/tools/tools_screen.dart';
import '../../screens/tools/pt_calculator_screen.dart';
import '../../screens/tools/duct_calculator_screen.dart';
import '../../screens/tools/superheat_calculator_screen.dart';
import '../../screens/tools/unit_converter_screen.dart';
import '../../screens/tools/refrigerant_selector_screen.dart';
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
  static const String profile = '/profile';
  static const String tools = '/tools';
  static const String ptChart = '/tools/pt-chart';
  static const String ductSizer = '/tools/duct-sizer';
  static const String superheat = '/tools/refrigerant';
  static const String unitConverter = '/tools/converter';
  static const String refrigerantSelector = '/tools/refrigerant-selector';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case tools:
        return MaterialPageRoute(builder: (_) => const ToolsScreen());
      case ptChart:
        return MaterialPageRoute(builder: (_) => const PTCalculatorScreen());
      case ductSizer:
        return MaterialPageRoute(builder: (_) => const DuctCalculatorScreen());
      case superheat:
        return MaterialPageRoute(builder: (_) => const SuperheatCalculatorScreen());
      case unitConverter:
        return MaterialPageRoute(builder: (_) => const UnitConverterScreen());
      case refrigerantSelector:
        return MaterialPageRoute(builder: (_) => const RefrigerantSelectorScreen());
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
