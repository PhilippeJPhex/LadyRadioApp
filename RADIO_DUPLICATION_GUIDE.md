# Guida per duplicare l'app Lady Radio per un'altra radio

Questa guida spiega come prendere questa app e trasformarla velocemente nell'app di un'altra radio.

E' scritta per una persona non specializzata in informatica: segui i passaggi in ordine, senza saltare la checklist iniziale.

## 1. Obiettivo

Partiamo da questa app e cambiamo:

- nome della radio;
- logo;
- icona app;
- colori;
- streaming live;
- streaming TV;
- sito web;
- contatti;
- social;
- frequenze;
- palinsesto/trasmissioni;
- podcast;
- banner pubblicitari;
- Bundle ID iOS;
- package Android;
- configurazione CarPlay / Android Auto.

## 2. Prima di iniziare: prepara una scheda della nuova radio

Compila questa scheda prima di toccare il codice.

```text
Nome radio:
Esempio: Radio Toscana

Nome breve app:
Esempio: Radio Toscana

Dominio sito:
Esempio: https://www.radiotoscana.it

Email:
Esempio: redazione@radiotoscana.it

Telefono:
Esempio: 055123456

WhatsApp con prefisso internazionale:
Esempio: 393331234567

Facebook:
Esempio: https://www.facebook.com/radiotoscana

Instagram:
Esempio: https://www.instagram.com/radiotoscana

Stream audio live:
Esempio: https://stream.example.com/radio/icecast.audio

Stream video TV HLS:
Esempio: https://stream.example.com/video/playlist.m3u8

Frequenze FM:
Esempio:
- Firenze: 102.1 FM
- Mugello: 95.4 FM

Colore principale:
Esempio: #8B2287

Colore secondario:
Esempio: #4A1348

Colore accento:
Esempio: #F72C5B

Logo quadrato:
Esempio: logo-radio-512.png

Icona app 1024x1024:
Esempio: appicon-radio.png

Bundle ID iOS:
Esempio: it.radiotoscana.app

Application ID Android:
Esempio: it.radiotoscana.app
```

## 3. Crea una copia del progetto

Non lavorare direttamente sul progetto Lady Radio se devi creare un'altra app.

1. Duplica la cartella del progetto.
2. Rinomina la cartella.

Esempio:

```text
LadyRadioApp
RadioToscanaApp
```

3. Apri la nuova cartella in VS Code.

## 4. Cerca tutti i riferimenti Lady Radio

In VS Code:

1. Premi `Cmd + Shift + F`.
2. Cerca:

```text
Lady Radio
```

3. Cerca anche:

```text
LadyRadio
ladyradio
lady512
it.ladyradio
```

Ogni risultato va valutato. Non cambiare alla cieca: alcuni file sono documentazione, altri sono codice.

## 5. File principale per testi, contatti e link

Apri:

```text
lib/core/app_constants.dart
```

Qui cambi i dati generali della radio.

### Cosa cambiare

```dart
static const String whatsappNumber = '393925727775';
static const String phoneNumber = '0555048248';
static const String email = 'redazione@ladyradio.it';
```

Sostituisci con i dati della nuova radio.

Poi cambia:

```dart
static const String website = 'https://www.ladyradio.it';
static const String logoAsset = 'assets/lady512.png';
static const String logoUrl = '...';
```

Esempio:

```dart
static const String website = 'https://www.radiotoscana.it';
static const String logoAsset = 'assets/radio-toscana-512.png';
static const String logoUrl =
    'https://www.radiotoscana.it/wp-content/uploads/logo.png';
```

Poi cambia lo stream audio di fallback:

```dart
static const String fallbackStreamUrl = '...';
```

Poi social:

```dart
static const String facebookUrl = '...';
static const String instagramUrl = '...';
```

Poi frequenze:

```dart
static const List<Map<String, String>> frequencies = [
  {'area': 'Firenze, Prato e Pistoia', 'freq': '102.1 FM'},
  {'area': 'Mugello', 'freq': '95.4 FM'},
  {'area': 'Valdisieve', 'freq': '95.6 FM'},
];
```

Esempio:

```dart
static const List<Map<String, String>> frequencies = [
  {'area': 'Firenze', 'freq': '101.5 FM'},
  {'area': 'Prato', 'freq': '98.2 FM'},
];
```

Poi testi:

```dart
static const String appTagline = "...";
static const String liveSubtitle = 'IN DIRETTA SU LADY RADIO';
```

## 6. Colori dell'app

Apri:

```text
lib/core/app_theme.dart
```

Qui cambi i colori principali.

