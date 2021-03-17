create or replace view custitemupcview
(
    custid,
    item,
    upc
)
as
select 
    A.custid,
    A.item,
    A.itemalias
  from custitemalias A
 where A.aliasdesc like 'UPC%'
   and A.rowid =
      (select min(B.rowid)
         from custitemalias B
        where B.custid = A.custid
          and B.item = A.item
          and B.aliasdesc like 'UPC%');

comment on table custitemupcview is '$Id$';

-- exit;
