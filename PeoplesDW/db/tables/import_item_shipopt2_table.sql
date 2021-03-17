create table import_item_shipopt2_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  allocrule             varchar2(10),
  qtytype               varchar2(1),
  variancepct           number(3),
  weightcheckrequired   varchar2(1),
  subslprsnrequired     varchar2(1)
  );



