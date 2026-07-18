import 'package:mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/article_provider.dart';
import '../../models/article.dart';
import '../../providers/history_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/utils/category_utils.dart';
import 'widgets/latest_articles_section.dart';
import 'widgets/popular_articles_section.dart';
import 'widgets/history_tab.dart';
import 'widgets/bookmarks_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isUnlocked = true;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _logSearchQuery(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty || cleanText.length < 2) return;
    try {
      FirebaseFirestore.instance
          .collection('search_queries')
          .doc(cleanText.toLowerCase())
          .set({
            'query': cleanText,
            'count': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Ignored if Firestore is unavailable
    }
  }

  Future<void> _loadBiometricSettings() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    final canCheck =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    
    final biometricEnabled = enabled == 'true';

    setState(() {
      _biometricEnabled = biometricEnabled;
      _canCheckBiometrics = canCheck;
      if (biometricEnabled && canCheck) {
        _isUnlocked = false;
      }
    });

    if (biometricEnabled && canCheck) {
      _authenticateOnLaunch();
    }
  }

  Future<void> _authenticateOnLaunch() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực vân tay để truy cập ứng dụng',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        setState(() {
          _isUnlocked = true;
        });
      }
    } catch (e) {
      // Keep it locked
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Authenticate first before enabling
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason:
              'Xác thực sinh trắc học để bật tính năng đăng nhập nhanh',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (didAuthenticate) {
          await _storage.write(key: 'biometric_enabled', value: 'true');
          setState(() {
            _biometricEnabled = true;
          });
        }
      } catch (e) {
        // Handle error
      }
    } else {
      await _storage.delete(key: 'biometric_enabled');
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }


  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.textMuted,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ứng dụng đang khóa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng xác thực vân tay để truy cập',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _authenticateOnLaunch,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3F51B5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              TextButton.icon(
                icon: const Icon(Icons.logout, size: 16),
                label: const Text(
                  'Đăng nhập bằng tài khoản khác',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentBright,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildSearchTab(),
      BookmarksTab(onBack: () => setState(() => _selectedIndex = 0)),
      HistoryTab(onBack: () => setState(() => _selectedIndex = 0)),
      _buildSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary, // Dark theme background
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCustomBottomNavBar() {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / 5;
    final double barHeight = 86;

    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Trang chủ',
      },
      {'icon': Icons.search, 'activeIcon': Icons.search, 'label': 'Tìm kiếm'},
      {
        'icon': Icons.bookmark_outline,
        'activeIcon': Icons.bookmark,
        'label': 'Đã lưu',
      },
      {'icon': Icons.history, 'activeIcon': Icons.history, 'label': 'Lịch sử'},
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Cài đặt',
      },
    ];

    return Container(
      height: barHeight + 20,
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: _selectedIndex.toDouble(),
          end: _selectedIndex.toDouble(),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final double loc = itemWidth * value + (itemWidth / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The curved background
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight + 20,
                child: CustomPaint(
                  painter: _NavPainter(loc),
                  size: Size(width, barHeight + 20),
                ),
              ),

              // The icons and text
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    final isSelected = index == _selectedIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          if (index == 1) {
                            _searchFocusNode.requestFocus();
                          } else {
                            _searchFocusNode.unfocus();
                          }
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: itemWidth,
                        height: barHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 26,
                              child: isSelected
                                  ? const SizedBox()
                                  : Icon(
                                      items[index]['icon'] as IconData,
                                      color: AppColors.textSecondary,
                                      size: 26,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[index]['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accentBright
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // The animated active circle
              Positioned(
                left: loc - 26,
                top: 18,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBright,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    items[_selectedIndex]['activeIcon'] as IconData,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dashboard tab matching the mockup
  Widget _buildDashboardTab() {
    final userAsync = ref.watch(userProfileProvider);
    final userModel = userAsync.asData?.value;

    final displayName = userModel?.displayName ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Kỹ thuật viên');

    final avatarText = displayName.isNotEmpty
        ? displayName.substring(0, displayName.length > 2 ? 2 : displayName.length).toUpperCase()
        : '?';

    final Map<String, List<Color>> avatarGradients = {
      'purple': [const Color(0xFF7C3AED), const Color(0xFF3F51B5)],
      'pink': [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
      'blue': [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
      'orange': [const Color(0xFFFF9800), const Color(0xFFFF5722)],
      'green': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
    };

    final colors = avatarGradients[userModel?.photoURL ?? 'purple'] ?? avatarGradients['purple']!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Custom Avatar
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatarText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (userModel?.isPremium == true)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.stars, color: Colors.white, size: 8),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Tìm mã lỗi, model hoặc triệu chứng...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1; // Switch to Search tab
                          _searchFocusNode.requestFocus();
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.mic, color: Color(0xFF388AF6)),
                ],
              ),
            ),
          ),
        ),

        // Quick Actions Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionItem(
                  Icons.construction,
                  'Công cụ',
                  const Color(0xFF388AF6),
                ),
                _buildQuickActionItem(
                  Icons.search,
                  'Tra Cứu',
                  const Color(0xFFFF9800),
                ),
                _buildQuickActionItem(
                  Icons.forum_outlined,
                  'Cộng đồng',
                  const Color(0xFFE91E63),
                ),
                _buildQuickActionItem(
                  Icons.bookmark_outline,
                  'Đã Lưu',
                  const Color(0xFF00BFA5),
                ),
              ],
            ),
          ),
        ),



        const SliverToBoxAdapter(
          child: LatestArticlesSection(),
        ),
        const SliverToBoxAdapter(
          child: PopularArticlesSection(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (label == 'Tra Cứu') {
              setState(() {
                _selectedIndex = 1; // Switch to Search tab
                _searchFocusNode.requestFocus();
              });
            } else if (label == 'Đã Lưu') {
              setState(() {
                _selectedIndex = 2; // Open Bookmarks
              });
            } else if (label == 'Công cụ') {
              Navigator.pushNamed(context, AppRoutes.tools);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tính năng "$label" đang được phát triển.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }



  // Premium Settings Tab
  Widget _buildSettingsTab() {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      data: (userModel) {
        if (userModel == null) {
          return const Center(
            child: Text(
              'Vui lòng đăng nhập',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final Map<String, List<Color>> avatarGradients = {
          'purple': [const Color(0xFF7C3AED), const Color(0xFF3F51B5)],
          'pink': [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
          'blue': [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
          'orange': [const Color(0xFFFF9800), const Color(0xFFFF5722)],
          'green': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
        };

        final colors = avatarGradients[userModel.photoURL] ?? avatarGradients['purple']!;
        final displayName = userModel.displayName;
        final avatarText = displayName.isNotEmpty
            ? displayName.substring(0, displayName.length > 2 ? 2 : displayName.length).toUpperCase()
            : '?';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Text(
                  'Cài đặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini Profile Card
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: userModel.isPremium ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  avatarText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (userModel.isPremium) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber, width: 0.5),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.stars, color: Colors.amber, size: 10),
                                              SizedBox(width: 4),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    userModel.email,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Thông tin cá nhân & tài khoản >',
                                    style: TextStyle(
                                      color: AppColors.accentBright,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Security Section
                    const Text(
                      'BẢO MẬT & ĐĂNG NHẬP',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.fingerprint, color: Color(0xFF388AF6)),
                                  SizedBox(width: 16),
                                  Text(
                                    'Đăng nhập bằng vân tay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              _canCheckBiometrics
                                  ? Switch(
                                      value: _biometricEnabled,
                                      onChanged: _toggleBiometric,
                                      activeThumbColor: const Color(0xFF388AF6),
                                    )
                                  : const Text(
                                      'Không hỗ trợ',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Log out Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800]?.withValues(alpha: 0.2),
                          foregroundColor: Colors.red[200],
                          elevation: 0,
                          side: BorderSide(color: Colors.red[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Lỗi: ${err.toString()}', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSearchTab() {
    final query = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(searchCategoryProvider);
    final filteredArticles = ref.watch(filteredArticlesProvider);
    final allArticlesAsync = ref.watch(allArticlesProvider);

    // Get unique categories dynamically
    final List<String> dynamicCategories = allArticlesAsync.when(
      data: (articles) {
        final categories = articles.map((a) => a.category).toSet().toList();
        return ['all', ...categories];
      },
      loading: () => ['all'],
      error: (_, _) => ['all'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 24, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // Go back to Dashboard
                  });
                },
              ),
              const Text(
                'Tra cứu mã lỗi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Tìm mã lỗi, model hoặc triệu chứng...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _logSearchQuery,
                  ),
                ),
                if (query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),

        // Category Filter Chips (Dynamic)
        if (dynamicCategories.length > 1)
          Container(
            height: 46,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: dynamicCategories.length,
              itemBuilder: (context, index) {
                final catKey = dynamicCategories[index];
                final isSelected = selectedCategory == catKey;
                final displayTitle = getCategoryDisplayName(catKey);

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      displayTitle,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref
                            .read(searchCategoryProvider.notifier)
                            .setCategory(catKey);
                      }
                    },
                    selectedColor: const Color(0xFF388AF6),
                    backgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.divider,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

        // Results Area
        Expanded(
          child: query.isEmpty
              ? _buildPopularSearches()
              : _buildSearchResults(filteredArticles),
        ),
      ],
    );
  }



  Widget _buildPopularSearches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('search_queries')
          .orderBy('count', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        List<String> popularKeywords = [
          'EB1 Electrolux',
          'OE Daikin',
          'H11 Panasonic',
          'Mất nguồn',
          'Nháy đèn',
        ];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          try {
            popularKeywords = snapshot.data!.docs
                .map((doc) => doc['query'] as String)
                .toList();
          } catch (e) {
            // Keep fallback on data cast issues
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tìm kiếm phổ biến',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: popularKeywords.map((kw) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = kw;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: kw.length),
                      );
                      _logSearchQuery(kw);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bgCard),
                      ),
                      child: Text(
                        kw,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<Article> articles) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy kết quả nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm từ khóa khác hoặc xóa bộ lọc',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final currentQuery = ref.read(searchQueryProvider);
                  if (currentQuery.isNotEmpty) {
                    _logSearchQuery(currentQuery);
                  }
                  ref.read(historyProvider.notifier).addArticleToHistory(article.id);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.guideDetail,
                    arguments: article,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Category indicator circle
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF5BA4F8).withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          getCategoryIcon(article.category),
                          color: const Color(0xFF5BA4F8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    article.titleVi,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (article.isPremium) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[800],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'VIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.contentVi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}

class _NavPainter extends CustomPainter {
  final double loc;

  _NavPainter(this.loc);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.bgSecondary
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Dày lên tí cho cân đối

    final path = Path();
    final double top = 25.0; // The flat part of the bar

    path.moveTo(0, top);
    path.lineTo(loc - 40, top);

    // Smooth bump going up (không đẩy lên quá cao, đỉnh là 10 thay vì 0)
    path.cubicTo(loc - 20, top, loc - 20, 10, loc, 10);
    path.cubicTo(loc + 20, 10, loc + 20, top, loc + 40, top);

    path.lineTo(size.width, top);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black38, 10, false);

    // Draw background
    canvas.drawPath(path, fillPaint);
    
    // Draw top border only
    final borderPath = Path();
    borderPath.moveTo(0, top);
    borderPath.lineTo(loc - 40, top);
    borderPath.cubicTo(loc - 20, top, loc - 20, 10, loc, 10);
    borderPath.cubicTo(loc + 20, 10, loc + 20, top, loc + 40, top);
    borderPath.lineTo(size.width, top);
    
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NavPainter oldDelegate) =>
      oldDelegate.loc != loc;
}


