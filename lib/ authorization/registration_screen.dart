import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'email_confirmation_screen.dart'; // Импортируйте экран с кодом подтверждения

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message, {bool isVisibleToUser = false}) {
    if (!isVisibleToUser) {
      return; // Не показывать сообщение пользователю
    }

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.black,
      duration: Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Пароли не совпадают', isVisibleToUser: true);
      return false;
    }

    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackbar('Пожалуйста, заполните все поля', isVisibleToUser: true);
      return false;
    }

    final Map<String, String> registrationData = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      print('Отправка запроса с данными: $registrationData');
      final response = await http.post(
        Uri.parse('http://109.73.196.253:8001/api/auth/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 201) {
        return true; // Успешная регистрация
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('detail') && responseData['detail'] is Map) {
          if (responseData['detail'].containsKey('username') && responseData['detail'].containsKey('email')) {
            _showErrorSnackbar('Пользователь с таким именем и почтой уже существует', isVisibleToUser: true);
          } else if (responseData['detail'].containsKey('username')) {
            _showErrorSnackbar('Пользователь с таким именем уже существует', isVisibleToUser: true);
          } else if (responseData['detail'].containsKey('email')) {
            _showErrorSnackbar('Пользователь с такой почтой уже существует', isVisibleToUser: true);
          } else {
            _showErrorSnackbar(responseData['detail'] ?? 'Произошла ошибка при регистрации', isVisibleToUser: true);
          }
        } else {
          _showErrorSnackbar('Произошла ошибка при регистрации', isVisibleToUser: true);
        }
      } else {
        _showErrorSnackbar('Произошла ошибка при регистрации', isVisibleToUser: true);
      }
      return false;
    } catch (e) {
      _showErrorSnackbar('Ошибка сети: ${e.toString()}', isVisibleToUser: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF48FB1),
      appBar: AppBar(
        title: Text('Music Trainee'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Регистрация',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Имя пользователя',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Электронная почта',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Подтверждение пароля',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    if (value != _passwordController.text) {
                      _showErrorSnackbar('Пароли не совпадают', isVisibleToUser: true);
                      return null;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      minimumSize: Size(80, 40),
                      side: BorderSide(color: Colors.white),
                    ),
                    child: Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        bool isRegistered = await _registerUser();
                        if (isRegistered) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PasswordRecoveryConfirmationCodeScreen(email: _emailController.text),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}
