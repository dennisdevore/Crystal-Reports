--
-- $Id$
--
create or replace package alps.zaiconversion as


procedure start_conversion
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure convert_detail
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_location  in varchar2,
    in_item      in varchar2,
    in_lotno     in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_created   in varchar2,
    in_invclass  in varchar2,
    in_invstatus in varchar2,
    in_lpcnt     in number,
    in_lpqty     in number,
    in_lpid      in varchar2,
    in_totqty    in number,
    in_adjust    in varchar2,
    in_user      in varchar2,
    out_error    out varchar2,
    out_msgno    out number,
    out_message  out varchar2);


end zaiconversion;
/

exit;
