--
-- $Id$
--

DROP TABLE TMSORDERSTATUS CASCADE CONSTRAINTS ; 

CREATE TABLE TMSORDERSTATUS ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE);

CREATE UNIQUE INDEX TMSORDERSTATUS_IDX ON 
  TMSORDERSTATUS(CODE) 
; 


insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('TMSOrderStatus','Y','Y','>A;0;_');

insert into tmsorderstatus ( code,descr,abbrev) values ('P','Pending','Pending');
insert into tmsorderstatus ( code,descr,abbrev) values ('S','Shipped','Shipped');
insert into tmsorderstatus ( code,descr,abbrev) values ('X','Cancelled','Cancelled');

exit;