```dart
static const Color primaryColor = Color(0xFF8B2287);
static const Color secondaryColor = Color(0xFF4A1348);
static const Color accentColor = Color(0xFFF72C5B);
static const Color bgColor = Color(0xFFF9F5F9);
```

Come leggere un colore:

```text
#8B2287 diventa Color(0xFF8B2287)
```

Regola:

- prendi il colore esadecimale, esempio `#123456`;
- togli `#`;
- aggiungi `0xFF` davanti;
- diventa `Color(0xFF123456)`.

Esempio:

```dart
static const Color primaryColor = Color(0xFF0057A8);
static const Color secondaryColor = Color(0xFF003B73);
static const Color accentColor = Color(0xFFFFC400);
static const Color bgColor = Color(0xFFF4F8FC);
```

## 7. Colore fascia del mini player globale

Apri:

```text
lib/widgets/global_mini_player.dart
```

Cerca:

```dart
globalMiniPlayerBackgroundColor
```

Oggi e' impostato a:

```dart
const Color(0xFF6A1E68)
```

Cambialo con un colore coerente con la nuova radio.

## 8. Logo interno dell'app

Il logo principale usato nell'app oggi e':

```text
assets/lady512.png
```

Per cambiarlo:

1. Prepara un PNG quadrato, meglio `512x512`.
2. Mettilo nella cartella:

```text
assets/
```

Esempio:

```text
assets/radio-toscana-512.png
```

3. Apri:

```text
lib/core/app_constants.dart
```

4. Cambia:

```dart
static const String logoAsset = 'assets/lady512.png';
```

in:

```dart
static const String logoAsset = 'assets/radio-toscana-512.png';
```

## 9. Punti dove il logo e' ancora scritto manualmente

Alcuni punti possono usare direttamente:

```text
assets/lady512.png
```

Per trovarli:

1. In VS Code premi `Cmd + Shift + F`.
2. Cerca:

```text
assets/lady512.png
```

3. Sostituisci con il nuovo logo oppure, meglio, con:

```dart
AppConstants.logoAsset
```

File dove controllare con attenzione:

- `lib/widgets/lady_radio_header.dart`
- `lib/screens/live_screen.dart`
- `lib/screens/podcast_screen.dart`
- `lib/core/audio_handler.dart`
- `ios/Runner/CarPlaySceneDelegate.swift`

## 10. Icona dell'app

Il file sorgente dell'icona e' configurato in:

```text
pubspec.yaml
```

