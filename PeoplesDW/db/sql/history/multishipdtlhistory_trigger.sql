create or replace trigger multishipdtlhist_aiu
after insert or update or delete
on multishipdtl
for each row
begin
   if deleting then
	   insert into multishipdtlhistory
		   (whenoccurred, rid, orderid, shipid, cartonid, estweight, actweight, trackid, status,
  		    shipdatetime, carrierused, reason, cost, termid, satdeliveryused, packlistshipdatetime,
  		    length, width, height, dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03,
  		    dtlpassthruchar04, dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07,
  		    dtlpassthruchar08, dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11,
  		    dtlpassthruchar12, dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15,
  		    dtlpassthruchar16, dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19,
  		    dtlpassthruchar20, dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
  		    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08, dtlpassthrunum09,
  		    dtlpassthrunum10, rmatrackingno, actualcarrier, dtlpassthrudate01, dtlpassthrudate02,
  		    dtlpassthrudate03, dtlpassthrudate04, dtlpassthrudoll01, dtlpassthrudoll02, datetimeshipped,
  		    sscc)
	   values
		   (systimestamp, :old.rowid, :old.orderid, :old.shipid, :old.cartonid, :old.estweight, :old.actweight, :old.trackid, :old.status,
  		    :old.shipdatetime, :old.carrierused, :old.reason, :old.cost, :old.termid, :old.satdeliveryused, :old.packlistshipdatetime,
  		    :old.length, :old.width, :old.height, :old.dtlpassthruchar01, :old.dtlpassthruchar02, :old.dtlpassthruchar03,
  		    :old.dtlpassthruchar04, :old.dtlpassthruchar05, :old.dtlpassthruchar06, :old.dtlpassthruchar07,
  		    :old.dtlpassthruchar08, :old.dtlpassthruchar09, :old.dtlpassthruchar10, :old.dtlpassthruchar11,
  		    :old.dtlpassthruchar12, :old.dtlpassthruchar13, :old.dtlpassthruchar14, :old.dtlpassthruchar15,
  		    :old.dtlpassthruchar16, :old.dtlpassthruchar17, :old.dtlpassthruchar18, :old.dtlpassthruchar19,
  		    :old.dtlpassthruchar20, :old.dtlpassthrunum01, :old.dtlpassthrunum02, :old.dtlpassthrunum03, :old.dtlpassthrunum04,
  		    :old.dtlpassthrunum05, :old.dtlpassthrunum06, :old.dtlpassthrunum07, :old.dtlpassthrunum08, :old.dtlpassthrunum09,
  		    :old.dtlpassthrunum10, :old.rmatrackingno, :old.actualcarrier, :old.dtlpassthrudate01, :old.dtlpassthrudate02,
  		    :old.dtlpassthrudate03, :old.dtlpassthrudate04, :old.dtlpassthrudoll01, :old.dtlpassthrudoll02, :old.datetimeshipped,
  		    :old.sscc);
   else
	   insert into multishipdtlhistory
		   (whenoccurred, rid, orderid, shipid, cartonid, estweight, actweight, trackid, status,
  		    shipdatetime, carrierused, reason, cost, termid, satdeliveryused, packlistshipdatetime,
  		    length, width, height, dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03,
  		    dtlpassthruchar04, dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07,
  		    dtlpassthruchar08, dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11,
  		    dtlpassthruchar12, dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15,
  		    dtlpassthruchar16, dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19,
  		    dtlpassthruchar20, dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
  		    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08, dtlpassthrunum09,
  		    dtlpassthrunum10, rmatrackingno, actualcarrier, dtlpassthrudate01, dtlpassthrudate02,
  		    dtlpassthrudate03, dtlpassthrudate04, dtlpassthrudoll01, dtlpassthrudoll02, datetimeshipped,
  		    sscc)
	   values
		   (systimestamp, :new.rowid, :new.orderid, :new.shipid, :new.cartonid, :new.estweight, :new.actweight, :new.trackid, :new.status,
  		    :new.shipdatetime, :new.carrierused, :new.reason, :new.cost, :new.termid, :new.satdeliveryused, :new.packlistshipdatetime,
  		    :new.length, :new.width, :new.height, :new.dtlpassthruchar01, :new.dtlpassthruchar02, :new.dtlpassthruchar03,
  		    :new.dtlpassthruchar04, :new.dtlpassthruchar05, :new.dtlpassthruchar06, :new.dtlpassthruchar07,
  		    :new.dtlpassthruchar08, :new.dtlpassthruchar09, :new.dtlpassthruchar10, :new.dtlpassthruchar11,
  		    :new.dtlpassthruchar12, :new.dtlpassthruchar13, :new.dtlpassthruchar14, :new.dtlpassthruchar15,
  		    :new.dtlpassthruchar16, :new.dtlpassthruchar17, :new.dtlpassthruchar18, :new.dtlpassthruchar19,
  		    :new.dtlpassthruchar20, :new.dtlpassthrunum01, :new.dtlpassthrunum02, :new.dtlpassthrunum03, :new.dtlpassthrunum04,
  		    :new.dtlpassthrunum05, :new.dtlpassthrunum06, :new.dtlpassthrunum07, :new.dtlpassthrunum08, :new.dtlpassthrunum09,
  		    :new.dtlpassthrunum10, :new.rmatrackingno, :new.actualcarrier, :new.dtlpassthrudate01, :new.dtlpassthrudate02,
  		    :new.dtlpassthrudate03, :new.dtlpassthrudate04, :new.dtlpassthrudoll01, :new.dtlpassthrudoll02, :new.datetimeshipped,
  		    :new.sscc);
   end if;
end;
/
show error trigger multishipdtlhist_aiu;

exit;
