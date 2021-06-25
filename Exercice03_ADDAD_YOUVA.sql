/*Une province a un ensemble de montagnes , un pays a un ensemble de province ainsi que les idrefs 
des organisations auquel il appartient ainsi que les rivieres source dont il est le source
les montagnes ont des coordonnées 
et chaque continent a un ensemble de pays qui l'englobe
*/
---------------------------------------------------------------------------------------------------------------------------
--le type Coordoonée pour les coordonnées pour montagne 
create or replace type T_Coordinates as object(
    Latitude number,
    Longitude number,
    member function toXML return XMLType
);
/

create or replace type body T_Coordinates as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        -- Ajout des attributs
        outPut:=XMLType.createxml ('<coordinates latitude="'|| Latitude ||'" ' || 'longitude="'||Longitude ||'" '||'/>' );
        return outPut;
    end;
end;
/ 
-------------------------------------------------------------------------------------------------------------------------------------
create or replace type  T_Mountain as object(
    --la montagne a pour attribut l'altitude
    name varchar2(50),
    height number,
    --un type coordinate pour latitude et longitude
    coordinates T_Coordinates,
    --la province a laquelle elle appartient (elle peut appartenir a plusieur province différente)
    province varchar2(50),
    member function toXML return XMLType 
);
/

create or replace type body T_Mountain as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --creation de l'instance et ajout d'attibut 
        outPut:=XMLType.createxml ('<mountain name="'|| name ||'" ' || 'height="'||height ||'" '||'/>' );
        --les coordonnées peuvents etre null
        if coordinates is not null then
              output := XMLType.appendchildxml(output,'mountain', coordinates.toXML());
        end if;
        return outPut;
    end;
end;
/

--creation d'un type ensebmliste de montagne
create or replace type T_EnsMountain as table of T_Mountain;
/

--creation de la table avec ajout des contrainte
create table mountains of T_Mountain(name NOT NULL,height NOT NULL,constraint coordinatesLatitude check (coordinates.Latitude is not null),
                                               constraint coordinatesLongitude check(coordinates.Longitude is not null));
                                               /
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE type T_Province as OBJECT(
    --country represente le pays d'appartenance de la province 
    name VARCHAR2(50),
    country varchar2(4),
    member function toXML return XMLType 
);
/

create or replace type body T_Province as
    member function toXML return XMLType is
    outPut XMLType;
    Result varchar2(256);
    --l'ensemble des montagnes de la province
    tmpEnsM T_EnsMountain;
    begin
        --creation de l'instance
        Result:= '<province name="'|| name ||'" />';
        outPut :=XMLType.createxml(Result);
        --collect des montagne de la province
        select value(m) bulk collect into tmpEnsM from mountains m where self.name=m.province;
        --Ajout des noeuds fils montagne ,pour province
        for m IN 1..tmpEnsM.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'province', tmpEnsM(m).toXML());   
            end loop; 
            
        return outPut;    
        end;
end;
/ 

--creation d'un type ensebmliste pour les provinces
create or replace type T_EnsProvince as table of T_Province;
/
--creation de la table avec contrainte pour name et country
create table Provinces of T_Province (name not null,country not Null ) ;
/

------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Organization as object (
    --le type organization a un nom et une appreviation et une date de creation
    abbreviation varchar2(12),
    name varchar2(100),
    created date,
    member function toXML return XMLType
);
/
    
create or replace type body T_Organization as
    member function toXML return XMLType is
    outPut XMLType;
    result varchar2(256);
    begin
        --comme y a des organizations qui ont des espaces au miliu de l'abbreviation je prend donc l'abbreviation
        --hoter des espaces avec la fonction replace auquel j'ajoute le prefix '-Org' pour que sa ce sois un identifiant
        --ensuite les autres attributs s'ajoute 
        result :='<organization id="Org-'|| replace(abbreviation,' ','') ||'" abbreviation="'||abbreviation||'" name="'||name||'" ';
        --ici je regarde si la date de creation est existante
        if created is not null then
            result :=result || ' dateCreation="'||created||'" ';
        end if;
        result :=result||'/>';
        --creation de l'instance
        outPut:=XMLtype.createxml(result);    
    return outPut;
    end;
