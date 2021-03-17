--
-- $Id$
--
set pagesize 60 linesize 100 verify off feedback off newpage 0
break on segment_type skip 1 on owner
ttitle center 'Segments with extents >= ' &&1 skip 2

column segment_type format a8 heading "Type"
column segment_name format a32 heading "Segment Name"
column owner format a10 heading "Owner"
column extents format 9999999999 heading "Extents"
column next_extent format 9999999999 heading "Next|Extent"
column max_extents format 9999999999 heading "Max|Extents"
column remext format 9999999999 heading "Extents|Remaining"

select segment_type,
       segment_name,
       owner,
       extents,
       max_extents,
       max_extents-extents remext,
       next_extent
   from sys.dba_segments
   where segment_type in ('INDEX', 'TABLE', 'CLUSTER', 'ROLLBACK')
     and extents >= &&1
    order by segment_type, owner, remext

/
set verify on feedback on
ttitle off
undefine 1
