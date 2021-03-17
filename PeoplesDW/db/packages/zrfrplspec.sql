--
-- $Id$
--
create or replace package alps.rfreplenishment as

procedure pick_a_repl
   (in_taskid        in number,
    in_user          in varchar2,
    in_plannedlp     in varchar2,
    in_pickedlp      in varchar2,
    in_custid        in varchar2,
    in_item          in varchar2,
    in_qty           in number,
    in_pickfac       in varchar2,
    in_pickloc       in varchar2,
    in_uom           in varchar2,
    in_picktype      in varchar2,
    in_dropseq       in number,
    in_pickqty       in number,
    in_picked_child  in varchar2,
    in_subtask_rowid in varchar2,
    in_picked_to_lp  in varchar2,
    out_lpcount      out number,
    out_error        out varchar2,
    out_message      out varchar2);

procedure drop_a_repl
   (in_taskid    in number,
    in_facility  in varchar2,
    in_drop_loc  in varchar2,
    in_user      in varchar2,
    out_message  out varchar2);

procedure purge_item_repls
   (in_facility   in varchar2,
    in_location   in varchar2,
    in_lpid       in varchar2,
    in_user       in varchar2,
    out_overpurge out varchar2,
    out_message   out varchar2);

end rfreplenishment;
/

exit;
