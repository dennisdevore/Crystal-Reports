--
-- $Id$
--
--drop index orderhdr_transapptdate_idx;

create index orderhdr_transapptdate_idx on
   orderhdr(transapptdate) tablespace users16kb;

exit;
