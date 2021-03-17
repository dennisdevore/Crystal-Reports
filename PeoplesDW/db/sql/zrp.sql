--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);


begin

out_msg := '';
out_errorno := 0;

zrpl.process_replenish_request(
'REPLPF', -- request type
'A',     -- facility
'CCC',   -- custid
'KEYBOARD',  -- item
'PF04', -- locid
'ZBRIAN', -- userid
'Y', -- trace
out_errorno, -- 0-good;others-bad
out_msg); -- error message

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || out_msg);

end;
/
--exit;
