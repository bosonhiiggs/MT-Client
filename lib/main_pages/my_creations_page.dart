import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'music_courses_page.dart';
import 'my_courses_page.dart';
import '../Create_courses/create_course.dart';

class MyCreationsScreen extends StatefulWidget {
  @override
  _MyCreationsScreenState createState() => _MyCreationsScreenState();
}

class _MyCreationsScreenState extends State<MyCreationsScreen> {
  int _selectedIndex = 2; // установите начальный индекс вкладки "Преподавание"

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCoursesScreen()),
        );
      }else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Мои творения'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.0),
            Text(
              'Здесь будут храниться созданные вами курсы',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Spacer(),
                ElevatedButton(
                  child: Text('Создать курс'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateCoursePage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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