Cerca:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/appicon-ladyradio.png"
```

Per una nuova radio:

1. Prepara icona PNG `1024x1024`, senza trasparenza.
2. Mettila in:

```text
assets/
```

Esempio:

```text
assets/appicon-radio-toscana.png
```

3. Cambia:

```yaml
image_path: "assets/appicon-ladyradio.png"
```

in:

```yaml
image_path: "assets/appicon-radio-toscana.png"
```

4. Esegui:

```bash
dart run flutter_launcher_icons
```

Questo rigenera le icone Android e iOS.

## 11. Nome app visibile su iPhone

Apri:

```text
ios/Runner/Info.plist
```

Cerca:

```xml
<key>CFBundleDisplayName</key>
<string>Lady Radio</string>
```

Cambia `Lady Radio` con il nome della nuova radio.

Esempio:

```xml
<string>Radio Toscana</string>
```

## 12. Nome app visibile su Android

Apri:

```text
android/app/src/main/AndroidManifest.xml
```

Cerca:

```xml
android:label="Lady Radio"
```

Cambia con il nome della nuova radio.

## 13. Titolo Flutter dell'app

Apri:

```text
lib/main.dart
```

Cerca:

```dart
title: 'Lady Radio',
```

Cambia:

```dart
title: 'Radio Toscana',
```

Controlla anche il canale notifiche audio:

```dart
androidNotificationChannelName: 'Lady Radio Riproduzione',
```

## 14. Bundle ID iOS

Per pubblicare una nuova app iOS serve un Bundle ID diverso.

Esempio:

```text
it.ladyradio.app
```

diventa:

```text
it.radiotoscana.app
```

Si cambia in Xcode:

1. Apri:

```bash
open ios/Runner.xcworkspace
```

2. Seleziona progetto `Runner`.
3. Seleziona target `Runner`.
4. Vai su `Signing & Capabilities`.
5. Cambia `Bundle Identifier`.
6. Se usi CarPlay, crea anche nuovo App ID nel portale Apple Developer con capability CarPlay.

Controlla anche nel file:

```text
ios/Runner.xcodeproj/project.pbxproj
```

cercando:

```text
PRODUCT_BUNDLE_IDENTIFIER
```

## 15. Package Android

Apri:

```text
android/app/build.gradle.kts
```

Cambia:

```kotlin
namespace = "it.ladyradio.lady_app"
applicationId = "it.ladyradio.lady_app"
```

Esempio:

```kotlin
namespace = "it.radiotoscana.app"
applicationId = "it.radiotoscana.app"
```

Poi apri:

```text
android/app/src/main/kotlin/it/ladyradio/lady_app/MainActivity.kt
```

Il package dentro al file oggi e':

```kotlin
package it.ladyradio.lady_app
```

Per una nuova radio deve combaciare con il nuovo package.

Esempio:

```kotlin
package it.radiotoscana.app
```

Nota: idealmente va spostata anche la cartella Kotlin per riflettere il package. Se non sai farlo, chiedi supporto tecnico.

## 16. Config online streaming

Apri:

```text
lib/data/config_service.dart
```

Cerca:

```dart
https://www.ladyradio.it/stream_conf/config.json
```

Questo file JSON online contiene configurazioni come stream live, TV e contatti.

Per una nuova radio hai due opzioni.

### Opzione A: stessa struttura online

Crei sul sito della nuova radio:

```text
https://www.nuovaradio.it/stream_conf/config.json
```

Il file deve avere una struttura compatibile con:

```json
{
  "radio": {
    "url": "https://stream.example.com/audio"
  },
  "tv": {
    "url": "https://stream.example.com/video/playlist.m3u8"
  },
  "info": {
    "website": "https://www.nuovaradio.it",
    "whatsapp": "393331234567",
    "email": {
      "to": "redazione@nuovaradio.it"
    },
    "facebook": "https://www.facebook.com/nuovaradio",
    "instagram": "https://www.instagram.com/nuovaradio"
  }
}
```

### Opzione B: solo fallback locale

Se non vuoi usare `config.json`, cambia almeno i fallback dentro `ConfigService`.

## 17. Stream live audio

Lo stream live viene usato in piu' punti.

Controlla:

- `lib/core/app_constants.dart`
- `lib/data/config_service.dart`
- `lib/core/audio_handler.dart`
- `ios/Runner/CarPlaySceneDelegate.swift`

Il formato consigliato e':

```text
https://.../icecast.audio
```

Oppure un altro URL HTTP/HTTPS supportato da `just_audio`.

## 18. Stream TV

La TV interna usa:

```text
lib/screens/live_screen.dart
```

Cerca:

```dart
const String tvUrl =
```

Oggi punta a un HLS:

```text
playlist.m3u8
```

Per una nuova radio usa preferibilmente un flusso HLS:

```text
https://.../playlist.m3u8
```

Evita RTMP/RTSP se puoi: su iOS e Flutter sono piu' complicati.

## 19. Palinsesto e trasmissioni

Il palinsesto viene letto da WordPress:

```text
lib/data/schedule_service.dart
```

Endpoint atteso:

```text
https://www.sito-radio.it/wp-json/ladyapp/v1/schedule
```

Ogni trasmissione dovrebbe avere dati simili:

```json
{
  "id": "123",
  "postId": "123",
  "title": "Nome programma",
  "subtitle": "Descrizione programma",
  "startTime": "12:00",
  "endTime": "14:00",
  "day": "1",
  "imageUrl": "https://...",
  "rssFeed": "https://..."
}
```

Significato `day`:

```text
1 = Lunedi'
2 = Martedi'
3 = Mercoledi'
4 = Giovedi'
5 = Venerdi'
6 = Sabato
7 = Domenica
```

Se la nuova radio non ha WordPress o non ha questo endpoint, bisogna adattare `ScheduleService`.

## 20. Podcast

I podcast vengono letti dai feed RSS indicati nel palinsesto.

Controlla:

```text
lib/data/rss_service.dart
```

Ogni programma deve avere un campo:

```text
rssFeed
```

Esempio:

```text
https://www.nuovaradio.it/feed/podcast/nome-programma
```

Se un programma non ha feed RSS, la lista puntate sara' vuota.

## 21. Banner pubblicitari e statistiche

I banner vengono gestiti da:

```text
lib/data/banner_service.dart
lib/widgets/campaign_banner.dart
```

Endpoint attuale:

```text
https://www.ladyradio.it/wp-json/ladyapp/v1
```

Per una nuova radio va cambiato in:

```text
https://www.nuovaradio.it/wp-json/ladyapp/v1
```

Dentro `banner_service.dart` cambia:

```dart
static const String _baseUrl = '...';
static const String _siteOrigin = '...';
static const String _siteReferer = '...';
```

Controlla anche:

```dart
'X-Requested-With': 'it.ladyradio.app',
```

Deve diventare il package della nuova app.

In `campaign_banner.dart` controlla eventuali UTM:

```text
utm_source=ladyradio_app
```

## 22. CarPlay

La parte CarPlay iOS e':

```text
ios/Runner/CarPlaySceneDelegate.swift
```

Cerca e cambia:

```text
Lady Radio
ladyradio.it
assets/lady512.png
```

Punti importanti:

- titolo live;
- nome programma;
- artwork;
- URL config online;
- testi tab;
- messaggi preferiti.

Se la nuova radio deve avere CarPlay:

1. Crea nuovo App ID Apple.
2. Abilita capability `CarPlay Audio App`.
3. Crea provisioning profile corretto.
4. Verifica che `Runner.entitlements` contenga:

```xml
<key>com.apple.developer.carplay-audio</key>
<true/>
```

## 23. Android Auto

La parte Android Auto passa principalmente da:

```text
lib/core/audio_handler.dart
android/app/src/main/res/xml/automotive_app_desc.xml
```

In `audio_handler.dart` cerca:

```text
Lady Radio
it.ladyradio.lady_app
assets/lady512.png
```

Da cambiare:

- nome live;
- album/nome radio;
- package Android;
- logo;
- metadati lock screen;
- metadati Android Auto.

## 24. Testi vocali e permessi

Controlla:

```text
lib/core/voice_service.dart
```

Cambia:

```text
Lady Radio
393925727775
```

Controlla anche i testi privacy in:

```text
ios/Runner/Info.plist
macos/Runner/Info.plist
```

Esempio:

```xml
<string>Lady Radio usa il microfono...</string>
```

## 25. Splash screen

Controlla:

```text
lib/main.dart
ios/Runner/Assets.xcassets/LaunchImage.imageset/
android/app/src/main/res/drawable/launch_background.xml
```

Se lo splash mostra il vecchio logo, cambia le immagini dentro `LaunchImage.imageset` e gli asset Android.

## 26. Mappe e immagini locali

La schermata Frequenze usa:

```text
assets/MappaToscana-LADY.png
assets/MappaToscana-LADY.svg
```

Se la nuova radio ha un'altra zona:

1. prepara nuova mappa;
2. mettila in `assets/`;
3. apri `lib/screens/frequencies_screen.dart`;
4. cerca:

```text
MappaToscana-LADY
```

5. sostituisci con il nuovo file.

## 27. Cover locali dei programmi

La cartella:

```text
cover/
```

contiene immagini di programmi.

Se la nuova radio usa immagini da WordPress, potrebbero non servire.

Se vuoi fallback locali:

1. metti le immagini in `cover/`;
2. aggiorna eventuali riferimenti in `lib/data/mock_data.dart`;
3. controlla i programmi senza immagine online.

## 28. Dati finti / fallback

Apri:

```text
lib/data/mock_data.dart
```

Questo file contiene dati di esempio Lady Radio.

Per una nuova radio:

- cambiare nomi programmi;
- cambiare descrizioni;
- cambiare orari;
- cambiare immagini;
- cambiare feed podcast.

Anche se l'app usa WordPress, e' meglio aggiornare questi fallback.

## 29. Testi nelle schermate

Cerca in tutto il progetto:

```text
Lady Radio
```

File importanti:

- `lib/screens/live_screen.dart`
- `lib/screens/podcast_screen.dart`
- `lib/screens/program_screen.dart`
- `lib/screens/frequencies_screen.dart`
- `lib/screens/schedule_screen.dart`
- `lib/widgets/lady_radio_header.dart`
- `lib/widgets/global_mini_player.dart`
- `lib/main.dart`

Per ogni risultato chiediti:

```text
Questo testo lo vedra' l'utente?
Se si', va cambiato.
```

## 30. Checklist veloce file da cambiare

Questa e' la lista piu' importante.

```text
lib/core/app_constants.dart
lib/core/app_theme.dart
lib/data/config_service.dart
lib/data/banner_service.dart
lib/data/schedule_service.dart
lib/data/mock_data.dart
lib/core/audio_handler.dart
lib/core/voice_service.dart
lib/main.dart
lib/widgets/lady_radio_header.dart
lib/widgets/global_mini_player.dart
lib/screens/live_screen.dart
lib/screens/video_player_screen.dart
lib/screens/podcast_screen.dart
lib/screens/program_screen.dart
lib/screens/frequencies_screen.dart
lib/screens/schedule_screen.dart
ios/Runner/Info.plist
ios/Runner/CarPlaySceneDelegate.swift
ios/Runner.xcodeproj/project.pbxproj
android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/.../MainActivity.kt
pubspec.yaml
assets/
cover/
```

## 31. Ordine consigliato per duplicare una radio

Segui questo ordine.

1. Duplica cartella progetto.
2. Cambia nome cartella.
3. Cambia `pubspec.yaml` se vuoi rinominare il progetto Flutter.
4. Cambia `AppConstants`.
5. Cambia `AppTheme`.
6. Cambia logo in `assets/`.
7. Cambia icona app e rigenera con `flutter_launcher_icons`.
8. Cambia nome app iOS/Android.
9. Cambia Bundle ID iOS.
10. Cambia Application ID Android.
11. Cambia stream live.
12. Cambia stream TV.
13. Cambia endpoint config.
14. Cambia endpoint banner.
15. Cambia palinsesto/podcast.
16. Cambia testi Lady Radio rimasti.
17. Cambia CarPlay.
18. Cambia Android Auto.
19. Esegui test.

## 32. Comandi da eseguire dopo le modifiche

Da terminale nella cartella progetto:

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
cd ios
pod install
cd ..
flutter analyze
```

