import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

import 'Forget_password.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================= SERVER =================
  final String baseUrl = "http://192.168.1.4:8000";

  // ================= FORM =================
  final _formKey = GlobalKey<FormState>();

  // ================= CONTROLLERS =================
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool hidePassword = true;
  // ================= FIELD ERRORS =================
  String? usernameError;
  String? passwordError;

  // ================= LOGIN =================
  Future<void> loginUser() async {
    setState(() {
      usernameError = null;
      passwordError = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print(data);

      // ================= SUCCESS =================
      if (data["status"] == "success") {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setBool("logged_in", true);
        await prefs.setInt("user_id", data["user_id"]);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(),
          ),
        );
      }

      // ================= FIELD ERROR =================
      else {
        setState(() {
          if (data["field"] == "username") {
            usernameError = data["message"];
          } else if (data["field"] == "password") {
            passwordError = data["message"];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= LOCALIZATION =================
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  // ================= TEXT FIELD =================
  Widget buildTextField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    String? errorText,
    bool obscureText = false,
  }) {
    bool isPasswordField = controller == passwordController;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: TextFormField(

        controller: controller,

        obscureText:
        isPasswordField
            ? hidePassword
            : obscureText,

        onChanged: (_) {
          setState(() {
            if (controller == usernameController) {
              usernameError = null;
            } else {
              passwordError = null;
            }
          });
        },

        validator: (value) {
          if (value == null || value.isEmpty) {
            return text(
              context,
              "Required",
              "مطلوب",
            );
          }
          return null;
        },

        decoration: InputDecoration(

          hintText: hint,

          errorText: errorText,

          filled: true,

          fillColor: Colors.white,

          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(25),
          ),

          suffixIcon:
          isPasswordField
              ? IconButton(

            icon: Icon(
              hidePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),

            onPressed: () {
              setState(() {
                hidePassword =
                !hidePassword;
              });
            },

          )
              : null,
        ),
      ),
    );
  }

  // ================= SMALL BUTTON =================
  Widget buildSmallButton(
      BuildContext context,
      String label,
      VoidCallback onPressed,
      ) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF90CF8E),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    Align(
                      alignment: Localizations.localeOf(context).languageCode == 'ar'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const SizedBox(height: 40),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            text(context, "Welcome Back!", "مرحباً بعودتك!"),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text(
                              context,
                              "Drive safe. Someone is waiting for you.",
                              "سوق علي مهلك سوق",
                            ),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // USERNAME
                    buildTextField(
                      context: context,
                      hint: text(context, "Username", "اسم المستخدم"),
                      controller: usernameController,
                      errorText: usernameError,
                    ),

                    // PASSWORD
                    buildTextField(
                      context: context,
                      hint: text(
                        context,
                        "Password",
                        "كلمة المرور",
                      ),
                      controller: passwordController,
                      obscureText: true,
                      errorText: passwordError,
                    ),

                    const SizedBox(height: 20),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: buildSmallButton(
                        context,
                        text(
                          context,
                          "Forgot Password?",
                          "هل نسيت كلمة المرور؟",
                        ),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const ForgetPasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LOGIN BUTTON
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF90CF8E),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await loginUser();
                          }
                        },
                        child: Text(
                          text(context, "LOG IN", "تسجيل الدخول"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SIGN UP
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(text(
                            context,
                            "Don't have an account?",
                            "ليس لديك حساب؟",
                          )),
                          buildSmallButton(
                            context,
                            text(context, "Sign Up", "إنشاء حساب"),
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                  const SignUpScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}