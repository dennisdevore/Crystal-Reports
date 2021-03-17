--
-- $Id$
--
--drop table qcresultdtl;

create table qcresultdtl(
   id                number(7) not null,
   orderid           number(7) not null,
   shipid            number(2) not null,
   lpid              varchar2(15) not null,
   qtyreceived       number(7),
   qtychecked        number(7),
   qtypassed         number(7),
   qtyfailed         number(7),
   inspectdate       date,
   inspector         varchar2(12),
   disposition       varchar2(2),
   notes             long,
   condition         varchar2(4),
   lastuser          varchar2(12),
   lastupdate        date
);

create unique index pk_qcresultdtl
  on qcresultdtl(id, orderid, shipid, lpid);

create index qcresultdtl_lpid_idx
  on qcresultdtl(lpid);

-- exit;


