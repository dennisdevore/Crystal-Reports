--
-- $ID: alter_tbl_loads09.sql
--
alter table loads add
(
  liveunload       char(1) default 'N',
  etatofacility    date
);

commit;

exit;
