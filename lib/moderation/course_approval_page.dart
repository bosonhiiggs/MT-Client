import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_pages/music_courses_page.dart';
import 'lesson_review_page.dart';

class CourseApprovalScreen extends StatefulWidget {
  final Course course;

  CourseApprovalScreen({required this.course});

  @override
  _CourseApprovalScreenState createState() => _CourseApprovalScreenState();
}

class _CourseApprovalScreenState extends State<CourseApprovalScreen> {
  List<Module> _modules = [];
  String? _sessionId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
    });

    if (_sessionId != null) {
      _fetchModules();
    }
  }

  Future<void> _fetchModules() async {
    if (_sessionId == null) return;

    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/modules/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId',
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);

        List<Module> modules = (data as List).map((json) => Module.fromJson(json)).toList();

        // Fetch lessons for each module
        for (var module in modules) {
          await _fetchLessonsForModule(module);
        }

        setState(() {
          _modules = modules;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLessonsForModule(Module module) async {
    if (_sessionId == null) return;

    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/modules/${module.id}/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId',
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);

        List<Lesson> lessons = (data as List).map((json) => Lesson.fromJson(json)).toList();
        module.lessons.addAll(lessons);
      }
    } catch (e) {
      // Обработка ошибок
    }
  }

  Future<void> _approveCourse() async {
    // Логика одобрения курса
  }

  Future<void> _rejectCourse() async {
    // Логика отклонения курса
  }

  Widget _buildRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            color: Color(0xFFF48FB1),
          );
        } else if (index == rating.floor() && rating % 1 != 0) {
          return Stack(
            children: [
              Icon(
                Icons.star,
                color: Colors.grey,
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: rating % 1,
                  child: Icon(
                    Icons.star,
                    color: Color(0xFFF48FB1),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Icon(
            Icons.star,
            color: Colors.grey,
          );
        }
      }),
    );
  }

  String _formatRating(double rating) {
    if (rating % 1 == 0) {
      return '${rating.toInt()}/5';
    } else {
      return '${rating.toStringAsFixed(1)}/5';
    }
  }

  Widget _buildModules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            'Модули',
            style: TextStyle(fontSize: 30),
          ),
        ),
        SizedBox(height: 8.0),
        if (_modules.isEmpty)
          Center(
            child: Text(
              'Модули отсутствуют',
              style: TextStyle(fontSize: 18),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              final module = _modules[index];
              return ModuleTile(module: module, moduleIndex: index + 1, courseSlug: widget.course.slug);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.targetDescription,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          widget.course.description,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16.0),
                        _buildModules(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _approveCourse,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: Text('Одобрить курс'),
                ),
                ElevatedButton(
                  onPressed: _rejectCourse,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: Text('Отклонить курс'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleTile extends StatefulWidget {
  final Module module;
  final int moduleIndex;
  final String courseSlug;

  ModuleTile({required this.module, required this.courseSlug, required this.moduleIndex});

  @override
  _ModuleTileState createState() => _ModuleTileState();
}

class _ModuleTileState extends State<ModuleTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      width: MediaQuery.of(context).size.width,
      color: Color(0xFFF48FB1),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Color(0xFFF48FB1),
            iconColor: Colors.white,
          ),
          listTileTheme: ListTileThemeData(
            tileColor: Colors.white,
          ),
        ),
        child: ExpansionTile(
          title: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '${widget.moduleIndex}. ${widget.module.title}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: Colors.white,
          ),
          children: widget.module.lessons.asMap().entries.map((entry) {
            final lessonIndex = entry.key + 1;
            final lesson = entry.value;
            return Column(
              children: [
                ListTile(
                  title: Text(
                    '${widget.moduleIndex}.$lessonIndex. ${lesson.title}',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonReviewScreen(
                          lesson: lesson,
                          courseSlug: widget.courseSlug,
                          moduleId: widget.module.id,
                          lessonId: lesson.id,
                        ),
                      ),
                    );
                  },
                ),
                if (lessonIndex < widget.module.lessons.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: Colors.white,
                      thickness: 1,
                    ),
                  ),
              ],
            );
          }).toList(),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _isExpanded = isExpanded;
            });
          },
        ),
      ),
    );
  }
}

class Module {
  final int id;
  final String title;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      lessons: (json['lessons'] as List).map((json) => Lesson.fromJson(json)).toList(),
    );
  }
}

class Lesson {
  final int id;
  final String title;

  Lesson({required this.id, required this.title});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}
