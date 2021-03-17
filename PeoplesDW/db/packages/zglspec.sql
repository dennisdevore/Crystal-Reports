--
-- $Id$
--
create or replace package alps.genlinepicks as

function total_picks_for_order
(in_orderid in number
,in_shipid in number
) return integer;
   
function total_picks_for_wave
(in_wave in number
) return integer;
   
procedure gen_line_item_pick
(in_facility          in varchar2
,in_orderid           in number
,in_shipid            in number
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_qty               in number
,in_taskpriority      in varchar2
,in_picktype          in varchar2
,in_regen             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure validate_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure validate_unset_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure gen_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_lpid              in varchar2
,in_topick_qty        in number
,out_errorno          in out number
,out_msg              in out varchar2);

procedure get_manual_pick_select_qty
(in_orderid           in number
,in_shipid            in number
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,out_select_qty       in out number);

procedure delete_manual_picks
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_lpid              in varchar2
,in_delete_order_rows in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure gen_order_picks
(in_orderid           in number
,in_shipid            in number
,in_picktype          in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

PRAGMA RESTRICT_REFERENCES (total_picks_for_order, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (total_picks_for_wave, WNDS, WNPS, RNPS);

end genlinepicks;
/
exit;
