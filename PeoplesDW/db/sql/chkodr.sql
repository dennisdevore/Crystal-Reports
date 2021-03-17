--
-- $Id$
--
set serveroutput on;

declare

cursor curLiPs is
select lpid,qtyrcvd
from orderdtlrcpt rc
where custid = '17131'
and orderid = 355448
and serialnumber is null
and exists (select * from allplateview pl
                                  where rc.lpid = pl.lpid
                                         and pl.serialnumber is not null)
and exists (select * from custitem ci
                                 where rc.custid = ci.custid
                                        and rc.item = ci.item
                                        and ci.serialrequired in ('Y','O'))
and exists (select * from platehistory ph
                                 where rc.lpid = ph.lpid
                                        and ph.lasttask in ('IA','SC'));

ap allplateview%rowtype;

begin

for lp in curLips
loop
  select *
    into ap
    from allplateview
   where lpid = lp.lpid;
  update orderdtlrcpt
     set serialnumber = ap.serialnumber,
         useritem1 = ap.useritem1
   where orderid = 355448
     and lpid = lp.lpid;
  zut.prt('updated ' || lp.lpid);
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--commit;
--exit;
