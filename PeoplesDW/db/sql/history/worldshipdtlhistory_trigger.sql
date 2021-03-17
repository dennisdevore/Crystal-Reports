create or replace trigger worldshipdtlhist_aiu
after insert or update or delete
on worldshipdtl
for each row
begin
   if deleting then
	   insert into worldshipdtlhistory
		   (whenoccurred, rid, orderid, shipid, cartonid, estweight, actweight, trackid,
		      status, shipdatetime, carrierused, reason, cost, termid, satdeliveryused,
		      packlistshipdatetime, length, width, height, rmatrackingno, actualcarrier,
		      charcost)
	   values
		   (systimestamp, :old.rowid, :old.orderid, :old.shipid, :old.cartonid, :old.estweight, :old.actweight, :old.trackid,
		      :old.status, :old.shipdatetime, :old.carrierused, :old.reason, :old.cost, :old.termid, :old.satdeliveryused,
		      :old.packlistshipdatetime, :old.length, :old.width, :old.height, :old.rmatrackingno, :old.actualcarrier,
		      :old.charcost);
   else
	   insert into worldshipdtlhistory
		   (whenoccurred, rid, orderid, shipid, cartonid, estweight, actweight, trackid,
		      status, shipdatetime, carrierused, reason, cost, termid, satdeliveryused,
		      packlistshipdatetime, length, width, height, rmatrackingno, actualcarrier,
		      charcost)
	   values
		   (systimestamp, :new.rowid, :new.orderid, :new.shipid, :new.cartonid, :new.estweight, :new.actweight, :new.trackid,
		      :new.status, :new.shipdatetime, :new.carrierused, :new.reason, :new.cost, :new.termid, :new.satdeliveryused,
		      :new.packlistshipdatetime, :new.length, :new.width, :new.height, :new.rmatrackingno, :new.actualcarrier,
		      :new.charcost);
   end if;
end;
/
show error trigger worldshipdtlhist_aiu;

exit;
