# Guida aggiornamento App Store - Lady Radio

Questa guida serve per pubblicare **un aggiornamento** di Lady Radio su App Store, non una prima pubblicazione. L'app esiste gia' in App Store Connect: il lavoro corretto e' creare una nuova versione iOS dentro la scheda esistente, caricare una nuova build, provarla con TestFlight e inviarla in review.

Fonti Apple utili:

- [Create a new version](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
- [Choose a build to submit](https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit)
- [Release a version update in phases](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases/)
- [CarPlay audio entitlement](https://developer.apple.com/documentation/carplay/supporting-previous-versions-of-ios)

## 0. Dati del progetto

- App: `Lady Radio`
- Bundle ID iOS: `it.ladyradio.app`
- Team Apple: `6797DPV9C7`
- Workspace Xcode da aprire sempre: `ios/Runner.xcworkspace`
- Target Xcode principale: `Runner`
- Entitlements device: `ios/Runner/Runner.entitlements`
- Entitlements simulator CarPlay: `ios/Runner/Runner-CarPlay-Simulator.entitlements`
- Profilo usato finora per test: `Lady Test Filippo 2`
- Versione Flutter attuale nel progetto: `pubspec.yaml` -> `version: 1.0.0+1`

## 1. Prima regola per aggiornare un'app esistente

Non creare una nuova app in App Store Connect.

Devi usare la scheda gia' esistente di Lady Radio, perche' il Bundle ID deve rimanere lo stesso:

```text
it.ladyradio.app
```

Se cambi Bundle ID, Apple la considera un'altra app e non un aggiornamento.

## 2. Controllo stato app attuale su App Store Connect

1. Apri [App Store Connect](https://appstoreconnect.apple.com/).
2. Vai su `Apps`.
3. Apri `Lady Radio`.
4. Verifica che l'app attuale sia pubblicata o comunque abbia una versione iOS esistente.
5. Controlla lo stato della versione attuale.

Per creare un nuovo aggiornamento, normalmente la versione corrente deve essere in uno stato distribuibile, per esempio:

```text
Ready for Distribution
```

Se la versione attuale e' ancora in review, rejected, developer rejected o in preparazione, valuta prima se completare o annullare quel flusso.

## 3. Creare la nuova versione iOS in App Store Connect

1. In App Store Connect apri `Apps`.
2. Seleziona `Lady Radio`.
3. Nella sidebar, sotto la piattaforma `iOS`, cerca la versione corrente.
4. Clicca il pulsante `+` accanto alla piattaforma/versione iOS.
5. Inserisci il nuovo numero versione.

Esempio:

```text
Versione attuale su App Store: 1.0.0
Nuova versione da pubblicare: 1.0.1
```

Oppure, se e' un aggiornamento piu' grande:

```text
Versione attuale su App Store: 1.0.0
Nuova versione da pubblicare: 1.1.0
```

6. Clicca `Create`.
7. App Store Connect copia molti metadati dalla versione precedente: descrizione, keyword, screenshot, privacy ecc.
8. Non dare per scontato che siano tutti corretti: vanno ricontrollati.

## 4. Aggiornare versione e build number nel progetto Flutter

Apri `pubspec.yaml`.

Trova:

```yaml
version: 1.0.0+1
```

Formato:

```text
versione_pubblica+build_number
```

Esempio pratico per aggiornamento:

```yaml
version: 1.0.1+2
```

Significato:

- `1.0.1` e' la versione visibile su App Store.
- `2` e' il build number tecnico.

Regole importanti:

- La versione prima del `+` deve combaciare con la nuova versione creata in App Store Connect.
- Il numero dopo il `+` deve essere maggiore di qualunque build gia' caricata per quella versione.
- Se carichi una build e Apple la rifiuta per un problema tecnico, non puoi ricaricare lo stesso build number: devi incrementarlo.

Esempio:

```yaml
version: 1.0.1+2
```

Se devi caricare una seconda build della stessa versione:

```yaml
version: 1.0.1+3
```

Se in futuro pubblichi una nuova versione:

```yaml
version: 1.0.2+4
```

## 5. Controllare Bundle ID e signing in Xcode

Apri il workspace corretto:

```bash
open ios/Runner.xcworkspace
```

In Xcode:

1. Seleziona il progetto `Runner` nella colonna sinistra.
2. Seleziona il target `Runner`.
3. Apri `Signing & Capabilities`.
4. Controlla `Team`.

Deve essere:

```text
6797DPV9C7
```

5. Controlla `Bundle Identifier`.

Deve essere:

```text
it.ladyradio.app
```

6. Controlla che l'app non stia usando un Bundle ID diverso come:

```text
it.ladyradio.ladyApp
it.ladyradio.app.debug
```

Per pubblicare l'aggiornamento, il Bundle ID deve essere esattamente quello gia' collegato all'app esistente su App Store Connect.

## 6. Controllare le capability su Apple Developer

Vai su [Apple Developer](https://developer.apple.com/account/).

1. Apri `Certificates, Identifiers & Profiles`.
2. Vai su `Identifiers`.
3. Cerca `it.ladyradio.app`.
4. Apri l'Identifier.
5. Verifica le capability.

Per questa app servono almeno:

```text
CarPlay Audio App
Audio background mode lato progetto
```

Nel file `ios/Runner/Runner.entitlements` deve esserci:

```xml
<key>com.apple.developer.carplay-audio</key>
<true/>
```

Nel `Info.plist` deve esserci il background audio:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## 7. Profilo di provisioning per App Store

Il profilo `Lady Test Filippo 2` e' utile per sviluppo/test, ma per l'upload App Store serve firma di distribuzione valida.

Hai due strade.

### Opzione A - Firma automatica Xcode

Consigliata se Xcode riesce a gestire correttamente CarPlay.

In Xcode:

1. `Runner` target.
2. `Signing & Capabilities`.
3. Configurazione `Release`.
4. Attiva `Automatically manage signing`.
5. Seleziona il team corretto.
6. Xcode crea o seleziona il profilo di distribuzione corretto.

### Opzione B - Firma manuale

Usala se Xcode non aggancia bene CarPlay.

Nel portale Apple Developer:

1. Vai su `Profiles`.
2. Clicca `+`.
3. Scegli `App Store`.
4. Seleziona l'App ID:

```text
it.ladyradio.app
```

5. Seleziona il certificato `Apple Distribution`.
6. Dai un nome chiaro, per esempio:

```text
Lady Radio App Store Distribution
```

7. Scarica il `.mobileprovision`.
8. Doppio click sul file per installarlo.
9. Torna in Xcode.
10. In `Signing & Capabilities`, per `Release`, seleziona quel provisioning profile.

## 8. Verificare un provisioning profile

Da Terminale puoi controllare il contenuto di un profilo.

Esempio:

```bash
security cms -D -i /Users/filippopicerno/Downloads/NOME_PROFILO.mobileprovision | plutil -p -
```

Per cercare CarPlay:

```bash
security cms -D -i /Users/filippopicerno/Downloads/NOME_PROFILO.mobileprovision | plutil -p - | grep carplay
```

Devi vedere qualcosa come:

```text
com.apple.developer.carplay-audio
```

Controlla anche:

```text
ApplicationIdentifierPrefix
Entitlements.application-identifier
Entitlements.com.apple.developer.team-identifier
```

L'application identifier deve finire con:

```text
it.ladyradio.app
```

## 9. Preparazione locale prima della build

Da root progetto:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

Se CocoaPods segnala problemi:

```bash
cd ios
pod repo update
pod install
cd ..
```

Se Xcode dice:

```text
The sandbox is not in sync with the Podfile.lock
```

esegui:

```bash
cd ios
pod install
cd ..
```

Se Xcode dice:

```text
database is locked
```

chiudi build concorrenti:

1. Ferma build in Xcode.
2. Chiudi eventuali `flutter run`.
3. Chiudi simulatori non necessari.
4. Riapri Xcode.
5. Fai `Product > Clean Build Folder`.

## 10. Controlli codice prima dell'archivio

Esegui:

```bash
flutter analyze
```

Nel progetto possono rimanere warning noti su plugin/deprecazioni. Blocca la pubblicazione solo se trovi:

- errori Dart;
- errori di compilazione;
- crash all'avvio;
- tracking banner non funzionante;
- streaming live non funzionante;
- podcast non funzionanti;
- CarPlay assente;
- firma senza entitlement CarPlay.

Poi fai una build iOS senza firma per controllare la compilazione:

```bash
flutter build ios --release --no-codesign
```

Se questa fallisce, non andare in Xcode Archive: prima correggi l'errore.

## 11. Test funzionale prima dell'upload

Installa su iPhone reale da Xcode:

1. Apri `ios/Runner.xcworkspace`.
2. Seleziona il tuo iPhone fisico.
3. Seleziona scheme `Runner`.
4. Usa configurazione `Release` se vuoi simulare meglio App Store/TestFlight.
5. Fai `Product > Clean Build Folder`.
6. Premi `Run`.

Checklist minima iPhone:

- App si apre senza schermata bianca o crash.
- Home mostra logo, banner e sezioni correttamente.
- Live parte premendo play.
- Se un podcast e' in riproduzione e passi a Live, l'icona play/pause si aggiorna correttamente.
- Podcast: lista programmi, lista puntate, player puntata.
- Preferiti: aggiunta, rimozione e riapertura episodio.
- Mini-player viola non copre logo e shortcut preferiti.
- Banner: impression viene inviata.
- Banner: click viene inviato prima dell'apertura browser.
- Video player si apre su iOS senza zoom fuori bordo.
- Audio continua in background.
- Lock screen mostra metadati corretti.

## 12. Test log tracking banner

Per vedere i log su Simulator:

```bash
flutter run -d "iPhone 17"
```

Per vedere i log su iPhone fisico:

```bash
flutter run -d 00008150-001211800A78401C
```

Oppure da Xcode:

1. Apri `ios/Runner.xcworkspace`.
2. Seleziona iPhone.
3. Premi `Run`.
4. Guarda la console in basso.

Log attesi:

```text
[BANNER TRACKING] +1 VISTA
[BANNER TRACKING] +1 CLICK
```

Se vedi `301 Moved Permanently`, controlla che l'endpoint usi:

```text
https://www.ladyradio.it/wp-json/ladyapp/v1
```

e non:

```text
http://ladyradio.it/...
https://ladyradio.it/...
```

## 13. Test CarPlay fisico

Prima verifica entitlement nella build installata.

Dopo build firmata:

```bash
codesign -d --entitlements - build/ios/iphoneos/Runner.app
```

Deve comparire:

```text
com.apple.developer.carplay-audio
```

Poi test fisico:

1. Installa l'app su iPhone.
2. Collega iPhone a CarPlay fisico.
3. Sul display CarPlay apri la griglia app.
4. Cerca Lady Radio.

Se non compare:

1. Su iPhone apri `Impostazioni`.
2. Vai su `Generali`.
3. Vai su `CarPlay`.
4. Seleziona l'auto.
5. Tocca `Personalizza`.
6. Verifica che Lady Radio non sia nascosta.
7. Se ancora non compare, controlla di nuovo entitlement e provisioning profile.

Checklist CarPlay:

- All'avvio ci sono 3 tab: `Live`, `Podcast`, `Preferiti`.
- Tab `Live`: appare `Ascolta la diretta`.
- Toccando `Ascolta la diretta` si apre il player Live.
- Tab `Podcast`: appare lista dei podcast disponibili.
- Toccando un podcast si apre lista puntate.
- Toccando una puntata si apre il player corrispondente.
- Tab `Preferiti`: mostra contenuti salvati.
- Metadati player non si sovrappongono.
- Cambio Podcast -> Live aggiorna play/pause.
- Cambio Live -> Podcast aggiorna titolo/autore/artwork.

## 14. Preparare metadati della nuova versione

In App Store Connect, nella nuova versione iOS:

1. Controlla `What's New in This Version`.
2. Scrivi note chiare dell'aggiornamento.

Esempio:

```text
Abbiamo migliorato la stabilita' dell'app, aggiunto il supporto CarPlay, ottimizzato la riproduzione audio e aggiornato la gestione dei podcast.
```

3. Controlla descrizione app.
4. Controlla keyword.
5. Controlla URL supporto.
6. Controlla URL privacy policy.
7. Controlla copyright.
8. Controlla categoria.
9. Controlla classificazione eta'.

Se CarPlay e' una feature nuova, valuta di citarla nelle note versione, ma non promettere disponibilita' se Apple non ha ancora approvato entitlement/profilo in distribuzione.

## 15. Screenshot

Per un aggiornamento, gli screenshot esistenti possono rimanere, ma vanno aggiornati se l'interfaccia e' cambiata in modo evidente.

Controlla:

- screenshot iPhone 6.7";
- screenshot iPhone 6.5" o equivalenti richiesti da App Store Connect;
- screenshot iPad se l'app e' disponibile anche per iPad;
- eventuali screenshot che mostrano funzioni non piu' presenti;
- eventuali screenshot che non mostrano CarPlay se vuoi comunicare la feature.

Nota: gli screenshot CarPlay non sempre sono richiesti come slot separato; usali solo se App Store Connect li accetta o se servono nel materiale marketing.

## 16. Privacy App Store

In App Store Connect apri:

```text
App Privacy
```

Ricontrolla le risposte perche' questo aggiornamento include tracking banner e chiamate WordPress.

Da verificare con il titolare:

- impression banner;
- click banner;
- indirizzo IP lato server WordPress;
- user-agent;
- log server;
- eventuali cookie/sessioni WordPress;
- apertura link esterni;
- streaming audio;
- podcast;
- preferiti locali;
- microfono;
- speech recognition.

Se l'app non usa IDFA e non traccia utenti cross-app/cross-site, non aggiungere ATT solo per prudenza.

Pero' se i banner o WordPress permettono tracciamento cross-site/cross-app tramite identificatori, serve valutare ATT e dichiarazione privacy corretta.

La privacy policy pubblica dovrebbe descrivere:

- ascolto streaming;
- podcast;
- banner;
- click/impression;
- dati tecnici raccolti dal server;
- link esterni;
- dati salvati localmente;
- contatti privacy.

## 17. Export compliance

Durante TestFlight o invio review Apple puo' chiedere informazioni su crittografia/export compliance.

Per questa app, normalmente si usa HTTPS/TLS standard tramite sistema operativo.

Se non ci sono librerie crittografiche proprietarie o funzioni crypto specifiche, in genere si dichiara l'uso standard di crittografia esente/di sistema. Confermare comunque con il titolare o consulente prima dell'invio.

## 18. Creare archivio da Xcode

In Xcode:

1. Apri `ios/Runner.xcworkspace`.
2. In alto seleziona scheme `Runner`.
3. Come destinazione seleziona:

```text
Any iOS Device (arm64)
```

oppure:

```text
Any iOS Device
```

4. Non selezionare Simulator per Archive.
5. Vai su `Product`.
6. Premi `Clean Build Folder`.
7. Poi vai su `Product > Archive`.
8. Attendi la fine della build.

Se l'archive non parte:

- controlla signing;
- controlla provisioning profile;
- controlla che non sia selezionato un simulator;
- controlla `Runner.xcworkspace`, non `Runner.xcodeproj`;
- esegui `pod install`;
- riprova `Clean Build Folder`.

## 19. Validare e caricare l'archive

Quando si apre Organizer:

1. Seleziona l'archive appena creato.
2. Clicca `Distribute App`.
3. Scegli `App Store Connect`.
4. Scegli `Upload`.
5. Lascia attive le opzioni standard di validazione.
6. Procedi.
7. Xcode valida firma, entitlements e bundle.
8. Se la validazione passa, conferma upload.

Se fallisce per signing:

- controlla che il profilo sia App Store Distribution, non Development;
- controlla che il certificato Apple Distribution sia nel Keychain;
- controlla che il Bundle ID sia `it.ladyradio.app`;
- controlla che il profilo contenga `com.apple.developer.carplay-audio`;
- controlla che `Runner.entitlements` non contenga entitlement non presenti nel profilo.

## 20. Attendere processing build

Dopo upload:

1. Torna su App Store Connect.
2. Apri `Lady Radio`.
3. Vai su `TestFlight`.
4. Attendi che la build appaia.

Apple puo' impiegare da pochi minuti a piu' tempo.

Quando il processing finisce, riceverai anche una mail.

Se la build non compare:

- controlla che upload Xcode sia davvero completato;
- controlla mail Apple per errori;
- controlla versione e build number;
- controlla che Bundle ID sia quello dell'app esistente.

## 21. TestFlight interno

Prima di inviare in review:

1. Vai su `TestFlight`.
2. Seleziona la build appena caricata.
3. Compila eventuali domande export compliance.
4. Aggiungi tester interni.
5. Installa da TestFlight sul tuo iPhone.

Checklist TestFlight:

- avvio app;
- Live;
- Podcast;
- Preferiti;
- banner impression;
- banner click;
- video player;
- background audio;
- lock screen;
- CarPlay fisico.

Importante: TestFlight e' piu' vicino all'App Store rispetto all'installazione da Xcode. Testare CarPlay da TestFlight e' fondamentale.

## 22. Collegare la build alla nuova versione

Quando la build e' processata:

1. Vai su `Apps`.
2. Apri `Lady Radio`.
3. Apri la nuova versione iOS creata.
4. Scorri fino alla sezione `Build`.
5. Clicca `+`.
6. Seleziona la build corretta.
7. Salva.

Puoi associare una sola build alla versione da inviare in review.

Se carichi una build nuova:

1. Rimuovi la build vecchia dalla sezione `Build`.
2. Aggiungi quella nuova.
3. Salva.

## 23. App Review Information

Compila o verifica:

- nome contatto;
- telefono;
- email;
- note per reviewer;
- eventuale account demo, se richiesto.

Per questa app conviene aggiungere una nota CarPlay.

Esempio:

```text
L'app include supporto CarPlay Audio. Per testare CarPlay: collegare iPhone a un sistema CarPlay, aprire Lady Radio dalla griglia CarPlay, poi provare tab Live, Podcast e Preferiti. L'app riproduce streaming radio live e podcast.
```

Se alcune funzioni richiedono rete o contenuti live, indicarlo:

```text
La riproduzione audio richiede connessione internet. I contenuti podcast sono caricati dinamicamente dai feed Lady Radio.
```

## 24. Scegliere rilascio immediato o manuale

In App Store Connect, prima dell'invio, scegli come rilasciare l'aggiornamento dopo approvazione.

Opzioni tipiche:

### Automatic release

Apple pubblica appena approva.

Usala se sei sicuro e non devi coordinare comunicazione o backend.

### Manual release

Apple approva, ma la pubblicazione parte solo quando premi tu il rilascio.

Consigliata se vuoi:

- testare con calma;
- coordinare sito/social;
- evitare pubblicazione notturna;
- aspettare conferma del backend WordPress.

### Phased release

Apple distribuisce l'aggiornamento gradualmente in 7 giorni agli utenti con aggiornamenti automatici.

Percentuali Apple:

```text
Giorno 1: 1%
Giorno 2: 2%
Giorno 3: 5%
Giorno 4: 10%
Giorno 5: 20%
Giorno 6: 50%
Giorno 7: 100%
```

Nota: anche con phased release, qualsiasi utente puo' aggiornare manualmente dall'App Store.

Per questo rilascio, visto che include CarPlay e modifiche audio/tracking, e' ragionevole usare:

```text
Manual release oppure phased release
```

## 25. Invio in review

Prima di premere `Submit for Review`, controlla:

- nuova versione creata correttamente;
- build associata;
- build TestFlight provata;
- CarPlay fisico provato;
- tracking banner verificato;
- privacy aggiornata;
- screenshot validi;
- note versione compilate;
- App Review Information compilata;
- export compliance completata;
- release mode scelto.

Poi:

1. Clicca `Submit for Review`.
2. Rispondi alle domande finali Apple.
3. Conferma.

## 26. Durante la review

Monitora:

- email Apple;
- App Store Connect;
- eventuali messaggi in `Resolution Center`.

Se Apple chiede chiarimenti su CarPlay:

- rispondi che l'app e' una radio/audio app;
- spiega i tre tab CarPlay;
- indica che non ci sono funzioni video o interazioni complesse in CarPlay;
- specifica che il video player e' solo nell'app iPhone, non nell'interfaccia CarPlay.

Se Apple chiede chiarimenti su tracking:

- descrivi impression/click banner;
- specifica se i dati sono aggregati o personali;
- indica privacy policy;
- chiarisci se non viene usato IDFA.

## 27. Dopo approvazione

Se hai scelto automatic release:

1. Apple pubblica automaticamente.
2. Controlla App Store quando lo stato diventa `Ready for Distribution`.

Se hai scelto manual release:

1. Attendi stato `Pending Developer Release`.
2. Quando sei pronto, clicca `Release This Version`.

Se hai scelto phased release:

1. Controlla percentuali giorno per giorno.
2. Monitora crash, recensioni e feedback.
3. Se c'e' un problema serio, pausa phased release.

## 28. Controlli post-release

Subito dopo pubblicazione:

- installa/aggiorna da App Store su iPhone;
- apri app;
- prova Live;
- prova Podcast;
- prova Preferiti;
- prova banner;
- prova video;
- prova background audio;
- prova CarPlay fisico;
- controlla log/backend WordPress per impression e click;
- controlla eventuali crash in Xcode Organizer/App Store Connect.

## 29. Se qualcosa va storto dopo pubblicazione

Apple non permette di tornare direttamente a una versione precedente gia' pubblicata.

Se l'aggiornamento ha un problema:

1. Correggi il codice.
2. Incrementa build number.
3. Se necessario incrementa anche versione.
4. Carica nuova build.
5. Invia nuovo aggiornamento.

Se stai usando phased release:

1. Pausa il rilascio.
2. Valuta fix.
3. Carica nuova build/versione corretta.

## 30. Comandi rapidi utili

Pulizia e dipendenze:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

Analisi:

```bash
flutter analyze
```

Build controllo senza firma:

```bash
flutter build ios --release --no-codesign
```

Build release firmata:

```bash
flutter build ios --release
```

Aprire workspace:

```bash
open ios/Runner.xcworkspace
```

Verificare entitlement app buildata:

```bash
codesign -d --entitlements - build/ios/iphoneos/Runner.app
```

Verificare provisioning profile:

```bash
security cms -D -i /percorso/file.mobileprovision | plutil -p -
```

## 31. Checklist finale sintetica

Prima del submit:

- `pubspec.yaml` aggiornato, esempio `1.0.1+2`.
- App Store Connect: nuova versione iOS creata nella scheda esistente.
- Bundle ID sempre `it.ladyradio.app`.
- Signing Release valido per App Store.
- Provisioning profile contiene CarPlay.
- `Runner.entitlements` contiene `com.apple.developer.carplay-audio`.
- `Info.plist` contiene background audio.
- `flutter analyze` senza errori bloccanti.
- `flutter build ios --release --no-codesign` OK.
- Archive Xcode OK.
- Upload App Store Connect OK.
- TestFlight OK.
- CarPlay fisico OK.
- Build associata alla nuova versione.
- Privacy e tracking verificati.
- Submit for Review.
