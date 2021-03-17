--
-- $Id$
--
alter table conversions add (
    lastuser      varchar2(12),
    lastupdate    date
);

update conversions set lastuser = 'SYS',
                       lastupdate = sysdate;


insert into conversions values('CUIN','CUFT',1728,'SYS',sysdate);

exit;
