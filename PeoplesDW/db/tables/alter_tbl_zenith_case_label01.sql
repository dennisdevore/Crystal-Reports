--
-- $Id: alter_tbl_zenith_case_labels01.sql $
--
alter table zenith_case_labels add (
   hdrchar01     varchar2(255),
   hdrchar02     varchar2(255),
   hdrchar03     varchar2(255),
   hdrchar04     varchar2(255),
   hdrchar05     varchar2(255),
   hdrchar06     varchar2(255),
   hdrchar07     varchar2(255),
   hdrchar08     varchar2(255),
   hdrchar09     varchar2(255),
   hdrchar10     varchar2(255),
   hdrnum01     number(16,4),
   hdrnum02     number(16,4),
   hdrnum03     number(16,4),
   hdrnum04     number(16,4),
   hdrnum05     number(16,4),
   hdrnum06     number(16,4),
   hdrnum07     number(16,4),
   hdrnum08     number(16,4),
   hdrnum09     number(16,4),
   hdrnum10     number(16,4),
   dtlchar01     varchar2(255),
   dtlchar02     varchar2(255),
   dtlchar03     varchar2(255),
   dtlchar04     varchar2(255),
   dtlchar05     varchar2(255),
   dtlchar06     varchar2(255),
   dtlchar07     varchar2(255),
   dtlchar08     varchar2(255),
   dtlchar09     varchar2(255),
   dtlchar10     varchar2(255),
   dtlnum01     number(16,4),
   dtlnum02     number(16,4),
   dtlnum03     number(16,4),
   dtlnum04     number(16,4),
   dtlnum05     number(16,4),
   dtlnum06     number(16,4),
   dtlnum07     number(16,4),
   dtlnum08     number(16,4),
   dtlnum09     number(16,4),
   dtlnum10     number(16,4)
);
create index zenith_case_labels_lpid
   on zenith_case_labels(lpid);
exit;
