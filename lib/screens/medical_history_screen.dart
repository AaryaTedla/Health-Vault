import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});
  @override State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedMetric = 'Blood Sugar';

  final List<String> _metrics = [
    'Blood Sugar', 'Blood Pressure', 'Weight', 'HbA1c'
  ];

  // Mock chart data
  final Map<String, List<FlSpot>> _chartData = {
    'Blood Sugar': [
      FlSpot(0, 142), FlSpot(1, 138), FlSpot(2, 155), FlSpot(3, 148),
      FlSpot(4, 162), FlSpot(5, 145), FlSpot(6, 139),
    ],
    'Blood Pressure': [
      FlSpot(0, 138), FlSpot(1, 135), FlSpot(2, 142), FlSpot(3, 130),
      FlSpot(4, 145), FlSpot(5, 133), FlSpot(6, 128),
    ],
    'Weight': [
      FlSpot(0, 78.5), FlSpot(1, 78.2), FlSpot(2, 77.8), FlSpot(3, 77.5),
      FlSpot(4, 77.0), FlSpot(5, 76.8), FlSpot(6, 76.5),
    ],
    'HbA1c': [
      FlSpot(0, 7.8), FlSpot(1, 7.6), FlSpot(2, 7.4), FlSpot(3, 7.5),
      FlSpot(4, 7.2), FlSpot(5, 7.3), FlSpot(6, 7.1),
    ],
  };

  final Map<String, Map<String, dynamic>> _metricInfo = {
    'Blood Sugar': {'unit': 'mg/dL', 'normal': '70–140', 'current': '139', 'trend': 'down', 'color': 0xFF3498DB},
    'Blood Pressure': {'unit': 'mmHg', 'normal': '<130/80', 'current': '128/82', 'trend': 'down', 'color': 0xFFE74C3C},
    'Weight': {'unit': 'kg', 'normal': '65–75', 'current': '76.5', 'trend': 'down', 'color': 0xFF2ECC71},
    'HbA1c': {'unit': '%', 'normal': '<5.7', 'current': '7.1', 'trend': 'down', 'color': 0xFFF39C12},
  };

  final List<Map<String, dynamic>> _timeline = [
    {'date': '12 Jan 2025', 'event': 'Blood Sugar Test', 'hospital': 'Apollo Hospital', 'result': 'HbA1c: 7.2% (slightly high)', 'type': 'lab', 'icon': Icons.science_rounded, 'color': 0xFF3498DB},
    {'date': '5 Jan 2025', 'event': 'Cardiology Checkup', 'hospital': 'Fortis Hospital', 'result': 'ECG normal, BP controlled', 'type': 'visit', 'icon': Icons.monitor_heart_rounded, 'color': 0xFFE74C3C},
    {'date': '28 Dec 2024', 'event': 'Prescription Updated', 'hospital': 'Dr. Sharma Clinic', 'result': 'Amlodipine dosage adjusted', 'type': 'prescription', 'icon': Icons.receipt_long_rounded, 'color': 0xFF2ECC71},
    {'date': '15 Dec 2024', 'event': 'Chest X-Ray', 'hospital': 'Manipal Hospital', 'result': 'No abnormalities detected', 'type': 'scan', 'icon': Icons.coronavirus_rounded, 'color': 0xFF9B59B6},
    {'date': '2 Dec 2024', 'event': 'Routine Blood Work', 'hospital': 'Narayana Health', 'result': 'Cholesterol slightly elevated', 'type': 'lab', 'icon': Icons.science_rounded, 'color': 0xFFF39C12},
    {'date': '10 Nov 2024', 'event': 'Hospital Discharge', 'hospital': 'Manipal Hospital', 'result': 'BP management — 3 day stay', 'type': 'discharge', 'icon': Icons.local_hospital_rounded, 'color': 0xFF1ABC9C},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Medical History',
              subtitle: 'AI-powered health insights',
              height: 120,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting health report...'))),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textHint,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'AI Insights'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildDashboard(),
            _buildTimeline(),
            _buildAIInsights(user?.conditions ?? []),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: Dashboard ────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final info = _metricInfo[_selectedMetric]!;
    final color = Color(info['color'] as int);
    final spots = _chartData[_selectedMetric]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Metric selector ──────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _metrics.length,
              itemBuilder: (_, i) {
                final m = _metrics[i];
                final mColor = Color(_metricInfo[m]!['color'] as int);
                final sel = m == _selectedMetric;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMetric = m),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? mColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? mColor : AppTheme.divider)),
                      child: Text(m, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppTheme.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // ─── Current value card ───────────────────────────────────────
          HealthCard(
            child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedMetric, style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: info['current'], style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                      TextSpan(text: '  ${info['unit']}', style: const TextStyle(
                        fontSize: 16, color: AppTheme.textSecondary,
                        fontFamily: 'Poppins')),
                    ])),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(
                        info['trend'] == 'down' ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: info['trend'] == 'down' ? AppTheme.secondary : AppTheme.danger,
                        size: 18),
                      const SizedBox(width: 4),
                      Text(
                        info['trend'] == 'down' ? 'Improving' : 'Worsening',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: info['trend'] == 'down' ? AppTheme.secondary : AppTheme.danger)),
                    ]),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('Normal: ${info['normal']}', style: TextStyle(
                        fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Last 7 readings', style: TextStyle(
                      fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          // ─── Line chart ───────────────────────────────────────────────
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-Day Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: (spots.map((s) => s.y).reduce((a, b) => b - a > 0 ? b - a : a - b)) / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.divider, strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40,
                          getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)))),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return Text(days[v.toInt() % 7],
                              style: const TextStyle(fontSize: 11, color: AppTheme.textHint));
                          })),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 4, color: color,
                              strokeWidth: 2, strokeColor: Colors.white)),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.08)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          // ─── Stats row ────────────────────────────────────────────────
          Builder(builder: (context) {
  final appState = context.watch<AppState>();
  final docCount = appState.documents.length;
  final medCount = appState.medicines.length;
  final hospitals = appState.documents
    .map((d) => d.hospitalName).toSet().length;
  return Row(children: [
    Expanded(child: _MiniStatCard('Documents',
      '$docCount', Icons.folder_rounded, AppTheme.primary)),
    const SizedBox(width: 12),
    Expanded(child: _MiniStatCard('Medicines',
      '$medCount', Icons.medication_rounded, AppTheme.secondary)),
    const SizedBox(width: 12),
    Expanded(child: _MiniStatCard('Hospitals',
      '$hospitals', Icons.local_hospital_rounded, AppTheme.accent)),
  ]).animate().fadeIn(delay: 250.ms);
}),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── TAB 2: Timeline ────────────────────────────────────────────────────
  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      itemCount: _timeline.length,
      itemBuilder: (_, i) {
        final item = _timeline[i];
        final color = Color(item['color'] as int);
        final isLast = i == _timeline.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(item['icon'] as IconData, color: color, size: 22)),
              if (!isLast)
                Container(width: 2, height: 60, color: AppTheme.divider),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: HealthCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(item['event'], style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(item['type'].toString().toUpperCase(), style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(item['hospital'], style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text(item['result'], style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(item['date'], style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                    ]),
                  ]),
                ).animate().fadeIn(delay: Duration(milliseconds: 80 * i)).slideX(begin: 0.05),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── TAB 3: AI Insights ──────────────────────────────────────────────────
  Widget _buildAIInsights(List<String> conditions) {
    final insights = [
      {
        'title': 'Blood Sugar Trend',
        'insight': 'Your blood sugar has improved by 8% over the last month. Continue with your current diet and exercise routine.',
        'icon': Icons.trending_down_rounded,
        'color': AppTheme.secondary,
        'type': 'positive',
      },
      {
        'title': 'Blood Pressure',
        'insight': 'Your blood pressure readings are within acceptable range. Your Amlodipine appears to be working well.',
        'icon': Icons.favorite_rounded,
        'color': AppTheme.secondary,
        'type': 'positive',
      },
      {
        'title': 'HbA1c Still High',
        'insight': 'Your HbA1c at 7.1% is above the ideal target of below 6.5%. Discuss with your doctor about adjusting your diabetes medicine.',
        'icon': Icons.warning_rounded,
        'color': AppTheme.warning,
        'type': 'warning',
      },
      {
        'title': 'Cholesterol Elevated',
        'insight': 'Your last blood work showed cholesterol at 210 mg/dL. Reduce fried foods and increase fish and nuts in your diet.',
        'icon': Icons.restaurant_rounded,
        'color': AppTheme.warning,
        'type': 'warning',
      },
      {
        'title': 'Medicine Adherence',
        'insight': 'You took 89% of your medicines on time this month. Try setting louder alarms for your 2:00 PM Aspirin.',
        'icon': Icons.medication_rounded,
        'color': AppTheme.primary,
        'type': 'info',
      },
    ];

    final mealTips = conditions.contains('Type 2 Diabetes')
        ? ['Choose brown rice over white rice', 'Eat small meals every 3 hours', 'Avoid fruit juices — eat whole fruits', 'Include methi (fenugreek) in your diet']
        : ['Eat plenty of vegetables and fruits', 'Stay hydrated — 8 glasses of water daily', 'Reduce salt and processed foods', 'Include protein in every meal'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Health Analysis', style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Based on your uploaded documents', style: TextStyle(
                  color: Colors.white70, fontSize: 13)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text('Updated today', style: TextStyle(color: Colors.white, fontSize: 11))),
            ]),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),
          const Text('Health Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Insights list
          ...insights.asMap().entries.map((e) {
            final i = e.key;
            final ins = e.value;
            final color = ins['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(ins['icon'] as IconData, color: color, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ins['title'] as String, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(ins['insight'] as String, style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                  ])),
                ]),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 60)).slideY(begin: 0.05),
            );
          }),

          const SizedBox(height: 20),
          const Text('AI Meal Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Based on: ${conditions.isEmpty ? "General health" : conditions.join(", ")}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),

          HealthCard(
            child: Column(
              children: mealTips.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(
                      ['🥗', '💧', '🍎', '🫘'][e.key % 4],
                      style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, height: 1.4))),
                ]),
              )).toList(),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 16),
          const DisclaimerBox(text: AppConstants.medicalDisclaimer),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }
}
