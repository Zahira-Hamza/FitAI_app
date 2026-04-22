import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CaloriesBarChart extends StatefulWidget {
  final List<double> data; // 7 values Mon–Sun
  final int todayIndex; // 0=Mon … 6=Sun

  const CaloriesBarChart({
    super.key,
    required this.data,
    required this.todayIndex,
  });

  @override
  State<CaloriesBarChart> createState() => _CaloriesBarChartState();
}

class _CaloriesBarChartState extends State<CaloriesBarChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = widget.data.isEmpty
        ? 500.0
        : widget.data.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal < 200 ? 300.0 : maxVal + 80);

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        color: i == widget.todayIndex
                            ? const Color(0xFFC4C0FF)
                            : const Color(0xFF9E9EBE),
                        fontWeight: i == widget.todayIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchCallback: (_, response) =>
                setState(() => _touched = response?.spot?.touchedBarGroupIndex),
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                '${rod.toY.toInt()} kcal',
                const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          barGroups: widget.data.asMap().entries.map((e) {
            final isToday = e.key == widget.todayIndex;
            final isTouched = e.key == _touched;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  color: isTouched
                      ? Colors.white
                      : isToday
                          ? const Color(0xFFC4C0FF)
                          : const Color(0xFF6C63FF).withOpacity(0.5),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
