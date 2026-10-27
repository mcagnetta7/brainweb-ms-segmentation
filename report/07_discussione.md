# 7. Discussione

Questo capitolo interpreta i risultati del Capitolo 6. Per ogni affermazione si distingue tra ciò che i risultati **mostrano** direttamente e ciò che **suggeriscono** o con cui sono **coerenti**: i meccanismi che non sono stati isolati sperimentalmente sono presentati come interpretazioni, non come fatti dimostrati. La separazione tra i tre gruppi di evidenza (test riservato, dati visti, test prospettico originale della v3) resta valida anche qui: i risultati della v4 sui dati visti servono a capire i meccanismi e le tendenze, non come validazione indipendente.

Un risultato basso di Dice o di Recall non indica un fallimento dell'esperimento: è una proprietà dell'algoritmo in quella condizione, e il protocollo serve proprio a renderla visibile.

## 7.1 Interpretazione generale dei risultati

L'insieme dei risultati mostra due modi di errore opposti.

1. **Sovrasegmentazione per falsi positivi**, che è il difetto dominante della v3: la predizione si estende al tessuto normale iperintenso quando le lesioni sono assenti o poche (Sezione 6.4 e test riservato) e quando il rumore è elevato (Sezione 6.1).
2. **Sotto-rilevamento per falsi negativi**, che è il difetto principale che resta con la v4: la v4 elimina gran parte della sovrasegmentazione, ma perde voxel di lesione che si trovano fuori da S2 oppure che non vengono mantenuti dalle successive fasi di soglia e post-processing.

Il passaggio dalla v3 alla v4 non ha quindi eliminato gli errori: ha spostato il punto di lavoro della pipeline dal primo regime al secondo. La v4 è più selettiva: produce molti meno falsi positivi e si comporta molto meglio quando le lesioni sono assenti o rare, al prezzo di una sensibilità più bassa per le lesioni deboli, piccole o fuori dal supporto anatomico.

## 7.2 Analisi dei falsi positivi

**Phantom normale.** Il phantom senza lesioni del test riservato è la verifica più diretta del comportamento sui falsi positivi: ogni voxel predetto è un errore, e il risultato mostra se la pipeline etichetta come lesione il tessuto normale quando nessuna lesione è presente. Su questi dati, mai visti durante lo sviluppo, la v4 riduce i falsi positivi da 31.917 a 172 voxel senza rumore e da 17.486 a 30 voxel con rumore 3 % (Tabella 6.8), cioè di oltre il 99 %. È l'evidenza indipendente più forte che la correzione introdotta con la v4 si estende oltre i casi su cui è stata progettata, per il difetto che doveva correggere. Il risultato non è comunque nullo: restano 10 e 5 piccole componenti false.

Lo stesso caso mostra anche il limite della Specificity: la v3 ottiene 0,9955 pur predicendo quasi 32.000 voxel di lesione inesistenti. Questo conferma che la Specificity, da sola, non distingue una segmentazione buona da una pessima (Sezione 4.6).

**Perché la v3 sovrasegmenta.** La v3 etichetta come lesione la classe più alta della partizione di `multithresh` all'interno di S2. `multithresh` si limita a dividere l'istogramma in classi di intensità: non sa che cosa sia una lesione. Con carico lieve i due livelli della soglia risultano molto vicini, la classe più alta contiene in larga parte sostanza grigia (Sezione 5.10) e la predizione si espande nel tessuto normale; lo stesso accade, in modo ancora più netto, sul phantom normale. I risultati suggeriscono quindi un **limite strutturale** dell'assegnare il significato di "lesione" alla classe di intensità più alta quando le lesioni non formano una popolazione distinta, cioè quando sono poche o assenti. La quota di ciascun tessuto nella classe più alta è stata misurata sui dati di sviluppo, ma il meccanismo non è stato isolato con un esperimento dedicato.

**Falsi positivi residui della v4.** Sui casi con lesioni la v4 produce ancora falsi positivi, ma pochi di essi formano componenti isolate: una sola componente falsa su pn3, nessuna su msles3 e due su msles1 nel test riservato. Nelle slice visualizzate e nella vista 3D degli errori molti falsi positivi residui appaiono come sottili estensioni periferiche delle regioni lesionali (Figure 6.5 e 6.8). Questo è coerente con un disaccordo sui bordi, dove le intensità della lesione sfumano in quelle del tessuto circostante, più che con la rilevazione di strutture spurie; il meccanismo dei bordi non è stato però misurato separatamente.

