create or replace view relwavesview
as select W.*, 
        T.abbrev tms_status_abbrev
    from tms_status T, wavesview W
   where nvl(W.tms_status,'X') in ('X','4')
     and T.code = W.tms_status;

comment on table relwavesview is '$Id';

exit;
