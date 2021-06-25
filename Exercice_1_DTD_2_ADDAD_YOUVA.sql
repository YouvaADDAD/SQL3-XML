/*Un pays a l'ensemble des langues que parle ce pays avec un pourcentage pour chaque langues
un pays a l'ensemble des pays voisins comme T_Borders 
une organisation a un ensemble de pays en attributs*/
----------------------------------------------HeadQuarter---------------------------
create or replace type T_headquarter as object(
  /*le nom du qg correspond a la city ou ce trouve l'oganization*/
  name varchar2(50),
  member function toXML return XMLType
);
/

create or replace type body T_headquarter as 
  member function toXML return XMLType is
    outPut XMLtype;
    begin 
    --Ajout de l'attribut name pour headQuarter
    select XMLELEMENT("headquarter",XMLATTRIBUTES(name as "name")) into outPut from dual;
    return output;
    end;
end;
/
------------------------------------------------------------------------------------

--------------------------------------Language--------------------------------------
create or replace type T_Language as object(
   /*Un pays a plusieurs langues avec un pourcentage*/
    language varchar2(100),
    percent number,
    member function toXML return XMLType
);
/

create or replace type Body T_Language as 
  member function toXML return XMLType is
    output XMLType;
    begin
    --Ajout des attributs pour la langue et creation de l'instance 
    select XMLELEMENT("language",XMLATTRIBUTES(language as "language",percent as "percent")) into outPut from dual;
    return output;
    end;
  end;
/
/*creation d'un type ensembliste
ici je n'ai pas eu besoin de créer la table language j'aurais pu m'en passé
mais l'utilisation de language dans country m'avais contraint a le faire*/
create or replace type T_EnsLanguage as table of T_Language;
-------------------------------------------------------------------------------------------------------------

------------------------------------------------Border-------------------------------------------------------
create or replace type T_Border as object(
    /*Frontiere avec un pays contient code du pays frontalier et la longueur */
    countryCode varchar2(4),
    length number,
    member function toXML return XMLType
);
/

create or replace type body T_Border as
  member function toXML return XMLType is
  outPut XMLType;
  begin
    --Ajout d'attributs code country et length
    select XMLELEMENT("border",XMLATTRIBUTES(countryCode as "countryCode", length as "length")) into outPut from dual;
    return outPut;
  end;
end;
/

--creation d'un type ensembliste pour border
create type T_EnsBorder as table of T_Border;
----------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------Borders----------------------------------------------------

create or replace type T_Borders as object(
    /*l'ensemble des frontiere avec leurs length*/
    frontiere T_EnsBorder,
    member function toXML return XMLType
);
/

create or replace type body T_Borders as
  member function toXML return XMLType is
  outPut XMLType;
  begin
  --creation de l'instance
  outPut := XMLType.createxml('<borders/>');
  --ajout de noeud fils des pays frontalier
  for b in 1..frontiere.count loop
    outPut :=XMLType.appendchildxml(outPut,'borders', frontiere(b).toXML());
  end loop;
  return outPut;
  
  end;
end;
/

/*
--pas besoin de table de border
create table border of T_Borders
nested table frontiere store as front;*/
--------------------------------------------------------------------------------------------------------
create or replace TYPE T_Country as OBJECT(
    /*Un pays a plusieurs langue et plusieur pays frontalier donc ajout d'ensemble de langues et un type 
    borders qui prend toutes les frontires possible*/
    code varchar2(5),
    name VARCHAR2(60),
    population number,
    --les langues du pays
    languages T_EnsLanguage,
    --la frontiere du pays
    border T_Borders,
    member function toXML return XMLType
);
/

create or replace type body T_Country as
   member function toXML return XMLType is
   outPut XMLType ;
   begin
        --Ajout d'attribut pour le pays
        select XMLELEMENT("country",XMLATTRIBUTES(code as "code",name as "name",population as "population")) into outPut from dual;
        --ajout de noeud fils language
        for l in 1..languages.count loop 
            outPut := XMLType.appendchildxml(outPut,'country', languages(l).toXML());
        end loop;
        --ajout de noeud fils des frontieres
        outPut := XMLType.appendchildxml(outPut,'country', border.toXML());
        return outPut;
   end;
   
end;
/

--creation de la table country avec les nested table
create table Countries of T_Country
nested table border.frontiere store as frontieres,nested table languages store as lan;

--creation du type ensembliste country
create or replace type T_EnsCountry as table of T_Country;

create or replace type T_Organization as object(
  /*Une Organization a plusieur pays d'ou le countries en attribut et un QG*/
    name varchar2(12),
    --a plusieur pays
    countries T_EnsCountry,
    --a un quartier generalle
    headquarter T_headquarter,
    member function toXML return XMLType
);
/

create or replace type body T_Organization as
    member function toXML return XMLType is
    outPut XMLType;
    begin
    --creation de l'instance
    outPut :=XMLType.createxml('<organization/>');
    
    --Ajout des pays comme fils a organization
    for c in 1..countries.count loop
      outPut := XMLType.appendchildxml(outPut,'organization', countries(c).toXML());
    end loop ;
      --ajout de headquarter comme fils a organization
      outPut := XMLType.appendchildxml(outPut,'organization',headquarter.toXML());
      
      return outPut;
      end;
      
end;
/
/*Une Organization a au moins un pays et le name du QG est requis*/
create table organizations of T_Organization(constraint PNile check(countries is not null),constraint qg check(headquarter.name is not null))
nested table countries store as ps(
nested table border.frontiere store as bd, nested table languages store as lg);

--type ensembliste organization pour mondial
create or replace type T_EnsOrganization as table of T_Organization;

-----------------------Type ET Table MONDIAL------------------------------------------------
create or replace type T_Mondiale as object (
  /*un nom Quelconque */
    name varchar2(10),
    member function toXML return XMLType
);
/

create or replace type body T_Mondiale as
member function toXML return XMLType is 
    outPut XMLType;
    tmpO T_EnsOrganization;
    begin
         outPut :=XMLType.createxml('<mondial/>');
         /*On charge les Country on creer le XMLType*/
         select value(o) bulk collect into tmpO from organizations o;
         --On ajoute les noeuds fils a mondial toute les organisations appelles elle meme toXML du pays
         for o in 1..tmpO.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpO(o).toXML());
          end loop;
        return outPut;
     end;
end;
/

create table Mondial of T_Mondiale;


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
insert into Countries (select T_Country(c.code,c.name,c.population,
                                       (select cast(collect(T_Language(l.name,l.percentage)) as T_EnsLanguage) from language l where c.code=l.country),
                                       T_Borders((select cast(collect (T_Border (c2.code,b.length)) as T_EnsBorder) from borders b,country c2 
                                                  where ((c.code = b.country1 and c2.code = b.country2) or (c.code = b.country2 and c2.code = b.country1))
                                      
                                                ))
                                       )from country c); 
                                                                                                                                             
insert into organizations (select T_Organization(o.abbreviation,
                                                  (select cast(collect (T_Country(c.code ,c.name,c.population,c.languages,c.border)) as T_EnsCountry)  
                                                   from countries c , isMember i where i.organization=o.abbreviation and i.country=c.code ), 
                                                  T_headquarter(o.city))             
                          from organization o where o.city is not null);
                         
insert into mondial values (T_Mondiale('Mondial'));

WbExport -type=text
         -file='mondialExercice1DTD2.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from Mondial m  ;








