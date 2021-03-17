create or replace view Shipperview
(
statusabbrev,
LASTUSER,
LASTUPDATE,
Shipper,
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
ShipperSTATUS
)
as
select
Shipperstatus.abbrev,
Shipper.LASTUSER,
Shipper.LASTUPDATE,
Shipper,
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
ShipperSTATUS
from Shipper, Shipperstatus
where Shipper.Shipperstatus = Shipperstatus.code (+);

comment on table Shipperview is '$Id$';


create or replace view custshipperview
(
custid,
statusabbrev,
LASTUSER,
LASTUPDATE,
Shipper,
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
ShipperSTATUS
)
as
select
custshipper.custid,
Shipperview.statusabbrev,
Shipperview.LASTUSER,
Shipperview.LASTUPDATE,
custshipper.Shipper,
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
ShipperSTATUS
from custshipper, Shipperview
where custshipper.shipper = shipperview.shipper;

comment on table custshipperview is '$Id$';

exit;
