update impexp_lines
   set procname = upper(replace(upper(procname), 'LOAD_TENDER', 'LOAD_TDR'))
 where upper(procname) like 'LOAD_TENDER%';
exit;
