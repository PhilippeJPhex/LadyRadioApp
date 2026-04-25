# Guida Lady Radio su iPhone, iPad, Mac e CarPlay

Questa guida raccoglie la configurazione Apple del progetto Flutter Lady Radio.

## 1. Requisiti sul Mac
Installa Xcode, accetta la licenza e verifica che CocoaPods sia disponibile:
```bash
sudo xcodebuild -license accept
sudo gem install cocoapods
```

## 2. Dipendenze Flutter e iOS
Dal root del progetto:
```bash
flutter pub get
cd ios
pod install
cd ..
```

Apri sempre `ios/Runner.xcworkspace` in Xcode, non `ios/Runner.xcodeproj`, perché i plugin Flutter passano da CocoaPods.

## 3. iPhone e iPad
Il target iOS è già configurato come app universale:
```text
TARGETED_DEVICE_FAMILY = 1,2
```

Questo significa:
- `1` = iPhone
- `2` = iPad

In Xcode, nel target Runner:
1. Vai in **Signing & Capabilities**.
2. Imposta il tuo Team Apple.
3. Aggiungi **Background Modes**.
4. Spunta **Audio, AirPlay, and Picture in Picture**.

Il file `ios/Runner/Info.plist` include già:
- `UIBackgroundModes` con `audio`
- schemi per WhatsApp, web, telefono e mail
- descrizioni per microfono, speech recognition e controlli multimediali

## 4. Mac
Il progetto contiene già il target `macos/`. Per abilitarlo e compilare:
```bash
flutter config --enable-macos-desktop
flutter build macos --release
```

La sandbox macOS deve permettere l'accesso rete in uscita, altrimenti stream radio, podcast, immagini e API non funzionano. Sono già stati aggiornati:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

Entrambi includono:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

## 5. CarPlay
CarPlay non si abilita solo da Flutter o Xcode: Apple deve approvare una capability speciale sul tuo Apple Developer account.

Per una radio/app audio servono normalmente:
- `com.apple.developer.carplay-audio` per CarPlay audio su iOS 14 e successivi.
- `com.apple.developer.playable-content` per compatibilità Media Player/iOS 13 e precedenti.

Procedura:
1. Vai su Apple Developer > Certificates, Identifiers & Profiles.
2. Apri l'App ID `it.ladyradio.ladyApp`.
3. Richiedi/abilita **CarPlay Audio App** nelle **Additional Capabilities**.
4. Rigenera e scarica i provisioning profile.
5. Solo dopo l'approvazione Apple, crea `ios/Runner/Runner.entitlements` partendo da `ios/Runner/CarPlay.entitlements.example`.
6. In Xcode, imposta **Code Signing Entitlements** del target Runner a `Runner/Runner.entitlements`.
7. Testa dal simulatore con **I/O > External Displays > CarPlay**.

Senza approvazione Apple l'app può compilare per iPhone, iPad e Mac, ma non apparirà nella home di CarPlay.

## 6. Icone
Il progetto usa `flutter_launcher_icons`. Per rigenerare le icone:
```bash
flutter pub run flutter_launcher_icons:main
```

La sorgente configurata è `assets/lady512.png`.

## 7. Build
Comandi principali:
```bash
flutter run
flutter build ios --release
flutter build ipa
flutter build macos --release
```

Per pubblicare su App Store:
1. Verifica bundle identifier e signing in Xcode.
2. Crea l'archivio con Xcode o `flutter build ipa`.
3. Carica l'IPA con Transporter o Xcode Organizer.
