create or replace view custitemchemcodeotrbolinfoview
(
    custid,
    item,
    chemcode,
    otherdescr
)
as
select custid,
       item,
       chemcode,
       otherdescr
  from chemcodebolinfoview, custitem
 where primarychemcode is not null
   and donotprintbol <> 'Y'
   and primarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       otherdescr
  from chemcodebolinfoview, custitem
 where secondarychemcode is not null
   and donotprintbol <> 'Y'
   and secondarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       otherdescr
  from chemcodebolinfoview, custitem
 where tertiarychemcode is not null
   and donotprintbol <> 'Y'
   and tertiarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       otherdescr
  from chemcodebolinfoview, custitem
 where quaternarychemcode is not null
   and donotprintbol <> 'Y'
   and quaternarychemcode = chemcode(+);

comment on table custitemchemcodeotrbolinfoview is '$Id$';


exit;