## 7.3 Analisi dei falsi negativi

La v4 innalza la soglia effettiva rispetto al livello TA: la soglia minima risulta attiva in tutti i casi valutati. La conseguenza diretta, sui dati visti e sul test riservato, è una Precision più alta, meno falsi positivi e una Recall più bassa rispetto alla v3.

**Una parte dei falsi negativi è strutturale.** Poiché ogni predizione è contenuta in S2, i voxel di lesione che cadono fuori da S2 sono falsi negativi per costruzione. I dati permettono quindi una scomposizione parziale: sul phantom msles1 del test riservato, 110 dei 322 voxel falsi negativi si trovano fuori da S2 e non possono essere recuperati dalle fasi successive; i valori corrispondenti sono 686 su 3.025 per msles3, 454 su 1.206 per pn3 e 703 su 2.345 per pn9.

**La parte restante si trova dentro S2** ed è stata persa per effetto della soglia o dell'apertura morfologica; i dati disponibili non permettono di separare queste due cause. Contributi plausibili, che però non sono stati isolati voxel per voxel, sono:

- voxel di lesione la cui intensità filtrata non supera la soglia minima, cioè parti di lesione deboli o a basso contrasto;
- voxel periferici di lesioni il cui nucleo è segmentato, dove l'intensità diminuisce verso il bordo;
- lesioni molto piccole che non contengono nessun voxel sopra soglia, o che vengono eliminate dall'apertura.

Non tutti i falsi negativi hanno la stessa causa, e nessuna singola lesione mancata viene qui attribuita a un meccanismo specifico.

## 7.4 Comportamento con basso carico lesionale

Il caso lieve del test riservato (msles1 con rumore 3 %) mostra bene sia il miglioramento sia il suo limite. La v4 elimina la sovrasegmentazione catastrofica della v3, che su questo caso predice 16.891 voxel per 422 voxel reali, e porta il Dice da 0,024 a 0,341 e la Precision da 0,012 a 0,610 (Tabella 6.8). Allo stesso tempo la Recall della v4 è bassa (0,237), solo 4 delle 13 lesioni vengono toccate dalla predizione, e il 26 % dei voxel di lesione si trova fuori da S2.

Il carico lesionale lieve **non è quindi risolto**. Una lettura corretta è che la v4 trasforma il modo di errore dominante, da una sovrasegmentazione massiccia a un regime di sotto-rilevamento più conservativo. Lo stesso andamento si osserva sulla simulazione lieve con seme 1, che però fa parte dei dati di sviluppo della v4.

## 7.5 Comportamento con alto carico lesionale

Sul caso grave del test riservato (msles3 con rumore 3 %) **la v3 ottiene un Dice leggermente più alto della v4** (0,788 contro 0,773) e una Recall più alta (0,765 contro 0,701), mentre la v4 ha meno falsi positivi e una Precision più alta (Tabella 6.8). La v4 non è quindi migliore della v3 in ogni metrica e in ogni condizione.

Con carico grave i risultati sono coerenti con una condizione in cui le lesioni formano una popolazione di intensità sufficientemente distinta e la regola della v3, che associa la classe più alta alle lesioni, risulta più adeguata. In questa condizione le visualizzazioni sono coerenti con un effetto della soglia minima anche sui voxel periferici delle lesioni. Il risultato è coerente con un punto di lavoro più conservativo: un piccolo costo in Dice con carico grave, a fronte di un grande guadagno con carico lieve e in assenza di lesioni.

## 7.6 Effetto del rumore

**v3, test prospettico originale.** Il test mostra un comportamento stabile tra l'1 % e il 5 % di rumore (Dice 0,692 e 0,715), seguito da un netto peggioramento dal 7 % in poi (Tabella 6.1). L'andamento non è monotono e il calo è dovuto principalmente all'aumento dei falsi positivi e al conseguente crollo della Precision (0,28–0,29), più che a un crollo della Recall, che resta tra 0,68 e 0,75. Il cedimento della v3 ad alto rumore è quindi guidato principalmente dall'aumento dei falsi positivi e dal crollo della Precision, piuttosto che da un crollo della Recall.

