--
-- $Id$
--

create table import_order_acknowledgment (
   importfileid      varchar2(255),
   custid            varchar2(10),
   po                varchar2(20),
   reference         varchar2(20),
   orderid           number(9),
   shipid            number(2),
   status            char(1),
   ackcomment        clob,
   lastupdate        date
);
create unique index pk_import_order_ack
   on import_order_acknowledgment(importfileid, custid, po, reference);

exit;
