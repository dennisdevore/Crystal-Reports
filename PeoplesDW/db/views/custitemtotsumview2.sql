create or replace view custitemtotsumview2 as
select tot.facility as facility,
   tot.custid as custid,
   tot.item as item,
   ci.descr as descr,
   sum(tot.lipcount) as totlips,
   sum(tot.qty) as totqty,
   zit.alloc_qty(tot.custid,tot.item,tot.facility) as alcqty 
   from custitem ci, custitemtotsumview tot 
   where tot.custid = ci.custid and tot.item = ci.item 
   group by tot.facility,tot.custid,tot.item,ci.descr;
comment on table custitemtotsumview2 is '$Id$';
 exit;
