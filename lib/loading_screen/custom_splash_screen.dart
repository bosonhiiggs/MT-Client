import 'package:flutter/material.dart';
import '../ authorization/main.dart';

class CustomSplashScreen extends StatefulWidget {
  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLoginScreen();
  }

  Future<void> _navigateToLoginScreen() async {
    await Future.delayed(Duration(seconds: 3)); // Имитация загрузки
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF48FB1), // Установить цвет фона
      child: Center(
        child: Image.asset("assets/icons/ic2.png"), // Добавить изображение
      ),
    );
  }
}