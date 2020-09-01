import 'package:flutter/material.dart';
import 'package:stundenplan/constants.dart';
import 'package:stundenplan/content.dart';
import 'package:stundenplan/shared_state.dart';

import 'grid.dart';

class TimeTable extends StatelessWidget {
  TimeTable(
      {@required this.sharedState,
      @required this.content});

  final SharedState sharedState;
  final Content content;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int y = 0; y < sharedState.height; y++)
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
                  WeekdayGridObject(Constants.weekDays[x], x, x == 1,
                      x == Constants.width - 1, sharedState)
                else
                  ClassGridObject(
                      content, sharedState, x, y - 1, x == 1, context)
            ],
          ),
      ],
    );
  }
}
