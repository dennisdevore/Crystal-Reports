--
-- $Id$
--
create or replace package zlog as

----------------------------------------------------------------------
--
-- add - add a log entry
--
----------------------------------------------------------------------
PROCEDURE add
(
    in_src  varchar2,
    in_msg  varchar2
);


PROCEDURE cleanup
(
    in_date date
);
END zlog;
/
exit;
