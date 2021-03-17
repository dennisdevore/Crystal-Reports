--
-- $Id$
--
create or replace package alps.rf as

-- constants

ORD_PICKING       CONSTANT    varchar2(1) := '5';
ORD_PICKED        CONSTANT    varchar2(1) := '6';
ORD_LOADING       CONSTANT    varchar2(1) := '7';
ORD_LOADED        CONSTANT    varchar2(1) := '8';

LOD_PICKING       CONSTANT    varchar2(1) := '5';
LOD_PICKED        CONSTANT    varchar2(1) := '6';
LOD_LOADING       CONSTANT    varchar2(1) := '7';
LOD_LOADED        CONSTANT    varchar2(1) := '8';


-- Public functions

procedure single_misc_charge
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_ordertype in varchar2,
    in_activity  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_shipno    in number,
    in_user      in varchar2,
    in_comment1  in clob,
    in_weight    in number,
    out_message  out varchar2,
    in_billmethod in varchar2 default null);

function xlate_fromlpid
   (fromlp in varchar2,
    mylp   in varchar2)
return varchar2;
pragma restrict_references (xlate_fromlpid, wnds, wnps, rnps);

function calc_expiration
   (expires       in varchar2,
    manufactured  in varchar2,
    shelflife     in number)
return date;
pragma restrict_references (calc_expiration, wnds, wnps, rnps);

function is_location_physical
   (in_facility in varchar2,
    in_location in varchar2)
return varchar2;
pragma restrict_references (is_location_physical, wnds, wnps, rnps);

function is_plate_passed
   (in_lpid   in varchar2,
    in_lptype in varchar2)
return number;                   -- 0 => false else true
pragma restrict_references (is_plate_passed, wnds, wnps, rnps);

function last_nonsu_invstatus
   (in_lpid in varchar2)
return varchar2;
pragma restrict_references (last_nonsu_invstatus, wnds, wnps, rnps);

function any_tasks_for_lp
   (in_lpid       in varchar2,
    in_parentlpid in varchar2)
return boolean;
pragma restrict_references (any_tasks_for_lp, wnds, wnps, rnps);

function virtual_lpid
   (in_lpid in varchar2)
return varchar2;                 -- null => not part of a virtual lp tree
pragma restrict_references (virtual_lpid, wnds, wnps, rnps);

function is_expiration_in_past
   (in_expdate in varchar2,
    in_mfgdate in varchar2,
    in_custid  in varchar2,
    in_item    in varchar2)
return varchar2;
pragma restrict_references (is_expiration_in_past, wnds, wnps, rnps);


-- Public procedures


procedure move_shippingplate
   (in_rowid     in rowid,
    in_location  in varchar2,
    in_status    in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    out_message  out varchar2);

procedure get_next_lpid
   (out_lpid    out varchar2,
    out_message out varchar2);

procedure verify_location
   (in_facility     in varchar2,
    in_location     in varchar2,
    in_equipment    in varchar2,
    out_loc_status  out varchar2,
    out_loc_type    out varchar2,
    out_check_id    out varchar2,
    out_error       out varchar2,
    out_message     out varchar2);

procedure verify_super_axs
   (in_user     in varchar2,
    in_pword    in varchar2,
    in_form     in varchar2,
    in_facility in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure verify_custitem
   (in_custid        in varchar2,
    in_item          in varchar2,
    out_item         out varchar2,
    out_baseuom      out varchar2,
    out_expiryact    out varchar2,
    out_recinvsts    out varchar2,
    out_weight       out number,
    out_cube         out number,
    out_amt          out number,
    out_shelflife    out number,
    out_parsefield   out varchar2,
    out_parseruleid  out varchar2,
    out_error        out varchar2,
    out_message      out varchar2);

procedure start_receiving
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_loadno    in number,
    in_try_bulk  in varchar2,
    in_opmode    in varchar2,
    out_loadno   out number,
    out_po       out varchar2,
    out_custid   out varchar2,
    out_custname out varchar2,
    out_is_dock  out varchar2,
    out_has_xfer out varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure get_baseuom_factor
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_baseuom  in varchar2,
    in_touom    in varchar2,
    io_factor   in out number,
    out_error   out varchar2,
    out_message out varchar2);

procedure mark_dock_empty
   (in_dockdoor   in varchar2,
    in_facility   in varchar2,
    in_equipment  in varchar2,
    in_user       in varchar2,
    in_loadno     in number,
    in_nosetemp   in number,
    in_middletemp in number,
    in_tailtemp   in number,
    out_error     out varchar2,
    out_message   out varchar2);

procedure verify_facility
   (in_facility     in varchar2,
    in_user         in varchar2,
    out_usecheckids out varchar2,
    out_error       out varchar2,
    out_message     out varchar2);

