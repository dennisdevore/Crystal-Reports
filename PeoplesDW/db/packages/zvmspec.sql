--
-- $Id$
--
create or replace package alps.zvicsmsg as

procedure send_vics_bol_request
(in_userid   in varchar2
,in_loadno   in number
,in_orderid  in number
,in_shipid   in number
,in_reqtype  in varchar2
,in_printer  in varchar2
,out_errorno out number
,out_msg     out varchar2
);

procedure get_vics_bol_request
(out_userid           in out varchar2
,out_loadno           in out varchar2
,out_orderid          in out varchar2
,out_shipid           in out varchar2
,out_reqtype          in out varchar2
,out_printer          in out varchar2
,out_errorno          in out varchar2
,out_msg              in out varchar2
);

end zvicsmsg;
/
--exit;
