
/*Filip G�ogowski
Analiza bramkarzy 
Program stworzony w celu analizy bramkarzy dost�pnych w grze fifa okre�lenie do jakiego wieku osi�gaj� najwi�kszy rozw�j*/


LIBNAME fifa 'C:\Users\FIJIP\Desktop\SasProjekty';

PROC IMPORT datafile='C:\Users\FIJIP\Desktop\SasProjekty\Fifa19DataSet.csv' 
	out=fifa.rawdata 
	dbms = CSV 
 ;
run;
/* Pozycje wyt�umaczone dla niewtajemniczonych
bramkarz			GK	Goalkeeper 				bramkarze maj� puste wszystkie statystyki z ni�ej wymienionych
obro�cy				RB	Right Back
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
/*wst�pna kr�tka analiza danych*/
PROC CONTENTS data=fifa.rawdata position;
run;

PROC CONTENTS data=fifa.rawdata short;
run;

/* Z danych mo�na si� dowiedzie� statystyk na temat zawodnik�w. Dzi�ki temu mo�emy wybra� najlepszy zesp� albo najciekawszych m�odych zawodnik�w.
Na pewno trzeba usun�� pierwsz� kolumne gdy� zb�dnie wylicza zawodnink�w.
Jako Cel ustalmy okre�lenie wieku kiedy bramkarze przestaj� si� rozwija� i osiagaj� szczyt mo�liwo�ci.
Mo�na usun�� kolumny Photo Flag  Club_logo gdy� zawieraj� tylko linki do zdj�� nieb�d�cych obiektem zainteresowa� tego projektu.roz��czno�ci mi�dzy zbiorami
*/

DATA Fifa.wszyscy;
	set fifa.rawdata; 
	Drop VAR1 Photo Flag Club_Logo Real_face Jersey_number Joined Loaned_from;
RUN;/* dane bez zb�dnych kolumn*/

/*wybierzmy tylko bramkarzy. Ze wst�pnej analizy wida� �e bramkarze maj� warto�ci na polach �redniej punktacji z pozycji w polu warto�ci NULL, np LS*/

DATA Fifa.Bramkarze;
	set fifa.wszyscy;
	where LS is null;/*LS dla bramkarzy ma tak� posta�*/
	VALUE_Num=INPUT(compress(VALUE,'�M'),best9.)*1000000;
	Wage_Num=INPUT(compress(wage,'�KM'),best9.)*1000;
	WEIGHT_NUM=INPUT(compress(WEIGHT,'lbs�KM'),best9.);/*waga, warto�� i pensja zamieniamy na faktyczne warto�ci numeryczne*/;
	DROP LS ST RS LW LF CF RF RW LAM CAM RAM LM LCM LDM CM RCM RM LWB CDM RDM RWB LB LCB CB RCB RB /*usuwamy punkty kt�re i tak s� puste*/
		crossing finishing volleys dribbling curve ballcontrol standingtackle slidingtackle weak_Foot Skill_moves
	/*atrybuty niekoniecznie potrzebne bramkarzowi, kt�rych usuni�cie mo�e przyspiesza� kompilacje wynik�w*/	;
RUN;

PROC SORT data=FIFA.bramkarze;
	by  Descending overall Descending potential VALUE_num;
RUN;/*zawodnicy zostali posortowani*/

libname library 'C:\Users\FIJIP\Desktop\SasProjekty';/*tworzenie biblioteki dla format�w*/
PROC FORMAT library=library;/*format kt�ry okre�li jak do�wiadczenie s� zawodnicy*/
	VALUE   poziom_reputacji 1='pocz�tkuj�cy'
							 2='amator'
							 3='zawodowiec'
							 4='ekspert'
							 5='legenda';
RUN;/*Zale�nie od poziomu dajemy odpowiedni� opinie*/

DATA Fifa.bramkarze_reputacja;
/*format value BEST12.*/;
	set fifa.bramkarze;
	poziom_reputacji = international_reputation; 
	FORMAT skill_moves poziom_reputacji.;
	KEEP NAME poziom_reputacji value_num;
RUN;

PROC FREQ DATA=fifa.bramkarze_reputacja;
    TABLES poziom_reputacji;
RUN;/*liczebno�� bramkarzy o okre�lonym poziomie reputacji*/

proc plot data=fifa.bramkarze_reputacja;
   plot poziom_reputacji*value_num='.' /	
         haxis=10000000 20000000 30000000 40000000 50000000
			;
   title 'Wykres warto�ci zawodnikow w zale�no�ci od reputacji';
run;

DATA Fifa.potencjal_bramkarzy;
	SET fifa.bramkarze;/*obliczamy jakie mo�liwo�ci rozwoju maj� jeszcze zawodnicy i przypisujemy opinie*/
	if POTENTIAL-OVERALL=0 then delete;
	if POTENTIAL-OVERALL<10  then potential='ma�y potencja�';
		else potential_opinion='wart uwagi';/*dzielimy zawodnik�w na tych z mala mozliwoscia rozwoju i z du�a*/
RUN;

PROC PLOT DATA=fifa.potencjal_bramkarzy;
   PLOT overall*value_num='.' /	
        haxis=10000000 20000000 30000000 40000000 50000000
			;
   TITLE 'Wykres warto�ci zawodnikow w zale�no�ci od warto�ci potencja�u';
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
RUN;/*wida� �e najwi�cej zawodnik�w ma potencja� by mie� overall oko�o 85*/

/*obliczyli�my �rednie, teraz zobaczmy jak wygl�da to na wykresie*/

PROC PLOT data=fifa.srednie_pot;/*liczymy �redni� overall i potential grupuj�c zawodnik�w wzgl�dem wieku */
	plot avg_overall*age='*'
		 avg_potential*age='o'/ overlay box;
		 title 'wykres potencja�u i osiagnie� zale�nie od wieku';
RUN;/*brzydki wykres, drugi raz go nie skompiluje*/

proc sgplot data=fifa.srednie_pot;
	scatter y=avg_overall x=age; /*pierwszy wykres �redniej z potencjalu*/
	scatter y=avg_potential x=age;/*drugi wykres �redniej z overall*/
	 title 'wykres potencja�u i osiagnie� zale�nie od wieku';
run;/*�adniejszy wykres i wida� �e do 29 roku �ycia bramkarze osiagaj� najcze�ciej sw�j szczyt mo�liwo�ci*/

/*Wida� zatem �e zawodnicy osi�gaj� szczyt mo�liwo��i �rednio do 29 roku �ycia. Rozpoczynaj�c zatem karieie jako zawodnik nie warto
zaczyna� jako tak "stara" osoba i trzeba si� liczy� �e po osi�gni�ciu tego wieku nasz zawodnik b�dzie juz coraz gorszy w kolejnych sezonach*/



