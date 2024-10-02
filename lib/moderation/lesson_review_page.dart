import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'course_approval_page.dart';

class LessonReviewScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseSlug;
  final int moduleId;
  final int lessonId;

  LessonReviewScreen({required this.lesson,
    required this.courseSlug,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  _LessonReviewScreenState createState() => _LessonReviewScreenState();
}

class FullScreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  FullScreenVideoPlayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
              ),
            ),
            IconButton(
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () {
                controller.value.isPlaying ? controller.pause() : controller.play();
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonReviewScreenState extends State<LessonReviewScreen> {
  int _currentStep = 0;
  dynamic _lessonData;
  String? _theoryContent;
  String? _fileContent;
  String? _questionText;
  List<dynamic> _testAnswers = [];
  VideoPlayerController? _controller;
  int? _selectedAnswerIndex;

  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Загружаем данные при инициализации
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeVideoController(String videoUrl) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        "http://80.90.187.60:8001/${videoUrl}"
    ));
    try {
      await _controller!.initialize();
      setState(() {});
      // _controller?.play();
    } catch (e) {
      print("Error $e");
    }
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');
      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://80.90.187.60:8001/api/mycourses/${widget
          .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/';
      final response = await http.get(
          Uri.parse(url),
          headers: headers
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        // print('Decoded data: $data');
        setState(() {
          _lessonData = data;
        });
        print("Initial $_lessonData");
        // _findTextContent();
        _generateSteps();

      } else {
        print('Cant load to lesson data. Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('Error to process load lesson data: $e');
    }

  }

  Future<void> _generateSteps() async {
    if (_lessonData == null) return;

    final contents = _lessonData['contents'];

    for (var content in contents) {
      if (content.containsKey('file_content')) {
        _steps.add({
          'type': 'file',
          'id': content['id'],
        });
      }
      if (content.containsKey('text_content')) {
        _steps.add({
          'type': 'text',
          'id': content['id'],
        });
      }
      if (content.containsKey('question_content')) {
        _steps.add({
          'type': 'question',
          'id': content['id'],
        });
      }
    }

    _steps.sort((a, b) {
      if (a['type'] == 'file' && b['type'] != 'file') return -1; // Видео вперед
      if (a['type'] != 'file' && b['type'] == 'file') return 1;  // Если b - видео, оно впереди

      if (a['type'] == 'text' && b['type'] != 'text') return -1; // Теория после видео
      if (a['type'] != 'text' && b['type'] == 'text') return 1;  // Если b - теория, оно впереди

      if (a['type'] == 'question') return 1;  // Тесты всегда последние
      if (b['type'] == 'question') return -1; // Если b - тест, оно позади

      return 0;
    });

    for (var step in _steps) {
      if (step['type'] == 'file') {
        print('type: ${step['type']}; id: ${step['id']}');
        await _loadFileContent(step['id']);

      } else if (step['type'] == 'text') {
        print('type: ${step['type']}; id: ${step['id']}');
        await _loadTheoryContent(step['id']);

      } else if (step['type'] == 'question') {
        print('type: ${step['type']}; id: ${step['id']}');
        await _loadTestContent(step['id']);

      }
    }

    setState(() {});

  }

  Future<void> _loadFileContent(int contentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://80.90.187.60:8001/api/mycourses/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        setState(() {
          _fileContent = data['item']['file'];
        });
        print("FIleCOntent: ${_fileContent}");
        if (_fileContent != null) {
          await _initializeVideoController(_fileContent!);
        } else {
          print('File content is null');
        }
      } else {
        print('Failed to load file content');
        print('Response code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error to load file: $e');
    }
  }

  Future<void> _loadTheoryContent(int contentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://80.90.187.60:8001/api/mycourses/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        setState(() {
          _theoryContent = data['item']['content'];
        });
        // print(_theoryContent);
      } else {
        print('Failed to load Theory Text');
        print('Response code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error to load theory: $e');
    }
  }

  Future<void> _loadTestContent(int contentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://80.90.187.60:8001/api/mycourses/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        setState(() {
          _questionText = data['item']['text'];
          _testAnswers = data['item']['answers'];
        });
      } else {
        print('Failed to load Theory Text');
        print('Response code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error to load theory: $e');
    }
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPlayer(controller: _controller!),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
        actions: [
          Row(
            children: List.generate(_steps.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentStep == index ? Color(0xFFF48FB1) : Colors.grey,
                  border: Border.all(
                    color: Colors.black,
                    width: 2.0,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepContent(),
          Spacer(), // Добавляем Spacer для перемещения кнопок вниз
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_lessonData == null) {
      return Center(child: CircularProgressIndicator()); // Индикатор загрузки
    }

    if (_steps.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    final currentStepData = _steps[_currentStep];

    switch (currentStepData['type']) {
      case 'file':
        return _buildVideoStep();
      case 'text':
        print('Step text: ${currentStepData['data']}');
        return _buildTheoryStep();
      case 'question':
        print('Step question: ${currentStepData['data']}');
        print(_questionText);
        print(_testAnswers);
        return _buildTestStep();
      default:
        return Container();
    }
  }

  Widget _buildVideoStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Видео'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),

        if (_controller != null && _controller!.value.isInitialized)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              height: 300,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VideoProgressIndicator(
                      _controller!, allowScrubbing: true,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        _enterFullScreen();
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildTheoryStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Теория'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения теории
        // Text('Теоретический контент'),
        _theoryContent != null
            ? Text(_theoryContent!)
            : CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildTestStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text('Тест'),
            automaticallyImplyLeading: false,
            centerTitle: true,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тестовый вопрос: $_questionText',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _testAnswers.length,
                  itemBuilder: (context, index) {
                    final answer = _testAnswers[index];
                    bool isCorrect = answer['is_true']; // Предположим, у вас есть эта информация
                    bool isSelected = _selectedAnswerIndex == index;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAnswerIndex = index;
                          });
                        },
                        splashColor: Colors.transparent, // Убираем цвет всплеска
                        highlightColor: Colors.transparent,
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.white, // Цвет по умолчанию
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(answer['text']),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Домашнее задание'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения домашнего задания
        Text('Домашнее задание'),
        ElevatedButton(
          onPressed: () {
            // Логика для отправки домашнего задания
          },
          child: Text('Отправить домашнее задание'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFFF48FB1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, left: 10, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton(
              onPressed: () {
                _controller?.pause(); // Остановить видео при переходе
                setState(() {
                  _currentStep--;
                });
              },
              child: Text('Предыдущий этап'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: Size(150, 50),
              ),
            ),
          Spacer(),
          if (_currentStep < _steps.length - 1)
            ElevatedButton(
              onPressed: () {
                _controller?.pause(); // Остановить видео при переходе
                setState(() {
                  _currentStep++;
                });
              },
              child: Text('Следующий этап'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: Size(150, 50),
              ),
            ),
          if (_currentStep == _steps.length - 1)
            ElevatedButton(
              onPressed: () {
                _controller?.pause(); // Остановить видео при завершении
                Navigator.pop(context);
              },
              child: Text('Закончить урок'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                minimumSize: Size(150, 50),
              ),
            ),
        ],
      ),
    );
  }
}
