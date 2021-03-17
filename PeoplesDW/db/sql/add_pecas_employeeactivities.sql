--
-- $Id$
--
insert into employeeactivities values('SPTR', 'Ship to Production Tour', 'ShipProdTour', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('SPWK', 'Ship to Production Work', 'ShipProdWork', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('WIPR', 'Work In Progress Receipt', 'WIP Receipt', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('FGDR', 'Finished Goods Receipt', 'FG Receipt', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('TKIT', 'Take Item', 'Take Item', 'N', 'SYSTEM', sysdate);

commit;

exit;
