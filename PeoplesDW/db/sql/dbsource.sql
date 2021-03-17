--
-- $Id$
--
set long 2000000000;

select text from user_source
where name = 'ZWAVE'
and type = 'PACKAGE BODY'
order by line;
exit;
