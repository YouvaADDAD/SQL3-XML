/*Dans ce fichier on va trouver le fichier sql pour la génération XML de la dtd 1 
Une province a un ensemble de montagnes ,deserts,islands 
les islands ont une coordonnées du coup le type coordonnées
les country ont un ensemble de province et et de country
le type mondiale lance le tout
*/
-----------------------type et Table T_Aeroport------------------------------
create or replace type T_airport as object(
    --l'attibut country est le code du pays auquelle appartient cette aeroport
    --parce que un aeroport appartient a un seul pays et un pays a plusieurs aeroport
    --l'attribut nearCity c'est la city dans lequelle il ce trouve
    name varchar2(100),
    nearCity varchar2(50),
    country varchar2(4),
    member function toXML return XMLType
);
/

create or replace type body T_Airport as
    /*ici je verifie si l'attibut nearCity n'est pas null ceci correspond au #IMPIELED*/
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --Ajout des attributs name et nearCity , XMLATTRIBUTES ajoute si seulement si nearCity n'est pas null
        select XMLElement("airport",XMLATTRIBUTES(SELF.name as "name",self.nearCity as "nearCity" )) into outPut from dual;
        return outPut;
    end;
end;
/ 

/*definition des tables et l'ensemble d'aeroport 
le nom du pays dois etre non nulle du au #REQUIERED*/
create table Airports of T_Airport(name not Null);
/
--creation d'un type ensembliste d'aeroport
create or replace type T_EnsAirport as table of T_Airport;
/

-----------------------------------------------------------------------

-----------------------Type ET Table CONTINENT----------------------------
create or replace type T_Continent as object(
    /*Pour stocker le nom et le pourcent du continent*/
     name varchar2(50),
     percent number,
     member function toXML return XMLType
);
/

create or replace type body T_Continent as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --l'ajout d'attribut dans le noeud continent
        select XMLElement("continent",XMLATTRIBUTES(self.name as "name",self.percent as "percent")) into outPut from dual;
        return outPut;
    end;
end;
/ 

/*Creation d'un type ensembliste de continent 
Ici on a pas besoin de créer une table de continent c'est country qui prendra sois de bien remplir*/
create or replace type T_EnsContinent as table of T_Continent  ;
/
-----------------------------------------------------------------------

-----------------------Type ET Table COORDINATE--------------------------------------------
create or replace type T_Coordinates as object(
    --Le type Coordinates sert juste de type on crée pas de table
    Latitude number,
    Longitude number,
    member function toXML return XMLType
);

/

create or replace type body T_Coordinates as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --a la création de l'instance XMLType on ajoute les attributs 
        select XMLELEMENT("coordinates",XMLATTRIBUTES(latitude as "latitude",longitude as "longitude")) into outPut from dual;
        return outPut;
    end;
end;
/ 
------------------------------------------------------------------------------------------

-----------------------Type ET Table ISLAND----------------------------------------------
create or replace TYPE T_island as object (
    /*pour ici aussi une island appartient a une seul province et une province a zero ou plusieur islands*/
    --peu contenir une coordonnée
    name varchar2(50),
    coordinates T_coordinates,
    --l'attribut province pour retrouver les Islands appartenant a cette province
    province varchar2(50),
    member function toXML return XMLType
);
/


create or replace type body T_island as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --Ajout de l'element coordonnée
        select XMLELEMENT("island",XMLATTRiButes(name as "name"),coordinates.toXML()) into outPut from dual;
       return outPut;
    end;
end;
/ 

/*on cree une contraint pour que les latitude et longitude ne sois pas null et le nom de l'island ne sois pas null aussi*/
create table Islands of T_island(name NOT NULL,constraint coordinatesLatitude check (coordinates.Latitude is not null),
                                               constraint coordinatesLongitude check(coordinates.Longitude is not null));
/
--Creation de type ensembliste 
create or replace type T_islands as table of T_island;
/
------------------------------------------------------------------------------------------

-----------------------Type ET Table ZONE----------------------------------------------
create or replace type  T_Mountain as object(
    /*Une montagne appartient a une province et une province peu avoir plusieur montagnes*/
    name varchar2(50),
    height number,
    --l'attribut province pour retrouver les montagnes appartenant a cette province
    province varchar2(50),
    member function toXML return XMLType 
);
/

