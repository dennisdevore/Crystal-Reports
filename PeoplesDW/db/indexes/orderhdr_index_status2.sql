drop index orderhdr_status_idx2;

create index orderhdr_status_idx2
on orderhdr(fromfacility,orderstatus,custid)
nologging tablespace users16kb;

drop index orderhdr_status_idx;

alter index orderhdr_status_idx2 rename to orderhdr_status_idx;

exit;
/