--
-- $Id$
--
create or replace package alps.zputaway as

procedure get_uoms_in_uos
   (in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_uos       in varchar2,
    io_howmany   in out number,
    out_error    out varchar2,
    out_message  out varchar2);

procedure get_used_uos
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_uos       in varchar2,
    in_curlp     in varchar2,
    io_used      in out number,
    out_error    out varchar2,
    out_message  out varchar2);

procedure putaway_lp
   (in_action       in varchar2,
    in_lpid         in varchar2,
    in_facility     in varchar2,
    in_location     in varchar2,
    in_sender       in varchar2,
    in_keeptogether in varchar2,
    in_equipment    in varchar2,
    out_message     out varchar2,
    out_facility    out varchar2,
    out_location    out varchar2);

procedure putaway_lp_delay
   (in_action       in varchar2,
    in_lpid         in varchar2,
    in_facility     in varchar2,
    in_location     in varchar2,
    in_sender       in varchar2,
    in_keeptogether in varchar2,
    out_message     out varchar2);

procedure rebuild_putaway_mps
   (in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure assign_item
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_location  in varchar2,
    in_item	     in varchar2,
    in_newitem   in varchar2,
    in_newcustid in varchar2,
    out_message  out varchar2);

procedure unassign_item
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_location in varchar2,
    in_item	    in varchar2,
    out_message out varchar2);

procedure get_remaining_uoms
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_curlp     in varchar2,
    in_maxqty    in number,
    in_maxuom    in varchar2,
    io_remaining in out number,
    out_error    out varchar2,
    out_message  out varchar2);

function is_putaway_loc_restricted
   (in_lpid  in varchar2,
    in_loc   in varchar2)
return varchar2;
pragma restrict_references (is_putaway_loc_restricted, wnds);

procedure highest_whole_uom
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_uom      in varchar2,
    out_qty     out number,
    out_uom     out varchar2,
    out_message out varchar2);

procedure putaway_decon_orphans;


end zputaway;
/

exit;
