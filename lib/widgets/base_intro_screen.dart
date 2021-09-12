import 'package:flutter/material.dart';
import 'package:stundenplan/shared_state.dart';

class BaseIntroScreen extends StatelessWidget {
  const BaseIntroScreen(
      {required this.sharedState,
      required this.title,
      required this.subtitle,
      required this.child,
      required this.onPressed,
      this.buttonText = "Weiter",
      this.noButton = false});

  final SharedState sharedState;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool noButton;
  final Widget child;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: sharedState.theme.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      title,
                      style: TextStyle(
                          color: sharedState.theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 40.0
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: sharedState.theme.textColor, fontSize: 18.0
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              child,
              if (noButton) Container() else ElevatedButton(
                onPressed: onPressed,
                style: ButtonStyle(
                  shape:  MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                      )
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(
                    sharedState.theme.subjectColor,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                        color: sharedState.theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
