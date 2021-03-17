--
-- $Id$
--
create or replace PACKAGE alps.ztasks
IS

function active_tasks_for_order
(in_orderid number
,in_shipid number
) return boolean;

function active_tasks_for_orderdtl
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return boolean;

function passed_tasks_for_order
(in_orderid number
,in_shipid number
) return boolean;

PROCEDURE task_delete
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE subtask_no_pick
(in_rowid rowid
,in_facility varchar2
,in_custid varchar2
,in_taskid number
,in_lpid varchar2
,in_userid varchar2
,in_delete_commitments_yn varchar2
,out_msg IN OUT varchar2
);

PROCEDURE delete_subtasks_by_loadno
(in_loadno number
,in_userid varchar2
,in_facility varchar2
,out_msg IN OUT varchar2
);

PROCEDURE delete_subtasks_by_order
(in_orderid number
,in_shipid number
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE delete_subtasks_by_orderitem
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,in_reqtype varchar2
,out_msg IN OUT varchar2
);

function upgrade_priority
(in_current_priority varchar2
) return varchar2;

PROCEDURE task_change_priority
(in_facility varchar2
,in_taskid number
,in_priority varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE task_preassign
(in_facility varchar2
,in_taskid number
,in_touserid varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE task_to_pick_list
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE task_reverse_pick_list
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE task_to_labels
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,in_prtid varchar2
,in_profid varchar2
,out_msg IN OUT varchar2
);

PROCEDURE task_reverse_labels
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
);

procedure picked_plate_count
  (in_taskid in number,
   out_count out number,
   out_msg out varchar2);

function task_crush_factor
(in_taskid number
,in_tasktype varchar2
,in_custid varchar2
,in_item varchar2
) return number;

function task_uom_pick_seq
(in_tasktype varchar2
,in_custid varchar2
,in_pickuom varchar2
) return number;

PRAGMA RESTRICT_REFERENCES (upgrade_priority, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (active_tasks_for_order, WNDS, WNPS, RNPS);

END ztasks;
/
exit;
