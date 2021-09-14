import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stundenplan/pages/intro/course_list_import_page.dart';
import 'package:stundenplan/pages/intro/course_selection.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/widgets/base_intro_screen.dart';

class CourseInputMethodSelectionPage extends StatefulWidget {
  final SharedState sharedState;

  const CourseInputMethodSelectionPage(this.sharedState);

  @override
  _CourseInputMethodSelectionPageState createState() => _CourseInputMethodSelectionPageState();
}

class _CourseInputMethodSelectionPageState extends State<CourseInputMethodSelectionPage> {

  final ImagePicker picker = ImagePicker();
  final textDetector = GoogleMlKit.vision.textDetector();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseIntroScreen(
        sharedState: widget.sharedState,
        onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelectionPage(widget.sharedState)));
        },
        subtitle: "Du kannst entweder ein Foto machen, oder deine Kurse selber eingeben.",
        title: "Kurse",
        noButton: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.66,
                decoration: BoxDecoration(
                  color:Colors.transparent,
                  border: Border.all(
                      color: widget.sharedState.theme.textColor
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ElevatedButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 35.0, horizontal: 10.0)),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseListImportPage(widget.sharedState)));
                  },
                  child: Column(
                    children: [
                       Icon(
                        Icons.document_scanner_outlined,
                        color: widget.sharedState.theme.textColor,
                        size: 80,
                      ),
                      const SizedBox(height: 10.0),
                      Text("Automatisch",
                          style: GoogleFonts.poppins(
                              color: widget.sharedState.theme.textColor,
                              fontSize: 30.0,
                              fontWeight: FontWeight.bold
                          )
                      )
                    ]
                  ),
                ),
              )
            ),
            const SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.66,
                  decoration: BoxDecoration(
                    color:Colors.transparent,
                    border: Border.all(
                      color: widget.sharedState.theme.textColor
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ElevatedButton (
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 35.0, horizontal: 10.0)),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelectionPage(widget.sharedState)));
                    },
                    child: Column(
                        children: [
                          Icon(
                            Icons.edit,
                            color: widget.sharedState.theme.textColor,
                            size: 80,
                          ),
                          const SizedBox(height: 10.0),
                          Text("Manuell",
                            style: GoogleFonts.poppins(
                                color: widget.sharedState.theme.textColor,
                                fontSize: 30.0,
                                fontWeight: FontWeight.bold
                            )
                          )
                        ]
                    )
                  ),
                )
            ),
          ],
        )
    );
  }
}
