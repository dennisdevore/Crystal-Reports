--
-- $Id$
--
--drop table qcresult;

create table qcresult(
   id                number(7) not null,
   orderid           number(7) not null,
   shipid            number(2) not null,
   supplier          varchar2(10),
   receiptdate       date,
   inspectdate       date,
   qtyexpected       number(7),
   qtytoinspect      number(7),
   qtyreceived       number(7),
   qtychecked        number(7),
   qtypassed         number(7),
   qtyfailed         number(7),
   status            varchar2(2),
   controlnumber     varchar2(10),
   lastuser          varchar2(12),
   lastupdate        date
);

create unique index pk_qcresult
  on qcresult(id, orderid, shipid);

create index qcresult_order_idx
  on qcresult(orderid, shipid, id);

-- exit;