**v4, dati visti.** Sugli stessi livelli di rumore la v4 non mostra l'esplosione dei falsi positivi: i falsi positivi diminuiscono all'aumentare del rumore e la Precision aumenta (Tabella 6.5). Il costo è un calo marcato della Recall, da 0,689 a pn1 a 0,332 a pn9: con rumore elevato il limite dominante della v4 diventa la sensibilità. All'aumentare del rumore la soglia minima diminuisce meno del livello TA, e il margine con cui la supera cresce; questo è coerente con una soglia minima che diventa via via il criterio decisivo, e relativamente più severo. Questi casi sono dati visti per la v4: il suo comportamento ad alto rumore su dati nuovi non è stato verificato, perché il test riservato copre solo i livelli 0 % e 3 %.

**Meccanismo ad alto rumore.** All'aumentare del rumore si osservano contemporaneamente tre fenomeni: i due livelli di `multithresh` si avvicinano, i falsi positivi della v3 aumentano fortemente e la frazione della ground truth contenuta in S2 diminuisce, da 0,887 a 0,800 (Sezione 6.3). Il comportamento della soglia è coerente con una minore separabilità delle intensità, mentre la contemporanea riduzione della copertura di S2 indica che al cedimento ad alto rumore contribuiscono sia il supporto anatomico sia la classificazione della T2. I dati non permettono di attribuire il cedimento alla sola soglia; una maggiore sovrapposizione delle distribuzioni di intensità dopo il filtraggio è un'ipotesi compatibile con queste osservazioni, non un risultato dimostrato.

## 7.7 Problema delle lesioni piccole

Le lesioni piccole sono il punto più debole della pipeline, sia nella v3 sia nella v4.

- Sul test riservato la v4 tocca 4 delle 13 lesioni con carico lieve e 18 delle 39 con carico grave; sui casi moderati visti ne tocca tra 9 e 25 su 59, pur recuperando più del 60 % del volume lesionale fino al 5 % di rumore. Molte lesioni della ground truth non vengono quindi toccate affatto, e il Dice, dominato dalle lesioni grandi, non lo rende visibile.
- Per la v3 la dimensione mediana delle lesioni mancate è di 1,5, 5 e 2,5 voxel nei tre carichi, contro 27, 36,5 e 93 voxel delle lesioni rilevate (Sezione 6.4): le lesioni mancate sono in prevalenza le più piccole. In tutti e tre i phantom la ground truth contiene lesioni di un solo voxel.
- Nel test prospettico della v3 il numero di lesioni "rilevate" aumenta ad alto rumore (41 e 44 a pn7 e pn9, contro 32 e 24 a pn1 e pn5) mentre il Dice diminuisce (Tabella 6.2). Questo è coerente con contatti casuali tra i falsi positivi che si espandono e le lesioni, e mostra perché il conteggio delle lesioni rilevate non va letto come misura della qualità della segmentazione: con il criterio adottato basta un voxel in comune per considerare una lesione rilevata.

Ci si aspetta che le lesioni piccole e deboli siano più vulnerabili all'esclusione da S2, alla soglia minima della v4 e all'apertura morfologica; per le singole lesioni, tuttavia, la causa della mancata rilevazione non è stata isolata.

## 7.8 Ruolo del supporto S2

Il supporto S2 è il blocco più importante della pipeline, e lo è in entrambe le direzioni.

**Il maggiore riduttore di falsi positivi.** Nello studio di ablazione l'introduzione di S2 porta il punteggio di sviluppo da 0,058 a 0,600, di gran lunga il passo più grande dell'intero sviluppo, riducendo i falsi positivi su pn0 da 66.484 a 1.167 voxel (Tabella 6.4). Escludendo il liquor e gli altri tessuti iperintensi non lesionali, S2 è ciò che rende utilizzabile una soglia sulla T2.

**Un tetto rigido alla Recall.** Poiché tutte le fasi successive operano solo dentro S2, la frazione della ground truth contenuta in S2 è un limite superiore alla Recall: 0,739 sul caso lieve del test riservato, 0,932 sul caso grave, 0,871 su pn3 e 0,800 su pn9. Nessuna scelta di soglia o di morfologia può superare questo limite.

S2 è quindi contemporaneamente la principale fonte di controllo dei falsi positivi e un limite strutturale alla sensibilità. Non si tratta di una contraddizione, ma di un compromesso esplicito tra sensibilità e specificità, insito nell'uso di un supporto anatomico rigido.

**Contributo degli altri blocchi.** Lo studio di ablazione chiarisce anche il ruolo dei blocchi restanti, sempre su dati di sviluppo:

