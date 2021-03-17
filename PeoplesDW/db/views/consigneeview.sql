create or replace view consigneeview
(
statusabbrev,
LASTUSER,
LASTUPDATE,
consignee,
NAME,
CONTACT,
ADDR1,
ADDR2,
CITY,
STATE,
POSTALCODE,
COUNTRYCODE,
PHONE,
FAX,
EMAIL,
consigneeSTATUS,
ltlcarrier,
tlcarrier,
spscarrier,
billto,
shipto,
billtoconsignee,
shiptype,
shipterms,
shiptypeabbrev,
shiptermsabbrev
)
as
select
consigneestatus.abbrev,
consignee.LASTUSER,
consignee.LASTUPDATE,
consignee,
NAME,
CONTACT,
ADDR1,
ADDR2,
CITY,
STATE,
POSTALCODE,
COUNTRYCODE,
PHONE,
FAX,
EMAIL,
consigneeSTATUS,
ltlcarrier,
tlcarrier,
spscarrier,
billto,
shipto,
billtoconsignee,
shiptype,
shipterms,
shipmenttypes.abbrev,
shipmentterms.abbrev
from consignee, consigneestatus, shipmenttypes, shipmentterms
where consignee.consigneestatus = consigneestatus.code (+)
  and consignee.shiptype = shipmenttypes.code(+)
  and consignee.shipterms = shipmentterms.code(+);

comment on table consigneeview is '$Id$';


create or replace view custconsigneeview
(
custid,
statusabbrev,
LASTUSER,
LASTUPDATE,
consignee,
NAME,
CONTACT,
ADDR1,
ADDR2,
CITY,
STATE,
POSTALCODE,
COUNTRYCODE,
PHONE,
FAX,
EMAIL,
consigneeSTATUS,
ltlcarrier,
tlcarrier,
spscarrier,
billto,
shipto,
billtoconsignee,
shiptype,
shipterms,
shiptypeabbrev,
shiptermsabbrev
)
as
select
custconsignee.custid,
consigneeview.statusabbrev,
consigneeview.LASTUSER,
consigneeview.LASTUPDATE,
custconsignee.consignee,
NAME,
CONTACT,
ADDR1,
ADDR2,
CITY,
STATE,
POSTALCODE,
COUNTRYCODE,
PHONE,
FAX,
EMAIL,
consigneeSTATUS,
ltlcarrier,
tlcarrier,
spscarrier,
billto,
shipto,
billtoconsignee,
shiptype,
shipterms,
shiptypeabbrev,
shiptermsabbrev
from custconsignee, consigneeview
where custconsignee.consignee = consigneeview.consignee;

comment on table custconsigneeview is '$Id$';

exit;
