--
-- $Id$
--
set serveroutput on;

declare

prmOrderid int;
prmShipid int;

begin

  prmOrderId := &&1;
  prmShipid := 1;

  update orderhdr
     set qtyship = qtypick,
         weightship = weightpick,
         cubeship = cubepick,
         amtship = amtpick,
         orderstatus = '9',
         dateshipped = sysdate,
         lastuser = 'ZADJ',
         lastupdate = sysdate
   where orderid =  prmOrderId
     and shipid = prmShipId
     and orderstatus <= '7';

  if sql%rowcount = 1 then
    zut.prt('order updated');
  else
    zut.prt('no order update');
  end if;
  
  delete from commitments
   where orderid = prmOrderId
     and shipid = prmShipId;


end;
/
--exit;
