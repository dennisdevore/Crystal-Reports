--
-- $Id: orderdtlrcpt_index.sql 1 2005-05-26 12:20:03Z ed $
--
drop index orderdtlrcpt_plpid_idx;

create index orderdtlrcpt_plpid_idx
   on orderdtlrcpt(nvl(parentlpid,lpid));

exit;