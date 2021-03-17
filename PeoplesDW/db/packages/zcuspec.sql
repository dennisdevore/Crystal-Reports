--
-- $Id$
--
create or replace PACKAGE alps.zcustomer
IS

FUNCTION lot_label
(in_custid IN varchar2
) return varchar2;

FUNCTION item_label
(in_custid IN varchar2
) return varchar2;

FUNCTION po_label
(in_custid IN varchar2
) return varchar2;

FUNCTION equiv_uom_qty
(in_custid IN varchar2
,in_item varchar2
,in_fromuom varchar2
,in_qty number
,in_touom varchar2
) return number;

procedure pack_list_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
);

procedure master_pack_list_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
);

function bol_rpt_format
(in_orderid in number
,in_shipid in number
) return varchar2;
function bol_rpt_fullpath
(in_orderid in number
,in_shipid in number
) return varchar2;
function mbol_rpt_format
(in_orderid in number
,in_shipid in number
) return varchar2;
FUNCTION next_uom
(in_custid varchar2
,in_item varchar2
,in_fromuom varchar2
,in_next_count number
) return varchar2;

procedure pack_list_audit_format
(in_orderid in number
,in_shipid in number
,out_format in out varchar2
);

FUNCTION credit_hold
(in_custid IN varchar2
) return varchar2;

procedure order_check_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
);
procedure small_pkg_email_pack_list_fmt
(in_custid in varchar2
,out_format in out varchar2
,out_email_addresses in out varchar2
);
PRAGMA RESTRICT_REFERENCES (lot_label, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (item_label, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (po_label, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (equiv_uom_qty, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (next_uom, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (credit_hold, WNDS, WNPS, RNPS);

END zcustomer;
/
show errors package zcustomer;
exit;
