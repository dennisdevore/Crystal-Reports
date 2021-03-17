--
-- $Id$
--
alter table orderhdr add
(
    origorderid     number(7),
    origshipid      number(2),
    bulkretorderid  number(7),
    bulkretshipid   number(2),
    returntrackingno    varchar2(20)
);

exit;
