import 'package:flutter/material.dart';
import 'profile_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key}); // ✅ No language parameter

  /// 🌍 Language helper
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  /// 🔹 Build editable text field
  Widget buildField(BuildContext context, String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
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
        appBar: AppBar(
          title: Text(text(context, "Edit Profile", "تعديل الملف الشخصي")),
          backgroundColor: const Color(0xFFAED6AE),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              buildField(context, text(context, "Name", "الاسم"), "Muhammed Suhail"),
              buildField(context, text(context, "Username", "اسم المستخدم"), "Muhammed_Suhail_12"),
              buildField(context, text(context, "Email", "البريد الإلكتروني"), "Muhammed@yahoo.com"),
              buildField(context, text(context, "Age", "العمر"), "21"),
              buildField(context, text(context, "National ID", "الرقم القومي"), "304060200818"),
              buildField(context, text(context, "License Plate", "رقم اللوحة"), "8778 س ب ج"),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8BC98B),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  // Go back to Profile screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Text(text(context, "Save Profile", "حفظ الملف"),
                    style: const TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}