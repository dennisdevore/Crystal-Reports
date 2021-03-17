create or replace trigger orderhdrbolcomments_au
--
-- $Id: orderhdrbolcomments_trigger.sql 3210 2008-12-02 20:27:13Z eric $
--
after update
on orderhdrbolcomments
for each row
begin

if nvl(:old.bolcomment,'x') != nvl(:new.bolcomment,'x') then
    insert into orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    values
      (sysdate, :new.orderid, :new.shipid, :new.lastuser,
           'CHANGE',
            'Bolcomment was: '|| chr(13) || chr(10) ||
            nvl(substr(:old.bolcomment,1,500),'(null)'));
end if;
end;
/
show error trigger orderhdrbolcomments_au;

exit;

