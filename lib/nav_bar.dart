import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {

  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void onItemTapped(BuildContext context, int index) {

    // prevent reopening same screen
    if (index == currentIndex) return;

    if (index == 0) {

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );

    } else if (index == 1) {

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/history',
            (route) => false,
      );

    } else if (index == 2) {

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/profile',
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green,

      onTap: (index) =>
          onItemTapped(context, index),

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: "",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "",
        ),
      ],
    );
  }
}