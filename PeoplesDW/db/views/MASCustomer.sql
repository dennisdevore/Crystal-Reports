CREATE OR REPLACE VIEW MASCustomer
(CompanyNo
,DivisionNo
,LocationNo
,CustomerNo
,CustomerName
,AddressLine1
,AddressLine2
,AddressLine3
,City
,State
,ZipCode
,CountryCode)
 as select
'55',
f.facility,
f.facility,
c.custid,
c.name,
c.addr1,
c.addr2,
null,
c.city,
c.state,
c.postalcode,
c.countrycode
from customer c, facility f;

