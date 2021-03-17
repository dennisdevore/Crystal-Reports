--
-- $Id$
--
alter table invadjactivity add(
  OLDCUSTID                                   VARCHAR2(10)
, OLDitem varchar2(50)
, OLDLOTNUMBER                                VARCHAR2(30)
, OLDINVENTORYCLASS                           VARCHAR2(2)
, OLDINVSTATUS                                VARCHAR2(2)
, NEWCUSTID                                   VARCHAR2(10)
, NEWitem varchar2(50)
, NEWLOTNUMBER                                VARCHAR2(30)
, NEWINVENTORYCLASS                           VARCHAR2(2)
, NEWINVSTATUS                                VARCHAR2(2)
);
exit;
