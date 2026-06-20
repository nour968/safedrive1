import 'package:flutter/material.dart';
import 'package:untitled1/Splash_Screen.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key}); //

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();

  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasLength = false;
  final String baseUrl = "http://192.168.1.4:8000";
  /// 🌍 Language helper
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
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

  Widget rule(bool valid, String textRule) {
    return Row(
      children: [
        Icon(valid ? Icons.check_circle : Icons.circle_outlined,
            color: valid ? Colors.green : Colors.grey, size: 18),
        const SizedBox(width: 8),
        Text(
          textRule,
          style: TextStyle(color: valid ? Colors.green : Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    String? placeholder,
    bool obscureText = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          labelText: placeholder,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
        validator: validator,
      ),
    );
  }

  // ✅ Validators remain the same
  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) return text(context, "Required", "مطلوب");
    if (!RegExp(r"^[a-zA-Zأ-ي\s]+$").hasMatch(value)) return text(context, "Only letters allowed", "يسمح فقط بالحروف");
    return null;
  }
  String normalizeDigits(String input) {
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const english = ['0','1','2','3','4','5','6','7','8','9'];

    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }
  String? ageValidator(String? value) {
    if (value == null || value.isEmpty) return text(context, "Required", "مطلوب");

    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String normalized = value;
    for (int i = 0; i < arabic.length; i++) {
      normalized = normalized.replaceAll(arabic[i], english[i]);
    }

    if (!RegExp(r"^\d+$").hasMatch(normalized)) {
      return text(context, "Only numbers allowed", "يسمح بالأرقام فقط");
    }

    int age = int.parse(normalized);
    if (age < 18) return text(context, "Must be at least 18 years old", "يجب أن يكون العمر 18 سنة على الأقل");

    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return text(context, "Required", "مطلوب");
    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) return text(context, "Invalid email", "البريد الإلكتروني غير صالح");
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return text(context, "Required", "مطلوب");
    if (!(hasUppercase && hasLowercase && hasNumber && hasSpecial && hasLength)) {
      return text(context, "Password does not meet requirements", "كلمة المرور لا تفي بالمتطلبات");
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value != passwordController.text) return text(context, "Passwords do not match", "كلمة المرور غير متطابقة");
    return null;
  }

  String? nationalIdValidator(String? value) {
    if (value == null || value.isEmpty) return text(context, "Required", "مطلوب");
    if (!RegExp(r"^\d{14}$").hasMatch(value)) return text(context, "Must be exactly 14 digits", "يجب أن يتكون الرقم القومي من 14 رقمًا");
    return null;
  }

  String? licensePlateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return text(context, "Required", "مطلوب");
    }

    String input = value.trim();

    // Normalize Arabic digits → English digits
    const arabicDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const englishDigits = ['0','1','2','3','4','5','6','7','8','9'];

    for (int i = 0; i < arabicDigits.length; i++) {
      input = input.replaceAll(arabicDigits[i], englishDigits[i]);
    }

    // Clean multiple spaces
    input = input.replaceAll(RegExp(r'\s+'), ' ');

    // ONLY Arabic letters allowed (أ-ي range)
    final regex = RegExp(r'^[0-9]{1,4}\s*-\s*[أ-ي](\s+[أ-ي]){0,2}$');

    if (!regex.hasMatch(input)) {
      return text(
        context,
        "Invalid format e.g. 1234-أ ب ج",
        "صيغة غير صحيحة مثل 1234-أ ب ج",
      );
    }

    return null;
  }
  Future<void> signUpUser() async {

    try {

      final response = await http.post(

        Uri.parse("$baseUrl/signup"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({

          "first_name":
          firstNameController.text.trim(),

          "last_name":
          lastNameController.text.trim(),

          "age": normalizeDigits(ageController.text.trim()),

          "username":
          usernameController.text.trim(),

          "email":
          emailController.text.trim(),

          "password":
          passwordController.text.trim(),

          "national_id": normalizeDigits(nationalIdController.text.trim()),

          "license_plate":
          licensePlateController.text.trim(),

        }),
      );

      final data = jsonDecode(response.body);

      print(data);

      if (data["status"] == "success") {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sign Up Successful"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
          ),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );

    }
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () =>Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WelcomeScreen(),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            text(context, "Sign Up", "إنشاء حساب"),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            context: context,
                            controller: firstNameController,
                            hint: text(context, "First Name", "الاسم الأول"),
                            validator: nameValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            context: context,
                            controller: lastNameController,
                            hint: text(context, "Last Name", "اسم العائلة"),
                            validator: nameValidator,
                          ),
                        ),
                      ],
                    ),
                    buildTextField(
                      context: context,
                      controller: ageController,
                      hint: text(context, "Age", "العمر"),
                      validator: ageValidator,
                    ),
                    buildTextField(
                      context: context,
                      controller: usernameController,
                      hint: text(context, "Username", "اسم المستخدم"),
                    ),
                    buildTextField(
                      context: context,
                      controller: emailController,
                      hint: text(context, "Email", "البريد الإلكتروني"),
                      validator: emailValidator,
                    ),
                    buildTextField(
                      context: context,
                      controller: passwordController,
                      hint: text(context, "Password", "كلمة المرور"),
                      obscureText: true,
                      onChanged: checkPassword,
                      validator: passwordValidator,
                    ),
                    const SizedBox(height: 5),
                    rule(hasLength, text(context, "At least 8 characters", "على الأقل 8 أحرف")),
                    rule(hasUppercase, text(context, "One uppercase letter", "حرف كبير واحد")),
                    rule(hasLowercase, text(context, "One lowercase letter", "حرف صغير واحد")),
                    rule(hasNumber, text(context, "One number", "رقم واحد")),
                    rule(hasSpecial, text(context, "One special character", "رمز خاص واحد")),
                    buildTextField(
                      context: context,
                      controller: confirmPasswordController,
                      hint: text(context, "Confirm Password", "تأكيد كلمة المرور"),
                      obscureText: true,
                      validator: confirmPasswordValidator,
                    ),
                    buildTextField(
                      context: context,
                      controller: nationalIdController,
                      hint: text(context, "National ID", "الرقم القومي"),
                      validator: nationalIdValidator,
                    ),
                    buildTextField(
                      context: context,
                      controller: licensePlateController,
                      hint: text(context, "License Plate", "رقم اللوحة"),
                      validator: licensePlateValidator,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF90CF8E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              signUpUser();
                            }
                          },
                          child: Text(
                            text(context, "Sign Up", "إنشاء حساب"),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            text(context, "Already have an account? ", "هل لديك حساب بالفعل؟ "),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              text(context, "Login Here", "تسجيل الدخول"),
                              style: const TextStyle(
                                color: Color(0xFF90CF8E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }
}