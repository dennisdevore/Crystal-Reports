--
-- $Id$
--
create or replace package alps.zrecorder
as

procedure receive_item
	 (in_facility     in  varchar2,
    in_orderid      in  number,
    in_shipid       in  number,
    in_custid       in  varchar2,
    in_po		        in  varchar2,
    in_reference    in  varchar2,
    in_billoflading in  varchar2,
    in_shipper	    in  varchar2,
    in_carrier		  in  varchar2,
    in_trailer		  in  varchar2,
    in_seal		      in  varchar2,
    in_doorloc		  in  varchar2,
    in_receiptdate  in  date,
    in_itementered  in  varchar2,
    in_item         in  varchar2,
    in_lot          in  varchar2,
    in_qty          in  number,
    in_uom          in  varchar2,
    in_location     in  varchar2,
    in_invstatus    in  varchar2,
    in_invclass     in  varchar2,
    in_handtype     in  varchar2,
    in_serial       in  varchar2,
    in_useritem1    in  varchar2,
    in_useritem2    in  varchar2,
    in_useritem3    in  varchar2,
    in_countryof    in  varchar2,
    in_expdate      in  date,
    in_mfgdate      in  date,
    in_user         in  varchar2,
    in_weight       in  number,
    in_nosetemp     in  number,
    in_middletemp   in  number,
    in_tailtemp     in  number,
    out_orderid	    out number,
    out_loadno		  out number,
    out_errmsg      out varchar2);

procedure close_receipt
	(in_facility in  varchar2,
    in_loadno   in  number,
    in_user     in  varchar2,
    in_receiptdate  in  date,
    out_errmsg  out varchar2);

end zrecorder;
/

exit;
