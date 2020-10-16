import 'package:flutter/material.dart';
import 'package:stundenplan/shared_state.dart';

class Loader extends StatelessWidget {
  const Loader(this.sharedState);

  final SharedState sharedState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        valueColor:
            AlwaysStoppedAnimation<Color>(sharedState.theme.subjectColor),
        backgroundColor: Colors.transparent,
        strokeWidth: 6.0,
      ),
    );
  }
}
