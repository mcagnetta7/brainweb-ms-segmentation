# 4. Metodologia di valutazione

Questo capitolo definisce come le predizioni della pipeline sono confrontate con la ground truth. Tutte le metriche sono calcolate da funzioni dedicate, separate dalla segmentazione e verificate su casi artificiali con risultato noto prima di essere applicate ai dati BrainWeb. La ground truth interviene **solo in questa fase**, dopo che la predizione è stata generata.

In tutto il capitolo $M_{pred}$ indica la maschera binaria predetta e $M_{GT} = (\text{label} = 10)$ la maschera delle lesioni della ground truth (Sezione 2.3). Entrambe sono volumi logici di 181 × 217 × 181 voxel definiti sulla stessa griglia.

## 4.1 Matrice di confusione voxel-wise

Il confronto di base è voxel per voxel. Ogni voxel del volume cade in una e una sola delle quattro categorie:

| | $M_{GT} = 1$ (lesione) | $M_{GT} = 0$ (non lesione) |
|---|---|---|
| **$M_{pred} = 1$** | **TP** – vero positivo | **FP** – falso positivo |
| **$M_{pred} = 0$** | **FN** – falso negativo | **TN** – vero negativo |

In termini di insiemi:

$$ TP = |M_{pred} \cap M_{GT}|, \qquad FP = |M_{pred} \cap \neg M_{GT}| $$

$$ FN = |\neg M_{pred} \cap M_{GT}|, \qquad TN = |\neg M_{pred} \cap \neg M_{GT}| $$

I quattro conteggi sono disgiunti e la loro somma è sempre pari al numero totale di voxel del volume, 7.109.137. Tutte le metriche voxel-wise delle sezioni seguenti sono calcolate a partire da questi quattro numeri.

![Figura 4.1](../results/figures/report_ch4_confusion_example.png)

*Figura 4.1 – Esempio di matrice di confusione voxel-wise su un caso artificiale 3 × 3: (a) ground truth, (b) predizione, (c) categoria di ogni voxel, con veri positivi in verde, falsi positivi in rosso, falsi negativi in blu e veri negativi in grigio. Si ottengono TP = 2, FP = 1, FN = 1 e TN = 5, da cui Dice = 2/3, IoU = 1/2, Precision = 2/3, Recall = 2/3 e Specificity = 5/6. Gli stessi colori sono usati nelle figure dei risultati.*

## 4.2 Dice coefficient

Il **coefficiente di Dice** [Dice, 1945] misura la sovrapposizione tra predizione e ground truth:

$$ Dice = \frac{2\,TP}{2\,TP + FP + FN} = \frac{2\,|M_{pred} \cap M_{GT}|}{|M_{pred}| + |M_{GT}|} $$

Vale 1 se le due maschere coincidono e 0 se non hanno alcun voxel in comune. Il Dice non dipende dai veri negativi, quindi non è influenzato dalla grande quantità di voxel di sfondo e di tessuto sano. Per questo motivo è la **metrica principale** del progetto: è la metrica usata per confrontare le configurazioni durante lo sviluppo (Capitolo 5) e la prima riportata nei risultati.

## 4.3 Intersection over Union

L'**Intersection over Union** (IoU, o indice di Jaccard) è il rapporto tra l'intersezione e l'unione delle due maschere:

$$ IoU = \frac{TP}{TP + FP + FN} = \frac{|M_{pred} \cap M_{GT}|}{|M_{pred} \cup M_{GT}|} $$

Anche l'IoU ignora i veri negativi. Dice e IoU sono legati da una relazione monotona:

$$ IoU = \frac{Dice}{2 - Dice} $$

quindi ordinano sempre le predizioni allo stesso modo; l'IoU è numericamente più severo, perché penalizza maggiormente gli errori. È riportato come metrica complementare al Dice.

## 4.4 Precision

La **Precision** indica quale frazione dei voxel predetti come lesione è effettivamente lesione:

$$ Precision = \frac{TP}{TP + FP} $$

Una Precision bassa segnala una **sovrasegmentazione**: la pipeline etichetta come lesione molto tessuto che non lo è. È la metrica più sensibile ai falsi positivi ed è quella che, nei risultati, distingue più chiaramente i casi in cui la segmentazione si espande nel tessuto normale.

## 4.5 Recall / Sensitivity

