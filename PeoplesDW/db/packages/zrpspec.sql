--
-- $Id$
--
create or replace package alps.replenish as

procedure send_replenish_msg
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure send_replenish_msg_no_commit
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure recv_replenish_msg
(in_correlation       in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_custid           in out varchar2
,out_item             in out varchar2
,out_locid            in out varchar2
,out_userid           in out varchar2
,out_trace            in out varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

end replenish;
/
exit;
