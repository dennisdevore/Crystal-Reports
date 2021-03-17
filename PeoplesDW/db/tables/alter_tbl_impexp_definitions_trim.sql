--
-- $Id: alter_tbl_impexp_definitions_trim.sql 381 2006-08-11 01:16:55Z brianb $
--
alter table impexp_definitions add
(trim_leading_spaces_yn char(1)
);

update impexp_definitions
   set trim_leading_spaces_yn = 'Y'
 where trim_leading_spaces_yn is null;
commit;

exit;
