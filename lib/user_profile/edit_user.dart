import 'package:client/user_profile/verify_code_page.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../main_pages/music_courses_page.dart';
import '../main_pages/my_courses_page.dart';
import '../main_pages/my_creations_page.dart';
import '../main_pages/profile_page.dart';

class EditUserPage extends StatefulWidget {
  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  bool _isLoading = true;
  int _selectedIndex = 3;
  String username = '';
  String firstName = '';
  String lastName = '';
  String email = '';
  String avatarUrl = 'http://80.90.187.60:8001/media/users/users_default_avatar.jpg';
  File? _image;

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  // TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.get(
        Uri.parse('http://80.90.187.60:8001/api/auth/aboutme/'),
        headers: {
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        print('Raw data: $rawData');
        final data = json.decode(rawData);
        print('Decoded data: $data');

        setState(() {
          avatarUrl = data['avatar'];
          username = data['username'];
          firstName = data['first_name'];
          lastName = data['last_name'];
          email = data['email'];

          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
          _usernameController.text = username;
          // _emailController.text = email;
        });
      } else {
        print('Не удалось загрузить данные пользователя. Код статуса: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Не удалось загрузить данные пользователя');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось загрузить данные пользователя');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> compressImage(File file, {int quality = 70}) async {
    Uint8List bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      List<int> compressedBytes = img.encodeJpg(image, quality: quality);
      File compressedFile = File(file.path.replaceAll('.jpg', '_compressed.jpg'))
        ..writeAsBytesSync(compressedBytes);
      return compressedFile;
    }

    return file;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _image = await compressImage(imageFile);
      setState(() {});
    }
  }

  Future<void> _updateUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('http://80.90.187.60:8001/api/auth/update/'),
      );

      request.headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
      request.headers['X-CSRFToken'] = csrfToken;

      if (_firstNameController.text != firstName) {
        request.fields['first_name'] = _firstNameController.text;
      }
      if (_lastNameController.text != lastName) {
        request.fields['last_name'] = _lastNameController.text;
      }
      // if (_emailController.text != email) {
      //   request.fields['email'] = _emailController.text;
      // }

      if (_image != null) {
        var avatarFile = await http.MultipartFile.fromPath('avatar', _image!.path);
        request.files.add(avatarFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        setState(() {
          imageCache.clear();
          imageCache.clearLiveImages();
          avatarUrl = 'новый URL изображения' + "?${DateTime.now().millisecondsSinceEpoch}";
        });
        print('Данные пользователя успешно обновлены');
      } else {
        print('Не удалось обновить данные пользователя. Код статуса: ${response.statusCode}');
        print('Тело ответа: $responseBody');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось обновить данные пользователя');
    }
  }

  Future<void> _resetPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.post(
        Uri.parse('http://80.90.187.60:8001/api/auth/reset-request/'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
        },
        body: json.encode({'email': email}),
      );

      print('Код статуса запроса на смену пароля: ${response.statusCode}');

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VerifyCodePage()),
        );
      } else {
        print('Не удалось отправить запрос на смену пароля. Код статуса: ${response.statusCode}');
      }
    } catch (e) {
      print('Произошла ошибка при отправке запроса на смену пароля: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('Редактировать профиль'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _image == null
                        ? NetworkImage(avatarUrl)
                        : FileImage(_image!) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFF48FB1),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0,),
            Text(email, style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                  ),
            ),
            SizedBox(height: 16.0),
            buildTextField('Имя', _firstNameController, false),
            SizedBox(height: 16.0),
            buildTextField('Фамилия', _lastNameController, false),
            SizedBox(height: 16.0),
            buildTextField('Имя пользователя', _usernameController, false),
            SizedBox(height: 16.0),
            // buildTextField('e-mail', _emailController, false),
            // SizedBox(height: 16.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ButtonTheme(
                  minWidth: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _updateUserData();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: Text('Сохранить изменения'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                ButtonTheme(
                  minWidth: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _resetPassword();
                    },
                    child: Text('Сменить пароль'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
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

  Widget buildTextField(String hintText, TextEditingController controller, bool obscureText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
        obscureText: obscureText,
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}
