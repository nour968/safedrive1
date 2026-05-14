import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'Edit_profile_screen.dart';
import 'nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // ✅ No language parameter

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  /// 🌍 Language helper
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  /// 📸 Pick image from camera or gallery
  Future pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  /// 📂 Show bottom sheet to pick image
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(text(context, "Take Photo", "التقاط صورة")),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(text(context, "Choose from Gallery", "اختيار من المعرض")),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Widget for profile fields
  Widget profileField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        bottomNavigationBar: const CustomBottomNavBar(
          currentIndex: 2, // 👈 Home tab
        ),
        appBar: AppBar(
          title: Text(text(context, "Profile", "الملف الشخصي")),
          centerTitle: true,
          backgroundColor: const Color(0xFFAED6AE),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                    profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: showImageOptions,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              profileField(text(context, "Name", "الاسم"), "Muhammed Suhail"),
              profileField(text(context, "Username", "اسم المستخدم"), "Muhammed_Suhail_12"),
              profileField(text(context, "Email", "البريد الإلكتروني"), "Muhammed@yahoo.com"),
              profileField(text(context, "Age", "العمر"), "21"),
              profileField(text(context, "National ID", "الرقم القومي"), "304060200818"),
              profileField(text(context, "License Plate", "رقم اللوحة"), "1234-ث ق غ"),
              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Text(text(context, "Edit Personal Information", "تعديل الملف الشخصي"),
                    style: const TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}