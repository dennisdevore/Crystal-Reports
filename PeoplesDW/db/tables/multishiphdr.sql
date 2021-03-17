--
-- $Id$
--
drop table multishiphdr;

create table multishiphdr
(
    orderid         number(7) not null ,
    shipid          number(2) not null ,
    custid          varchar2(10) not null ,
    shiptoname      varchar2(40),
    shiptocontact   varchar2(40),
    shiptoaddr1     varchar2(40),
    shiptoaddr2     varchar2(40),
    shiptocity      varchar2(30),
    shiptostate     varchar2(2),
    shiptopostalcode    varchar2(12),
    shiptocountrycode   varchar2(3),
    shiptophone         varchar2(15),
    carrier         varchar2(10),
    carriercode     varchar2(4),
    specialservice1 varchar2(30),
    specialservice2 varchar2(30),
    specialservice3 varchar2(30),
    specialservice4 varchar2(30),
    terms           varchar2(3)
);

create unique index pk_multishiphdr on multishiphdr(orderid, shipid);

-- exit ;,
