--
-- $Id$
--
create or replace package alps.zbuildmap as

procedure build_map(in_facility in varchar2,
                    in_userid   in varchar2,
                    out_msg     in out varchar2);

end zbuildmap;
/

exit;
