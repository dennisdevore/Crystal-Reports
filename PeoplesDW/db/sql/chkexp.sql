--
-- $Id$
--
select P.lpid, P.invstatus
from plate P, custitem I, customer C
where P.expirationdate is not null
and I.custid = P.custid
and I.item = P.item
and nvl(I.shelflife,0) = 0
and C.custid = P.custid
and decode(nvl(I.expdaterequired,'C'), 'C', nvl(C.expdaterequired, 'N'),
		I.expdaterequired) = 'N'
/
