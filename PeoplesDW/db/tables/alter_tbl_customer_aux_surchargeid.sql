--
-- $Id: alter_tbl_customer_aux_surchargeid.sql $
--
/*
alter table customer_aux add
(
   surchargeid varchar2(12)
);
*/
alter table customer_aux
  drop column surchargeid;
alter table customer_aux_old
  drop column surchargeid;
alter table customer_aux_new
  drop column surchargeid;
  
exit;
