--
-- $Id: alter_tbl_oldexp_definitions_trim.sql 381 2006-08-11 01:16:55Z brianb $
--
alter table oldexp_definitions add
(trim_leading_spaces_yn char(1)
);

update oldexp_definitions
   set trim_leading_spaces_yn = 'Y'
 where trim_leading_spaces_yn is null;
commit;

exit;
