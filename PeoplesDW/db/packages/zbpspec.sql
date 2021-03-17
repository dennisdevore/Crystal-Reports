--
-- $Id$
--
create or replace package alps.batchpicks as

procedure generate_batch_tasks
(in_wave number
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_batchcartontype varchar2
,in_sortloc varchar2
,in_userid varchar2
,in_trace varchar2
,in_consolidated varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure allocate_picks_to_orders
(in_wave number
,in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_consolidated varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

procedure update_consolidated_tasks
(in_wave number
,in_userid varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);

PROCEDURE delete_batchtasks_by_orderitem
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,in_reqtype varchar2
,out_msg IN OUT varchar2
);

end batchpicks;
/
--exit;
