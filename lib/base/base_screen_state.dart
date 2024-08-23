import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main_pages/music_courses_page.dart';
import '../main_pages/my_courses_page.dart';
import '../main_pages/my_creations_page.dart';
import '../main_pages/profile_page.dart';

abstract class BaseScreenState<T extends StatefulWidget> extends State<T> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = getInitialIndex();
  }

  int getInitialIndex() => 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {

        Navigator.pushReplacement(
          context,
          // MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MusicCoursesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;  // Возвращаем виджет без анимации
            },
          ),
        );

      } else if (index == 1) {

        Navigator.pushReplacement(
          context,
          // MaterialPageRoute(builder: (context) => MyCoursesScreen()),
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MyCoursesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;  // Возвращаем виджет без анимации
            },
          ),
        );

      } else if (index == 3) {

        Navigator.pushReplacement(
          context,
          // MaterialPageRoute(builder: (context) => ProfilePage()),
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;  // Возвращаем виджет без анимации
            },
          ),
        );

      } else if (index == 2) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => MyCreationsScreen()),
        // );

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MyCreationsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;  // Возвращаем виджет без анимации
            },
          ),
        );

      }
    });
  }

}













