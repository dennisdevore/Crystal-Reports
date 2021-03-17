--
-- $Id$
--
create or replace package alps.zconsorder
as

function cons_orderid
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;							-- consolidated orderid (wave)
pragma restrict_references (cons_orderid, wnds, wnps, rnps);

function cons_shiptype
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_shiptype, wnds, wnps, rnps);

function cons_carrier
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_carrier, wnds, wnps, rnps);

function cons_ordertype
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_ordertype, wnds, wnps, rnps);

function cons_componenttemplate
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_componenttemplate, wnds, wnps, rnps);

function cons_multiship
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_multiship, wnds, wnps, rnps);

function cons_orderstatus
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_orderstatus, wnds, wnps, rnps);

function cons_workorderseq
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_workorderseq, wnds, wnps, rnps);

function cons_loadno
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_loadno, wnds, wnps, rnps);

function cons_stopno
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_stopno, wnds, wnps, rnps);

function cons_shipno
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_shipno, wnds, wnps, rnps);

function cons_invstatus
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2;
pragma restrict_references (cons_invstatus, wnds, wnps, rnps);

function cons_invstatusind
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2;
pragma restrict_references (cons_invstatusind, wnds, wnps, rnps);

function cons_inventoryclass
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2;
pragma restrict_references (cons_inventoryclass, wnds, wnps, rnps);

function cons_invclassind
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2;
pragma restrict_references (cons_invclassind, wnds, wnps, rnps);

function cons_custid
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_custid, wnds, wnps, rnps);

function cons_fromfacility
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_fromfacility, wnds, wnps, rnps);

function cons_qtycommit
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_qtycommit, wnds, wnps, rnps);

function cons_qty2check
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_qty2check, wnds, wnps, rnps);

function cons_shipto
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_shipto, wnds, wnps, rnps);

function cons_consignee
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_consignee, wnds, wnps, rnps);

function cons_any_hdr_rfautodisplay
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_any_hdr_rfautodisplay, wnds, wnps, rnps);

function cons_any_dtl_rfautodisplay
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2;
pragma restrict_references (cons_any_dtl_rfautodisplay, wnds, wnps, rnps);

function cons_hdr_comments_len
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;
pragma restrict_references (cons_hdr_comments_len, wnds, wnps, rnps);

function cons_dtl_comments_len
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number,			-- shipid or 0 wave
    in_item     in varchar2,
    in_lotno    in varchar2)
return number;
pragma restrict_references (cons_dtl_comments_len, wnds, wnps, rnps);

procedure cons_plate_pick
   (in_taskid          in number,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
	 in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_orderid         in number,
    in_shipid          in number,
    in_qty             in number,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_extra_process   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2);

function cons_shipped
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return number;			            -- 0 Not Cons Shipped, 1 Cons All Shipped

procedure cons_dec_batchtasks
   (in_taskid    in number,
    in_custid    in varchar2,
	 in_orderitem in varchar2,
    in_lotno     in varchar2,
    in_item      in varchar2,
    in_plannedlp in varchar2,
    in_fromloc   in varchar2,
    in_qty       in number,
    out_message  out varchar2);

function cons_manual_picks
	(in_orderid  in number,			-- orderid or wave
	 in_shipid   in number)			-- shipid or 0 wave
return varchar2;
pragma restrict_references (cons_manual_picks, wnds, wnps, rnps);

end zconsorder;
/

exit;
