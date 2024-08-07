import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'my_courses_page.dart';
import 'my_creations_page.dart';

class MusicCoursesScreen extends StatefulWidget {
  @override
  _MusicCoursesScreenState createState() => _MusicCoursesScreenState();
}

class _MusicCoursesScreenState extends State<MusicCoursesScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCoursesScreen()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreationsScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Музыкальные курсы'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Center(
        child: Text('Страница музыкальных курсов'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, color: Colors.white),
            label: 'Каталог',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.menu, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            label: 'Мои курсы',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.favorite_border, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined, color: Colors.white),
            label: 'Преподавание',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.storage_outlined, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Мой профиль',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.person, color: Colors.black),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        backgroundColor: Color(0xFFF48FB1),
        onTap: _onItemTapped,
      ),
    );
  }
}