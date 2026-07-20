import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// RevenueCat service — singleton wrapper around purchases_flutter v10.
/// Call RevenueCatService.initialize() once in main() after Firebase init.
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  /// RevenueCat API key passed via --dart-define=REVENUECAT_API_KEY=...
  /// Prefix with "goog_" for Google Play, "appl_" for App Store.
  /// Falls back to a development key only in debug mode (never production).
  String get _apiKey {
    // ignore: avoid_dynamic_calls
    const apiKey = String.fromEnvironment(
      'REVENUECAT_API_KEY',
      defaultValue: '',
    );
    if (apiKey.isNotEmpty) return apiKey;

    // Development fallback — never ship with a real entitlement.
    assert(() {
      // ignore: avoid_print
      print(
        '[RevenueCat] WARNING: Using placeholder API key in debug mode. '
        'Set --dart-define=REVENUECAT_API_KEY=goog_... for real purchases.',
      );
      return true;
    }());
    return 'YOUR_REVENUECAT_API_KEY';
  }

  /// Entitlement identifier as configured in the RevenueCat dashboard.
  /// This must match exactly (e.g., "vip", "premium", "pro").
  static const String entitlementId = 'vip';

  bool _initialized = false;

  /// Initialize the RevenueCat SDK. Call once at app startup, after Firebase.
  Future<void> initialize() async {
    if (_initialized) return;

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    // purchases_flutter v10+ uses PurchasesConfiguration
    await Purchases.configure(PurchasesConfiguration(_apiKey));

    _initialized = true;

    // Sync Firebase user with RevenueCat so backend receives correct UID
    await _syncUser();
  }

  /// Sync the current Firebase user to RevenueCat.
  /// RevenueCat stores the appUserID (Firebase UID) and sends it in webhooks,
  /// so the backend can map purchases to Firestore user docs.
  Future<void> _syncUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // logIn accepts the Firebase UID as the RevenueCat appUserID
      await Purchases.logIn(user.uid);
    } catch (e) {
      debugPrint('[RevenueCat] login failed: $e');
    }
  }

  /// Call this on Firebase Auth state changes (login/logout).
  Future<void> onAuthStateChanged(User? user) async {
    if (user != null) {
      await Purchases.logIn(user.uid);
    } else {
      await Purchases.logOut();
    }
  }

  // ─── Offerings ───────────────────────────────────────────────────────────

  /// Fetch packages configured in the RevenueCat dashboard.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] getOfferings failed: $e');
      return null;
    }
  }

  /// Get the default (annual) package from the current offering.
  /// Falls back to the first available package if no annual found.
  Package? getDefaultPackage(Offerings? offerings) {
    if (offerings == null) return null;
    final current = offerings.current;
    if (current == null) return null;

    return _bestPackage(current.availablePackages);
  }

  Package? _bestPackage(List<Package> packages) {
    if (packages.isEmpty) return null;

    // Prefer annual, then monthly, then any other
    return packages.firstWhere(
      (p) => p.packageType == PackageType.annual,
      orElse: () => packages.firstWhere(
        (p) => p.packageType == PackageType.monthly,
        orElse: () => packages.first,
      ),
    );
  }

  // ─── Purchase ────────────────────────────────────────────────────────────

  /// Purchase a package. Returns true if VIP entitlement is now active.
  /// Throws [UserCancelledException] if user dismisses the paywall.
  /// Throws other exceptions on purchase failure.
  Future<bool> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    final customerInfo = result.customerInfo;
    return customerInfo.entitlements.all[entitlementId]?.isActive == true;
  }

  /// Restore purchases. Returns true if any active entitlement was restored.
  Future<bool> restore() async {
    final customerInfo = await Purchases.restorePurchases();
    return customerInfo.entitlements.all[entitlementId]?.isActive == true;
  }

  // ─── Entitlement status ──────────────────────────────────────────────────

  /// True if the VIP entitlement is currently active.
  Future<bool> isVipActive() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[entitlementId]?.isActive == true;
    } catch (e) {
      debugPrint('[RevenueCat] isVipActive failed: $e');
      return false;
    }
  }

  /// True if the user is currently in a free trial period.
  Future<bool> isInTrial() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[entitlementId]?.isActive == true &&
          info.entitlements.all[entitlementId]?.willRenew == false;
    } catch (e) {
      return false;
    }
  }

  /// Expiry date of the current entitlement, or null.
  Future<DateTime?> getExpiryDate() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final dateStr = info.entitlements.all[entitlementId]?.expirationDate;
      return dateStr != null ? DateTime.tryParse(dateStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// The product ID (SKU) of the active entitlement, or null.
  Future<String?> getActiveProductId() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[entitlementId]?.productIdentifier;
    } catch (e) {
      return null;
    }
  }
}
