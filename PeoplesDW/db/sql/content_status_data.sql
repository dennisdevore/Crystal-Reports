--
-- $Id  content_status_data.sql 466 2005-12-13 16:09:52Z ed $
--


delete from contents_status;

insert into contents_status
   values('E', 'Empty', 'Empty', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('A', 'Arrived', 'Arrived', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('F', 'Full', 'Full', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('7', 'Loading', 'Loading', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('8', 'Loaded', 'Loaded', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('9', 'Shipped', 'Shipped', 'N', 'SYNAPSE', sysdate);




update trailer set contents_status = 'F' where contents_status = 'H';

commit;

exit;

