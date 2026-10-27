# 5. Protocollo sperimentale

Questo capitolo ricostruisce come si è arrivati alla pipeline finale descritta nel Capitolo 3: con quali regole sono state prese le decisioni, su quali dati e con quali esperimenti. Non descrive ogni singola prova eseguita, ma i passaggi che hanno determinato la forma del metodo. Per ciascuno studio di valutazione (test prospettico, ablazione, rumore, carico lesionale, test riservato) si descrive qui **come** è stato condotto; i risultati numerici sono riportati nel Capitolo 6. Fanno eccezione i pochi risultati necessari per capire perché una decisione è stata presa.

Tutti i valori riportati in questo capitolo per i casi di sviluppo sono valori *in-sample*: sono stati ottenuti sugli stessi dati usati per scegliere il metodo e sono quindi tendenzialmente ottimistici.

## 5.1 Strategia generale di sviluppo

Lo sviluppo ha seguito alcune regole fisse, mantenute per tutto il progetto.

**Dati di sviluppo.** Fino alla v3 tutte le scelte sono state fatte esclusivamente su pn0 e pn3 (Sezione 2.7). I casi di test non sono stati scaricati prima del congelamento della versione da valutare.

**Criterio di selezione.** Ogni configurazione candidata è stata valutata con il Dice sul volume completo in entrambi i casi di sviluppo, e confrontata tramite un unico punteggio:

$$ \text{DevelopmentScore} = \frac{Dice_{pn0} + Dice_{pn3}}{2} $$

Lo stesso insieme di parametri è sempre applicato a entrambi i casi: non sono ammessi parametri diversi per livelli di rumore diversi. Il Dice di ciascun caso è comunque sempre riportato, per rendere visibile se un miglioramento dipende da una sola condizione.

**Predizioni prima della ground truth.** In ogni esperimento tutte le predizioni sono state generate e salvate prima di caricare la ground truth, che è stata usata solo per valutare predizioni già fissate.

**Confronti controllati.** Gli esperimenti sono stati organizzati confrontando un numero limitato di varianti rispetto a una configurazione di riferimento. Quando possibile, il confronto tra configurazioni che differivano per un singolo blocco ha permesso di isolare l'effetto della modifica introdotta.

**Nessuna regola basata sulla posizione delle lesioni.** Poiché tutte le configurazioni pre-calcolate condividono la stessa ground truth msles2, già osservata durante lo sviluppo, non sono ammesse regole, regioni di interesse o intervalli di slice derivati dalla posizione delle lesioni (Sezione 2.3).

![Figura 5.1](../results/figures/report_ch5_timeline.png)

*Figura 5.1 – Cronologia dello sviluppo e dell'uso dei dati. Per ogni passo sono indicati i dati utilizzati e il loro stato: in blu le fasi di sviluppo, che usano solo dati già visti; in grigio i congelamenti e la definizione del protocollo; in verde il test prospettico originale della v3; in giallo lo studio di robustezza al carico lesionale; in arancione il test riservato finale della v4. I casi di test sono stati osservati per la prima volta solo nei passi 3 e 9; le simulazioni con seme 1 nel passo 4.*

## 5.2 Prima pipeline e scelta della modalità

Il primo tratto dello sviluppo ha costruito una pipeline di base completa, composta da maschera cerebrale, soglia e post-processing, e ha scelto la modalità su cui segmentare.

**Maschera cerebrale.** Sono stati valutati diversi approcci per isolare il cervello, prima sulla T2 e poi sulla T1: soglia di Otsu con pulizia morfologica, watershed, ricostruzione morfologica, rilevamento dei bordi con Canny e propagazione della maschera tra slice adiacenti. La soluzione adottata è la sequenza 3D di erosione, selezione della componente più grande e dilatazione descritta nella Sezione 3.3, verificata visivamente su tutte le slice nei tre piani.

