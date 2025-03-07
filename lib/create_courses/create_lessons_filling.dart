import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Card;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController, VideoPlayer, VideoProgressIndicator;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // для определения типа контента
import 'package:mime/mime.dart';

import 'create_lessons.dart'; // для определения MIME типа файла

class LessonData {
  final String lessonName;
  final String videoPath;
  final String theoryText;
  final String testQuestion;
  final String correctAnswer;
  final List<String> wrongAnswers;

  LessonData({
    required this.lessonName,
    required this.videoPath,
    required this.theoryText,
    required this.testQuestion,
    required this.correctAnswer,
    required this.wrongAnswers,
  });
}

class Answer {
  final int id;
  final String text;
  final bool isTrue;

  Answer({required this.id, required this.text, required this.isTrue});
}

class CreateLessonPage2 extends StatefulWidget {
  final String courseSlug;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;
  final int lessonIndex;
  final String moduleId;
  final String lessonName;
  final String lessonId;

  CreateLessonPage2({
    required this.courseSlug,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
    required this.lessonIndex,
    required this.lessonName,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  _CreateLessonPage2State createState() => _CreateLessonPage2State();
}

class _CreateLessonPage2State extends State<CreateLessonPage2> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoading = true;

  String _lessonName = '';
  String _videoPath = '';
  String _taskText = '';
  String _testQuestion = '';
  String _correctAnswer = '';
  String _homeworkText = '';
  int _correctAnswerId = 0;
  String _initialTaskText = '';
  String _initialQuestionText = '';
  String _initialCorrectAnswer = '';
  String _initialHomeworkText = '';
  List<String> _wrongAnswers = [];
  List<dynamic> _answerListObjects = [];
  PlatformFile? videoFile;
  VideoPlayerController? _controller;

  TextEditingController _taskTextController = TextEditingController();
  TextEditingController _testQuestionController = TextEditingController();
  TextEditingController _correctAnswerController = TextEditingController();
  TextEditingController _homeworkController = TextEditingController(); // Добавлен контроллер для домашнего задания
  List<TextEditingController> _controllers = [];

  int? _contentId;
  int? _questionId;

  @override
  void initState() {
    super.initState();
    _lessonName = widget.lessonName;
    _taskTextController.text = _taskText;
    _fetchLessonData();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoController(String videoUrl) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller!.initialize();
      setState(() {});
      _controller?.play();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _fetchLessonData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');
      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
          .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/';
      final response = await http.get(
          Uri.parse(url),
          headers: headers
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        print(data);

        List<dynamic> contents = data['contents'];
        for (var content in contents) {
          if (content.containsKey('text_content')) {
            await _fetchContentData(content['id'], 'text');
          } else if (content.containsKey('file_content')) {
            await _fetchContentData(content['id'], 'file');
          } else if (content.containsKey('question_content')) {
            await _fetchContentData(content['id'], 'question');
          } else if (content.containsKey('task_content')) {
            await _fetchContentData(content['id'], 'task');
          }

        }

        setState(() {
          _isLoading = false;
        });

      } else {
        print('Cant load to lesson data. Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

    } catch (e) {
      print('Error to process load lesson data: $e');
    }
  }

  Future<void> _fetchContentData(int contentId, String typeObject) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');
      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final contentData = jsonDecode(rawData);
        print(contentData);
        //
        if (typeObject == 'text') {
          setState(() {
            _taskText = contentData['content'];
            _taskTextController.text = _taskText;
            _initialTaskText = _taskText;
            _contentId = contentId;
          });
        }

        if (typeObject == 'file') {
          setState(() {
            String videoUrl = "http://109.73.196.253:8001${contentData['file']}";
            _videoPath = videoUrl;
            _contentId = contentId;
          });
          await _initializeVideoController(_videoPath);
        }

        if (typeObject == 'question') {
          await _parseAnswers(contentId, contentData['answers']);
          setState(() {
            _testQuestion = contentData['text'];
            _testQuestionController.text = _testQuestion;
            _initialQuestionText = _testQuestion;
            _contentId = contentId;
            _questionId = contentData['id'];
          });
          _controllers = List.generate(_wrongAnswers.length, (index) => TextEditingController(text: _wrongAnswers[index]));
        }

        if (typeObject == 'task') {
          print("Домашка");
          setState(() {
            _homeworkText = contentData['description'];
            _homeworkController.text = _homeworkText;
            _initialHomeworkText = _homeworkText;
            _contentId = contentId;
          });
        }

      } else {
        print('Failed to load content data. Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching content data: $e');
    }
  }

