
/*Filip G³ogowski
Analiza bramkarzy 
Program stworzony w celu analizy bramkarzy dostêpnych w grze fifa okreœlenie do jakiego wieku osi¹gaj¹ najwiêkszy rozwój*/


LIBNAME fifa 'C:\Users\FIJIP\Desktop\SasProjekty';

PROC IMPORT datafile='C:\Users\FIJIP\Desktop\SasProjekty\Fifa19DataSet.csv' 
	out=fifa.rawdata 
	dbms = CSV 
 ;
run;
/* Pozycje wyt³umaczone dla niewtajemniczonych
bramkarz			GK	Goalkeeper 				bramkarze maj¹ puste wszystkie statystyki z ni¿ej wymienionych
obroñcy				RB	Right Back
					RCB Right Center Back
					CB	Center Back
					LCB Left Center Back
					LB	Left Back
pomocnicy 			RWB	Right Wing Back
					RDM Right Defensive Midfielder
					CDM	Center Defensive Midfielder
					LDM Left Defensive Midfielder
					LWB	Left Wing Back
					RM	Right Midfielder
					RCM Right Center Midfielder
					CM	Center Midfielder
					LCM Left Center Midfielder
					LM	Left Midfielder
					RAM Right Attacking Midfielder
					CAM Center Attacking Midfielder
					LAM	Left Attacking Midfielder
napastnicy			RW	Right Wing
					RF  Right Forward
					CF	Center Forward
					LF  Left Forward
					LW	Left Wing
					RS	Right Striker
					ST	Striker
					LS	Left Striker
*/
/*wstêpna krótka analiza danych*/
PROC CONTENTS data=fifa.rawdata position;
run;

PROC CONTENTS data=fifa.rawdata short;
run;

/* Z danych mo¿na siê dowiedzieæ statystyk na temat zawodników. Dziêki temu mo¿emy wybraæ najlepszy zespó³ albo najciekawszych m³odych zawodników.
Na pewno trzeba usun¹æ pierwsz¹ kolumne gdy¿ zbêdnie wylicza zawodninków.
Jako Cel ustalmy okreœlenie wieku kiedy bramkarze przestaj¹ siê rozwijaæ i osiagaj¹ szczyt mo¿liwoœci.
Mo¿na usun¹æ kolumny Photo Flag  Club_logo gdy¿ zawieraj¹ tylko linki do zdjêæ niebêd¹cych obiektem zainteresowañ tego projektu.roz³¹cznoœci miêdzy zbiorami
*/

DATA Fifa.wszyscy;
	set fifa.rawdata; 
	Drop VAR1 Photo Flag Club_Logo Real_face Jersey_number Joined Loaned_from;
RUN;/* dane bez zbêdnych kolumn*/

/*wybierzmy tylko bramkarzy. Ze wstêpnej analizy widaæ ¿e bramkarze maj¹ wartoœci na polach œredniej punktacji z pozycji w polu wartoœci NULL, np LS*/

DATA Fifa.Bramkarze;
	set fifa.wszyscy;
	where LS is null;/*LS dla bramkarzy ma tak¹ postaæ*/
	VALUE_Num=INPUT(compress(VALUE,'€M'),best9.)*1000000;
	Wage_Num=INPUT(compress(wage,'€KM'),best9.)*1000;
	WEIGHT_NUM=INPUT(compress(WEIGHT,'lbs€KM'),best9.);/*waga, wartoœæ i pensja zamieniamy na faktyczne wartoœci numeryczne*/;
	DROP LS ST RS LW LF CF RF RW LAM CAM RAM LM LCM LDM CM RCM RM LWB CDM RDM RWB LB LCB CB RCB RB /*usuwamy punkty które i tak s¹ puste*/
		crossing finishing volleys dribbling curve ballcontrol standingtackle slidingtackle weak_Foot Skill_moves
	/*atrybuty niekoniecznie potrzebne bramkarzowi, których usuniêcie mo¿e przyspieszaæ kompilacje wyników*/	;
RUN;

