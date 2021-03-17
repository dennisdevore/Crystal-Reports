--
-- $Id$
--
alter table custitem add
(
   use_fifo varchar(1)
);
update custitem set use_fifo = 'N'
   where fifowindowdays is null;
update custitem set use_fifo = 'Y'
   where fifowindowdays is not null;
commit;

exit;
