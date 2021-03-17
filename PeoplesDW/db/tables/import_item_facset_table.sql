create table import_item_facset_table
( load_sequence     number(7),
  record_sequence   number(7),
  custid            varchar2(10),
  item varchar2(50),
  facility          varchar2(3),
  allocrule         varchar2(10),
  replenrule        varchar2(10),
  putawayprofile    varchar2(2)
);


