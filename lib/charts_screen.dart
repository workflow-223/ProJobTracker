import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    _applicationStatusFuture = FirestoreDatabase.fetchApplicationStatusData();
    _positionsAppliedFuture = FirestoreDatabase.fetchPositionsAppliedData();
    _barDataFuture = FirestoreDatabase.fetchBarData();
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  LegendItem(color: Color(0xFFFF6FCF), label: 'Applied'),
                  LegendItem(color: Color(0xFFD691FF), label: 'Interviews'),
                  LegendItem(color: Color(0xFFFFA500), label: 'Rejected'),
                  LegendItem(color: Color(0xFFFFFF99), label: 'Accepted'),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  LegendItem(color: Color(0xFF42A5F5), label: 'Software Developer'),
                  LegendItem(color: Color(0xFFCE93D8), label: 'AI/ML Engineer'),
                  LegendItem(color: Color(0xFFFFB74D), label: 'Data Science'),
                  LegendItem(color: Color(0xFF9CCC65), label: 'Data Engineer'),
                  LegendItem(color: Color(0xFFBDBDBD), label: 'Other'),
                ],
              ),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  LegendItem(color: Color(0xFF42A5F5), label: 'Software Developer'),
                  LegendItem(color: Color(0xFFCE93D8), label: 'AI/ML Engineer'),
                  LegendItem(color: Color(0xFFFFB74D), label: 'Data Science'),
                  LegendItem(color: Color(0xFF9CCC65), label: 'Data Engineer'),
                  LegendItem(color: Color(0xFFBDBDBD), label: 'Other'),
                ],
              ),
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
                            reservedSize: 50,
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final style = const TextStyle(fontSize: 11);
                              switch (value.toInt()) {
                                case 0:
                                  return Text('Software\nEng', style: style);
                                case 1:
                                  return Text('AI/ML\nEng', style: style);
                                case 2:
                                  return Text('Data\nScience', style: style);
                                case 3:
                                  return Text('Data\nEng', style: style);
                                case 4:
                                  return Text('Other', style: style);
                              }
                              return const SizedBox.shrink();
                            },
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

class FirestoreDatabase {
  static Future<List<PieChartSectionData>> fetchApplicationStatusData() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('email', isEqualTo: userEmail)
        .get();

    final statusCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final status = doc['status'] ?? 'Other';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    if (statusCounts.isEmpty) return [];
    
    final total = statusCounts.values.fold(0, (sum, val) => sum + val);
    final colorMap = {
      'Applied': Color(0xFFFF6FCF),
      'Interviews': Color(0xFFD691FF),
      'Rejected': Color(0xFFFFA500),
      'Accepted': Color(0xFFFFFF99),
    };

    return statusCounts.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colorMap[entry.key] ?? Colors.grey,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  static Future<List<PieChartSectionData>> fetchPositionsAppliedData() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('email', isEqualTo: userEmail)
        .get();

    final positionCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final position = doc['position'] ?? 'Other';
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }

    if (positionCounts.isEmpty) return [];
    
    final total = positionCounts.values.fold(0, (sum, val) => sum + val);
    final colorMap = {
      'Software Developer': Color(0xFF42A5F5),
      'AI/ML Engineer': Color(0xFFCE93D8),
      'Data Science': Color(0xFFFFB74D),
      'Data Engineer': Color(0xFF9CCC65),
    };

    return positionCounts.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: percentage,
        color: colorMap[entry.key] ?? Color(0xFFBDBDBD),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  static Future<List<BarChartGroupData>> fetchBarData() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('email', isEqualTo: userEmail)
        .get();

    // If no jobs with salaries are found, return an empty list
    if (snapshot.docs.isEmpty) return [];
    
    final salarySums = <String, double>{};
    final count = <String, int>{};

    for (var doc in snapshot.docs) {
      final position = doc['position'] ?? 'Other';
      final rawSalary = doc['salary'];
      if (rawSalary == null || rawSalary is! num) continue;

      final salary = rawSalary.toDouble();
      salarySums[position] = (salarySums[position] ?? 0) + salary;
      count[position] = (count[position] ?? 0) + 1;
    }

    // If no jobs with salaries are found, return an empty list
    if (salarySums.isEmpty) return [];
    
    final colorMap = {
      'Software Developer': Color(0xFF42A5F5),
      'AI/ML Engineer': Color(0xFFCE93D8),
      'Data Science': Color(0xFFFFB74D),
      'Data Engineer': Color(0xFF9CCC65),
    };

    final positionList = ['Software Developer', 'AI/ML Engineer', 'Data Science', 'Data Engineer', 'Other'];

    return List.generate(positionList.length, (index) {
      final position = positionList[index];
      final totalSalary = salarySums[position] ?? 0;
      final totalCount = count[position] ?? 0;
      final avg = totalCount > 0 ? totalSalary / totalCount : 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: avg / 1000,
            color: colorMap[position] ?? Color(0xFFBDBDBD),
          )
        ],
      );
    });
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}