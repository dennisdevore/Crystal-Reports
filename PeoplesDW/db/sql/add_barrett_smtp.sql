--
-- $Id$
--
insert into systemdefaults values ('SMTP_HOST', 'smtp.1and1.com', 'SUP', sysdate);
insert into systemdefaults values ('SMTP_PORT', '25', 'SUP', sysdate);
insert into systemdefaults values ('SMTP_DOMAIN', 'barrettdistribution.com', 'SUP', sysdate);
insert into systemdefaults values ('SMTP_USER', 'm37388151-101', 'SUP', sysdate);
insert into systemdefaults values ('SMTP_PASS', 'notify', 'SUP', sysdate);
commit;
exit;
