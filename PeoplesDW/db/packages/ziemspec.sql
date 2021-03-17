create or replace package alps.impexpmsg as

--
-- $Id$
--

IE_DEFAULT_QUEUE       CONSTANT        varchar2(3) := 'ieq';

procedure impexp_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_when              in varchar2
,in_loadno            in number
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_tablename         in varchar2
,in_columnname        in varchar2
,in_filtercolumnname  in varchar2
,in_company           in varchar2
,in_warehouse         in varchar2
,in_begindatetimestr  in varchar2
,in_enddatetimestr    in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure impexp_request_queue
(in_queuename         in varchar2
,in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_when              in varchar2
,in_loadno            in number
,in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_tablename         in varchar2
,in_columnname        in varchar2
,in_filtercolumnname  in varchar2
,in_company           in varchar2
,in_warehouse         in varchar2
,in_begindatetimestr  in varchar2
,in_enddatetimestr    in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure impexp_receive_msg
(in_queuename         in varchar2
,in_instance          in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_custid           in out varchar2
,out_formatid         in out varchar2
,out_filepath         in out varchar2
,out_when             in out varchar2
,out_loadno           in out  number
,out_orderid          in out  number
,out_shipid           in out  number
,out_userid           in out varchar2
,out_tablename        in out varchar2
,out_columnname       in out varchar2
,out_filtercolumnname in out varchar2
,out_company          in out varchar2
,out_warehouse        in out varchar2
,out_begindatetimestr in out varchar2
,out_enddatetimestr   in out varchar2
,out_logseq           in out number
,out_errorno          in out number
,out_msg              in out varchar2);

procedure update_impexp_log_start
(in_logseq            in number
,in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure impexp_log_manual_import
(in_logseq            in number
,in_instance          in varchar2
,in_formatid          in varchar2
,in_filepath          in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure update_impexp_log_finish
(in_logseq            in number
,out_errorno          in out number
,out_msg              in out varchar2);

procedure insert_impexp_log_detail
(in_logseq            in number
,in_logtext           in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure rerequest_impexp_log
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

FUNCTION find_queue(in_facility varchar2, in_custid varchar2)
return varchar2;

procedure resequence_impexp_chunkinc
(in_definc            in number
,in_lineinc           in number
,out_errorno          out number
,out_msg              out varchar2);

procedure add_instance
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);

procedure delete_instance
(in_instance          in varchar2
,out_errorno          in out number
,out_msg              in out varchar2);
end impexpmsg;
/
exit;
