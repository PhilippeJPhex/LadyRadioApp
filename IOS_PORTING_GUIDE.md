# Guida Migrazione Lady Radio su iOS

Questa guida ti aiuterà a configurare il progetto Flutter esistente per funzionare correttamente su dispositivi Apple.

## 1. Requisiti Preliminari sul Mac
Assicurati di aver installato **CocoaPods**, essenziale per gestire le librerie native iOS (come `just_audio` e `audio_service`):
```bash
sudo gem install cocoapods
```

## 2. Configurazione Progetto
1. Apri il terminale nella cartella del progetto e scarica le dipendenze:
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```
2. Apri il file `ios/Runner.xcworkspace` in **Xcode**.

## 3. Xcode: Signing & Capabilities (Fondamentale)
Per una Radio App, la configurazione delle "Capabilities" è critica:
1. Seleziona il progetto **Runner** nella barra laterale sinistra.
2. Vai nel tab **Signing & Capabilities**.
3. Clicca su **+ Capability** e aggiungi **Background Modes**.
4. Spunta le seguenti voci:
   - [x] **Audio, AirPlay, and Picture in Picture** (Necessario per far suonare la radio a schermo spento).
   - [x] **Background fetch** (Consigliato).

## 4. Configurazione Info.plist
Apri `ios/Runner/Info.plist` e aggiungi/modifica le seguenti chiavi per supportare le funzioni che abbiamo sviluppato:

### Supporto WhatsApp e Link Esterni
Aggiungi questo blocco per permettere a `url_launcher` di aprire WhatsApp:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>whatsapp</string>
  <string>https</string>
  <string>http</string>
</array>
```

### Descrizione Permessi (Apple è molto severa)
Anche se l'app è principalmente una radio, aggiungi queste stringhe per evitare rifiuti in fase di revisione:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Questa app non usa il microfono, ma la libreria audio richiede questa dichiarazione.</string>
<key>NSAppleMusicUsageDescription</key>
<string>Necessario per il controllo della riproduzione audio.</string>
```

## 5. Gestione icone
Se non lo hai già fatto, usa il pacchetto `flutter_launcher_icons` (già presente nel pubspec.yaml probabilmente):
```bash
flutter pub run flutter_launcher_icons:main
```
Questo genererà automaticamente tutti i formati richiesti da iOS a partire dal file `assets/lady512.png`.

## 6. Build e Test
### Da VS Code:
1. Collega il tuo iPhone o avvia un Simulatore (Cmd+Shift+P -> "Flutter: Launch Emulator").
2. Premi **F5** per avviare il debug.

### Da Terminale (Consigliato per la prima build):
```bash
flutter run
```

## 7. Note Specifiche per Lady Radio
- **MiniPlayer e UI**: Grazie al layout con `Stack` e il padding di 100px che abbiamo impostato, l'interfaccia dovrebbe rispettare correttamente la "Safe Area" degli iPhone con Notch/Isola Dinamica.
- **Audio Service**: Su iOS, i controlli nel centro di controllo (lock screen) sono gestiti automaticamente da `audio_service` senza configurazioni aggiuntive, a patto che il Background Mode sia attivo.

## 8. Preparazione per App Store
Quando sarai pronto per pubblicare:
1. Cambia il **Bundle Identifier** in Xcode (es: `it.ladyradio.app`).
2. Crea una build di produzione:
   ```bash
   flutter build ipa
   ```
3. Carica il file `.ipa` generato tramite **Transporter** o Xcode (Product > Archive).
