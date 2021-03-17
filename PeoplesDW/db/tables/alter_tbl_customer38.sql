--
-- $Id$
--
alter table customer add
(
   use_fifo varchar(1)
);
update customer set use_fifo = 'N'
   where fifowindowdays is null;
update customer set use_fifo = 'Y'
   where fifowindowdays is not null;
commit;

exit;