PROC SORT data=FIFA.bramkarze;
	by  Descending overall Descending potential VALUE_num;
RUN;/*zawodnicy zostali posortowani*/

libname library 'C:\Users\FIJIP\Desktop\SasProjekty';/*tworzenie biblioteki dla formatów*/
PROC FORMAT library=library;/*format który okreœli jak doœwiadczenie s¹ zawodnicy*/
	VALUE   poziom_reputacji 1='pocz¹tkuj¹cy'
							 2='amator'
							 3='zawodowiec'
							 4='ekspert'
							 5='legenda';
RUN;/*Zale¿nie od poziomu dajemy odpowiedni¹ opinie*/

DATA Fifa.bramkarze_reputacja;
/*format value BEST12.*/;
	set fifa.bramkarze;
	poziom_reputacji = international_reputation; 
	FORMAT skill_moves poziom_reputacji.;
	KEEP NAME poziom_reputacji value_num;
RUN;

PROC FREQ DATA=fifa.bramkarze_reputacja;
    TABLES poziom_reputacji;
RUN;/*liczebnoœæ bramkarzy o okreœlonym poziomie reputacji*/

proc plot data=fifa.bramkarze_reputacja;
   plot poziom_reputacji*value_num='.' /	
         haxis=10000000 20000000 30000000 40000000 50000000
			;
   title 'Wykres wartoœci zawodnikow w zale¿noœci od reputacji';
run;

DATA Fifa.potencjal_bramkarzy;
	SET fifa.bramkarze;/*obliczamy jakie mo¿liwoœci rozwoju maj¹ jeszcze zawodnicy i przypisujemy opinie*/
	if POTENTIAL-OVERALL=0 then delete;
	if POTENTIAL-OVERALL<10  then potential='ma³y potencja³';
		else potential_opinion='wart uwagi';/*dzielimy zawodników na tych z mala mozliwoscia rozwoju i z du¿a*/
RUN;

PROC PLOT DATA=fifa.potencjal_bramkarzy;
   PLOT overall*value_num='.' /	
        haxis=10000000 20000000 30000000 40000000 50000000
			;
   TITLE 'Wykres wartoœci zawodnikow w zale¿noœci od wartoœci potencja³u';
RUN;

PROC SQL;
	create table fifa.srednie_pot as 
		select age ,mean(potential) as avg_potential , mean(overall) as avg_overall from fifa.bramkarze
		group by age
		order by age, avg_overall;
QUIT;

proc sgplot data=fifa.srednie_pot;
	histogram avg_overall;
	histogram avg_potential;
RUN;/*widaæ ¿e najwiêcej zawodników ma potencja³ by mieæ overall oko³o 85*/

/*obliczyliœmy œrednie, teraz zobaczmy jak wygl¹da to na wykresie*/

PROC PLOT data=fifa.srednie_pot;/*liczymy œredni¹ overall i potential grupuj¹c zawodników wzglêdem wieku */
	plot avg_overall*age='*'
		 avg_potential*age='o'/ overlay box;
		 title 'wykres potencja³u i osiagnieæ zale¿nie od wieku';
RUN;/*brzydki wykres, drugi raz go nie skompiluje*/

proc sgplot data=fifa.srednie_pot;
	scatter y=avg_overall x=age; /*pierwszy wykres œredniej z potencjalu*/
	scatter y=avg_potential x=age;/*drugi wykres œredniej z overall*/
	 title 'wykres potencja³u i osiagnieæ zale¿nie od wieku';
run;/*³adniejszy wykres i widaæ ¿e do 29 roku ¿ycia bramkarze osiagaj¹ najczeœciej swój szczyt mo¿liwoœci*/

/*Widaæ zatem ¿e zawodnicy osi¹gaj¹ szczyt mo¿liwoœæi œrednio do 29 roku ¿ycia. Rozpoczynaj¹c zatem karieie jako zawodnik nie warto
zaczynaæ jako tak "stara" osoba i trzeba siê liczyæ ¿e po osi¹gniêciu tego wieku nasz zawodnik bêdzie juz coraz gorszy w kolejnych sezonach*/



