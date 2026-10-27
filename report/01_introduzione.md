# 1. Introduzione

## 1.1 Contesto e motivazioni

La sclerosi multipla (SM) è una malattia del sistema nervoso centrale che produce lesioni, in larga parte localizzate nella sostanza bianca del cervello. La risonanza magnetica (MRI) è lo strumento di imaging di riferimento per osservarle: nelle immagini pesate in T2 le lesioni appaiono come regioni più chiare, iperintense, rispetto alla sostanza bianca circostante.

Individuare e delimitare le lesioni, cioè **segmentarle**, permette di misurarne il numero, la posizione e il volume. Eseguita manualmente, questa operazione richiede di esaminare il volume slice per slice, è lunga e dipende dall'esperienza di chi la svolge: annotatori diversi possono tracciare contorni diversi della stessa lesione. Una segmentazione **automatica** offre invece un risultato ripetibile e veloce, che può essere misurato e confrontato in modo oggettivo.

Questo progetto affronta la segmentazione automatica delle lesioni di SM come problema di elaborazione delle immagini, su dati simulati con ground truth nota, con l'obiettivo di costruire una pipeline funzionante e di misurarne con rigore pregi e limiti.

## 1.2 Segmentazione delle lesioni di sclerosi multipla

La segmentazione delle lesioni di SM è un problema difficile per diverse ragioni.

- **Dimensioni ridotte.** Molte lesioni occupano pochi voxel. Una lesione di pochi voxel è difficile da distinguere dal rumore e può essere eliminata da qualsiasi operazione di pulizia del risultato.
- **Contrasto variabile.** L'intensità delle lesioni non è uniforme: alcune sono molto più chiare della sostanza bianca, altre poco. Le parti periferiche sfumano gradualmente nel tessuto circostante, e il bordo della lesione non è netto.
- **Somiglianza con tessuti normali.** Nelle immagini T2 non sono solo le lesioni a essere chiare: anche il liquor, che riempie i ventricoli e i solchi, è iperintenso, spesso quanto o più delle lesioni. Una soglia sull'intensità, da sola, non distingue le lesioni dal liquor.
- **Rumore.** Il rumore di acquisizione allarga le distribuzioni di intensità dei tessuti e ne aumenta la sovrapposizione, rendendo meno affidabile qualsiasi soglia.
- **Sbilanciamento tra le classi.** Le lesioni rappresentano una frazione minima del volume: nel phantom moderato msles2, ad esempio, costituiscono circa lo 0,05 % dei voxel. Questo rende facile ottenere metriche apparentemente ottime anche con segmentazioni scadenti, e richiede una scelta attenta delle metriche di valutazione.
- **Carico lesionale variabile.** Il numero e il volume delle lesioni variano molto da caso a caso. Un metodo che funziona quando le lesioni sono numerose può comportarsi in modo molto diverso quando sono poche o assenti.

## 1.3 Approccio del progetto

Il progetto utilizza esclusivamente **tecniche classiche di elaborazione delle immagini**: soglie automatiche basate sull'istogramma, filtraggio, operazioni morfologiche, analisi delle componenti connesse ed elaborazione 2D e 3D dei volumi. Non vengono usati metodi di apprendimento automatico o di deep learning. Il metodo non richiede quindi dati di addestramento, e ogni suo blocco ha un ruolo esplicito e verificabile.

Il lavoro si basa sul database simulato **BrainWeb**, che fornisce volumi MRI con una ground truth esatta e consente di variare in modo controllato il livello di rumore e il carico lesionale. Lo sviluppo è stato organizzato secondo un protocollo sperimentale in cui le predizioni sono state generate prima di caricare la ground truth, le versioni valutate sono state congelate prima dei test e la valutazione finale è stata eseguita su dati mai osservati durante lo sviluppo della v4.

Il metodo è stato costruito in versioni successive. Una prima versione (v3) è stata sottoposta a un test prospettico su livelli di rumore mai visti; uno studio successivo sul carico lesionale ne ha rivelato un difetto con carico lieve, e la versione finale (v4) è stata progettata per correggerlo e verificata su un test riservato indipendente dallo sviluppo della v4.

## 1.4 Obiettivi

Gli obiettivi del progetto sono:

- realizzare una **segmentazione completamente automatica** delle lesioni di SM in volumi MRI 3D, con soglie stimate dai dati e senza interventi manuali;
- **valutare quantitativamente** le predizioni rispetto alla ground truth, con metriche voxel-wise sull'intero volume e con un'analisi a livello di singola lesione;
- studiare il comportamento della pipeline al variare del **rumore** e del **carico lesionale**, mettendone in evidenza sia i punti di forza sia i modi di errore;
- quantificare il contributo dei singoli blocchi della pipeline;
- produrre **visualizzazioni 2D e 3D** delle predizioni, della ground truth e degli errori;
- garantire che tutti i risultati siano **riproducibili** e riconducibili ai dati e al codice da cui derivano.

## 1.5 Struttura della relazione

La relazione è organizzata come segue.

- Il **Capitolo 2** descrive il dataset BrainWeb, i volumi utilizzati, le configurazioni di rumore e di carico lesionale, e l'organizzazione dei dati tra sviluppo e test.
- Il **Capitolo 3** descrive la pipeline finale: maschera cerebrale, supporto anatomico, filtraggio, soglia e post-processing.
- Il **Capitolo 4** definisce le metriche di valutazione.
- Il **Capitolo 5** ricostruisce il protocollo sperimentale e il percorso di sviluppo che ha portato alla versione finale.
- Il **Capitolo 6** riporta i risultati: test prospettico, studio di ablazione, robustezza al rumore e al carico lesionale, test riservato finale e visualizzazioni 2D e 3D.
- Il **Capitolo 7** discute i risultati, analizza i falsi positivi e i falsi negativi e ne descrive i limiti.
- Il **Capitolo 8** riassume i risultati raggiunti e indica i possibili sviluppi futuri.
