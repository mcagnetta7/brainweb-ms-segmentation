# 6. Risultati

Questo capitolo riporta i risultati degli studi descritti nel Capitolo 5. Il commento è limitato a ciò che i numeri e le figure mostrano direttamente; l'interpretazione dei risultati, le cause degli errori e i limiti sono discussi nel Capitolo 7.

I risultati appartengono a tre gruppi di evidenza diversi (Sezione 2.7), che sono sempre indicati esplicitamente e non vengono mai mescolati in una stessa media:

- **test prospettico originale** della v3 (pn1, pn5, pn7, pn9);
- **dati visti** durante lo sviluppo, cioè risultati *in-sample*;
- **test riservato finale** della v4 (seme 2), che è l'evidenza principale per la versione finale.

Tutte le metriche sono calcolate sul volume completo (Capitolo 4). Nelle tabelle Dice, IoU, Precision e Recall sono arrotondati a tre decimali, la Specificity a cinque e l'errore volumetrico a una cifra decimale; i valori a piena precisione sono conservati nei file dei risultati. Le medie riportate sono solo descrittive e calcolate all'interno di un singolo gruppo.

## 6.1 Risultati del test prospettico originale della v3

La Tabella 6.1 riporta i risultati della v3 sui quattro livelli di rumore mai osservati durante il suo sviluppo.

*Tabella 6.1 – Test prospettico originale della v3 (msles2, 3.512 voxel di lesione).*

| Caso | Rumore | Dice | IoU | Precision | Recall | Specificity | Errore vol. | Predetti | TP | FP | FN |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pn1 | 1 % | 0,692 | 0,529 | 0,659 | 0,729 | 0,99981 | 10,7 % | 3.887 | 2.561 | 1.326 | 951 |
| pn5 | 5 % | 0,715 | 0,556 | 0,748 | 0,685 | 0,99989 | 8,4 % | 3.217 | 2.405 | 812 | 1.107 |
| pn7 | 7 % | 0,408 | 0,256 | 0,280 | 0,750 | 0,99905 | 167,6 % | 9.399 | 2.633 | 6.766 | 879 |
| pn9 | 9 % | 0,409 | 0,257 | 0,292 | 0,680 | 0,99919 | 132,4 % | 8.162 | 2.387 | 5.775 | 1.125 |

Ai livelli di rumore 1 % e 5 % la v3 ottiene un Dice di 0,692 e 0,715, coerente con i valori di sviluppo (0,685 su pn0 e 0,694 su pn3). Ai livelli 7 % e 9 % il Dice scende a circa 0,41. La Recall resta compresa tra 0,68 e 0,75 su tutti e quattro i livelli, mentre la Precision scende da 0,66–0,75 a 0,28–0,29: i falsi positivi aumentano da circa 800–1.300 a circa 5.800–6.800 voxel e il volume predetto supera di oltre il doppio quello reale. L'andamento non è graduale: il valore migliore si ottiene a pn5 e il calo avviene tra il 5 % e il 7 %.

*Tabella 6.2 – Analisi lesion-wise del test prospettico della v3 (59 lesioni nella ground truth; criterio "almeno un voxel in comune").*

| Caso | Lesioni rilevate | Lesioni mancate | Componenti predette | Componenti false |
|---|---:|---:|---:|---:|
| pn1 | 32 | 27 | 41 | 9 |
| pn5 | 24 | 35 | 32 | 3 |
| pn7 | 41 | 18 | 127 | 86 |
| pn9 | 44 | 15 | 143 | 102 |

A pn7 e pn9 il numero di lesioni "rilevate" aumenta, insieme a un forte aumento delle componenti false: come discusso nella Sezione 4.8, un conteggio di lesioni rilevate più alto non indica qui una segmentazione migliore.

**Versioni secondarie.** Nello stesso test sono state valutate anche le versioni v1 e v2, congelate prima del test come termini di confronto (Tabella 6.3).

