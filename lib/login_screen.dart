import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'Forget_password.dart';
import 'Home_Screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key}); // ✅ removed language parameter

  /// 🌍 Localization helper
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  Widget buildTextField(BuildContext context, String hint, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget buildSmallButton(BuildContext context, String label, VoidCallback onPressed) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF90CF8E),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          text(context, "Welcome Back!", "مرحباً بعودتك!"),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text(context, "Drive safe. Someone is waiting for you.", "'سوق علي مهلك سوق'"),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  buildTextField(context, text(context, "Username", "اسم المستخدم")),
                  buildTextField(context, text(context, "Password", "كلمة المرور"), obscureText: true),
                  Align(
                    alignment: Alignment.centerRight,
                    child: buildSmallButton(
                      context,
                      text(context, "Forgot Password?", "هل نسيت كلمة المرور؟"),
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF90CF8E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                      child: Text(
                        text(context, "LOG IN", "تسجيل الدخول"),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text(context, "Don't have an account?", "ليس لديك حساب؟")),
                        const SizedBox(width: 5),
                        buildSmallButton(
                          context,
                          text(context, "Sign Up", "إنشاء حساب"),
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignUpScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}