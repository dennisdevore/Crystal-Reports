--
-- $Id$
--
drop table p1pkcaselabels;

create table p1pkcaselabels
(orderid number,
 shipid  number,
 custid  varchar(10),
 item    varchar(20),
 seq     number,
 seqof   number);

exit;
