--
-- $Id$
--
alter table custproductgroup add
(
   use_fifo varchar(1)
);
update custproductgroup set use_fifo = 'N'
   where fifowindowdays is null;
update custproductgroup set use_fifo = 'Y'
   where fifowindowdays is not null;
commit;

exit;
