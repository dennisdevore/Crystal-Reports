--
-- $Id: add_billingmethod_tariff.sql $
--
insert into billingmethod (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
	values('PLCB','Pallet Count Break','PltCnt Break','N','ZETHCON',SYSDATE);
  
insert into billingmethod (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
	values('PCBR','Pallet Count Break Receipt','PltCnt Rcpt','N','ZETHCON',SYSDATE);
	
exit;