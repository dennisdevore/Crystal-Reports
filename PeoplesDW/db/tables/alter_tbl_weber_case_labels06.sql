--
-- $Id: alter_tbl_weber_case_labels06.sql 8844 2012-08-28 21:19:04Z ed $
--
alter table weber_case_labels add
(
   dtlpassthrudoll01             number(10,2),
   dtlpassthrudoll02             number(10,2),
   shiptocontact                 varchar2(40),
   case_height                   number(10,4),
   case_length                   number(10,4),
   case_weight                   number(17,8),
   case_width                    number(10,4),
   quantity                      number(7)
);

exit;
