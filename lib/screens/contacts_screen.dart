import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 130, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              'Contattaci',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Siamo sempre disponibili per ascoltarti.\nContattaci per la diretta, segnalazioni o pubblicità.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            
            _buildActionCard(
              context,
              icon: Icons.chat_outlined,
              title: '+39 ${AppConstants.whatsappNumber.replaceFirst('39', '')}',
              subtitle: 'WhatsApp alla diretta e segnalazioni',
              onTap: () => _launchUrl('https://wa.me/${AppConstants.whatsappNumber}'),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              icon: Icons.email_outlined,
              title: AppConstants.email,
              subtitle: 'Scrivi una email alla redazione',
              onTap: () => _launchUrl('mailto:${AppConstants.email}'),
            ),
            const SizedBox(height: 32),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Promuovi la tua attività',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: AppConstants.phoneNumber,
              subtitle: 'Per promuovere la tua attività',
              onTap: () => _launchUrl('tel:${AppConstants.phoneNumber}'),
            ),
            const SizedBox(height: 24),
            // Social media row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook_rounded, size: 32),
                  color: AppTheme.primaryColor,
                  onPressed: () => _launchUrl(AppConstants.facebookUrl),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Image.asset('assets/instagram-brand.png', width: 32, height: 32, color: AppTheme.primaryColor),
                  onPressed: () => _launchUrl(AppConstants.instagramUrl),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.language, size: 32),
                  color: AppTheme.primaryColor,
                  onPressed: () => _launchUrl(AppConstants.website),
                ),
              ],
            ),
            
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

  Widget _buildActionCard(BuildContext context, {IconData? icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (icon != null)
              Positioned(
                right: -20,
                top: -20,
                child: Icon(icon, size: 100, color: Colors.white.withValues(alpha: 0.1)),
              ),
            Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
