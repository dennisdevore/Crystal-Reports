create table import_item_recopt1_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  lotrequired           varchar2(1),
  lotrftag              varchar2(5),
  serialrequired        varchar2(1),
  serialrftag           varchar2(5),
  user1required         varchar2(1),
  user1rftag            varchar2(5),
  user2required         varchar2(1),
  user2rftag            varchar2(5),
  user3required         varchar2(1),
  user3rftag            varchar2(5),
  mfgdaterequired       varchar2(1),
  expdaterequired       varchar2(1),
  countryrequired       varchar2(1)
  );



