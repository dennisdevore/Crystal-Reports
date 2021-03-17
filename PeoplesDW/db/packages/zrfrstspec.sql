--
-- $Id$
--
create or replace package alps.rfrestaging as

procedure adjust_orderdtlline
   (in_custid    in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    in_qty       in number,
    in_newshipid in number,
    in_user      in varchar2,
    out_message  out varchar2);

procedure wand_lp_for_restage
   (in_lpid      in varchar2,
    in_facility  in varchar2,
    in_user      in varchar2,
    in_equipment in varchar2,
    out_custid   out varchar2,
    out_location out varchar2,
    out_orderid  out number,
    out_shipid   out number,
    out_error    out varchar2,
    out_message  out varchar2);

procedure verify_newshipid
   (in_orderid   in number,
    in_shipid    in number,
    in_newshipid in number,
    out_loadno   out number,
    out_message  out varchar2);

procedure restage_shipid
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_user      in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_newshipid in number,
    out_error    out varchar2,
    out_message  out varchar2);

end rfrestaging;
/

exit;
