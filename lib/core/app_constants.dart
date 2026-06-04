/// Centralizzazione di tutte le costanti dell'app Lady Radio:
/// link, contatti, testi. Da qui si modificano una sola volta.
class AppConstants {
  // --- Contatti ---
  static const String whatsappNumber = '393925727775';
  static const String phoneNumber = '0555048248';
  static const String email = 'redazione@ladyradio.it';

  // --- Link esterni ---
  static const String website = 'https://www.ladyradio.it';
  static const String logoAsset = 'assets/lady512.png';
  static const String logoUrl =
      'https://www.ladyradio.it/wp-content/uploads/2024/05/Logo_Lady_Radio_Sito.png';

  // --- Banner fallback Home ---
  // Usato solo quando il plugin WordPress non restituisce banner attivi.
  // Può essere un asset locale, es. 'assets/banner-fallback.png',
  // oppure un URL remoto https://...
  // Lasciare vuoto per nascondere il banner quando non ci sono campagne.
  static const String fallbackBannerImage =
      'assets/banner-fallback-ladyradio.jpg';
  static const String fallbackBannerTargetUrl = website;

  // --- Stream (fallback locale, la config ufficiale viene da ConfigService) ---
  static const String fallbackStreamUrl =
      'https://stream4.xdevel.com/audio0s978435-2634/stream/icecast.audio';

  // --- Social ---
  static const String facebookUrl = 'https://www.facebook.com/ladyradio';
  static const String instagramUrl = 'https://www.instagram.com/ladyradio1';

  // --- Frequenze FM ---
  static const List<Map<String, String>> frequencies = [
    {'area': 'Firenze, Prato e Pistoia', 'freq': '102.1 FM'},
    {'area': 'Mugello', 'freq': '95.4 FM'},
    {'area': 'Valdisieve', 'freq': '95.6 FM'},
  ];

  // --- Testi UI ---
  static const String appTagline =
      "La tua radio nell'hinterland fiorentino.\nMusica, sport, cronaca e cultura.";
  static const String liveSubtitle = 'IN DIRETTA SU LADY RADIO';

  // --- WhatsApp helpers ---
  static Uri whatsappUri({String text = ''}) => Uri.parse(
    'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(text)}',
  );

  static Uri whatsappWebUri({String text = ''}) => Uri.parse(
    'https://api.whatsapp.com/send?phone=$whatsappNumber&text=${Uri.encodeComponent(text)}',
  );
}
