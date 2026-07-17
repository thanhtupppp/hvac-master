# Giao diện Đăng nhập Mobile và Admin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai giao diện đăng nhập tối giản kết hợp kính mờ (Minimalist & Glassmorphism) hỗ trợ chế độ Sáng/Tối cho cả Admin Web (React/Next.js) và Mobile (Flutter).

**Architecture:** Sử dụng Firebase Auth làm hạt nhân xác thực trung tâm. Trên Admin, sử dụng `signInWithPopup` cho Google OAuth. Trên Mobile, tích hợp thêm `local_auth` cho xác thực sinh trắc học cục bộ (vân tay/Face ID) và `google_sign_in` cho Google OAuth.

**Tech Stack:** React, Next.js, Tailwind CSS v4, shadcn/ui, Flutter (Dart), `flutter_riverpod`, `local_auth`, `google_sign_in`, Firebase Auth SDK.

## Global Constraints
- Phải hỗ trợ giao diện đáp ứng (Responsive) tốt trên thiết bị di động và máy tính.
- Tự động thay đổi giao diện theo cấu hình hệ thống (Sáng/Tối).
- Sử dụng phông chữ kỹ thuật chính xác (Fira Code/Fira Sans trên Web, và phông chữ thiết kế tương tự trên Mobile).

---

### Task 1: Cấu hình và Bổ sung Dependency cho ứng dụng Mobile

