import 'package:flutter/material.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/shared_state.dart';

import 'grid.dart';

class TimeTable extends StatelessWidget {
  const TimeTable({/*required*/ required this.sharedState, /*required*/ required this.content});

  final SharedState sharedState;
  final Content content;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int y = 0; y < sharedState.content.cells.length+1; y++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int x = 0; x < Constants.width; x++)
                if (x == 0)
                  if (y == 0)
                    PlaceholderGridObject()
                  else
                    TimeGridObject(y, sharedState)
                else if (y == 0)
                  WeekdayGridObject(
                      weekday: Constants.weekDays[x],
                      x: x,
                      needsLeftBorder: x == 1,
                      needsRightBorder: x == Constants.width - 1,
                      sharedState: sharedState)
                else
                  ClassGridObject(
                      content: content,
                      sharedState: sharedState,
                      x: x,
                      y: y - 1,
                      needsLeftBorder: x == 1,
                      context: context)
            ],
          ),
      ],
    );
  }
}
