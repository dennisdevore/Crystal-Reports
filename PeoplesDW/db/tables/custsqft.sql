--
-- $Id$
--
create table custsqft
(facility varchar2(3) not null
,custid varchar2(10) not null
,sqft number(7)
, LASTUSER                                 VARCHAR2(12)
, LASTUPDATE                               DATE
);
exit;