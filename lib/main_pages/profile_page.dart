import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../base/base_screen_state.dart';
import '../base/bottom_navigation_utils.dart';
import '../main.dart';
import '../moderation/moderation_profile_page.dart';
import '../user_profile/edit_user.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends BaseScreenState<ProfilePage> {
  bool _isLoading = true;
  int _selectedIndex = 3;
  String _email = 'loading...';
  String _fullName = 'loading...';
  String _avatarUrl = 'http://80.90.187.60:8001/media/users/users_default_avatar.jpg'; // Установите URL по умолчанию
  bool _isModerator = false;

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
            'Content-Type': 'application/json; charset=UTF-8',
            'Cookie': 'sessionid=$sessionId',
          },
        );

        if (response.statusCode == 200) {
          final rawData = utf8.decode(response.bodyBytes); // на каждую страницу
          print('Raw data: $rawData');
          final data = json.decode(rawData);
          print('Decoded data: $data');
          setState(() {
            _isModerator = data['is_moderator'] ?? false;
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
      } finally {
        setState(() {
          _isLoading = false;
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
          await prefs.setBool('isLoggedIn', false);

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

  void _aboutCompany() {
    // Добавьте функционал для перехода к информации о компании
  }

  void _enterModerationMode() {
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => ModerationProfilePage()),
    // );
    if (_isModerator) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ModerationProfilePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('У вас нет прав модератора.'))
      );
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'pyaninyury@yandex.ru',
    );
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
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
      body: _isLoading ? Center(child: CircularProgressIndicator()) : Column(
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
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: _launchEmail,
                    child: Text('Тех. поддержка'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(_selectedIndex, onItemTapped),
    );
  }
}
