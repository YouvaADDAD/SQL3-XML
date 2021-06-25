/*Les méthodes compute et peak ont été définie dans le type country
un country un a type geo en attribut
les méthode match c'est pour l'utilisation de distinct faut surcharger la méthode order afin d y arriver*/
------------------------------------Type ET Table COORDINATE--------------------------------------------------------------------
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
       --ajout d'attribut
        outPut:=XMLType.createxml ('<coordinates latitude="'|| Latitude ||'" ' || 'longitude="'||Longitude ||'" '||'/>' );
        return outPut;
    end;
end;
/ 
-------------------------------------Type ET Table ISLAND-----------------------------------------------------------
create or replace TYPE T_island as object (
    /*pour ici aussi une island appartient a une seul province et une province a zero ou plusieur islands*/
    --peu contenir une coordonnée
    name varchar2(50),
    coordinates T_coordinates,
    --l'attribut province pour retrouver les Islands appartenant a cette province
    province varchar2(50),
    --methode pour comparer des instances islands , c'est pour la méthode distinct
    --l'equivalent de la méthode equal de java
    ORDER MEMBER FUNCTION match (m T_island) RETURN number,
    member function toXML return XMLType
);
/


create or replace type body T_island as
    order member function match (m T_island) return number is
         begin
              --si le nom de self et plus grand que le nom de l'instance en parametre je renvois 1 si egalité 0 sinon -1
              if self.name>m.name then return 1;
              elsif self.name<m.name then return -1;           
              else return 0;
              end if;
         end;

    member function toXML return XMLType is
    outPut XMLType;
    begin
        --creation de l'instance et ajout d'attribut
        outPut:=XMLType.createxml ('<island name="'||name||'" />');
        --en regarde si la coordonnée est null
        if coordinates is not null then
              output := XMLType.appendchildxml(output,'island', coordinates.toXML());
        end if;
       return outPut;
    end;
end;
/ 

/*on cree une contraint pour que les latitude et longitude ne sois pas null et le nom de l'island ne sois pas null aussi*/
create table Islands of T_island(name NOT NULL,constraint coordinatesLatitude check (coordinates.Latitude is not null),
                                               constraint coordinatesLongitude check(coordinates.Longitude is not null));
--Creation de type ensembliste 
create or replace type T_islands as table of T_island;
-----------------------Type ET Table ZONE-------------------------------------------------------------------------------------
create or replace type  T_Mountain as object(
    /*Une montagne appartient a une province et une province peu avoir plusieur montagnes*/
    name varchar2(50),
    height number,
    --l'attribut province pour retrouver les montagnes appartenant a cette province
    province varchar2(50),
    --methode pour ordonnée, pour le distinct
    ORDER MEMBER FUNCTION match (m T_Mountain) RETURN number,
    member function toXML return XMLType 
);
/

create or replace type body T_Mountain as
    order member function match (m T_Mountain) return number is
         begin
            --si nom equivalent renvois 0 si nom de self plus grand alors 1 sinon -1
              if self.name>m.name then return 1;
              elsif self.name<m.name then return -1;           
              else return 0;
              end if;
         end;
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --ajout d'attribut et creation d'instance
        outPut:=XMLType.createxml ('<mountain name="'|| name ||'" ' || 'height="'||height ||'" '||'/>' );
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
    --methode pour ordonnée, pour le distinct
    ORDER MEMBER FUNCTION match (m T_Desert) RETURN number,
    member function toXML return XMLType
);
/

create or replace type body T_Desert as
     order member function match (m T_Desert) return number is
         begin
             --si nom equivalent renvois 0 si nom de self plus grand alors 1 sinon -1
              if self.name>m.name then return 1;
              elsif self.name<m.name then return -1;           
              else return 0;
              end if;
         end;
    member function toXML return XMLType is
    outPut XMLType;
    Result varchar2(256);
    begin
        --ajout d'attribut
        Result:= '<desert name="'|| name ||'" ';
        --compare si l'area n'est pas null pour le #IMPIELED
        if area is not null then Result := Result || 'area="' || area || '"';
        end if ;
        Result := Result || ' />';
        --creation de l'instance
        return XMLtype.createxml(Result);
    end;
end;
/ 

--creation des types ensemblistes
create or replace type T_EnsDesert as table of T_Desert;
create or replace type T_EnsMountain as table of T_Mountain;
--creation des tables avec contraintes
create table Mountains of T_Mountain(name NOT NULL,height NOT NULL);
create table Deserts of T_Desert( name NOT NULL);



------------------------------------------------------------------------------------------------------------------
--on prend la table province telle qu'elle
create table provinces as select * from Mondial.province;
------------------------------------------------------------------------------------------------------------------

create or replace type T_geo as object (
    --le type geo a un ensemble de montagne ,de deserts,et d'islands distincts
    mountains T_EnsMountain,
    deserts  T_EnsDesert,
    islands  T_islands,
    member function toXML return XMLType
);
/

