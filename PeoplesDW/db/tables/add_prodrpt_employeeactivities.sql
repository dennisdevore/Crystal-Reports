--
-- $Id$
--
insert into employeeactivities values('1LIP', 'LP 1 Step Receipt', 'LP 1Step Rec', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('ALIP', 'LP ASN Receipt', 'LP ASN Rec', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('BADT', 'Batch Pick Detail', 'Batch Detail', 'N', 'SYSTEM', sysdate);
insert into employeeactivities values('CONS', 'Consolidate MP', 'ConsolidMP', 'N', 'SYSTEM', sysdate);

delete employeeactivities where code='OOPK';
delete employeeactivities where code='OPUT';

commit;

exit;