**Soglia.** Sulla T2 all'interno della maschera cerebrale sono state confrontate tre soglie globali binarie: una soglia fissata manualmente, una soglia iterativa e la soglia di Otsu. Tutte hanno prodotto un Dice inferiore a 0,04, a causa della grande quantità di tessuto iperintenso non lesionale. Poiché l'istogramma della T2 mostrava più di due popolazioni di intensità, si è passati a una soglia multi-livello con `multithresh` a due livelli, considerando lesione la classe più alta; questa soluzione ha migliorato il punteggio ed è stata mantenuta. Una soglia locale, variabile nello spazio, è stata valutata e non mantenuta.

**Morfologia e componenti.** Un'apertura 2D ha ridotto in modo apprezzabile i falsi positivi; una chiusura successiva all'apertura ha peggiorato il risultato ed è stata scartata. Un filtro che rimuoveva le componenti 2D più piccole migliorava leggermente il punteggio, ma è stato **respinto** da un criterio di protezione delle piccole lesioni: eliminava completamente alcune sezioni di lesioni reali. La crescita di regione è stata considerata, ma non introdotta: il criterio adottato richiedeva la presenza di nuclei di lesione affidabili da cui far crescere la regione, mentre a questo stadio la predizione conteneva circa trenta falsi positivi per ogni vero positivo.

**Scelta della modalità.** T1, T2 e PD sono state confrontate singolarmente con la stessa architettura. La T2 è risultata nettamente la modalità migliore per identificare le lesioni (punteggio di sviluppo 0,057 contro 0,016 della PD e 0,004 della T1). Anche la combinazione T2 ∩ PD è stata valutata: rimuoveva soprattutto falsi positivi, ma anche alcuni voxel di lesione, e ha ottenuto un punteggio leggermente inferiore alla sola T2. È stata quindi mantenuta la T2, più semplice. La PD non è stata più utilizzata.

**Limite della pipeline di base.** A questo stadio il punteggio di sviluppo era circa 0,057: le lesioni erano in gran parte trovate, ma sepolte in decine di migliaia di falsi positivi. L'analisi degli errori ha mostrato che i falsi positivi erano dominati da strutture iperintense in T2 di tipo fluido, in particolare il liquor. Un'ottimizzazione congiunta di pre-filtraggio, numero di livelli della soglia, morfologia e filtro sulle componenti ha portato solo un miglioramento marginale (punteggio 0,058): le operazioni di pulizia rimuovevano solo una piccola frazione dei falsi positivi. Il problema non era la pulizia del risultato, ma la regione in cui la soglia veniva cercata.

## 5.3 Supporto anatomico S2 e versione v1

Per escludere il liquor e gli altri tessuti iperintensi non lesionali è stato introdotto un supporto anatomico ricavato dalla T1, nella quale il liquor è scuro (Sezione 3.4). L'esperimento ha confrontato tre supporti di complessità crescente:

- **S0**: la sola maschera cerebrale;
- **S1**: la maschera cerebrale privata della classe T1 bassa;
- **S2**: la regione T1 alta riempita, privata della classe T1 bassa.

I tre supporti sono stati valutati in combinazione con due soglie, entrambe ricalcolate all'interno del supporto: il livello TA di `multithresh` e la soglia di Otsu binaria, oltre alle varianti di morfologia e di filtro sulle componenti.

La configurazione migliore è risultata **S2 con il livello TA**, con un punteggio di sviluppo salito da 0,058 a 0,600: i falsi positivi su pn0 sono scesi da circa 66.000 a circa 1.200 voxel. La soglia di Otsu binaria è risultata peggiore del livello TA in tutte le combinazioni. Questa configurazione è stata congelata come **v1**.

Già in questa fase è emerso il limite strutturale di S2: circa l'11–13 % dei voxel di lesione cade fuori dal supporto e non può più essere recuperato (Capitolo 7).

## 5.4 Filtraggio della T2 e versione v2

