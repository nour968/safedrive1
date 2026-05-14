import 'package:flutter/material.dart';
import 'main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // Screen size
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [

            // Background Image
            SizedBox.expand(
              child: Image.asset(
                "assets/welcome.png",
                fit: BoxFit.cover,
              ),
            ),

            // Welcome Text
            PositionedDirectional(
              bottom: height * 0.32, // responsive
              start: width * 0.06,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? "أهلاً بك" : "WELCOME",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.08, // responsive font
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: height * 0.008),

                  Text(
                    isArabic
                        ? "لنبدأ الآن"
                        : "Let's Get Started",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width * 0.04,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Container
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * 0.30, // responsive
                width: double.infinity,
                padding: EdgeInsets.all(width * 0.06),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),

                child: Column(
                  children: [

                    Text(
                      isArabic
                          ? "اختر اللغة"
                          : "Select Language",
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: height * 0.03),

                    // English Button
                    SizedBox(
                      width: width * 0.55,
                      height: height * 0.065,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF8BC98B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),

                        onPressed: () {
                          MyApp.setLocale(
                              context,
                              const Locale('en'));

                          Navigator.pushReplacementNamed(
                              context,
                              '/signup');
                        },

                        child: Text(
                          "English",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.045,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.02),

                    // Arabic Button
                    SizedBox(
                      width: width * 0.55,
                      height: height * 0.065,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),

                        onPressed: () {
                          MyApp.setLocale(
                              context,
                              const Locale('ar'));

                          Navigator.pushReplacementNamed(
                              context,
                              '/signup');
                        },

                        child: Text(
                          "Arabic",
                          style: TextStyle(

                            fontSize: width * 0.045,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}