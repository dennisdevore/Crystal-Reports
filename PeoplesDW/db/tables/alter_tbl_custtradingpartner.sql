--
-- $Id$
--
create table custtradingpartner
(custid         VARCHAR2(10) not null
,tradingpartner varchar2(10) not null
,LASTUSER       VARCHAR2(12)
,LASTUPDATE     DATE
);

create unique index custtradingpartner_idx on
  custtradingpartner(tradingpartner);

create index custtradingpartner_custid_idx on
  custtradingpartner(custid,tradingpartner);
--exit;
