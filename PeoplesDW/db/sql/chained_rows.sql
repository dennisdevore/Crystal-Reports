set serveroutput on;
spool chained_rows.out

create table CHAINED_ROWS (
    owner_name         varchar2(30),
    table_name         varchar2(30),
    cluster_name       varchar2(30),
    partition_name     varchar2(30),
    subpartition_name  varchar2(30),
    head_rowid         rowid,
    analyze_timestamp  date
  );

begin
     for x in (select table_name
                 from user_tables
                where iot_type is null
                  and exists 
                  (select 1
                     from user_objects
                    where object_name = table_name
                      and object_type = 'TABLE'))
     loop
        zut.prt(x.table_name);
        begin
          execute immediate 'analyze table ' || x.table_name ||
                            ' list chained rows into chained_rows';
        exception when others then
          zut.prt(sqlerrm);
        end;
     end loop;
end;
/
select table_name,count(1)
  from chained_rows
 group by table_name
 order by count(1) desc;
drop table chained_rows;
exit;
