--
-- $Id$
--
create table custitemcatchweight (
   custid     varchar2(10) not null,
   item varchar2(50) not null,
   orderid	  number(7),
   shipid	  number(7),
   uom        varchar2(4),
   totqty     number(10),
   totweight  number(15,4),
   lastuser   varchar2(12),
   lastupdate date
);
exit;
