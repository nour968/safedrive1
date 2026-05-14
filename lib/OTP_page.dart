import 'package:flutter/material.dart';
import 'ConfirmPassword_Screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> controllers =
  List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes =
  List.generate(4, (_) => FocusNode());

  /// 🌍 Localization helper
  String text(BuildContext context, String en, String ar) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  bool get isOtpComplete => controllers.every((c) => c.text.isNotEmpty);

  void nextField(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Widget otpBox(int index) {
    return SizedBox(
      width: 60,
      height: 60,
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

  void verifyOtp() {
    String otp = controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConfirmPasswordScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text(context, "Enter valid OTP", "أدخل رمز تحقق صحيح")),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
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
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                text(context,
                    "Enter the OTP sent to your phone",
                    "أدخل رمز التحقق المرسل إلى هاتفك"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => otpBox(index)),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text(context, "Didn't receive OTP? ", "لم تستلم الرمز؟ ")),
                  GestureDetector(
                    onTap: () {}, // TODO: Implement resend OTP
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
                        : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isOtpComplete ? verifyOtp : null,
                  child: Text(
                    text(context, "VERIFY & PROCEED", "تحقق واستمر"),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1,color: Colors.white),
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