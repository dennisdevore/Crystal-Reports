alter table billparentpltcnt drop constraint pk_billparentpltcnt;
alter table billparentpltcnt add constraint 
pk_billparentpltcnt primary key(facility,custid,effdate,lpid);
exit;
