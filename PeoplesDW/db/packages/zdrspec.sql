--
-- $Id: zdrspec.sql 1 2005-05-26 12:20:03Z ed $
--
create or replace package alps.zdirectrelease as

procedure direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_picktype          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure undo_direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure complete_direct_release
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_picktype          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

end zdirectrelease;
/
exit;