  Future<void> _parseAnswers (int questionId, List<dynamic> answers) async {
    List<String> wrongAnswers = [];
    List<dynamic> answerListObjects = [];
    for (var answer in answers) {

      if (answer['is_true'] == true) {
        setState(() {
          _correctAnswer = answer['text'];
          _correctAnswerController.text = _correctAnswer;
          _initialCorrectAnswer = _correctAnswer;
          _correctAnswerId = answer['id'];
        });
      } else if (answer['is_true'] == false) {
        wrongAnswers.add(answer['text']);
        answerListObjects.add(answer);
      }
    }

    setState(() {
      _wrongAnswers = wrongAnswers;
      _answerListObjects = answerListObjects;
    });

  }

  Future<void> _initializeController() async {
    if (videoFile != null) {
      _controller = VideoPlayerController.file(File(videoFile!.path!));

      try {
        await _controller!.initialize();
        setState(() {
          _controller?.play();
        });
      } catch (e) {
        print('Ошибка инициализации видео: $e');
      }
    }
  }

  Future<void> _updateLessonName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/';

    final requestBody = {
      'title': _lessonName,
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Lesson name update successfully!');
      } else {
        print('Failed to update lesson name: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error updating lesson name: $e');
    }
  }

  Future<void> _sendHomeworkToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/task/';

    final requestBody = {
      "title": "Домашнее задание - ${widget.lessonName}",
      "description": _homeworkText
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('Task data sent successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to send task data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending task data: $e');
    }
  }

  Future<void> _sendTextToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/text/';

    final requestBody = {
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}text",
      "content": _taskText
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('Text data sent successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to send text data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending text data: $e');
    }
  }

  Future<void> _deleteTextData(int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';

    try {
      final response = await http.delete(
          Uri.parse(url),
          headers: headers
      );

      if (response.statusCode == 204) {
        print('Text data was successfully deleted');
        _fetchLessonData();
      } else {
        print('Failed to delete text data: ${response.statusCode}');
      }

    } catch (e) {
      print("Error deleting text data: $e");
    }
  }

  Future<void> _updateHomeworkData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/task/';

    final requestBody = {
      "title": "Домашнее задание - ${widget.lessonName}",
      "description": _homeworkText
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Task update successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to update task data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error update task data: $e');
    }
  }

  Future<void> _updateTextData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/text/';

    final requestBody = {
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}text",
      "content": _taskText
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Text data update successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to update text data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error update text data: $e');
    }
  }

  Future<void> _sendVideoToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/file/';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll(headers);

    if (videoFile != null) {
      final mimeType = lookupMimeType(videoFile!.path!);
      final video = await http.MultipartFile.fromPath(
        'file',
        videoFile!.path!,
        contentType: MediaType.parse(mimeType ?? 'video/mp4'),
      );
      request.fields['title'] =
      '${widget.courseSlug}lesson${widget.lessonId}video';
      request.files.add(video);
      print(request);

      print('Отправляемое видео: ${videoFile!.name}, MIME: $mimeType');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("Send video status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        print('Video sent successfully');
      } else {
        print('Failed to send video: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending video: $e');
    }
  }

  Future<void> _deleteVideoFromServer (int contentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      final Map<String, String> headers = {};
      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
          .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/'; // URL для удаления видео
      final response = await http.delete(Uri.parse(url), headers: headers);
      print(url);
      if (response.statusCode == 204) {
        print('Видео успешно удалено с сервера');
      } else {
        print('Ошибка при удалении видео. Статус код: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении видео: $e');
    }
  }

  Future<void> _sendQuestionToServer () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/question/';

    final requestBody = {
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}question",
      "text": _testQuestion
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        _questionId = responseBody['id'];
        print('Question data sent successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to send Question data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error sending Question data: $e');
    }
  }

  Future<void> _deleteQuestionData (int contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/$contentId/';

    try {
      final response = await http.delete(
          Uri.parse(url),
          headers: headers
      );

      if (response.statusCode == 204) {
        print('Question data was successfully deleted');
      } else {
        print('Failed to delete question data: ${response.statusCode}');
      }

    } catch (e) {
      print("Error deleting question data: $e");
    }
  }

  Future<void> _updateQuestionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/question/';

    final requestBody = {
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}question",
      "text": _testQuestion
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Question data update successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to update Question data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error update Question data: $e');
    }
  }

  Future<void> _sendCorrectAnswerToServer(questionId) async {
    print("send correct answer");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/answer/';

    final requestBody = {
      "question": questionId,
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}answer",
      "text": _correctAnswer,
      "is_true": true
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('Answer data sent successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to send asnwer data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error sending answer data: $e');
    }

  }

  Future<void> _sendUnCorrectAnswerToServer(String answer, int questionId) async {
    print("send uncorrect answer");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/answer/';

    final requestBody = {
      "question": questionId,
      "title": "${widget.courseSlug}${widget.moduleId}-${widget.lessonId}answer",
      "text": answer,
      "is_true": false
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        print('Answer data sent successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to send asnwer data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error sending answer data: $e');
    }

  }

  Future<void> _updateCorrectAnswer() async {
    print("Update Correct");

    final correctAnswerId = _correctAnswerId;
    final correctAnswerText = _correctAnswer;
    print(correctAnswerId);
    print(correctAnswerText);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/answer/${correctAnswerId}';

    final requestBody = {
      "text": correctAnswerText
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Answer data update successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to update asnwer data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error delete answer data: $e');
    }

  }

  Future<void> _updateWrongAnswer(int index, String answerText) async {
    print("Update Wrong");

    final answerId = _answerListObjects[index]['id'];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/answer/${answerId}';

    final requestBody = {
      "text": answerText,
    };

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Answer data update successfully for ID: $answerId');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to update answer data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating answer data: $e');
    }
  }

  Future<void> updateAllWrongAnswers() async {
    for (int i = 0; i < _wrongAnswers.length; i++) {
      final answerText = _wrongAnswers[i];

      if (answerText.isEmpty) {
        continue;
      }

      if (_answerListObjects[i]['text'] != answerText) {
        await _updateWrongAnswer(i, answerText);
      }
    }

    for (String answerText in _wrongAnswers) {
      if (!_answerListObjects.any((answer) => answer['text'] == answerText)) {
        await _sendUnCorrectAnswerToServer(answerText, _questionId!);
      }
    }
  }

  Future<void> _deleteAnswer(answerIndex) async {
    print("ID for delete: ${answerIndex}");
    final answerForDeleteId = answerIndex;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://109.73.196.253:8001/api/mycreations/create/${widget
        .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/answer/${answerForDeleteId}';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 204) {
        print('Answer data delete successfully');
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Failed to delete asnwer data: ${response.statusCode}');
        print('Response body: ${responseBody}');
      }
    } catch (e) {
      print('Error delete answer data: $e');
    }

  }

  void _addWrongAnswer() {
    if (_wrongAnswers.length >= 3) {
      _showLimitREachedDialog();
    } else {
      setState(() {
        _wrongAnswers.add('');
        _answerListObjects.add({});
        _controllers.add(TextEditingController());
      });
    }
  }

  void _showLimitREachedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Лимит достигнут'),
          content: Text('Вы не можете добавить больше 3 неправильных ответов.'),
          actions: [
            TextButton(onPressed: () {Navigator.of(context).pop();}, child: Text('OK'))
          ],
        );
      },
    );
  }

  bool _isVideoDeleted = false;
  bool _isNewVideoAdded = false;

  @override
  Widget build(BuildContext context) {
    print('Video file path: ${videoFile?.path}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание урока'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поле для названия урока
              _buildLessonNameField(),
              SizedBox(height: 16),
              // Блок для прикрепления видео
              _buildVideoAttachmentSection(),
              if (!_isVideoDeleted && _controller != null && _controller!.value.isInitialized)
                GestureDetector(
                  onLongPress: () {
                    _showVideoDeleteBottomSheet(context);
                  },
                  child: Padding(
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
                                _controller!, allowScrubbing: true),
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
                        ],
                      ),
                    ),
                  ),
                ),
              if (videoFile != null && !_isVideoDeleted &&
                  (_controller == null || !_controller!.value.isInitialized))
                Text(
                  'Выбранное видео: ${videoFile!.name}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (_isVideoDeleted)
                Text(
                  'Видео удалено',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),

              // Поле для текста задания
              _buildTaskTextField(),
              // Поле для вопроса теста
              _buildTestQuestionField(),
              // Поле для правильного ответа
              _buildCorrectAnswerField(),
              // Список неправильных ответов
              _buildWrongAnswersList(),
              // Кнопка для добавления неправильного ответа
              _buildAddWrongAnswerButton(),
              // Поле для домашнего задания
              _buildHomeworkTextField(),
              // Кнопка "Сохранить"
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

// Метод для создания поля названия урока
  Widget _buildLessonNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFF48FB1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          initialValue: _lessonName,
          onChanged: (value) {
            setState(() {
              _lessonName = value;
            });
          },
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Название урока',
            labelStyle: TextStyle(color: Colors.white),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }

