# AppStructure

Questa mappa indica dove si trovano le schermate principali dell'app Lady Radio e cosa si gestisce da ogni file.

## Avvio app

### `lib/main.dart`
Gestisce:
- bootstrap dell'app Flutter
- inizializzazione `AudioService`
- creazione globale di `audioHandler`
- `MaterialApp`
- splash screen iniziale
- tema principale dell'app

Da modificare quando:
- devi cambiare configurazioni globali dell'app
- devi modificare splash/loading iniziale
- devi configurare servizi iniziali
- devi cambiare titolo app o tema globale

## Navigazione principale

### `lib/screens/main_screen.dart`
Gestisce:
- tab principali dell'app
- navigazione interna di ogni tab con `Navigator` separati
- bottom navigation bar
- overlay del mini-player viola globale
- apertura della schermata podcast quando tocchi il mini-player

Da modificare quando:
- devi aggiungere/rimuovere tab principali
- devi cambiare comportamento della bottom navigation
- devi modificare dove appare il mini-player globale
- devi gestire navigazioni comuni tra schermate

### `lib/widgets/bottom_nav_bar.dart`
Gestisce:
- UI della barra di navigazione inferiore
- icone e label dei tab

Da modificare quando:
- vuoi cambiare icone o nomi dei tab
- vuoi cambiare stile della barra inferiore

## Home

### `lib/screens/home_screen.dart`
Gestisce:
- schermata Home
- header con logo
- banner pubblicitario
- palinsesto/programmi del giorno
- ultimi podcast
- apertura dettaglio programma
- apertura player podcast
- spazio dinamico sopra l'header quando il mini-player viola e' visibile

Da modificare quando:
- vuoi cambiare layout della Home
- vuoi spostare logo, banner, palinsesto o ultimi podcast
- vuoi modificare le card podcast
- vuoi gestire la sovrapposizione con il mini-player

### `lib/viewmodels/home_viewmodel.dart`
Gestisce:
- caricamento dati per la Home
- programmi del giorno
- ultimi episodi podcast
- refresh della Home
- associazione tra episodi e programmi

Da modificare quando:
- vuoi cambiare sorgente dati della Home
- vuoi cambiare quanti podcast recenti mostrare
- vuoi modificare logica di refresh/caricamento

### `lib/widgets/lady_radio_header.dart`
Gestisce:
- logo in alto nella Home
- saluto contestuale
- shortcut area personale/preferiti
- indicatore presenza preferiti

Da modificare quando:
- vuoi cambiare header Home
- vuoi cambiare icona preferiti/personale
- vuoi cambiare testo saluto

## Live

### `lib/screens/live_screen.dart`
Gestisce:
- schermata Live
- copertina/logo centrale
- bottoni share, TV e WhatsApp
- titolo brano/live corrente
- bottone play/pause animato
- apertura player video TV

Da modificare quando:
- vuoi cambiare UI della schermata Live
- vuoi cambiare bottoni azione Live
- vuoi cambiare layout del player Live

### `lib/viewmodels/live_viewmodel.dart`
Gestisce:
- stato play/pause della diretta
- sincronizzazione con `audioHandler`
- titolo live/metadati ICY
- loading state della diretta
- comportamento del tap play/pause

Da modificare quando:
- il bottone play/pause non riflette lo stato reale
- vuoi cambiare logica di avvio/pausa della diretta
- vuoi gestire diversamente il passaggio da podcast a live

## Podcast

### `lib/screens/program_screen.dart`
Gestisce:
- dettaglio di un programma/podcast
- lista puntate del programma
- apertura del player podcast

Da modificare quando:
- vuoi cambiare pagina dettaglio programma
- vuoi cambiare lista puntate
- vuoi modificare navigazione verso il player podcast

### `lib/screens/podcast_screen.dart`
Gestisce:
- player podcast
- stato play/pause episodio
- progress bar e seek
- avanti/indietro nella playlist
- share, preferiti e WhatsApp per episodio
- sincronizzazione con mini-player globale

