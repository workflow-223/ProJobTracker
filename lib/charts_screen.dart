import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'auth_service.dart';
import 'database_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late Future<List<PieChartSectionData>> _applicationStatusFuture;
  late Future<List<PieChartSectionData>> _positionsAppliedFuture;
  late Future<List<BarChartGroupData>> _barDataFuture;

  @override
  void initState() {
    super.initState();
    _applicationStatusFuture = _fetchApplicationStatusData();
    _positionsAppliedFuture = _fetchPositionsAppliedData();
    _barDataFuture = _fetchBarData();
  }

  Future<List<PieChartSectionData>> _fetchApplicationStatusData() async {
    final userId = AuthService().userId;
    if (userId == null) return [];

    final rows = await DatabaseService.getStatusCounts(userId);
    if (rows.isEmpty) return [];

    final total = rows.fold<int>(0, (sum, r) => sum + (r['count'] as int));
    final colorMap = {
      'Applied': const Color(0xFFFF6FCF),
      'Interviewed': const Color(0xFFD691FF),
      'Rejected': const Color(0xFFFFA500),
      'Accepted': const Color(0xFFB2FF59),
    };

    return rows.map((row) {
      final status = row['status'] as String;
      final count = row['count'] as int;
      final percentage = (count / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colorMap[status] ?? Colors.grey,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Future<List<PieChartSectionData>> _fetchPositionsAppliedData() async {
    final userId = AuthService().userId;
    if (userId == null) return [];

    final rows = await DatabaseService.getPositionCounts(userId);
    if (rows.isEmpty) return [];

    final total = rows.fold<int>(0, (sum, r) => sum + (r['count'] as int));
    final colorPalette = [
      const Color(0xFF42A5F5),
      const Color(0xFFCE93D8),
      const Color(0xFFFFB74D),
      const Color(0xFF9CCC65),
      const Color(0xFFBDBDBD),
    ];

    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      final count = row['count'] as int;
      final percentage = (count / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colorPalette[entry.key % colorPalette.length],
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Future<List<BarChartGroupData>> _fetchBarData() async {
    final userId = AuthService().userId;
    if (userId == null) return [];

    final rows = await DatabaseService.getAvgSalaryByPosition(userId);
    if (rows.isEmpty) return [];

    final colorPalette = [
      const Color(0xFF42A5F5),
      const Color(0xFFCE93D8),
      const Color(0xFFFFB74D),
      const Color(0xFF9CCC65),
      const Color(0xFFBDBDBD),
    ];

    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      final avgSalary = (row['avg_salary'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: avgSalary / 1000,
            color: colorPalette[entry.key % colorPalette.length],
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Application Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<List<PieChartSectionData>>(
                future: _applicationStatusFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No job data available'),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(
                      sections: snapshot.data!,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    )),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Positions Applied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FutureBuilder<List<PieChartSectionData>>(
                future: _positionsAppliedFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No job data available'),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(
                      sections: snapshot.data!,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    )),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Average Salaries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FutureBuilder<List<BarChartGroupData>>(
                future: _barDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No salary data available'),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 300,
                    child: BarChart(BarChartData(
                      maxY: 150,
                      barGroups: snapshot.data!,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value % 20 == 0) {
                                return Text('${value.toInt()}k');
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true, horizontalInterval: 20),
                      borderData: FlBorderData(show: false),
                    )),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
