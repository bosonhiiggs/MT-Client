import 'package:flutter/material.dart';
import 'custom_splash_screen.dart';
import 'registration_screen.dart';
import 'password_recovery_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Trainee',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: CustomSplashScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Вход',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Установить цвет фона
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Установить цвет фона
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100, // Изменить размер кнопки
                  child: ElevatedButton(
                    child: Text('Войти'),
                    onPressed: () {
                      // Обработка нажатия на кнопку Войти
                    },
                  ),
                ),
              ],
            ),
            Expanded(child: SizedBox()), // Добавить пустое пространство между кнопкой "Войти" и текстами
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  child: Text(
                    'Забыли пароль?',
                    style: TextStyle(color: Colors.black), // Изменить цвет текста
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PasswordRecoveryScreen()),
                    );
                  },
                ),
                TextButton(
                  child: Text(
                    'Зарегистрироваться',
                    style: TextStyle(color: Colors.black), // Изменить цвет текста
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegistrationScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}