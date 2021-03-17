--
-- $Id$
--
create or replace package alps.dynamicpickfront as


procedure process_lp_remove
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_locid    in varchar2);

procedure build_dynamicpf
   (in_facility       in varchar2,
    in_custid         in varchar2,
    in_item           in varchar2,
    in_ar_rowid       in rowid,
    in_invstatus      in varchar2,
    in_inventoryclass in varchar2,
    in_lotnumber      in varchar2,
    in_wave           in number,
    out_pickfront     out varchar2);

function is_dynamicpf
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_locid    in varchar2)
return varchar2;
pragma restrict_references (is_dynamicpf, wnds);

function count_dynamicpfs
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_uom      in varchar2)
return number;
pragma restrict_references (count_dynamicpfs, wnds);

procedure verify_pickfront
   (in_facility  in varchar2,
    in_pickfront in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_dynamic   in varchar2,
    out_msg      out varchar2);


end dynamicpickfront;
/

exit;
