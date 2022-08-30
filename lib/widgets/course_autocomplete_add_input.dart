import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:stundenplan/parsing/parse_timetable.dart';
import 'package:stundenplan/shared_state.dart';


class CourseAutoCompleteAddInput extends StatefulWidget {
  const CourseAutoCompleteAddInput(
      {required this.sharedState, required this.onAdd});

  final SharedState sharedState;
  final void Function(String) onAdd;

  @override
  _CourseAutoCompleteAddInput createState() => _CourseAutoCompleteAddInput();
}

class _CourseAutoCompleteAddInput extends State<CourseAutoCompleteAddInput> {

  List<String> options = [];
  TextEditingController courseAddNameTextEditingController = TextEditingController();

  Future<void> setOptions() async {
    final client = Client();
    options = await getAllAvailableSubjects(client, widget.sharedState.profileManager.schoolClassFullName, widget.sharedState.profileManager.schoolGrade!);
  }

  @override
  void initState() {
    super.initState();
    setOptions();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 60+12,
              decoration: BoxDecoration(
                  color: widget.sharedState.theme.textColor.withAlpha(200),
                  borderRadius: BorderRadius.circular(15)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return options.where((String option) {
                      return option.contains(textEditingValue.text);
                    });
                  },
                  fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted
                      ) {
                    courseAddNameTextEditingController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(border: InputBorder.none, hintText: "En"),
                      style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 30.0),
                    );
                  },
                  optionsViewBuilder: (
                      BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options
                      ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        child: Container(
                          width: 150,
                          color : Color.fromRGBO(widget.sharedState.theme.textColor.red-20, widget.sharedState.theme.textColor.green-20, widget.sharedState.theme.textColor.blue-20, 1.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(0.0),
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return GestureDetector(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  title: Text(option, style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: 20.0),),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            child: ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    )
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                  widget.sharedState.theme.subjectColor,
                ),
              ),
              onPressed: () {
                setState(() {
                  widget.sharedState.hasChangedCourses = true;
                  widget.onAdd(courseAddNameTextEditingController.text);
                  courseAddNameTextEditingController.text = "";
                });
              },
              child: Container(
                height: 60+12,
                width: 60-12,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: 60-12,
                  color: widget.sharedState.theme.textColor,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}