*Tabella 6.3 – Dice delle tre versioni congelate sul test prospettico.*

| Caso | v1 | v2 | v3 (principale) |
|---|---:|---:|---:|
| pn1 | 0,661 | 0,670 | 0,692 |
| pn5 | 0,412 | 0,662 | 0,715 |
| pn7 | 0,562 | 0,425 | 0,408 |
| pn9 | 0,561 | 0,456 | 0,409 |
| media descrittiva | 0,549 | 0,553 | 0,556 |

Sul test le tre versioni hanno medie molto vicine, mentre in sviluppo i loro punteggi erano 0,600, 0,661 e 0,690. Ciascuna versione peggiora a un livello di rumore diverso: la v1, senza filtraggio, già a pn5; la v2 e la v3, con la T2 filtrata, a pn7 e pn9.

## 6.2 Risultati dello studio di ablazione

Lo studio di ablazione (Sezione 5.7) usa solo risultati di sviluppo su pn0 e pn3; tutti i valori sono quindi in-sample. La Tabella 6.4 riporta i confronti controllati principali, nei quali le due configurazioni differiscono per un solo blocco.

*Tabella 6.4 – Contributo dei singoli blocchi (variazione del punteggio di sviluppo, media del Dice su pn0 e pn3).*

| Blocco modificato | Contesto | Punteggio prima → dopo | Variazione |
|---|---|---:|---:|
| Supporto: S0 → S2 | soglia TA, apertura quadrata, G1 | 0,058 → 0,600 | **+0,542** |
| di cui S0 → S1 (esclusione della classe T1 bassa) | | 0,058 → 0,402 | +0,344 |
| di cui S1 → S2 (regione T1 alta riempita) | | 0,402 → 0,600 | +0,198 |
| Morfologia: nessuna → diamante | dopo il filtraggio 3D | 0,560 → 0,690 | **+0,130** |
| Filtraggio della T2: nessuno → anisotropo 2D | base v1 | 0,600 → 0,661 | **+0,061** |
| Morfologia: quadrato 3 × 3 → diamante | dopo il filtraggio 3D | 0,661 → 0,690 | +0,029 |
| Apertura: nessuna → quadrato 3 × 3 | prima di S2 | 0,042 → 0,057 | +0,015 |
| Filtro sulle componenti di una slice: presente → assente | dopo filtraggio 3D e diamante | 0,688 → 0,690 | +0,002 |
| Filtraggio: 2D → 3D | apertura quadrata, G1 | 0,661 → 0,663 | +0,001 |
| Filtro sulle componenti di una slice: introduzione | prima di S2 | 0,057 → 0,058 | +0,001 |
| Recupero dentro S2 | base v2 | 0,661 → 0,563 | −0,098 |
| Recupero verso una regione più ampia | base v2 | 0,661 → 0,035 | −0,626 |

Il supporto anatomico S2 è di gran lunga il contributo maggiore: riduce i falsi positivi su pn0 e pn3 da 66.484 e 63.126 voxel a 1.167 e 3.123. Seguono la morfologia dopo il filtraggio 3D e il filtraggio anisotropo della T2. Il passaggio dal filtraggio 2D a quello 3D e il filtro sulle componenti hanno effetti piccoli, che dipendono dal contesto: il filtro sulle componenti migliora leggermente il punteggio prima di S2 e lo peggiora leggermente nella configurazione finale. Entrambe le forme di recupero riducono il punteggio: la prima perché aggiunge più falsi positivi che veri positivi, la seconda perché si espande in modo massiccio nel tessuto normale (circa 195.000 e 169.000 falsi positivi).

La Figura 6.1 mostra il percorso di sviluppo come catena di modifiche di un solo blocco.

![Figura 6.1](../results/figures/report_ch6_ablation_trajectory.png)

