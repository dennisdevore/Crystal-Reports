--
-- $Id: alter_tbl_customer_aux_packlist_email_parms.sql 5854 2010-12-13 14:41:08Z ed $
--
alter table customer_aux add
(
   packlist_email_yn char(1),
   packlist_email_rpt_format varchar2(255),
   packlist_email_addresses varchar2(255)
);

update customer_aux
   set packlist_email_yn = 'N'
 where packlist_email_yn is null;

exit;
