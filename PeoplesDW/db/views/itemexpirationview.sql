CREATE OR REPLACE VIEW ITEMEXPIRATIONVIEW ( CUSTID,
COMPANYNAME, ITEM, DESCR, LOTNUMBER,
LOCATION, FACILITYNAME, LPID, UOM,
QUANTITY, EXPIRATIONDATE, DAYSTOEXPIRE, CRITICALLEVEL,FACILITY,
CRITLEVEL1,CRITLEVEL2,CRITLEVEL3,expireaction
 ) as
 select a.custid,e.name as companyname,a.item,b.descr, a.lotnumber, a.location,  c.name as facilityname,
        a.lpid, d.abbrev as UOM, a.quantity,
        a.expirationdate,
        trunc(a.expirationdate - trunc(sysdate)) as daystoexpire,
        decode(ceil(trunc((expirationdate - trunc(sysdate)))/critlevel1),1,1,
        decode(ceil(trunc((expirationdate - trunc(sysdate)))/critlevel2),1,2,3)) as criticallevel,
        a.facility, critlevel1,critlevel2,critlevel3,f.abbrev
from plate a, custitemview b, facility c, unitsofmeasure d, customer e, expirationactions f
where a.custid = b.custid and
	  a.item=b.item and
	  a.facility = c.facility and
	  a.unitofmeasure = d.code and
	  a.custid = e.custid and
	  a.expirationdate is not null and
	  a.expirationdate > trunc(sysdate) and
          a.expiryaction = f.code(+) and
	  critlevel1 > 0 and
	  critlevel2 > 0 and
	  critlevel3 > 0 and
	  decode(ceil(trunc((expirationdate - trunc(sysdate)))/critlevel1),1,1,
          decode(ceil(trunc((expirationdate - trunc(sysdate)))/critlevel2),1,1,
          decode(ceil(trunc((expirationdate - trunc(sysdate)))/critlevel3),1,1,0))) = 1;
          
comment on table ITEMEXPIRATIONVIEW is '$Id$';
          
--exit;

