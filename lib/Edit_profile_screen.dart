import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  final int userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  final nationalIdController = TextEditingController();
  final licenseController = TextEditingController();

  bool isLoading = true;

  String? usernameServerError; // 🔥 backend error

  // =========================
  // TEXT HELPER
  // =========================
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // =========================
  // DIGIT NORMALIZER
  // =========================
  String normalizeDigits(String input) {
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    const english = ['0','1','2','3','4','5','6','7','8','9'];

    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  // =========================
  // VALIDATORS
  // =========================
  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }
    if (!RegExp(r"^[a-zA-Zأ-ي\s]+$").hasMatch(value)) {
      return text(context, "Only letters allowed", "يسمح فقط بالحروف");
    }
    return null;
  }

  // 🔥 UPDATED: Username validator - English only, no spaces
  String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return text(
        context,
        "Only English, numbers, underscore",
        "الإنجليزية والأرقام والشرطة السفلية فقط",
      );
    }

    if (value.contains(' ')) {
      return text(context, "No spaces allowed", "لا توجد مسافات مسموحة");
    }

    return usernameServerError; // 🔥 backend error here
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }
    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
      return text(context, "Invalid email", "البريد الإلكتروني غير صالح");
    }
    return null;
  }

  String? ageValidator(String? value) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }

    String normalized = normalizeDigits(value);

    if (!RegExp(r"^\d+$").hasMatch(normalized)) {
      return text(context, "Only numbers allowed", "يسمح بالأرقام فقط");
    }

    int age = int.parse(normalized);
    if (age < 18) {
      return text(context, "Must be 18+", "يجب أن يكون العمر 18+");
    }

    return null;
  }

  String? nationalIdValidator(String? value) {
    if (value == null || value.isEmpty) {
      return text(context, "Required", "مطلوب");
    }

    String normalized = normalizeDigits(value);

    if (!RegExp(r"^\d{14}$").hasMatch(normalized)) {
      return text(context, "Must be 14 digits", "يجب 14 رقمًا");
    }

    return null;
  }

  String? licensePlateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return text(context, "Required", "مطلوب");
    }

    String input = normalizeDigits(value.trim());
    input = input.replaceAll(RegExp(r'\s+'), ' ');

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

  // =========================
  // LOAD USER
  // =========================
  Future<void> loadUser() async {
    final res = await http.get(
      Uri.parse("http://192.168.1.4:8000/get-user/${widget.userId}"),
    );

    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      final user = data["user"];

      setState(() {
        nameController.text = user["name"] ?? "";
        usernameController.text = user["username"] ?? "";
        emailController.text = user["email"] ?? "";
        ageController.text = (user["age"] ?? "").toString();
        nationalIdController.text = user["national_id"] ?? "";
        licenseController.text = user["license_plate"] ?? "";
        isLoading = false;
      });
    }
  }

  // =========================
  // SAVE USER
  // =========================
  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final res = await http.post(
      Uri.parse("http://192.168.1.4:8000/update-user/${widget.userId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "first_name": nameController.text.split(" ").first,
        "last_name": nameController.text.split(" ").length > 1
            ? nameController.text.split(" ").last
            : "",
        "username": usernameController.text,
        "email": emailController.text,
        "age": normalizeDigits(ageController.text),
        "national_id": normalizeDigits(nationalIdController.text),
        "license_plate": licenseController.text,
      }),
    );

    final data = jsonDecode(res.body);

    if (data["status"] == "success") {
      Navigator.pop(context, true);
    } else {
      setState(() {
        usernameServerError = data["message"]; // 🔥 show under field
      });

      _formKey.currentState!.validate();
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          backgroundColor: const Color(0xFF8BC98B),
          title: Text(
            text(context, "Edit Profile", "تعديل الملف الشخصي"),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  controller: nameController,
                  validator: nameValidator,
                  decoration: InputDecoration(
                    labelText: text(context, "Name", "الاسم"),
                  ),
                ),

                // 🔥 UPDATED: Username field with helper text and input formatter
                TextFormField(
                  controller: usernameController,
                  validator: usernameValidator, // ✅ FIXED
                  onChanged: (_) {
                    setState(() => usernameServerError = null);
                  },
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))
                  ],
                  decoration: InputDecoration(
                    labelText: text(context, "Username", "اسم المستخدم"),
                    // 🔥 Helper text below field
                    helperText: text(
                      context,
                      "English letters, numbers, underscore only (no spaces)",
                      "الحروف الإنجليزية والأرقام والشرطة السفلية فقط (بدون مسافات)",
                    ),
                    helperMaxLines: 2,
                  ),
                ),

                TextFormField(
                  controller: emailController,
                  validator: emailValidator,
                  decoration: InputDecoration(
                    labelText: text(context, "Email", "البريد الإلكتروني"),
                  ),
                ),

                TextFormField(
                  controller: ageController,
                  validator: ageValidator,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: text(context, "Age", "العمر"),
                  ),
                ),

                TextFormField(
                  controller: nationalIdController,
                  validator: nationalIdValidator,
                  decoration: InputDecoration(
                    labelText: text(context, "National ID", "الرقم القومي"),
                  ),
                ),

                TextFormField(
                  controller: licenseController,
                  validator: licensePlateValidator,
                  decoration: InputDecoration(
                    labelText: text(context, "License Plate", "رقم اللوحة"),
                  ),
                ),

                const SizedBox(height: 20),

                // ======================================================
                // SAVE BUTTON
                // ======================================================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8BC98B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: saveUser,
                    child: Text(
                      text(context, "Save", "حفظ"),
                      style: const TextStyle(
                        color: Colors.white,
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
      ),
    );
  }
}