--
-- $Id$
--
alter table qcresult add (
  custid    varchar2(10),
  item varchar2(50),
  lotnumber varchar2(30));

-- exit;