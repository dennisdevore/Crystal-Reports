set pagesize 0
set long 2000000000
spool topsql.out
SELECT * FROM(
SELECT
'SQL:' ||
sql_text,
' MODULE: ' || module,
ceil(cpu_time/greatest(executions,1)) ave_cpu_time,
ceil(elapsed_time/greatest(executions,1)) ave_elapsed_time,
ceil(disk_reads/greatest(executions,1)) ave_disk_reads,
persistent_mem per_mem, runtime_mem run_mem,
ceil(sorts/greatest(executions,1)) ave_sorts,
ceil(parse_calls/greatest(executions,1)) ave_parse_calls,
ceil(Buffer_gets/greatest(executions,1)) ave_buffer_gets,
ceil(rows_processed/greatest(executions,1)) ave_row_proc,
ceil(Serializable_aborts/greatest(executions,1)) ave_ser_aborts
FROM
v$sqlarea
order by elapsed_time desc, cpu_time, disk_reads)
where rownum<101;
exit;
