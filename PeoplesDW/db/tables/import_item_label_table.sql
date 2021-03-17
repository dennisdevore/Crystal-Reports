create table import_item_label_table
( load_sequence             number(7),
  record_sequence           number(7),
  custid                    varchar2(10),
  item                      varchar2(50),
  labelprofile              varchar2(4),
  prtlps_on_load_arrival    char(1),
  system_generated_lps      char(1),
  prtlps_profid             varchar2(4),
  prtlps_def_handling       varchar2(4),
  sscccasepackfromuom       varchar2(4),
  sscccasepacktouom         varchar2(4),
  prtlps_putaway_dir        char(1)
);


