--
-- $Id$
--
insert into systemdefaults
       (
        defaultid,
        defaultvalue,
        lastuser,
        lastupdate
       )
       values
       (
       'AR_ACCOUNT',
       '999-9090',
       'SUP',
       sysdate
       );
commit;
exit;
