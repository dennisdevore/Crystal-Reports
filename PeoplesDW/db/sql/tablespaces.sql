--
-- $Id$
--
create tablespace synapse_act2_data
    datafile '/usr/oradata/test/synact2dat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synact2idx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synactdat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synactidx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synhisdat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synhisidx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/syninvdat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/syninvidx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synlod2dat01.dbf' size 50m autoextend on next 5m
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
    datafile '/usr/oradata/test/synlod2idx01.dbf' size 50m autoextend on next 5m
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
    datafile '/usr/oradata/test/synloddat01.dbf' size 50m autoextend on next 5m
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
    datafile '/usr/oradata/test/synlodidx01.dbf' size 50m autoextend on next 5m
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
    datafile '/usr/oradata/test/synohisdat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synohisidx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synorddat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synordidx01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/syntmpdat01.dbf' size 200m autoextend on next 20m
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
    datafile '/usr/oradata/test/syntmpidx01.dbf' size 50m autoextend on next 5m
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
    datafile '/usr/oradata/test/synusrdat01.dbf' size 100m autoextend on next 10m
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
    datafile '/usr/oradata/test/synusridx01.dbf' size 100m autoextend on next 10m
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
