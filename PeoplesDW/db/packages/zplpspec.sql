--
-- $Id$
--
create or replace package alps.parentlp as


procedure build_tote_from_shippingplate
   (in_tlpid    in varchar2,
    in_slpid    in varchar2,
    in_user     in varchar2,
    in_tasktype in varchar2,
    in_taskid   in number,
    in_dropseq  in number,
    in_pickloc  in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure build_batchpick_parentlp
   (in_plpid           in varchar2,
    in_picktotype      in varchar2,
    in_facility        in varchar2,
    in_location        in varchar2,
    in_quantity        in varchar2,
    in_user            in varchar2,
    in_taskid          in number,
    in_dropseq         in number,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_lotno           in varchar2,
    in_fromlpid        in varchar2,
    in_picktype        in varchar2,
    in_pickloc         in varchar2,
    in_uom             in varchar2,
    in_orderitem       in varchar2,
    in_orderlot        in varchar2,
    in_plannedlp       in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    out_error          out varchar2,
    out_message        out varchar2);

procedure clone_lp
   (in_lpid          in varchar2,
    in_location 	   in varchar2,
    in_status        in varchar2,
    in_quantity 	   in number,
    in_weight        in number,
    in_user     	   in varchar2,
    in_tasktype   	in varchar2,
    in_parentlpid 	in varchar2,
    in_taskid        in number,
    in_shippinglpid  in varchar2,
    in_dropseq       in number,
    out_cloneid      out varchar2,
    out_message      out varchar2);

procedure build_empty_parent
   (io_lpid        in out varchar2,
    in_facility    in varchar2,
    in_location    in varchar2,
    in_status      in varchar2,
    in_type        in varchar2,
    in_user        in varchar2,
    in_disposition in varchar2,
	 in_custid 	    in varchar2,
	 in_item		    in varchar2,
	 in_orderid	    in number,
	 in_shipid 	    in number,
	 in_loadno 	    in number,
	 in_stopno 	    in number,
	 in_shipno 	    in number,
    in_lotnumber   in varchar2,
    in_invstatus   in varchar2,
    in_invclass    in varchar2,
    out_message    out varchar2);

procedure attach_child_plate
   (in_parentlpid in varchar2,
    in_childlpid  in varchar2,
    in_location   in varchar2,
    in_status     in varchar2,
    in_user       in varchar2,
    out_message   out varchar2);

procedure morph_lp_to_multi
   (in_lpid     in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure detach_child_plate
   (in_parentlpid   in varchar2,
    in_childlpid    in varchar2,
    in_location     in varchar2,
    in_destfacility in varchar2,
    in_destlocation in varchar2,
    in_status       in varchar2,
    in_user         in varchar2,
    in_tasktype     in varchar2,
    out_message     out varchar2);

procedure decrease_parent
   (in_parentlpid in varchar2,
    in_quantity   in number,
    in_weight     in varchar2,
    in_user       in varchar2,
    in_tasktype   in varchar2,
    out_message   out varchar2);

procedure balance_master
   (in_lpid     in varchar2,
    in_tasktype in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure build_mass_manifest
   (in_lpid     in varchar2,
    in_taskid   in number,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

function type_pa_lpid
   (in_lpid   in varchar2,
    in_custid in varchar2,
    in_item   in varchar2,
    in_lotno  in varchar2)
return varchar2;


end parentlp;
/

exit;