procedure verify_customer
   (in_custid    in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure bind_lp_to_user
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_custid    in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    in_tasktype  in varchar2,
    in_shipok    in varchar2,
    out_error    out varchar2,
    out_message  out varchar2,
    out_facility out varchar2,
    out_location out varchar2,
    out_status   out varchar2,
    out_item     out varchar2,
    out_custid   out varchar2,
    out_rowid    out varchar2,
    out_wasship  out varchar2,
    out_lpid     out varchar2,
    out_lptype   out varchar2);

procedure wand_taskable_lp
   (in_lpid      in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_tasktype  in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure identify_lp
   (in_lpid        in varchar2,
    out_lptype     out varchar2,
    out_xrefid     out varchar2,
    out_xreftype   out varchar2,
    out_parentid   out varchar2,
    out_parenttype out varchar2,
    out_topid      out varchar2,
    out_toptype    out varchar2,
    out_message    out varchar2);

procedure decrease_lp
   (in_lpid      in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    in_invstatus in varchar2,
    in_invclass  in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure suspend_item
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_qty       in number,
    in_user      in varchar2,
    in_invclass  in varchar2,
    in_fromlpid  in varchar2,
    out_message  out varchar2);

procedure unempty_dock
   (in_dockdoor  in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_user      in varchar2,
    io_loadno    in out number,
    out_error    out varchar2,
    out_message  out varchar2);

procedure tally_lp_receipt
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2);


procedure lpid_auto_charge
   (in_event    in varchar2,
    in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure cust_auto_charge
   (in_event    in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_po       in varchar2,
    in_loadno   in number,
    in_stopno   in number,
    in_shipno   in number,
    in_user     in varchar2,
    out_message out varchar2);

procedure build_in_lp_from_qa
   (in_qalpid   in varchar2,
    in_inlpid   in varchar2,
    in_qty      in number,
    in_user     in varchar2,
    out_adj1    out varchar2,
    out_adj2    out varchar2,
    out_adj3    out varchar2,
    out_adj4    out varchar2,
    out_errno   out number,
    out_message out varchar2);

procedure hold_lp_tasks
   (in_lpid      in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure process_held_lp_tasks
   (in_lpid      in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure calc_misc_charges
   (in_facility  in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_ordertype in varchar2,
    in_activity  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_shipno    in number,
    in_user      in varchar2,
    out_message  out varchar2);

procedure so_lock
   (io_key in out number);

procedure so_release
   (io_key in out number);

procedure get_next_vlpid
   (out_vlpid   out varchar2,
    out_message out varchar2);

procedure add_item
    (in_custid  in  varchar2,
     in_item    in  varchar2,
     in_baseuom in  varchar2,
     in_nextuom in  varchar2,
     in_nextqty in  number,
     in_workuom in  varchar2,
     in_length  in  number,
     in_width   in  number,
     in_height  in  number,
     in_weight  in  number,
     in_pickto  in  varchar2,
     in_cnttype in  varchar2,
     in_userid  in  varchar2,
     out_msg    out varchar2);

procedure is_lp_overbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    out_overbuilt out number);

procedure check_underbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    out_underbuilt out number);

procedure is_lp_underbuilt
   (in_lip       in varchar2,
    in_customer   in varchar2,
    in_item       in varchar2,
    in_entuom     in varchar2,
    in_qty        in number,
    in_baseuom    in varchar2,
    in_underqty   in number,
    out_underbuilt out number);

procedure verify_multi_item
   (in_mlip       in varchar2,
    in_item       in varchar2,
    out_multi_item out number);

procedure rf_assume_task
   (in_facility      in  varchar2,
    in_orig_userid   in  varchar2,
    in_new_userid    in  varchar2,
    out_error        out number,
    out_message      out varchar2);
procedure add_rf_user_linux_login
   (in_facility        in varchar2,
    in_rf_userid   in out varchar2,
    in_rf_userid_info  in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2);
procedure modify_rf_user_linux_login
   (in_facility        in varchar2,
    in_rf_userid   in out varchar2,
    in_rf_userid_info  in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2);
procedure populate_rf_sessions
   (in_facility        in varchar2,
    in_userid          in out varchar2,
    out_error          out number,
    out_message        out varchar2);
procedure kill_rf_user
   (in_facility  in varchar2,
    in_rf_userid in varchar2,
    in_userid    in varchar2,
    out_error    out number,
    out_message  out varchar2);
procedure is_order_international
   (in_orderid       in number,
    in_shipid        in number,
    out_international out number);

procedure damage_shippingplate
   (in_lpid      in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_qty       in number,
    in_lotno     in varchar2,
    in_uom       in varchar2,
    in_lptype    in varchar2,
    in_reason    in varchar2,
    in_fromlpid  in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  in out varchar2);


end rf;
/

show errors package rf;

exit;
