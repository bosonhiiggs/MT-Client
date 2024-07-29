import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'music_courses_page.dart';
import 'my_courses_page.dart';
import 'my_creations_page.dart';
import '../user_profile/edit_user.dart';
import '../ authorization/main.dart'; // Импортируем экран входа
// import './assets/icons/test2.png';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3; // Установите начальный индекс вкладки профиля
  String _email = 'loading...';
  String _fullName = 'loading...';
  String _avatarUrl = 'http://80.90.187.60:8001/media/users/users_default_avatar.jpg'; // Установите URL по умолчанию

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');

    if (sessionId != null) {
      try {
        final response = await http.get(
          Uri.parse('http://80.90.187.60:8001/api/auth/aboutme/'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'sessionid=$sessionId',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _email = data['email'] ?? 'user@email.auth';
            _fullName = (data['first_name']?.isNotEmpty == true && data['last_name']?.isNotEmpty == true)
                ? '${data['first_name']} ${data['last_name']}'
                : 'Имя Фамилия';
            _avatarUrl = data['avatar']; // Установите URL по умолчанию, если нет аватара
            // _avatarUrl = data['avatar'] ?? 'http://example.com/default_avatar.jpg'; // Установите URL по умолчанию, если нет аватара
            // if (_avatarUrl.startsWith('http://80.90.187.60/media/')) {
            //    _avatarUrl = _avatarUrl.replaceFirst('http://80.90.187.60/media/', 'http://80.90.187.60:8001/media/');
            // }
          });
        } else {
          // Обработка ошибок
          setState(() {
            _email = 'Не удалось загрузить данные';
            _fullName = 'Не удалось загрузить данные';
          });
        }
      } catch (e) {
        setState(() {
          _email = 'Ошибка: ${e.toString()}';
          _fullName = 'Ошибка: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    if (sessionId != null && csrfToken != null) {
      try {
        final response = await http.get(
          Uri.parse('http://80.90.187.60:8001/api/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'sessionid=$sessionId; csrftoken=$csrfToken',
          },
        );

        if (response.statusCode == 200) {
          await prefs.remove('sessionid');
          await prefs.remove('csrftoken');

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при выходе из аккаунта. Попробуйте позже.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сети: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Невозможно завершить сеанс. Отсутствует информация о сессии.')),
      );
    }
  }

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
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreationsScreen()),
        );
      }
    });
  }

  void _aboutCompany() {
    // Добавьте функционал для перехода к информации о компании
  }

  void _enterModerationMode() {
    // Добавьте функционал для входа в режим модерации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Мой профиль'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage: NetworkImage(_avatarUrl), // Используем NetworkImage для загрузки из сети
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    _fullName,
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditUserPage()),
                      );
                    },
                    child: Text('Редактировать профиль'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _enterModerationMode,
                    child: Text('Вход в режим модерации'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _aboutCompany,
                    child: Text('О нашей компании'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _logout,
                    child: Text('Выйти из аккаунта'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
