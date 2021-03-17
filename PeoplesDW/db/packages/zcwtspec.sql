--
-- $Id$
--
create or replace package alps.zcatchweight
as

function item_avg_weight
   (in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number;
pragma restrict_references (item_avg_weight, wnds, wnps, rnps);

function lp_item_weight
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number;
pragma restrict_references (lp_item_weight, wnds, wnps, rnps);

function ship_lp_item_weight
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_uom    in varchar2)
return number;
pragma restrict_references (ship_lp_item_weight, wnds, wnps, rnps);

function maxleftoverweight
return number;
pragma restrict_references (maxleftoverweight, wnds, wnps, rnps);

procedure set_item_catch_weight
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_qty      in number,
    in_uom      in varchar2,
    in_weight   in number,
    in_user     in varchar2,
    out_message out varchar2);

procedure adjust_shippingplate_weight
	(in_lpid      in varchar2,
    in_weight    in number,
    in_user      in varchar2,
    out_parentlp out varchar2,
    out_message  out varchar2);

procedure process_weight_difference
   (in_lpid           in varchar2,
    in_picked_weight  in number,
    in_prev_lp_weight in number,    -- only used if in_picktype == 'P'
    in_user           in varchar2,
    in_picktype       in varchar2,
    out_message       out varchar2);

procedure add_item_lot_catch_weight
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotnumber in varchar2,
    in_weight    in number,
    out_message  out varchar2);

end zcatchweight;
/

exit;
