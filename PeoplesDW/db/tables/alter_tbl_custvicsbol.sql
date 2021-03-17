--
-- $Id$
--
CREATE TABLE CUSTVICSBOL (
CUSTID      VARCHAR2(10)  NOT NULL,
SHIPTO      VARCHAR2(10),
ORDERTYPE   CHAR(1) NOT NULL,
REPORTNAME  VARCHAR2(255) NOT NULL,
LASTUSER    VARCHAR2 (12),
LASTUPDATE  DATE
);

CREATE UNIQUE INDEX custvicsbol_idx ON
  custvicsbol(CUSTID, ORDERTYPE, SHIPTO, REPORTNAME);

create table custvicsbolcopies (
CUSTID      VARCHAR2(10)  NOT NULL,
SHIPTO      VARCHAR2(10),
ORDERTYPE   CHAR(1) NOT NULL,
REPORTNAME  VARCHAR2(255) NOT NULL,
BOLTYPE     VARCHAR2(4),
COPYNUMBER  NUMBER(2),
COPYMSG     VARCHAR2(36),
LASTUSER    VARCHAR2 (12),
LASTUPDATE  DATE
);

create unique index custvicsbolcopies_idx on
  custvicsbolcopies(custid,shipto,ordertype,reportname,boltype,
  copynumber);

--exit;
