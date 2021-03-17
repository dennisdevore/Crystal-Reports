--
-- $Id$
--
create table invoicedtl
(
 billstatus     varchar2(1) not null,
 facility       varchar2(3) not null,
 custid         varchar2(10) not null,
 orderid        number(7) not null,
 item varchar2(50),
 lotnumber      varchar2(30),
 activity       varchar2(4) not null,
 activitydate   date,
 handling       varchar2(4),
 invoice        number(8),
 invdate        date,
 invtype        varchar2(1),
 po             varchar2(10),
 lpid           varchar2(15),
 enteredqty     number(7),
 entereduom     varchar2(4),
 enteredrate    number(12,6),
 enteredamt     number(10,2),
 calcedqty      number(7),
 calceduom      varchar2(4),
 calcedrate     number(12,6),
 calcedamt      number(10,2),
 minimum        number(10,2),
 billedqty      number(7),
 billedrate     number(12,6),
 billedamt      number(10,2),
 expiregrace    date,
 statusrsn      varchar2(4),
 exceptrsn      varchar2(4),
 comment1       long,
 lastuser       varchar2(12),
 lastupdate     date,
 statususer     varchar2(12),
 statusupdate   date
);


create index  invoicedtl_idx on
       invoicedtl(
             billstatus,
             facility,
             custid,
             orderid,
             item,
             activity,
             activitydate);
