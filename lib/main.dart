import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert'; // For JSON encoding/decoding of session data
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'screens/home_screen.dart';
import 'models/task.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';
import 'screens/premium_screen.dart'; // Add this import

// Initialize flutter_local_notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// A simple model for managing the focus timer state
class FocusModel extends ChangeNotifier {
  static const String _prefKeyRemainingTime = 'remainingTime';
  static const String _prefKeyCustomFocusDuration = 'customFocusDuration';
  static const String _prefKeyCustomBreakDuration = 'customBreakDuration';
  static const String _prefKeyCompletedSessions = 'completedSessions';
  static const String _prefKeyTasks = 'tasks'; // For storing tasks
  static const String _prefKeyFocusSound = 'focusSound';
  static const String _prefKeyBreakSound = 'breakSound';
  static const String _prefKeyCurrentTaskId = 'currentTaskId';
  
  // New properties for premium features and additional metrics
  static const String _prefKeyIsPremium = 'isPremium';
  static const String _prefKeyWeeklyGoal = 'weeklyFocusGoal';
  static const String _prefKeyDailyGoal = 'dailyFocusGoal';
  static const String _prefKeyTotalFocusTime = 'totalFocusTime';
  static const String _prefKeyStreak = 'currentStreak';
  static const String _prefKeyLastFocusDate = 'lastFocusDate';

  // Eklenen yeni özellikler için tanımlar
  static const String _prefKeyPomodoroCount = 'pomodoroCount';
  static const String _prefKeyTaskCategories = 'taskCategories';
  static const String _prefKeyNotifications = 'notificationsEnabled';
  
  // Yeni değişken tanımları
  int _completedPomodoroCount = 0;
  List<String> _taskCategories = ['İş', 'Kişisel', 'Eğitim', 'Diğer']; // Varsayılan kategoriler
  bool _notificationsEnabled = true;
  
  static const int _defaultFocusDuration = 25 * 60;
  static const int _defaultBreakDuration = 5 * 60;
  static const String _defaultSound = 'sounds/default_alarm.mp3'; // Ensure this file exists

  int _focusDuration = _defaultFocusDuration;
  int _remainingFocusTime = _defaultFocusDuration;
  bool _isFocusRunning = false;
  Timer? _focusTimer;

  int _breakDuration = _defaultBreakDuration;
  int _remainingBreakTime = _defaultBreakDuration;
  bool _isBreakRunning = false;
  Timer? _breakTimer;

  List<DateTime> _completedSessions = [];
  List<Task> _tasks = []; // List to store tasks
  String? _currentTaskIdForSession; // ID of the task for the current/next focus session

  String _selectedFocusSound = _defaultSound;
  String _selectedBreakSound = _defaultSound;

  bool _isPremium = false;
  int _weeklyFocusGoal = 10; // Default: 10 sessions per week
  int _dailyFocusGoal = 4; // Default: 4 sessions per day
  int _totalFocusMinutes = 0; // Total minutes spent focusing
  int _currentStreak = 0; // Current streak of days with focus sessions
  DateTime? _lastFocusDate;

  SharedPreferences? _prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Analizler ve istatistikler için yeni değişkenler
  static const String _prefKeyLongestStreak = 'longestStreak';
  static const String _prefKeyMostProductiveDay = 'mostProductiveDay';
  static const String _prefKeyMostProductiveHour = 'mostProductiveHour';
  static const String _prefKeyCompletedTasks = 'completedTasks';
  
  int _longestStreak = 0;
  String _mostProductiveDay = 'Pazartesi'; // Varsayılan değer
  int _mostProductiveHour = 9; // Varsayılan değer (sabah 9)
  int _completedTasks = 0;

  int get remainingFocusTime => _remainingFocusTime;
  bool get isFocusRunning => _isFocusRunning;
  int get focusDuration => _focusDuration;

  int get remainingBreakTime => _remainingBreakTime;
  bool get isBreakRunning => _isBreakRunning;
  int get breakDuration => _breakDuration;

  List<DateTime> get completedSessions => _completedSessions;
  int get completedSessionCount => _completedSessions.length;

