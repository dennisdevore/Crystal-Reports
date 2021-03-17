--
-- $Id$
--
DROP TABLE TEMPCUSTITEMOUT CASCADE CONSTRAINTS ; 

CREATE TABLE TEMPCUSTITEMOUT ( 
  SNO         NUMBER (3), 
  NAMEID      VARCHAR2 (12), 
  FACILITY    VARCHAR2 (3), 
  CUSTID      VARCHAR2 (10), 
  ITEM        VARCHAR2 (20), 
  DESCR       VARCHAR2 (32), 
  LOTNUMBER   VARCHAR2 (30), 
  QUANTITY    NUMBER (7), 
  QNTENTERED  NUMBER (7), 
  UOM         VARCHAR2 (4), 
  BASEUOM     VARCHAR2 (4),
  COMMENTS    VARCHAR2 (255));


CREATE UNIQUE INDEX TEMP_CUST_ITEM_OUT ON 
  TEMPCUSTITEMOUT(NAMEID, CUSTID, ITEM, LOTNUMBER); 
  
  exit;
