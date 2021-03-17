--
-- $Id$
--
create or replace package alps.ztaskutilities as

procedure get_next_taskid(out_taskid  out number,
                          out_message out varchar2);

end ztaskutilities;
/

exit;
