import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main_pages/my_courses_page.dart';
import 'lesson_content_screen.dart'; // Импортируем второй файл

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
  int? _currentLessonId;
  OverlayEntry? _overlayEntry;
  List<Comment> _comments = [];
  String _commentText = '';
  double _rating = 0.0;
  bool _isLoading = true;
  String _userFirstName = '';
  String _userLastName = '';

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
      _userFirstName = prefs.getString('first_name') ?? '';
      _userLastName = prefs.getString('last_name') ?? '';
    });

    if (_sessionId != null || _csrfToken != null) {
      _fetchModules();
      _fetchComments();
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

        List<Module> modules = (data as List).map((json) => Module.fromJson(json)).toList();

        // Fetch lessons for each module
        for (var module in modules) {
          await _fetchLessonsForModule(module);
        }

        setState(() {
          _modules = modules;
          _isLoading = false;
        });
        print('Modules fetched successfully: $_modules');
      } else {
        print('Failed to fetch modules: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching modules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLessonsForModule(Module module) async {
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/modules/${module.id}/';
    print('Fetching lessons for module ${module.id} from: $url');

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

        List<Lesson> lessons = (data as List).map((json) => Lesson.fromJson(json)).toList();
        module.lessons.addAll(lessons);
        print('Lessons fetched for module ${module.id}: $lessons');
      } else {
        print('Failed to fetch lessons for module ${module.id}: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching lessons for module ${module.id}: $e');
    }
  }

  Future<void> _fetchComments() async {
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/comments/';
    print('Fetching comments from: $url');

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

        List<Comment> comments = (data as List).map((json) => Comment.fromJson(json)).toList();

        setState(() {
          _comments = comments;
        });
        print('Comments fetched successfully: $_comments');
      } else {
        print('Failed to fetch comments: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_sessionId == null || _csrfToken == null || _currentLessonId == null) return;

    // Assuming you have the module_id, lesson_id, and content_id available
    final moduleId = 1; // Replace with the actual module ID
    final lessonId = _currentLessonId; // Replace with the actual lesson ID if different
    final contentId = 1; // Replace with the actual content ID

    // Construct the URL
    final url = 'http://80.90.187.60:8001/api/mycourses/${widget.course.slug}/modules/$moduleId/$lessonId/$contentId/comments/';
    print('Submitting comment to: $url'); // Debugging information

    // Construct the request body
    final requestBody = json.encode({
      'comment': _commentText,
      'ratings': [_rating],
      'first_name': _userFirstName,
      'last_name': _userLastName,
    });
    print('Request body: $requestBody'); // Debugging information

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$_sessionId',
          'X-CSRFToken': _csrfToken!,
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}'); // Debugging information
      print('Response body: ${response.body}'); // Debugging information

      if (response.statusCode == 201) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);
        print('Decoded data: $data'); // Debugging information

        Comment newComment = Comment.fromJson(data);

        setState(() {
          _comments.add(newComment);
          _commentText = '';
          _rating = 0.0;
        });
        print('Comment submitted successfully: $newComment'); // Debugging information
      } else {
        print('Failed to submit comment: ${response.statusCode}'); // Debugging information
        print('Response body: ${response.body}'); // Debugging information
      }
    } catch (e) {
      print('Error submitting comment: $e'); // Debugging information
    }
  }

  void _showLessonId(int lessonId) {
    setState(() {
      _currentLessonId = lessonId;
    });

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Lesson ID: $_currentLessonId',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _hideLessonId() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
          : SingleChildScrollView(
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
                  _buildDescription(),
                  SizedBox(height: 16.0),
                  _buildModules(),
                  SizedBox(height: 16.0),
                  _buildCommentSection(),
                ],
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            'Модули',
            style: TextStyle(fontSize: 30), // Set the color for the module title
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
              print('Building module: ${module.title} with ${module.lessons.length} lessons');
              return ModuleTile(module: module, moduleIndex: index + 1);
            },
          ),
      ],
    );
  }

  Widget _buildCommentSection() {
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
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                  child: Icon(
                    Icons.star,
                    color: index < _rating ? Color(0xFFF48FB1) : Colors.grey,
                  ),
                );
              }),
            ),
          ],
        ),
        SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
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
                    onPressed: _submitComment,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _commentText = value;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.0),
        if (_comments.isEmpty)
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
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return CommentTile(comment: comment);
            },
          ),
      ],
    );
  }
}

class ModuleTile extends StatefulWidget {
  final Module module;
  final int moduleIndex;

  ModuleTile({required this.module, required this.moduleIndex});

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
                        builder: (context) => LessonContentScreen(lesson: lesson),
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

  Module({required this.id, required this.title, required this.lessons});

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
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

class Comment {
  final int id;
  final String user;
  final String firstName;
  final String lastName;
  final String avatar;
  final String comment;
  final double rating;

  Comment({
    required this.id,
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.comment,
    required this.rating,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      user: json['user'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
      comment: json['comment'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
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
                  comment.comment,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      color: index < comment.rating ? Color(0xFFF48FB1) : Colors.grey,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
