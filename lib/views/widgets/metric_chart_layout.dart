import 'package:flutter/material.dart';

/// Shared layout helpers for metric explorer charts.
abstract final class MetricChartLayout {
  static double edgePad(int pointCount) {
    if (pointCount <= 1) return 0;
    if (pointCount <= 2) return 0.42;
    if (pointCount <= 4) return 0.28;
    return 0.18;
  }

  static const chartPadding = EdgeInsets.fromLTRB(2, 6, 16, 2);

  static Widget axisDateLabel(String text, {Color? color}) {
    return SizedBox(
      width: 54,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
