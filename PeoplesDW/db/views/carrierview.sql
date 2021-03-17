create or replace view carrierview
(
statusabbrev,
LASTUSER,
LASTUPDATE,
CARRIER,
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
CARRIERTYPE,
CARRIERSTATUS,
scac,
multiship
)
as
select
carrierstatus.abbrev,
carrier.LASTUSER,
carrier.LASTUPDATE,
CARRIER,
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
CARRIERTYPE,
CARRIERSTATUS,
scac,
multiship
from carrier, carrierstatus
where carrier.carrierstatus = carrierstatus.code (+);

comment on table carrierview is '$Id$';

--exit;

