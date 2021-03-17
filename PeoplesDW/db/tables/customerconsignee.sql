--
-- $Id$
--
DROP TABLE CUSTOMERCARRIERS CASCADE CONSTRAINTS ; 

CREATE TABLE CUSTOMERCARRIERS ( 
  CUSTID      VARCHAR2 (10)  NOT NULL, 
  SHIPTYPE    VARCHAR2(1)    NOT NULL, 
  FROMWEIGHT  NUMBER        NOT NULL, 
  TOWEIGHT    NUMBER        NOT NULL, 
  CARRIER     VARCHAR2 (4)  NOT NULL,
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE); 


CREATE UNIQUE INDEX CUSTSHIPWGHT ON 
  CUSTOMERCARRIERS(CUSTID, SHIPTYPE, FROMWEIGHT); 
  

exit;