--
-- $Id$
--
select b.file_name, a.tablespace_name, a.bytes, a.blocks
from dba_free_space a, dba_data_files b
where a.file_id = b.file_id
and a.tablespace_name = 'TEMP';
exit;
