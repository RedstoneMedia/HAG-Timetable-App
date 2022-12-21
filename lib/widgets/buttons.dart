import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/shared_state.dart';
import 'package:stundenplan/theme.dart' as my_theme;
import 'package:url_launcher/url_launcher.dart';

class SelectableButton extends StatelessWidget {
  const SelectableButton(
      {required this.onPressed,
      required this.backgroundColor,
      required this.borderColor,
      required this.selectedBorderColor,
      required this.child,
      this.isSelected = false});

  final bool isSelected;
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1.0,
      child: Container(
        height: 90.0,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? selectedBorderColor : borderColor,
            width: isSelected ? 4.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 7.0 : 11.0),
          child: Material(
            color: backgroundColor,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(isSelected ? 0.0 : 3.0),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeButton extends StatefulWidget {
  const ThemeButton(
      {required this.theme, required this.isSelected, required this.onPressed});

  final my_theme.Theme theme;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  _ThemeButtonState createState() => _ThemeButtonState();
}

class _ThemeButtonState extends State<ThemeButton> {
  @override
  Widget build(BuildContext context) {
    return SelectableButton(
      onPressed: widget.onPressed,
      backgroundColor: widget.theme.backgroundColor,
      borderColor: widget.theme.textColor,
      selectedBorderColor: widget.theme.subjectColor,
      isSelected: widget.isSelected,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.theme.themeName,
              style: TextStyle(
                  color: widget.theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 40.0),
            ),
            _ThemeSquare(widget.theme),
          ],
        ),
      ),
    );
  }
}

class _ThemeSquare extends StatelessWidget {
  const _ThemeSquare(this.theme);

  final my_theme.Theme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _ColoredSquare(theme.subjectColor),
              _ColoredSquare(theme.subjectSubstitutionColor),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _ColoredSquare(theme.textColor),
              _ColoredSquare(theme.subjectDropOutColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColoredSquare extends StatelessWidget {
  const _ColoredSquare(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: EdgeInsets.all(2.0),
        child: Container(
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8.0)),
          height: double.infinity,
        ),
      ),
    );
  }
}

class ColorPickerButton extends StatefulWidget {
  ColorPickerButton(
      {required this.text,
      required this.bgColor,
      required this.textColor,
      required this.onPicked,
      required this.theme,
      this.borderColor,
      this.padding = 12.0,
      this.fontSize = 20.0});

  final String text;
  Color bgColor;
  Color textColor;
  Color? borderColor;
  double padding;
  double fontSize;
  final void Function(Color) onPicked;
  final my_theme.Theme theme;

  @override
  _ColorPickerButtonState createState() => _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: () {
            showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text(
                      'Farbe für "${widget.text}"',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        enableAlpha: false,
                        pickerColor: widget.bgColor,
                        onColorChanged: (Color newColor) {
                          setState(() {
                            widget.bgColor = newColor;
                            widget.onPicked(newColor);
                          });
                        },
                        pickerAreaBorderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2.0),
                          topRight: Radius.circular(2.0),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Fertig",
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0),
                        ),
                      ),
                    ],
                  );
                });
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.bgColor,
              border: Border.all(
                  color: widget.borderColor != null ? widget.borderColor! : widget.theme.textColor.withAlpha(150),
                  style: widget.bgColor.withAlpha(255) == widget.theme.backgroundColor.withAlpha(255) ? BorderStyle.solid : BorderStyle.none),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: widget.padding),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: widget.textColor.withAlpha(255) == widget.bgColor.withAlpha(255) ? my_theme.Theme.invertColor(widget.textColor) : widget.textColor,
                  fontSize: widget.fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StandardButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final SharedState sharedState;
  final Color color;
  final double fontSize;
  final Color? textColor;
  final FontWeight fontWeight;
  final double size;
  final bool disabled;

  const StandardButton({
    required this.text,
    required this.onPressed,
    required this.sharedState,
    required this.color,
    this.fontSize = 20,
    this.fontWeight = FontWeight.bold,
    this.textColor,
    this.size = 1,
    this.disabled = false
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ButtonStyle(
        shape:  MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            )
        ),
        backgroundColor: MaterialStateProperty.all<Color>(
          color,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0 * size, horizontal: 10.0 * size),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              color: textColor ?? sharedState.theme.textColor,
              fontWeight: fontWeight,
              fontSize: fontSize),
        ),
      ),
    );
  }
}

/// A Help Button, that opens a help page in the wiki, if pressed. Must be placed in a Stack widget.
class HelpButton extends StatelessWidget {
  final SharedState sharedState;
  final String helpPage;

  const HelpButton(this.helpPage, {required this.sharedState});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -10,
      top: -10,
      child: FloatingActionButton(
        onPressed: () async {
          await launchUrl(Uri.parse("${Constants.wikiBaseUrl}/$helpPage"));
        },
        backgroundColor: sharedState.theme.textColor.withAlpha(150),
        mini: true,
        tooltip: "Hilfe",
        child: Icon(
          Icons.help_outline_sharp,
          color: sharedState.theme.backgroundColor,
          size: 25.0,
        ),
      ),
    );
  }
}
