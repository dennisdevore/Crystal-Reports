create or replace package body zlog as
--
-- $Id$
--

last_date   date := null;
last_seq    number := null;

----------------------------------------------------------------------
--
-- add - add a log entry
--
----------------------------------------------------------------------
PROCEDURE add
(
    in_src  varchar2,
    in_msg  varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
l_seq number;

BEGIN
    INSERT into pecas_log(created,seq,source,message)
    VALUES(sysdate,logseq.nextval,in_src, in_msg);

    COMMIT;
EXCEPTION WHEN OTHERS THEN
    rollback;
END add;


PROCEDURE cleanup
(
    in_date date
)
IS
BEGIN
    delete from pecas_log
     where created <= in_date;

EXCEPTION WHEN OTHERS THEN
    null;
END cleanup;

END zlog;
/
exit;
