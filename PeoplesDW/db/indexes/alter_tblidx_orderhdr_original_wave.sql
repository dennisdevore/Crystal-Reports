--
-- $Id: alter_tblidx_orderhdr_original_wave.sql 285 2005-10-28 17:35:55Z ed $
--
create index orderhdr_original_wave_idx on
   orderhdr(original_wave_before_combine) tablespace users16kb;
exit;
