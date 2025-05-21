import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusModel = Provider.of<FocusModel>(context);
    final sessions = focusModel.completedSessions;

    // Group sessions by date for statistics
    final Map<String, int> sessionsByDate = {};
    for (final session in sessions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(session);
      sessionsByDate[dateStr] = (sessionsByDate[dateStr] ?? 0) + 1;
    }

    // Sort dates for the chart
    final sortedDates = sessionsByDate.keys.toList()..sort();
    final last7Days = sortedDates.length > 7
        ? sortedDates.sublist(sortedDates.length - 7)
        : sortedDates;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade50,
            Colors.indigo.shade50,
          ],
        ),
      ),
      child: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz tamamlanmış odaklanma seansı yok.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to timer screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Scaffold(
                              body: Center(child: Text('Timer'))),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer),
                    label: const Text('Zamanlayıcıya Git'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Odaklanma İstatistikleri',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  context: context,
                                  title: 'Toplam Seans',
                                  value: sessions.length.toString(),
                                  icon: Icons.check_circle,
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  context: context,
                                  title: 'Bu Ay',
                                  value: sessions
                                      .where((s) =>
                                          s.month == DateTime.now().month &&
                                          s.year == DateTime.now().year)
                                      .length
                                      .toString(),
                                  icon: Icons.calendar_month,
                                  color: Colors.green,
                                ),
                                _buildStatCard(
                                  context: context,
                                  title: 'Bugün',
                                  value: sessions
                                      .where((s) =>
                                          DateFormat('yyyy-MM-dd')
                                                  .format(s) ==
                                          DateFormat('yyyy-MM-dd')
                                              .format(DateTime.now()))
                                      .length
                                      .toString(),
                                  icon: Icons.today,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Son 7 günlük aktivite',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: last7Days.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Henüz veri yok',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: last7Days.map((date) {
                                        final count = sessionsByDate[date] ?? 0;
                                        final maxSessions = sessionsByDate.values
                                            .reduce(
                                                (max, value) => max > value
                                                    ? max
                                                    : value);
                                        final height = maxSessions > 0
                                            ? 130 * (count / maxSessions)
                                            : 0.0;

                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  count.toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(context)
                                                            .primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: height,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.bottomCenter,
                                                      end: Alignment.topCenter,
                                                      colors: [
                                                        Theme.of(context)
                                                            .primaryColor,
                                                        Theme.of(context)
                                                                .primaryColor
                                                            .withAlpha(153),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  DateFormat('dd/MM')
                                                      .format(DateTime.parse(
                                                          date)),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Tüm Seanslar',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Display in reverse chronological order
                        final sessionTime = sessions[sessions.length - 1 - index];
                        final dateStr = DateFormat('yyyy-MM-dd').format(sessionTime);
                        final timeStr = DateFormat('HH:mm').format(sessionTime);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              'Odaklanma Seansı: ${focusModel.focusDuration ~/ 60} dakika',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Tarih: $dateStr | Saat: $timeStr',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.timer,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                      childCount: sessions.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
