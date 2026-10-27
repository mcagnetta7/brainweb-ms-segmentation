# 2. Dataset BrainWeb

## 2.1 Il database BrainWeb

Il progetto utilizza esclusivamente dati del **Simulated Brain Database (SBD) BrainWeb**, distribuito dal McConnell Brain Imaging Centre del Montreal Neurological Institute (McGill University). BrainWeb fornisce volumi MRI cerebrali **simulati** a partire da un modello anatomico digitale del cervello (*phantom*), per il quale è nota con esattezza la classe di tessuto di ogni voxel [Collins et al., 1998; Kwan et al., 1999; Cocosco et al., 1997].

La scelta di BrainWeb è motivata da quattro proprietà, tutte essenziali per un progetto di segmentazione basato su tecniche classiche:

- **ground truth esatta**: il modello anatomico da cui le immagini sono generate fornisce l'etichetta di ogni voxel, comprese le lesioni di sclerosi multipla (SM), senza l'incertezza di un'annotazione manuale;
- **condizioni controllate**: rumore, disomogeneità di intensità e carico lesionale possono essere variati uno alla volta, mantenendo fissi tutti gli altri fattori;
- **allineamento voxel a voxel**: le diverse modalità MRI e la ground truth condividono la stessa griglia spaziale, senza bisogno di registrazione;
- **riproducibilità**: i volumi sono pubblici e, per le simulazioni personalizzate, il seme del generatore di rumore rende ripetibile ogni realizzazione.

Va sottolineato fin d'ora che si tratta di **dati simulati e non di MRI cliniche**. Le lesioni del modello SM sono state segmentate da scansioni reali e inserite, all'interno della sostanza bianca, nel modello anatomico del cervello normale; le immagini sono però prodotte da un simulatore MRI. Le conseguenze di questa scelta sulla validità esterna dei risultati sono discusse nel Capitolo 7.

## 2.2 Volumi MRI e formato dei dati

Il database pre-calcolato per la SM offre tre modalità: **T1**, **T2** e **PD** (*proton density*). Le pesature differiscono per il contrasto tra i tessuti: in particolare, nelle immagini T2 le lesioni di SM appaiono iperintense rispetto alla sostanza bianca, mentre la T1 offre un buon contrasto tra sostanza bianca, sostanza grigia e liquor.

Nel progetto sono state scaricate T1, T2 e PD per le due configurazioni di sviluppo iniziali (pn0 e pn3) e soltanto T1 e T2 per tutte le altre. La PD è stata analizzata durante lo sviluppo come possibile modalità aggiuntiva, ma non fa parte della pipeline finale, che utilizza la T1 per il supporto anatomico e la T2 per l'identificazione delle lesioni (Capitolo 3).

Tutti i volumi utilizzati hanno le stesse caratteristiche geometriche e di formato:

| Proprietà | Valore |
|---|---|
| Dimensioni (X × Y × Z) | 181 × 217 × 181 voxel (7.109.137 voxel) |
| Dimensione del voxel | 1 × 1 × 1 mm³ (voxel isotropi) |
| Spessore di slice | 1 mm |
| Formato MRI | *raw short*: interi senza segno a 16 bit, con intensità codificate nell'intervallo a 12 bit 0–4095, *little-endian* |
| Formato ground truth | *raw byte*: interi a 8 bit senza segno, etichette 0–10 |
| Intestazione | assente (le dimensioni sono note dalla pagina di download) |
| Disomogeneità di intensità (INU) | 0 % per tutti i volumi utilizzati |

Il formato *raw* è stato preferito al formato MINC perché può essere letto direttamente in MATLAB con `fopen`/`fread`, senza librerie esterne. Poiché il file non contiene alcuna intestazione, le informazioni necessarie alla lettura, cioè dimensioni, tipo di dato, ordine dei byte e ordine dei voxel, sono state verificate sui file effettivamente scaricati.

In particolare:

