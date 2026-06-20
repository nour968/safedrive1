import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Edit_profile_screen.dart';
import 'nav_bar.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  File? profileImage;

  final ImagePicker picker = ImagePicker();

  Map<String, dynamic>? userData;

  bool isLoading = true;

  // ======================================================
  // LANGUAGE HELPER
  // ======================================================

  String text(BuildContext context, String en, String ar) {

    return Localizations.localeOf(context)
        .languageCode == 'ar'
        ? ar
        : en;
  }

  // ======================================================
  // INIT STATE
  // ======================================================


  late int userId;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getInt("user_id")!;
    });

    fetchUserData();
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }
  // ======================================================
  // FETCH USER DATA
  // ======================================================
      Future<void> fetchUserData() async {
        try {
          final response = await http.get(
            Uri.parse("http://192.168.1.4:8000/get-user/$userId"),
          );

          final data = jsonDecode(response.body);

          if (data["status"] == "success") {
            setState(() {
              userData = data["user"];
              isLoading = false;
            });
          } else {
            setState(() => isLoading = false);

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

  // ======================================================
  // UPLOAD IMAGE
  // ======================================================
  Future<void> uploadProfileImage(
      File imageFile,
      ) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "http://192.168.1.4:8000/upload-profile-image/$userId",
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
        ),
      );

      var response = await request.send();

      var responseBody =
      await response.stream.bytesToString();

      var data = jsonDecode(responseBody);

      if (data["status"] == "success") {
        await fetchUserData();
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
          content: Text("Upload Error: $e"),
        ),
      );
    }
  }
  // ======================================================
  // PICK IMAGE
  // ======================================================

  Future<void> pickImage(
      ImageSource source,
      ) async {

    final XFile? image =
    await picker.pickImage(
      source: source,
    );

    if (image == null) return;

    await uploadProfileImage(
      File(image.path),
    );
  }


  // ======================================================
  // IMAGE OPTIONS
  // ======================================================

  void showImageOptions() {

    showModalBottomSheet(

      context: context,

      builder: (context) {

        return SafeArea(

          child: Wrap(

            children: [

              ListTile(

                leading: const Icon(Icons.camera_alt),

                title: Text(
                  text(
                    context,
                    "Take Photo",
                    "التقاط صورة",
                  ),
                ),

                onTap: () {

                  Navigator.pop(context);

                  pickImage(ImageSource.camera);
                },
              ),

              ListTile(

                leading: const Icon(Icons.photo_library),

                title: Text(
                  text(
                    context,
                    "Choose from Gallery",
                    "اختيار من المعرض",
                  ),
                ),

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

  // ======================================================
  // PROFILE FIELD
  // ======================================================

  Widget profileField(
      String title,
      String value,
      ) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 10),

        const Divider(),
      ],
    );
  }

  // ======================================================
  // UI
  // ======================================================

  @override
  Widget build(BuildContext context) {

    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(

      textDirection:
      isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,

      child: Scaffold(

        backgroundColor: Colors.white,

        bottomNavigationBar: const CustomBottomNavBar(
          currentIndex: 2,
        ),

        appBar: AppBar(
          centerTitle: true,
          title: Text(
            text(context, "Profile", "الملف الشخصي"),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          backgroundColor: const Color(0xFF8BC98B),
        ),

        body: isLoading

            ? const Center(
          child: CircularProgressIndicator(),
        )

            : SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(

            children: [

              const SizedBox(height: 10),

              // ======================================================
              // PROFILE IMAGE
              // ======================================================

              Stack(
                children: [

                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],

                    backgroundImage:
                    userData?["profile_image"] != null &&
                        userData!["profile_image"].toString().isNotEmpty
                        ? NetworkImage(
                      "http://192.168.1.4:8000/uploads/${userData!["profile_image"]}",
                    )
                        : null,

                    child:
                    userData?["profile_image"] == null ||
                        userData!["profile_image"].toString().isEmpty
                        ? const Icon(
                      Icons.person,
                      size: 50,
                    )
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
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ======================================================
              // USER DATA
              // ======================================================

              profileField(

                text(context, "Name", "الاسم"),

                userData?["name"] ?? "",
              ),

              profileField(

                text(context, "Username", "اسم المستخدم"),

                userData?["username"] ?? "",
              ),

              profileField(

                text(context, "Email", "البريد الإلكتروني"),

                userData?["email"] ?? "",
              ),

              profileField(

                text(context, "Age", "العمر"),

                userData?["age"].toString() ?? "",
              ),

              profileField(

                text(context, "National ID", "الرقم القومي"),

                userData?["national_id"] ?? "",
              ),

              profileField(

                text(context, "License Plate", "رقم اللوحة"),

                userData?["license_plate"] ?? "",
              ),

              const SizedBox(height: 30),

              // ======================================================
              // EDIT BUTTON
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

                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(userId: userId),
                      ),
                    );

                    if (result == true) {
                      fetchUserData(); // 🔥 reload from DB
                    }

                    if (result == true) {
                      fetchUserData(); // 🔥 refresh after edit
                    }
                  },

                  child: Text(

                    text(
                      context,
                      "Edit Personal Information",
                      "تعديل الملف الشخصي",
                    ),

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
    );
  }
}