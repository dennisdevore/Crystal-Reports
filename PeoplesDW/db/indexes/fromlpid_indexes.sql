--
-- $Id: fromlpid_indexes.sql 1 2005-05-26 12:20:03Z ed $
--
create index plate_fromlpid_idx
   on plate(fromlpid) tablespace users16kb;
create index deletedplate_fromlpid_idx
   on deletedplate(fromlpid) tablespace users16kb;
exit;
