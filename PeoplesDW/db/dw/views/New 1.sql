select * from DW.F_INVOICE_HEADER
where modification_time between to_date('20210301','yyyymmdd')
                            and to_date('20210307','yyyymmdd');

AND ID.LASTUPDATE between to_date('20210301','yyyymmdd')
                            and to_date('20210307','yyyymmdd') --and h.invoice = 3818386
drop table tmp;
create table tmp as
   SELECT SYS_CONTEXT ('USERENV', 'SERVICE_NAME')    DB_Service_Name,
          a.lastupdate                               Modification_Time,
          a.code                                     Unit_Of_Measure,
          a.descr                                    Unit_Of_Measure_Desc,
          a.abbrev                                   Unit_Of_Measure_Abbrev,
          a.dtlupdate                                Detail_Update_YN,
          a.lastuser                                 AS last_update_user,
          a.lastupdate                               AS last_update_time
     FROM alps.unitsofmeasure a;
