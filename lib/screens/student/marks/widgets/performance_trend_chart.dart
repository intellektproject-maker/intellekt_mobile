import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PerformanceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> marks;

  const PerformanceTrendChart({
    super.key,
    required this.marks,
  });

  List<FlSpot> _spots() {
    final List<FlSpot> spots = [];

    int x = 0;

    for (final mark in marks) {
      final obtained =
      mark['marks_obtained']?.toString().toUpperCase();

      if (obtained == 'A') {
        spots.add(FlSpot(x.toDouble(), 0));
      } else {
        final score =
            double.tryParse(obtained ?? '0') ?? 0;

        final total =
            double.tryParse(
              mark['total_marks'].toString(),
            ) ??
                1;

        spots.add(
          FlSpot(
            x.toDouble(),
            (score / total) * 100,
          ),
        );
      }

      x++;
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          const Text(
            "Performance Trend",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,

                gridData: FlGridData(
                  show: true,
                ),

                borderData: FlBorderData(
                  show: true,
                ),

                titlesData: FlTitlesData(

                  rightTitles:
                  const AxisTitles(),

                  topTitles:
                  const AxisTitles(),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 32,
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,

                      getTitlesWidget:
                          (value, meta) {

                        final index =
                        value.toInt();

                        if (index >=
                            marks.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            "T${index + 1}",
                            style:
                            const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineBarsData: [

                  LineChartBarData(
                    spots: _spots(),

                    isCurved: true,

                    barWidth: 4,

                    color: Colors.blue,

                    dotData: const FlDotData(
                      show: true,
                    ),

                    belowBarData:
                    BarAreaData(
                      show: true,
                      color: Colors.blue
                          .withOpacity(.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}