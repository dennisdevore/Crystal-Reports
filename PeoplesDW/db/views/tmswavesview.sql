create or replace view tmswavesview
as select W.*, 
        T.abbrev tms_status_abbrev
    from tms_status T, wavesview W
   where nvl(W.tms_status,'X') in ('1','2','3')
     and T.code = W.tms_status;

comment on table tmswavesview is '$Id$';

exit;
