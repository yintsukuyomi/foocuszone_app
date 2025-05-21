import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? colorScheme.surface 
          : colorScheme.surface,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: isDarkMode 
            ? colorScheme.surface 
            : colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FocusZone Premium',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sınırsız özellikler ile odaklanmanızı artırın',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Features section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Özellikleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Feature items
                  _buildFeatureItem(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Detaylı İstatistikler',
                    description: 'Verimlilik analizleri ve ilerleme grafikleri',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    icon: Icons.cloud_sync,
                    title: 'Bulut Senkronizasyonu',
                    description: 'Tüm cihazlarınızda verilerinize erişin',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    icon: Icons.music_note,
                    title: 'Özel Sesler',
                    description: 'Odaklanma ve mola için ek sesler ve müzik',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    icon: Icons.palette,
                    title: 'Özel Temalar',
                    description: 'Ekstra tema seçenekleri ve özelleştirmeler',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    icon: Icons.backup_table,
                    title: 'Kapsamlı Veri Yedekleme',
                    description: 'Tüm verilerinizi güvenle yedekleyin',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    icon: Icons.smart_toy,
                    title: 'Gelişmiş AI Asistan',
                    description: 'Daha güçlü ve kişiselleştirilmiş AI yanıtları',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Price section
                  Center(
                    child: Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              '49,99 ₺ / yıl',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'sadece ayda 4,17 ₺',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimaryContainer.withAlpha(204),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _purchasePremium(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'HEMEN SATIN AL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // In a real app, you'd add terms of service links here
                            Text(
                              '7 gün ücretsiz deneme',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimaryContainer.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _purchasePremium(BuildContext context) {
    // In a real app, this would integrate with in-app purchases
    // For this demo, we'll just update the premium status directly
    
    // Show a dialog to simulate purchase
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Premium Satın Al'),
          content: const Text(
            'Bu bir örnek uygulamadır. Gerçek bir ödeme işlemi gerçekleşmeyecektir. '
            'Premium özellikleri simüle etmek için devam edin.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final focusModel = Provider.of<FocusModel>(context, listen: false);
                focusModel.setPremiumStatus(true);
                
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium özellikleri başarıyla aktifleştirildi!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Satın Al'),
            ),
          ],
        );
      },
    );
  }
}