La v1 risultava sensibilmente peggiore su pn3 che su pn0, cioè in presenza di rumore. Lo sviluppo è stato quindi esteso con un esperimento dedicato al rumore. La nuova versione sarebbe diventata la principale solo se strettamente migliore della v1.

L'esperimento ha combinato due fattori:

- **filtraggio**: nessun filtro, filtro gaussiano oppure diffusione anisotropa con parametri fissi, applicati alla T1, alla T2 o a entrambe;
- **recupero**: nessun recupero, oppure ricostruzione morfologica che espande i voxel segmentati dentro S2 o verso una regione più ampia.

Tutte le configurazioni con la T2 filtrata hanno superato la v1; filtrare la sola T1 ha dato risultati instabili. Entrambe le forme di recupero sono state respinte: la prima aggiungeva più falsi positivi che veri positivi, la seconda si espandeva in modo massiccio nel tessuto normale. La configurazione scelta, con la sola T2 filtrata per diffusione anisotropa slice per slice e senza recupero, è stata congelata come **v2** (punteggio di sviluppo 0,661).

Filtri lineari e non lineari di uso generale (gaussiano, mediano, a media mobile) erano già stati esplorati all'inizio del progetto sulla pipeline di base, senza essere mantenuti.

## 5.5 Pipeline v3 e congelamento

Un ultimo esperimento di sviluppo ha affinato la v2 su tre fattori:

- diffusione anisotropa applicata slice per slice (2D) oppure all'intero volume (3D);
- apertura assente, con elemento a diamante di raggio 1 oppure con elemento quadrato 3 × 3;
- presenza o assenza del filtro che rimuove le componenti 3D presenti in una sola slice.

In tutte le combinazioni l'elemento a diamante ha dato risultati migliori del quadrato, e il quadrato migliori dell'assenza di apertura; la diffusione 3D è risultata migliore di quella 2D. La configurazione scelta, con diffusione 3D, diamante di raggio 1 e nessun filtro sulle componenti, è la **v3**, con punteggio di sviluppo 0,690.

La v3 è stata congelata come versione principale per il test; v1 e v2 sono rimaste congelate come versioni secondarie di confronto. Il congelamento è stato verificato rigenerando le predizioni di sviluppo voxel per voxel a partire dal codice congelato.

## 5.6 Test prospettico originale della v3

Il test della v3 ha seguito il seguente protocollo:

1. verifica dell'integrità della versione congelata tramite le impronte SHA-256 del codice;
2. download dei volumi T1 e T2 di pn1, pn5, pn7 e pn9, mai utilizzati durante lo sviluppo;
3. generazione e salvataggio delle predizioni della v3 e delle versioni secondarie v1 e v2, prima di caricare la ground truth;
4. valutazione con le metriche del Capitolo 4, eseguita una sola volta.

Non era stata fissata alcuna soglia di successo o fallimento: i risultati sono stati riportati così come osservati. La v3 era la versione principale scelta al termine dello sviluppo, e il risultato del test non ha modificato questa designazione né alcun parametro. I risultati sono riportati nella Sezione 6.1.

Il test misura la robustezza della pipeline a livelli di rumore non visti sullo stesso phantom msles2: non misura la generalizzazione a nuove anatomie o a nuove lesioni.

## 5.7 Studio di ablazione

Per quantificare il contributo di ciascun blocco della v3 è stato condotto uno **studio di ablazione retrospettivo**, basato esclusivamente sui risultati di sviluppo già salvati: nessuna nuova predizione, nessun dato di test.

Ogni configurazione valutata durante lo sviluppo è stata descritta dai blocchi che la compongono (supporto, filtro, dimensionalità del filtro, morfologia, regola sulle componenti, recupero). Un confronto tra due configurazioni è stato considerato un'**ablazione controllata** solo se le due configurazioni differivano esattamente in un blocco, condizione verificata automaticamente. In questo modo sono stati individuati dodici confronti controllati, e il percorso di sviluppo dalla prima soglia multi-livello alla v3 è risultato una catena di sette modifiche di un solo blocco ciascuna.

