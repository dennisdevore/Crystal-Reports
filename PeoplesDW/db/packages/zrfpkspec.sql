--
-- $Id$
--
create or replace package alps.rfpicking as

type type_pass_picks is record (
  lpid shippingplate.lpid%type,
  orderid orderhdr.orderid%type,
  shipid orderhdr.shipid%type,
  taskid tasks.taskid%type,
  tasktype tasks.tasktype%type,
  mass_manifest waves.mass_manifest%type
);
type cursor_pass_picks is ref cursor return type_pass_picks;

type type_pnd_locations is record (
  panddlocation zone.panddlocation%type
);
type cursor_pnd_locs is ref cursor return type_pnd_locations;

function is_attrib_ok
   (in_ind    in varchar2,
    in_list   in varchar2,
    in_attrib in varchar2)
return boolean;
pragma restrict_references (is_attrib_ok, wnds, wnps, rnps);

function any_vlp_batch_work
   (in_lpid       in varchar2)
return boolean;
pragma restrict_references (any_vlp_batch_work, wnds, wnps, rnps);

procedure build_carton
   (in_clip         in varchar2,
    in_shlpid       in varchar2,
    in_user         in varchar2,
    in_need_master  in varchar2,
    in_tasktype     in varchar2,
    in_cartontype   in varchar2,
    out_message     out varchar2);

procedure build_mast_shlp
   (in_mlip       in varchar2,
    in_shlpid     in varchar2,
    in_user       in varchar2,
    in_tasktype   in varchar2,
    out_builtmlip out varchar2,
    out_message   out varchar2);

procedure pick_a_plate
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_qty             in number,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_uom             in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_extra_process   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_pickqty         in number,
    in_weight          in number,
    in_taskedlp        in varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2);

procedure stage_a_plate
   (in_shlpid        in varchar2,
    in_drop_loc      in varchar2,
    in_user          in varchar2,
    in_tasktype      in varchar2,
    in_pass          in varchar2,
    in_stage_loc     in varchar2,
    in_mass_manifest in varchar2,
    in_deconsolidate in varchar2,
    out_error        out varchar2,
    out_message      out varchar2,
    out_is_loaded    out varchar2);    -- 'Y' if load switched to status '8'; else 'N'

procedure stage_for_kitting
   (in_lpid            in varchar2,
    in_facility        in varchar2,
    in_drop_loc        in varchar2,
    in_user            in varchar2,
    in_tasktype        in varchar2,
    in_workorderseq    in number,
    in_workordersubseq in number,
    in_stage_loc       in varchar2,
    out_error          out varchar2,
    out_message        out varchar2);

procedure add_loc_cycle_count
   (in_location     in varchar2,
    in_facility     in varchar2,
    in_reason       in varchar2,
    in_pickpriority in varchar2,
    in_user         in varchar2,
    out_message     out varchar2);

procedure bump_custitemcount
   (in_custid    in varchar2,
    in_item      in varchar2,
    in_type      in varchar2,
    in_uom       in varchar2,
    in_cnt       in number,
    in_user      in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure check_pick_fifo
   (in_plannedlp  in varchar2,
    in_uom        in varchar2,
    in_qty        in number,
    in_zone       in varchar2,
    in_pickedlp   in varchar2,
    in_custid     in varchar2,
    in_item       in varchar2,
    in_lotno      in varchar2,
    out_invstatus out varchar2,
    out_invclass  out varchar2,
    out_message   out varchar2);

procedure resume_passed_pick
   (in_lpid       in varchar2,
    in_lptype     in varchar2,
    in_user       in varchar2,
    out_tasktype  out varchar2,
    out_message   out varchar2);

procedure reinstate_task
   (in_taskid   in number,
    in_user     in varchar2,
    out_message out varchar2);

procedure serial_pick
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_requested       in number,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_partmpcpt       in number,
    in_taskedlp        in varchar2,
    io_multi           in out varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2);

procedure linepick_multi
   (in_taskid   in number,
    in_tasktype in varchar2,
    in_dropseq  in number,
    in_user     in varchar2,
    in_lpid     in varchar2,
    in_pickfac  in varchar2,
    in_pickloc  in varchar2,
    out_lpcount out number,
    out_error   out varchar2,
    out_message out varchar2);

procedure stage_multi
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_drop_loc  in varchar2,
    in_user      in varchar2,
    in_tasktype  in varchar2,
    in_stage_loc in varchar2,
    out_error    out varchar2,
    out_message  out varchar2);

procedure pick_1_sn_from_mp
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_taskedlp        in varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2);

procedure adjust_for_extra_pick
   (in_subtask_rowid in varchar2,
    in_shlpid        in varchar2,
    in_pickqty       in number,
    in_pickuom       in varchar2,
    in_qty           in number,
    in_user          in varchar2,
    in_pickedlp      in varchar2,
    out_rowid        out varchar2,
    out_message      out varchar2);

