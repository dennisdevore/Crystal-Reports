--
-- $Id$
--
CREATE TABLE WORKORDERINSTRUCTIONS (
  SEQ NUMBER(8, 0) NOT NULL,
  PARENT NUMBER(8, 0),
  ACTION VARCHAR2(2),
  NOTES LONG,
  CUSTID VARCHAR2(10),
  item varchar2(50),
  TITLE VARCHAR2(35),
  QTY NUMBER(8, 0),
  COMPONENT VARCHAR2(20),
  DESTFACILITY VARCHAR2(3),
  DESTLOCATION VARCHAR2(10),
  DESTLOCTYPE VARCHAR2(12)
);

exit;