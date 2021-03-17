--
-- $Id$
--
alter table customer_aux add
(
   allow_paper_based_sorting_yn  char(1),
   sortation_document            varchar2(255)
);

update customer_aux
   set allow_paper_based_sorting_yn = 'N'
   where allow_paper_based_sorting_yn is null;

exit;
