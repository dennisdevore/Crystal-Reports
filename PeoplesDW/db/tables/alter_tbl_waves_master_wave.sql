--
-- $Id: alter_tbl_waves07.sql 1 2005-05-26 12:20:03Z ed $
--
alter table waves add
(
master_wave number(9)
);

create index waves_master_wave_idx on waves(master_wave);

exit;
