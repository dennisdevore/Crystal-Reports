--
-- $Id$
--
create or replace package zlbprt as


procedure print_load_flags
	(in_printno  in number,
    in_profid	 in varchar2,
	 in_event    in varchar2,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure print_carton_labels
	(in_printno  in number,
	 in_event    in varchar2,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure get_lpid_profid
   (in_event	  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_consignee in varchar2,
    in_lpid      in varchar2,
    out_uom      out varchar2,
    out_profid   out varchar2);

end zlbprt;
/

exit;
