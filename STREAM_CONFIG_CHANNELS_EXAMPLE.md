# Esempio `channels` per `stream_conf/config.json`

Aggiungi questa sezione al file:

```text
https://ladyradio.it/stream_conf/config.json
```

Esempio:

```json
{
  "radio": {
    "url": "https://stream4.xdevel.com/audio0s978435-2634/stream/icecast.audio"
  },
  "tv": {
    "url": "https://flash8.xdevel.com/ladyradiovideo/ladyradiovideo/playlist.m3u8",
    "text": "Anche su www.ladyradio.it"
  },
  "info": {
    "website": "https://ladyradio.it/",
    "whatsapp": "3925 72 77 75",
    "email": {
      "to": "redazione@ladyradio.it"
    },
    "facebook": "https://www.facebook.com/LadyRadioFirenze",
    "instagram": "https://www.instagram.com/ladyradiofirenze/"
  },
  "channels": [
    {
      "title": "FM",
      "subtitle": "Firenze, Prato e Pistoia",
      "detail": "102.1 FM",
      "icon": "fm"
    },
    {
      "title": "FM",
      "subtitle": "Mugello",
      "detail": "95.4 FM",
      "icon": "fm"
    },
    {
      "title": "FM",
      "subtitle": "Valdisieve",
      "detail": "95.6 FM",
      "icon": "fm"
    },
    {
      "title": "Streaming audio",
      "subtitle": "Ascolta la diretta dall'app e dal sito",
      "detail": "Live online",
      "url": "https://ladyradio.it/",
      "icon": "stream"
    },
    {
      "title": "DAB",
      "subtitle": "Ascolta Lady Radio in digitale",
      "detail": "Canale DAB Lady Radio",
      "icon": "dab"
    },
    {
      "title": "Smart speaker",
      "subtitle": "Chiedi al tuo assistente vocale di riprodurre Lady Radio",
      "detail": "Alexa / Google Home",
      "icon": "smart_speaker"
    },
    {
      "title": "Lady Radio TV",
      "subtitle": "Guarda la diretta video",
      "detail": "Video live",
      "url": "https://flash8.xdevel.com/ladyradiovideo/ladyradiovideo/playlist.m3u8",
      "icon": "tv"
    },
    {
      "title": "Sito web",
      "subtitle": "Diretta, notizie e contenuti",
      "detail": "ladyradio.it",
      "url": "https://ladyradio.it/",
      "icon": "web"
    },
    {
      "title": "Facebook",
      "subtitle": "Seguici e resta aggiornato",
      "detail": "Lady Radio Firenze",
      "url": "https://www.facebook.com/LadyRadioFirenze",
      "icon": "facebook"
    },
    {
      "title": "Instagram",
      "subtitle": "Stories, video e aggiornamenti",
      "detail": "@ladyradiofirenze",
      "url": "https://www.instagram.com/ladyradiofirenze/",
      "icon": "instagram"
    },
    {
      "title": "CarPlay e Android Auto",
      "subtitle": "Ascolta Lady Radio anche in auto",
      "detail": "App mobile",
      "icon": "car"
    }
  ]
}
```

Campi supportati da ogni canale:

- `title`: titolo della card.
- `subtitle`: descrizione breve.
- `detail`: valore in evidenza, ad esempio frequenza o indirizzo sito.
- `url`: opzionale. Se presente, la card diventa cliccabile.
- `icon`: opzionale. Valori consigliati: `fm`, `dab`, `smart_speaker`, `stream`, `tv`, `web`, `facebook`, `instagram`, `car`, `app`.

Se `channels` non e' presente, l'app usa automaticamente un fallback costruito da frequenze, sito, social e ascolto in auto gia' presenti nel config.

Forma rapida supportata per aggiungere solo DAB e smart speaker senza riscrivere tutti gli altri canali:

```json
{
  "channels": {
    "dab": {
      "title": "DAB",
      "subtitle": "Ascolta Lady Radio in digitale",
      "detail": "Canale DAB Lady Radio"
    },
    "smart_speaker": {
      "title": "Smart speaker",
      "subtitle": "Chiedi al tuo assistente vocale di riprodurre Lady Radio",
      "detail": "Alexa / Google Home"
    }
  }
}
```

Gli ID riconosciuti per l'ordinamento sono: `fm`, `dab`, `web`/`sito_web`, `facebook`/`fb`, `instagram`/`ig`, `carplay_android_auto`/`car`, `smart_speaker`.

Nota: il file sul server deve restare JSON valido. Evita la virgola finale dopo l'ultimo elemento o dopo `]`; l'app ora prova a tollerarla, ma e' meglio correggerla alla fonte.
