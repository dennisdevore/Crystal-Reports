create table import_item_uomseq_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  sequence              number(3),
  qty                   number(7),
  fromuom               varchar2(4),
  touom                 varchar2(4),
  cube                  number(10,4),
  picktotype            varchar2(4),
  velocity              varchar2(1),
  weight                number(17,8),
  cartontype            varchar2(4),
  length                number(10,4),
  width                 number(10,4),
  height                number(10,4)
  );



