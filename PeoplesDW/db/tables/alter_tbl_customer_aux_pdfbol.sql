--
-- $Id: alter_tbl_customer_aux_pdfbol.sql  $
--
alter table customer_aux add
(
  pdfbol   char(1) default 'N',
  pdfmbol  char(1) default 'N'
);

exit;
