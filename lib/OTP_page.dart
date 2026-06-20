import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ConfirmPassword_Screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 🔥 NOW 5 DIGITS
  final List<TextEditingController> controllers =
  List.generate(5, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(5, (_) => FocusNode());

  bool isLoading = false;

  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  bool get isOtpComplete =>
      controllers.every((c) => c.text.isNotEmpty);

  void nextField(int index, String value) {
    if (value.isNotEmpty && index < 4) {
      focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 55,
      height: 55,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onChanged: (value) => nextField(index, value),
      ),
    );
  }

  // ======================================================
  // VERIFY OTP (5 DIGITS)
  // ======================================================
  Future<void> verifyOtp() async {
    String otp = controllers.map((c) => c.text).join();

    // 🔥 NOW 5 DIGITS CHECK
    if (otp.length != 5) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.4:8000/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (data["status"] == "success") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmPasswordScreen(email: widget.email),
          ),
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

  // ======================================================
  // RESEND OTP
  // ======================================================
  Future<void> resendOtp() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.4:8000/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Text(
                text(context, "OTP Verification", "التحقق من الرمز"),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold ,color: Colors.black),
              ),

              const SizedBox(height: 15),

              Text(
                text(
                  context,
                  "Enter OTP sent to ${widget.email}",
                  "أدخل الرمز المرسل إلى ${widget.email}",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 🔥 NOW 5 BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) => otpBox(index)),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text(context, "Didn't receive OTP? ", "لم تستلم الرمز؟ ")),
                  GestureDetector(
                    onTap: resendOtp,
                    child: Text(
                      text(context, "Resend OTP", "إعادة الإرسال"),
                      style: const TextStyle(
                        color: Color(0xFF8BC98B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOtpComplete
                        ? const Color(0xFF8BC98B)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isOtpComplete ? verifyOtp : null,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    text(context,
                        "VERIFY & PROCEED",
                        "تحقق واستمر"),
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
    );
  }
}