import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class LessonData {
  final String lessonName;
  final String videoPath;
  final String taskText;
  final String testQuestion;
  final String correctAnswer;
  final String wrongAnswer1;
  final String wrongAnswer2;

  LessonData({
    required this.lessonName,
    required this.videoPath,
    required this.taskText,
    required this.testQuestion,
    required this.correctAnswer,
    required this.wrongAnswer1,
    required this.wrongAnswer2,
  });
}

class CreateLessonPage2 extends StatefulWidget {
  final String courseName;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;
  final int lessonIndex;
  final String lessonName;

  CreateLessonPage2({
    required this.courseName,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
    required this.lessonIndex,
    required this.lessonName,
  });

  @override
  _CreateLessonPage2State createState() => _CreateLessonPage2State();
}

class _CreateLessonPage2State extends State<CreateLessonPage2> {
  final _formKey = GlobalKey<FormState>();

  String _lessonName = '';
  String _videoPath = '';
  String _taskText = '';
  String _testQuestion = '';
  String _correctAnswer = '';
  String _wrongAnswer1 = '';
  String _wrongAnswer2 = '';
  PlatformFile? videoFile;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _lessonName = widget.lessonName;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    if (videoFile != null) {
      _controller = VideoPlayerController.file(File(videoFile!.path!))
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Video file path: ${videoFile?.path}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание урока'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
              SizedBox(height: 16),
              Row(
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
                        setState(() {
                          videoFile = file.files.first;
                        });
                        await _initializeController();
                      }
                    },
                  ),
                ],
              ),
              if (_controller != null && _controller!.value.isInitialized)
                Container(
                  height: 300,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),
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
              SizedBox(height: 16),
              Text('Напишите текст к заданию, либо оставьте поле пустым'),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFF48FB1), width: 3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  maxLines: null,
                  initialValue: _taskText,
                  onChanged: (value) {
                    setState(() {
                      _taskText = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Текст задания',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Введите вопрос для теста или оставьте тест пустым: '),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFF48FB1), width: 3),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextFormField(
                  initialValue: _testQuestion,
                  onChanged: (value) {
                    setState(() {
                      _testQuestion = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Вопрос теста',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Введите правильный ответ к тесту в зелёное поле, а неправильные в красное'),
              SizedBox(height: 8),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 3),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextFormField(
                      initialValue: _correctAnswer,
                      onChanged: (value) {
                        setState(() {
                          _correctAnswer = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Правильный ответ',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextFormField(
                      initialValue: _wrongAnswer1,
                      onChanged: (value) {
                        setState(() {
                          _wrongAnswer1 = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Неправильный ответ 1',
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 3),
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextFormField(
                      initialValue: _wrongAnswer2,
                      onChanged: (value) {
                        setState(() {
                          _wrongAnswer2 = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Неправильный ответ 2',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                child: Text('Сохранить'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFF48FB1),
                  shape: StadiumBorder(),
                ),
                onPressed: () {
                  // Save data and navigate back to the previous page
                  Navigator.pop(context, LessonData(
                    lessonName: _lessonName,
                    videoPath: _videoPath,
                    taskText: _taskText,
                    testQuestion: _testQuestion,
                    correctAnswer: _correctAnswer,
                    wrongAnswer1: _wrongAnswer1,
                    wrongAnswer2: _wrongAnswer2,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}