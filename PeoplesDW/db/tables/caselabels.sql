--
-- $Id$
--
drop table caselabels;

create table caselabels
(orderid   number,
 shipid    number,
 custid    varchar2(10),
 item varchar2(50),
 lotnumber varchar2(30),
 lpid      varchar2(15),
 barcode   varchar2(20),
 seq       number,
 seqof     number,
 created   date);

exit;
