create or replace view custitemchemcodebolinfoview
(
    custid,
    item,
    chemcode,
    rank,
    bolinfo
)
as
select custid,
       item,
       chemcode,
       1,
       bolinfo
  from chemcodebolinfoview, custitem
 where primarychemcode is not null
   and primarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       2,
       bolinfo
  from chemcodebolinfoview, custitem
 where secondarychemcode is not null
   and secondarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       3,
       bolinfo
  from chemcodebolinfoview, custitem
 where tertiarychemcode is not null
   and tertiarychemcode = chemcode(+)
union
select custid,
       item,
       chemcode,
       4,
       bolinfo
  from chemcodebolinfoview, custitem
 where quaternarychemcode is not null
   and quaternarychemcode = chemcode(+);

comment on table custitemchemcodebolinfoview is '$Id$';

create or replace view custitemcheminfoview
(
   custid,
   item,
   cnt
)
as
select I.custid, I.item, count(C.item)
  from custitemchemcodebolinfoview C, custitem I
 where I.custid = C.custid(+)
   and I.item = C.item(+)
 group by I.custid, I.item;

comment on table custitemcheminfoview is '$Id$';


exit;

