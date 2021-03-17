set serveroutput on;
set heading off;
set pagesize 0;
set linesize 32000;
set trimspool on;
spool change_item_code.out;

declare
l_cnt pls_integer;
l_adjreason invadjactivity.adjreason%type := 'PC';
l_userid userheader.nameid%type := 'ITEMCHG';
out_errorno number;
out_msg varchar2(255);

procedure change_item(
in_custid varchar2,
in_old_item varchar2,
in_new_item varchar2
)
is

begin

zim14.change_item_code(
in_custid,
in_old_item,
in_new_item,
l_adjreason,
'IA', -- tasktype
'SAP Item Conversion', -- custreference
l_userid,
'N',
out_errorno,
out_msg
);

zut.prt('iaj : ' || out_msg);

if out_errorno = 0 then
  commit;
else
  rollback;
end if;

exception when others then 
  zut.prt('ci ex ' || sqlerrm);
end change_item;

begin

change_item('CAR013','57808','100087291');
change_item('CAR013','64151','100087403');
change_item('CAR013','66080','100087488');
change_item('CAR013','67701','100087552');
change_item('CAR013','68385','100087553');
change_item('CAR013','68553','100087915');
change_item('CAR013','68554','100087560');
change_item('CAR013','68555','100087881');
change_item('CAR013','69622','100087688');
change_item('CAR013','69631','100087894');
change_item('CAR013','70353','100087689');
change_item('CAR013','70455','100087151');
change_item('CAR013','70454','100087896');
change_item('CAR013','70458','100087979');
change_item('CAR013','70452','100087149');
change_item('CAR013','60436','100087300');
change_item('CAR013','70246','100087793');

change_item('CAR010','63419','100087370');
change_item('CAR010','63884','100087382');
change_item('CAR010','63886','100087383');
change_item('CAR010','63898','100087384');
change_item('CAR010','64587','100087420');
change_item('CAR010','66382','100087502');
change_item('CAR010','66767','100087332');
change_item('CAR010','67187','100087526');  -- no new item
change_item('CAR010','68604','100087616');
change_item('CAR010','69054','100087665');
change_item('CAR010','69056','100087667');
change_item('CAR010','69058','100087669');
change_item('CAR010','69064','100087673');
change_item('CAR010','69143','100087678');
change_item('CAR010','69175','100087779');
change_item('CAR010','69318','100087696');
change_item('CAR010','69322','100087697');
change_item('CAR010','69325','100087699');
change_item('CAR010','69343','100087701');
change_item('CAR010','69438','100087709');
change_item('CAR010','69440','100087710');
change_item('CAR010','69607','100087719');
change_item('CAR010','69609','100087720');
change_item('CAR010','69611','100087721');
change_item('CAR010','70105','100087748');
change_item('CAR010','70221','100087749');
change_item('CAR010','70246','100087793');
change_item('CAR010','70248','100087767');
change_item('CAR010','70251','100087768');
change_item('CAR010','70273','100087770');
change_item('CAR010','70275','100087771');
change_item('CAR010','70503','100087791');
change_item('CAR010','70610','100087722');
change_item('CAR010','70786','100087711');
change_item('CAR010','70800','100087827');
change_item('CAR010','71041','100103729');

exception when others then
  zut.prt('ex others ' || sqlerrm);
  zut.prt('others...');
end;
/
exit;
