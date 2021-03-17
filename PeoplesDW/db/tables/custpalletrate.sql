--
-- $Id: custpalletrate.sql 1 2013-05-02 12:20:03Z ay $
--
create table custpalletrate (
custid          varchar2(10)    not null,
rategroup       varchar2(10)    not null,
effdate         date            not null,
activity        varchar2(4)     not null,
billmethod      varchar2(4)     not null,
pallettype      varchar2(12)    not null,
rate            number(12,6)    not null,
lastuser        varchar2(12),
lastupdate      date
);

create unique index custpalletrate_idx on 
   custpalletrate(custid, rategroup, effdate,activity, billmethod, pallettype);