Build iOS senza firma:

```bash
flutter build ios --release --no-codesign
```

Build Android:

```bash
flutter build apk --release
```

## 33. Test minimo prima di consegnare

Test su iPhone:

- app si apre;
- logo corretto;
- colori corretti;
- nome app corretto;
- live audio parte;
- play/pause funziona;
- TV parte;
- podcast si aprono;
- puntate partono;
- preferiti funzionano;
- banner si vede;
- click banner apre link;
- tracking banner arriva;
- WhatsApp apre numero corretto;
- email apre indirizzo corretto;
- sito apre dominio corretto;
- frequenze corrette;
- lock screen mostra nome radio corretto;
- CarPlay mostra nome radio corretto.

Test su Android:

- app si apre;
- icona corretta;
- nome app corretto;
- live audio parte;
- podcast parte;
- TV parte;
- Android Auto, se previsto.

## 34. Errori comuni

### L'app mostra ancora Lady Radio

Cerca:

```text
Lady Radio
ladyradio
lady512
```

### L'icona non cambia

Esegui:

```bash
dart run flutter_launcher_icons
```

Poi disinstalla l'app dal telefono e reinstallala.

### Su iPhone non appare CarPlay

Controlla:

- Bundle ID corretto;
- provisioning profile corretto;
- capability CarPlay attiva;
- `Runner.entitlements`;
- build installata da Xcode/TestFlight con profilo giusto.

