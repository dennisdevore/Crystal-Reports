create or replace view printerview
(prtid
,description
,type
,queue
,stock
,lastuser
,lastupdate
,facility
,typeabbrev
,stockabbrev
,lpsprintno
,lpshost
,winshare
)
as
select
 prtid
,description
,type
,queue
,stock
,printer.lastuser
,printer.lastupdate
,facility
,printertypes.abbrev
,printerstock.abbrev
,lpsprintno
,lpshost
,winshare
from printer,
     printertypes,
     printerstock
where printer.type = printertypes.code(+)
and printer.stock = printerstock.code(+);

comment on table printerview is '$Id$';

exit;
