--
-- $Id: tablespaces.sql 1 2005-05-26 12:20:03Z ed $
--
create tablespace synapse_act2_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synact2dat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_act2_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synact2idx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_act_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synactdat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_act_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synactidx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_his_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synhisdat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 5m
                    next 5m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_his_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synhisidx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 5m
                    next 5m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_inv_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/syninvdat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 1m
                    next 1m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_inv_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/syninvidx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 1m
                    next 1m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_lod2_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synlod2dat01.dbf' size 50m autoextend on next 5m
    logging
    default storage(initial 200k
                    next 200k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_lod2_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synlod2idx01.dbf' size 50m autoextend on next 5m
    logging
    default storage(initial 200k
                    next 200k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_lod_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synloddat01.dbf' size 50m autoextend on next 5m
    logging
    default storage(initial 200k
                    next 200k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_lod_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synlodidx01.dbf' size 50m autoextend on next 5m
    logging
    default storage(initial 200k
                    next 200k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_ohis_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synohisdat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 5m
                    next 5m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_ohis_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synohisidx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 5m
                    next 5m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_ord_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synorddat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 1m
                    next 1m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_ord_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synordidx01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 1m
                    next 1m
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_temp_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/syntmpdat01.dbf' size 200m autoextend on next 20m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_temp_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/syntmpidx01.dbf' size 50m autoextend on next 5m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_user_data
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synusrdat01.dbf' size 100m autoextend on next 10m
    logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

create tablespace synapse_user_index
    datafile '$ORACLE_BASE/oradata/$ORACLE_SID/synusridx01.dbf' size 100m 
	 autoextend on next 10m 
	 logging
    default storage(initial 504k
                    next 504k
                    minextents 1
                    maxextents unlimited
                    pctincrease 0)
    online
    permanent
/

exit;
