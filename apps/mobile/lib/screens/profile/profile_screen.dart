import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Preset avatar gradients map
  final Map<String, List<Color>> _avatarGradients = {
    'purple': [const Color(0xFF7C3AED), const Color(0xFF3F51B5)],
    'pink': [const Color(0xFFE91E63), const Color(0xFF9C27B0)],
    'blue': [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
    'orange': [const Color(0xFFFF9800), const Color(0xFFFF5722)],
    'green': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile(UserModel user) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _errorMessage = 'Tên hiển thị không được bỏ trống';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(userProfileServiceProvider).updateDisplayName(newName);
      setState(() {
        _successMessage = 'Cập nhật thông tin thành công!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Cập nhật thất bại. Vui lòng thử lại.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _changeAvatarColor(String colorName) async {
    try {
      await ref.read(userProfileServiceProvider).updateAvatarColor(colorName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật màu sắc ảnh đại diện!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đổi màu ảnh đại diện.')),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text(
          'Xóa tài khoản?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Hành động này không thể hoàn tác. Mọi dữ liệu đã lưu, lịch sử và đăng ký VIP của bạn sẽ bị xóa vĩnh viễn.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              _executeDeleteAccount();
            },
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeDeleteAccount() async {
    setState(() {
      _isSaving = true;
    });
    try {
      await ref.read(userProfileServiceProvider).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Yêu cầu đăng nhập lại', style: TextStyle(color: Colors.white)),
          content: Text(
            e.toString().contains('đăng nhập lại')
                ? 'Để thực hiện thao tác nhạy cảm này, vui lòng đăng xuất và đăng nhập lại tài khoản của bạn.'
                : 'Đã có lỗi xảy ra: ${e.toString()}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Trang cá nhân',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Vui lòng đăng nhập để xem thông tin.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Initialize controller with display name once loaded
          if (_nameController.text.isEmpty && !_isSaving) {
            _nameController.text = user.displayName;
          }

          final colors = _avatarGradients[user.photoURL] ?? _avatarGradients['purple']!;
          final avatarText = user.displayName.isNotEmpty
              ? user.displayName.substring(0, user.displayName.length > 2 ? 2 : user.displayName.length).toUpperCase()
              : '?';

          final expiryText = user.premiumExpiry != null
              ? DateFormat('dd/MM/yyyy').format(user.premiumExpiry!)
              : 'Vĩnh viễn';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Area with selection
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            avatarText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      if (user.isPremium)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.stars, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Choose Avatar Preset
                const Text(
                  'CHỌN MÀU ĐẠI DIỆN',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _avatarGradients.keys.map((colorKey) {
                    final gradColors = _avatarGradients[colorKey]!;
                    final isSelected = user.photoURL == colorKey;

                    return GestureDetector(
                      onTap: () => _changeAvatarColor(colorKey),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.transparent),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // VIP Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isPremium ? Colors.amber.withValues(alpha: 0.3) : AppColors.divider,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isPremium ? Icons.stars : Icons.star_outline,
                        color: user.isPremium ? Colors.amber : AppColors.textMuted,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isPremium ? 'Tài khoản Premium (VIP)' : 'Tài khoản Miễn phí',
                              style: TextStyle(
                                color: user.isPremium ? Colors.amber : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isPremium ? 'Hết hạn ngày: $expiryText' : 'Nâng cấp để mở khóa mọi tài liệu kỹ thuật.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Information Form
                const Text(
                  'THÔNG TIN TÀI KHOẢN',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Address (Read-only)
                      const Text(
                        'Email đăng ký',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Divider(height: 32, color: AppColors.divider),

                      // Display Name Input
                      const Text(
                        'Tên hiển thị',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Nhập tên hiển thị...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentPrimary),
                          ),
                          filled: true,
                          fillColor: AppColors.bgPrimary,
                        ),
                        enabled: !_isSaving,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Save changes Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSaving ? null : () => _saveProfile(user),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Lưu thay đổi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // Danger zone section
                const Text(
                  'TÙY CHỌN TÀI KHOẢN',
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Logout
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white70),
                        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      // Delete account
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        title: const Text('Yêu cầu xóa tài khoản', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                        onTap: _confirmDeleteAccount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Đã có lỗi xảy ra: ${err.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
