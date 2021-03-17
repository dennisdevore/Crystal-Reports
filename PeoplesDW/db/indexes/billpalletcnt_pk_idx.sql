--
-- $Id$
--
drop index billpalletcnt_pk_idx;

create unique index billpalletcnt_pk_idx
       on billpalletcnt(facility, custid, effdate, item, lotnumber);

exit;
