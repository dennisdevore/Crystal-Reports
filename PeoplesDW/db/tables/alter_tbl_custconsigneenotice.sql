--
-- $Id$
--
CREATE TABLE CUSTCONSIGNEENOTICE (
CUSTID      VARCHAR2(10)  NOT NULL,
SHIPTO      VARCHAR2(10),
ORDERTYPE   CHAR(1) NOT NULL,
FORMATNAME  VARCHAR2(35) NOT NULL,
LASTUSER    VARCHAR2 (12),
LASTUPDATE  DATE
);

CREATE UNIQUE INDEX custconsigneenotice_idx ON
  custconsigneenotice(CUSTID, ORDERTYPE, SHIPTO, FORMATNAME);
exit;
