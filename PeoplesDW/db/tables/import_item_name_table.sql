create table import_item_name_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  descr                 varchar2(40),
  abbrev                varchar2(12),
  rategroup             varchar2(10),
  status                varchar2(4),
  needs_review_yn       char(1)
  );