procedure get_alternate_pick
   (in_subtask_rowid in varchar2,
    in_user          in varchar2,
    in_equipment     in varchar2,
    out_lpid         out varchar2,
    out_location     out varchar2,
    out_message      out varchar2);

procedure assign_step2_plates
   (in_taskid   in number,
    in_fromloc  in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure take_item
   (in_facility     in varchar2,
    in_orderid      in number,
    in_shipid       in number,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_lpid         in varchar2,
    in_loc          in varchar2,
    in_shiplpid     in varchar2,
    in_user         in varchar2,
    out_errorno     out number,
    out_message     out varchar2,
    out_loaded_load out varchar2);  -- non-zero if load switched to status '8'; else 0

procedure any_after_pick_counting
   (in_facility     in varchar2,
    in_location     in varchar2,
    in_lpid         in varchar2,
    in_user         in varchar2,
    out_taskid      out number,
    out_message     out varchar2);

procedure putaway_virtual
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure stage_full_virtual
   (in_lpid     in varchar2,
    in_user     in varchar2,
    in_tasktype in varchar2,
    out_message out varchar2);

procedure check_overpick
   (in_pickqty       in number,
    in_item          in varchar2,
    in_pickuom       in varchar2,
    in_subtask_rowid in varchar2,
    out_lower        out number,
    out_upper        out number,
    out_errorno      out number,
    out_message      out varchar2);

procedure pick_an_mp_child
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_baseuom         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_picktype        in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    in_pickuom         in varchar2,
    in_unit_weight     in number,
    in_needed          in number,
    in_taskedlp        in varchar2,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2,
    out_picked         out varchar2);

procedure pick_1_full
   (in_taskid          in number,
    in_shlpid          in varchar2,
    in_user            in varchar2,
    in_pickedlp        in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_dropseq         in number,
    in_pickuom         in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_subtask_rowid   in varchar2,
    in_remaining       in number,
    out_clip           out varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2);

procedure is_auto_stage_loc_mixed
   (in_orderid in number,
    in_shipid in number,
    in_user in varchar2,
    out_mixed out varchar2);

procedure is_print_at_pick_ok
   (in_facility      in varchar2,
    in_custid        in varchar2,
    in_enteredlpid   in varchar2,
    out_ok           out varchar2);

procedure ship_matissue_lp
  (in_shlpid        in varchar2,
   in_user          in varchar2,
   out_error        out varchar2,
   out_message      out varchar2);

function valid_pass_pick_task(
  v_taskid in tasks.taskid%type)
return number;

/* this function will return if the user, facility combination currently has any
   partially picked order tasks where they need to be passed to someone else
   because the customer is set to force pick passing
   returns 'Y' or 'N'
*/
function any_force_pass_picks
  (in_user              in varchar2,
   in_facility          in varchar2)
return varchar2;

procedure get_force_pass_pick_locs
  (in_user              in varchar2,
   in_facility          in varchar2,
   out_cursor           out cursor_pnd_locs);

procedure get_force_pass_picks
  (in_user              in varchar2,
   in_facility          in varchar2,
   in_pndloc            in varchar2,
   out_cursor           out cursor_pass_picks);

function any_pass_plates_for_task
  (in_taskid            in varchar2)
return number;

function get_pnd_loc_for_task
  (in_taskid            in varchar2,
   in_facility          in varchar2,
   in_location          in varchar2)
return varchar2;

function get_pnd_location
  ( in_facility          in varchar2,
    in_location          in varchar2)
return varchar2;

procedure get_pass_picks_in_loc
  (in_facility          in varchar2,
   in_location          in varchar2,
   in_equipment         in varchar2,
   out_cursor           out cursor_pass_picks,
   out_message          out varchar2);

procedure validate_pass_plate
  (in_facility          in varchar2,
   in_location          in varchar2,
   in_lpid              in varchar2,
   in_equipment         in varchar2,
   out_taskid           out number,
   out_orderid          out number,
   out_shipid           out number,
   out_message          out varchar2);

procedure cluster_resume_pass_pick
  (in_taskid            in number,
   in_facility          in varchar2,
   in_location          in varchar2,
   in_position          in number,
   in_user              in varchar2,
   io_tasktype          in out varchar2,
   out_message          out varchar2);

function can_equip_pick_subtask
  (in_equipment         in varchar2,
   in_subtask_rowid     in varchar2)
return varchar2;

procedure move_orders_to_picked
  (in_included_rowids IN clob
  ,in_facility IN varchar2
  ,in_userid IN varchar2
  ,out_errorno IN OUT number
  ,out_msg  IN OUT varchar2
  ,out_warning_count IN OUT number
  ,out_error_count IN OUT number
  ,out_picked_count IN OUT number
);

PROCEDURE order_to_picked
  (in_orderid IN number
  ,in_shipid IN number
  ,in_facility IN varchar2
  ,in_userid IN varchar2
  ,out_warning IN OUT number
  ,out_errorno IN OUT number
  ,out_msg  IN OUT varchar2
);

end rfpicking;
/
show errors package rfpicking;
exit;
