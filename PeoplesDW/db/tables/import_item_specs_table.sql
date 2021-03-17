create table import_item_specs_table
( load_sequence     number(7),
  record_sequence   number(7),
  custid            varchar2(10),
  item varchar2(50),
  shelflife         number(4),
  expiryaction      varchar2(2),
  profid            varchar2(2),
  labeluom          varchar2(4),
  productgroup      varchar2(4),
  nmfc              varchar2(12),
  lotsumreceipt     varchar2(1),
  lotsumrenewal     varchar2(1),
  lotsumbol         varchar2(1),
  lotsumaccess      varchar2(1),
  ltlfc             varchar2(10),
  countryof         varchar2(3),
  hazardous         varchar2(1),
  stackheight       number(3),
  stackheightuom    varchar2(4),
  reorderqty        number(10),
  unitsofstorage    varchar2(255),
  nmfc_article      varchar2(15),
  tms_commodity_code varchar2(30),
  itmpassthruchar01 varchar2(255),
  itmpassthruchar02 varchar2(255),
  itmpassthruchar03 varchar2(255),
  itmpassthruchar04 varchar2(255),
  itmpassthrunum01  number(16,4),
  itmpassthrunum02  number(16,4),
  itmpassthrunum03  number(16,4),
  itmpassthrunum04  number(16,4)
);


