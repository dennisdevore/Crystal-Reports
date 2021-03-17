--
-- $Id: zoospec.sql 8653 2012-07-12 20:37:40Z eric $
--
create or replace package alps.zoperationaloverview as

OO_ITEM_LIMIT           constant       integer := 14;
OODAILY_DEFAULT_QUEUE   CONSTANT       varchar2(7) := 'oodaily';

procedure pctfull
   (in_facilities in varchar2,
    out_pctfull   out number,
    out_message   out varchar2);

procedure closereceipt
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_units     in number);

procedure inboundactivity
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_hours     in number);

procedure shiporder
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_units     in number);

procedure outboundactivity
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_hours     in number);

procedure addrevenue
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_invtype   in varchar2,
    in_amount    in number);

procedure closeload
   (in_facility  in varchar2,
    in_loadno    in number,
    in_loadtype  in varchar2);

procedure gettotals
   (in_facilities          in varchar2,
    in_custids             in varchar2,
    in_timeframe           in varchar2,
    out_message            out varchar2,
    out_closedreceipts     out number,
    out_closedloads        out number,
    out_inboundunits       out number,
    out_inboundhours       out number,
    out_ordersshipped      out number,
    out_loadsshipped       out number,
    out_outboundunits      out number,
    out_outboundhours      out number,
    out_receiptrevenue     out number,
    out_renewalrevenue     out number,
    out_accessorialrevenue out number,
    out_miscrevenue        out number,
    out_creditrevenue      out number);

procedure getaverage
   (in_facilities          in varchar2,
    in_custids             in varchar2,
    in_timeframe           in varchar2,
    in_avg_months          in number,
    out_message            out varchar2,
    out_closedreceipts     out number,
    out_closedloads        out number,
    out_inboundunits       out number,
    out_inboundhours       out number,
    out_ordersshipped      out number,
    out_loadsshipped       out number,
    out_outboundunits      out number,
    out_outboundhours      out number,
    out_receiptrevenue     out number,
    out_renewalrevenue     out number,
    out_accessorialrevenue out number,
    out_miscrevenue        out number,
    out_creditrevenue      out number);

procedure getothercounts
   (in_facilities         in varchar2,
    in_customers          in varchar2,
    out_ob_unshipped      out number,
    out_ob_active         out number,
    out_ib_active         out number,
    out_ob_shipped_late   out number);
	
procedure update_oodailytotals
  (in_capturedate        in date,
   in_facility           in varchar2,
   in_custid             in varchar2,
   in_closedreceipts     in number,
   in_inboundunits       in number,
   in_inboundhours       in number,
   in_ordersshipped      in number,
   in_outboundunits      in number,
   in_outboundhours      in number,
   in_receiptrevenue     in number,
   in_renewalrevenue     in number,
   in_accessorialrevenue in number,
   in_miscrevenue        in number,
   in_creditrevenue      in number);

end zoperationaloverview;
/

exit;
