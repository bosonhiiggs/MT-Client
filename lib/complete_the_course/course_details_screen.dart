import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main_pages/my_courses_page.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  CourseDetailsScreen({required this.course});

  @override
  _CourseDetailsScreenState createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isExpanded = false;
  List<Module> _modules = [];
  String? _sessionId;
  String? _csrfToken;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
    });

    if (_sessionId != null || _csrfToken != null) {
      _fetchModules();
    }
  }

  Future<void> _fetchModules() async {
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/modules/';
    print('Fetching modules from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);
        print('Decoded data: $data');

        setState(() {
          _modules = (data as List).map((json) => Module.fromJson(json)).toList();
        });
        print('Modules fetched successfully: $_modules');
      } else {
        print('Failed to fetch modules: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching modules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.course.logo.isNotEmpty)
                Image.network(
                  widget.course.logo,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 16.0),
              Text(
                widget.course.targetDescription,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              _buildDescription(),
              SizedBox(height: 16.0),
              _buildModules(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    bool showLoadMore = widget.course.description.length > 300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isExpanded
              ? widget.course.description
              : (widget.course.description.length > 300
              ? widget.course.description.substring(0, 300) + '...'
              : widget.course.description),
          style: TextStyle(fontSize: 16),
        ),
        if (showLoadMore)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _isExpanded ? 'Скрыть текст' : 'Загрузить еще',
                  style: TextStyle(fontSize: 16, color: Color(0xFFF48FB1)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModules() {
    if (_modules.isEmpty) {
      return Center(
        child: Text(
          'Модули отсутствуют',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index];
        return ExpansionTile(
          title: Container(
            color: Color(0xFFF48FB1),
            padding: EdgeInsets.all(16.0),
            child: Text(
              module.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.transparent,
          children: module.lessons.map((lesson) {
            return ListTile(
              title: Text(lesson.title),
              tileColor: Colors.transparent,
            );
          }).toList(),
        );
      },
    );
  }
}

class Module {
  final int id;
  final String title;
  final List<Lesson> lessons;

  Module({required this.id, required this.title, required this.lessons});

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      lessons: json['lessons'] != null
          ? (json['lessons'] as List).map((lessonJson) => Lesson.fromJson(lessonJson)).toList()
          : [],
    );
  }
}

class Lesson {
  final String title;

  Lesson({required this.title});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json['title'] ?? '',
    );
  }
}
