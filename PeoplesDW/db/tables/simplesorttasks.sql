create table simplesorttasks
(
  orderid         number(9),
  shipid          number(2),
  item            varchar2(50),
  subtaskrowid    varchar2(18),
  taskid          number(15),
  shippinglpid    varchar2(15),
  lpid            varchar2(15),
  custid          varchar2(10),
  orderitem       varchar2(50),
  orderlot        varchar2(30),
  qty             number(10),
  facility        varchar2(3),
  fromloc         varchar2(10),
  uom             varchar2(4),
  shippingtype    varchar2(2),
  tasktype        varchar2(2),
  picktotype      varchar2(4),
  pickuom         varchar2(4),
  pickqty         number(10),
  weight          number(17,8),
  lotnumber       varchar2(30),
  useritem1       varchar2(20),
  useritem2       varchar2(20),
  useritem3       varchar2(20),
  serialnumber    varchar2(30)
);
create index alps.simplesorttasks_idx on simplesorttasks
(orderid, shipid, item);

exit;

