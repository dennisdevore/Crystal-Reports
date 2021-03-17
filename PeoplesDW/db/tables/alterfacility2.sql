--
-- $Id$
--
alter table facility add
(
 remitname           varchar2(40),
 remitaddr1          varchar2(40),
 remitaddr2          varchar2(40),
 remitcity           varchar2(30),
 remitstate          varchar2(2),
 remitpostalcode     varchar2(12),
 remitcountrycode    varchar2(3)
);

exit;
