--
-- $Id$
--
insert into tbl_global_label_repository (label_id,label_type_id,en)
	values(500,12,'Order List');
insert into tbl_lkup_permissions values(19,500);
insert into tbl_report_types values('ODRRECSUM',500,19);
commit;
insert into tbl_global_label_repository (label_id,label_type_id,en)
	values(501,12,'Orders Recieved');
insert into tbl_lkup_permissions values(20,501);
insert into tbl_report_types values('ODRRECSUM',501,20);
commit;
insert into tbl_global_label_repository (label_id,label_type_id,en)
	values(502,12,'Order Exception Summary');
insert into tbl_lkup_permissions values(21,502);
insert into tbl_report_types values('ODRECPTSUM',502,21);
commit;
insert into tbl_global_label_repository (label_id,label_type_id,en)
	values(503,12,'Order Exception Detail');
insert into tbl_lkup_permissions values(22,503);
insert into tbl_report_types values('ODRECPTDTL',503,22);
commit;
insert into tbl_global_label_repository (label_id,label_type_id,en)
	values(504,12,'Inventory Report');
insert into tbl_lkup_permissions values(23,504);
insert into tbl_report_types values('GENINV',504,24);
commit;
exit;



