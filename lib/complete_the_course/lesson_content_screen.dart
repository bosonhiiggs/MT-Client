import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'course_details_screen.dart';
import 'package:http/http.dart' as http;

class LessonContentScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseSlug;
  final int moduleId;
  final int lessonId;

  LessonContentScreen({required this.lesson,
    required this.courseSlug,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  _LessonContentScreenState createState() => _LessonContentScreenState();
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

class _LessonContentScreenState extends State<LessonContentScreen> {
  bool _isLoadingComment = true;

  int _currentStep = 0;
  dynamic _lessonData;
  String? _theoryContent;
  String? _fileContent;
  String? _questionText;
  String? _taskContent;
  String? _selectedFilePath;
  String? _submissionMessage;
  bool? _ratingMessage;
  List<dynamic> _testAnswers = [];
  VideoPlayerController? _controller;
  int? _selectedAnswerIndex;

  String? _commentText;
  List<Comment> _commentsVideo = [];
  List<Comment> _commentsTheory = [];
  List<Comment> _commentsTest = [];
  List<Comment> _commentsTask = [];

  List<Map<String, dynamic>> _steps = [];

  TextEditingController _commentController = TextEditingController();


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
      if (content.containsKey('task_content')) {
        _steps.add({
          'type': 'task',
          'id': content['id'],
        });
      }
    }

    _steps.sort((a, b) {
      if (a['type'] == 'file' && b['type'] != 'file') return -1; // Файл вперед
      if (a['type'] != 'file' && b['type'] == 'file') return 1;  // Если b - файл, он впереди

      if (a['type'] == 'text' && b['type'] != 'text') return -1; // Текст после файла
      if (a['type'] != 'text' && b['type'] == 'text') return 1;  // Если b - текст, он впереди

      if (a['type'] == 'question' && b['type'] != 'question') return -1; // Вопрос после текста
      if (a['type'] != 'question' && b['type'] == 'question') return 1;  // Если b - вопрос, он впереди

      if (a['type'] == 'task' && b['type'] != 'task') return -1; // Задание после вопроса
      if (a['type'] != 'task' && b['type'] == 'task') return 1;  // Если b - задание, оно впереди

      return 0; // Для всех остальных типов - оставляем порядок без изменений
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

      } else if (step['type'] == 'task') {
        print('type: ${step['type']}; id: ${step['id']}');
        await _loadTaskContent(step['id']);

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

        final commentsData = data['comments'];
        print("Comments Data: $commentsData");

        List<Comment> comments = [];
        for (var json in commentsData) {
          final comment = Comment.fromJson(json);
          final userInfo = await _fetchUserInfo(comment.user);
          final firstName = userInfo.firstname.isNotEmpty ? userInfo.firstname : userInfo.username;
          final lastName = userInfo.lastname.isNotEmpty ? userInfo.lastname : '';

          comments.add(comment.copyWith(
            firstName: firstName,
            lastName: lastName,
            avatar: userInfo.avatar,
          ));
        }

        setState(() {
          _commentsVideo = comments;
          _isLoadingComment = false;
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

        final commentsData = data['comments'];
        print("Comments Data: $commentsData");

        List<Comment> comments = [];
        for (var json in commentsData) {
          final comment = Comment.fromJson(json);
          final userInfo = await _fetchUserInfo(comment.user);
          final firstName = userInfo.firstname.isNotEmpty ? userInfo.firstname : userInfo.username;
          final lastName = userInfo.lastname.isNotEmpty ? userInfo.lastname : '';

          comments.add(comment.copyWith(
            firstName: firstName,
            lastName: lastName,
            avatar: userInfo.avatar,
          ));
        }

        setState(() {
          _commentsTheory = comments;
          _theoryContent = data['item']['content'];
          _isLoadingComment = false;
        });
        // print(_theoryContent);
        // print("1234: $_comments");
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
        final commentsData = data['comments'];
        print("Comments Data: $commentsData");

        List<Comment> comments = [];
        for (var json in commentsData) {
          final comment = Comment.fromJson(json);
          final userInfo = await _fetchUserInfo(comment.user);
          final firstName = userInfo.firstname.isNotEmpty ? userInfo.firstname : userInfo.username;
          final lastName = userInfo.lastname.isNotEmpty ? userInfo.lastname : '';

          comments.add(comment.copyWith(
            firstName: firstName,
            lastName: lastName,
            avatar: userInfo.avatar,
          ));
        }

        setState(() {
          _commentsTest = comments;
          _isLoadingComment = false;
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

  Future<void> _loadTaskContent(int contentId) async {
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

        final commentsData = data['comments'];
        print("Comments Data: $commentsData");

        List<Comment> comments = [];
        for (var json in commentsData) {
          final comment = Comment.fromJson(json);
          final userInfo = await _fetchUserInfo(comment.user);
          final firstName = userInfo.firstname.isNotEmpty ? userInfo.firstname : userInfo.username;
          final lastName = userInfo.lastname.isNotEmpty ? userInfo.lastname : '';

          comments.add(comment.copyWith(
            firstName: firstName,
            lastName: lastName,
            avatar: userInfo.avatar,
          ));
        }

        setState(() {
          _commentsTask = comments;
          _isLoadingComment = false;
          // _questionText = data['item']['text'];
          _taskContent = data['item']['description'];
        });
        await _checkFileExistence(contentId);
      } else {
        print('Failed to load Task Text');
        print('Response code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error to load task: $e');
    }
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(controller: _controller!),
      ));
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path; // Сохраняем путь к файлу
      });
    } else {
      print('No file selected');
    }
  }


  Future<void> _submitHomework(int contentId, String filePath) async {
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

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();

      if (response.statusCode == 200) {
        // Уведомляем пользователя об успешной отправке
        print('File submit successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл успешно отправлен!')),
        );
      } else {
        print('Ошибка отправки файла: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки файла. Попробуйте еще раз.')),
        );
      }
    } catch (e) {
      print('Ошибка отправки файла: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка. Попробуйте еще раз.')),
      );
    }
  }


  Future<void> _checkFileExistence(int currentContentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      final Map<String, String> headers = {};
      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final response = await http.get(
          Uri.parse('http://80.90.187.60:8001/api/mycourses/${widget
              .courseSlug}/modules/${widget.moduleId}/${widget
              .lessonId}/$currentContentId/submission'),
          headers: headers
      );
      print("Status check HW: ${response.statusCode}");

      if (response.statusCode == 200) {
        // print(228);
        final data = jsonDecode(response.body);
        if (data['file'] != null) {
          if (mounted) {
            setState(() {
              _selectedFilePath = data['file'];
              _submissionMessage =
              "Файл на сервере: ${_selectedFilePath!.split('/').last}";
            });
            // print("Путь до ДЗ$_selectedFilePath");
          }
          await _checkReview(currentContentId, headers);
        } else {
          if (mounted) {
            setState(() {
              _submissionMessage = "Файл не найден на сервере.";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _submissionMessage = "Ошибка при проверке файла.";
          });
        }
      }
    } catch (e) {
      print("Error check file: $e");
    }
  }

  Future<void> _checkReview(int currentContentId, Map<String, String> headers) async {
    try {
      final reviewResponse = await http.get(
        Uri.parse('http://80.90.187.60:8001/api/mycourses/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$currentContentId/submission/review'),
        headers: headers,
      );

      if (reviewResponse.statusCode == 200) {
        final reviewData = jsonDecode(reviewResponse.body);
        if (reviewData['is_correct'] != null) {
          final rating = reviewData['is_correct'];
          if (rating) {
            setState(() {
              _ratingMessage = true;
            });
          } else if (rating) {
            setState(() {
              _ratingMessage = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error check review: $e");
    }
  }

  Future<void> _submitComment(int contentId, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionid = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');
    print("Push button for comments");
    if (sessionid == null || csrfToken == null) return;

    // Construct the URL
    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/comments/';
    print(url);

    // Construct the request body
    final requestBody = json.encode({
      'text': _commentText
    });
    print('Request body: $requestBody'); // Debugging information

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken!,
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}'); // Debugging information
      print('Response body: ${response.body}'); // Debugging information

      if (response.statusCode == 201) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);
        print('Decoded data: $data'); // Debugging information

        final userId = data['author'];
        final userInfo = await _fetchUserInfo(userId);

        Comment newComment = Comment.fromJson(data).copyWith(
          firstName: userInfo.firstname.isNotEmpty
              ? userInfo.firstname
              : userInfo.username,
          lastName: userInfo.lastname,
          avatar: userInfo.avatar,
        );

        if (type == 'Video') {
          setState(() {
            _commentsVideo.add(newComment);
            _commentText = '';
          });
        } else if (type == 'Theory') {
          setState(() {
            _commentsTheory.add(newComment);
            _commentText = '';
          });
        } else if (type == 'Test') {
          setState(() {
            _commentsTest.add(newComment);
            _commentText = '';
          });
        }  else if (type == 'Task') {
          setState(() {
            _commentsTask.add(newComment);
            _commentText = '';
          });
        }
        _commentController.clear();
        print(
            'Comment submitted successfully: $newComment'); // Debugging information
      } else {
        print('Failed to submit comment: ${response.statusCode}'); // Debugging information
        print('Response body: ${response.body}'); // Debugging information
      }
    } catch (e) {
      print('Error submitting comment: $e'); // Debugging information
    }
  }

  Future<UserInfo> _fetchUserInfo(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionid = prefs.getString('sessionid');
    final url = 'http://80.90.187.60:8001/api/user/$userId/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'sessionid=$sessionid',
      },
    );

    if (response.statusCode == 200) {
      final rawData = utf8.decode(response.bodyBytes);
      final data = json.decode(rawData);
      return UserInfo.fromJson(data);
    } else {
      throw Exception('Failed to load user info');
    }
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

      body: SingleChildScrollView(
        child: Column(
        children: [
          _buildStepContent(),
          // Spacer(), // Добавляем Spacer для перемещения кнопок вниз

        ],
      ),
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
    // print(currentStepData);

    switch (currentStepData['type']) {
      case 'file':
        return _buildVideoStep();
      case 'text':
        return _buildTheoryStep();
      case 'question':
        return _buildTestStep();
      case 'task':
        return _buildHomeworkStep();
      default:
        return Container();
    }
  }

  Widget _buildVideoStep() {
    final currentContentId = _steps[_currentStep]['id'];
    return Column(
      children: [
        AppBar(
          title: Text('Видео'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),

        if (_controller != null && _controller!.value.isInitialized)
          Padding(
            padding: const EdgeInsets.all(16.0),
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

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 15),
              _buildNavigationButtons(),
              _buildCommentSection(currentContentId, _commentsVideo, 'Video'),
            ],

          ),
        )
      ],
    );
  }

  Widget _buildTheoryStep() {
    final currentContentId = _steps[_currentStep]['id'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: Text('Теория'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _theoryContent != null
                  ? Text(_theoryContent!)
                  : CircularProgressIndicator(),
              SizedBox(height: 15),
              _buildNavigationButtons(),
              _buildCommentSection(currentContentId, _commentsTheory, 'Theory'),
            ],

          ),
        )
      ],
    );
  }

  Widget _buildTestStep() {
    final currentContentId = _steps[_currentStep]['id'];
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
                _questionText != null ?
                Text(
                  'Тестовый вопрос: $_questionText',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ) : Center(child: CircularProgressIndicator(),),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 15),
                _buildNavigationButtons(),
                _buildCommentSection(currentContentId, _commentsTest, 'Test'),
              ],

            ),
          )
        ],
      ),
    );
  }

  Widget _buildHomeworkStep() {
    final currentContentId = _steps[_currentStep]['id'];

    return Column(
      children: [
        AppBar(
          title: Text('Домашнее задание'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    _taskContent != null ?
                    Text(
                      'Задание: $_taskContent',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                    : Center(child: CircularProgressIndicator()),
              SizedBox(height: 20),
              if (_selectedFilePath == null)
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text('Прикрепить файл'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                  ),
                ),
              SizedBox(height: 20),
              if (_selectedFilePath != null)
                Text('Выбранный файл: ${_selectedFilePath!.split('/').last}'),
              ElevatedButton(
                onPressed: () {
                  if (_selectedFilePath != null) {
                    _submitHomework(currentContentId, _selectedFilePath!);
                  } else {
                    print('Пожалуйста, прикрепите файл перед отправкой.');
                  }
                },
                child: Text('Отправить'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFF48FB1),
                ),
              ),
              SizedBox(height: 30,),
              if (_ratingMessage != null)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ratingMessage == true
                        ? Colors.green[200] // Цвет для "зачтено"
                        : Colors.red[200],  // Цвет для "не принято"
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _ratingMessage == true ? 'Зачтено' : 'Не принято',
                    style: TextStyle(
                      fontSize: 16,
                      color: _ratingMessage == true ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 15),
              _buildNavigationButtons(),
              _buildCommentSection(currentContentId, _commentsTask, 'Task'),
            ],

          ),
        )
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

  Widget _buildCommentSection(int contentId, List<dynamic> comments, String type) {
    print("_isLoadingComment: ${_isLoadingComment}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Комментарии',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
        SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Оставьте комментарий...',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF48FB1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF48FB1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF48FB1)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    color: Color(0xFFF48FB1),
                    onPressed: () => _submitComment(contentId, type),
                    // onPressed: null,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _commentText = value;
                  });
                },
                // controller: TextEditingController(text: _commentText),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.0),

        if (_isLoadingComment)
          Center(child: CircularProgressIndicator())
        else if (comments.isEmpty)
          Center(
            child: Text(
              'Комментарии отсутствуют',
              style: TextStyle(fontSize: 18),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              // final comment = _comments[index];
              final comment = comments.reversed.toList()[index];
              return CommentTile(comment: comment);
            },
          ),

      ],
    );
  }
}

class Comment {
  final int id;
  final int user;
  final String firstName;
  final String lastName;
  final String avatar;
  final String text;

  Comment({
    required this.id,
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.text,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      user: json['author'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Comment copyWith({
    int? id,
    int? user,
    String? firstName,
    String? lastName,
    String? avatar,
    String? text,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      text: text ?? this.text,
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;

  CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.avatar),
            radius: 24,
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.firstName} ${comment.lastName}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  comment.text,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}