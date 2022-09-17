import 'package:flutter/material.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:stundenplan/shared_state.dart';

class PullDownToRefresh extends StatelessWidget {
  const PullDownToRefresh(
      {/*required*/ required this.refreshController,
      /*required*/ required this.sharedState,
      /*required*/ required this.onRefresh,
      /*required*/ required this.child});

  final RefreshController refreshController;
  final SharedState sharedState;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: refreshController,
      header: WaterDropHeader(
        refresh: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(sharedState.theme.subjectColor),
        ),
        waterDropColor: sharedState.theme.subjectColor,
        complete: Icon(
          Icons.done,
          color: sharedState.theme.subjectColor,
        ),
      ),
      onRefresh: onRefresh,
      child: child,
    );
  }
}
