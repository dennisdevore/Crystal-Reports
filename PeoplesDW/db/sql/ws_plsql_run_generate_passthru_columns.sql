set serveroutput on;
declare
out_msg varchar2(1000);

begin
  ws_utility.generate_passthru_column_defs(out_msg);

  dbms_output.put_line(out_msg);

end;
/

exit;
