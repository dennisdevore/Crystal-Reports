--
-- $Id$
--
drop table storageparms;

create table storageparms
(
objectclass varchar(10) not null,
descr varchar2(80),
storageparm long,
lastuser varchar2(12),
lastupdate date
);

exit;