- la documentazione BrainWeb indica un ordine dei byte *big-endian*, ma i file serviti risultano *little-endian*: letti in questo modo tutti i valori cadono nell'intervallo documentato 0–4095, mentre una lettura *big-endian* produce valori fino a 65.295, incompatibili con dati a 12 bit;
- la coordinata X varia più rapidamente e la Z più lentamente; il volume viene quindi ricostruito come array MATLAB di dimensioni 181 × 217 × 181, con dimensione 1 = X, dimensione 2 = Y e dimensione 3 = Z (indice di slice assiale);
- la dimensione di ogni file, pari a 14.218.274 byte per le MRI e 7.109.137 byte per la ground truth, corrisponde esattamente a un volume completo, e il loader del progetto rifiuta qualsiasi file di dimensione diversa.

La corrispondenza tra gli assi dell'array e le direzioni anatomiche è stata verificata visivamente, ad eccezione del verso sinistra/destra dell'asse X, che le fonti consultate non permettono di stabilire con certezza. Per questo motivo nessuna figura del progetto riporta etichette anatomiche sinistra/destra.

## 2.3 Ground truth

BrainWeb fornisce il modello anatomico in due forme: un insieme di volumi *fuzzy*, che riportano per ogni voxel la frazione di ciascun tessuto, e un modello **discreto (*crisp*)**, che assegna a ogni voxel l'etichetta del tessuto prevalente. Poiché la pipeline produce una maschera binaria e non frazioni di tessuto, il progetto utilizza il modello *crisp*.

Le etichette del modello discreto sono:

| Etichetta | Tessuto | Etichetta | Tessuto |
|---|---|---|---|
| 0 | sfondo | 6 | cute |
| 1 | liquor (CSF) | 7 | cranio |
| 2 | sostanza grigia | 8 | *glial matter* |
| 3 | sostanza bianca | 9 | tessuto connettivo |
| 4 | grasso | **10** | **lesione SM** |
| 5 | muscolo / cute | | |

La maschera di riferimento delle lesioni è definita come:

$$ M_{GT} = (\text{label} = 10) $$

cioè l'insieme dei voxel con etichetta 10.

Per il modello msles2 si contano 3.512 voxel di lesione; i conteggi di tutte le etichette coincidono con i volumi per classe pubblicati da BrainWeb, a 1 mm³ per voxel, il che conferma l'integrità del file.

![Figura 2.1](../results/figures/report_ch2_modalities_gt.png)

*Figura 2.1 – Stessa slice assiale (k = 102) del volume BrainWeb msles2 pn0 (rumore 0 %): T1 (sinistra), T2 (centro) e T2 con la ground truth delle lesioni, label 10, sovrapposta in ciano (destra). Le lesioni sono iperintense in T2; MRI e ground truth condividono la stessa griglia, senza registrazione. La slice è quella con il maggior numero di voxel di lesione, scelta solo per la visualizzazione.*

La ground truth viene usata **soltanto per la valutazione**. Non è mai un ingresso della segmentazione: nessuna soglia, regione di interesse, intervallo di slice o regola spaziale è stata derivata dalla posizione delle lesioni. Questa regola è particolarmente importante perché tutte le configurazioni di rumore del database pre-calcolato condividono la stessa ground truth msles2, già osservata durante lo sviluppo.

## 2.4 Configurazioni di rumore

Il database pre-calcolato per la SM offre sei livelli di rumore, indicati con i codici BrainWeb **pn0, pn1, pn3, pn5, pn7 e pn9**, corrispondenti a una deviazione standard del rumore pari allo 0, 1, 3, 5, 7 e 9 % dell'intensità di un tessuto di riferimento.

Per i dati pre-calcolati il tessuto di riferimento è la sostanza bianca per la T1 e il liquor per la T2 e la PD. Il rumore è gaussiano sulle componenti reale e immaginaria del segnale, quindi segue una statistica di Rice nelle regioni di segnale e di Rayleigh nello sfondo.

![Figura 2.2](../results/figures/report_ch2_noise_levels.png)

*Figura 2.2 – La stessa slice T2 (k = 102) del phantom msles2 per i sei livelli di rumore del database pre-calcolato, da pn0 (0 %) a pn9 (9 %), visualizzati con la stessa scala di grigi per renderli direttamente confrontabili.*

