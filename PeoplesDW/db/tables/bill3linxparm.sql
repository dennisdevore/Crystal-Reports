create table bill3linxparm (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;

create unique index bill3linxparm_idx on
bill3linxparm(code);

insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('Bill3LinxParm','Y','Y','>Aaaaaaaaaaaa','SYNAPSE',sysdate);

Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('ORDERCHG', 'Order charge', '2.00', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('ITEMRATE', 'Item Rate', '0.50', 'Y', 'KRAZA', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('LTL', 'LTL Carrier', 'YELO', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('LTL', 'LTL Carrier', 'RLCR', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('SURLTL', 'LTL Surcharge', '25.00', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('SURWEIGHT', 'Weight Surcharge', '24.5', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('SURCUBE', 'Cube Surcharge', '1000', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('SURWEIGHTAMT', 'Weight Surcharge Amount', '3.00', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('SURCUBEAMT', 'Cube Surcharge Amount', '3.00', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('CUSTOMDOC', 'Custom Doc Charge', '2.00', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('PRTLTL', 'LTL Printing Charge', '0.30', 'Y', 'SYNAPSE', sysdate);
Insert into BILL3LINXPARM
   (CODE, DESCR, ABBREV, DTLUPDATE, LASTUSER, LASTUPDATE)
 Values
   ('PRTORD', 'Order Printing Charge', '0.10', 'Y', 'SYNAPSE', sysdate);
COMMIT;

exit;

