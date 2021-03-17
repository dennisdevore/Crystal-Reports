create table import_item_hazset_table
( load_sequence         number(7),
  record_sequence       number(7),
  custid                varchar2(10),
  item varchar2(50),
  hazardflag            varchar2(1),
  hazardclass           varchar2(12),
  primarychemcode       varchar2(12),
  secondarychemcode     varchar2(12),
  tertiarychemcode      varchar2(12),
  quaternarychemcode    varchar2(12),
  imoprimarychemcode    varchar2(12),
  imosecondarychemcode  varchar2(12),
  imotertiarychemcode   varchar2(12),
  imoquaternarychemcode varchar2(12),
  iataprimarychemcode   varchar2(12),
  iatasecondarychemcode varchar2(12),
  iatatertiarychemcode  varchar2(12),
  iataquaternarychemcode varchar2(12)
  );



