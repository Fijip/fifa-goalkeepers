
/*Filip Głogowski
Analiza bramkarzy 
Program stworzony w celu analizy bramkarzy dostępnych w grze fifa określenie do jakiego wieku osiągają największy rozwój*/


LIBNAME fifa 'C:\Users\FIJIP\Desktop\SasProjekty';

PROC IMPORT datafile='C:\Users\FIJIP\Desktop\SasProjekty\Fifa19DataSet.csv' 
	out=fifa.rawdata 
	dbms = CSV 
 ;
run;
/* Pozycje wytłumaczone dla niewtajemniczonych
bramkarz			GK	Goalkeeper 				bramkarze mają puste wszystkie statystyki z niżej wymienionych
obrońcy				RB	Right Back
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
/*wstępna krótka analiza danych*/
PROC CONTENTS data=fifa.rawdata position;
run;

PROC CONTENTS data=fifa.rawdata short;
run;

/* Z danych można się dowiedzieć statystyk na temat zawodników. Dzięki temu możemy wybrać najlepszy zespół albo najciekawszych młodych zawodników.
Na pewno trzeba usunąć pierwszą kolumne gdyż zbędnie wylicza zawodninków.
Jako Cel ustalmy określenie wieku kiedy bramkarze przestają się rozwijać i osiagają szczyt możliwości.
Można usunąć kolumny Photo Flag  Club_logo gdyż zawierają tylko linki do zdjęć niebędących obiektem zainteresowań tego projektu.rozłączności między zbiorami
*/

DATA Fifa.wszyscy;
	set fifa.rawdata; 
	Drop VAR1 Photo Flag Club_Logo Real_face Jersey_number Joined Loaned_from;
RUN;/* dane bez zbędnych kolumn*/

/*wybierzmy tylko bramkarzy. Ze wstępnej analizy widać że bramkarze mają wartości na polach średniej punktacji z pozycji w polu wartości NULL, np LS*/

DATA Fifa.Bramkarze;
	set fifa.wszyscy;
	where LS is null;/*LS dla bramkarzy ma taką postać*/
	VALUE_Num=INPUT(compress(VALUE,'€M'),best9.)*1000000;
	Wage_Num=INPUT(compress(wage,'€KM'),best9.)*1000;
	WEIGHT_NUM=INPUT(compress(WEIGHT,'lbs€KM'),best9.);/*waga, wartość i pensja zamieniamy na faktyczne wartości numeryczne*/;
	DROP LS ST RS LW LF CF RF RW LAM CAM RAM LM LCM LDM CM RCM RM LWB CDM RDM RWB LB LCB CB RCB RB /*usuwamy punkty które i tak są puste*/
		crossing finishing volleys dribbling curve ballcontrol standingtackle slidingtackle weak_Foot Skill_moves
	/*atrybuty niekoniecznie potrzebne bramkarzowi, których usunięcie może przyspieszać kompilacje wyników*/	;
RUN;

PROC SORT data=FIFA.bramkarze;
	by  Descending overall Descending potential VALUE_num;
RUN;/*zawodnicy zostali posortowani*/

libname library 'C:\Users\FIJIP\Desktop\SasProjekty';/*tworzenie biblioteki dla formatów*/
PROC FORMAT library=library;/*format który określi jak doświadczenie są zawodnicy*/
	VALUE   poziom_reputacji 1='początkujący'
							 2='amator'
							 3='zawodowiec'
							 4='ekspert'
							 5='legenda';
RUN;/*Zależnie od poziomu dajemy odpowiednią opinie*/

DATA Fifa.bramkarze_reputacja;
/*format value BEST12.*/;
	set fifa.bramkarze;
	poziom_reputacji = international_reputation; 
	FORMAT skill_moves poziom_reputacji.;
	KEEP NAME poziom_reputacji value_num;
RUN;

PROC FREQ DATA=fifa.bramkarze_reputacja;
    TABLES poziom_reputacji;
RUN;/*liczebność bramkarzy o określonym poziomie reputacji*/

proc plot data=fifa.bramkarze_reputacja;
   plot poziom_reputacji*value_num='.' /	
         haxis=10000000 20000000 30000000 40000000 50000000
			;
   title 'Wykres wartości zawodnikow w zależności od reputacji';
run;

DATA Fifa.potencjal_bramkarzy;
	SET fifa.bramkarze;/*obliczamy jakie możliwości rozwoju mają jeszcze zawodnicy i przypisujemy opinie*/
	if POTENTIAL-OVERALL=0 then delete;
	if POTENTIAL-OVERALL<10  then potential='mały potencjał';
		else potential_opinion='wart uwagi';/*dzielimy zawodników na tych z mala mozliwoscia rozwoju i z duża*/
RUN;

PROC PLOT DATA=fifa.potencjal_bramkarzy;
   PLOT overall*value_num='.' /	
        haxis=10000000 20000000 30000000 40000000 50000000
			;
   TITLE 'Wykres wartości zawodnikow w zależności od wartości potencjału';
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
RUN;/*widać że najwięcej zawodników ma potencjał by mieć overall około 85*/

/*obliczyliśmy średnie, teraz zobaczmy jak wygląda to na wykresie*/

%MACRO wykres(dane, x, y1, y2);
PROC PLOT data=&dane;/*liczymy średnią overall i potential grupując zawodników względem wieku */
	plot &y1*&xe='*'
		 &y2*&xe='o'/ overlay box;
RUN;/*brzydki wykres, drugi raz go nie skompiluje*/
%MEND;
%wykres1(fifa.srednie_pot, age, avg_overall, avg_potential);


%MACRO wykres2(dane, x, y1, y2);
PROC SGPLOT DATA=&dane;
	scatter y=&y1 x=&x; /*pierwszy wykres średniej z potencjalu*/
	scatter y=&y2 x=&x;/*drugi wykres średniej z overall*/
;
RUN;/*ładniejszy wykres i widać że do 29 roku życia bramkarze osiagają najcześciej swój szczyt możliwości*/
%MEND;
%wykres2(fifa.srednie_pot, age, avg_overall, avg_potential);

/*Widać zatem że zawodnicy osiągają szczyt możliwośći średnio do 29 roku życia. Rozpoczynając zatem karieie jako zawodnik nie warto
zaczynać jako tak "stara" osoba i trzeba się liczyć że po osiągnięciu tego wieku nasz zawodnik będzie juz coraz gorszy w kolejnych sezonach*/