  List<Task> get tasks => _tasks;
  String? get currentTaskIdForSession => _currentTaskIdForSession;

  String get selectedFocusSound => _selectedFocusSound;
  String get selectedBreakSound => _selectedBreakSound;

  // Available sounds (ensure these files exist in assets/sounds/)
  // This list should ideally be dynamic or more robustly managed
  final List<String> availableSounds = [
    'sounds/default_alarm.mp3',
    'sounds/calm_chime.mp3',
    'sounds/short_break.mp3',
  ];

  bool get isPremium => _isPremium;
  int get weeklyFocusGoal => _weeklyFocusGoal;
  int get dailyFocusGoal => _dailyFocusGoal;
  int get totalFocusMinutes => _totalFocusMinutes;
  int get currentStreak => _currentStreak;
  
  // Yeni değişkenler için getter metotları
  int get completedPomodoroCount => _completedPomodoroCount;
  List<String> get taskCategories => _taskCategories;
  bool get notificationsEnabled => _notificationsEnabled;

  // Getter metotları
  int get longestStreak => _longestStreak;
  String get mostProductiveDay => _mostProductiveDay;
  int get mostProductiveHour => _mostProductiveHour;
  int get completedTasks => _completedTasks;

  // Method to calculate productivity score (0-100%)
  int getProductivityScore() {
    if (_completedSessions.isEmpty) return 0;

    // Calculate sessions in the last 7 days
    final DateTime now = DateTime.now();
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    final int sessionsThisWeek = _completedSessions
        .where((dt) => dt.isAfter(weekAgo))
        .length;

    // Calculate productivity score based on weekly goal
    final double weeklyProgress = _weeklyFocusGoal > 0
        ? (sessionsThisWeek / _weeklyFocusGoal)
        : 0;

    // Limit to 100% and convert to int percentage
    return (weeklyProgress * 100).clamp(0, 100).toInt();
  }

  // Get sessions today
  int getSessionsToday() {
    final String today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    return _completedSessions
        .where((dt) => dt.toString().startsWith(today))
        .length;
  }

  // Get daily goal completion percentage
  int getDailyGoalCompletion() {
    final int todaySessions = getSessionsToday();
    return _dailyFocusGoal > 0
        ? ((todaySessions / _dailyFocusGoal) * 100).clamp(0, 100).toInt()
        : 0;
  }

