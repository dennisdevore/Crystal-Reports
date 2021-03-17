--
-- $Id$
--
create or replace PACKAGE alps.zinvadj
IS

PROCEDURE inventory_adjustment
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
,in_inventoryclass varchar2
,in_invstatus varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
,in_location varchar2
,in_expirationdate date
,in_qty number
,in_orig_custid varchar2
,in_orig_item varchar2
,in_orig_inventoryclass varchar2
,in_orig_invstatus varchar2
,in_orig_lotnumber varchar2
,in_orig_serialnumber varchar2
,in_orig_useritem1 varchar2
,in_orig_useritem2 varchar2
,in_orig_useritem3 varchar2
,in_orig_location varchar2
,in_orig_expirationdate date
,in_orig_qty number
,in_facility varchar2
,in_adjreason varchar2
,in_userid varchar2
,in_tasktype varchar2
,in_weight number
,in_orig_weight number
,in_mfgdate date
,in_orig_mfgdate date
,in_anvdate date
,in_orig_anvdate date
,out_adjrowid1 IN OUT varchar2
,out_adjrowid2 IN OUT varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_custreference IN varchar2 default null
,in_tasks_ok IN varchar2 default null
,in_suppress_edi_yn varchar2 default 'N'
,in_sysdate IN date default null
,in_comments IN clob default null
,in_adjust_picked_invstatus in varchar2 default null
,in_adjust_orderdtlrcpt IN varchar2 default 'N'
,in_calc_weight_from_item IN varchar2 default 'N'
,in_calling_proc IN varchar2 default null
);

PROCEDURE inventory_adjustment
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
,in_inventoryclass varchar2
,in_invstatus varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
,in_location varchar2
,in_expirationdate date
,in_qty number
,in_orig_custid varchar2
,in_orig_item varchar2
,in_orig_inventoryclass varchar2
,in_orig_invstatus varchar2
,in_orig_lotnumber varchar2
,in_orig_serialnumber varchar2
,in_orig_useritem1 varchar2
,in_orig_useritem2 varchar2
,in_orig_useritem3 varchar2
,in_orig_location varchar2
,in_orig_expirationdate date
,in_orig_qty number
,in_facility varchar2
,in_adjreason varchar2
,in_userid varchar2
,in_tasktype varchar2
,in_weight number
,in_orig_weight number
,in_mfgdate date
,in_orig_mfgdate date
,in_anvdate date
,in_orig_anvdate date
,in_length number
,in_orig_length number
,in_width number
,in_orig_width number
,in_height number
,in_orig_height number
,in_pallet_weight number
,in_orig_pallet_weight number
,out_adjrowid1 IN OUT varchar2
,out_adjrowid2 IN OUT varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_custreference IN varchar2 default null
,in_tasks_ok IN varchar2 default null
,in_suppress_edi_yn varchar2 default 'N'
,in_sysdate IN date default null
,in_comments IN clob default null
,in_adjust_picked_invstatus in varchar2 default null
,in_adjust_orderdtlrcpt IN varchar2 default 'N'
,in_calc_weight_from_item IN varchar2 default 'N'
,in_calling_proc IN varchar2 default null
);

PROCEDURE change_invstatus
(in_lpid varchar2
,in_newinvstatus varchar2
,in_reason varchar2
,in_tasktype varchar2
,in_userid varchar2
,out_adjrowid1 IN OUT varchar2
,out_adjrowid2 IN OUT varchar2
,out_controlnumber IN OUT varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_tasks_ok IN varchar2 default null
,in_suppress_edi_yn varchar2 default 'N'
);

PROCEDURE change_invclass
(in_lpid varchar2
,in_newinvclass varchar2
,in_reason varchar2
,in_tasktype varchar2
,in_tasks_ok IN varchar2 default null
,in_userid varchar2
,out_adjrowid1 IN OUT varchar2
,out_adjrowid2 IN OUT varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

PROCEDURE mass_inventory_adjustment
(out_errorcount IN OUT number);

procedure loc_invstatus_change
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
,in_baseuom varchar2
,in_qty number
,in_weight number
,in_facility varchar2
,in_invstatus varchar2
,in_adjreason varchar2
,in_tasktype varchar2
,in_event varchar2 -- 'ENTR' or 'EXIT'
,in_userid varchar2
);

END zinvadj;
/
exit;