La **Recall** (o *sensitivity*) indica quale frazione dei voxel di lesione della ground truth è stata trovata:

$$ Recall = \frac{TP}{TP + FN} $$

Una Recall bassa segnala una **sotto-segmentazione**: parti delle lesioni, o lesioni intere, non vengono rilevate.

Precision e Recall descrivono i due tipi di errore separatamente e tendono a muoversi in direzioni opposte: una soglia più permissiva aumenta la Recall e riduce la Precision, una più severa fa il contrario. Il Dice, che può essere scritto come media armonica di Precision e Recall, riassume il bilanciamento tra i due. Nella discussione dei risultati le tre metriche sono sempre lette insieme, perché lo stesso Dice può nascondere comportamenti molto diversi.

## 4.6 Specificity

La **Specificity** indica quale frazione dei voxel non di lesione è stata correttamente classificata come tale:

$$ Specificity = \frac{TN}{TN + FP} $$

Nel problema in esame questa metrica va interpretata con molta cautela a causa del forte **sbilanciamento tra le classi**. Nel phantom msles2 i voxel di lesione sono 3.512 su 7.109.137, cioè circa lo 0,05 % del volume, mentre i voxel negativi sono 7.105.625. Il denominatore della Specificity è quindi enorme e la metrica resta vicina a 1 anche in presenza di errori gravi:

- una predizione completamente vuota, che non trova alcuna lesione, ha Specificity pari a 1;
- nel test riservato, la v3 applicata al phantom normale senza rumore predice 31.917 voxel di lesione inesistenti, eppure la sua Specificity vale 0,9955.

La sola Specificity non è quindi in grado di distinguere una buona segmentazione da una pessima. Viene riportata per completezza e perché, nel phantom normale, è una delle poche metriche definite, ma l'analisi si basa su Dice, IoU, Precision e Recall e sui conteggi assoluti di FP e FN.

Il calcolo dei veri negativi è fatto sull'**intero volume**, comprese le regioni esterne al cervello, senza restringerlo alla maschera cerebrale: in questo modo la definizione non dipende da una maschera prodotta dalla pipeline stessa.

## 4.7 Volume della lesione ed errore volumetrico

Il volume di una maschera binaria è calcolato come numero di voxel positivi per il volume del singolo voxel. Con voxel isotropi da 1 mm il volume del voxel è 1 mm³, quindi il volume in mm³ coincide numericamente con il numero di voxel:

$$ V = |M| \times (1 \times 1 \times 1)\ \text{mm}^3 $$

L'**errore volumetrico percentuale** confronta il volume predetto con quello della ground truth:

$$ \text{Volume Error}\,\% = \frac{|V_{pred} - V_{GT}|}{V_{GT}} \times 100 $$

La metrica formale è **assoluta**: non distingue tra sovrastima e sottostima. La differenza con segno $V_{pred} - V_{GT}$ è riportata separatamente, solo a scopo descrittivo, per indicare la direzione dell'errore. I valori superiori al 100 % sono possibili e non vengono troncati: indicano che la differenza assoluta tra volume predetto e volume reale supera il volume reale stesso.

L'errore volumetrico misura soltanto la quantità di lesione stimata, non la sua posizione. Una predizione può avere un errore volumetrico vicino a zero ed essere comunque sbagliata, se i voxel predetti si trovano nel posto sbagliato. Per questo l'errore volumetrico è sempre letto insieme alle metriche di sovrapposizione.

## 4.8 Analisi lesion-wise

Le metriche voxel-wise sono dominate dalle lesioni più grandi: una lesione di qualche migliaio di voxel pesa sul Dice molto più di dieci lesioni di pochi voxel. Per valutare quante lesioni vengono effettivamente individuate, il progetto affianca alle metriche voxel-wise un'**analisi lesion-wise**, a livello di oggetto.

**Definizione degli oggetti.** Le lesioni della ground truth e le regioni predette sono definite come **componenti connesse 3D con connettività 26**, calcolate sull'intero volume: due voxel appartengono alla stessa componente se condividono una faccia, uno spigolo o un vertice. Nessuna componente viene rimossa, unita o filtrata per dimensione.