  // Calculate focus time distribution by hour of day (for charts)
  Map<int, int> getFocusTimeDistribution() {
    final Map<int, int> hourDistribution = {};

    // Initialize all hours to 0
    for (int i = 0; i < 24; i++) {
      hourDistribution[i] = 0;
    }

    // Count sessions by hour
    for (final session in _completedSessions) {
      final int hour = session.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    return hourDistribution;
  }

  String get displayFocusTime {
    int minutes = _remainingFocusTime ~/ 60;
    int seconds = _remainingFocusTime % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String get displayBreakTime {
    int minutes = _remainingBreakTime ~/ 60;
    int seconds = _remainingBreakTime % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  FocusModel() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _focusDuration = _prefs?.getInt(_prefKeyCustomFocusDuration) ?? _defaultFocusDuration;
    _remainingFocusTime = _prefs?.getInt(_prefKeyRemainingTime) ?? _focusDuration;
    if (_remainingFocusTime > _focusDuration || (_remainingFocusTime <= 0 && _focusDuration > 0)) {
        _remainingFocusTime = _focusDuration;
    }

    _breakDuration = _prefs?.getInt(_prefKeyCustomBreakDuration) ?? _defaultBreakDuration;
    _remainingBreakTime = _breakDuration;

    final String? sessionsJson = _prefs?.getString(_prefKeyCompletedSessions);
    if (sessionsJson != null) {
      try {
        final List<dynamic> decodedSessions = jsonDecode(sessionsJson);
        _completedSessions = decodedSessions.map((s) => DateTime.parse(s)).toList();
      } catch (e) {
        _completedSessions = [];
      }
    }

    final String? tasksJson = _prefs?.getString(_prefKeyTasks);
    if (tasksJson != null) {
      try {
        final List<dynamic> decodedTasks = jsonDecode(tasksJson);
        _tasks = decodedTasks.map((taskMap) => Task.fromJson(taskMap as Map<String, dynamic>)).toList();
      } catch (e) {
        _tasks = [];
      }
    }
    _selectedFocusSound = _prefs?.getString(_prefKeyFocusSound) ?? _defaultSound;
    _selectedBreakSound = _prefs?.getString(_prefKeyBreakSound) ?? _defaultSound;
    _currentTaskIdForSession = _prefs?.getString(_prefKeyCurrentTaskId);

    _isPremium = _prefs?.getBool(_prefKeyIsPremium) ?? false;
    _weeklyFocusGoal = _prefs?.getInt(_prefKeyWeeklyGoal) ?? 10;
    _dailyFocusGoal = _prefs?.getInt(_prefKeyDailyGoal) ?? 4;
    _totalFocusMinutes = _prefs?.getInt(_prefKeyTotalFocusTime) ?? 0;
    _currentStreak = _prefs?.getInt(_prefKeyStreak) ?? 0;

    final String? lastFocusDateStr = _prefs?.getString(_prefKeyLastFocusDate);
    if (lastFocusDateStr != null) {
      _lastFocusDate = DateTime.parse(lastFocusDateStr);
    }

    // Yeni tercihleri yükle
    _completedPomodoroCount = _prefs?.getInt(_prefKeyPomodoroCount) ?? 0;
    
    final String? categoriesJson = _prefs?.getString(_prefKeyTaskCategories);
    if (categoriesJson != null) {
      try {
        final List<dynamic> decodedCategories = jsonDecode(categoriesJson);
        _taskCategories = decodedCategories.cast<String>();
      } catch (e) {
        _taskCategories = ['İş', 'Kişisel', 'Eğitim', 'Diğer']; // Varsayılan kategoriler
      }
    }
    
    _notificationsEnabled = _prefs?.getBool(_prefKeyNotifications) ?? true;

    _longestStreak = _prefs?.getInt(_prefKeyLongestStreak) ?? 0;
    _mostProductiveDay = _prefs?.getString(_prefKeyMostProductiveDay) ?? 'Pazartesi';
    _mostProductiveHour = _prefs?.getInt(_prefKeyMostProductiveHour) ?? 9;
    _completedTasks = _prefs?.getInt(_prefKeyCompletedTasks) ?? 0;

    // İlk yükleme için en verimli gün ve saati hesapla
    if (_completedSessions.isNotEmpty) {
      _calculateProductivityMetrics();
    }

    // Update streak if necessary
    _updateStreak();

    notifyListeners();
  }

  Future<void> _saveRemainingFocusTime() async {
    await _prefs?.setInt(_prefKeyRemainingTime, _remainingFocusTime);
  }

  Future<void> _saveCustomFocusDuration() async {
    await _prefs?.setInt(_prefKeyCustomFocusDuration, _focusDuration);
  }

  Future<void> _saveCustomBreakDuration() async {
    await _prefs?.setInt(_prefKeyCustomBreakDuration, _breakDuration);
  }

  Future<void> _saveCompletedSessions() async {
    final List<String> sessionsJson = _completedSessions.map((dt) => dt.toIso8601String()).toList();
    await _prefs?.setString(_prefKeyCompletedSessions, jsonEncode(sessionsJson));
  }

  Future<void> _saveTasks() async {
    final List<Map<String, dynamic>> tasksJson = _tasks.map((task) => task.toJson()).toList();
    await _prefs?.setString(_prefKeyTasks, jsonEncode(tasksJson));
  }

  Future<void> _saveSoundPreferences() async {
    await _prefs?.setString(_prefKeyFocusSound, _selectedFocusSound);
    await _prefs?.setString(_prefKeyBreakSound, _selectedBreakSound);
  }

  Future<void> _saveCurrentTaskId() async {
    if (_currentTaskIdForSession != null) {
      await _prefs?.setString(_prefKeyCurrentTaskId, _currentTaskIdForSession!);
    } else {
      await _prefs?.remove(_prefKeyCurrentTaskId);
    }
  }

  Future<void> _savePremiumStatus() async {
    await _prefs?.setBool(_prefKeyIsPremium, _isPremium);
  }

  Future<void> _saveWeeklyFocusGoal() async {
    await _prefs?.setInt(_prefKeyWeeklyGoal, _weeklyFocusGoal);
  }

  Future<void> _saveDailyFocusGoal() async {
    await _prefs?.setInt(_prefKeyDailyGoal, _dailyFocusGoal);
  }

  Future<void> _saveTotalFocusTime() async {
    await _prefs?.setInt(_prefKeyTotalFocusTime, _totalFocusMinutes);
  }

  Future<void> _saveStreak() async {
    await _prefs?.setInt(_prefKeyStreak, _currentStreak);
    if (_lastFocusDate != null) {
      await _prefs?.setString(_prefKeyLastFocusDate, _lastFocusDate!.toIso8601String());
    }
  }

  // Pomodoroları kaydet
  Future<void> _savePomodoroCount() async {
    await _prefs?.setInt(_prefKeyPomodoroCount, _completedPomodoroCount);
  }
  
  // Kategorileri kaydet
  Future<void> _saveCategories() async {
    await _prefs?.setString(_prefKeyTaskCategories, jsonEncode(_taskCategories));
  }
  
  // Bildirim ayarlarını kaydet
  Future<void> _saveNotificationSettings() async {
    await _prefs?.setBool(_prefKeyNotifications, _notificationsEnabled);
  }
  
  Future<void> _saveCompletedTasksCount() async {
    await _prefs?.setInt(_prefKeyCompletedTasks, _completedTasks);
  }

  Future<void> _saveLongestStreak() async {
    await _prefs?.setInt(_prefKeyLongestStreak, _longestStreak);
  }

  Future<void> _saveMostProductiveData() async {
    await _prefs?.setString(_prefKeyMostProductiveDay, _mostProductiveDay);
    await _prefs?.setInt(_prefKeyMostProductiveHour, _mostProductiveHour);
  }

  void setFocusDuration(int minutes) {
    if (minutes > 0) {
      _focusDuration = minutes * 60;
      if (!_isFocusRunning) {
        _remainingFocusTime = _focusDuration;
        _saveRemainingFocusTime(); 
      }
      _saveCustomFocusDuration();
      notifyListeners();
    }
  }

  void setBreakDuration(int minutes) {
    if (minutes > 0) {
      _breakDuration = minutes * 60;
      if (!_isBreakRunning) {
        _remainingBreakTime = _breakDuration;
      }
      _saveCustomBreakDuration();
      notifyListeners();
    }
  }

  void setSelectedFocusSound(String soundPath) {
    _selectedFocusSound = soundPath;
    _saveSoundPreferences();
    notifyListeners();
  }

  void setSelectedBreakSound(String soundPath) {
    _selectedBreakSound = soundPath;
    _saveSoundPreferences();
    notifyListeners();
  }

  void setCurrentTaskIdForSession(String? taskId) {
    _currentTaskIdForSession = taskId;
    _saveCurrentTaskId();
    notifyListeners();
  }

  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    _savePremiumStatus();
    notifyListeners();
  }
  
  void setWeeklyFocusGoal(int sessions) {
    if (sessions > 0) {
      _weeklyFocusGoal = sessions;
      _saveWeeklyFocusGoal();
      notifyListeners();
    }
  }
  
  void setDailyFocusGoal(int sessions) {
    if (sessions > 0) {
      _dailyFocusGoal = sessions;
      _saveDailyFocusGoal();
      notifyListeners();
    }
  }

  // Yeni kategori eklemek için metot
  void addCategory(String category) {
    if (!_taskCategories.contains(category) && category.trim().isNotEmpty) {
      _taskCategories.add(category);
      _saveCategories();
      notifyListeners();
    }
  }
  
  // Kategori silmek için metot
  void deleteCategory(String category) {
    if (_taskCategories.contains(category) && _taskCategories.length > 1) {
      _taskCategories.remove(category);
      _saveCategories();
      notifyListeners();
    }
  }
  
  // Bildirim durumunu değiştir
  void toggleNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    _saveNotificationSettings();
    notifyListeners();
  }
  
