--
-- $Id$
--
create or replace package alps.zorderchk as


-- constants


OP_INSERT    CONSTANT   integer := 0;
OP_UPDATE    CONSTANT   integer := 1;
OP_DELETE    CONSTANT   integer := 2;


-- Public procedures


procedure check_order
	(in_orderid  in number,
	 in_shipid   in number,
	 in_custid   in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2);

procedure check_plate
	(in_lpid     in varchar2,
    in_facility in varchar2,
	 in_location in varchar2,
	 in_orderid  in number,
	 in_shipid   in number,
    in_custid   in varchar2,
	 in_item     in varchar2,
    in_lotno    in varchar2,
	 in_qty      in number,
	 in_uom      in varchar2,
    in_user     in varchar2,
	 in_opcode	 in number,
    out_error   out varchar2,
    out_message out varchar2);
procedure order_check_required (
  in_orderid in number,
  in_shipid in number,
  out_message out varchar2
);

end zorderchk;
/

exit;