Da modificare quando:
- vuoi cambiare UI player podcast
- vuoi cambiare controlli audio podcast
- vuoi modificare gestione preferiti da player
- vuoi cambiare comportamento quando entri/esci dal player

### `lib/data/rss_service.dart`
Gestisce:
- download feed RSS podcast
- parsing XML dei feed
- conversione feed in lista episodi

Da modificare quando:
- cambia sorgente RSS
- vuoi cambiare parsing dei feed
- vuoi aggiungere fallback o gestione errori RSS

### `lib/models/rss_episode.dart`
Gestisce:
- modello dati di una puntata RSS
- mapping XML -> oggetto Dart

Da modificare quando:
- vuoi aggiungere campi episodio
- vuoi cambiare come vengono letti titolo, data, durata, audio URL o immagine

## Preferiti

### `lib/screens/favorites_screen.dart`
Gestisce:
- schermata lista preferiti
- apertura podcast salvati
- rimozione/visualizzazione preferiti

Da modificare quando:
- vuoi cambiare UI dei preferiti
- vuoi cambiare comportamento al tap su un preferito

### `lib/data/favorites_service.dart`
Gestisce:
- salvataggio preferiti in `SharedPreferences`
- aggiunta/rimozione/toggle preferiti
- notifica UI quando cambia la lista

Da modificare quando:
- vuoi cambiare formato dati dei preferiti
- vuoi sincronizzare preferiti online
- vuoi cambiare criteri di duplicazione

## Mini-player globale

### `lib/widgets/global_mini_player.dart`
Gestisce:
- rettangolo viola "In riproduzione"
- visibilita' del mini-player quando un podcast/flusso non-live e' attivo
- tap per tornare al player podcast
- toggle preferito dal mini-player
- `isPodcastScreenVisible`
- `currentPodcastPageId`

Da modificare quando:
- vuoi cambiare aspetto del mini-player
- vuoi cambiare quando deve apparire o sparire
- vuoi cambiare azioni rapide sul mini-player

## Audio

### `lib/core/audio_handler.dart`
Gestisce:
- player audio centrale con `just_audio`
- integrazione `audio_service`
- live stream
- podcast e playlist
- lock screen / control center
- metadati audio
- controlli play, pause, next, previous, seek
- struttura Android Auto / browse audio

Da modificare quando:
- vuoi cambiare logica audio centrale
- vuoi cambiare metadati mostrati nel sistema
- vuoi cambiare playlist o coda
- vuoi modificare supporto Android Auto
- vuoi cambiare comportamento live/podcast a livello player

### `lib/core/app_constants.dart`
Gestisce:
- URL e contatti principali
- stream fallback
- sito web
- WhatsApp
- email
- frequenze FM
- testi globali

Da modificare quando:
- cambiano link, numeri, email o stream fallback
- vuoi centralizzare nuove costanti globali

## Video

### `lib/screens/video_player_screen.dart`
Gestisce:
- player TV/video
- webview/video player per lo stream video

Da modificare quando:
- vuoi cambiare player TV
- vuoi cambiare URL video
- vuoi cambiare UI della pagina video

## Frequenze e contatti

### `lib/screens/frequencies_screen.dart`
Gestisce:
- schermata frequenze radio
- lista aree/frequenze

Da modificare quando:
- cambiano frequenze FM
- vuoi cambiare layout della pagina frequenze

### `lib/screens/contacts_screen.dart`
Gestisce:
- schermata contatti
- link telefono, email, sito, social, WhatsApp

Da modificare quando:
- cambiano contatti o social
- vuoi cambiare UI dei contatti

## Palinsesto

### `lib/screens/schedule_screen.dart`
Gestisce:
- schermata palinsesto
- lista programmi/schedule

Da modificare quando:
- vuoi cambiare visualizzazione palinsesto
- vuoi modificare navigazione dal palinsesto ai programmi

