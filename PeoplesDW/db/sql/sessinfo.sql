set heading off;
spool sessinfo.out;
select /*+ gather_plan_statistics */ 
       proc.spid,
	   sid, 
	   osuser,
	   executions,
       proc.program,
	   sql_text
  from v$session sess, v$sql sql, v$process proc
 where sess.sql_id = sql.sql_id
   and sess.status = 'ACTIVE'
   and sess.paddr = proc.addr(+);
exit;
