--
-- $Id$
--
-- show indexes for a table
set serverout on
set echo off
set feedback off
set verify off
declare
	idx_name user_indexes.index_name%TYPE;
	cursor C1 is
  		select index_name, uniqueness from user_indexes
   		where table_name = upper('&1');
	cursor c2 is
  		select column_name from user_ind_columns
   		where index_name = rtrim(idx_name)
   		order by column_position;
begin
	dbms_output.enable(100000);
	dbms_output.put_line('Table: '||upper('&1'));
	for c1rec in C1 loop
		idx_name := c1rec.index_name;
		dbms_output.put_line(   '.   Index: '||c1rec.index_name||' - '
            || c1rec.uniqueness);
		for c2rec in C2 loop
			dbms_output.put_line('.     Col: '||c2rec.column_name);
		end loop;
		dbms_output.put_line('=======================');
	end loop;
end;
/
set feedback on
set verify on
