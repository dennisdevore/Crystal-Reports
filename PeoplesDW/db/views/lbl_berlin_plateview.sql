create or replace view lbl_berlin_plateview
(
   lpid,
   item,
   descr,
   weight,
   po,
   cname
)
as
select P.lpid,
       P.item,
       CI.descr,
       P.weight,
       P.po,
       CU.name
   from plate P, customer CU, custitem CI
   where CU.custid (+) = P.custid
     and CI.custid (+) = P.custid
     and CI.item (+) = P.item;

comment on table lbl_berlin_plateview is '$Id';

exit;
