import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stundenplan/shared_state.dart';

class PullDownToRefresh extends StatelessWidget {
  const PullDownToRefresh(
      {@required this.refreshController,
      @required this.sharedState,
      @required this.onRefresh,
      @required this.child});

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