end;
/

--creation de la table organization avec les contrainte
create table organizations of T_Organization(
    abbreviation constraint OrgaKey primary Key,
    name not null
);/
--creation du type ensembliste d'organization
create or replace type T_EnsOrganization as table of T_Organization;
/
------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Border as object(
    --country le pays voisins 
    country varchar2(4),
    --la longueur de la frontiere 
    length number,
    member function toXML return XMLType
);
/

create or replace type body T_Border as
  member function toXML return XMLType is
  outPut XMLType;
  begin
    --ajout des attributs country et length
    outPut := XMLType.createxml('<border country="'||country||'" ' ||'length="'||length||'" />');
    return outPut;
  end;
end;
/

--creation d'un type ensembliste 
create type T_EnsBorder as table of T_Border;
/
------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_river as object(
    --une riviere a un nom et une longueur
    name varchar2(50),
    length number,
    member function toXML return XMLType
);
/

        
create or replace type body T_river as
    member function toXML return XMLType is
    outPut XMLType;
    result varchar2(100);
    begin
        --ici de meme y a des rivieres qui on des espaces et des / donc je les supprime et je rajour riv- comme
        --prefix pour former un identifiant 
        result :='<river id="riv-'|| replace(replace(name,' ',''),'/','')||'" name="'||name||'" ';
        if length is not null then
            result :=result || 'length="'||length||'" ';
        end if;
        result := result ||'/>';
        outPut:=XMLtype.createxml(result);
        return outPut;
    end;
end;
/

--creaton du type ensembliste et de la table riviere ainsi que des contraintes
create or replace type T_EnsRiver as table of T_river;
/
create table rivers of T_river(name constraint riverKey primary Key);
/
------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Country as object(
    --un pays a les provinces ,les frontiere avec laquelle elle est liee et ,les riviere source de ce pays,ainsi
    --que les organizations auquel elle est affilier
    name varchar2(50) ,
    code varchar2(4),
    population number,
    province T_EnsProvince,
    border T_EnsBorder,
    SourceC T_EnsRiver,
    affilier T_EnsOrganization,
    member function toXML return XMLType
);
/


create or replace type body T_Country as
  member function toXML return XMLType is
    outPut XMLType;
    Result varchar2(1000);
    rivS varchar2(256);
    OrgaMember varchar2(1000);
    begin
        --ajout d'attribut
        Result:= '<country name="'|| name ||'" code="'||code||'" population="'||population||'" ';
        rivS :='';
        OrgaMember :='';
        --l'ajout d'attribut source qui est de type IDREFS 
        for c in 1..SourceC.count loop
            --j'ajoute un préfix au début pour dire que c'est une riviére pour le l'ID de riviere 
            --afin de pouvoir utilisé la fonction id()
          rivS :=rivS||'riv-'|| replace(replace(SourceC(c).name,' ',''),'/','');
          if(c<>SourceC.Count) then rivS := rivS||' '; end if;
        end loop;
        if(SourceC.count>0) then Result := Result ||'Source="'||rivS||'" '; end if ;
        
        --ajout des organizations en form d'attribut qui est un IDREFS aussi pour chaque pays
        --ajout d'un préfix pour afin de former un ID , qui va etre utilisé pour la fonction id()
        for o in 1..affilier.count 
          loop
            OrgaMember := OrgaMember||'Org-'|| replace(affilier(o).abbreviation,' ','')||' ';
          end loop;
         if(affilier.count>0) then Result := Result || 'isMember="'|| OrgaMember||'" '; end if ;
        result :=result||'/>';
        outPut :=XMLType.createxml(Result);
        
        --les provinces comme noeud fils
        for p in 1..province.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', province(p).toXML());
          end loop;
        
        --frontieres comme fils de country aussi
        for b in 1..border.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', border(b).toXML());
          end loop;
        return outPut;
        end;
 end;
/

--creation dy type ensebmliste de country
create or replace type T_EnsCountry as table of T_Country;
/

