--
-- $Id$
--
create or replace package alps.zcrossdock
as

procedure build_xdock_outbound
   (in_orderid  in number,
    in_shipid   in number,
    in_shipto   in varchar2,
    in_userid   in varchar2,
    out_orderid out number,
    out_shipid  out number,
    io_msg      in out varchar2);

procedure add_xdock_plate
   (in_lpid   in varchar2,
    in_asn    in varchar2,
    in_userid in varchar2,
    in_loc    in varchar2,
    out_err   out varchar2,
    out_msg   out varchar2);

procedure update_xdock_plate
   (in_lpid   in varchar2,
    in_userid in varchar2,
    out_msg   out varchar2);

procedure check_for_active_crossdock
   (in_lpid   in varchar2,
    out_dest  out varchar2,
    out_msg   out varchar2);

end zcrossdock;
/

exit;