**Criterio di corrispondenza.** Una lesione della ground truth e una componente predetta si considerano corrispondenti se condividono **almeno un voxel**. Il criterio è stato fissato prima di osservare qualsiasi risultato lesion-wise, proprio per evitare di scegliere a posteriori una soglia di sovrapposizione arbitraria. Le relazioni possono essere molti-a-molti: una componente predetta può toccare più lesioni e una lesione può essere toccata da più componenti.

Da questo criterio derivano le grandezze riportate:

| Grandezza | Definizione |
|---|---|
| lesione rilevata | lesione della ground truth toccata da almeno una componente predetta |
| lesione mancata | lesione della ground truth non toccata da alcuna componente predetta |
| componente falsa | componente predetta che non tocca alcuna lesione della ground truth |

**Limite del criterio.** Poiché basta un solo voxel in comune, una lesione "rilevata" **non è necessariamente segmentata bene**: può essere coperta solo in minima parte. Il numero di lesioni rilevate indica quante lesioni la pipeline ha almeno toccato, non quanto bene le ha delineate. Per la stessa ragione, una predizione che si espande nel tessuto circostante può aumentare il numero di lesioni rilevate per semplice contatto casuale, pur peggiorando la segmentazione. L'analisi lesion-wise è quindi usata come diagnostica, sempre insieme alle metriche voxel-wise e mai da sola.

Non sono state calcolate metriche a livello di oggetto più restrittive, come un Dice per singola lesione o distanze tra i contorni.

![Figura 4.2](../results/figures/report_ch4_lesionwise_example.png)

*Figura 4.2 – Esempio artificiale del criterio lesion-wise (componenti connesse 26, corrispondenza con almeno un voxel in comune). La lesione 1 risulta rilevata anche se la predizione ne copre un solo voxel su 36; la lesione 2 è rilevata e coperta interamente; la lesione 3 non è toccata da alcuna predizione ed è mancata; la componente a destra non tocca alcuna lesione ed è una componente falsa. Le lesioni rilevate sono quindi 2 su 3 nonostante gran parte del volume lesionale non sia segmentato (39 voxel di falsi negativi), a dimostrazione del fatto che "rilevata" non significa "segmentata bene".*

## 4.9 Valutazione sull'intero volume 3D

Tutte le metriche principali sono calcolate **sul volume completo**: i quattro conteggi TP, FP, FN e TN vengono accumulati su tutti i 7.109.137 voxel e le metriche sono calcolate una sola volta a partire da questi totali. Non sono calcolate come media dei valori ottenuti sulle singole slice.

La distinzione è importante. Una media per slice darebbe lo stesso peso a una slice con due voxel di lesione e a una con duecento, e richiederebbe una regola arbitraria per le molte slice senza lesioni, nelle quali Dice, Precision e Recall non sono informativi. Il calcolo sul volume completo pesa invece ogni voxel allo stesso modo e corrisponde direttamente alla natura tridimensionale delle lesioni.

Metriche slice per slice sono state calcolate solo come **strumento diagnostico**, per individuare lungo l'asse assiale dove si concentrano gli errori; non sono mai state mediate né usate per scegliere tra configurazioni. È stato verificato che la somma dei conteggi delle singole slice riproduce esattamente i conteggi del volume completo.

**Casi senza lesioni.** Nel phantom normale del test riservato la ground truth non contiene alcun voxel di lesione, e alcune metriche perdono significato:

- il Dice e l'IoU valgono 0 per qualsiasi predizione non vuota, indipendentemente dal fatto che i falsi positivi siano trenta o trentamila;
- la Precision vale 0 per lo stesso motivo;
- la Recall ha denominatore nullo;
- l'errore volumetrico percentuale non è definito, perché $V_{GT} = 0$.

Per questi casi il protocollo di valutazione, fissato prima di generare i dati, prevede di **non riportare** Dice, IoU, Precision, Recall ed errore volumetrico, che nelle tabelle compaiono come valori non disponibili. Si riportano invece le grandezze che descrivono direttamente il comportamento della pipeline in assenza di lesioni: il numero di voxel predetti, che coincidono tutti con falsi positivi, il numero di componenti false, la frazione di falsi positivi rispetto alla maschera cerebrale e a S2, e la Specificity.

**Precisione dei valori.** Tutte le metriche sono conservate a piena precisione nei file dei risultati; l'arrotondamento è applicato soltanto nelle tabelle di presentazione della relazione.
