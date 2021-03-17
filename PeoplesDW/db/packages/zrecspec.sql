--
-- $Id$
--
create or replace package alps.zreceive as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- check_order
--
----------------------------------------------------------------------
PROCEDURE check_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_loadno    IN      number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- find_orders
--
----------------------------------------------------------------------
PROCEDURE find_orders
(
    in_loadno    IN      number,
    out_orderid  OUT     number,
    out_shipid  OUT     number,
    out_count    OUT     number,
    out_errmsg   OUT     varchar2
);


----------------------------------------------------------------------
--
-- add_receipt_lpid
--
----------------------------------------------------------------------
PROCEDURE add_receipt_lpid
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_shipno    IN      number,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_serial    IN      varchar2,
    in_useritem1 IN      varchar2,
    in_useritem2 IN      varchar2,
    in_useritem3 IN      varchar2,
    in_countryof IN      varchar2,
    in_expdate   IN      date,
    in_mfgdate   IN      date,
    in_qty       IN      number,
    in_uom       IN      varchar2,
    in_lpid      IN      varchar2,
    in_mlpid     IN      varchar2,
    in_invstatus IN      varchar2,
    in_invclass  IN      varchar2,
    in_facility  IN      varchar2,
    in_location  IN      varchar2,
    in_user      IN      varchar2,
    in_handtype  IN      varchar2,
    in_action    IN      varchar2,
    in_weight    IN      number,
    out_errmsg   OUT     varchar2
);

----------------------------------------------------------------------
--
-- complate_plate -
--
----------------------------------------------------------------------
PROCEDURE complete_plate
(
   in_lpid     IN  varchar2,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
);

----------------------------------------------------------------------
--
-- empty_trailer -
--
----------------------------------------------------------------------
PROCEDURE empty_trailer
(
   in_dock       IN  varchar2,
   in_facility   IN  varchar2,
   in_loadno     IN  number,
   in_user       IN  varchar2,
   in_nosetemp   IN  number,
   in_middletemp IN  number,
   in_tailtemp   IN  number,
   out_errmsg    OUT varchar2
);

----------------------------------------------------------------------
--
-- transfer_plate -
--
----------------------------------------------------------------------
PROCEDURE transfer_plate
(
   in_lpid     IN  varchar2,
   in_facility IN  varchar2,
   in_location IN  varchar2,
   in_loadno   IN  number,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
);


procedure check_line_qty
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_qty_to_receive IN number
,out_errorno IN OUT number
,out_errmsg OUT varchar2
);

PROCEDURE change_qtyapproved
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_linenumber IN number
,in_qtyapproved IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
);

procedure check_overage
   (in_orderid   in number,
    in_shipid    in number,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotnumber in varchar2,
    in_qty       in number,
    out_errno    out number,
    out_msg      out varchar2,
    out_supcode  out varchar2);

procedure verify_master_receipt
   (in_mstr_orderid in number,
    in_mstr_shipid  in number,
    in_custid       in varchar2,
    in_rcpt_orderid in number,
    in_rcpt_shipid  in number,
    out_msg         out varchar2);

procedure close_master_receipt
   (in_mstr_orderid in number,
    in_mstr_shipid  in number,
    in_userid       in varchar2,
    out_msg         out varchar2);

procedure update_receipt_dtl
   (in_orderid     in number,
    in_shipid      in number,
    in_item        in varchar2,
    in_lotnumber   in varchar2,
    in_uom         in varchar2,
    in_itementered in varchar2,
    in_uomentered  in varchar2,
    in_qty         in number,
    in_qtygood     in number,
    in_qtydmgd     in number,
    in_weight      in number,
    in_weightgood  in number,
    in_weightdmgd  in number,
    in_cube        in number,
    in_cubegood    in number,
    in_cubedmgd    in number,
    in_amt         in number,
    in_amtgood     in number,
    in_amtdmgd     in number,
    in_userid      in varchar2,
    in_comment     in varchar2,
    out_msg        out varchar2);

procedure verify_inbound_notice
   (in_inot_orderid in number,
    in_inot_shipid  in number,
    in_custid       in varchar2,
    out_msg         out varchar2);

procedure close_inbound_notice
   (in_inot_orderid in number,
    in_inot_shipid  in number,
    in_userid       in varchar2,
    out_msg         out varchar2);

procedure get_autoinc_value
   (in_custid  in varchar2,
    in_item    in varchar2,
    in_lotno   in varchar2,
    in_type    in varchar2,         -- 'LOT','SER','US1','US2','US3'
    in_orderid in number,
    in_shipid  in number,
    out_value  out varchar2,
    out_msg    out varchar2);

procedure update_inbound_plate_dim
   (in_lpid    in varchar2,
    in_length  in number,
    in_width   in number,
    in_height  in number,
    in_plt_weight in number,
    in_user    in varchar2,
    out_msg    out varchar2);

procedure get_useritem1_from_asn
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    out_useritem1 in out varchar2);

procedure orderdtl_text
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotno      in varchar2,
    in_import_col in varchar2,
    out_text      out varchar2,
    out_msg       out varchar2);

procedure update_orderdtl_text
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotno      in varchar2,
    in_update_col in varchar2,
    in_text       in varchar2,
    out_msg       out varchar2);

end zreceive;
/

show errors package zreceive;
exit;
