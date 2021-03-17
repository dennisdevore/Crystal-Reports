delete from messageauthors where code = '947';
delete from messageauthors where code = 'ADJXPICK';
delete from messageauthors where code = 'CUSTOMEX';
delete from messageauthors where code = 'DAILYBILL';
delete from messageauthors where code = 'EMAILSHIPORD';
delete from messageauthors where code = 'GENBATCH';
delete from messageauthors where code = 'IMPEXPCHK';
delete from messageauthors where code = 'IMPINV';
delete from messageauthors where code = 'LINERELEASE';
delete from messageauthors where code = 'MAIL';
delete from messageauthors where code = 'NTFYORDSHIP';
delete from messageauthors where code = 'PICK_A_PLATE';

commit;

insert into messageauthors values(
'947', 'Import Export', '947', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'ADJXPICK', 'RF Picking', 'ADJXPICK', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'CUSTOMEX','Custom Code', 'CUSTOMEX', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'DAILYBILL', 'Oracle Daily Billing', 'DAILYBILL', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'EMAILSHIPORD', 'Email Ship Order', 'EMAILSHIPORD', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'GENBATCH', 'Generate Batch Tasks', 'GENBATCH', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'IMPEXPCHK', 'Import/Export', 'IMPEXPCHK ', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'IMPINV', 'Inventory Import', 'IMPINV', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'LINERELEASE', 'Gen Picks', 'LINERELEASE', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'MAIL', 'Oracle Emailer', 'MAIL', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'NTFYORDSHIP', 'Shipment Notification', 'NTFYORDSHIP', 'N', 'SYSTEM', sysdate);

insert into messageauthors values(
'PICK_A_PLATE', 'RF Picking', 'PICK_A_PLATE', 'N', 'SYSTEM', sysdate);

commit;

exit;
