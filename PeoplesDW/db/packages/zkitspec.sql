--
-- $Id$
--
create or replace package alps.kitting
as

procedure load_custworkorder
	(in_seq	    in number,
	 out_message out varchar2);

function first_subseq		         -- assumes load_custworkorder has been called
	(in_component in varchar2,
	 in_facility  in varchar2)
return custworkorderinstructions.subseq%type;

function is_subseq_ready
   (in_seq      in number,
    in_subseq   in number,
    in_facility in varchar2,
    in_location in varchar2)
return number;                      -- 0 => false else true
pragma restrict_references (is_subseq_ready, wnds, wnps, rnps);

function any_subseq_ready
   (in_seq      in number,
    in_facility in varchar2,
    in_location in varchar2)
return number;                      -- 0 => false else true
pragma restrict_references (any_subseq_ready, wnds, wnps, rnps);

function is_kit_closeable
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    in_lotnumber in varchar2)
return varchar2;
pragma restrict_references (is_kit_closeable, wnds);

procedure find_pick_stage_loc
	(in_seq 			 	in number,		-- sequence of workorder
	 in_lpid 		 	in varchar2,	-- lp (shipping or license) to stage
	 in_facility	 	in varchar2,   -- operator's current facility
	 out_stage_loc	 	out varchar2,	-- selected staging location (could be null)
	 out_stage_type 	out varchar2,  -- selected type of staging location (could be null)
	 out_stage_abbrev out varchar2,  -- abbreviation of staging location type (could be null)
	 out_subseq       out number, 	-- subseq associated with staging location
    out_error      	out varchar2,	-- if 'Y' then I/O errror in out_message
    out_message    	out varchar2); -- error or 'warning' message

procedure start_workorder
	(in_orderid 	in number,
	 in_shipid     in number,
	 in_user       in varchar2,
	 out_seq 		out number,
	 out_custid		out varchar2,
    out_error     out varchar2,
    out_message   out varchar2);

procedure show_cwo
	(in_seq	     in number,
	 in_facility  in varchar2,
	 in_component in varchar2 := null);

procedure get_topmost_order
   (in_seq                in number,
    out_orderid           out number,
    out_shipid            out number,
    out_ordertype         out varchar2,
    out_qtyorder          out number,
    out_componenttemplate out varchar2,
    out_stageloc          out varchar2,
    out_message           out varchar2);

procedure complete_subseq
   (in_facility in varchar2,
    in_location in varchar2,
    in_seq      in number,
    in_subseq   in number,
    in_qtydone  in number,
    in_newloc   in varchar2,
	 in_user     in varchar2,
    in_qtycheck in varchar2,
    out_seqdone out varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure scrap_component
   (in_facility  in varchar2,
    in_seq       in number,
    in_custid    in varchar2,
    in_component in varchar2,
    in_qty       in number,
	 in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure finishup_seq
   (in_facility  in varchar2,
    in_seq       in number,
    in_custid    in varchar2,
	 in_user      in varchar2,
    out_message  out varchar2);

procedure test_lp_dekit
   (in_lpid       in varchar2,
    in_facility   in varchar2,
	 out_custid    out varchar2,
    out_item      out varchar2,
    out_location  out varchar2,
    out_msgno     out number,
    out_message   out varchar2);

procedure dekit_lp
   (in_lpid       in varchar2,
	 in_user       in varchar2,
    out_msgno     out number,
    out_message   out varchar2);

procedure restore_comp_lp
   (in_lpid       in varchar2,      -- lp to restore
    in_facility   in varchar2,
    in_qty        in number,
	 in_user       in varchar2,
    in_mlip       in varchar2,      -- lp of multi (if any)
    in_klip       in varchar2,      -- lp of kit item
    out_error     out varchar2,
    out_msgno     out number,
    out_message   out varchar2);

procedure finish_noauto_dekit
   (in_lpid       in varchar2,
    in_qty        in number,
	 in_user       in varchar2,
    out_message   out varchar2);

procedure finish_comp_cleanup
   (in_facility   in varchar2,
    in_seq        in number,
    in_item       in varchar2,
	 in_user       in varchar2,
    in_lpid       in varchar2,  -- null OK
    in_lpqty      in number,    -- ignored if in_lpid is null
    in_putfromloc in varchar2,  -- ignored if in_lpid is null
    in_opcode     in number,    -- ignored if in_lpid is null: 0-insert, 1-update, 2-undelete
    in_spoiled    in varchar2,
    out_error     out varchar2,
    out_msgno     out number,
    out_message   out varchar2);

procedure package_component
   (in_facility     in varchar2,
    in_opcode       in number,
    in_seq          in number,
    in_lpid         in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_invstatus    in varchar2,
    in_invclass     in varchar2,
    in_lotnumber    in varchar2,
    in_serialnumber in varchar2,
    in_useritem1    in varchar2,
    in_useritem2    in varchar2,
    in_useritem3    in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_user         in varchar2,
    in_weight       in number,
    out_done        out varchar2,
    out_error       out varchar2,
    out_message     out varchar2);

procedure complete_kit_wave
(in_wave IN number
,in_userid IN varchar2
,out_errmsg IN OUT varchar2
);

procedure closeout_kit
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    in_lotnumber in varchar2,
	 in_user      in varchar2,
    out_message  out varchar2);

procedure purge_closed_kit_subtask
   (in_rowid    in varchar2,
	 in_user     in varchar2,
    out_results out varchar2,
    out_message out varchar2);


end kitting;
/

exit;
