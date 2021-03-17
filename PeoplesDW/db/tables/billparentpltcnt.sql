create table billparentpltcnt (
  facility varchar2(3) not null,
  custid varchar2(10) not null,
  effdate date not null,
  lpid varchar2(15) not null,
  parentlpid varchar2(15),
  item varchar2(50),
  lotnumber varchar2(30),
  lastuser varchar2(12),
  lastupdate date,
  primary key (facility, custid, effdate, lpid)
);
create index bppc_parentlpid_idx on billparentpltcnt(nvl(parentlpid,lpid), effdate);

exit;
/
