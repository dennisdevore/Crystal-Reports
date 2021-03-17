CREATE OR REPLACE VIEW ALPS.HP_RETURNS_LABEL_VIEW 
(
    SHIPLPID,
    FROMLPID,
    CTOSTONUM,
    CTSTOALPHA,
    LOADNO,
    CT
)
AS
select S.lpid,
       nvl(P.parentlpid, P.lpid),
       C.ctostoprefix,
	  decode(C.ctostoprefix, 10000000, 'CTO', 20000000, 'STO', C.ctostoprefix),
	  S.loadno,
	  concat(substr(c.ctostoprefix,1,4), S.loadno)
from custitem C, shippingplate S, plate P
where C.item = S.item
  and C.custid = S.custid
  and S.type = 'F'
  and S.custid ='HP'
  and S.parentlpid is null
  and P.lpid = S.fromlpid
  and P.lpid = (select min(P2.lpid)
         from plate P2
         start with P2.lpid = nvl(P.parentlpid, P.lpid)
         connect by prior P2.lpid = P2.parentlpid);

comment on table HP_RETURNS_LABEL_VIEW  is '$Id$';
exit;
