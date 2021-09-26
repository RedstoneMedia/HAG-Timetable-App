import 'package:flutter/material.dart';
import 'package:stundenplan/calendar_data.dart';
import '../shared_state.dart';

Future<void> showCalenderInfoDialog(List<CalendarDataPoint> dataPoints, BuildContext context, SharedState sharedState) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: sharedState.theme.backgroundColor,
        title: Text(
          'Kalender Infos',
          style: TextStyle(color: sharedState.theme.textColor),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            height: 300,
            width: MediaQuery.of(context).size.height * 0.8,
            child: ListView.builder(
              itemCount: dataPoints.length,
              itemBuilder: (_, i) {
                final dataPoint = dataPoints[i];
                final String timeString;
                if (dataPoint.startDate == dataPoint.endDate) {
                  timeString = "${dataPoint.endDate.hour.toString().padLeft(2, "0")}:${dataPoint.endDate.minute.toString().padLeft(2, "0")}";
                } else if (dataPoint.endDate.difference(dataPoint.startDate).inDays > 0){
                  timeString = "${dataPoint.startDate.day.toString().padLeft(2, "0")}.${dataPoint.startDate.month.toString().padLeft(2, "0")} - ${dataPoint.endDate.day.toString().padLeft(2, "0")}.${dataPoint.endDate.month.toString().padLeft(2, "0")}";
                } else {
                  timeString = "${dataPoint.startDate.hour.toString().padLeft(2, "0")}:${dataPoint.startDate.minute.toString().padLeft(2, "0")} - ${dataPoint.endDate.hour.toString().padLeft(2, "0")}:${dataPoint.endDate.minute.toString().padLeft(2, "0")}";
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Name:",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                        Expanded(
                          child: Text(dataPoint.name,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Typ:",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                        Expanded(
                          child: Text(dataPoint.calendarType.name(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("Zeit:",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                        Expanded(
                          child: Text(timeString,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: sharedState.theme.textColor)),
                        ),
                      ],
                    ),
                    Divider(
                      height: 20,
                      thickness: 1,
                      color: sharedState.theme.subjectDropOutColor,
                    )
                  ],
                );
              },
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Schließen',
              style: TextStyle(
                  color: sharedState.theme.subjectSubstitutionColor
              )
            ),
          ),
        ],
      );
    }
  );
}