import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_pages/music_courses_page.dart';
import 'lesson_review_page.dart';
import 'moderation_page.dart';

class CourseApprovalScreen extends StatefulWidget {
  final Course course;

  CourseApprovalScreen({required this.course});

  @override
  _CourseApprovalScreenState createState() => _CourseApprovalScreenState();
}

class _CourseApprovalScreenState extends State<CourseApprovalScreen> {
  List<Module> _modules = [];
  String? _sessionId;
  String? _csrfToken;
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
      _csrfToken = prefs.getString('csrftoken');
    });

    if (_sessionId != null) {
      _fetchModules();
    }
  }

  Future<void> _fetchModules() async {
    if (_sessionId == null) return;

    final url = 'http://109.73.196.253:8001/api/mycourses/${widget.course.slug}/modules/';

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
        print("Decoded Modules: $data");

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
        print("Status code: ${response.statusCode}");
        print("Body: ${response.bodyBytes}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error for loading modules $e");
    }
  }

  Future<void> _fetchLessonsForModule(Module module) async {
    if (_sessionId == null) return;

    final url = 'http://109.73.196.253:8001/api/mycourses/${widget.course.slug}/modules/${module.id}/';

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
        print('Decoded lesson data: $data');

        List<Lesson> lessons = (data as List).map((json) => Lesson.fromJson(json)).toList();
        module.lessons.addAll(lessons);
        print('Lessons fetched for module ${module.id}: $lessons');
      } else {
        print('Failed to fetch lessons for module ${module.id}: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      // Обработка ошибок
      print('Error fetching lessons for module ${module.id}: $e');
    }
  }

  Future<void> _approveCourse() async {
    // Логика одобрения курса
    // if (_sessionId == null) return;
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://109.73.196.253:8001/api/moderation/${widget.course.slug}/';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
          'X-CSRFToken': _csrfToken!,
        },
        body: json.encode({'action': 'approve'}),
      );
      if (response.statusCode == 200) {
        print('Course approve successfully');
      } else {
        print('Error approve response server: ${response.statusCode}');
      }
    } catch (e) {
      print("Error for approve course: $e");
    }
  }

  Future<void> _rejectCourse() async {
    // Логика отклонения курса
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://109.73.196.253:8001/api/moderation/${widget.course.slug}/';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
          'X-CSRFToken': _csrfToken!,
        },
        body: json.encode({'action': 'disapprove'}),
      );
      if (response.statusCode == 200) {
        print('Course disapprove successfully');
      } else {
        print('Error disapprove response server: ${response.statusCode}');
      }
    } catch (e) {
      print("Error for disapprove course: $e");
    }
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
                  onPressed: () {
                    _approveCourse();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ModerationPage())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  ),
                  child: Text('Одобрить курс'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _rejectCourse();
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ModerationPage())
                    );
                  },
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
      // lessons: (json['lessons'] as List).map((json) => Lesson.fromJson(json)).toList(),
      lessons: [],
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