create or replace type body T_Mountain as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --Ajout des attributs 
        select XMLELEMENT("mountain",XMLATTRIBUTES(name as "name",height as "height")) into outPut from dual;
        return outPut;
    end;
end;
/ 

create or replace Type T_Desert as object (
     /*Un desert appartient a une province et une province peu avoir plusieur deserts*/
    name varchar2(50),
    area number,
    --l'attribut province pour retrouver les deserts appartenant a cette province
    province varchar2(50),
    member function toXML return XMLType
);
/

create or replace type body T_Desert as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --Ajout des attributs a deserts
        select XMLELEMENT("desert",XMLATTRIBUTES(name as "name",area as "area")) into outPut from dual;
        return outPut;
      
    end;
end;
/ 

--creation de type ensembliste de desert et montagne
create or replace type T_EnsDesert as table of T_Desert;
/
create or replace type T_EnsMountain as table of T_Mountain;
/
/*faut rajouter des contraintes sur name et le height #REQUIERED*/
create table Mountains of T_Mountain(name NOT NULL,height NOT NULL);
/
/*name est requis mais area est #IMPIELED*/
create table Deserts of T_Desert( name NOT NULL);
/
------------------------------------------------------------------------------------------

-----------------------Type ET Table Province----------------------------------------------
create or replace type T_Province as OBJECT(
    /*Une province appartient a un seul pays et un pays a plusieur province*/
    name VARCHAR2(50),
    capital VARCHAR2(50),
    --l'attribut country pour retrouver les provinces appartenant a ce pays
    country varchar2(4),
    member function toXML return XMLType 
);
/

create or replace type body T_Province as
    member function toXML return XMLType is
    --Dans cette méthode je cherche toutes les montagnes,deserts et islands appartenant a une province que je vais 
    --collecter et stocker dans les types adequat
    --ensuite j'appel la méthode toXML pour chacun d'eux 
    outPut XMLType;
    --Result est un conteneur
    Result varchar2(256);
    tmpEnsM T_EnsMountain;
    tmpEnsD T_EnsDesert;
    tmpEnsI T_islands;
    begin
        --D'aprés la DTD faut nécessairement ajouter capital meme si il est nulle donc sa donnerai capital=""
        Result:= '<province name="'|| name ||'" '||'capital="' || capital ||'" />';
        outPut :=XMLType.createxml(Result);
        /*La collect des montagnes/desert/islands de la province 
        On remarque ici que on prend d'abord toutes les montagnes ensuite deserts ensuite islands qui est bien
        conforme a la dtd */
        select value(m) bulk collect into tmpEnsM from mountains m where self.name=m.province;
        select value(d) bulk collect into tmpEnsD from deserts d where self.name=d.province;
        select value(i) bulk collect into tmpEnsI from islands i where self.name=i.province;
        
        --les boucles for pour les appelles au toXML pour chaque type
        for m IN 1..tmpEnsM.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'province', tmpEnsM(m).toXML());   
            end loop; 
            
        for d IN 1..tmpEnsD.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'province', tmpEnsD(d).toXML());   
            end loop;
            
        for i in 1..tmpEnsI.count loop
            outPut := XMLType.appendchildxml(outPut,'province', tmpEnsI(i).toXML());
        end loop;
        
        return outPut;    
        end;
end;
/ 

--Creation d'un type ensembliste de province
create or replace type T_EnsProvince as table of T_Province;
/
/*name et capital meme si il est egale a "" sa ne pose pas de probléme ne doivent pas etre egale a null*/
create table Provinces of T_Province (name not null) ;
/
-------------------------------------------------------------------------------------------

-----------------------Type ET Table COUNTRY------------------------------------------------

create or replace type T_Country as object(
    /*Un pays a un ensemble de province et peu appartenir a plusieur continent*/
    name varchar2(50) ,
    code varchar2(4),
    --le continent auquel appartient contenant le pourcentage
    Continent T_EnsContinent,
    --les provinces du pays
    province T_EnsProvince,
    member function toXML return XMLType
);
/


