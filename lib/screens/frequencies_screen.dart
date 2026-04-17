import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';

class FrequenciesScreen extends StatelessWidget {
  const FrequenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  'assets/lady512.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scopri come ascoltarci!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Firenze e dintorni, 102.1 FM.\nSport, cronaca, musica e tanto altro su Lady Radio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            
            const SizedBox(height: 40),
            
            // Map
            Container(
              height: 250,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                'assets/MappaToscana-LADY.png',
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Frequenze dinamiche da AppConstants
            ...AppConstants.frequencies.map((f) => _buildFreqRow(f['area']!, f['freq']!)),
            
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                const text = '[SEGNALAZIONE]: ciao, vorrei segnalare un problema riguardante...';
                final url = AppConstants.whatsappUri(text: text);
                final webUrl = AppConstants.whatsappWebUri(text: text);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  await launchUrl(webUrl);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: const Text('Segnala un problema', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqRow(String area, String frequency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(area, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Text(frequency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