*Figura 6.1 – Punteggio di sviluppo (media del Dice su pn0 e pn3) lungo il percorso di sviluppo: soglia multi-livello (0,042), apertura quadrata (0,057), filtro sulle componenti (0,058), supporto S2 = v1 (0,600), filtraggio anisotropo 2D = v2 (0,661), filtraggio 3D (0,663), apertura a diamante (0,688), rimozione del filtro sulle componenti = v3 (0,690). Valori in-sample; ogni passo è misurato nel contesto dei blocchi precedenti.*

## 6.3 Robustezza al rumore

La Tabella 6.5 riporta il comportamento della v3 e della v4 sui sei livelli di rumore del database pre-calcolato. Per la v3 pn0 e pn3 sono casi di sviluppo e pn1, pn5, pn7 e pn9 il test prospettico; per la v4 tutti e sei i casi sono **dati visti**.

*Tabella 6.5 – Robustezza al rumore (msles2). In corsivo i casi di sviluppo della v3.*

| Caso | Rumore | Status per la v3 | Dice v3 | Precision v3 | Recall v3 | FP v3 | Dice v4 | Precision v4 | Recall v4 | FP v4 |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| *pn0* | *0 %* | *sviluppo* | *0,685* | *0,646* | *0,730* | *1.406* | 0,722 | 0,755 | 0,691 | 788 |
| pn1 | 1 % | test | 0,692 | 0,659 | 0,729 | 1.326 | 0,723 | 0,760 | 0,689 | 763 |
| *pn3* | *3 %* | *sviluppo* | *0,694* | *0,693* | *0,696* | *1.085* | 0,711 | 0,775 | 0,657 | 669 |
| pn5 | 5 % | test | 0,715 | 0,748 | 0,685 | 812 | 0,721 | 0,836 | 0,634 | 438 |
| pn7 | 7 % | test | 0,408 | 0,280 | 0,750 | 6.766 | 0,663 | 0,896 | 0,526 | 214 |
| pn9 | 9 % | test | 0,409 | 0,292 | 0,680 | 5.775 | 0,493 | 0,953 | 0,332 | 58 |

**v3.** Il Dice è stabile fino al 5 % di rumore e scende a circa 0,41 dal 7 %, per l'aumento dei falsi positivi. Il livello TA calcolato automaticamente diminuisce in modo monotono con il rumore, da 0,616 a pn0 a 0,414 a pn9, e la distanza tra i due livelli di `multithresh` si riduce da circa 0,12 a pn1 a circa 0,06 a pn7 e pn9. Nello stesso intervallo la frazione dei voxel di lesione contenuta in S2 scende da 0,887 a 0,800.

**Effetto del filtraggio.** Il confronto controllato tra v1 (senza filtro) e v2 (T2 filtrata) mostra che il filtraggio migliora nettamente il Dice fino al 5 % di rumore (a pn5 da 0,412 a 0,662), mentre a pn7 e pn9 la versione senza filtro ottiene un Dice più alto (0,562 contro 0,425 a pn7).

**v4 (dati visti).** Sugli stessi casi la v4 non presenta l'aumento dei falsi positivi ad alto rumore: i falsi positivi diminuiscono all'aumentare del rumore, da 788 a 58 voxel, e la Precision aumenta fino a 0,953. La Recall diminuisce invece da 0,691 a 0,332, e a pn9 il Dice è 0,493. La soglia minima della v4 diminuisce meno del livello TA al crescere del rumore (da 0,628 a pn1 a 0,554 a pn9, contro 0,604 e 0,414 del livello TA) ed è la soglia effettivamente applicata in tutti i casi.

![Figura 6.2](../results/figures/report_ch6_noise.png)

*Figura 6.2 – Dice, Precision e Recall in funzione del livello di rumore. v3: i punti di sviluppo (pn0, pn3) sono distinti da quelli del test prospettico originale (pn1, pn5, pn7, pn9). v4: tutti i punti sono dati visti durante lo sviluppo e non costituiscono un test indipendente.*