### `lib/data/schedule_service.dart`
Gestisce:
- recupero dati palinsesto
- normalizzazione programmi/orari

Da modificare quando:
- cambia sorgente dati del palinsesto
- vuoi cambiare parsing o fallback del palinsesto

## Banner pubblicitari

### `lib/widgets/campaign_banner.dart`
Gestisce:
- visualizzazione banner pubblicitari
- click sui banner

Da modificare quando:
- vuoi cambiare layout banner
- vuoi cambiare comportamento al click

### `lib/data/banner_service.dart`
Gestisce:
- recupero banner dal backend WordPress
- parsing dati banner

Da modificare quando:
- cambia endpoint banner
- vuoi cambiare logica di tracking o fallback

## Tema e componenti UI

### `lib/core/app_theme.dart`
Gestisce:
- colori principali
- tema Material
- decorazioni comuni
- stile card/chip

Da modificare quando:
- vuoi cambiare palette
- vuoi cambiare stile globale dei componenti

### `lib/widgets/glass_container.dart`
Gestisce:
- contenitore UI riusabile effetto glass/card

Da modificare quando:
- vuoi cambiare stile dei box principali

### `lib/widgets/animated_play_button.dart`
Gestisce:
- bottone play/pause animato
- stato loading/play/pause

Da modificare quando:
- vuoi cambiare icona, animazione o dimensione del bottone play

## Configurazione remota

### `lib/data/config_service.dart`
Gestisce:
- download configurazione remota
- stream URL live
- URL TV
- contatti remoti
- fallback locali

Da modificare quando:
- cambia endpoint `config.json`
- vuoi cambiare fallback live/TV/contatti

## CarPlay

### `ios/Runner/CarPlaySceneDelegate.swift`
Gestisce:
- app nativa CarPlay
- tab CarPlay `Live`, `Podcast`, `Preferiti`
- lista podcast su CarPlay
- lista puntate su CarPlay
- player CarPlay / Now Playing
- metadati CarPlay
- streaming live e podcast via `AVPlayer`

Da modificare quando:
- vuoi cambiare UI o flusso CarPlay
- vuoi cambiare tab CarPlay
- vuoi cambiare metadati nel player CarPlay
- vuoi cambiare comportamento audio su CarPlay

### `ios/Runner/Info.plist`
Gestisce:
- permessi iOS
- scene iOS e CarPlay
- background audio
- URL schemes

Da modificare quando:
- aggiungi permessi iOS
- cambi configurazione scene
- aggiungi capability collegate a Info.plist

### `ios/Runner/Runner-CarPlay-Simulator.entitlements`
Gestisce:
- entitlement CarPlay usate solo dal simulator

Da modificare quando:
- vuoi testare CarPlay nel simulatore

### `ios/Runner/CarPlay.entitlements.example`
Gestisce:
- esempio di entitlement CarPlay reale

Nota:
- Per usare CarPlay su iPhone reale serve approvazione Apple Developer della capability `CarPlay Audio App`.
- Non attivare entitlement CarPlay reali su device finche' Apple non le ha abilitate sull'App ID.

## iOS e macOS build

### `ios/Podfile`
Gestisce:
- dipendenze native iOS via CocoaPods
- integrazione plugin Flutter iOS

Da modificare quando:
- aggiungi plugin nativi
- devi cambiare deployment target iOS

### `macos/Podfile`
Gestisce:
- dipendenze native macOS via CocoaPods
- integrazione plugin Flutter macOS

Da modificare quando:
- aggiungi plugin nativi macOS
- devi cambiare deployment target macOS

### `macos/Runner/DebugProfile.entitlements`
### `macos/Runner/Release.entitlements`
Gestiscono:
- sandbox macOS
- accesso rete in uscita

Da modificare quando:
- servono permessi macOS aggiuntivi
- cambi comportamento sandbox

