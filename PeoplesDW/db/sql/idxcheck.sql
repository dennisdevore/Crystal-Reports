--
-- $Id$
--
select table_name
   from user_tables
   where table_name not in (select table_name from user_indexes);

select table_name
   from user_tables
   where table_name not in (select table_name from user_indexes
                              where uniqueness = 'UNIQUE');

exit;