Tutte le configurazioni pre-calcolate usate nel progetto si riferiscono al phantom msles2, con spessore 1 mm e INU 0 % (codice rf0). L'INU è stata mantenuta a zero per isolare il rumore come unica variabile di perturbazione.

Il ruolo dei sei livelli è stato fissato all'inizio del progetto, prima di qualsiasi sviluppo dell'algoritmo:

| Configurazione | Rumore | Ruolo nel protocollo originale |
|---|---:|---|
| pn0 | 0 % | sviluppo |
| pn3 | 3 % | sviluppo |
| pn1 | 1 % | test (*held-out*) |
| pn5 | 5 % | test (*held-out*) |
| pn7 | 7 % | test (*held-out*) |
| pn9 | 9 % | test (*held-out*) |

pn0 è stato usato per l'analisi iniziale dei dati; pn3 è stato aggiunto allo sviluppo per disporre fin da subito di immagini rumorose su cui progettare il filtraggio.

La separazione non è stata fatta per slice, ad esempio utilizzando il 70 % delle slice per lo sviluppo e il 30 % per il test, perché le slice appartengono allo stesso volume continuo e sono spazialmente correlate. Una divisione di questo tipo avrebbe dato l'impressione ingannevole di disporre di dati di test indipendenti.

Come si vedrà nella Sezione 2.7, il ruolo di pn1, pn5, pn7 e pn9 è cambiato nel corso del progetto.

## 2.5 Carico lesionale

BrainWeb dispone di tre modelli anatomici SM, che differiscono per il carico lesionale:

| Phantom | Denominazione BrainWeb | Volume lesionale | Disponibilità |
|---|---|---:|---|
| msles1 | *mild* (lieve) | 422 mm³ | solo simulazioni personalizzate |
| msles2 | *moderate* (moderato) | 3.512 mm³ | database pre-calcolato e simulazioni personalizzate |
| msles3 | *severe* (grave) | 10.104 mm³ | solo simulazioni personalizzate |

Il database pre-calcolato è costruito esclusivamente sul modello moderato; per i carichi lieve e grave è stato necessario ricorrere a simulazioni personalizzate, descritte nella Sezione 2.6.

![Figura 2.3](../results/figures/report_ch2_lesion_load_3d.png)

*Figura 2.3 – Lesioni della ground truth (label 10, ciano) dei tre phantom SM: msles1 (422 voxel), msles2 (3.512 voxel) e msles3 (10.104 voxel), visualizzate in 3D con la stessa vista e gli stessi limiti spaziali. La superficie grigia, molto trasparente, è la maschera cerebrale ricavata automaticamente dalla T1 (Sezione 3.3), mostrata solo come contesto spaziale.*

È disponibile inoltre il modello del **cervello normale**, privo di lesioni, nel quale sono state inserite le lesioni dei tre modelli SM.

I termini lieve, moderato e grave indicano qui esclusivamente **tre carichi lesionali simulati**: non corrispondono a stadi clinici della malattia.

Inoltre i tre modelli condividono la stessa anatomia di base e differiscono solo per le lesioni; non rappresentano quindi soggetti diversi.

## 2.6 Simulazioni personalizzate BrainWeb

Per studiare il carico lesionale e per costruire un test riservato indipendente dallo sviluppo della v4, il progetto ha utilizzato il servizio di **simulazione personalizzata** di BrainWeb, che consente di scegliere phantom, sequenza, rumore, INU e seme del generatore di rumore.

Tutte le simulazioni sono state richieste con spessore 1 mm, immagine di modulo, INU 0 % (campo A), rumore riferito al tessuto più brillante e lo stesso formato *raw* dei dati pre-calcolati.

### Scelta del protocollo di simulazione

La documentazione BrainWeb è ambigua sul protocollo con cui è stato generato il database pre-calcolato: una pagina indica il protocollo ICBM, mentre le pagine di download dei volumi riportano il protocollo AI.

Per decidere in modo verificabile sono state richieste entrambe le versioni del phantom msles2 senza rumore e confrontate con il volume pre-calcolato pn0 corrispondente:

