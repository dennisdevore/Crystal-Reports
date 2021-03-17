create table import_item_validation_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  lotfmtruleid          varchar2(10),
  lotfmtaction          varchar2(1),
  serialfmtruleid       varchar2(10),
  serialfmtaction       varchar2(1),
  user1fmtruleid        varchar2(10),
  user1fmtaction        varchar2(1),
  user2fmtruleid        varchar2(10),
  user2fmtaction        varchar2(1),
  user3fmtruleid        varchar2(10),
  user3fmtaction        varchar2(1)
  );



