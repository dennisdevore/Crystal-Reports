--
-- $Id$
--
truncate table palletinventory;

alter table palletinventory add(
carrier varchar2(4),
consignee varchar2(10)
);

-- exit;
