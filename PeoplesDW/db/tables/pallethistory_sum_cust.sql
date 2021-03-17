--
-- $Id: pallethistory_sum_cust.sql 1 2005-05-26 12:20:03Z ed $
--
create table pallethistory_sum_cust (
  custid      varchar2 (10)  not null,
  facility    varchar2 (3)  not null,
  pallettype  varchar2 (12)  not null,
  trunc_lastupdate  date not null,
  inpallets   number (7),
  outpallets  number (7)
);

create unique index pallethistory_sum_cust_idx
on pallethistory_sum_cust
(custid,facility,pallettype,trunc_lastupdate);

exit;