**Files:**
- Modify: [pubspec.yaml](file:///d:/hvac-master/apps/mobile/pubspec.yaml:43-45)

**Interfaces:**
- Consumes: Không có
- Produces: Các package `local_auth` và `google_sign_in` sẵn sàng để import và sử dụng.

- [ ] **Step 1: Bổ sung dependencies vào pubspec.yaml**
  Chèn thêm `local_auth: ^2.2.0` và `google_sign_in: ^6.2.1` vào danh sách dependencies.
  
  Sửa đổi trong `apps/mobile/pubspec.yaml`:
  ```yaml
    google_mobile_ads: ^9.0.0
    purchases_flutter: ^10.4.1
    local_auth: ^2.2.0
    google_sign_in: ^6.2.1
  ```

- [ ] **Step 2: Chạy flutter pub get để tải thư viện mới**
  Run: `flutter pub get` trong thư mục `apps/mobile`
  Expected: Lệnh chạy thành công, tải và cài đặt thành công 2 thư viện mới mà không có xung đột phiên bản.

- [ ] **Step 3: Commit**
  ```bash
  git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
  git commit -m "chore: add local_auth and google_sign_in dependencies to mobile"
  ```

---

### Task 2: Hiện thực Giao diện Đăng nhập Admin Web (Next.js)

**Files:**
- Modify: [page.tsx](file:///d:/hvac-master/apps/admin/src/app/login/page.tsx:1-87)

**Interfaces:**
- Consumes: Firebase Auth SDK, `AuthContext`
- Produces: Giao diện đăng nhập Admin Web hoàn chỉnh tại địa chỉ `/login`.

- [ ] **Step 1: Thay đổi mã nguồn file page.tsx để xây dựng giao diện mới**
  Thay thế toàn bộ nội dung của [page.tsx](file:///d:/hvac-master/apps/admin/src/app/login/page.tsx) bằng giao diện chia đôi màn hình (Split-screen) tối giản với SVG HVAC cách điệu ở cột trái, và thẻ Card đăng nhập Email/Google ở cột phải.
  
  ```tsx
  "use client";

  import { useState } from "react";
  import { Button } from "@/components/ui/button";
  import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
  import { Input } from "@/components/ui/input";
  import { Label } from "@/components/ui/label";
  import { signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider } from "firebase/auth";
  import { auth } from "@/lib/firebase";
  import { useRouter } from "next/navigation";
  import { useAuth } from "@/contexts/AuthContext";
  import { Eye, EyeOff, ShieldCheck } from "lucide-react";

  export default function LoginPage() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const router = useRouter();
    const { user } = useAuth();

    if (user) {
      router.push("/");
      return null;
    }

    const handleLogin = async (e: React.FormEvent) => {
      e.preventDefault();
      setError("");
      setIsLoading(true);

      try {
        await signInWithEmailAndPassword(auth, email, password);
        router.push("/");
      } catch (err: any) {
        console.error(err);
        setError("Đăng nhập thất bại. Vui lòng kiểm tra lại email hoặc mật khẩu.");
      } finally {
        setIsLoading(false);
      }
    };

    const handleGoogleLogin = async () => {
      setError("");
      setIsLoading(true);
      const provider = new GoogleAuthProvider();
      try {
        await signInWithPopup(auth, provider);
        router.push("/");
      } catch (err: any) {
        console.error(err);
        setError("Đăng nhập Google thất bại hoặc bị hủy bỏ.");
      } finally {
        setIsLoading(false);
      }
    };

    return (
      <div className="grid lg:grid-cols-2 min-h-screen w-full bg-slate-50 dark:bg-slate-900 transition-colors duration-300">
        {/* Cột trái: HVAC Pro branding - chỉ Desktop */}
        <div className="hidden lg:flex flex-col justify-between p-12 bg-slate-950 text-white relative overflow-hidden">
          <div className="absolute inset-0 opacity-10">
            {/* Lưới SVG quạt gió cách điệu */}
            <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                  <path d="M 40 0 L 0 0 0 40" fill="none" stroke="currentColor" strokeWidth="1" />
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#grid)" />
            </svg>
          </div>
          
          <div className="z-10 flex items-center gap-3 font-bold text-2xl text-green-500">
            <div className="h-10 w-10 rounded-lg bg-green-500/10 border border-green-500/30 flex items-center justify-center">
              <ShieldCheck className="h-6 w-6 text-green-500" />
            </div>
            <span>HVAC Pro Admin</span>
          </div>

          <div className="z-10 space-y-4">
            <h1 className="text-4xl font-extrabold tracking-tight font-mono">
              Hệ thống Quản trị Tra cứu Kỹ thuật
            </h1>
            <p className="text-slate-400 text-lg max-w-md">
              Công cụ quản lý bài viết hướng dẫn mã lỗi, sơ đồ mạch điện và tài liệu sửa chữa điện lạnh đa ngôn ngữ tích hợp AI.
            </p>
          </div>

          <div className="z-10 text-xs text-slate-500">
            © 2026 HVAC Pro. Đã đăng ký bản quyền.
          </div>
        </div>

        {/* Cột phải: Card đăng nhập */}
        <div className="flex items-center justify-center p-8">
          <Card className="w-full max-w-md border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-950/70 backdrop-blur-md shadow-xl transition-all duration-300">
            <CardHeader className="space-y-1">
              <CardTitle className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
                Đăng nhập hệ thống
              </CardTitle>
              <CardDescription className="text-slate-500 dark:text-slate-400">
                Hãy lựa chọn phương thức đăng nhập bên dưới.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Đăng nhập nhanh Google */}
              <Button 
                variant="outline" 
                className="w-full flex items-center justify-center gap-2 h-10 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-900 dark:text-white hover:bg-slate-50 dark:hover:bg-slate-800"
                onClick={handleGoogleLogin}
                disabled={isLoading}
              >
                <svg className="h-5 w-5" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22-.03-.63z" fillRule="evenodd" />
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                </svg>
                <span>Đăng nhập với Google</span>
              </Button>

              <div className="relative flex items-center justify-center">
                <div className="absolute inset-0 flex items-center">
                  <span className="w-full border-t border-slate-200 dark:border-slate-800" />
                </div>
                <span className="relative px-3 bg-white dark:bg-slate-950 text-xs text-slate-500 uppercase">
                  Hoặc bằng email
                </span>
              </div>

              {/* Form Đăng nhập Email */}
              <form onSubmit={handleLogin} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input 
                    id="email" 
                    placeholder="admin@example.com" 
                    type="email" 
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="border-slate-200 dark:border-slate-800 dark:bg-slate-900"
                    disabled={isLoading}
                  />
                </div>
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label htmlFor="password">Mật khẩu</Label>
                    <a href="#" className="text-xs text-green-600 hover:text-green-500 hover:underline">Quên mật khẩu?</a>
                  </div>
                  <div className="relative">
                    <Input 
                      id="password" 
                      placeholder="••••••••" 
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      className="border-slate-200 dark:border-slate-800 dark:bg-slate-900 pr-10"
                      disabled={isLoading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-300"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </div>
                {error && <p className="text-sm text-red-500">{error}</p>}
                
                <Button 
                  type="submit" 
                  className="w-full h-10 mt-2 bg-green-600 hover:bg-green-500 text-white font-semibold transition-colors duration-300"
                  disabled={isLoading}
                >
                  {isLoading ? "Đang xử lý..." : "Đăng nhập bằng Email"}
                </Button>
              </form>
            </CardContent>
            <CardFooter className="flex justify-center border-t border-slate-100 dark:border-slate-900 py-4">
              <p className="text-xs text-slate-400 dark:text-slate-500 text-center">
                Quyền truy cập hạn chế chỉ dành cho Quản trị viên HVAC Pro.
              </p>
            </CardFooter>
          </Card>
        </div>
      </div>
    );
  }
  ```

- [ ] **Step 2: Chạy kiểm thử thủ công giao diện**
  Giao diện đã đổi, hãy kiểm tra biên dịch bằng cách chạy thử máy chủ phát triển của admin hoặc xem lỗi biên dịch nếu có.
  Run: `npm run build` trong thư mục `apps/admin`
  Expected: Build thành công không có lỗi TypeScript hay lỗi liên kết.

- [ ] **Step 3: Commit**
  ```bash
  git add apps/admin/src/app/login/page.tsx
  git commit -m "feat: implement minimalist and split-screen login page for admin web"
  ```

---

### Task 3: Tạo Màn hình Đăng nhập Mobile (Flutter) với Glassmorphism

**Files:**
- Create: [login_screen.dart](file:///d:/hvac-master/apps/mobile/lib/screens/login/login_screen.dart)

**Interfaces:**
- Consumes: Firebase Auth SDK, `local_auth` package, `google_sign_in` package.
- Produces: Widget `LoginScreen` hiển thị biểu mẫu đăng nhập bằng Email, Google và Vân tay/Face ID.

- [ ] **Step 1: Tạo tệp login_screen.dart**
  Viết giao diện cho `LoginScreen` với cấu trúc `BackdropFilter` làm kính mờ, các form trường nhập và tích hợp Firebase Auth, xác thực vân tay qua `LocalAuthentication` và đăng nhập Google qua `GoogleSignIn`.

  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:local_auth/local_auth.dart';
  import '../home/home_screen.dart';

  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _obscurePassword = true;
    bool _isLoading = false;
    String? _errorMessage;

    final LocalAuthentication _localAuth = LocalAuthentication();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    @override
    void dispose() {
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

    Future<void> _loginWithEmail() async {
      if (!_formKey.currentState!.validate()) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _navigateToHome();
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    Future<void> _loginWithGoogle() async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return; // Hủy đăng nhập
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        _navigateToHome();
      } catch (e) {
        setState(() {
          _errorMessage = 'Đăng nhập Google thất bại hoặc không được hỗ trợ.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    Future<void> _authenticateBiometrics() async {
      try {
        final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

        if (!canAuthenticate) {
          setState(() {
            _errorMessage = 'Thiết bị không hỗ trợ xác thực sinh trắc học.';
          });
          return;
        }

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Vui lòng quét vân tay hoặc khuôn mặt để đăng nhập nhanh',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          // Lưu ý: Trong thực tế, sinh trắc học sẽ dùng để lấy Credentials đã được mã hóa/lưu trước đó.
          // Ở đây mô phỏng đăng nhập thành công vào trang chủ sau khi xác nhận vân tay/khuôn mặt.
          _navigateToHome();
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Lỗi trong quá trình xác thực sinh trắc học.';
        });
      }
    }

    void _navigateToHome() {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF020617)]
                  : const [Color(0xFFE3F2FD), Color(0xFFF5F5F5)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Area
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.ac_unit,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HVAC Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.slate[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hệ thống tra cứu chuyên nghiệp',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.slate[400] : Colors.slate[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Glassmorphism Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.slate[950]!.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.slate[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email Input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập Email.';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Định dạng Email không hợp lệ.';
                                    }
                                    return null;
                                  },
                                  disabled: _isLoading,
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu.';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải chứa ít nhất 6 ký tự.';
                                    }
                                    return null;
                                  },
                                  disabled: _isLoading,
                                ),
                                const SizedBox(height: 12),

                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Quên mật khẩu?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (_errorMessage != null) ...[
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Login Button
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : _loginWithEmail,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? Colors.slate[800] : Colors.slate[300],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Hoặc đăng nhập bằng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.slate[500] : Colors.slate[600],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? Colors.slate[800] : Colors.slate[300],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google & Biometric buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google button
                                    _buildRoundSocialButton(
                                      icon: Image.network(
                                        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                        height: 24,
                                        width: 24,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.g_mobiledata, size: 32),
                                      ),
                                      onTap: _isLoading ? null : _loginWithGoogle,
                                    ),
                                    const SizedBox(width: 24),

                                    // Fingerprint/Biometrics Button
                                    _buildRoundSocialButton(
                                      icon: Icon(
                                        Icons.fingerprint,
                                        size: 28,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onTap: _isLoading ? null : _authenticateBiometrics,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildRoundSocialButton({
      required Widget icon,
      required VoidCallback? onTap,
    }) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.slate[900]!.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            border: Border.all(
              color: isDark ? Colors.slate[800]! : Colors.slate[200]!,
            ),
          ),
          child: icon,
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Commit**
  ```bash
  git add apps/mobile/lib/screens/login/login_screen.dart
  git commit -m "feat: add Glassmorphism LoginScreen for Flutter mobile app"
  ```

---

### Task 4: Tích hợp định tuyến Đăng nhập và sửa OnboardingScreen

**Files:**
- Modify: [onboarding_screen.dart](file:///d:/hvac-master/apps/mobile/lib/screens/onboarding/onboarding_screen.dart:1-58)
- Modify: [main.dart](file:///d:/hvac-master/apps/mobile/lib/main.dart:53-81)

**Interfaces:**
- Consumes: Widget `LoginScreen`
- Produces: Luồng mở ứng dụng được định tuyến qua `OnboardingScreen` đến `LoginScreen`.

- [ ] **Step 1: Cập nhật onboarding_screen.dart để chuyển hướng sang LoginScreen**
  Thay đổi đích đến chuyển hướng khi nhấn nút "Bắt đầu ngay" trong `OnboardingScreen` từ `HomeScreen` sang `LoginScreen`.

  Sửa đổi trong `apps/mobile/lib/screens/onboarding/onboarding_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../login/login_screen.dart';

  class OnboardingScreen extends StatelessWidget {
  ...
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Bắt đầu ngay', style: TextStyle(fontSize: 18)),
  ```

- [ ] **Step 2: Cập nhật main.dart hỗ trợ tự động khôi phục phiên đăng nhập**
  Cập nhật hàm xây dựng ứng dụng trong `main.dart` kiểm tra xem người dùng đã đăng nhập từ trước qua Firebase Auth chưa. Nếu có, chuyển thẳng tới `HomeScreen`. Nếu chưa, chuyển tới `OnboardingScreen`.

  Sửa đổi trong `apps/mobile/lib/main.dart`:
  ```dart
  import 'package:firebase_auth/firebase_auth.dart';
  import 'screens/login/login_screen.dart';
  import 'screens/home/home_screen.dart';

  class HvacApp extends ConsumerWidget {
    const HvacApp({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final currentUser = FirebaseAuth.instance.currentUser;

      return MaterialApp(
        title: 'HVAC Pro',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: currentUser != null ? const HomeScreen() : const OnboardingScreen(),
      );
    }
  }
  ```

- [ ] **Step 3: Chạy phân tích tĩnh mã nguồn Flutter để đảm bảo không có lỗi**
  Run: `flutter analyze`
  Expected: No issues found!

- [ ] **Step 4: Chạy kiểm thử tự động trên mobile để xác thực**
  Run: `flutter test`
  Expected: Smoke test for HvacApp passes.

- [ ] **Step 5: Commit**
  ```bash
  git add apps/mobile/lib/screens/onboarding/onboarding_screen.dart apps/mobile/lib/main.dart
  git commit -m "feat: redirect onboarding and main entry to LoginScreen and add session check"
  ```
