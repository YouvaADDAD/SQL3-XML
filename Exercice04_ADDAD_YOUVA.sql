/*les elements continent en des id qui représente maitnant les noms de continent en lower
un pays prend comme idrefs les continents auquel il appartient
de meme pour les organizations 
les rivers aussi prennent comme idref les pays dont la riviere est source
pour l'utilisation de la fonction id()*/
---------------------------------------------------------------------------------------------------------------------------
--le type Coordonnée n'a pas éte change c'est le même que précedemment
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
        --ajout des attributs
        outPut:=XMLType.createxml ('<coordinates latitude="'|| Latitude ||'" ' || 'longitude="'||Longitude ||'" '||'/>' );
        return outPut;
    end;
end;
/ 
-------------------------------------------------------------------------------------------------------------------------------------
--Meme type que l'exercice 3
create or replace type  T_Mountain as object(
    name varchar2(50),
    height number,
    coordinates T_Coordinates,
    province varchar2(50),
    member function toXML return XMLType 
);
/

create or replace type body T_Mountain as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        outPut:=XMLType.createxml ('<mountain name="'|| name ||'" ' || 'height="'||height ||'" '||'/>' );
        if coordinates is not null then
              output := XMLType.appendchildxml(output,'mountain', coordinates.toXML());
        end if;
        return outPut;
    end;
end;
/

create or replace type T_EnsMountain as table of T_Mountain;
/
create table mountains of T_Mountain(name NOT NULL,height NOT NULL,constraint coordinatesLatitude check (coordinates.Latitude is not null),
                                               constraint coordinatesLongitude check(coordinates.Longitude is not null));
/
------------------------------------------------------------------------------------------------------------------------------------------------
--Meme type que l'exercice 03
CREATE OR REPLACE type T_Province as OBJECT(
    name VARCHAR2(50),
    country varchar2(4),
    member function toXML return XMLType 
);
/

create or replace type body T_Province as
    member function toXML return XMLType is
    outPut XMLType;
    Result varchar2(256);
    tmpEnsM T_EnsMountain;
    begin
        Result:= '<province name="'|| name ||'" />';
        outPut :=XMLType.createxml(Result);
        select value(m) bulk collect into tmpEnsM from mountains m where self.name=m.province;
        
        for m IN 1..tmpEnsM.COUNT
            loop
               outPut := XMLType.appendchildxml(outPut,'province', tmpEnsM(m).toXML());   
            end loop; 
            
        return outPut;    
        end;
end;
/ 

create or replace type T_EnsProvince as table of T_Province;
/
create table Provinces of T_Province (name not null,country not Null ) ;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--les Organizations meme type que l'exercice 03
create or replace type T_Organization as object (
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
    id varchar2(20);
    begin
        id:='Org-'||abbreviation;
        result :='<organization id="'|| REPLACE(id,' ','') ||'" abbreviation="'||abbreviation||'" name="'||name||'" ';
        if created is not null then
            result :=result || ' dateCreation="'||created||'" ';
        end if;
        result :=result||'/>';
        outPut:=XMLtype.createxml(result);    
    return outPut;
    end;
end;
/


create table organizations of T_Organization(
    abbreviation constraint OrgaKey primary Key,
    name not null
);
/
create or replace type T_EnsOrganization as table of T_Organization;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--Meme que exercice 03
create or replace type T_Border as object(
    country varchar2(4),
    length number,
    member function toXML return XMLType
);
/

create or replace type body T_Border as
  member function toXML return XMLType is
  outPut XMLType;
  begin
    outPut := XMLType.createxml('<border country="'||'Cou-'||country||'" ' ||'length="'||length||'" />');
    return outPut;
  end;
end;
/

create type T_EnsBorder as table of T_Border;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--Les continents ont un name et dans le XML ils ont un id qui est le lower du nom du continent
create or replace type T_Continent as object(
     name varchar2(50),
     member function toXML return XMLType
);
/

create or replace type body T_Continent as
    member function toXML return XMLType is
    outPut XMLType;
    begin
        --le replace '/' c'est parce que il y a un continent contenant ce caractere '/' qui ne peux pas etre pris
        --comme id 
        outPut:=XMLType.createxml ('<continent id="'||lower(replace(name,'/',''))||'" name="'|| name ||'" />' );
        return outPut;
    end;
end;
/ 

create table Continents of T_Continent(name not Null);
/
create or replace type T_EnsContinent as table of T_Continent  ;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--Le type country prend l'ensemble des previnces ,des borders
--on prend aussi l'ensemble des continents ainsi que l'ensemble des organization pour le mettre en attributs du 
--XML comme type IDREFS
create or replace type T_Country as object(
    name varchar2(50) ,
    code varchar2(4),
    population number,
    province T_EnsProvince,
    border T_EnsBorder,
    continent T_EnsContinent,
    affilier T_EnsOrganization,
    member function toXML return XMLType
);
/


create or replace type body T_Country as
  member function toXML return XMLType is
    outPut XMLType;
    Result varchar2(1000);
    ContiIn varchar2(256);
    OrgaMember varchar2(1000);
    id varchar2(20);
    begin
        --ajout du préfix
        id:='Cou-'||code;
        --replacement des espaces en vides pour le id du country
        Result:= '<country id="'|| REPLACE(id,' ','') ||'" name="'|| name ||'" code="'||code||'" population="'||population||'" ';
        ContiIn :='';
        OrgaMember :='';
        --ajout de noeuds de l'attributs continent 
        for c in 1..continent.count loop
          ContiIn := ContiIn||lower(replace(continent(c).name,'/',''));
          if(c<>continent.Count) then ContiIn := ContiIn||' '; end if;
        end loop;
        Result := Result ||'continent="'||ContiIn||'" ';
        --ajout de l'attribut isMember 
        for o in 1..affilier.count 
          loop
            OrgaMember := OrgaMember||'Org-'||REPLACE(affilier(o).abbreviation,' ','')||' ';
          end loop;
         if(length(OrgaMember)>0) then Result := Result || 'isMember="'|| OrgaMember||'" '; end if ;
         result :=result||'/>';
        outPut :=XMLType.createxml(Result);
        --ajout des noeuds fils provinces
        for p in 1..province.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', province(p).toXML());
          end loop;
        --Ajout des Borders
        for b in 1..border.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'country', border(b).toXML());
          end loop;
        return outPut;
        end;
 end;
