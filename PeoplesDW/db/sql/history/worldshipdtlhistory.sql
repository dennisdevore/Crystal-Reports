create table worldshipdtlhistory
(whenoccurred      timestamp(9),
 rid               rowid,
 orderid           number(9),
 shipid            number(2),
 cartonid          varchar2(20 byte),
 estweight         number(17,8),
 actweight         number(17,8),
 trackid           varchar2(30 byte),
 status            varchar2(10 byte),
 shipdatetime      varchar2(14 byte),
 carrierused       varchar2(10 byte),
 reason            varchar2(100 byte),
 cost              number(10,2),
 termid            varchar2(4 byte),
 satdeliveryused   varchar2(1 byte),
 packlistshipdatetime varchar2(14 byte),
 length            number(10,4),
 width             number(10,4),
 height            number(10,4),
 rmatrackingno     varchar2(30 byte),
 actualcarrier     varchar2(4 byte),
 charcost          varchar2(12 byte));

create index wsdtlhistory_date_idx on worldshipdtlhistory(whenoccurred) tablespace users16kb;

create index wsdtlhistory_carton_idx on worldshipdtlhistory(cartonid) tablespace users16kb;

exit;
