--
-- $Id$
--
create index orderdtlrcpt_faccusitmlot_idx
   on orderdtlrcpt(facility, custid, item, lotnumber);

exit;
