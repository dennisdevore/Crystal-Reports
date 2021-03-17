create or replace trigger tasks_aiu
after insert or update or delete
on tasks
for each row
begin
   if deleting then
	   insert into taskhistory
		   (whenoccurred, taskid, tasktype, facility, fromsection,
		    fromloc, fromprofile, tosection, toloc, toprofile,
          touserid, custid, item, lpid, uom,
          qty, locseq, loadno, stopno, shipno,
          orderid, shipid, orderitem, orderlot, priority,
          prevpriority, curruserid, lastuser, lastupdate, pickuom,
          pickqty, picktotype, wave, pickingzone, cartontype,
          weight, cube, staffhrs, cartonseq, clusterposition,
          convpickloc, step1_complete)
	   values
		   (systimestamp, :old.taskid, :old.tasktype, :old.facility, :old.fromsection,
		    :old.fromloc, :old.fromprofile, '(Delete)', :old.toloc, :old.toprofile,
          :old.touserid, :old.custid, :old.item, :old.lpid, :old.uom,
          :old.qty, :old.locseq, :old.loadno, :old.stopno, :old.shipno,
          :old.orderid, :old.shipid, :old.orderitem, :old.orderlot, :old.priority,
          :old.prevpriority, :old.curruserid, :old.lastuser, :old.lastupdate, :old.pickuom,
          :old.pickqty, :old.picktotype, :old.wave, :old.pickingzone, :old.cartontype,
          :old.weight, :old.cube, :old.staffhrs, :old.cartonseq, :old.clusterposition,
          :old.convpickloc, :old.step1_complete);
   else
	   insert into taskhistory
		   (whenoccurred, taskid, tasktype, facility, fromsection,
		    fromloc, fromprofile, tosection, toloc, toprofile,
          touserid, custid, item, lpid, uom,
          qty, locseq, loadno, stopno, shipno,
          orderid, shipid, orderitem, orderlot, priority,
          prevpriority, curruserid, lastuser, lastupdate, pickuom,
          pickqty, picktotype, wave, pickingzone, cartontype,
          weight, cube, staffhrs, cartonseq, clusterposition,
          convpickloc, step1_complete)
	   values
		   (systimestamp, :new.taskid, :new.tasktype, :new.facility, :new.fromsection,
		    :new.fromloc, :new.fromprofile, :new.tosection, :new.toloc, :new.toprofile,
          :new.touserid, :new.custid, :new.item, :new.lpid, :new.uom,
          :new.qty, :new.locseq, :new.loadno, :new.stopno, :new.shipno,
          :new.orderid, :new.shipid, :new.orderitem, :new.orderlot, :new.priority,
          :new.prevpriority, :new.curruserid, :new.lastuser, :new.lastupdate, :new.pickuom,
          :new.pickqty, :new.picktotype, :new.wave, :new.pickingzone, :new.cartontype,
          :new.weight, :new.cube, :new.staffhrs, :new.cartonseq, :new.clusterposition,
          :new.convpickloc, :new.step1_complete);
   end if;
end;
/
show error trigger tasks_aiu;

exit;
