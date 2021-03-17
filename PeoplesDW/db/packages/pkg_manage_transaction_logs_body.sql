create or replace package body pkg_manage_transaction_logs as
--
-- $Id$
--
                        
procedure usp_insert_log(  
  nameid VARCHAR2,
  event VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is

begin

  insert into tbl_transaction_logs(nameid, event)
         values(nameid, event);
         
  return_status := 1;
  return_msg := 'OKAY';       
              
  exception when others then
     return_status := 0;
     return_msg := sqlerrm;       

end usp_insert_log;

end pkg_manage_transaction_logs;
/
exit;
