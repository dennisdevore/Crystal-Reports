--
-- $Id: alter_tbl_zenith_case_label11.sql 4788 2010-03-03 22:31:39Z ed $
--
alter table zenith_case_labels add (
   shiptofax    varchar2(25),
   quantity     number(7)
);

exit;
