column tsname       format a15         heading 'Tablespace Name'
column flname       format a30         heading 'Filename'
column siz          format 999,999,990 heading 'File Size|(MB)'
column maxsiz       format 999,999,990 heading 'Max Size|(MB)'
column pctmax       format 990         heading 'Pct|Max'

set linesize  1000
set trimspool on
set pagesize  32000
set verify    off
set feedback  off

spool datafile_usage.out

select substr(file_name,29,15)                            flname
,      tablespace_name                                    tsname
,      bytes/1024/1024                                    siz
,      decode(maxbytes,0,0,maxbytes/1024/1024)            maxsiz
,      decode(maxbytes,0,0,bytes/maxbytes*100)            pctmax
from   dba_data_files
order by file_name
/

column tsname      clear
column flname      clear
column siz         clear
column maxsiz      clear
column pctmax      clear
exit;
