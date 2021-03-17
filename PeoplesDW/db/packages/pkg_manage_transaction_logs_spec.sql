--
-- $Id$
--
create or replace package pkg_manage_transaction_logs is
                        
procedure usp_insert_log(  
  nameid VARCHAR2,
  event VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

end pkg_manage_transaction_logs;
/
exit;