// Метод для создания секции прикрепления видео
  Widget _buildVideoAttachmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('Прикрепите видео к уроку: '),
          Spacer(),
          IconButton(
            icon: Icon(Icons.file_download),
            color: Color(0xFFF48FB1),
            onPressed: () async {
              final file = await FilePicker.platform.pickFiles(
                type: FileType.video,
              );

              if (file != null) {
                final maxSize = 500 * 1024 * 1024;
                final pickedFile = file.files.first;
                final fileSize = pickedFile.size;

                if (fileSize > maxSize) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Упс... Максимальный размер файла 500Мб.'))
                  );
                } else {
                  setState(() {
                    videoFile = file.files.first;
                    _isNewVideoAdded = true;
                    _isVideoDeleted = false;
                  });
                  await _initializeController();
                }
              }
            },
          ),
        ],
      ),
    );
  }

// Метод для создания поля текста задания
  Widget _buildTaskTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFF48FB1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: _taskTextController,
          maxLines: null,
          onChanged: (value) {
            setState(() {
              _taskText = value;
            });
          },
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Текст теории',
            labelStyle: TextStyle(color: Colors.white),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }

// Метод для создания поля вопроса теста
  Widget _buildTestQuestionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFF48FB1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: _testQuestionController,
          onChanged: (value) {
            setState(() {
              _testQuestion = value;
            });
          },
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Вопрос для теста',
            labelStyle: TextStyle(color: Colors.white),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }

