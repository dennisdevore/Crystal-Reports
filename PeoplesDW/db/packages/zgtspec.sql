--
-- $Id$
--
create or replace package alps.gentasks as

procedure move_request
(in_facility          in varchar2
,in_lpid              in varchar2
,in_taskpriority      in varchar2
,in_destloc           in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2
,in_type              in varchar2 := 'MV'
);

procedure pick_by_lip_request
(in_facility          in varchar2
,in_lpid              in varchar2
,in_taskpriority      in varchar2
,in_stageloc          in varchar2
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

end gentasks;
/
exit;