## 6.4 Robustezza al carico lesionale

La Tabella 6.6 riporta i risultati sulle simulazioni con seme 1 e rumore 0 %, che differiscono solo per il carico lesionale. Per la v3 queste simulazioni non erano state utilizzate nello sviluppo originario ed erano state analizzate dopo il test prospettico; per la v4 sono invece dati visti, perché fanno parte del suo sviluppo.

*Tabella 6.6 – Robustezza al carico lesionale (seme 1, rumore 0 %).*

| Phantom | Voxel di lesione | Versione | Dice | Precision | Recall | Predetti | FP | Errore vol. | Lesioni rilevate | Componenti false | GT dentro S2 |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| msles1 (lieve) | 422 | v3 | 0,013 | 0,007 | 0,455 | 29.301 | 29.109 | 6.843,4 % | 7 di 13 | 670 | 0,713 |
| msles2 (moderato) | 3.512 | v3 | 0,662 | 0,677 | 0,648 | 3.363 | 1.087 | 4,2 % | 22 di 59 | 7 | 0,884 |
| msles3 (grave) | 10.104 | v3 | 0,788 | 0,801 | 0,776 | 9.793 | 1.951 | 3,1 % | 23 di 39 | 1 | 0,931 |
| msles1 (lieve) | 422 | v4 (dati visti) | 0,266 | 0,342 | 0,218 | 269 | 177 | 36,3 % | 4 di 13 | 8 | 0,713 |
| msles2 (moderato) | 3.512 | v4 (dati visti) | 0,667 | 0,720 | 0,622 | 3.033 | 849 | 13,6 % | 21 di 59 | 2 | 0,884 |
| msles3 (grave) | 10.104 | v4 (dati visti) | 0,788 | 0,827 | 0,752 | 9.195 | 1.595 | 9,0 % | 21 di 39 | 0 | 0,931 |

Con carico moderato e grave la v3 ottiene risultati coerenti con lo sviluppo. Con carico lieve predice 29.301 voxel a fronte di 422 voxel reali, cioè circa 69 volte il volume reale, con Dice 0,013. Nel caso lieve anche la frazione della ground truth contenuta in S2 è più bassa (0,713) che negli altri due casi.

Le lesioni mancate dalla v3 sono soprattutto le più piccole: la dimensione mediana delle lesioni mancate è di 1,5, 5 e 2,5 voxel nei tre phantom, contro 27, 36,5 e 93 voxel delle lesioni rilevate.

Sugli stessi casi, che fanno parte del suo sviluppo, la v4 riduce i voxel predetti nel caso lieve da 29.301 a 269, con Dice 0,266, e lascia sostanzialmente invariati i casi moderato e grave.

![Figura 6.3](../results/figures/report_ch6_lesion_load.png)

*Figura 6.3 – Dice, Precision e Recall della v3 e della v4 sui tre carichi lesionali simulati (seme 1, rumore 0 %). Per la v4 questi casi sono dati visti durante lo sviluppo.*

## 6.5 Risultati finali della v4 sul test riservato

La Tabella 6.7 è la **tabella principale** della relazione: riporta i risultati della versione finale v4 sui quattro casi del test riservato, generati dopo il congelamento della v4 e valutati una sola volta.

*Tabella 6.7 – Test riservato finale della v4 (template AI, seme 2). Per il phantom normale le metriche di sovrapposizione e l'errore volumetrico non sono riportati (Sezione 4.9).*

| Caso | Rumore | Voxel di lesione | Predetti | Dice | IoU | Precision | Recall | Specificity | Errore vol. | TP | FP | FN | Lesioni rilevate | Componenti false |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| normale | 0 % | 0 | 172 | – | – | – | – | 0,99998 | – | 0 | 172 | 0 | – | 10 |
| normale | 3 % | 0 | 30 | – | – | – | – | 1,00000 | – | 0 | 30 | 0 | – | 5 |
| msles1 (lieve) | 3 % | 422 | 164 | 0,341 | 0,206 | 0,610 | 0,237 | 0,99999 | 61,1 % | 100 | 64 | 322 | 4 di 13 | 2 |
| msles3 (grave) | 3 % | 10.104 | 8.211 | 0,773 | 0,630 | 0,862 | 0,701 | 0,99984 | 18,7 % | 7.079 | 1.132 | 3.025 | 18 di 39 | 0 |