/

create or replace type T_EnsCountry as table of T_Country;
/

create table Countries of T_country(code constraint paysKey primary Key,name not null)
nested table province store as prov , nested table border store as bord,nested table continent store as cont,nested table affilier store as member;
/
------------------------------------------------------------------------------------------------------------------------------------------------
--le type river prend un ensemble de pays dont il est source
create or replace type T_river as object(
    name varchar2(50),
    length number,
    source T_EnsCountry,
    member function toXML return XMLType
);
/

        
create or replace type body T_river as
    member function toXML return XMLType is
    outPut XMLType;
    result varchar2(100);
    essue varchar2(1000);
    begin
       --Ajout des attributs name
        result :='<river name="'||name||'" ';
        if length is not null then
            --on check si length n'est pas null
            result :=result || 'length="'||length||'" ';
        end if;
        essue :='';
        --ajout en attributs des pays dont il est le source comme IDREFS
        for c in 1..source.count 
          loop
            essue := essue||'Cou-'||REPLACE(source(c).code,' ','');
            if(c<>source.Count) then essue := essue||' '; end if;
          end loop;
          if(source.count>0) then result := result || 'source="'||essue||'" '; end if;
          result := result ||'/>';
          outPut:=XMLtype.createxml(result);
          return outPut;
    end;
end;
/

create or replace type T_EnsRiver as table of T_river;
/
create table rivers of T_river(
    name constraint riverKey primary Key)
nested table source store as sr(nested table province store as proven , nested table border store as bd,nested table continent store as co,nested table affilier store as mem);
/
------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------
--Sers de main lance tout et remplit le fichier XML
create or replace type T_Mondial as object (
    name varchar2(10),
    member function toXML return XMLType
);
/

create or replace type body T_Mondial as
  member function toXML return XMLType is 
    outPut XMLType;
    tmpC T_EnsContinent;
    tmpCo T_EnsCountry;
    tmpO T_EnsOrganization;
    tmpR T_EnsRiver;
    
    begin
         outPut :=XMLType.createxml('<mondial/>');
         select value(c) bulk collect into tmpC from continents c;
         select value(co) bulk collect into tmpCo from countries co;
         select value(o) bulk collect into tmpO from organizations o;
         select value(r) bulk collect into tmpR from rivers r;
         
         for c in 1..tmpC.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpC(c).toXML());
          end loop;
          
          for co in 1..tmpCo.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpCo(co).toXML());
          end loop;

          for o in 1..tmpO.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpO(o).toXML());
          end loop;
          
          for r in 1..tmpR.count 
          loop
            outPut := XMLType.appendchildxml(outPut,'mondial', tmpR(r).toXML());
          end loop;
          
        return outPut;
        end;
end;
/

create table Mondial of T_Mondial;
/

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into organizations ((select T_organization(o.abbreviation,o.name,o.established) from organization o ));

insert into mountains (select T_mountain(m.name,m.height,T_coordinates(m.Coordinates.Latitude,m.Coordinates.Longitude),g.province) 
from mountain m ,geo_mountain g where m.name=g.mountain);

insert into provinces (select T_Province(p.name,p.country) from province p);

insert into Continents (select T_Continent(c.name) from continent c); 

insert into countries (select T_country(c.name,c.code,c.population,
                      (select cast (collect(T_province(p.name,p.country)) as T_EnsProvince ) from province p where p.country=c.code),
                      (select cast(collect (T_Border (c2.code,b.length)) as T_EnsBorder) from borders b,country c2 
                      where ((c.code = b.country1 and c2.code = b.country2) or (c.code = b.country2 and c2.code = b.country1))),
                      (select cast(collect(T_continent(e.continent)) as T_EnsContinent) from encompasses e where e.country=c.code),
                      (select cast (collect(T_Organization(o.abbreviation,o.name,o.created)) as T_EnsOrganization) from ismember i,organizations o 
                      where i.country=c.code and o.abbreviation=i.organization)
                      )from country c); 

insert into rivers (select T_River(r.name,r.length,
                                  (select cast (collect(value(c)) as T_EnsCountry ) from countries c,geo_source g where g.country=c.code and r.name=g.river)  
                   )from river r );




insert into mondial values (T_Mondial('Mondial'));


WbExport -type=text
         -file='MondialExercice4.xml'
         -createDir=true
         -encoding=ISO-8859-1
         -header=false
         -delimiter=','
         -decimal=','
         -dateFormat='yyyy-MM-dd'
/
select m.toXML().getClobVal()
from mondial m;


