--
-- $Id: invoicedtl_index1.sql 7885 2012-02-01 18:21:25Z eric $
--
create index  invoicedtl_cust_idx on
       invoicedtl(
             custid,
             billmethod,
             activitydate)			 
tablespace users16kb;

exit;