Ogni contributo è misurato nel contesto dei blocchi già presenti in quel momento: i contributi non sono quindi additivi, e l'effetto di un blocco può cambiare se cambiano gli altri. I risultati sono riportati nella Sezione 6.2.

## 5.8 Robustezza al rumore

La robustezza al rumore è stata valutata confrontando le prestazioni della pipeline sui sei livelli di rumore del database pre-calcolato, mantenendo fissi phantom, risoluzione e disomogeneità di intensità.

- **v3**: pn1, pn5, pn7 e pn9 costituiscono il test prospettico originale (Sezione 5.6); pn0 e pn3 sono riportati come riferimento di sviluppo, esplicitamente distinti dai punti di test. Il confronto controllato tra v1 e v2, che differiscono solo per il filtraggio, mostra inoltre l'effetto del filtro al variare del rumore.
- **v4**: dopo il suo congelamento la v4 è stata applicata agli stessi livelli di rumore come analisi secondaria. Questi casi erano già stati osservati durante il test della v3, quindi i risultati della v4 su di essi sono riportati come **dati visti**, non come test indipendente.

I risultati sono riportati nella Sezione 6.3.

## 5.9 Robustezza al carico lesionale

Il database pre-calcolato contiene un solo carico lesionale. Per valutare l'effetto del carico lesionale sono state usate le simulazioni personalizzate con seme 1 (Sezione 2.6): i tre phantom msles1, msles2 e msles3, con impostazioni identiche e rumore 0 %, in modo che l'unica differenza fosse la quantità di lesioni.

La v3 congelata è stata applicata senza modifiche ai tre phantom, dopo il test prospettico. Lo studio misura il comportamento della pipeline al variare di un carico lesionale simulato sulla stessa anatomia, non la generalizzazione a nuovi pazienti. I risultati sono riportati nella Sezione 6.4.

## 5.10 Analisi del fallimento della v3

Lo studio del carico lesionale ha rivelato un difetto della v3 che il test prospettico non poteva mostrare, perché tutte le configurazioni pre-calcolate hanno lo stesso carico moderato. Sul phantom con carico lieve la v3 ha predetto 29.301 voxel di lesione a fronte di 422 voxel reali: una sovrasegmentazione massiccia, a fronte di risultati coerenti con lo sviluppo sui carichi moderato e grave.

Per capirne la causa, prima di modificare l'algoritmo è stata condotta una diagnostica sui soli dati di sviluppo, che ha esaminato la distribuzione della T2 filtrata all'interno di S2 separatamente per ciascun tessuto della ground truth. Ne sono emersi tre elementi:

- nel caso lieve i due livelli di `multithresh` risultano molto vicini (0,433 e 0,469, contro 0,443 e 0,562 nel caso moderato);
- il livello TA cade all'interno della distribuzione della sostanza grigia: circa il 57 % della sostanza grigia contenuta in S2 supera la soglia, contro una quota compresa tra lo 0,4 % e il 4 % negli altri casi di sviluppo;
- la distribuzione della T2 nella regione T1 alta (WM-like) di S2 risulta invece stabile tra i casi e si calcola senza alcuna informazione della ground truth.

![Figura 5.2](../results/figures/report_ch5_mild_load_diagnostic.png)

*Figura 5.2 – Distribuzione della T2 filtrata all'interno di S2, separata per tessuto della ground truth, nei cinque casi di sviluppo della v4; le curve sono normalizzate per tessuto e le linee verticali indicano i due livelli di `multithresh` (tratteggiata: primo livello; continua: livello TA). Nei casi con carico moderato e grave il livello TA si trova sopra la distribuzione della sostanza grigia; nel caso lieve (msles1) cade al suo interno, e una larga parte della sostanza grigia supera la soglia. I tessuti con meno di 100 voxel in S2, come il liquor in pn0 e pn3, non sono disegnati. La ground truth è usata solo per questa diagnostica, mai dalla segmentazione.*

