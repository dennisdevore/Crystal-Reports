create or replace view alps.hp_returns_label_view
(
   shiplpid,
   fromlpid,
   ctostonum,
   ctstoalpha,
   loadno,
   ct
)
as
select S.lpid,
       nvl(P.parentlpid, nvl(P.lpid, nvl(D.parentlpid, D.lpid))),
       C.ctostoprefix,
	    decode(C.ctostoprefix, 10000000, 'CTO', 20000000, 'STO', C.ctostoprefix),
	    S.loadno,
	    concat(substr(c.ctostoprefix,1,4), S.loadno)
from custitem C, shippingplate S, plate P, deletedplate D
where C.item = S.item
  and C.custid = S.custid
  and S.type = 'F'
  and S.custid ='HP'
  and S.parentlpid is null
  and P.lpid (+) = S.fromlpid
  and D.lpid (+) = S.fromlpid
  and ((P.parentlpid is null and D.parentlpid is null)
    or (S.fromlpid in
         (select min(lpid) from plate where parentlpid = P.parentlpid
          union
          select min(lpid) from deletedplate where parentlpid = D.parentlpid)));
          
comment on table hp_returns_label_view is '$Id$';
          
exit;
