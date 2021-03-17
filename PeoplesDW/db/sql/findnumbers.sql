--
-- $Id$
--
select
trim(table_name) as table_name,
trim(column_name) as column_name,
data_precision as precision
  from user_tab_columns c
 where data_type = 'NUMBER'
   and exists
       (select *
          from user_objects o
         where c.table_name = o.object_name
           and o.object_type = 'TABLE')
   and column_name not in ('LOADNO','STOPNO','SHIPNO','ORDERID','SHIPID')
   and column_name not like 'WIDTH%'
 order by table_name,column_name;
--exit;