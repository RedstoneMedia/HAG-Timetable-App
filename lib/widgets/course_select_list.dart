import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/shared_state.dart';

// ignore: must_be_immutable
class CourseSelectList extends StatefulWidget {
  @override
  _CourseSelectListState createState() => _CourseSelectListState();

  CourseSelectList(this.sharedState, this.courses);

  SharedState sharedState;
  List<String> courses;
}

class _CourseSelectListState extends State<CourseSelectList> {
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.courses.length; i++) {
      addController();
    }
    setCoursesText();
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CourseSelectList oldWidget) {
    while (widget.courses.length > controllers.length) {
      addController();
    }
    setCoursesText();
    super.didUpdateWidget(oldWidget);
  }

  void addController() {
    controllers.add(TextEditingController());
  }

  void setCoursesText() {
    setState(() {
      for (var i = 0; i < widget.courses.length; i++) {
        controllers[i].text = widget.courses[i];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: widget.sharedState.theme.textColor.withAlpha(15),
            borderRadius: BorderRadius.circular(5)),
        child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: [for (var index = 0; index < widget.courses.length; index++)
              Dismissible(
                key: ObjectKey(widget.courses[index]), // Never use a UniqueKey here
                background: Container(
                  color: Colors.red,
                ),
                onDismissed: (_) {
                  setState(() {
                    widget.sharedState.hasChangedCourses = true;
                    widget.courses.removeAt(index);
                    controllers[index].dispose();
                    controllers.removeAt(index);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.edit,
                              color: widget.sharedState.theme.textColor,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: widget.sharedState.theme.textColor),
                            ),
                          ),
                          onChanged: (text) {
                            widget.sharedState.hasChangedCourses = true;
                            widget.courses[index] = text;
                          },
                          controller: controllers[index],
                          style: GoogleFonts.poppins(
                              color: widget.sharedState.theme.textColor,
                              fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}
