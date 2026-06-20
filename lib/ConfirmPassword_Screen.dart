import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class ConfirmPasswordScreen extends StatefulWidget {
  final String email;

  const ConfirmPasswordScreen({super.key, required this.email});

  @override
  State<ConfirmPasswordScreen> createState() =>
      _ConfirmPasswordScreenState();
}

class _ConfirmPasswordScreenState extends State<ConfirmPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmPasswordController =
  TextEditingController();

  bool isLoading = false;

  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasLength = false;

  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar'
        ? ar
        : en;
  }

  void checkPassword(String password) {
    setState(() {
      hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      hasNumber = RegExp(r'\d').hasMatch(password);
      hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      hasLength = password.length >= 8;
    });
  }

  String? passwordValidator(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }
    if (!(hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecial &&
        hasLength)) {
      return text(context,
          "Password does not meet requirements",
          "كلمة المرور لا تحقق الشروط");
    }
    return null;
  }

  String? confirmPasswordValidator(
      String? value, BuildContext context) {
    if (value != passwordController.text) {
      return text(
          context,
          "Passwords do not match",
          "كلمتا المرور غير متطابقتين");
    }
    return null;
  }

  Future<void> resetPassword() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.4:8000/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "new_password": passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text(
                context,
                "Password changed successfully",
                "تم تغيير كلمة المرور بنجاح")),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget rule(bool valid, String ruleText) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.circle_outlined,
          color: valid ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(ruleText, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget buildPasswordField(BuildContext context) {
    return TextFormField(
      controller: passwordController,
      obscureText: true,
      onChanged: checkPassword,
      validator: (value) =>
          passwordValidator(value, context),
      decoration: InputDecoration(
        hintText: text(
            context, "New Password", "كلمة المرور الجديدة"),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget buildConfirmPasswordField(BuildContext context) {
    return TextFormField(
      controller: confirmPasswordController,
      obscureText: true,
      validator: (value) =>
          confirmPasswordValidator(value, context),
      decoration: InputDecoration(
        hintText: text(
            context, "Confirm Password", "تأكيد كلمة المرور"),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection:
      isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 30, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                Text(
                  text(context,
                      "Set New Password",
                      "تعيين كلمة مرور جديدة"),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                buildPasswordField(context),

                const SizedBox(height: 15),

                rule(hasLength,
                    text(context, "At least 8 characters",
                        "على الأقل 8 أحرف")),
                rule(hasUppercase,
                    text(context, "One uppercase letter",
                        "حرف كبير واحد")),
                rule(hasLowercase,
                    text(context, "One lowercase letter",
                        "حرف صغير واحد")),
                rule(hasNumber,
                    text(context, "One number", "رقم واحد")),
                rule(hasSpecial,
                    text(context,
                        "One special character",
                        "رمز خاص واحد")),

                const SizedBox(height: 20),

                buildConfirmPasswordField(context),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF8BC98B),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                      if (_formKey.currentState!
                          .validate()) {
                        resetPassword();
                      }
                    },
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text(
                      text(context, "SUBMIT", "إرسال"),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}