// Метод для создания поля правильного ответа
  Widget _buildCorrectAnswerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _correctAnswerController,
        onChanged: (value) {
          setState(() {
            _correctAnswer = value;
          });
        },
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: 'Правильный ответ',
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

// Метод для создания списка неправильных ответов
  Widget _buildWrongAnswersList() {
    return SingleChildScrollView(
      child: Column(
        children: _wrongAnswers.asMap().entries.map((entity) {
          int index = entity.key;
          String answer = entity.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controllers[index],
                    onChanged: (value) {
                      setState(() {
                        _wrongAnswers[index] = value;
                      });
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Неправильный ответ',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Color(0xFFF48FB1)),
                  onPressed: () async {
                    _deleteAnswer(_answerListObjects[index]['id']);
                    setState(() {
                      if (_wrongAnswers.length >= 1) {
                        _wrongAnswers.removeAt(index);
                        _answerListObjects.removeAt(index);
                        _controllers.removeAt(index);
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

// Метод для создания кнопки добавления неправильного ответа
  Widget _buildAddWrongAnswerButton() {
    return ElevatedButton(
      onPressed: _addWrongAnswer,
      child: Text('Добавить неправильный ответ'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFFF48FB1),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        textStyle: TextStyle(fontSize: 16),
      ),
    );
  }

// Метод для создания поля домашнего задания
  Widget _buildHomeworkTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFF48FB1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextFormField(
          controller: _homeworkController,
          maxLines: null,
          onChanged: (value) {
            setState(() {
              _homeworkText = value;
            });
          },
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Домашнее задание',
            labelStyle: TextStyle(color: Colors.white),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }

// Метод для создания кнопки "Сохранить"
  Widget _buildSaveButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _isSaving ? null : () async {
          setState(() {
            _isSaving = true;
          });
          await _handleSave(context);
          setState(() {
            _isSaving = false;
          });
          // Переход к следующей странице
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateLessonPage(
                courseSlug: widget.courseSlug,
                courseDescription: widget.courseDescription,
                courseAbout: widget.courseAbout,
                moduleIndex: widget.moduleIndex,
                moduleName: widget.moduleName,
                moduleId: widget.moduleId,
              ),
            ),
          );

        },
        child: Text('Сохранить'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFFF48FB1),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          textStyle: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

// Новый метод для обработки сохранения
  Future<void> _handleSave(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      // Сохранение названия урока
      if (_lessonName.isNotEmpty) {
        await _updateLessonName();
      }

      // Сохранение текстовых данных
      if (_initialTaskText.isEmpty && _taskText.isNotEmpty) {
        await _sendTextToServer();
      } else if (_taskText != _initialTaskText) {
        if (_taskText.isEmpty) {
          await _deleteTextData(_contentId!);
        } else {
          await _updateTextData();
        }
      }

      // Отправка видео на сервер, если оно выбрано
      if (_isNewVideoAdded && videoFile != null) {
        if (_videoPath.isNotEmpty) {
          // Если существует предыдущее видео, удалите его
          await _deleteVideoFromServer(_contentId!);
        }
        // Отправка нового видео на сервер
        await _sendVideoToServer();
      } else if (_isVideoDeleted) {
        // Удаление видео с сервера
        await _deleteVideoFromServer(_contentId!);
      }

      if (_initialQuestionText.isEmpty && _testQuestion.isNotEmpty) {
        await _sendQuestionToServer();
      } else if (_testQuestion != _initialQuestionText) {
        if (_testQuestion.isEmpty) {
          await _deleteQuestionData(_contentId!);
        } else {
          await _updateQuestionData();
        }
      }

      if (_initialCorrectAnswer.isEmpty && _correctAnswer.isNotEmpty) {
        await _sendCorrectAnswerToServer(_questionId!);
      } else if (_correctAnswer != _initialCorrectAnswer) {
        await _updateCorrectAnswer();
      }

      await updateAllWrongAnswers();

      if (_initialHomeworkText.isEmpty && _homeworkText.isNotEmpty) {
        print('Отправка на сервер');
        // await _sendTextToServer();
        await _sendHomeworkToServer();
      } else if (_homeworkText != _initialHomeworkText) {
        if (_homeworkText.isEmpty) {
          // print("Delete homework with id ${_contentId!}");
          await _deleteTextData(_contentId!);
        } else {
          print("Update homework");
          await _updateHomeworkData();
        }
      }
    }
  }

  void _showVideoDeleteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: GestureDetector(
            onTap: () async {
              setState(() {
                _isVideoDeleted = true;
                _isNewVideoAdded = false;
                _controller?.dispose();
                videoFile = null;
              });
              await _deleteVideoFromServer(_contentId!);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.black),
                SizedBox(width: 8),
                Text(
                  'Удалить видео',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
