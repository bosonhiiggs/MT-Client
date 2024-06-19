import 'package:flutter/material.dart';
import 'dart:math';
import 'password_reset_screen.dart';

class PasswordRecoveryConfirmationCodeScreen extends StatefulWidget {
  final String email;

  PasswordRecoveryConfirmationCodeScreen({required this.email});

  @override
  _PasswordRecoveryConfirmationCodeScreenState createState() =>
      _PasswordRecoveryConfirmationCodeScreenState();
}

class _PasswordRecoveryConfirmationCodeScreenState
    extends State<PasswordRecoveryConfirmationCodeScreen> {
  String _confirmationCode = '';
  final _confirmationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateConfirmationCode();
  }

  void _generateConfirmationCode() {
    var random = Random();
    _confirmationCode = (random.nextInt(900000) + 100000).toString();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Введите код подтверждения',
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
                controller: _confirmationCodeController,
                decoration: InputDecoration(
                  hintText: 'Код подтверждения',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 150, // Изменить размер кнопки
                  child: ElevatedButton(
                    child: Text('Подтвердить'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                    onPressed: () {
                      if (_confirmationCodeController.text == _confirmationCode) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PasswordResetScreen()),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Ошибка'),
                              content: Text('Неправильный код подтверждения'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            Expanded(child: SizedBox()), // Добавить пустое пространство между кнопкой "Подтвердить" и текстами
            Text(
              'Код подтверждения: $_confirmationCode',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}