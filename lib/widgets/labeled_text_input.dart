import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/shared_state.dart';

class LabeledTextInput extends StatefulWidget {
  final String labelText;
  final SharedState sharedState;
  final List<String> outputList;
  final int index;
  final double fontSize;
  final bool obscureText;
  final bool incorrect;

  const LabeledTextInput(this.labelText, this.sharedState, this.outputList, this.index, {this.fontSize = 20, this.obscureText = false, this.incorrect = false});

  @override
  _LabeledTextInputState createState() => _LabeledTextInputState();
}

class _LabeledTextInputState extends State<LabeledTextInput> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    while (widget.outputList.length <= widget.index) {
      widget.outputList.add("");
    }
    textEditingController.text = widget.outputList[widget.index];
  }

  @override
  void didUpdateWidget(LabeledTextInput oldWidget) {
    textEditingController.text = widget.outputList[widget.index];
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.labelText,
          style: GoogleFonts.poppins(
              color: widget.sharedState.theme.textColor,
              fontSize: 20.0,
              fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            color: widget.sharedState.theme.textColor.withAlpha(200),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red, style: widget.incorrect ? BorderStyle.solid : BorderStyle.none),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextField(
              controller: textEditingController,
              obscureText: widget.obscureText,
              decoration: const InputDecoration(border: InputBorder.none),
              style: GoogleFonts.poppins(color: widget.sharedState.theme.invertedTextColor, fontSize: widget.fontSize),
              onChanged: (text) {
                widget.outputList[widget.index] = text;
              },
            ),
          ),
        ),
      ],
    );
  }
}
