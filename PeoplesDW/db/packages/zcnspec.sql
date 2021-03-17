--
-- $Id$
--
create or replace package alps.cn as

procedure get_next_controlnumber(out_controlnumber    out varchar2,
                                out_message out varchar2);

end cn;
/

exit;
