--
-- $Id: lastintacctbill_all.sql 1 2005-05-26 12:20:03Z ed $
--
CREATE TABLE LASTINTACCTBILL_ALL
(
  CODE        VARCHAR2(12 BYTE)                 NOT NULL,
  DESCR       VARCHAR2(32 BYTE)                 NOT NULL,
  ABBREV      VARCHAR2(12 BYTE)                 NOT NULL,
  DTLUPDATE   VARCHAR2(1 BYTE),
  LASTUSER    VARCHAR2(12 BYTE),
  LASTUPDATE  DATE
);

INSERT INTO LASTINTACCTBILL_ALL values
('ALLALL',	'Last Billing for All Custs' ,	'140918044502',	'Y',	'SYNAPSE',	SYSDATE);

commit;