create or replace view custitemwmitview
(
    custid,
    item,
    wmit
)
as
select 
    A.custid,
    A.item,
    A.itemalias
  from custitemalias A
 where A.aliasdesc like 'WMIT%'
   and A.rowid =
      (select min(B.rowid)
         from custitemalias B
        where B.custid = A.custid
          and B.item = A.item
          and B.aliasdesc like 'WMIT%');

comment on table custitemwmitview is '$Id$';

-- exit;
