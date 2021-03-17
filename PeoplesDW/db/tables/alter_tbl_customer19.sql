--
-- $Id$
--
alter table customer add
(
pick_by_line_number_yn char(1)
);
update customer
   set pick_by_line_number_yn = 'N'
 where pick_by_line_number_yn is null;
commit;
--exit;