### I banner non tracciano

Controlla:

- `_baseUrl` in `banner_service.dart`;
- `Origin`;
- `Referer`;
- `X-Requested-With`;
- endpoint WordPress;
- log server.

### I podcast non compaiono

Controlla:

- endpoint schedule;
- campo `rssFeed`;
- feed RSS valido;
- immagini programma;
- log Flutter.

## 35. Consiglio pratico per il futuro

Oggi molti valori sono sparsi in piu' file perche' l'app e' nata come app Lady Radio.

Per duplicare ancora piu' velocemente molte radio, conviene in futuro creare un solo file tipo:

```text
lib/brand/brand_config.dart
```

con dentro:

- nome radio;
- colori;
- logo;
- stream;
- contatti;
- social;
- WordPress base URL;
- bundle/package;
- testi principali.

In questo modo per creare una nuova radio basterebbe cambiare quasi solo quel file.

## 36. Checklist finale per una nuova radio

Prima di considerare finita la duplicazione:

- [ ] Nome app cambiato.
- [ ] Bundle ID iOS cambiato.
- [ ] Application ID Android cambiato.
- [ ] Logo interno cambiato.
- [ ] Icona app cambiata.
- [ ] Colori cambiati.
- [ ] Stream live cambiato.
- [ ] Stream TV cambiato.
- [ ] Sito cambiato.
- [ ] Email cambiata.
- [ ] WhatsApp cambiato.
- [ ] Social cambiati.
- [ ] Frequenze cambiate.
- [ ] Palinsesto collegato.
- [ ] Podcast collegati.
- [ ] Banner collegati.
- [ ] Tracking banner verificato.
- [ ] CarPlay aggiornato.
- [ ] Android Auto aggiornato.
- [ ] Test iPhone completato.
- [ ] Test Android completato.
- [ ] `flutter analyze` controllato.
- [ ] Build iOS controllata.
- [ ] Build Android controllata.
