import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CustomGraph extends StatelessWidget {
  CustomGraph({
    super.key,
    Color? mainLineColor,
    Color? belowLineColor,
    Color? aboveLineColor,
    required this.data,
    required this.limit,
    required this.showSpots,
    required this.average,
  })  : mainLineColor = Colors.redAccent,
        belowLineColor = Colors.red.shade100,
        aboveLineColor = Colors.white;

  final Color mainLineColor;
  final Color belowLineColor;
  final Color aboveLineColor;
  final List<FlSpot> data;
  final double limit;
  final double average;
  final bool showSpots;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: AspectRatio(
        aspectRatio: 2,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 28,
            top: 22,
            bottom: 12,
          ),
          child: LineChart(

            LineChartData(
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: limit,
                    color: Colors.redAccent,
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                      ),
                      labelResolver: (line) =>
                          'Limit: ${limit.toStringAsFixed(1)}',
                    ),
                  ),
                  HorizontalLine(
                    y: average,
                    color: Colors.redAccent,
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                      ),
                      labelResolver: (line) =>
                          'Avg: ${average.toStringAsFixed(1)}',
                    ),
                  ),
                ],
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (LineBarSpot spot) {
                    return Colors.redAccent;
                  },
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipBorderRadius: BorderRadius.circular(12),
                  getTooltipItems: (touchedSpots) {
                    List<LineTooltipItem> toolTips = [];

                    for (LineBarSpot spot in touchedSpots) {
                      toolTips.add(
                        LineTooltipItem(
                          spot.y.toString(),
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return toolTips;
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data,
                  isCurved: true,
                  curveSmoothness: 0.5,
                  barWidth: 1,
                  color: mainLineColor,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.white,
                    applyCutOffY: true,
                  ),
                  aboveBarData: BarAreaData(
                    show: true,
                    color: Colors.white,
                    cutOffY: limit,
                    applyCutOffY: false,
                  ),
                  dotData: FlDotData(
                    show: showSpots,
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        meta.formattedValue,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 8,
                          
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              gridData: FlGridData(
                show: false,
                drawVerticalLine: true,
                horizontalInterval: 3,
                // checkToShowHorizontalLine: (double value) {
                //   return value == 1 || value == 6 || value == 4 || value == 5;
                // },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