L'interpretazione è che la regola "la classe più alta di `multithresh` è lesione" funziona quando le lesioni formano una popolazione di intensità distinta, ma diventa inaffidabile quando le lesioni sono poche: in quel caso `multithresh` divide comunque l'istogramma in tre classi, e la classe più alta finisce per contenere tessuto normale. La stessa diagnostica ha mostrato che un indice di separabilità delle classi non distingueva il caso problematico, e non poteva quindi essere usato come controllo.

## 5.11 Sviluppo della v4

Per correggere il difetto è stata aperta una nuova fase di sviluppo successiva al test della v3.

Sono stati utilizzati i seguenti criteri:

- la v3 restava il risultato del test prospettico originale;
- i dati di sviluppo della v4 erano pn0, pn3 e le simulazioni con seme 1 (msles1, msles2, msles3); pn1, pn5, pn7 e pn9, già osservati, non sono stati usati per progettare la v4;
- un nuovo insieme di test è stato mantenuto separato dallo sviluppo della v4 ed è stato generato soltanto dopo il congelamento della nuova versione (Sezione 5.13);
- è stata valutata un'unica famiglia di regole derivata dall'analisi del fallimento della v3.

**Esperimento.** La regola valutata è la soglia minima descritta nella Sezione 3.7:

$$ T = \max\left(T_{TA2},\ \mu_{ref} + k\,\sigma_{ref}\right) $$

con $k \in \{3, 4, 5, 6\}$, più la configurazione senza soglia minima, che riproduce la v3 voxel per voxel e fa da riferimento.

**Criterio di scelta:**

- obiettivo: Dice medio sui cinque casi di sviluppo;
- vincolo di non inferiorità: su pn0, pn3, msles2 e msles3 il Dice non può peggiorare di più di 0,01 rispetto alla v3;
- la v4 corrisponde al valore di k ammissibile con l'obiettivo più alto, purché strettamente migliore della v3.

**Esito.** Il valore k = 6 è stato escluso dal vincolo di non inferiorità, perché peggiorava il Dice del caso grave di circa 0,018. Il valore **k = 5** è risultato ammissibile e con l'obiettivo più alto (Dice medio di sviluppo 0,631 contro 0,569 della v3). Con k = 5 la soglia minima supera il livello TA in tutti i casi di sviluppo: sul caso lieve i voxel predetti passano da 29.301 a 269.

![Figura 5.3](../results/figures/report_ch5_k_selection.png)

*Figura 5.3 – Scelta del coefficiente k della soglia minima $\mu_{ref} + k\,\sigma_{ref}$ sui cinque casi di sviluppo (valori in-sample). (a) Dice di ciascun caso: il caso lieve migliora nettamente da k = 5, mentre gli altri casi restano stabili o migliorano; con k = 6 il caso grave peggiora. (b) Dice medio, l'obiettivo del criterio di scelta: k = 6 è escluso dal vincolo di non inferiorità e k = 5, ammissibile e con l'obiettivo più alto, è il valore scelto.*

Questi valori sono in-sample: il caso lieve che ha rivelato il difetto fa parte dei dati di sviluppo e k è stato scelto sugli stessi dati. Il comportamento su dati nuovi, e in particolare su un cervello senza lesioni, poteva essere valutato solo con il test riservato.

## 5.12 Studio dell'isteresi

Dopo il congelamento della v4, lo studio è stato esteso ai nove casi già osservati: le sei configurazioni pn0, pn1, pn3, pn5, pn7 e pn9 e le tre simulazioni con seme 1. L'obiettivo era verificare se fosse possibile recuperare parte della sensibilità persa dalla v4 senza reintrodurre i falsi positivi. Tutti i risultati su questi casi sono in-sample.

