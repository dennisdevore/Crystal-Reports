create or replace view custitemchembolview
(
    custid,
    item,
    type,
    chemcode1,
    chemcode2,
    chemcode3,
    chemcode4,
    bolcomment1,
    bolcomment2,
    bolcomment3,
    bolcomment4,
    lastuser,
    lastupdate
)
as
select
    custid,
    item,
    'DOT',
    primarychemcode,
    secondarychemcode,
    tertiarychemcode,
    quaternarychemcode,
    C1.dotbolcomment,
    C2.dotbolcomment,
    C3.dotbolcomment,
    C4.dotbolcomment,
    custitem.lastuser,
    custitem.lastupdate
  from chemicalcodes C1, 
       chemicalcodes C2,
       chemicalcodes C3,
       chemicalcodes C4,
       custitem
  where
        primarychemcode = C1.chemcode(+)
           and  secondarychemcode = C2.chemcode(+)
   and  tertiarychemcode = C3.chemcode(+)
   and  quaternarychemcode = C4.chemcode(+)
union
select
    custid,
    item,
    'IMO',
    imoprimarychemcode,
    imosecondarychemcode,
    imotertiarychemcode,
    imoquaternarychemcode,
    C1.imobolcomment,
    C2.imobolcomment,
    C3.imobolcomment,
    C4.imobolcomment,
    custitem.lastuser,
    custitem.lastupdate
  from chemicalcodes C1, 
       chemicalcodes C2,
       chemicalcodes C3,
       chemicalcodes C4,
       custitem
  where
        imoprimarychemcode = C1.chemcode(+)
   and  imosecondarychemcode = C2.chemcode(+)
   and  imotertiarychemcode = C3.chemcode(+)
   and  imoquaternarychemcode = C4.chemcode(+)
union
select
    custid,
    item,
    'IATA',
    iataprimarychemcode,
    iatasecondarychemcode,
    iatatertiarychemcode,
    iataquaternarychemcode,
    C1.iatabolcomment,
    C2.iatabolcomment,
    C3.iatabolcomment,
    C4.iatabolcomment,
    custitem.lastuser,
    custitem.lastupdate
  from chemicalcodes C1, 
       chemicalcodes C2,
       chemicalcodes C3,
       chemicalcodes C4,
       custitem
  where
        iataprimarychemcode = C1.chemcode(+)
   and  iatasecondarychemcode = C2.chemcode(+)
   and  iatatertiarychemcode = C3.chemcode(+)
   and  iataquaternarychemcode = C4.chemcode(+);

comment on table custitemchembolview is '$Id$';

-- exit;
