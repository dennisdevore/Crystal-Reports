create table import_item_shipopt1_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  backorder             varchar2(2),
  allowsub              varchar2(1),
  invstatusind          varchar2(1),
  invstatus             varchar2(255),
  invclassind           varchar2(1),
  inventoryclass        varchar2(255),
  fifowindowdays        number(3)
  );