- **Filtraggio.** La diffusione anisotropa della T2 ha dato un miglioramento significativo, soprattutto riducendo i falsi positivi in presenza di rumore; l'estensione da 2D a 3D ha avuto un effetto piccolo rispetto a S2 e all'introduzione del filtraggio stesso.
- **Morfologia.** L'apertura resta utile anche dopo il filtraggio: senza di essa restano molti più falsi positivi. L'elemento quadrato 3 × 3, più aggressivo del diamante, rimuove più falsi positivi ma anche più voxel di lesione, e ottiene un risultato peggiore. L'utilità della morfologia dipende quindi dal contesto in cui è inserita, e la morfologia da sola non risolve il problema della segmentazione.
- **Filtro sulle componenti di una sola slice.** Ha avuto un piccolo effetto positivo in una fase iniziale e un effetto leggermente negativo nella configurazione finale; non è stato mantenuto.
- **Recupero.** Entrambe le forme di recupero tramite ricostruzione morfologica hanno aumentato i veri positivi, ma i falsi positivi molto di più, e sono state respinte.
- **Isteresi.** L'espansione a partire dai nuclei della v4 recuperava estensione lesionale con rumore elevato, ma si estendeva nel tessuto normale con rumore basso o carico lieve (Sezione 5.12). L'isteresi non è quindi inadeguata in sé: l'intensità di espansione utile dipendeva fortemente dalla condizione dell'immagine, e una singola regola fissa non era giustificabile con le evidenze disponibili.

## 7.9 Trade-off Precision–Recall della v4

Il risultato più importante del confronto tra le due versioni è un compromesso.

*Tabella 7.1 – Precision e Recall dalla v3 alla v4 su alcuni casi rappresentativi.*

| Caso | Gruppo di evidenza | Precision v3 → v4 | Recall v3 → v4 |
|---|---|---:|---:|
| msles1 3 % | test riservato | 0,012 → 0,610 | 0,495 → 0,237 |
| msles3 3 % | test riservato | 0,811 → 0,862 | 0,765 → 0,701 |
| pn1 | test prospettico per la v3, dati visti per la v4 | 0,659 → 0,760 | 0,729 → 0,689 |
| pn9 | test prospettico per la v3, dati visti per la v4 | 0,292 → 0,953 | 0,680 → 0,332 |

In **tutti** i casi con lesioni, sia del test riservato sia dei dati visti, la Precision aumenta e la Recall diminuisce passando dalla v3 alla v4. La v3 è più sensibile nei casi difficili, ma può sovrasegmentare in modo catastrofico; la v4 è più selettiva, con meno falsi positivi e un comportamento molto migliore quando le lesioni sono assenti o rare, al prezzo di una Recall più bassa nelle condizioni con lesioni deboli, rumore elevato o carico lieve.

Nessuna delle due metriche è considerata più importante dell'altra in assoluto. La progettazione della v4 privilegia deliberatamente la robustezza rispetto alla sovrasegmentazione catastrofica, accettando un profilo di sensibilità più conservativo. Questa è un'interpretazione del compromesso osservato, non un punto di lavoro ottimizzato per un uso clinico: non è stata fatta alcuna valutazione clinica, e i risultati non permettono di affermare che una delle due versioni sia più adatta alla diagnosi.

## 7.10 Limiti dello studio

**Dati simulati.** Tutte le immagini sono simulate con BrainWeb. Questa scelta ha reso possibili confronti controllati, con ground truth esatta e rumore e carico lesionale variati uno alla volta, ma limita la validità esterna: i risultati non si trasferiscono automaticamente a MRI cliniche reali, a pazienti reali o a scanner reali.

**Diversità anatomica.** La diversità anatomica è fortemente limitata all'ambiente BrainWeb utilizzato. I phantom msles1, msles2, msles3 e normale cambiano il carico lesionale, i livelli di rumore e i semi cambiano la realizzazione del rumore, ma nessuno di essi rappresenta una nuova anatomia. Il progetto non stima quindi la variabilità tra pazienti né le prestazioni su una popolazione; il seme 2 del test riservato fornisce realizzazioni del rumore mai viste, non nuove anatomie.

**Ground truth idealizzata.** La ground truth *crisp* assegna a ogni voxel un'etichetta esatta. Un'annotazione clinica reale comporta interpretazione da parte di esperti, incertezza sui bordi e variabilità tra annotatori, che qui non sono rappresentate né misurate.

