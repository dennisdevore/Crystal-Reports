--
-- $Id$
--
create or replace package alps.rfbldpallet as


-- constants


OP_INSERT    CONSTANT   integer := 0;
OP_UPDATE    CONSTANT   integer := 1;
OP_ATTACH    CONSTANT   integer := 2;
OP_MIX       CONSTANT   integer := 3;
OP_MULTI     CONSTANT   integer := 4;
OP_UNDELMP   CONSTANT   integer := 5;


-- Public procedures


procedure dupe_lp
   (in_fromlpid    in varchar2,
    in_tolpid      in varchar2,
    in_location    in varchar2,
    in_status      in varchar2,
    in_quantity    in number,
    in_user        in varchar2,
    in_disposition in varchar2,
    in_lasttask    in varchar2,
    in_taskid      in number,
    out_message    out varchar2);

procedure bld_pallet
   (in_tolpid      in varchar2,
    in_location    in varchar2,
    in_disposition in varchar2,
    in_bldop       in varchar2,
    in_fromid      in varchar2,
    in_fromtype    in varchar2,
    in_quantity    in number,
    in_uom         in varchar2,
    in_custid      in varchar2,
    in_id          in varchar2,
    in_id_is_lp    in varchar2,
    in_lotnumber   in varchar2,
    in_user        in varchar2,
    in_facility    in varchar2,
    in_invstatus   in varchar2,
    in_invclass    in varchar2,
    out_error      out varchar2,
    out_message    out varchar2);

end rfbldpallet;
/

exit;
