import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
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
              'Регистрация',
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
                  labelText: 'Имя пользователя',
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
                  labelText: 'Электронная почта',
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
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Установить цвет фона
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Подтверждение пароля',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(80, 40),
                  ),
                  child: Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    // Обработка нажатия на кнопку "Зарегистрироваться"
                  },
                ),
              ],
            ),
            Expanded(child: SizedBox()), // Добавить пустое пространство между кнопкой "Зарегистрироваться" и текстами
          ],
        ),
      ),
    );
  }
}