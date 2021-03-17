create table import_item_baseuom_table
( load_sequence     number(7),
  record_sequence   number(7),
  custid            varchar2(10),
  item varchar2(50),
  baseuom           varchar2(4),
  weight            number(17,8),
  cube              number(10,4),
  useramt1          number(10,2),
  useramt2          number(10,2),
  tareweight        number(17,8),
  velocity          varchar2(1),
  picktotype        varchar2(4),
  cartontype        varchar2(4),
  length            number(10,4),
  width             number(10,4),
  height            number(10,4)
);


