--
-- $Id$
--
truncate table pallethistory;

alter table pallethistory add(
carrier varchar2(4) not null,
consignee varchar2(10),
comment1  varchar2(80)
);

-- exit;
