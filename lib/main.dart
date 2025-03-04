import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:http/http.dart' as http;
import ' authorization/email_confirmation_screen.dart';
import ' authorization/password_recovery_screen.dart';
import ' authorization/registration_screen.dart';
import 'main_pages/music_courses_page.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  AppMetrica.activate(AppMetricaConfig("06bffc38-8f82-4cba-96e6-1c6ae56a587e"));

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Trainee',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: CustomSplashScreen(), // Запускаем загрузочную страницу
    );
  }
}

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(Duration(seconds: 3)); // Имитация загрузки
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    String url = 'http://109.73.196.253:8001/api/auth/login/';
    String username = _loginController.text.trim();
    String password = _passwordController.text.trim();

    Map<String, String> body = {
      'username': username,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(body),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final test1 = (response.headers);
        // Парсим JSON ответ
        print(test1);

        print(response.headers.containsKey("set-cookie"));

        String? sessionID;
        String? csrfToken;
        if (response.headers.containsKey('set-cookie')) {
          final cookies = response.headers['set-cookie']!;
          print(cookies);

          final csrfCookie = cookies.split(';').firstWhere(
                (cookie) => cookie.trim().startsWith('csrftoken='),
            orElse: () => '',
          );

          if (csrfCookie.isNotEmpty) {
            csrfToken = csrfCookie.split('=').last;
          }

          print(csrfToken);

          final sessionCookie = cookies.split(',').firstWhere(
                (cookie) => cookie.trim().startsWith('sessionid='),
            orElse: () => '',
          );
          if (sessionCookie.isNotEmpty) {
            sessionID = sessionCookie
                .split(';')
                .first
                .split('=')
                .last;
          }
          print(sessionID);
        }

        // Сохраняем sessionid и csrftoken в SharedPreferences
        if (sessionID != null && csrfToken != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('sessionid', sessionID);
          await prefs.setString('csrftoken', csrfToken);
          await prefs.setBool('isLoggedIn', true); // Сохраняем состояние авторизации

          // Переходим на экран с курсами музыки или другой экран
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Произошла ошибка. Не удалось извлечь sessionID или csrfToken.')),
          );
        }
      }
      else if (response.statusCode == 201) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        final email = data['email'];
        print(email);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordRecoveryConfirmationCodeScreen(email: email),
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Неверный логин или пароль')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Произошла ошибка. Пожалуйста, попробуйте позже.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: ${e.toString()}')),
      );
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
      body: Center(
        child: Padding(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: TextFormField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    hintText: 'Логин',
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
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      child: Text('Войти'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFF48FB1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: BorderSide(color: Colors.white),
                        ),
                      ),
                      onPressed: () {
                        AppMetrica.reportEvent('Авторизация');
                        if (_loginController.text.isNotEmpty &&
                            _passwordController.text.isNotEmpty) {
                          _login();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Введите логин и пароль')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    child: Text(
                      'Забыли пароль?',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      AppMetrica.reportEvent('Восстановление пароля');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PasswordRecoveryScreen()),
                      );
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Зарегистрироваться',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      AppMetrica.reportEvent('Регистрация');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationScreen()),
                      );
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
