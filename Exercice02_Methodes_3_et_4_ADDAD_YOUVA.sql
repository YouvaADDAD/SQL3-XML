/*toutes les méthodes ont été définie dans le type country afin de faire directement la joiture avec self.code
un country un a type contCountries en attribut*/
-----------------------------------------------------------------------------------------------------------------------
create table encompasse as select * from Mondial.encompasses;
--creation de la table encompasse telle que encompasses
------------------------------------------------------------------------------------------------------------------------------------
create table border as select * from Mondial.borders;
--creation de la table border telle que borders
------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Border as object(
    --le type border a le code du pays voisin et la longueur de la frontiere
    countryCode varchar2(4),
    blength number,
    member function toXML return XMLType
);
/
create or replace type body T_Border as
    member function toXML return XMLType is
        outPut XMLType;
        Result varchar2(256);
        begin
          --ajout d'attribut et création de l'instance
          Result := '<border countryCode="'||countryCode||'" length="'||blength||'" />';
          outPut :=XMLType.createxml(Result);
          return outPut;
        end;
    end;
/
--creer un type ensembliste pour border
create type T_EnsBorder as table of T_Border;
----------------------------------------------------------------------------------------------
create type contCountries as object (
    --contCountries a pour type un ensemble de frontiere pour un pays
    frontiere T_EnsBorder,
    member function toXML return XMLType
);
/

create or replace type body contCountries as
    member function toXML return XMLType is
        outPut XMLType;
        begin
          --creation de l'instance
          outPut :=XMLType.createxml('<contCountries />');
          --ajout des noeud fils ,les frontieres du pays
          for p in 1..frontiere.count loop
            outPut := XMLType.appendchildxml(outPut,'contCountries', frontiere(p).toXML()); 
          end loop;
          return outPut;
        end;
    end;
/


create or replace TYPE T_Country as OBJECT(
    --un pays a un code et nom
    --les méthodes continent Principale renvois le continent ou le pourcentage d'appartenance est plus grand
    --BorderPays les frontieres du pays qui appartient a un meme continent
    --blength la longueur de la frontiere total du pays ,avec des pays qu'ils appartiennent ou pas au meme continent
    code varchar2(5),
    name VARCHAR2(60),
    member function continentPrincipale return varchar2,
    member function BorderPays return contCountries,
    member function blength return number,
    --toXML1 pour la validation des méthode continent Principale et BorderPays
    member function toXML1 return XMLType,
    --toXML2 pour la validation des méthodes blength
    member function toXML2 return XMLType
    
);
/
--creation de la table country
create or replace type T_EnsCountry as table of T_Country;

--creation du corps des méthodes
create or replace type body T_Country as
   member function continentPrincipale return varchar2 is
   continent varchar2(50);
   begin
      --je prend le nom du pays qui a le plus grand pourcentage 
      --je fais une joiture avec percentage de encompasse et une sous requete qui renvois le pourcentage maximum
      select e1.continent into continent from encompasse e1  
      where e1.country= self.code and e1.percentage= (select max(e2.percentage) from encompasse e2 where e2.country=self.code) ;  
      return continent;
   end;
   
   member function BorderPays return contCountries is
   --la méthode a pour varible un type ensemble de frontiere ,et ensemble de pays
   bCountry T_EnsBorder ;
   pays T_EnsCountry;
   begin
        --collect des pays du meme continent tous
        select value(c) bulk collect into pays from countries c ,encompasse e where self.continentPrincipale()=e.continent and self.code <>e.country and c.code=e.country;--tout les pays du continent--
        --ensuite joiture entre ces pays et la table border 
        --ici donc on renvois le pays frontalier appartenant au meme pays
        select  cast(collect(T_Border(value(p).code,b.length)) as T_EnsBorder) into bCountry
        from table(pays) p ,border b 
         where (b.country1=self.code and b.country2=value(p).code and value(p).code=b.country2 ) 
                                                   or 
               (b.country2=self.code and b.country1=value(p).code and value(p).code=b.country1);
         --on renvois un type contCountries
         return contCountries(bCountry); 
   end;
   
   member function blength return number is
      result number ;
      begin
      --ici je somme toute les longueurs des frontieres ou le pays apparé comme country1 ou 2 
      --donc ici on somme sur des pays frontalier meme si ils sont pas dans le meme continent 
      select sum(b.length) into result from border b where b.country1=self.code or b.country2=self.code ;
      return result;
      end;
      
      --pour le continent pricipale et borderPays
   member function toXML1 return XMLType is
        outPut XMLType;
        begin
          --creation de l'instance et ajour des attributs
          outPut :=XMLType.createxml('<country name="'||self.name||'" continent="'||self.continentPrincipale()||'" />');
          --ajout des noeuds fils,de type border
          outPut := XMLType.appendchildxml(outPut,'country', self.BorderPays().toXML()); 
          return outPut;
        end; 
    
    --pour la longueur de la frontieres
    member function toXML2 return XMLType is
        outPut XMLType;
        begin
          --creation de l'instance avec ajouts des attributs,et calcul de la frontieres total
          outPut :=XMLType.createxml('<country name="'||self.name||'" blength="'||self.blength()||'" />');
          --ajout des pays appartenant au meme continent
          outPut := XMLType.appendchildxml(outPut,'country', self.BorderPays().toXML()); 
          return outPut;
        end;
end;
/

--creation de la table Country faut d'abord creer la table country ensuite exécuter le body
create table countries of T_Country;

------------------------------------------------------------------------------------------------------------------------------------------------------
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
    begin
         outPut :=XMLType.createxml('<mondial/>');
         /*Collect des object pays a mondial*/
         select value(c) bulk collect into tmpC from countries c;
         --ajout de noeud fils country 
         for c in 1..tmpC.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpC(c).toXML1());
          end loop;
        return outPut;
     end;
end;
/

--creation de la table
create table Mondial of T_Mondial;
------------------------------------------------------------------------------------------------------------------------------------------------------

insert into countries (select T_Country(c.code,c.name) from country c);

insert into mondial values(T_Mondial('Mondial'));

WbExport -type=text
         -file='MondialExercice2ContBord.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from mondial m ;
