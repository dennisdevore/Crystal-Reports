--
-- $Id$
--
create or replace package alps.zdebug as

-- depends upon oracle directory UTL_DIR
procedure dump_msg
   (in_msg  in varchar2,
    in_file in varchar2 default 'dumper');

end zdebug;
/

show errors package body zdebug;
exit;
