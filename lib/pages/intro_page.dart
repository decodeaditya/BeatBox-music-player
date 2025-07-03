// pages/intro_page.dart
import 'package:boomplay/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:boomplay/Models/hive_manager.dart'; // Import your HiveManager

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Image Section
          Flexible(
            flex: 3, // Give more flex to the image section
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(45),
                bottomRight: Radius.circular(45),
              ),
              child: SizedBox( // Use SizedBox instead of directly setting height on Image.asset
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6, // Adjusted height to be more flexible
                child: FittedBox( // Use FittedBox to ensure the image fits within its bounds
                  fit: BoxFit.cover,
                  child: Image.asset(
                    "assets/introImg.jpg",
                  ),
                ),
              ),
            ),
          ),
          // Text and Button Section
          Expanded(
            flex: 2, // Give less flex to the text/button section
            child: Container(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.maxFinite,
                    child: Text(
                      "Music without borders with BEATBOX :)",
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 31,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.maxFinite,
                    child: Text(
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Color(0xffE5E5E5),
                          fontSize: 16,
                        ),
                      ),
                      "Listen to your Favorite Tracks without privacy tensions!",
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () async {
                      final hiveManager = Provider.of<HiveManager>(context, listen: false);
                      await hiveManager.markOnboardingComplete();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    child: Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Continue →",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 19,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }
}