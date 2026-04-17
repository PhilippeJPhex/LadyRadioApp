# Guida Sincronizzazione PC-MAC via Git (Privato)

Segui questi passaggi per trasferire in sicurezza il codice di Lady Radio dal tuo PC Windows al Mac.

## 1. Preparazione sul PC Windows (Sorgente)

### A. Crea un Repository Privato
1. Vai su [GitHub.com](https://github.com) (o GitLab/Bitbucket).
2. Crea un nuovo repository chiamato `LadyRadioApp`.
3. **IMPORTANTE**: Seleziona l'opzione **Private**. Non aggiungere README, .gitignore o licenze (li abbiamo già).

### B. Inizializza Git nel progetto
Apri il terminale nella cartella del progetto (`C:/Users/filip/Desktop/Borda/AI/LadyAPP`) e digita:

```bash
# Inizializza Git
git init

# Aggiungi tutti i file (il file .gitignore filtrerà automaticamente i file inutili)
git add .

# Crea il primo commit
git commit -m "Initial commit: Android Auto & UI optimization"

# Collega il repository remoto (Sostituisci l'URL con quello del tuo repo appena creato)
git branch -M main
git remote add origin https://github.com/TUO_UTENTE/LadyRadioApp.git

# Carica il codice
git push -u origin main
```

---

## 2. Preparazione sul Mac (Destinazione)

### A. Scarica il codice
Apri il terminale sul Mac, spostati nella cartella dove tieni i progetti (es. `Documents/Projects`) e digita:

```bash
git clone https://github.com/TUO_UTENTE/LadyRadioApp.git
cd LadyRadioApp
```

### B. Installa le dipendenze
Una volta dentro la cartella sul Mac:
```bash
flutter pub get
cd ios
pod install
cd ..
```

---

## 3. Flusso di lavoro quotidiano (Sync)

Quando fai modifiche sul **PC** e vuoi vederle sul **Mac**:

1. **Sul PC (Invia):**
   ```bash
   git add .
   git commit -m "Descrizione della modifica"
   git push
   ```

2. **Sul Mac (Ricevi):**
   ```bash
   git pull
   ```

## Consigli Importanti
- **Sicurezza**: Non caricare mai file che contengono password o chiavi API (anche se il repo è privato, è buona pratica). Il tuo `.gitignore` sta già filtrando i file pesanti di build.
- **VS Code**: Puoi gestire tutto questo graficamente dal tab "Source Control" (l'icona con i tre nodi a sinistra) sia su Windows che su Mac, senza usare il terminale.
