--
-- $Id$
--
drop table shippingaudit;

create table shippingaudit
(
   lpid           varchar2(15),
   facility       varchar2(3),
   location       varchar2(10),
   custid         varchar2(10),
   item varchar2(50),
   qty            number(7),
   lotnumber      varchar2(30),
   serialnumber   varchar2(30),
   useritem1      varchar2(20),
   useritem2      varchar2(20),
   useritem3      varchar2(20),
   audituser      varchar2(12),
   auditdate      date,
   toplpid        varchar2(15),
   itementered    varchar2(20),
	results        varchar2(4)
);

exit;
