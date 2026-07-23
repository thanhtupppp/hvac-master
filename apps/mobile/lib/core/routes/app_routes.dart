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
import '../../screens/tools/category_detail_screen.dart';
import '../../models/tool_item.dart';
import '../../screens/tools/pt_calculator_screen.dart';
import '../../screens/tools/duct_calculator_screen.dart';
import '../../screens/tools/superheat_calculator_screen.dart';
import '../../screens/tools/unit_converter_screen.dart';
import '../../screens/tools/refrigerant_selector_screen.dart';
import '../../screens/tools/pressure_converter_screen.dart';
import '../../screens/tools/airflow_calculator_screen.dart';
import '../../screens/tools/air_velocity_calculator_screen.dart';
import '../../features/air_distribution/screens/duct_pressure_loss_screen.dart';
import '../../features/air_distribution/screens/fitting_loss_screen.dart';
import '../../features/air_distribution/screens/fan_selection_screen.dart';
import '../../features/air_distribution/screens/vav_box_sizing_screen.dart';
import '../../features/air_distribution/screens/diffuser_selection_screen.dart';
import '../../features/air_distribution/screens/grille_selection_screen.dart';
import '../../features/air_distribution/screens/equal_friction_screen.dart';
import '../../features/air_distribution/screens/velocity_reduction_screen.dart';
import '../../features/hydronic/screens/water_flow_screen.dart';
import '../../features/hydronic/screens/pipe_sizer_screen.dart';
import '../../features/hydronic/screens/pipe_pressure_loss_screen.dart';
import '../../screens/tools/ach_calculator_screen.dart';
import '../../screens/tools/saturation_temperature_screen.dart';
import '../../screens/tools/subcooling_calculator_screen.dart';
import '../../screens/tools/dew_point_calculator_screen.dart';
import '../../screens/tools/humidity_calculator_screen.dart';
import '../../screens/paywall/paywall_screen.dart';
import '../../screens/paywall/privacy_policy_screen.dart';
import '../../screens/paywall/terms_screen.dart';
import '../../screens/subscription/subscription_screen.dart';
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
  static const String toolCategory = '/tools/category';
  static const String ptChart = '/tools/pt-chart';
  static const String ductSizer = '/tools/duct-sizer';
  static const String ductPressureLoss = '/tools/pressure-loss';
  static const String fittingLoss = '/tools/fitting-loss';
  static const String fanSelection = '/tools/fan-selection';
  static const String vavBoxSizing = '/tools/vav-box-sizing';
  static const String diffuserSelection = '/tools/diffuser-selection';
  static const String grilleSelection = '/tools/grille-selection';
  static const String equalFriction = '/tools/equal-friction';
  static const String velocityReduction = '/tools/velocity-reduction';
  static const String waterFlow = '/tools/water-flow';
  static const String pipeSizer = '/tools/pipe-sizer';
  static const String pipePressureLoss = '/tools/pipe-pressure-loss';
  static const String superheat = '/tools/refrigerant';
  static const String unitConverter = '/tools/converter';
  static const String refrigerantSelector = '/tools/refrigerant-selector';
  static const String pressureConverter = '/tools/pressure-converter';
  static const String airflowCalculator = '/tools/airflow-calculator';
  static const String airVelocityCalculator = '/tools/air-velocity-calculator';
  static const String achCalculator = '/tools/ach-calculator';
  static const String saturationTemperature = '/tools/saturation-temperature';
  static const String subcoolingCalculator = '/tools/subcooling-calculator';
  static const String dewPointCalculator = '/tools/dew-point';
  static const String humidityCalculator = '/tools/humidity';
  static const String paywall = '/paywall';
  static const String subscription = '/subscription';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';

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
      case toolCategory:
        {
          final category = settings.arguments as ToolCategory?;
          if (category == null) return _errorRoute(settings.name);
          return MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: category),
          );
        }
      case ptChart:
        return MaterialPageRoute(builder: (_) => const PTCalculatorScreen());
      case ductSizer:
        return MaterialPageRoute(builder: (_) => const DuctCalculatorScreen());
      case ductPressureLoss:
        return MaterialPageRoute(
          builder: (_) => const DuctPressureLossScreen(),
        );
      case fittingLoss:
        return MaterialPageRoute(builder: (_) => const FittingLossScreen());
      case fanSelection:
        return MaterialPageRoute(builder: (_) => const FanSelectionScreen());
      case vavBoxSizing:
        return MaterialPageRoute(builder: (_) => const VavBoxSizingScreen());
      case diffuserSelection:
        return MaterialPageRoute(
          builder: (_) => const DiffuserSelectionScreen(),
        );
      case grilleSelection:
        return MaterialPageRoute(builder: (_) => const GrilleSelectionScreen());
      case equalFriction:
        return MaterialPageRoute(builder: (_) => const EqualFrictionScreen());
      case velocityReduction:
        return MaterialPageRoute(
          builder: (_) => const VelocityReductionScreen(),
        );
      case waterFlow:
        return MaterialPageRoute(builder: (_) => const WaterFlowScreen());
      case pipeSizer:
        return MaterialPageRoute(builder: (_) => const PipeSizerScreen());
      case pipePressureLoss:
        return MaterialPageRoute(
          builder: (_) => const PipePressureLossScreen(),
        );
      case superheat:
        return MaterialPageRoute(
          builder: (_) => const SuperheatCalculatorScreen(),
        );
      case unitConverter:
        return MaterialPageRoute(builder: (_) => const UnitConverterScreen());
      case refrigerantSelector:
        return MaterialPageRoute(
          builder: (_) => const RefrigerantSelectorScreen(),
        );
      case pressureConverter:
        return MaterialPageRoute(
          builder: (_) => const PressureConverterScreen(),
        );
      case airflowCalculator:
        return MaterialPageRoute(
          builder: (_) => const AirflowCalculatorScreen(),
        );
      case airVelocityCalculator:
        return MaterialPageRoute(
          builder: (_) => const AirVelocityCalculatorScreen(),
        );
      case achCalculator:
        return MaterialPageRoute(builder: (_) => const AchCalculatorScreen());
      case saturationTemperature:
        return MaterialPageRoute(
          builder: (_) => const SaturationTemperatureScreen(),
        );
      case subcoolingCalculator:
        return MaterialPageRoute(
          builder: (_) => const SubcoolingCalculatorScreen(),
        );
      case dewPointCalculator:
        return MaterialPageRoute(
          builder: (_) => const DewPointCalculatorScreen(),
        );
      case humidityCalculator:
        return MaterialPageRoute(
          builder: (_) => const HumidityCalculatorScreen(),
        );
      case paywall:
        return MaterialPageRoute(builder: (_) => const PaywallScreen());
      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case terms:
        return MaterialPageRoute(builder: (_) => const TermsScreen());
      case brandList:
        {
          final args = _extractArgs(
            settings,
            requiredKeys: ['category', 'categoryName'],
          );
          if (args == null) return _errorRoute(settings.name);
          return MaterialPageRoute(
            builder: (_) => BrandListScreen(
              category: args['category']! as String,
              categoryName: args['categoryName']! as String,
            ),
          );
        }
      case guideList:
        {
          final args = _extractArgs(settings, requiredKeys: ['category']);
          if (args == null) return _errorRoute(settings.name);
          return MaterialPageRoute(
            builder: (_) => GuideListScreen(
              category: args['category']! as String,
              categoryTitle:
                  args['categoryTitle'] as String? ??
                  args['categoryName'] as String? ??
                  '',
              brand: args['brand'] as String?,
              brandName: args['brandName'] as String?,
            ),
          );
        }
      case guideDetail:
        {
          final article = settings.arguments as Article?;
          if (article == null) return _errorRoute(settings.name);
          return MaterialPageRoute(
            builder: (_) => GuideDetailScreen(article: article),
          );
        }
      case pdfViewer:
        {
          final args = _extractArgs(
            settings,
            requiredKeys: ['pdfUrl', 'title'],
          );
          if (args == null) return _errorRoute(settings.name);
          return MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: args['pdfUrl']! as String,
              title: args['title']! as String,
            ),
          );
        }
      default:
        return _errorRoute(settings.name);
    }
  }

  static Map<String, Object?>? _extractArgs(
    RouteSettings settings, {
    required List<String> requiredKeys,
  }) {
    final raw = settings.arguments;
    if (raw is! Map<String, Object?>) return null;
    for (final key in requiredKeys) {
      if (!raw.containsKey(key)) return null;
    }
    return raw;
  }

  static Route<dynamic> _errorRoute(String? name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Route not found: $name')),
      ),
    );
  }
}