| Template | Sequenza T1 | Sequenza T2 | Correlazione T1 | Correlazione T2 |
|---|---|---|---:|---:|
| ICBM | SFLASH, TR 18 ms, flip 30°, TE 10 ms | DSE_LATE, TR 3300 ms, TE 35 / 120 ms | 0,990 | 0,939 |
| **AI** | **SFLASH, TR 35 ms, flip 45°, TE 10 ms** | **SE, TR 3000 ms, TE 80 ms** | **0,990** | **0,977** |

Il template ICBM produce una T2 con contrasto sensibilmente diverso da quello dei volumi pre-calcolati usati nello sviluppo, mentre il template AI risulta molto più vicino a quel dominio.

Le simulazioni personalizzate adottate nel progetto usano quindi il **template AI**; le simulazioni ICBM sono state archiviate ma **escluse da qualsiasi analisi e risultato**.

Anche con il template AI i volumi personalizzati non sono identici byte per byte a quelli pre-calcolati: i due domini sono vicini ma non coincidenti.

Sono stati prodotti due insiemi di simulazioni AI, distinti dal seme del generatore di rumore:

| Insieme | Seme | Phantom e rumore | Modalità | Uso |
|---|---:|---|---|---|
| Seme 1 | 1 | msles1, msles2, msles3 con rumore 0 % | T1, T2 | studio del carico lesionale (v3), poi sviluppo della v4 |
| Seme 2 | 2 | normale 0 %; normale 3 %; msles1 3 %; msles3 3 % | T1, T2 | **test riservato finale della v4** |

Per le simulazioni sono state scaricate anche le ground truth *crisp* dei modelli msles1 e msles3, che contengono rispettivamente 422 e 10.104 voxel con etichetta 10, in accordo con i volumi ufficiali, e quella del modello normale, che contiene soltanto le etichette 0–9.

Nel cervello normale ogni voxel predetto come lesione è quindi un falso positivo.

Per msles2 è stata riutilizzata la ground truth già disponibile.

Con un seme diverso da zero il servizio BrainWeb riproduce sempre la stessa realizzazione del rumore. Il seme 2 genera quindi realizzazioni del rumore mai viste durante lo sviluppo, ma **non nuove anatomie**: tutti i phantom derivano dallo stesso modello anatomico.

## 2.7 Organizzazione sviluppo/test e storia dei dati

L'uso dei dati è cambiato nel corso del progetto. Poiché il valore di un risultato dipende da quali dati erano già stati osservati quando l'algoritmo è stato definito, questa sezione ricostruisce la sequenza in modo esplicito.

La pipeline finale è descritta nel Capitolo 3, mentre l'evoluzione delle versioni v1–v4 è ricostruita nel Capitolo 5.

### 1. Sviluppo iniziale: pn0 e pn3

Tutto lo sviluppo dell'algoritmo, fino alla versione v3, è stato condotto esclusivamente su pn0 e pn3: analisi delle intensità, scelta della modalità, maschera cerebrale, filtraggio, soglia, morfologia e selezione dei parametri.

La ground truth di questi casi è stata usata solo per confrontare tra loro configurazioni candidate.

I risultati su pn0 e pn3 sono quindi risultati *in-sample* e tendenzialmente ottimistici.

### 2. Congelamento della v3 e test prospettico originale: pn1, pn5, pn7 e pn9

Al termine dello sviluppo la v3 è stata congelata.

Solo dopo il congelamento sono stati scaricati i volumi T1 e T2 di pn1, pn5, pn7 e pn9, mai visti fino a quel momento, sui quali la v3 è stata valutata una sola volta, senza modificare alcun parametro.

Questo costituisce il **test prospettico originale della v3**.

Il test misura la robustezza a livelli di rumore non visti sullo stesso phantom msles2, non la generalizzazione a nuovi pazienti o a nuove lesioni.

### 3. Studio del carico lesionale: simulazioni seme 1

Successivamente la v3 congelata è stata applicata alle simulazioni personalizzate msles1, msles2 e msles3, con seme 1 e rumore 0 %.

Questo esperimento ha rivelato un difetto della v3 con carico lesionale lieve, descritto nel Capitolo 6.

### 4. Sviluppo post-test della v4