**Acquisizione e intensità.** Tutti i volumi sono a 1 mm isotropi, generati con il protocollo AI e senza disomogeneità di intensità. Non sono stati valutati altri scanner, intensità di campo, sequenze o parametri di acquisizione, spessori di slice diversi, artefatti da movimento o disomogeneità di intensità. Il metodo dipende dalle intensità: le soglie sono automatiche, ma la regola che le usa (classe più alta della T2, soglia minima a cinque deviazioni standard) dipende dalle distribuzioni di intensità prodotte dalla simulazione. Una soglia automatica non equivale a un'invarianza rispetto all'acquisizione. Anche la normalizzazione fissa nell'intervallo 0–4095 è specifica del formato BrainWeb: l'applicazione a dati clinici richiederebbe una strategia di normalizzazione validata.

**Carico lesionale e rumore.** Sono stati valutati tre carichi lesionali simulati e il phantom senza lesioni: non costituiscono un modello continuo della gravità della malattia, e lieve, moderato e grave non corrispondono a stadi clinici. Per la v4 l'andamento ad alto rumore deriva solo da dati visti; il test riservato copre i livelli 0 % e 3 %.

**Dimensione del test riservato e asimmetria delle evidenze.** Il test riservato contiene quattro condizioni, due delle quali sono varianti senza lesioni dello stesso phantom, e nessun caso con carico moderato: fornisce evidenza indipendente sui modi di errore per cui la v4 è stata progettata, ma non è una validazione esterna ampia. Inoltre la v3 dispone di un test prospettico su quattro livelli di rumore, mentre la v4 è stata sviluppata quando quei casi erano già stati osservati e dispone di un test riservato più piccolo. I confronti tra v3 e v4 non hanno quindi tutti lo stesso valore metodologico; questa asimmetria è una conseguenza della storia dello sviluppo, non un errore, ed è mantenuta esplicita in tutte le tabelle.

**Limiti del metodo.** Il metodo è una pipeline classica e deterministica: è interpretabile, riproducibile, non richiede dati di addestramento e ogni blocco ha un ruolo diretto e verificabile. Per contro non dispone di un modello appreso dell'aspetto delle lesioni, ha una capacità limitata di rappresentare distribuzioni di intensità complesse e applica la stessa regola fissa in ogni condizione; il bilanciamento tra Precision e Recall può essere modificato solo cambiando regole progettate a mano. Il valore k = 5 è stato scelto sui dati di sviluppo e non è dimostrato ottimale al di fuori delle condizioni BrainWeb valutate. L'apertura morfologica è applicata slice per slice e non modella la forma 3D delle lesioni, anche se il filtraggio, la maschera cerebrale, la valutazione e l'analisi delle componenti sono tridimensionali.

**Limiti della valutazione.** La Specificity è dominata dallo sbilanciamento tra le classi. Il criterio lesion-wise considera rilevata una lesione con un solo voxel in comune, e non sono state calcolate metriche a livello di oggetto più restrittive. Le slice delle figure 2D sono state scelte con la regola del massimo numero di voxel di lesione: sono rappresentative di slice con lesioni, non delle prestazioni medie, e le viste 3D riducono questo limite mostrando le maschere complete. Non sono stati calcolati intervalli di confidenza né test statistici: le unità sperimentali sono condizioni simulate controllate, non una coorte di pazienti, e lo studio è una validazione sperimentale deterministica.

**Ambito.** I tempi di esecuzione non sono stati misurati: il progetto non fa affermazioni sulle prestazioni in tempo reale o sull'adeguatezza a un uso operativo. Si tratta di un limite di ambito, non di accuratezza.

**In sintesi**, i risultati mostrano un comportamento riproducibile su simulazioni BrainWeb controllate, incluso un test riservato indipendente successivo al congelamento della versione finale, ma non stabiliscono una generalizzazione clinica o a livello di popolazione. Il metodo resta dipendente dalle distribuzioni di intensità simulate, da una normalizzazione fissa, da un supporto anatomico rigido e da una regola di decisione classica fissa, e il suo punto di lavoro privilegia il controllo dei falsi positivi rispetto alla sensibilità. Prima di trarre conclusioni sull'applicabilità clinica sarebbe necessaria una validazione su MRI reali indipendenti e su condizioni di acquisizione più ampie.
