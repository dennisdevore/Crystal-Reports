--
-- $Id: alter_tbl_custconsignee03.sql 981 2006-07-02 00:09:25Z brianb $
--

/*
alter table custconsignee drop
(
export_format2,
export_format3,
generate_format2,
generate_format3
);
*/
alter table custconsignee add
(
generate_945       char(1),
export_format945   varchar2(35),
generate_810       char(1),
export_format810   varchar2(35)
);

set serveroutput on;
set flush on;

declare
cntRows integer;

begin

cntRows := 0;

update custconsignee
   set generate_945 = 'N'
   where generate_945 is null;

update custconsignee
   set generate_810 = 'N'
   where generate_810 is null;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
