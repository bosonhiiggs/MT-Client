import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Импортируйте пакет http
import 'dart:convert'; // Для кодировки JSON
import 'password_reset_screen.dart';
import 'music_courses_screen.dart'; // Импортируйте экран курсов

class PasswordRecoveryConfirmationCodeScreen extends StatefulWidget {
  final String email;

  PasswordRecoveryConfirmationCodeScreen({required this.email});

  @override
  _PasswordRecoveryConfirmationCodeScreenState createState() => _PasswordRecoveryConfirmationCodeScreenState();
}

class _PasswordRecoveryConfirmationCodeScreenState extends State<PasswordRecoveryConfirmationCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _confirmationCodeController = TextEditingController();

  @override
  void dispose() {
    _confirmationCodeController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.black,
      duration: Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _verifyCode() async {
    final String url = 'http://80.90.187.60:8001/api/auth/signup/confirm';
    final String confirmationCode = _confirmationCodeController.text;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'confirm_code': confirmationCode}),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Если код верен, переходите на MusicCoursesScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
        );
      } else if (response.statusCode == 400) {
        // Если код неверен, покажите ошибку
        _showErrorSnackbar('Неправильный код подтверждения');
      } else {
        // Обработка других статусов
        _showErrorSnackbar('Произошла ошибка. Попробуйте позже.');
      }
    } catch (error) {
      // Обработка ошибок сети и других исключений
      _showErrorSnackbar('Произошла ошибка. Проверьте подключение к интернету.');
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF48FB1),
      appBar: AppBar(
        title: Text('Подтверждение кода'),
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
                'Введите код подтверждения, отправленный на ваш email',
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _confirmationCodeController,
                  decoration: InputDecoration(
                    hintText: 'Код подтверждения',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите код';
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
                    child: Text('Подтвердить', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _verifyCode();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
