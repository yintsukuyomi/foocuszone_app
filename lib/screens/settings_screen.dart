import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _focusDurationController;
  late TextEditingController _breakDurationController;
  late TextEditingController _newCategoryController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final focusModel = Provider.of<FocusModel>(context, listen: false);
    _focusDurationController =
        TextEditingController(text: (focusModel.focusDuration ~/ 60).toString());
    _breakDurationController =
        TextEditingController(text: (focusModel.breakDuration ~/ 60).toString());
    _newCategoryController = TextEditingController();
  }

  @override
  void dispose() {
    _focusDurationController.dispose();
    _breakDurationController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });
    
    final focusModel = Provider.of<FocusModel>(context, listen: false);
    final int? focusMinutes = int.tryParse(_focusDurationController.text);
    final int? breakMinutes = int.tryParse(_breakDurationController.text);

    if (focusMinutes != null && focusMinutes > 0) {
      focusModel.setFocusDuration(focusMinutes);
    }
    if (breakMinutes != null && breakMinutes > 0) {
      focusModel.setBreakDuration(breakMinutes);
    }

    // Simulate a delay to avoid the UI jarring
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Kategori Ekle'),
          content: TextField(
            controller: _newCategoryController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Kategori Adı',
              hintText: 'Örn: Çalışma, Egzersiz, Okuma...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final newCategory = _newCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  final focusModel = Provider.of<FocusModel>(context, listen: false);
                  focusModel.addCategory(newCategory);
                  _newCategoryController.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusModel = Provider.of<FocusModel>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Durations Section
            _buildSectionHeader('Zamanlayıcı Ayarları'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingField(
                      label: 'Odaklanma Süresi',
                      controller: _focusDurationController,
                      suffix: 'dk',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingField(
                      label: 'Mola Süresi',
                      controller: _breakDurationController,
                      suffix: 'dk',
                      icon: Icons.coffee_outlined,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sound Section
            _buildSectionHeader('Bildirim Sesleri'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSoundSelector(
                      label: 'Odaklanma tamamlandı sesi',
                      selectedValue: focusModel.selectedFocusSound,
                      availableSounds: focusModel.availableSounds,
                      onChanged: (value) {
                        if (value != null) {
                          focusModel.setSelectedFocusSound(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSoundSelector(
                      label: 'Mola tamamlandı sesi',
                      selectedValue: focusModel.selectedBreakSound,
                      availableSounds: focusModel.availableSounds,
                      onChanged: (value) {
                        if (value != null) {
                          focusModel.setSelectedBreakSound(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Theme Section
            _buildSectionHeader('Tema Ayarları'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Açık Tema'),
                    leading: const Icon(Icons.light_mode),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Koyu Tema'),
                    leading: const Icon(Icons.dark_mode),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Sistem Ayarlarını Kullan'),
                    subtitle: Text(
                      'Cihazınızın tema ayarlarına göre değişir',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    leading: const Icon(Icons.settings_system_daydream),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: themeProvider.themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Interface Section - Removing the old theme toggle
            _buildSectionHeader('Arayüz Ayarları'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Yuvarlak Köşeler'),
                    subtitle: Text(
                      'Arayüzde köşeleri yumuşat',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    value: true, // Örnek değer, gerçek uygulamada ayardan gelecektir
                    onChanged: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bu özellik henüz desteklenmiyor'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Animasyonları Göster'),
                    subtitle: Text(
                      'Geçiş animasyonlarını etkinleştir',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    value: true, // Örnek değer, gerçek uygulamada ayardan gelecektir
                    onChanged: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bu özellik henüz desteklenmiyor'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Notification Section (Yeni)
            _buildSectionHeader('Bildirimler'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Bildirimleri Etkinleştir'),
                    subtitle: const Text(
                      'Pomodoro tamamlandığında ve mola bittiğinde bildirim al',
                    ),
                    value: focusModel.notificationsEnabled,
                    onChanged: (value) {
                      focusModel.toggleNotifications(value);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Categories Section (Yeni)
            _buildSectionHeader('Görev Kategorileri'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kategoriler',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Ekle'),
                          onPressed: _showAddCategoryDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Kategori listesi
                    ...focusModel.taskCategories.map((category) => 
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: focusModel.taskCategories.length > 1
                            ? () => focusModel.deleteCategory(category)
                            : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistics Section (Yeni)
            _buildSectionHeader('İstatistikler'),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Toplam Pomodoro',
                      '${focusModel.completedPomodoroCount}',
                      Icons.timer,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Toplam Odaklanma',
                      '${focusModel.totalFocusMinutes} dk',
                      Icons.hourglass_bottom,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Seri',
                      '${focusModel.currentStreak} gün',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            Center(
              child: FilledButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Ayarları Kaydet'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App info
            Center(
              child: Column(
                children: [
                  Text(
                    'FocusZone',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versiyon 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildSettingField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Container(
          width: 70, // Genişliği arttırıldı
          height: 40, // Sabit yükseklik verildi
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(128), // withOpacity(0.5) -> withAlpha(128)
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Değer giriş alanı
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Yazı boyutu arttırıldı
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              // Birim etiketi
              Container(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSoundSelector({
    required String label,
    required String selectedValue,
    required List<String> availableSounds,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Icon(Icons.music_note_outlined, color: colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: availableSounds.contains(selectedValue) ? selectedValue : null,
                items: availableSounds.map((sound) {
                  // Extract filename and make it more user-friendly
                  final displayName = sound
                      .split('/')
                      .last
                      .replaceAll('.mp3', '')
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
                      .join(' ');
                  
                  return DropdownMenuItem<String>(
                    value: sound,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
