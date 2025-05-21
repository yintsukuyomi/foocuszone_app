import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'timer_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'statistics_screen.dart';
import 'chat_screen.dart'; // Import the new ChatScreen
import 'premium_screen.dart';
import 'splash_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  static const List<Widget> _widgetOptions = <Widget>[
    TimerScreen(),
    TasksScreen(),
    StatisticsScreen(),
    ChatScreen(), // Add the ChatScreen
    SettingsScreen(),
  ];

  static const List<String> _appBarTitles = <String>[
    'Zamanlayıcı',
    'Görevler',
    'İstatistikler',
    'AI Asistan', // Add title for ChatScreen
    'Ayarlar',
  ];

  @override
  void initState() {
    super.initState();
    // Uygulamayı ilk açtığımızda SplashScreen'i gösteriyoruz
    _initialize();
  }

  Future<void> _initialize() async {
    // 2 saniyelik bir gecikmeden sonra ana ekrana geçiyoruz
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  void _openPremiumScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash Screen gösterimi
    if (!_isInitialized) {
      return const SplashScreen();
    }
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final focusModel = Provider.of<FocusModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        leading: _selectedIndex == 0 && focusModel.completedSessionCount > 0
          ? Badge(
              label: Text(focusModel.completedSessionCount.toString()),
              backgroundColor: colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2; // İstatistikler ekranına git
                  });
                },
              ),
            )
          : null,
        actions: [
          if (!focusModel.isPremium)
            IconButton(
              icon: const Icon(Icons.workspace_premium),
              tooltip: 'Premium\'a Yükselt',
              onPressed: _openPremiumScreen,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'FocuZone',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2025 FocuZone',
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Verimli çalışma için tasarlanmış pomodoro zamanlayıcısı.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: Theme.of(context).navigationBarTheme.backgroundColor,
        elevation: 0,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Zamanlayıcı',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Görevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Asistan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