  // Pomodoro sayacını artır
  void incrementPomodoroCount() {
    _completedPomodoroCount++;
    _savePomodoroCount();
    notifyListeners();
  }

  void startFocusTimer() {
    if (_isFocusRunning || _isBreakRunning) return;
    _isFocusRunning = true;
    if (_remainingFocusTime <= 0 || _remainingFocusTime > _focusDuration) {
        _remainingFocusTime = _focusDuration;
    }
    _saveRemainingFocusTime(); // Save state before starting timer
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingFocusTime > 0) {
        _remainingFocusTime--;
        // _saveRemainingFocusTime(); // Optionally save every tick, or less frequently
      } else {
        _recordCompletedFocusSession(); // Task ID is now part of session data if selected
        _showNotification("Focus Session Ended", "Time to take a break!");
        _playSound(_selectedFocusSound); // Use selected sound
        stopFocusTimer(reset: false); 
        startBreakTimer();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopFocusTimer({bool reset = false}) {
    _focusTimer?.cancel();
    _isFocusRunning = false;
    if (reset) {
      _remainingFocusTime = _focusDuration;
    }
    _saveRemainingFocusTime(); // Save current state when stopped/reset
    notifyListeners();
  }

  void resetFocusTimer() {
    stopFocusTimer(reset: true);
  }

  void startBreakTimer() {
    if (_isBreakRunning || _isFocusRunning) return;
    _isBreakRunning = true;
    _remainingBreakTime = _breakDuration;
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingBreakTime > 0) {
        _remainingBreakTime--;
      } else {
        _showNotification("Break Over", "Time to get back to focus!");
        _playSound(_selectedBreakSound); // Use selected sound
        stopBreakTimer(reset: true); 
        _remainingFocusTime = _focusDuration; 
        _saveRemainingFocusTime();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopBreakTimer({bool reset = false}) {
    _breakTimer?.cancel();
    _isBreakRunning = false;
    if (reset) {
      _remainingBreakTime = _breakDuration;
    }
    notifyListeners();
  }

  void resetBreakTimer() {
    stopBreakTimer(reset: true);
  }

  void skipBreak() {
    stopBreakTimer(reset: true);
    _remainingFocusTime = _focusDuration; // Reset focus time for next session
    _saveRemainingFocusTime();
    notifyListeners();
  }

  void _calculateProductivityMetrics() {
    // Streak güncelleme
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
      _saveLongestStreak();
    }

    // En verimli günü hesaplama
    Map<String, int> sessionsByDay = {};
    List<String> dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    
    for (DateTime session in _completedSessions) {
      // 1 = Pazartesi, 7 = Pazar
      int weekday = session.weekday;
      String dayName = dayNames[weekday - 1];
      sessionsByDay[dayName] = (sessionsByDay[dayName] ?? 0) + 1;
    }

    if (sessionsByDay.isNotEmpty) {
      // En çok oturum olan günü bul
      _mostProductiveDay = sessionsByDay.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // En verimli saati hesaplama
    Map<int, int> sessionsByHour = {};
    
    for (DateTime session in _completedSessions) {
      int hour = session.hour;
      sessionsByHour[hour] = (sessionsByHour[hour] ?? 0) + 1;
    }

    if (sessionsByHour.isNotEmpty) {
      _mostProductiveHour = sessionsByHour.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    _saveMostProductiveData();
  }

  void _updateStreak() {
    final DateTime today = DateTime.now();
    final DateTime startOfToday = DateTime(today.year, today.month, today.day);

    if (_lastFocusDate == null) {
      if (_completedSessions.isNotEmpty) {
        _lastFocusDate = startOfToday;
        _currentStreak = 1;
        _saveStreak();
      }
      return;
    }

    final DateTime startOfLastFocus = DateTime(
        _lastFocusDate!.year, _lastFocusDate!.month, _lastFocusDate!.day);

    // Check if any sessions today
    bool hadSessionToday = _completedSessions.any((dt) => 
      dt.year == today.year && dt.month == today.month && dt.day == today.day);
    
    if (hadSessionToday) {
      // If last recorded focus was yesterday, increment streak
      if (startOfToday.difference(startOfLastFocus).inDays == 1) {
        _currentStreak++;
        _lastFocusDate = startOfToday;
        _saveStreak();
      }
      // If last focus was before yesterday (skipped days), reset streak
      else if (startOfToday.difference(startOfLastFocus).inDays > 1) {
        _currentStreak = 1;
        _lastFocusDate = startOfToday;
        _saveStreak();
      }
    }
    // Check if streak should be reset (no sessions today and last focus wasn't yesterday)
    else if (startOfToday.difference(startOfLastFocus).inDays > 1) {
      _currentStreak = 0;
      _saveStreak();
    }
  }

  Future<void> _recordCompletedFocusSession() async {
    final DateTime now = DateTime.now();
    _completedSessions.add(now);
    await _saveCompletedSessions();

    // Update total focus minutes
    _totalFocusMinutes += _focusDuration ~/ 60;
    await _saveTotalFocusTime();
    
    // Bir pomodoro tamamlandı
    incrementPomodoroCount();

    // Update streak data
    _updateStreak();

    // Verimlilik metriklerini güncelle
    _calculateProductivityMetrics();

    // Görevle ilişkilendirme
    if (_currentTaskIdForSession != null) {
      int taskIndex = _tasks.indexWhere((t) => t.id == _currentTaskIdForSession);
      if (taskIndex != -1) {
        _tasks[taskIndex].incrementPomodoro();
        
        // Tahmini pomodoro sayısına ulaşıldığında otomatik tamamlama önerisi
        if (_tasks[taskIndex].pomodoroCount >= _tasks[taskIndex].estimatedPomodoros && 
            !_tasks[taskIndex].isCompleted) {
          // Bildirim göster
          _showNotification(
            "Görev Tamamlandı Gibi Görünüyor", 
            "${_tasks[taskIndex].title} için tahmini pomodoro sayısına ulaştınız."
          );
        }
        
        _saveTasks();
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    if (!_notificationsEnabled) return; // Bildirimler kapalıysa gösterme

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('focus_channel_id', 'Focus Timer',
            channelDescription: 'Notifications for focus timer completion',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID for each notification
        title,
        body,
        platformChannelSpecifics,
        payload: 'timer_ended');
  }

  Future<void> _playSound(String soundAsset) async {
    if (soundAsset.isEmpty) return; // Don't play if no sound is selected
    try {
      // Ensure the path is relative to the assets folder defined in pubspec.yaml
      // e.g., if pubspec has 'assets/sounds/', and file is 'timer_complete.mp3'
      // then AssetSource path should be 'sounds/timer_complete.mp3'
      await _audioPlayer.play(AssetSource(soundAsset));
    } catch (e) {
      // Silently handle errors since we don't have a logging framework yet
      // In production, this should be replaced with proper error handling
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _breakTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Task Management Methods - Bunlar eksikti, ekliyoruz
  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
  }

  void editTask(Task updatedTask) {
    int index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    if (_currentTaskIdForSession == taskId) {
      _currentTaskIdForSession = null; // Clear if the active task is deleted
      _saveCurrentTaskId();
    }
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    int index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _saveTasks();
      notifyListeners();
    }
  }

  // Tasklara ilişkin yeni metodlar
  void completeTask(String taskId) {
    int index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1 && !_tasks[index].isCompleted) {
      _tasks[index].isCompleted = true;
      _completedTasks++;
      _saveTasks();
      _saveCompletedTasksCount();
      notifyListeners();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.dotenv.load(fileName: '.env');

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // Initialize flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
          onDidReceiveLocalNotification: (id, title, body, payload) async {
    // Handle notification tapped logic here for older iOS versions
  });
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: ${notificationResponse.payload}');
    }
  });

  // Önyükleme (splash) ekranı için zaman ekle
  await Future.delayed(const Duration(milliseconds: 1500));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FocusModel()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Focus Zone',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
      routes: {
        '/premium': (context) => const PremiumScreen(),
      },
    );
  }
}
