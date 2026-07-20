/// Interval/billing cycle for a subscription plan.
enum PlanInterval { monthly, quarterly, yearly, lifetime }

/// Store / provider that sells the plan.
enum PlanProvider { googlePlay, appStore, web }

/// Theme color for the plan card.
enum PlanTheme { blue, purple, gold }

/// A subscription plan — mirrors the SubscriptionPlan type from the admin backend.
class Plan {
  final String id;
  final String? entitlementId;
  final String planCode;
  final String name;
  final String? nameEn;
  final String? description;
  final int priceVND;
  final double? priceUSD;
  final PlanInterval interval;
  final int? durationDays;
  final int trialDays;
  final String productId;
  final PlanProvider provider;
  final List<String> features;
  final bool isFeatured;
  final int sortOrder;
  final bool isActive;
  final String? badge;
  final PlanTheme theme;

  const Plan({
    required this.id,
    this.entitlementId,
    required this.planCode,
    required this.name,
    this.nameEn,
    this.description,
    required this.priceVND,
    this.priceUSD,
    required this.interval,
    this.durationDays,
    required this.trialDays,
    required this.productId,
    required this.provider,
    required this.features,
    required this.isFeatured,
    required this.sortOrder,
    required this.isActive,
    this.badge,
    this.theme = PlanTheme.blue,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as String? ?? '',
      entitlementId: json['entitlementId'] as String?,
      planCode: json['planCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String?,
      description: json['description'] as String?,
      priceVND: (json['priceVND'] as num?)?.toInt() ?? 0,
      priceUSD: (json['priceUSD'] as num?)?.toDouble(),
      interval: _parseInterval(json['interval'] as String?),
      durationDays: json['durationDays'] as int?,
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 0,
      productId: json['productId'] as String? ?? '',
      provider: _parseProvider(json['provider'] as String?),
      features:
          (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      badge: json['badge'] as String?,
      theme: _parseTheme(json['theme'] as String?),
    );
  }

  /// Formatted price string in VND (e.g. "99.000 đ").
  String get priceVNDFormatted {
    final s = priceVND.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  /// Short period label (e.g. "1 tháng", "3 tháng").
  String get periodLabel {
    switch (interval) {
      case PlanInterval.monthly:
        return '1 tháng';
      case PlanInterval.quarterly:
        return '3 tháng';
      case PlanInterval.yearly:
        return '12 tháng';
      case PlanInterval.lifetime:
        return 'Vĩnh viễn';
    }
  }
}

PlanInterval _parseInterval(String? v) {
  switch (v) {
    case 'monthly':
      return PlanInterval.monthly;
    case 'quarterly':
      return PlanInterval.quarterly;
    case 'yearly':
      return PlanInterval.yearly;
    case 'lifetime':
      return PlanInterval.lifetime;
    default:
      return PlanInterval.monthly;
  }
}

PlanProvider _parseProvider(String? v) {
  switch (v) {
    case 'google_play':
      return PlanProvider.googlePlay;
    case 'app_store':
      return PlanProvider.appStore;
    case 'web':
      return PlanProvider.web;
    default:
      return PlanProvider.googlePlay;
  }
}

PlanTheme _parseTheme(String? v) {
  switch (v) {
    case 'blue':
      return PlanTheme.blue;
    case 'purple':
      return PlanTheme.purple;
    case 'gold':
      return PlanTheme.gold;
    default:
      return PlanTheme.blue;
  }
}
