--
-- $Id$
--
create or replace package alps.genpicks as
   
procedure pick_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_userid            in varchar2
,in_wave              in number
,in_orderid           in number
,in_shipid            in number
,in_item              in varchar2
,in_lotnumber         in varchar2
,in_qty               in number
,in_taskpriority      in varchar2
,in_picktype          in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure receive_msg
(in_correlation       in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_userid           in out varchar2
,out_wave             in out number
,out_orderid          in out number
,out_shipid           in out number
,out_item             in out varchar2
,out_lotnumber        in out varchar2
,out_qty              in out number
,out_taskpriority     in out varchar2
,out_picktype         in out varchar2
,out_trace            in out varchar2
,out_sid              in out number
,out_errorno          in out number
,out_msg              in out varchar2);

end genpicks;
/
exit;
