--
-- $Id$
--
drop index load_flag_ctn_ctnid_idx;

create index load_flag_ctn_ctnid_idx on load_flag_ctn(cartonid);