--creation des tables avec les contraites et les nested table
create table Countries of T_country(code constraint paysKey primary Key,name not null)
nested table province store as prov , nested table border store as bord,nested table SourceC store as RivS,nested table affilier store as member;/
------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Continent as object(
     -- un continent a un ensemble de pays lui appartenant
     --un pays peu apparaitre plusieur fois ,sur deux continent different par exemple
     name varchar2(50),
     country T_EnsCountry,
     member function toXML return XMLType
);
/

create or replace type body T_Continent as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --creation de l'instance
        outPut:=XMLType.createxml ('<continent name="'|| name ||'" />' );
        --ajout des country comme des fils a continent en appelant la méthode toXML de chaque country
        for c in 1..country.count loop
          outPut := XMLType.appendchildxml(outPut,'continent', country(c).toXML());
        end loop;
        return outPut;
    end;
end;
/ 

--creation de la table continent avec les contraintes et les nested table 
create table Continents of T_Continent(name not Null)
nested table country store as cr(nested table province store as p , nested table border store as b,nested table SourceC store as RivSo,nested table affilier store as m) ;
--creation d'un type ensembliste pour mondia
create or replace type T_EnsContinent as table of T_Continent  ;
/
------------------------------------------------------------------------------------------------------------------------------------------------
create or replace type T_Mondial as object (
    --un nom quelconque ,sers de main 
    name varchar2(10),
    member function toXML return XMLType
);
/

create or replace type body T_Mondial as
  member function toXML return XMLType is 
    outPut XMLType;
    --On prend tout les continents ,organization,river de base de donnée 
    tmpC T_EnsContinent;
    tmpO T_EnsOrganization;
    tmpR T_EnsRiver;
    
    begin
        --cration de l'instance
         outPut :=XMLType.createxml('<mondial/>');
         --collect des continent,organization,river
         select value(c) bulk collect into tmpC from continents c;
         select value(o) bulk collect into tmpO from organizations o;
         select value(r) bulk collect into tmpR from rivers r;
         
         --ajout des noeuds fils continent qui lui meme ajoute ces country qui lui meme ajoute les provices,qui lui
         --meme ajoute les mountais
         
         for c in 1..tmpC.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpC(c).toXML());
          end loop;
          --ajout des organisations 
          for o in 1..tmpO.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpO(o).toXML());
          end loop;
          --ajout des rivers
          for r in 1..tmpR.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpR(r).toXML());
          end loop;
          
        return outPut;
        end;
end;
/

create table Mondial of T_Mondial;/
------------------------------------------------------------------------------------------------------------------------------------------

insert into organizations ((select T_organization(o.abbreviation,o.name,o.established) from organization o ))order by o.established;
/
insert into mountains (select T_mountain(m.name,m.height,T_coordinates(m.Coordinates.Latitude,m.Coordinates.Longitude),g.province) 
from mountain m ,geo_mountain g where m.name=g.mountain);
/
insert into provinces (select T_Province(p.name,p.country) from province p);
/
insert into countries (select T_country(c.name,c.code,c.population,
                      (select cast (collect(T_province(p.name,p.country)) as T_EnsProvince ) from province p where p.country=c.code),
                      (select cast(collect (T_Border (c2.code,b.length)) as T_EnsBorder) from borders b,country c2 
                      where ((c.code = b.country1 and c2.code = b.country2) or (c.code = b.country2 and c2.code = b.country1))),
                      (select cast(collect (T_River(r.name,r.length)) as T_EnsRiver) from geo_source g ,river r where r.name=g.river and g.country=c.code),
                      (select cast (collect(T_Organization(o.abbreviation,o.name,o.created)) as T_EnsOrganization) from ismember i,organizations o 
                      where i.country=c.code and o.abbreviation=i.organization)
                      )from country c); 
                      
/

insert into rivers (select T_River(r.name,r.length)from river r );
/

insert into Continents (select T_Continent(co.name,(select cast(collect (value(c)) as T_EnsCountry ) 
from countries c ,encompasses e where c.code=e.country and e.continent=co.name)
)from continent co);
/

insert into mondial values (T_Mondial('Mondial'));
/

WbExport -type=text
         -file='MondialExercice3.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/
select m.toXML().getClobVal()
from mondial m;
