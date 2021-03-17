--
-- $Id$
--
create or replace package alps.depicking
as

procedure adjust_order_and_load
   (in_orderid    in number,
    in_shipid     in number,
    in_facility   in varchar2,
    in_user       in varchar2,
    in_depick     in varchar2,
    out_message   out varchar2);

procedure depick_lp
   (in_spid        in varchar2,
    in_location    in varchar2,
    in_lpid        in varchar2,
    in_user        in varchar2,
    out_error      out varchar2,
    out_message    out varchar2);

procedure depick_multi
   (in_lpid     in varchar2,
    in_location in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure del_pick_subtask
   (in_rowid    in rowid,
    in_user     in varchar2,
    out_message out varchar2);

procedure purge_cxld_pick_task
   (in_taskid   in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure purge_cxld_pick_subtask
   (in_subtask_rowid in varchar2,
    in_user          in varchar2,
    out_results      out varchar2,     -- 'N' => nothing deleted and no errors
                                       -- 'E' => error occurred (see out_message)
                                       -- 'S' => subtask deleted
                                       -- 'T' => task (along with subtask) deleted
    out_message      out varchar2);

procedure depick_item
   (in_orderid      in number,
    in_shipid       in number,
    in_fromlpid     in varchar2,
    in_fromistote   in varchar2,
    in_custid       in varchar2,
    in_item         in varchar2,
    in_lotnumber    in varchar2,
    in_dpkqty       in number,
    in_dpkuom       in varchar2,
    in_baseuom		  in varchar2,
    in_serialnumber in varchar2,
    in_useritem1    in varchar2,
    in_useritem2    in varchar2,
    in_useritem3    in varchar2,
    in_toloc        in varchar2,
    in_tolpid       in varchar2,
    in_user         in varchar2,
    out_error       out varchar2,
    out_message     out varchar2);

procedure depick_qty_from_shipplate
	(in_lpid         in varchar2,
	 in_qty		     in number,
    in_uom          in varchar2,
    in_location     in varchar2,
    in_user         in varchar2,
    out_errmsg  	  out varchar2);

end depicking;
/

exit;
