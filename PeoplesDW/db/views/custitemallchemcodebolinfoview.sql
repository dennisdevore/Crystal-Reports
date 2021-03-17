create or replace view custitemallchemcodebolinfoview
(
    custid,
    item,
    chemcode,
    rank,
    type,
    bolinfo,
    chemcodebolcomment
)
as
select custid,
       item,
       chemcode,
       1,
      'DOT',	
       bolinfo,
       dotbolcomment
  from custitem, chemcodebolinfoview
 where primarychemcode is not null
   and chemcode = primarychemcode
union
select custid,
       item,
       chemcode,
       2,
       'DOT',	
       bolinfo,
       dotbolcomment
  from custitem, chemcodebolinfoview
 where secondarychemcode is not null
   and chemcode = secondarychemcode
union
select custid,
       item,
       chemcode,
       3,
        'DOT',	
       bolinfo,
       dotbolcomment
  from custitem, chemcodebolinfoview
 where tertiarychemcode is not null
   and chemcode = tertiarychemcode
union
select custid,
       item,
       chemcode,
       4,
        'DOT',	
       bolinfo,
       dotbolcomment
  from custitem, chemcodebolinfoview
 where quaternarychemcode is not null
   and chemcode = quaternarychemcode
union
select custid,
       item,
       chemcode,
       1,
      'IATA',	
       bolinfo,
       iatabolcomment
  from custitem, chemcodebolinfoview
 where iataprimarychemcode is not null
   and chemcode = iataprimarychemcode
union
select custid,
       item,
       chemcode,
       2,
       'IATA',	
       bolinfo,
       iatabolcomment
  from custitem, chemcodebolinfoview
 where iatasecondarychemcode is not null
   and chemcode = iatasecondarychemcode
union
select custid,
       item,
       chemcode,
       3,
        'IATA',	
       bolinfo,
       iatabolcomment
  from custitem, chemcodebolinfoview
 where iatatertiarychemcode is not null
   and chemcode = iatatertiarychemcode
union
select custid,
       item,
       chemcode,
       4,
        'IATA',	
       bolinfo,
       iatabolcomment
  from custitem, chemcodebolinfoview
 where iataquaternarychemcode is not null
   and chemcode = iataquaternarychemcode
union
select custid,
       item,
       chemcode,
       1,
      'IMO',	
       bolinfo,
       imobolcomment
  from custitem, chemcodebolinfoview
 where imoprimarychemcode is not null
   and chemcode = imoprimarychemcode
union
select custid,
       item,
       chemcode,
       2,
       'IMO',	
       bolinfo,
       imobolcomment
  from custitem, chemcodebolinfoview
 where imosecondarychemcode is not null
   and chemcode = imosecondarychemcode
union
select custid,
       item,
       chemcode,
       3,
        'IMO',	
       bolinfo,
       imobolcomment
  from custitem, chemcodebolinfoview
 where imotertiarychemcode is not null
   and chemcode = imotertiarychemcode
union
select custid,
       item,
       chemcode,
       4,
        'IMO',	
       bolinfo,
       imobolcomment
  from custitem, chemcodebolinfoview
 where imoquaternarychemcode is not null
   and chemcode = imoquaternarychemcode;

comment on table custitemallchemcodebolinfoview is '$Id$';

create or replace view custitemallcheminfoview
(
   custid,
   item,
   cnt
)
as
select I.custid, I.item, (select count(1)
                            from custitemallchemcodebolinfoview C
                           where C.custid = I.custid
                             and C.item = I.item)
  from custitem I;

comment on table custitemallcheminfoview is '$Id$';


exit;

