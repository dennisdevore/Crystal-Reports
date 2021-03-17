--
-- $Id: alter_tbl_carrierzone.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custlastrenewal add
(
  renewal_start     date,
  renewal_end       date,
  proc_beg_seconds  number,
  proc_asof_seconds number,
  proc_pltc_seconds number,
  proc_locc_seconds number,
  proc_lrr_seconds  number,
  proc_ordloop_seconds  number,
  proc_ordloop_rows number,
  proc_bac_seconds  number,
  proc_end_seconds  number,
  proc_tot_seconds  number
);
--exit;