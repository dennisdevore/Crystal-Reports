-- Create script for primary keys on tables
set serverout on
set echo off
set feedback off
set verify off
set linesize 250
set pagesize 0
set termout off
set trimspool on
set trimout on

create table pk_temp(table_name varchar2(30),
    index_name varchar2(30),
    cols varchar2(500), has_nulls char(1));

declare
idx_name user_indexes.index_name%TYPE;

cursor C_UNIQUE is
    select table_name, index_name, uniqueness from user_indexes
     where uniqueness = 'UNIQUE'
     order by table_name, index_name;

cursor C_COLS(in_index varchar2) is
    select I.column_name, T.nullable 
      from user_tab_columns T, user_ind_columns I
     where I.index_name = rtrim(in_index)
       and T.table_name = I.table_name
       and T.column_name = I.column_name
     order by I.column_position;
cursor C_CONS(in_table varchar2) is
    select constraint_name, table_name
     from user_constraints
    where constraint_type in ('P','U')
      and table_name = in_table;

CONS C_CONS%rowtype;

cols varchar2(1000);

hn char(1);
begin
    dbms_output.enable(1000000);

    for cidx in C_UNIQUE
    loop
        CONS := null;
        OPEN C_CONS(cidx.table_name);
        FETCH C_CONS into CONS;
        CLOSE C_CONS;

        if CONS.table_name is not null then
            -- dbms_output.put_line('Already PK:'||cidx.table_name);
            goto continue;
        end if;        

        cols := null;

        hn := 'N';
        for ccols in C_COLS(cidx.index_name) loop
            cols := cols||','||ccols.column_name ;
            if ccols.nullable = 'Y' then
                hn := 'Y';
            end if;
        end loop;

        insert into pk_temp
        values (cidx.table_name, cidx.index_name, substr(cols,2), hn);    
    
    <<continue>>
        null;
    end loop;

end;
/

spool pk_list
select 'Alter Table '||table_name||' add constraint PK_'||table_name
    ||' primary key('||cols||') using index '||index_name||';'
  from pk_temp
 where table_name in (
    select table_name
      from pk_temp
     group by table_name
    having count(1) = 1)
  and has_nulls = 'N'
 order by table_name, index_name;
spool pk_list_nulls
select 'Alter Table '||table_name||' add constraint PK_'||table_name
    ||' primary key('||cols||') using index '||index_name||';'
  from pk_temp
 where table_name in (
    select table_name
      from pk_temp
     group by table_name
    having count(1) = 1)
  and has_nulls = 'Y'
 order by table_name, index_name;
spool pk_list_multi
select decode(has_nulls,'Y','***** CAN BE NULL ****','') ||
    'Alter Table '||table_name||' add constraint PK_'||table_name
    ||' primary key('||cols||') using index '||index_name||';'
  from pk_temp
 where table_name in (
    select table_name
      from pk_temp
     group by table_name
    having count(1) > 1)
 order by table_name, index_name;
spool pk_no_unique
select table_name
  from user_tables
 where table_name not in
(select table_name
   from user_indexes
  where uniqueness = 'UNIQUE');
spool off
drop table pk_temp;
set feedback on
set verify on

