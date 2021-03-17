--
-- $Id$
--
create table workorderpicks
(
   orderid           number(9),
   shipid            number(2),
   custid            varchar2(10),
   item varchar2(50),
   lpid              varchar2(15),
   serialnumber      varchar2(30),
   lotnumber         varchar2(30),
   manufacturedate   date,
   expirationdate    date,
   countryof         varchar2(3),
   useritem1         varchar2(20),
   useritem2         varchar2(20),
   useritem3         varchar2(20),
   invstatus         varchar2(2),
   inventoryclass    varchar2(2),
   quantity          number(7),
   pickedon          date,
   pickedby          varchar2(12)
);

create index workorderpicks_idx on workorderpicks
   (orderid, shipid);

exit;
