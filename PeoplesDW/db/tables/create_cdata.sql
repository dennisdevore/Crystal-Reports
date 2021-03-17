--
-- $Id$
--
CREATE OR REPLACE TYPE CDATA AS OBJECT
(
    orderid     number(9),
    shipid      number(2),
    loadno      number(7),
    stopno      number(7),
    shipno      number(7),
    lpid        varchar2(15),
    custid      varchar2(10),
    item varchar2(50),
    lotnumber   varchar2(30),
    quantity    number(7),
    reason      varchar2(10),
    userid      varchar2(12),
    char01      varchar2(100),
    char02      varchar2(100),
    char03      varchar2(100),
    num01       number,
    num02       number,
    num03       number,
    out_no      number,
    out_char    varchar2(100)
);
/
exit;

