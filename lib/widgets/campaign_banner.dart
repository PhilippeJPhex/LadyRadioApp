import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/banner_service.dart';

class CampaignBanner extends StatefulWidget {
  const CampaignBanner({super.key});

  @override
  State<CampaignBanner> createState() => _CampaignBannerState();
}

class _CampaignBannerState extends State<CampaignBanner> {
  final BannerService _bannerService = BannerService();
  CampaignBannerModel? _activeBanner;
  bool _isLoading = true;
  bool _hasTrackedImpression = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final banner = await _bannerService.fetchActiveBanner();
    if (mounted) {
      setState(() {
        _activeBanner = banner;
        _isLoading = false;
      });
    }
  }

  void _onBannerTap() async {
    if (_activeBanner == null) return;

    // 1. Traccia il click sul database interno (mini-gestionale WP)
    await _bannerService.trackClick(_activeBanner!.id);

    // 2. Prepara l'URL con i tag di tracciamento (UTM) per il cliente
    String originalUrl = _activeBanner!.targetUrl;
    String taggedUrl = originalUrl;

    // Aggiungiamo i parametri UTM per far capire al cliente che il traffico viene dall'app
    const String utmTags =
        "utm_source=ladyradio_app&utm_medium=banner&utm_campaign=app_advertising";

    if (originalUrl.contains('?')) {
      taggedUrl = "$originalUrl&$utmTags";
    } else {
      taggedUrl = "$originalUrl?$utmTags";
    }

    // 3. Apri il link esterno sponsorizzato
    final url = Uri.parse(taggedUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Impossibile aprire il link: $taggedUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeBanner == null) {
      // Nessun banner attivo in questo periodo, nascondi lo spazio.
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _onBannerTap,
      child: Container(
        height: 120, // Altezza fissa per header piccolo non invadente
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent, // Sfondo di fallback
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: _activeBanner!.imageUrl,
            httpHeaders: const {'Referer': 'https://www.ladyradio.it/'},
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            imageBuilder: (context, imageProvider) {
              if (!_hasTrackedImpression) {
                _hasTrackedImpression = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _bannerService.trackImpression(_activeBanner!.id);
                });
              }
              return Image(image: imageProvider, fit: BoxFit.contain);
            },
            errorWidget: (_, _, _) => const Center(
              // In caso di errore nel caricamento dell'immagine sponsor (es. adblock/CORS), non mostrare nulla di rotto
              child: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
