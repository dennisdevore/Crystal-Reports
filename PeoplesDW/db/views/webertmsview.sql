CREATE OR REPLACE VIEW WEBERTMSCUSTCONSNVIEW ( ID, 
NAME, ADDR1, ADDR2, CITY, 
STATE, POSTALCODE, COUTNRY, LASTUPDATE
 ) AS select consignee as ID,name,addr1,addr2,city,state,postalcode,b.descr as coutnry,a.lastupdate 
from consignee a, countrycodes b 
where a.countrycode = b.code 
union 
select 'B'||lpad(custid,8,'0') as ID, 
name,addr1,addr2,city,state,postalcode,b.descr as coutnry,a.lastupdate 
from customer a, countrycodes b 
where a.countrycode = b.code;

comment on table WEBERTMSCUSTCONSNVIEW is '$Id$';

CREATE OR REPLACE VIEW WEBERTMSEXPORTVIEW ( BOL, 
CUSTID, SEQ, ORDERSTATUS, SHIPPER, 
CONSIGNEE, BILLTO, SHIPDATE, ARRIVALDATE, 
ORDERDATE, SHIPTERMS, SCAC, PO, 
REFERENCE, PRONO, APPTDATE, AMTCOD, 
REVENUCODE, HAZFLAG, QTYSHIP, WEIGHTSHIP, 
TERMINALCODE, ORDERID, SHIPID ) AS select to_char(oh.orderid) || '-' || to_char(oh.shipid) as BOL,custid,      
'00' as SEQ,      
 decode(oh.orderstatus,'1','P','2','P','3','P','4','P','5','P','6','P',      
 '6','P','7','P','8','P','9','S') as orderstatus,      
  lpad(oh.custid,9,'0') as shipper,oh.consignee,      
 decode(oh.shipterms,'COL',oh.shipto, 'PPD','B'||lpad(oh.custid,8,'0'),'3RD',oh.consignee) as billto,      
 oh.shipdate,oh.arrivaldate,oh.entrydate as orderdate,oh.shipterms,      
 oh.carrier as scac,oh.po,oh.reference, ld.prono,oh.apptdate,oh.amtcod,      
 decode(ce.state,'CA',4,2) as revenucode,       
  substr(zci.hazardous_item_on_order(oh.orderid,oh.shipid),1,1) as hazflag,      
 oh.qtyship,round(oh.weightship,0),      
 zimportproctms.calcterminalcode(to_char(oh.orderid) || '-' || to_char(oh.shipid)) as terminalcode,    
 oh.orderid,oh.shipid      
from orderhdr oh, loads ld, consignee ce       
where oh.ordertype = 'O' and oh.orderstatus < 'A'      
and oh.loadno =ld.loadno (+)       
and oh.consignee = ce.consignee (+)      
and oh.orderid < 10000;

comment on table WEBERTMSEXPORTVIEW is '$Id$';

CREATE OR REPLACE VIEW WEBERTMS_DETAIL ( DETAILBOL, 
SEQ, LINETYPE, PIECES, WEIGHT, 
HAZFLAG, LTLCLASS, DESCRIPTION, ORDERID, 
SHIPID ) AS select BOL as DETAILBOL,SEQ,LINETYPE,PIECES,WEIGHT,HAZFLAG,LTLCLASS,DESCRIPTION,  
  substr(bol,1,instr(bol,'-') - 1) as orderid, substr(bol,instr(bol,'-') + 1,1 ) as shipid  
  from tmsexport;

comment on table WEBERTMS_DETAIL is '$Id$';

CREATE OR REPLACE VIEW WEBERTMS_HDR ( BOL, 
CUSTID, SEQ, ORDERSTATUS, SHIPPER, 
CONSIGNEE, BILLTO, SHIPDATE, ARRIVALDATE, 
ORDERDATE, SHIPTERMS, SCAC, PO, 
REFERENCE, PRONO, APPTDATE, AMTCOD, 
REVENUCODE, HAZFLAG, QTYSHIP, WEIGHTSHIP, 
TERMINALCODE, ORDERID, SHIPID ) AS 
select "BOL","CUSTID","SEQ","ORDERSTATUS","SHIPPER","CONSIGNEE","BILLTO","SHIPDATE","ARRIVALDATE",
	"ORDERDATE","SHIPTERMS","SCAC","PO","REFERENCE","PRONO","APPTDATE","AMTCOD","REVENUCODE","HAZFLAG","QTYSHIP",
	"WEIGHTSHIP","TERMINALCODE","ORDERID","SHIPID"
from webertmsexportview;

comment on table WEBERTMS_HDR is '$Id$';

exit;

  
  





