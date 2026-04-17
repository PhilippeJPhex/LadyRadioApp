import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/favorites_service.dart';
import '../screens/favorites_screen.dart';

/// Header da usare nella HomeScreen: logo Lady Radio + saluto contestuale.
class LadyRadioHeader extends StatelessWidget {
  const LadyRadioHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Buongiorno 🌅';
    if (hour >= 12 && hour < 18) return 'Buon pomeriggio ☀️';
    return 'Buonasera 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), // Ridotto da 16, 16, 16, 8
      child: Row(
        children: [
          // Logo Lady Radio
          Container(
            width: 50,
            height: 50,
            child: Image.asset(
              'assets/lady512.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Lady Radio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          // Icona Area Personale (preferiti)
          ListenableBuilder(
            listenable: FavoritesService(),
            builder: (context, _) {
              final hasItems = FavoritesService().count > 0;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                        size: 26,
                      ),
                      if (hasItems)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

