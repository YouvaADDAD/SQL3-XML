--Le bloc PL/SQL pour la création du XMLSchema pour tester la validation d'un fichier
--Il faut ajouter le fichier avec la commande dbms_xmlschema.registerSchema qui prend le 
--nom du fichier ainsi que le fichier lui meme
--ensuite on regarde avec XMLISVALID qui prend un XMLType et un nom de fichier
--ensuite il regarde si le fichier en question est enregistrer dans la base
--la fonction renvoie 1 si schema valide 0 sinon
Declare 
 
 Begin
 dbms_xmlschema.registerSchema('SchemaEX3.xsd',
 '<xs:schema
  xmlns:xs="http://www.w3.org/2001/XMLSchema">

 <xs:element name="mondial">
  <xs:complexType>
   <xs:sequence>
    <xs:element ref="continent" minOccurs="0" maxOccurs="unbounded"/>
    <xs:element ref="organization" minOccurs="0" maxOccurs="unbounded"/>
    <xs:element ref="river" minOccurs="0" maxOccurs="unbounded"/>
   </xs:sequence>
  </xs:complexType>
 </xs:element>

 <xs:element name="continent">
  <xs:complexType>
   <xs:sequence>
    <xs:element ref="country" minOccurs="0" maxOccurs="unbounded"/>
   </xs:sequence>
   <xs:attribute name="name" type="xs:string" use="required"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="country">
  <xs:complexType>
   <xs:sequence>
    <xs:element ref="province" minOccurs="0" maxOccurs="unbounded"/>
    <xs:element ref="border" minOccurs="0" maxOccurs="unbounded"/>
   </xs:sequence>
   <xs:attribute name="name" type="xs:string" use="required"/>
   <xs:attribute name="code" type="xs:string" use="required"/>
   <xs:attribute name="population" type="xs:string" use="required"/>
   <xs:attribute name="Source" type="xs:IDREFS" use="optional"/>
   <xs:attribute name="isMember" type="xs:IDREFS" use="optional"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="province">
  <xs:complexType>
   <xs:sequence>
    <xs:element ref="mountain" minOccurs="0" maxOccurs="unbounded"/>
   </xs:sequence>
   <xs:attribute name="name" type="xs:string" use="required"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="mountain">
  <xs:complexType>
   <xs:sequence>
    <xs:element ref="coordinates" minOccurs="0" maxOccurs="1"/>
   </xs:sequence>
   <xs:attribute name="name" type="xs:string" use="required"/>
   <xs:attribute name="height" type="xs:string" use="required"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="coordinates">
  <xs:complexType>
   <xs:attribute name="latitude" type="xs:string" use="required"/>
   <xs:attribute name="longitude" type="xs:string" use="required"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="border">
  <xs:complexType>
   <xs:attribute name="country" type="xs:string" use="required"/>
   <xs:attribute name="length" type="xs:string" use="required"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="organization">
  <xs:complexType>
   <xs:attribute name="id" type="xs:ID" use="required"/>
   <xs:attribute name="abbreviation" type="xs:string" use="required"/>
   <xs:attribute name="name" type="xs:string" use="required"/>
   <xs:attribute name="dateCreation" type="xs:string" use="optional"/>
  </xs:complexType>
 </xs:element>

 <xs:element name="river">
  <xs:complexType>
   <xs:attribute name="id" type="xs:ID" use="required"/>
   <xs:attribute name="name" type="xs:string" use="required"/>
   <xs:attribute name="length" type="xs:string" use="optional"/>
  </xs:complexType>
 </xs:element>
</xs:schema>
');

end ;
/
SELECT schema_url FROM user_xml_schemas;

select XMLISVALID(m.toXML(), 'SchemaEX3.xsd') from mondial m;
