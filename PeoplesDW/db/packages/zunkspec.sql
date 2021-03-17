--
-- $Id$
--
create or replace package alps.unknown as

-- constants

UNK_RCPT_ITEM     CONSTANT    varchar2(10) := 'UNKNOWN';
UNK_RTRN_ITEM     CONSTANT    varchar2(10) := 'RETURNS';


-- Public procedures


procedure add_unknown_item(in_custid   in varchar2,
                           in_item     in varchar2,
                           in_user     in varchar2,
                           out_message out varchar2);

procedure build_unknown_lp(in_lpid           in varchar2,
                           in_facility       in varchar2,
                           in_location       in varchar2,
                           in_custid         in varchar2,
                           in_item           in varchar2,
                           in_qty            in number,
                           in_uom            in varchar2,
                           in_user           in varchar2,
                           in_loadno         in number,
                           in_stopno         in number,
                           in_shipno         in number,
                           in_orderid        in number,
                           in_shipid         in number,
                           in_invstatus      in varchar2,
                           in_lpstatus       in varchar2,
                           in_disposition    in varchar2,
                           in_po             in varchar2,
                           in_recmethod      in varchar2,
                           in_inventoryclass in varchar2,
                           in_condition      in varchar2,
                           out_message       out varchar2);

procedure del_unknown_lp(in_lpid       in varchar2,
                         in_item       in varchar2,
                         in_user       in varchar2,
                         out_message   out varchar2);

procedure empty_unknown_lp(in_lpid       in varchar2,
                           in_user       in varchar2,
                           out_message   out varchar2);

end unknown;
/

exit;