Per correggere tale difetto è stata aperta una nuova fase di sviluppo, dichiarata esplicitamente come successiva al test.

Da quel momento:

- i parametri della v4 sono stati scelti su pn0, pn3 e sulle simulazioni seme 1 (msles1, msles2 e msles3);
- anche pn1, pn5, pn7 e pn9, già osservati durante il test della v3, non costituiscono più un test per la v4 e sono pertanto considerati **dati visti**;
- dopo il congelamento della v4 anche questi casi sono stati inclusi formalmente nei dati di sviluppo per un ulteriore esperimento, che non ha modificato la v4.

### 5. Test riservato finale della v4: simulazioni seme 2

Prima del congelamento della v4 è stato dichiarato un insieme di test riservato composto da:

- phantom normale con rumore 0 %;
- phantom normale con rumore 3 %;
- msles1 con rumore 3 %;
- msles3 con rumore 3 %;

tutti generati utilizzando il seme 2.

Questi dati sono stati richiesti a BrainWeb solo **dopo** il congelamento della v4 e dopo aver fissato per iscritto il protocollo di valutazione.

Tutte le predizioni sono state generate e salvate prima di caricare la ground truth, e la valutazione è stata eseguita una sola volta, senza alcuna modifica successiva dell'algoritmo.

La sequenza produce quindi tre gruppi di evidenza, che nel resto della relazione vengono mantenuti distinti:

| Gruppo | Versione | Casi | Status metodologico |
|---|---|---|---|
| **Test riservato finale** | v4 | normale 0 %, normale 3 %, msles1 3 %, msles3 3 % (seme 2) | evidenza indipendente successiva al congelamento; è l'evidenza principale per la v4 |
| **Dati visti durante lo sviluppo della v4** | v4 | pn0, pn1, pn3, pn5, pn7, pn9; msles1, msles2, msles3 seme 1 | risultati *in-sample*; utili per analizzare meccanismi e tendenze, non come validazione indipendente |
| **Test prospettico originale** | v3 | pn1, pn5, pn7, pn9 | test genuinamente *held-out* della v3 |

Il fatto che pn1, pn5, pn7 e pn9 siano diventati in seguito dati visti per la v4 non toglie valore al loro ruolo storico di test prospettico per la v3.

Allo stesso modo, i risultati della v4 su questi casi non vanno letti come un test indipendente.

Ne deriva un'asimmetria tra le due versioni: la v3 dispone di un test prospettico su quattro livelli di rumore, mentre la v4 dispone di un test riservato più piccolo ma indipendente.

Questa asimmetria è una conseguenza diretta della storia dello sviluppo ed è discussa tra i limiti dello studio nel Capitolo 7.

## 2.8 Integrità e gestione dei dati

La gestione dei dati segue alcune regole fisse, applicate per tutta la durata del progetto:

- **dati originali immutabili**: i file scaricati da BrainWeb sono conservati in `data/raw/` con il nome assegnato al momento del download e non vengono mai modificati; qualsiasi elaborazione avviene in memoria;
- **separazione tra dati originali e dati prodotti**: maschere, predizioni e altri risultati intermedi sono salvati in `data/processed/`, mentre tabelle e figure sono salvate in `results/`;
- **tracciabilità del download**: per ogni insieme di dati è conservato un record con data, configurazione richiesta, informazioni della pagina di download e, per le simulazioni personalizzate, il numero di job BrainWeb;
- **impronte SHA-256**: ogni file scaricato è identificato dalla propria impronta SHA-256, ricontrollata prima e dopo gli esperimenti principali;
- **manifest dei risultati**: i risultati usati nella relazione sono elencati in file *manifest* con le relative impronte, in modo che qualsiasi modifica successiva risulti immediatamente rilevabile;
- **verifiche in lettura**: il loader controlla la dimensione esatta di ogni file, il tipo di dato e l'ordine dei byte prima di ricostruire il volume.

Queste regole, insieme al congelamento delle versioni dell'algoritmo, permettono di riprodurre ogni risultato riportato nella relazione a partire dagli stessi file di ingresso, come descritto nella Sezione 5.14.