**Phantom normale.** In assenza di lesioni la v4 predice 172 voxel senza rumore e 30 voxel con rumore 3 %, distribuiti rispettivamente in 10 e 5 piccole componenti. Rispetto alla maschera cerebrale, i falsi positivi rappresentano lo 0,010 % e lo 0,002 % del volume.

**Carico lieve.** Sul phantom msles1 con rumore 3 % la v4 ottiene Dice 0,341, con Precision 0,610 e Recall 0,237: predice meno voxel di quelli reali (164 contro 422) e tocca 4 delle 13 lesioni. Il 26 % dei voxel di lesione si trova fuori da S2.

**Carico grave.** Sul phantom msles3 con rumore 3 % la v4 ottiene Dice 0,773, con Precision 0,862 e Recall 0,701, senza componenti false; tocca 18 delle 39 lesioni.

## 6.6 Confronto descrittivo v3–v4

Il confronto tra v3 e v4 ha uno status diverso a seconda dei dati su cui viene fatto. Sul **test riservato** entrambe le versioni erano congelate e nessuna delle due aveva mai visto i dati: è l'unico confronto in cui le due versioni sono nella stessa condizione (Tabella 6.8).

*Tabella 6.8 – Test riservato: v4 (versione finale) e v3 (riferimento), stessi dati, entrambe congelate.*

| Caso | Versione | Predetti | Dice | Precision | Recall | FP | FN | Errore vol. | Componenti false | Specificity |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| normale 0 % | v3 | 31.917 | – | – | – | 31.917 | 0 | – | 723 | 0,99551 |
| normale 0 % | **v4** | **172** | – | – | – | 172 | 0 | – | 10 | 0,99998 |
| normale 3 % | v3 | 17.486 | – | – | – | 17.486 | 0 | – | 455 | 0,99754 |
| normale 3 % | **v4** | **30** | – | – | – | 30 | 0 | – | 5 | 1,00000 |
| msles1 3 % | v3 | 16.891 | 0,024 | 0,012 | 0,495 | 16.682 | 213 | 3.902,6 % | 399 | 0,99765 |
| msles1 3 % | **v4** | 164 | **0,341** | 0,610 | 0,237 | 64 | 322 | 61,1 % | 2 | 0,99999 |
| msles3 3 % | v3 | 9.525 | 0,788 | 0,811 | 0,765 | 1.796 | 2.375 | 5,7 % | 0 | 0,99975 |
| msles3 3 % | **v4** | 8.211 | **0,773** | 0,862 | 0,701 | 1.132 | 3.025 | 18,7 % | 0 | 0,99984 |

Sul phantom normale i falsi positivi passano da 31.917 a 172 voxel senza rumore e da 17.486 a 30 voxel con rumore 3 %, cioè una riduzione del 99,5 % e del 99,8 % rispetto alla v3 (valori derivati dai conteggi). Sul carico lieve la v3 predice 16.891 voxel a fronte di 422 reali; la v4 ne predice 164. Sul carico grave **la v3 ottiene un Dice leggermente più alto** (0,788 contro 0,773) e una Recall più alta (0,765 contro 0,701), mentre la v4 ha meno falsi positivi e una Precision più alta.

**Confronto sui dati visti.** Su pn1, pn5, pn7 e pn9 e sulle simulazioni con seme 1 il confronto ha uno status asimmetrico: per la v3 pn1–pn9 sono il test prospettico originale, per la v4 sono dati visti (Tabelle 6.5 e 6.6). Su questi casi si osserva lo stesso andamento del test riservato: in tutti i casi con lesioni la v4 ha Precision più alta e Recall più bassa della v3. Questo confronto non costituisce però una validazione indipendente della v4.

