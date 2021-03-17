--
-- $Id$
--
set serveroutput on;

declare
out_abbrev varchar2(12);
out_descr varchar2(32);
out_whse varchar2(12);
out_regular_whse varchar2(12);
out_returns_whse varchar2(12);

begin

zut.prt('begin get_cust_parm_value');

zmi3.get_cust_parm_value('HP','UNSTATUS',out_descr,out_abbrev);

zut.prt('out_abbrev is >' || out_abbrev || '<');
zut.prt('out_descr is >' || out_descr || '<');

zut.prt('end get_cust_parm_value');

zut.prt('begin get_whse');

zmi3.get_whse('HP','RG',out_whse,out_regular_whse,out_returns_whse);

zut.prt('out_whse is >' || out_whse || '<');
zut.prt('out_regular_whse is >' || out_regular_whse || '<');
zut.prt('out_returns_whse is >' || out_returns_whse || '<');

zut.prt('end get_whse');

zut.prt('begin get_whse_parm_value');

zmi3.get_whse_parm_value('HP','HPC1','GR-UNRESTRCT',out_descr,out_abbrev);

zut.prt('out_abbrev is >' || out_abbrev || '<');
zut.prt('out_descr is >' || out_descr || '<');

zut.prt('end get_whse_parm_value');

exception when others then
  zut.prt('others...');
  zut.prt(sqlerrm);
end;
/
--exit;