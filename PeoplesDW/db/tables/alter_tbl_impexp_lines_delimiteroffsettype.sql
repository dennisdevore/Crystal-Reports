--
-- $Id: alter_tbl_impexp_lines_delimiteroffsettype.sql 1 2005-05-26 12:20:03Z ed $
--
alter table impexp_lines
add
(delimiteroffsettype number(1)
);

update impexp_lines
   set delimiteroffsettype = 0
 where delimiteroffsettype is null;

exit;
