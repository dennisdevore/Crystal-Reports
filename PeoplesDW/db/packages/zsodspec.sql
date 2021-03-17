--
-- $Id$
--
create or replace package alps.zshiporder
as

procedure pick_shippingplate
   (in_lpid         in varchar2,
    in_lotno        in varchar2,
    in_receipt      in number,
    in_location     in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_weight       in number,
    in_stageloc     in varchar2,
    in_user         in varchar2,
    in_pickfororder in varchar2,
    in_facility     in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_orderid      in number,
    in_shipid       in number,
    out_errmsg      out varchar2);

procedure load_shippingplate
   (in_lpid         in varchar2,
    in_lotno        in varchar2,
    in_receipt      in number,
    in_location     in varchar2,
    in_qty          in number,
    in_uom          in varchar2,
    in_weight       in number,
    in_stageloc     in varchar2,
    in_user         in varchar2,
    in_pickfororder in varchar2,
    in_facility     in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_orderid      in number,
    in_shipid       in number,
    in_doorloc      in varchar2,
    in_carrier      in varchar2,
    in_billoflading in varchar2,
    in_trailer      in varchar2,
    in_seal         in varchar2,
    in_loadno       in number,
    in_nosetemp     in number,
    in_middletemp   in number,
    in_tailtemp     in number,
    out_errmsg      out varchar2);

procedure force_ship_order(
    in_orderid      in number,
    in_shipid       in number,
    in_userid       in varchar2,
    out_errmsg      out varchar2);

procedure deplete_shippinglpid_qtytasked
   (in_lpid in varchar2,
    out_msg out varchar2);

procedure check_overpick
   (in_qtypick   in number,
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    out_message  out varchar2);

procedure build_outbound_load
   (in_loadno       in number,
    in_orderid      in number,
    in_shipid       in number,
    in_carrier      in varchar2,
    in_trailer      in varchar2,
    in_seal         in varchar2,
    in_billoflading in varchar2,
    in_stageloc     in varchar2,
    in_doorloc      in varchar2,
    in_user         in varchar2,
    io_stopno       in out number,
    io_shipno       in out number,
    out_msg         out varchar2);

procedure close_matissue_workorder(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2);
    
procedure close_production_order(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2);
    
procedure prod_order_export_req(
    in_orderid      in number,
    in_shipid       in number,
    in_facility     in varchar2,
    in_userid       in varchar2,
    out_errmsg      out varchar2); 

end zshiporder;
/

exit;
