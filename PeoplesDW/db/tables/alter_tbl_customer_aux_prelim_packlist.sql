--
-- $Id: alter_tbl_customer_aux_paper_based_sortpick.sql 6856 2011-06-27 19:41:27Z ed $
--
alter table customer_aux add
(
   prelim_packlist_shipfrom  char(1),   /* 'C'ustomer Address or 'F'acility Address */
   prelim_packlist_rpt varchar2(255),
   prelim_packlist_option1 varchar2(255),
   prelim_packlist_option2 varchar2(255),
   prelim_packlist_option3 varchar2(255)
);

update customer_aux
   set prelim_packlist_shipfrom = 'C'
   where prelim_packlist_shipfrom is null;

exit;
