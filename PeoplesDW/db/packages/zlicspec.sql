--
-- $Id$
--
create or replace package alps.zlicense as

procedure logon
   (in_user     in varchar2,
    in_facility in varchar2,
    in_origin   in varchar2,
    out_msgno   out number,
    out_msg     out varchar2);

procedure logoff
   (in_user     in varchar2,
    in_facility in varchar2,
    in_origin   in varchar2,
    out_msgno   out number,
    out_msg     out varchar2);

procedure switchfacility
   (in_user        in varchar2,
    in_facility    in varchar2,
    in_origin      in varchar2,
    in_newfacility in varchar2,
    out_msgno      out number,
    out_msg        out varchar2);

end zlicense;
/

exit;