create or replace type body T_geo as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --creation de l'instance
        outPut :=XMLType.createxml('<geo/>'); 

        --Ajout des fils montagne 
        for m IN 1..mountains.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'geo', mountains(m).toXML());   
            end loop; 
        --Ajout des fils deserts   
        for d IN 1..deserts.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'geo', deserts(d).toXML());   
            end loop;
        --Ajout des fils islands  
        for i in 1..islands.count loop
            outPut := XMLType.appendchildxml(outPut,'geo', islands(i).toXML());
        end loop;
        
        return outPut;    
        end;
end;
/ 
------------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Country as object(
    --country a un nom code et un type geo
    name varchar2(50) ,
    code varchar2(4),
    geographie T_geo,
    --compute pour le calcul des montagnes,deserts,islands distinct
    member function compute return T_geo,
    --peak pour la plus haute montagne du pays
    member function peak return number,
    --toXML1 pour la question 1 celle des montagnes/deserts/islands distinct
    member function toXML1 return XMLType,
    --toXML2 pour la question 2 celle de la plus haute montagne
    member function toXML2 return XMLType
);
/

create or replace type body T_Country as
    member function compute return T_geo is
        --la méthode compute renvois un type T_geo
        --des variables de type ensembliste pour la collect
        tmpM  T_EnsMountain;
        tmpD  T_EnsDesert;
        tmpI  T_islands;
    begin
          --on collect les montagnes/deserts/islands distinct grace a la methode match sa fonctionne bien
          select  distinct value(m) bulk collect into tmpM from mountains m ,provinces p where p.country=self.code and m.province=p.name;
          select  distinct value(d) bulk collect into tmpD from deserts d ,provinces p where p.country=self.code and d.province=p.name;
          select  distinct value(i) bulk collect into tmpI from islands i ,provinces p where p.country=self.code and i.province=p.name;
    --on renvois le type T_geo     
    return T_geo(tmpM,tmpD,tmpI);
    end;

    member function peak return number is 
    maximum number;
    tmp T_geo;
    begin
        --la fonction coalesce renvois la premiere expression non null en argument
        --si max(value(m).height) n'est pas null on le renvois sinon 0
        --mais geographie.mountains aurai marcher a condition que la table ne sois pas vide
        --note comme je splitte les deux méthodes dans un meme fichier je calcule les geo pour un pays et je prend le max de la montagne
        --si la table country est vide on pourra quand meme avoir le resultat
        tmp:=self.compute();
        select coalesce(max(value(m).height),0) into maximum from table(tmp.mountains) m;
        return maximum;
    end;
    
    member function toXML1 return XMLType is
    outPut XMLType;
    Result varchar2(256);
    begin
        --ajout d'attribut
        Result:= '<country name="'||name||'" />';
        --creation d'instance
        outPut :=XMLType.createxml(Result);
        --ajout de fils  , geo appelle son toXML
        outPut :=XMLType.appendchildxml(outPut,'country', self.compute().toXML());
        return outPut;
    end;

    member function toXML2 return XMLType is
    outPut XMLType;
    Result XMLType;
    begin
        --creation d'instance 
        outPut :=XMLType.createxml('<country name="'||name||'" />');
        --ajout des montagne ,deserts ,islands au noeud country,comme noeud fils
        outPut :=XMLType.appendchildxml(outPut,'country', self.compute().toXML());
        --on ajoute un fils peak qui contient le peak de la plus haute montagne
        result :=XMLType.createxml('<peak height="'||self.peak()||'" />');
        --je le rajour seulement si il est superieur a 0
        if(self.peak()>0) then   outPut :=XMLType.appendchildxml(outPut,'country', result); end if;
        return outPut;
    end;
end;
/

--creation de la table avec les contraites et les nesteds tables
create table Countries of T_country(code constraint CountryKey primary Key,name not null)
nested table geographie.mountains store as mt,nested table geographie.deserts store as ds,nested table geographie.islands store as isl;
--creation du type ensembliste
create or replace type T_EnsCountry as table of T_Country;
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
         --ajout des noeuds fils a mondial
         for c in 1..tmpC.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpC(c).toXML2());
          end loop;
        return outPut;
     end;
end;
/
--creation de la table
create table Mondial of T_Mondial;
------------------------------------------------------------------------------------------------------------------------------------------------------

insert into Islands (select T_island(i.name, T_coordinates(i.Coordinates.Latitude,i.Coordinates.Longitude),g.province) 
from island i ,geo_Island g where i.Name=g.Island and (i.Coordinates.Latitude is not null or i.Coordinates.Longitude is not null ));

insert into Mountains (select T_Mountain(m.name,m.height,g.province) from mountain m ,geo_Mountain g where m.Name=g.mountain);


insert into Deserts (select T_Desert(d.name,d.area,g.province) from desert d,geo_desert g where d.name=g.desert);

insert into countries (select T_Country(c.name,c.code,T_geo(T_EnsMountain(),T_EnsDesert(),T_islands())) from country c);



update countries c
set c.geographie = c.compute()   result----type geo----


insert into mondial values(T_Mondial('Mondial'));

WbExport -type=text
         -file='mondialExercice2Peak.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/

select m.toXML().getClobVal() 
from mondial m ;

