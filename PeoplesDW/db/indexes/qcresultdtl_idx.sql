--
-- $Id$
--
drop index pk_qcresultdtl;

create unique index pk_qcresultdtl 
       on qcresultdtl(id, orderid, shipid, lpid);

drop index qcresultdtl_lpid_idx;

create index qcresultdtl_lpid_idx
       on qcresultdtl(lpid);

-- exit
