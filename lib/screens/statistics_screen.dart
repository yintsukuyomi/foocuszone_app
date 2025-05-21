import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'dart:math';
import '../models/task.dart'; // Task modelini import ediyoruz

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // İhtiyaç duyulan değişkenleri tanımlayalım
  int productivityScore = 0;
  int dailyGoalCompletion = 0;
  int sessionsToday = 0;
  int sessionsCount = 0;
  double totalHours = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateStats(); // initState'de istatistikleri güncelle
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStats(); // Provider değiştiğinde istatistikleri güncelle
  }
  
  void _updateStats() {
    // Provider'dan verileri al ve hesapla
    final focusModel = Provider.of<FocusModel>(context, listen: false);
    
    // İstatistikleri güncelle
    setState(() {
      productivityScore = focusModel.getProductivityScore();
      dailyGoalCompletion = focusModel.getDailyGoalCompletion();
      sessionsToday = focusModel.getSessionsToday();
      sessionsCount = focusModel.completedSessionCount;
      totalHours = focusModel.totalFocusMinutes / 60.0;
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final focusModel = Provider.of<FocusModel>(context);
    
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: "Genel Bakış"),
            Tab(text: "Haftalık"),
            Tab(text: "Ayrıntılı"),  // "Geçmiş" yerine "Ayrıntılı" yaptık
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, focusModel),
              _buildWeeklyTab(context, focusModel),
              _buildDetailedTab(context, focusModel),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverviewTab(BuildContext context, FocusModel focusModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Kategori dağılımını al
    final categoryDistribution = _getCategoryDistribution(focusModel);
    
    // En verimli kategorileri bul
    String mostProductiveCategory = 'Bilinmiyor';
    int maxPomodoroCount = 0;
    
    categoryDistribution.forEach((category, count) {
      if (count > maxPomodoroCount) {
        maxPomodoroCount = count;
        mostProductiveCategory = category;
      }
    });
    
    // İstatistik raporu oluştur
    final report = {
      'totalSessions': focusModel.completedSessionCount,
      'totalFocusMinutes': focusModel.totalFocusMinutes,
      'completedTasks': focusModel.completedTasks, 
      'currentStreak': focusModel.currentStreak,
      'longestStreak': focusModel.longestStreak,
      'totalPomodoros': focusModel.completedPomodoroCount,
      'weeklyGoalProgress': productivityScore,
      'dailyGoalProgress': dailyGoalCompletion,
      'mostProductiveDay': focusModel.mostProductiveDay,
      'mostProductiveHour': focusModel.mostProductiveHour,
    };
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verimlilik Kartı (Mevcut)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Verimlilik Skoru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: productivityScore / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.withAlpha(50),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getScoreColor(productivityScore),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$productivityScore%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(productivityScore),
                              ),
                            ),
                            Text(
                              _getScoreLabel(productivityScore),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hedef: Haftada ${focusModel.weeklyFocusGoal} oturum',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Yeni İstatistik Kartı: En Verimli Zamanlar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En Verimli Olduğunuz Zamanlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // En verimli gün
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(51),
                        child: Icon(Icons.calendar_today, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'En Verimli Gün',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              report['mostProductiveDay'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // En verimli saat
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.secondary.withAlpha(51),
                        child: Icon(Icons.access_time, color: colorScheme.secondary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'En Verimli Saat',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${report['mostProductiveHour']}:00',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // En verimli kategori
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.tertiary.withAlpha(51),
                        child: Icon(Icons.category, color: colorScheme.tertiary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'En Çok Çalıştığınız Kategori',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              mostProductiveCategory,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // İstatistik Kartları (Mevcut)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Günlük Hedef',
                  value: '$dailyGoalCompletion%',
                  subtitle: '$sessionsToday/${focusModel.dailyFocusGoal} oturum',
                  icon: Icons.today,
                  progressValue: dailyGoalCompletion / 100,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Seri',
                  value: '${focusModel.currentStreak}',
                  subtitle: 'gün',
                  icon: Icons.local_fire_department,
                  progressValue: null,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Toplam Oturum',
                  value: '$sessionsCount',
                  subtitle: 'tamamlandı',
                  icon: Icons.check_circle_outline,
                  progressValue: null,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Toplam Süre',
                  value: totalHours.toStringAsFixed(1),
                  subtitle: 'saat',
                  icon: Icons.access_time,
                  progressValue: null,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Hour Distribution Chart
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'En Verimli Saatleriniz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _buildHourDistributionChart(context, focusModel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyTab(BuildContext context, FocusModel focusModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Gerçek haftalık verileri FocusModel'den al
    final Map<String, int> weeklyData = _getWeeklySessionCounts(focusModel.completedSessions);
    
    // En yoğun günü bul
    String mostBusyDay = 'Yok';
    int maxSessions = 0;
    
    weeklyData.forEach((day, count) {
      if (count > maxSessions) {
        maxSessions = count;
        mostBusyDay = day;
      }
    });
    
    // Get the max value for scaling
    final int maxValue = weeklyData.values.isEmpty ? 1 : weeklyData.values.reduce(max);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu Haftaki Performans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weeklyData.entries.map((entry) {
                        final double barHeight = maxValue > 0 
                            ? 160 * (entry.value / maxValue) 
                            : 0;
                        
                        return Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min, // Add this to keep column height minimal
                            children: [
                              Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 30,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.key.substring(0, 3), // First 3 letters of day name
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis, // Add overflow handling
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Bu Hafta',
                  value: '${weeklyData.values.fold(0, (a, b) => a + b)}',
                  subtitle: 'oturum',
                  icon: Icons.calendar_today,
                  progressValue: null,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'En Yoğun Gün',
                  value: maxSessions > 0 ? mostBusyDay : '-',
                  subtitle: maxSessions > 0 ? '$maxSessions oturum' : 'Veri yok',
                  icon: Icons.star,
                  progressValue: null,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedTab(BuildContext context, FocusModel focusModel) {
    // Yeniden tasarlanan Ayrıntılı Rapor ekranı
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // İstatistik verileri
    // Kategori dağılımını al
    final categoryDistribution = _getCategoryDistribution(focusModel);
    
    // Rapor oluştur
    final report = {
      'totalSessions': focusModel.completedSessionCount,
      'totalFocusMinutes': focusModel.totalFocusMinutes,
      'completedTasks': focusModel.completedTasks, 
      'currentStreak': focusModel.currentStreak,
      'longestStreak': focusModel.longestStreak,
      'totalPomodoros': focusModel.completedPomodoroCount,
      'weeklyGoalProgress': productivityScore,
      'dailyGoalProgress': dailyGoalCompletion,
      'mostProductiveDay': focusModel.mostProductiveDay,
      'mostProductiveHour': focusModel.mostProductiveHour,
    };
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori Bazlı Dağılım
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori Dağılımı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pasta Grafik (burada basitleştirilmiş bir liste gösterimi)
                  ...categoryDistribution.entries.map((entry) {
                    final totalPomodoros = categoryDistribution.values.fold(0, (a, b) => a + b);
                    final percentage = totalPomodoros > 0 
                        ? ((entry.value / totalPomodoros) * 100).toStringAsFixed(1) 
                        : '0.0';
                        
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color: _getCategoryColor(entry.key, colorScheme),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.key),
                          ),
                          Text(
                            '$percentage% (${entry.value} pomodoro)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // İlerleme Özeti
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlerleme Özeti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailItem(context, 'Toplam Oturum', '${report['totalSessions']}', Icons.check_circle),
                  _buildDetailItem(context, 'Toplam Odaklanma', '${report['totalFocusMinutes']} dakika', Icons.timer),
                  _buildDetailItem(context, 'Toplam Pomodoro', '${report['totalPomodoros']}', Icons.av_timer),
                  _buildDetailItem(context, 'Tamamlanan Görevler', '${report['completedTasks']}', Icons.task_alt),
                  _buildDetailItem(context, 'Mevcut Seri', '${report['currentStreak']} gün', Icons.local_fire_department),
                  _buildDetailItem(context, 'En Uzun Seri', '${report['longestStreak']} gün', Icons.emoji_events),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Geçmiş Oturumlar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Geçmiş Oturumlar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Son ${focusModel.completedSessions.length > 5 ? 5 : focusModel.completedSessions.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Son 5 oturumu göster
                  ..._getRecentSessions(focusModel.completedSessions).map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${DateFormat('dd MMM').format(session)} · ${DateFormat('HH:mm').format(session)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${focusModel.focusDuration ~/ 60} dk',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  if (focusModel.completedSessions.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Tüm oturumları gösteren bir ekran açılabilir
                        },
                        child: const Text('Tümünü Görüntüle'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Kategori dağılımını hesaplayan yardımcı metot
  Map<String, int> _getCategoryDistribution(FocusModel model) {
    Map<String, int> distribution = {};
    
    for (Task task in model.tasks) {
      if (task.pomodoroCount > 0) {
        // pomodoroCount'u int'e çevir
        final int count = task.pomodoroCount;
        distribution[task.category] = (distribution[task.category] ?? 0) + count;
      }
    }
    
    return distribution;
  }
  
  // Son 7 günün verilerini haftalık olarak grupla
  Map<String, int> _getWeeklySessionCounts(List<DateTime> sessions) {
    final DateTime now = DateTime.now();
    final List<String> dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    Map<String, int> weeklyData = {};
    
    // Map'i günlere göre initialize et
    for (String day in dayNames) {
      weeklyData[day] = 0;
    }
    
    // Son 7 günü hesapla
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    
    // Sadece son 7 gündeki oturumları filtrele
    final List<DateTime> recentSessions = sessions.where((s) => s.isAfter(weekAgo)).toList();
    
    // Her oturumu haftanın gününe göre grupla
    for (DateTime session in recentSessions) {
      // weekday: 1 = Pazartesi, ..., 7 = Pazar
      String dayName = dayNames[session.weekday - 1];
      weeklyData[dayName] = (weeklyData[dayName] ?? 0) + 1;
    }
    
    return weeklyData;
  }
  
  List<DateTime> _getRecentSessions(List<DateTime> sessions) {
    if (sessions.isEmpty) return [];
    
    // Son 5 oturumu almak için kopyalayıp sıralayalım
    List<DateTime> recentSessions = List.from(sessions);
    recentSessions.sort((a, b) => b.compareTo(a)); // En yeni en üstte
    
    // En fazla 5 oturumu döndür
    return recentSessions.take(5).toList();
  }
  
  Color _getCategoryColor(String category, ColorScheme colorScheme) {
    // Her kategori için benzersiz bir renk döndür
    switch (category.toLowerCase()) {
      case 'iş':
        return Colors.blue;
      case 'kişisel':
        return Colors.green;
      case 'eğitim':
        return Colors.orange;
      case 'diğer':
        return Colors.purple;
      default:
        return colorScheme.primary;
    }
  }
  
  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progressValue,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHourDistributionChart(BuildContext context, FocusModel focusModel) {
    final hourDistribution = focusModel.getFocusTimeDistribution();
    
    // Get max value for scaling
    final int maxValue = hourDistribution.values.isEmpty 
        ? 1 
        : hourDistribution.values.reduce(max);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(24, (hour) {
        final int sessions = hourDistribution[hour] ?? 0;
        final double barHeight = maxValue > 0 
            ? 150 * (sessions / maxValue) 
            : 0;
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Add this line to minimize vertical space
            children: [
              Container(
                height: barHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getHourColor(hour, sessions),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (hour % 4 == 0)
                Text(
                  '$hour:00',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis, // Add overflow handling
                )
              else
                const SizedBox(height: 14),
            ],
          ),
        );
      }),
    );
  }
  
  Color _getHourColor(int hour, int sessions) {
    if (sessions == 0) {
      return Colors.grey.withAlpha(50);
    }
    
    // Alpha value calculation: opacity * 255, rounded to nearest int
    // Morning: 5-11
    if (hour >= 5 && hour < 12) {
      return Colors.amber.withAlpha(180 + (sessions * 12).clamp(0, 75).toInt());
    }
    // Afternoon: 12-17
    else if (hour >= 12 && hour < 18) {
      return Colors.orange.withAlpha(180 + (sessions * 12).clamp(0, 75).toInt());
    }
    // Evening: 18-23
    else if (hour >= 18) {
      return Theme.of(context).colorScheme.primary.withAlpha(180 + (sessions * 12).clamp(0, 75).toInt());
    }
    // Night: 0-4
    else {
      return Colors.indigo.withAlpha(180 + (sessions * 12).clamp(0, 75).toInt());
    }
  }
  
  String _getScoreLabel(int score) {
    if (score >= 90) return 'Mükemmel';
    if (score >= 75) return 'Çok İyi';
    if (score >= 60) return 'İyi';
    if (score >= 40) return 'Orta';
    return 'Geliştirilebilir';
  }
  
  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

