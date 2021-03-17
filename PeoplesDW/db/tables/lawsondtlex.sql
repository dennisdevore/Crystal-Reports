--
-- $Id$
--
create table lawsondtlex
(
    sessionid   varchar2(8),
    prefix      varchar2(2),
    invoice     number(8),
    linenumber  number(6),
    facility    varchar2(3),
    item varchar2(50),
    lotnumber   varchar2(30),
    descr       varchar2(32),
    quantity    number(9,2),
    price       number(12,6),
    amount      number(10,2),
    uom         varchar2(4),
    glaccount   varchar2(6),
    araccount   varchar2(6),
    orderid     number(7),
    activity    varchar2(4),
    activitydesc varchar2(32),
    reference   varchar2(20),
    po          varchar2(20)
);

exit;

