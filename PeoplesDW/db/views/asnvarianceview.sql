create or replace
function asnqty
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
) return number is
--
-- $Id$
--

qtyAsn integer;

begin
qtyAsn := 0;
select sum(qty)
  into qtyAsn
  from asncartondtl
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x');

return qtyAsn;

exception when others then
  return 0;
end;
/
create or replace
FUNCTION asntrackingno
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
) return varchar2 is
--
-- $Id$
--
strTrackingno asncartondtl.trackingno%type;

begin

strTrackingno := null;

select trackingno
  into strTrackingno
  from asncartondtl
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x');

return strTrackingno;

exception when others then
  return null;
end;
/
create or replace
function asnCustReference
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
) return varchar2 is
--
-- $Id$
--

strCustReference asncartondtl.CustReference%type;

begin

strCustReference := null;

select CustReference
  into strCustReference
  from asncartondtl
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x');

return strCustReference;

exception when others then
  return null;
end;
/
create or replace
function rcqty
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
) return number is
--
-- $Id
--

qtyRc integer;
begin
qtyRc := 0;
select sum(qtyrcvd)
  into qtyRc
  from orderdtlrcpt
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x');

return qtyRc;

exception when others then
  return 0;
end;
/
create or replace view asnvarviewexp
(expectedoractual
,orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
)
as
select
'E',
asn.orderid,
asn.shipid,
asn.item,
asn.lotnumber,
asn.serialnumber,
asn.useritem1,
asn.useritem2,
asn.useritem3
from asncartondtl asn
minus
select
'E',
rc.orderid,
rc.shipid,
rc.item,
rc.lotnumber,
rc.serialnumber,
rc.useritem1,
rc.useritem2,
rc.useritem3
from orderdtlrcptsumview rc;

comment on table asnvarviewexp is '$Id$';

create or replace view asnvarviewact
(expectedoractual
,orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
)
as
select
'A',
rc.orderid,
rc.shipid,
rc.item,
rc.lotnumber,
rc.serialnumber,
rc.useritem1,
rc.useritem2,
rc.useritem3
from orderdtlrcptsumview rc
minus
select
'A',
asn.orderid,
asn.shipid,
asn.item,
asn.lotnumber,
asn.serialnumber,
asn.useritem1,
asn.useritem2,
asn.useritem3
from asncartondtl asn;
/

comment on table asnvarviewact is '$Id$';

create or replace view asnvarview
(expectedoractual
,orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
)
as
select * from asnvarviewact
union
select * from asnvarviewexp;
/

comment on table asnvarview is '$Id$';

create or replace view asnvarianceview
(expectedoractual
,orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
,trackingno
,custreference
,qty
)
as
select
asv.expectedoractual,
asv.orderid,
asv.shipid,
asv.item,
asv.lotnumber,
asv.serialnumber,
asv.useritem1,
asv.useritem2,
asv.useritem3,
decode(asv.expectedoractual,'E',substr(asntrackingno(asv.orderid,asv.shipid,
  asv.item,asv.lotnumber,asv.serialnumber,asv.useritem1,
  asv.useritem2,asv.useritem3),1,22),null),
decode(asv.expectedoractual,'E',substr(asncustreference(asv.orderid,asv.shipid,
  asv.item,asv.lotnumber,asv.serialnumber,asv.useritem1,
  asv.useritem2,asv.useritem3),1,30),null),
decode(asv.expectedoractual,'E',asnqty(asv.orderid,asv.shipid,
  asv.item,asv.lotnumber,asv.serialnumber,asv.useritem1,
  asv.useritem2,asv.useritem3),rcqty(asv.orderid,asv.shipid,
  asv.item,asv.lotnumber,asv.serialnumber,asv.useritem1,
  asv.useritem2,asv.useritem3))
from asnvarview asv;
/

comment on table asnvarianceview is '$Id$';

--exit;
