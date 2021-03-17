--
-- $Id: alter_tbl_impexp_definitions_attachment_import.sql 1 2005-05-26 12:20:03Z ed $
--
alter table impexp_definitions
add
(order_attachment_import_yn char(1)
);

update impexp_definitions
   set order_attachment_import_yn = 'N'
 where order_attachment_import_yn is null;

exit;
