import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/task.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Ses efekti için değişken
  bool _isSoundEnabled = true;
  
  // Zamanlayıcı türü için değişken 
  String _timerType = 'standart'; // 'standart', 'görev odaklı', 'yarım saatlik'

  @override
  Widget build(BuildContext context) {
    final focusModel = Provider.of<FocusModel>(context);
    final List<Task> uncompletedTasks = focusModel.tasks.where((task) => !task.isCompleted).toList();
    
    // Calculate progress
    final double focusProgress = focusModel.focusDuration > 0
        ? (focusModel.focusDuration - focusModel.remainingFocusTime) / focusModel.focusDuration
        : 0.0;
    final double breakProgress = focusModel.breakDuration > 0
        ? (focusModel.breakDuration - focusModel.remainingBreakTime) / focusModel.breakDuration
        : 0.0;
    
    // Get the current theme's colors
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.surface;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define colors for focus and break
    final focusStatusColor = isDarkMode ? primaryColor : primaryColor;
    final breakStatusColor = isDarkMode ? Colors.teal : Colors.teal;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: focusModel.isBreakRunning ? breakStatusColor : focusStatusColor,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    focusModel.isBreakRunning 
                                        ? Icons.coffee 
                                        : Icons.psychology,
                                    color: focusModel.isBreakRunning 
                                        ? breakStatusColor 
                                        : focusStatusColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    focusModel.isBreakRunning ? 'Mola Zamanı' : 'Odaklanma Zamanı',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: focusModel.isBreakRunning 
                                          ? breakStatusColor 
                                          : focusStatusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toplam Oturum: ${focusModel.completedSessionCount}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          // Show current task if selected
                          if (focusModel.currentTaskIdForSession != null)
                            Flexible(
                              child: Chip(
                                label: Text(
                                  focusModel.tasks
                                      .firstWhere(
                                        (t) => t.id == focusModel.currentTaskIdForSession,
                                        orElse: () => Task(
                                          id: '',
                                          title: 'Görev',
                                          createdAt: DateTime.now(),
                                        ),
                                      )
                                      .title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                backgroundColor: focusModel.isBreakRunning 
                                    ? breakStatusColor.withAlpha(25) // withOpacity(0.1) -> withAlpha(25)
                                    : focusStatusColor.withAlpha(25), // withOpacity(0.1) -> withAlpha(25)
                                side: BorderSide(
                                  color: focusModel.isBreakRunning 
                                      ? breakStatusColor.withAlpha(76) // withOpacity(0.3) -> withAlpha(76)
                                      : focusStatusColor.withAlpha(76), // withOpacity(0.3) -> withAlpha(76)
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Timer Type Selector - New
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimerTypeOption(
                            type: 'standart',
                            label: 'Standart',
                            icon: Icons.timer,
                          ),
                          _buildTimerTypeOption(
                            type: 'görev odaklı',
                            label: 'Görevler',
                            icon: Icons.task_alt,
                          ),
                          _buildTimerTypeOption(
                            type: 'yarım saatlik',
                            label: '30 Dakika',
                            icon: Icons.timelapse,  // timer_30 yerine timelapse kullanılıyor
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Timer Circle
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Circle
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode 
                                ? colorScheme.surfaceContainerHighest 
                                : colorScheme.surfaceContainerHighest.withAlpha(76), // withOpacity(0.3) -> withAlpha(76)
                          ),
                        ),
                        
                        // Progress Indicator
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: focusModel.isBreakRunning ? breakProgress : focusProgress,
                            strokeWidth: 12,
                            backgroundColor: isDarkMode
                                ? Colors.grey.withAlpha(51) // withOpacity(0.2) -> withAlpha(51)
                                : Colors.grey.withAlpha(25), // withOpacity(0.1) -> withAlpha(25)
                            valueColor: AlwaysStoppedAnimation<Color>(
                              focusModel.isBreakRunning ? breakStatusColor : focusStatusColor,
                            ),
                          ),
                        ),
                        
                        // Timer Text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              focusModel.isBreakRunning
                                  ? focusModel.displayBreakTime
                                  : focusModel.displayFocusTime,
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w300,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              focusModel.isBreakRunning
                                  ? '${focusModel.breakDuration ~/ 60} dakikalık mola'
                                  : '${focusModel.focusDuration ~/ 60} dakikalık oturum',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sound Toggle - New
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, size: 18),
                      const SizedBox(width: 8),
                      const Text('Bildirim Sesi'),
                      Switch(
                        value: _isSoundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isSoundEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Control Buttons
                  focusModel.isBreakRunning
                      ? _buildBreakControls(focusModel, breakStatusColor)
                      : _buildFocusControls(focusModel, focusStatusColor),
                  
                  const SizedBox(height: 24),
                  
                  // Session Counter - Improved
                  _buildSessionCounter(focusModel),
                  
                  const SizedBox(height: 16),
                  
                  // Task selector (only when not in a session)
                  if (!focusModel.isFocusRunning && !focusModel.isBreakRunning && uncompletedTasks.isNotEmpty && _timerType == 'görev odaklı')
                    _buildTaskSelector(context, focusModel, uncompletedTasks),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFocusControls(FocusModel focusModel, Color focusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!focusModel.isFocusRunning)
          _buildControlButton(
            label: 'Başlat',
            icon: Icons.play_arrow_rounded,
            onPressed: focusModel.startFocusTimer,
            color: focusColor,
          ),
        
        if (focusModel.isFocusRunning) ...[
          _buildControlButton(
            label: 'Duraklat',
            icon: Icons.pause_rounded,
            onPressed: () => focusModel.stopFocusTimer(),
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          _buildControlButton(
            label: 'Sıfırla',
            icon: Icons.replay_rounded,
            onPressed: focusModel.resetFocusTimer,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }
  
  Widget _buildBreakControls(FocusModel focusModel, Color breakColor) {
    return _buildControlButton(
      label: 'Molayı Atla',
      icon: Icons.skip_next_rounded,
      onPressed: focusModel.skipBreak,
      color: breakColor,
    );
  }
  
  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return FadeTransition(
      opacity: _animationController,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }
  
  Widget _buildTaskSelector(BuildContext context, FocusModel focusModel, List<Task> tasks) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), // withOpacity(0.5) -> withAlpha(128)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Çalışacağınız Görevi Seçin',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              value: focusModel.currentTaskIdForSession,
              hint: const Text('Görev seçin'),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Genel Çalışma'),
                ),
                ...tasks.map((Task task) {
                  return DropdownMenuItem<String>(
                    value: task.id,
                    child: Text(task.title, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (String? taskId) {
                focusModel.setCurrentTaskIdForSession(taskId);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionCounter(FocusModel focusModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      color: isDarkMode 
          ? Colors.grey.withAlpha(25)
          : Colors.grey.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Bugün: ${focusModel.getSessionsToday()} oturum',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(width: 8),
            Text(
              'Toplam: ${focusModel.completedSessionCount}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimerTypeOption({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = _timerType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _timerType = type;
          
          // Zamanlayıcı türü değiştiğinde yapılacak işlemler
          if (type == 'yarım saatlik') {
            final focusModel = Provider.of<FocusModel>(context, listen: false);
            focusModel.setFocusDuration(30); // 30 dakika
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
