import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/shared_state.dart';

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
    for (int i = 0; i < widget.courses.length; i++) {
      controllers.add(new TextEditingController());
      controllers[i].text = widget.courses[i];
    }
  }

  void addController() {
    controllers.add(new TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courses.length != controllers.length) {
      addController();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: widget.sharedState.theme.textColor.withAlpha(15),
            borderRadius: BorderRadius.circular(5)),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.courses.length,
            itemBuilder: (_, index) {
              return Dismissible(
                key: Key(widget.courses[index]),
                background: Container(
                  color: Colors.red,
                ),
                onDismissed: (_) {
                  setState(() {
                    widget.courses.removeAt(index);
                    controllers.removeAt(index);
                  });
                },
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.edit,
                            color: widget.sharedState.theme.textColor,
                          ),
                          border: new OutlineInputBorder(
                            borderSide: new BorderSide(
                                color: widget.sharedState.theme.textColor),
                          ),
                        ),
                        onChanged: (text) {
                          widget.courses[index] = text;
                        },
                        controller: controllers[index],
                        style: GoogleFonts.poppins(
                            color: widget.sharedState.theme.textColor, fontSize: 25),
                      ),
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
