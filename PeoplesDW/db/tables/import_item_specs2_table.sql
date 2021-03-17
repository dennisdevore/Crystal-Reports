create table import_item_specs2_table
( load_sequence             number(7),
  record_sequence           number(7),
  custid                    varchar2(10),
  item                      varchar2(50),
  allow_uom_chgs            char(1),
  min_sale_life             number(4),
  min0qtysuspenseweight     number(17,8),
  stacking_factor           varchar2(12),
  treat_labeluom_separate   char(1)
);


