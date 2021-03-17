create or replace package alps.zimportproc947ia as
--
-- $Id$
--
PROCEDURE debug_msg
(in_text IN varchar2
);

procedure write_msg
(in_msg     in varchar2
,in_msgtype in varchar2);

procedure import_invadj_947_header
(in_importfileid  in varchar2
,in_facility      in varchar2
,in_custid        in varchar2
,in_transdate     in varchar2
,in_transtime     in varchar2
,in_facility_name in varchar2
,in_adjno         in varchar2
,out_errorno      in out number
,out_msg          in out varchar2);

procedure import_invadj_947_details
(in_importfileid  in varchar2
,in_item          in varchar2
,in_adjreason     in varchar2
,in_quantity      in number
,in_uom           in varchar2
,in_facility      in varchar2
,in_custid        in varchar2
,in_adjno         in varchar2
,in_invstatus     in varchar2
,out_errorno      in out number
,out_msg          in out varchar2);

procedure end_of_import_invadj_947
(in_importfileid  in varchar2
,out_errorno      in out number
,out_msg          in out varchar2);

procedure adjust_inventory_status
(in_lpid            in varchar2
,in_quantity        in number
,in_uom             in varchar2
,in_invstatus       in varchar2
,in_adjreason       in varchar2
,in_newlocid        in varchar2
,in_user            in varchar2
,out_newlpid        in out varchar2
,out_adjrowid1      in out varchar2
,out_adjrowid2      in out varchar2
,out_controlnumber  in out varchar2
,out_errorno        in out number
,out_msg            in out varchar2);

procedure adjust_inventory_quantity
(in_lpid          in varchar2
,in_quantity      in number
,in_uom           in varchar2
,in_invstatus     in varchar2
,in_adjreason     in varchar2
,out_adjrowid1    in out varchar2
,out_adjrowid2    in out varchar2
,out_errorno      in out number
,out_msg          in out varchar2);

end zimportproc947ia;
/

show errors package zimportproc947ia
exit;
