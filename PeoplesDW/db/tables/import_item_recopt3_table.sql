create table import_item_recopt3_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item                  varchar2(50),
  serialasncapture      varchar2(1),
  user1asncapture       varchar2(1),
  user2asncapture       varchar2(1),
  user3asncapture       varchar2(1),
  lot_seq_max           number(20),
  lot_seq_min           number(20),
  lot_seq_name          varchar2(30),
  serial_seq_max        number(20),
  serial_seq_min        number(20),
  serial_seq_name       varchar2(30),
  useritem1_seq_max     number(20),
  useritem1_seq_min     number(20),
  useritem1_seq_name    varchar2(30),
  useritem2_seq_max     number(20),
  useritem2_seq_min     number(20),
  useritem2_seq_name    varchar2(30),
  useritem3_seq_max     number(20),
  useritem3_seq_min     number(20),
  useritem3_seq_name    varchar2(30)
  );



