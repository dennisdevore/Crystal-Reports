create or replace package body alps.zdebug as
--
-- $Id$
--


-- Public procedures


procedure dump_msg
   (in_msg  in varchar2,
    in_file in varchar2)
is
   l_out utl_file.file_type;
begin
   l_out := utl_file.fopen('UTL_DIR',in_file,'a',32000);
   utl_file.put_line(l_out, in_msg);
   utl_file.fclose(l_out);

exception
	when OTHERS then
   	null;
end dump_msg;


end zdebug;
/

show errors package body zdebug;
exit;
