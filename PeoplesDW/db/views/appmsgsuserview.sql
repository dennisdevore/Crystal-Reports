create or replace view appmsgsuserview (nameid) as
select upper(nameid) from userheader where usertype='U' and userstatus='A' union
select '(AGGINVEN)' from dual union
select '(FRNTENDLBL)' from dual union
select 'AUTO_PLAN' from dual union
select 'AUTOWAVEPLAN' from dual union
select 'BILLER' from dual union
select 'CMPLTASK' from dual union
select 'DAILYBILL' from dual union
select 'DAILYJOB' from dual union
select 'DYNAMICPF' from dual union
select 'EXPRUN' from dual union
select 'FINDPLATE' from dual union
select 'FIX_PUTAWAY' from dual union
select 'FLUSH_RF' from dual union
select 'IMP860' from dual union
select 'IMPINVADJ' from dual union
select 'IMPITEM' from dual union
select 'IMPORDER' from dual union
select 'ITEMDEMAND' from dual union
select 'LDINV' from dual union
select 'LINERELEASE' from dual union
select 'MULTISHIP' from dual union
select 'PAPER' from dual union
select 'PECAS' from dual union
select 'PTL' from dual union
select 'SIPIMP' from dual union
select 'SYNAPSE' from dual union
select 'SYPMON' from dual union
select 'SYSTEM' from dual union
select 'UPDTIPF' from dual union
select 'UPDTPF' from dual union
select 'WAVEPLAN' from dual union
select 'WAVERELEASE' from dual union
select 'ZPT' from dual;
  
comment on table appmsgsuserview is '$Id';
  
exit;

