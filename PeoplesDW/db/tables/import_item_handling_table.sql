create table import_item_handling_table
( load_sequence            number(7),
  record_sequence          number(7),
  custid                   varchar2(10),
  item                     varchar2(50),
  locstchg_loctype         varchar2(3),
  locstchg_excl_tasktypes  varchar2(4000),
  locstchg_entry_invstatu  varchar2(2),
  locstchg_entry_adjreasn  varchar2(2),
  locstchg_exit_invstatus  varchar2(2),
  locstchg_exit_adjreason  varchar2(2) 
);


