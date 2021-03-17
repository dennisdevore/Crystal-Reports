--
-- $Id: add_PA_shippingplatestatus.sql
--
insert into shippingplatestatus values('PA', 'Packing Plate', 'Packing', 'N', 'SYNAPSE', sysdate);

commit;

exit;
