--
-- $Id$
--

create table import_plate (
   load_sequence     number(7),
   record_sequence   number(7),
   lpid              varchar2(15),
   item varchar2(50),
   custid            varchar2(10),
   facility          varchar2(3),
   location          varchar2(10),
   unitofmeasure     varchar2(4),
   quantity          number(7),
   serialnumber      varchar2(30),
   lotnumber         varchar2(30),
   creationdate      varchar2(20),
   manufacturedate   varchar2(20),
   expirationdate    varchar2(20),
   po                varchar2(20),
   recmethod         varchar2(2),
   condition         varchar2(2),
   countryof         varchar2(3),
   useritem1         varchar2(20),
   useritem2         varchar2(20),
   useritem3         varchar2(20),
   invstatus         varchar2(2),
   inventoryclass    varchar2(2),
   orderid           number(9),
   shipid            number(2),
   weight            number(13,4),
   qtyrcvd           number(7)
);

exit;
