--
-- $Id$
--
drop view lbl_bp_cs_view;

drop view lbl_bp_cs_view2;

drop view lbl_bp_task_carton_view;

drop view lbl_bp_task_cs_view;

drop view lbl_hf_task_cs_view;

--drop view lbl_hf_task_hdr_view;

--drop view lbl_hf_walmart_cs_view;

update labelprofileline set viewname = 'OLSON_LBL_BP_CS_VIEW' where viewname = 'LBL_BP_CS_VIEW';

update labelprofileline set viewname = 'OLSON_LBL_BP_CS_VIEW2' where viewname = 'LBL_BP_CS_VIEW2';

update labelprofileline set viewname = 'OLSON_LBL_BP_TASK_CARTON_VIEW' where viewname = 'LBL_BP_TASK_CARTON_VIEW';

update labelprofileline set viewname = 'OLSON_LBL_BP_TASK_CS_VIEW' where viewname = 'LBL_BP_TASK_CS_VIEW';

update labelprofileline set viewname = 'OLSON_LBL_HF_TASK_CS_VIEW' where viewname = 'LBL_HF_TASK_CS_VIEW';

update labelprofileline set viewname = 'OLSON_LBL_HF_TASK_HDR_VIEW' where viewname = 'LBL_HF_TASK_HDR_VIEW';

update labelprofileline set viewname = 'OLSON_LBL_HF_WALMART_CS_VIEW' where viewname = 'LBL_HF_WALMART_CS_VIEW';

