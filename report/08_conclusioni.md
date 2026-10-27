# 8. Conclusioni e sviluppi futuri

## 8.1 Risultati raggiunti

Il progetto ha realizzato una pipeline completamente automatica per la segmentazione delle lesioni di sclerosi multipla in volumi MRI BrainWeb, basata esclusivamente su tecniche classiche di elaborazione delle immagini. La versione finale, la v4, usa la T1 per delimitare un supporto anatomico in cui cercare le lesioni e la T2, filtrata con una diffusione anisotropa 3D, per identificarle tramite una soglia multi-livello vincolata da una soglia minima riferita a una regione WM-like dell'immagine stessa. Tutte le soglie sono stimate automaticamente da ciascun volume e la ground truth non interviene mai nella segmentazione.

I risultati principali sono i seguenti:

- **test riservato finale**, su dati mai visti durante lo sviluppo della v4: sul phantom senza lesioni la v4 produce 172 voxel falsi positivi senza rumore e 30 con rumore 3 %, contro 31.917 e 17.486 della v3; con rumore 3 % ottiene Dice 0,341 sul carico lieve e 0,773 sul carico grave (Sezione 6.5);
- **test prospettico originale della v3**, su quattro livelli di rumore mai visti: Dice tra 0,69 e 0,71 fino al 5 % di rumore e circa 0,41 al 7 % e al 9 %, per l'aumento dei falsi positivi (Sezione 6.1);
- **comportamento rispetto al carico lesionale e al rumore**, che ha messo in luce il difetto della v3 con carico lieve e ha motivato la v4 (Sezioni 6.3 e 6.4);
- **riproducibilità**: tutte le 26 combinazioni di versione e caso riproducono voxel per voxel le predizioni salvate, e tutti i risultati sono riconducibili ai file da cui derivano tramite impronte SHA-256 (Sezione 5.14).

Il confronto tra le due versioni sullo stesso test riservato mostra che la v4 ha spostato il comportamento della pipeline verso una maggiore selettività: elimina gran parte della sovrasegmentazione della v3, in particolare in assenza di lesioni e con carico lieve, al prezzo di una minore sensibilità alle lesioni deboli o piccole.

## 8.2 Contributo del progetto

Il contributo del progetto non sta in un singolo valore di Dice, ma nel modo in cui la pipeline è stata costruita e valutata.

- **Una pipeline classica, automatica e interpretabile.** Ogni blocco ha un ruolo preciso e verificabile, e lo studio di ablazione ne ha misurato il contributo: il supporto anatomico S2 è risultato il passo decisivo, seguito dalla morfologia e dal filtraggio della T2.
- **Un protocollo di sviluppo e test rigoroso.** Le predizioni sono state salvate prima di caricare la ground truth, le versioni valutate sono state congelate prima dei test e i dati del test riservato sono stati richiesti solo dopo il congelamento della v4.
- **L'individuazione esplicita dei modi di errore.** Il progetto non si limita a riportare i casi in cui la pipeline funziona: documenta il cedimento della v3 ad alto rumore e con carico lieve, ne analizza la causa sui dati di sviluppo e verifica la correzione con un test riservato indipendente dallo sviluppo della v4. Riporta inoltre apertamente i limiti che restano con la v4, compreso il caso grave in cui la v3 ottiene un Dice leggermente più alto.
- **Una distinzione rigorosa tra tipi di evidenza.** Test prospettico originale, dati visti durante lo sviluppo e test riservato finale sono stati tenuti separati in tutte le tabelle e le discussioni, in modo che ogni risultato venga letto con il proprio valore metodologico.
- **Tracciabilità e riproducibilità.** Le versioni congelate, i manifest con le impronte, la riproduzione automatica dei risultati e la validazione delle metriche su casi artificiali rendono ogni numero della relazione verificabile.

## 8.3 Limiti principali

I limiti sono discussi in dettaglio nella Sezione 7.10. I più importanti sono:

- tutti i dati sono simulati e la diversità anatomica è limitata all'ambiente BrainWeb utilizzato;
- il test riservato della versione finale è piccolo, con quattro condizioni;
- il supporto S2 impone un limite rigido alla Recall, perché i voxel di lesione che cadono fuori da esso non possono essere recuperati;
- la v4 tende al sotto-rilevamento, soprattutto per le lesioni piccole e deboli, con carico lieve e con rumore elevato;
- il metodo dipende dalle distribuzioni di intensità e da una normalizzazione specifica del formato BrainWeb;
- non è stata effettuata alcuna validazione clinica.

## 8.4 Possibili sviluppi futuri

I possibili sviluppi derivano direttamente dai limiti osservati. Nessuno di essi è stato implementato in questo progetto.

- **Validazione su MRI cliniche reali**, con annotazioni di esperti, per verificare se il comportamento osservato sulle simulazioni si mantiene su immagini reali, con il loro rumore, le loro disomogeneità e la variabilità delle annotazioni.
- **Più soggetti e maggiore diversità anatomica**, per stimare la variabilità tra pazienti, che il progetto, basato su un solo modello anatomico, non può misurare.
- **Normalizzazione delle intensità più robusta**, che non dipenda dall'intervallo fisso del formato BrainWeb, insieme a una valutazione con scanner, sequenze e livelli di disomogeneità di intensità diversi.
- **Test riservati più ampi**, in particolare con carico moderato e con rumore elevato, condizioni in cui il comportamento della v4 è stato osservato solo su dati già visti.
- **Migliore recupero delle lesioni piccole e deboli**, senza reintrodurre l'eccesso di falsi positivi che la v4 ha eliminato.
- **Un supporto anatomico meno rigido**, che conservi la capacità di S2 di escludere il liquor e gli altri tessuti iperintensi, ma riduca il limite che esso impone alla Recall.
- **Una crescita volumetrica controllata**, a partire dai nuclei di lesione affidabili, con una regola di espansione che non debba essere adattata al livello di rumore: lo studio dell'isteresi ha mostrato che l'espansione può recuperare estensione lesionale, ma che l'intensità utile dipendeva dalla condizione dell'immagine.
- **Confronto con altri approcci di segmentazione**, inclusi eventualmente metodi basati sull'apprendimento come benchmark esterno, per collocare le prestazioni della pipeline classica rispetto a strategie differenti.
