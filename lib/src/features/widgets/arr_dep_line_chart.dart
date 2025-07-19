// lib/src/features/widgets/arr_dep_line_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ArrDepLineChart extends StatelessWidget {
  final List<double> data2023;
  final List<double> data2024;
  final List<double> data2025;

  const ArrDepLineChart({
    super.key,
    required this.data2023,
    required this.data2024,
    required this.data2025,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                      if (value.toInt() < 0 || value.toInt() >= months.length) return const Text('');
                      return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: 4000,
                    getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              lineBarsData: [
                _buildLine(data2023, Colors.green),
                _buildLine(data2024, Colors.red),
                _buildLine(data2025, Colors.blue, showDotAtLast: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend("2023", Colors.green),
            const SizedBox(width: 12),
            _legend("2024", Colors.red),
            const SizedBox(width: 12),
            _legend("2025", Colors.blue),
          ],
        )
      ],
    );
  }

  LineChartBarData _buildLine(List<double> data, Color color, {bool showDotAtLast = false}) {
    final spots = List.generate(data.length, (index) => FlSpot(index.toDouble(), data[index]));
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, _) => showDotAtLast && spot.x == spots.last.x,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 5,
          color: Colors.white,
          strokeColor: color,
          strokeWidth: 2,
        ),
      ),
      barWidth: 2,
      dashArray: [6, 4],
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _legend(String year, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(year),
      ],
    );
  }
}