create or replace type body T_Country as
  member function toXML return XMLType is
    --ici dans cette méthode je collecte d'abord les aeroport du pays ensuite j'appelle le toXML de chaque type 
    --attribut/ou non de country ,aeroport ici comme il prend le pays je n'ai pas eu besoin de le mettre en attribut 
    --d'aeroport afin d'alleger un peu les tables imbriqué 
    outPut XMLType;
    Result varchar2(256);
    tmpA T_EnsAirport;
    vide Exception;
    begin
        /*Ici je fais directement le code du pays comme id */
        select XMLELEMENT("country",XMLATTRIBUTES(code as "idcountry",name as "name")) into outPut from dual;
        /*collecte des aeroports sachant qu'ils appartiennent a un seul pays*/
        select value(a) bulk collect into tmpA from airports a where self.code=a.country; 
        --Lancement des méthodes toXML
        for c IN 1..Continent.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'country', Continent(c).toXML());   
            end loop;
        for p in 1..province.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', province(p).toXML());
          end loop;
        for a in 1..tmpA.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', tmpA(a).toXML());
          end loop;
        return outPut;
        end;
 end;
/

--type ensembliste de country
create or replace type T_EnsCountry as table of T_Country;
/
/*les contraintes pour checker si j'ai au moins une province et appartenance a au moins un continent et le code en 
primary key*/
create table Countries of T_country(code constraint CountryKey primary Key,name not null,
                                         constraint provNotNil check (province is not null),
                                         constraint contNotNil check (Continent is not null))
nested table Continent store as cont , nested table Province store as prov;
/

-----------------------------------------------------------------------------------------

-----------------------Type ET Table MONDIAL------------------------------------------------
create or replace type T_Mondial as object (
    /*Un nom quelconque juste parce que on peut pas avoir un type sans aucun attribut*/
    name varchar2(10),
    member function toXML return XMLType
);
/

create or replace type body T_Mondial as
member function toXML return XMLType is 
    outPut XMLType;
    tmpC T_EnsCountry;
    /*Une Exception si j'ai aucun pays parce que on a la contrainte au moins un pays*/
    vide Exception;
    begin
         outPut :=XMLType.createxml('<mondial/>');
         /*Collect des object pays a mondial*/
         select value(c) bulk collect into tmpC from countries c;
         --si il y a aucun pays j'appelle l'exception
         if(tmpC.count <1) then raise vide; end if;
         --appelle de la méthode toXML pour chaque pays qui lui appelle aussi les méthodes xml de continent
         --province 
         for c in 1..tmpC.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpC(c).toXML());
          end loop;
        return outPut;
     
    exception
              --traitement de l'exception
              when vide then dbms_output.put_line('No such Country');
     end;
end;
/

create table Mondial of T_Mondial;
/
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
insert into Islands (select T_island(i.name, T_coordinates(i.Coordinates.Latitude,i.Coordinates.Longitude),g.province) 
from island i ,geo_Island g where i.Name=g.Island and (i.Coordinates.Latitude is not null or i.Coordinates.Longitude is not null ));
/
insert into Mountains (select T_Mountain(m.name,m.height,g.province) from mountain m ,geo_Mountain g where m.Name=g.mountain);
/
insert into Deserts (select T_Desert(d.name,d.area,g.province) from desert d,geo_desert g where d.name=g.desert);
/
--en prend pas les provinces qui ont une capitale null sinon souci de confirmation
insert into provinces (select T_Province(p.name,p.capital,c.code) from province p,country c where p.country=c.code);
/
insert into Airports (select T_Airport(a.name,a.city,c.code) from airport a ,Country c where a.country=c.code);
/

insert into countries (select T_Country(c.name,c.code,
                                       (select cast (collect(T_Continent(e.continent,e.percentage)) as T_EnsContinent ) from encompasses e where c.code=e.country),
                                       (select cast (collect(T_province(p.name,p.capital,p.country)) as T_EnsProvince ) from provinces p where p.country=c.code)) 
from country c);
/

insert into mondial values (T_Mondial('Terre'));
/


WbExport -type=text
         -file='mondialExercice1DTD1.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from mondial m ;