![Figura 6.4](../results/figures/report_ch6_reserved_v3_v4.png)

*Figura 6.4 – Test riservato: confronto tra v3 (riferimento) e v4 (versione finale). A sinistra i voxel falsi positivi sul phantom normale senza lesioni (scala logaritmica); a destra Dice, Precision e Recall sui due phantom con lesioni.*

## 6.7 Risultati visivi 2D

La Figura 6.5 mostra la segmentazione della v4 su una slice assiale di tre casi: pn3 (carico moderato, caso di sviluppo), msles1 e msles3 con rumore 3 % (test riservato). Le slice sono state scelte con una regola fissa, la slice con il maggior numero di voxel di lesione nella ground truth, solo per la visualizzazione; non rappresentano quindi le prestazioni medie per slice.

![Figura 6.5](../results/figures/report_ch6_2d_overview.png)

*Figura 6.5 – Segmentazione finale della v4 su una slice assiale per caso (righe: pn3, carico moderato, slice k = 102; msles1 test riservato, carico lieve, k = 70; msles3 test riservato, carico grave, k = 104). Colonne: T2 originale; T2 con la ground truth (ciano); T2 con la predizione della v4 (giallo); mappa degli errori con veri positivi (verde), falsi positivi (rosso) e falsi negativi (blu).*

Nella slice di pn3 i nuclei delle lesioni periventricolari sono segmentati; i falsi positivi compaiono come sottili bordi attorno alle regioni lesionali e i falsi negativi come piccole aree isolate della ground truth. Nella slice del caso lieve prevalgono i falsi negativi lungo una lesione sottile, di cui solo una piccola parte è segmentata. Nella slice del caso grave le strutture lesionali principali sono coperte, con falsi negativi residui sulle lesioni più piccole e sottili bordi di falsi positivi sulle lesioni grandi. Queste osservazioni sono qualitative e coerenti con i valori di Precision e Recall delle Tabelle 6.5 e 6.7.

## 6.8 Visualizzazione volumetrica 3D

Le Figure 6.6–6.8 mostrano le maschere complete in 3D per gli stessi tre casi, con la stessa vista, gli stessi limiti spaziali e la geometria isotropa da 1 mm. Le maschere sono visualizzate senza alcuna modifica: nessuna levigatura, rimozione di componenti o sottocampionamento.

![Figura 6.6](../results/figures/report_ch6_3d_prediction.png)

*Figura 6.6 – Maschera completa della v4 (giallo) nei tre casi. La superficie grigia, molto trasparente, è il bordo della maschera cerebrale automatica ricavata dalla T1 (Sezione 3.3), mostrata solo come contesto spaziale: non è una ricostruzione anatomica né una superficie della ground truth.*

![Figura 6.7](../results/figures/report_ch6_3d_gt_prediction.png)

*Figura 6.7 – Ground truth (ciano) e predizione della v4 (giallo), semi-trasparenti, nello stesso spazio, all'interno della maschera cerebrale automatica (grigio, solo contesto).*

![Figura 6.8](../results/figures/report_ch6_3d_tp_fp_fn.png)

*Figura 6.8 – Errori della v4 in 3D: veri positivi (verde), falsi positivi (rosso) e falsi negativi (blu).*

Le viste 3D mostrano che le lesioni occupano diverse regioni attorno ai ventricoli e si estendono su molte slice, e rendono direttamente visibile la differenza di carico lesionale tra i tre casi. Nel caso lieve la maggior parte delle lesioni della ground truth compare come falsi negativi, mentre nelle visualizzazioni 3D, nel caso grave i falsi positivi appaiono come sottili strati sul bordo delle grandi lesioni confluenti.
