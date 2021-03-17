--
-- $Id$
--
drop table multishipdtl;

create table multishipdtl
(
    orderid         number(7) not null ,
    shipid          number(2) not null ,
    cartonid        varchar2(15) not null ,
    estweight       number(10,4),
    actweight       number(10,4),
    trackid         varchar2(20),
    status          varchar2(10),  -- 'READY','SHIP PEND','SHIPPED',
                                   -- 'VOID','CANCEL'
    shipdatetime    varchar2(14),  -- YYYYMMDDHHMISS (HH - 24 hour clock)
    carrierused     varchar2(10),
    reason          varchar2(100),
    cost            number(10,2),
    termid          varchar2(4)
);

create unique index pk_multishipdtl on multishipdtl(orderid, shipid, cartonid);

create unique index ix_multishipdtl_cartonid on multishipdtl(cartonid);

-- exit ;,