È stata valutata una **segmentazione a isteresi**, realizzata con ricostruzione morfologica 3D: i voxel della v4 fungono da nuclei, che possono espandersi verso i voxel connessi la cui intensità supera una seconda soglia più bassa ($\mu_{ref} + 4\sigma_{ref}$ oppure $\mu_{ref} + 3\sigma_{ref}$), all'interno di S2 oppure di una regione più ampia, con e senza l'apertura finale.

Nessuna delle configurazioni ha superato la v4 sul Dice medio dei nove casi. L'espansione migliorava i casi con rumore elevato, dove la v4 è più conservativa, ma a basso rumore e con carico lieve si estendeva nel tessuto normale. L'intensità di espansione utile dipendeva quindi dalla condizione di acquisizione; sceglierla per livello di rumore sugli stessi casi avrebbe significato ottimizzare il metodo sui dati di valutazione. L'isteresi non è stata quindi mantenuta e, a questo punto, lo sviluppo è stato chiuso definitivamente.

## 5.13 Congelamento della v4 e test riservato

La v4 è stata congelata prima della generazione dei dati del test riservato. Il protocollo di valutazione prevedeva:

- **dati**: phantom normale con rumore 0 % e 3 %, msles1 e msles3 con rumore 3 %, template AI, seme 2 (Sezione 2.6);
- **versioni**: v4 come versione principale e v3 come riferimento, entrambe congelate e non modificabili durante il test;
- **ordine**: tutte le predizioni sono state generate e salvate prima di caricare qualsiasi ground truth;
- **phantom normale**: verifica che la relativa ground truth non contenesse lesioni;
- **metriche**: per i phantom con lesioni sono state utilizzate le metriche voxel-wise, volumetriche e lesion-wise del Capitolo 4; per il phantom normale sono stati riportati i voxel predetti, tutti falsi positivi, il numero di componenti false, la frazione di falsi positivi rispetto alla maschera cerebrale e a S2 e la Specificity, senza Dice, IoU, Precision, Recall ed errore volumetrico (Sezione 4.9);
- **interpretazione**: i risultati sono stati riportati così come osservati;
- **versione finale**: la v4 non è stata modificata dopo il test.

Dopo il congelamento della pipeline sono stati richiesti a BrainWeb i dati del test e la valutazione è stata eseguita una sola volta. Il test riservato è l'evidenza principale per la v4: è l'unico insieme di dati mai osservato durante il suo sviluppo. I risultati sono riportati nella Sezione 6.5.

## 5.14 Congelamento e riproducibilità

Il progetto è stato organizzato in modo che ogni risultato riportato possa essere ricondotto ai file da cui deriva e riprodotto.

- **Versioni congelate**: al congelamento di ogni versione sono state registrate le impronte SHA-256 del codice di segmentazione e dei risultati di riferimento. Prima e dopo i test le impronte sono state ricontrollate, per verificare che il codice valutato fosse esattamente quello congelato.
- **Dati e risultati**: i file di ingresso e i risultati di ogni studio sono elencati in file *manifest* con le relative impronte (Sezione 2.8).
- **Riproduzione automatica**: un unico script esegue le versioni congelate v3 e v4 su tutti i tredici casi del progetto (sei configurazioni pre-calcolate, tre simulazioni con seme 1 e quattro casi del test riservato) e ne calcola le metriche. Tutte le 26 combinazioni riproducono voxel per voxel le predizioni salvate durante gli esperimenti originali e gli stessi conteggi TP, FP, FN e TN. Questa riproduzione è una verifica di riproducibilità, non una nuova validazione.
- **Congelamento dei risultati finali**: le sorgenti dei risultati usati nella relazione e le tabelle e figure derivate da esse sono state congelate con due elenchi di impronte separati, in modo che ogni tabella e figura finale sia riconducibile ai risultati originali da cui è stata ottenuta.
- **Validazione delle metriche**: le funzioni di valutazione sono state verificate su casi artificiali con risultato noto (Capitolo 4).
