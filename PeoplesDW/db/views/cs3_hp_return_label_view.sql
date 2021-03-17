create or replace view alps.cs3_hp_return_label_view
(
   lpid,
   fromlpid,
   item,
   ctostoprefix,
   loadno,
   ctostoprealpha
)
as
select S.lpid,
       nvl(P.parentlpid, P.lpid),
       C.item,
       C.ctostoprefix,
       S.loadno,
       decode(C.ctostoprefix, 10000000, 'CTO', 20000000, 'STO',
       C.ctostoprefix)
from custitem C, shippingplate S, plate P
where C.item = S.item
  and C.custid = S.custid
  and S.type = 'F'
  and S.custid ='HP'
  and S.parentlpid is null
  and P.lpid = S.fromlpid
  and P.lpid = (select min(P2.lpid) 
         from plate P2
         where P2.item = P.item
         start with P2.lpid = nvl(P.parentlpid, P.lpid)
         connect by prior P2.lpid = P2.parentlpid);

comment on table cs3_hp_return_label_view is '$Id$';

exit;        
