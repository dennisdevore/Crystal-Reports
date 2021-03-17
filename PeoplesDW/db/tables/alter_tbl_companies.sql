--
-- $Id$
--

ALTER TABLE TBL_COMPANIES ADD ( 
  MAX_CANCEL_STATUS VARCHAR(1) );
  /
  update tbl_companies set max_cancel_status='0'
    where max_cancel_status is null;


 exit;



