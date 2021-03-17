--
-- $Id$
--
create or replace PACKAGE alps.gensorts
IS

procedure compute_largest_whole_pickuom
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
,in_baseuom varchar2
,in_baseqty number
,out_pickuom IN OUT varchar2
,out_pickqty IN OUT number
,out_picktotype IN OUT varchar2
,out_cartontype IN OUT varchar2
,out_baseqty IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure create_sortation_tasks
(in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

END gensorts;
/
exit;