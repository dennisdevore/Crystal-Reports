--
-- $Id: oodailytotals.sql 7079 2011-08-02 18:42:26Z ed $
--
create table oodailytotals
(
   capturedate          date,
   facility             varchar2(3) not null,
   custid               varchar2(10) not null,
   closedreceipts       number(10),
   inboundunits         number(15),
   inboundhours         number(15,4),
   ordersshipped        number(10),
   outboundunits        number(15),
   outboundhours        number(15,4),
   receiptrevenue       number(15,2),
   renewalrevenue       number(15,2),
   accessorialrevenue   number(15,2),
   miscrevenue          number(15,2),
   creditrevenue        number(15,2)
);

create unique index oodailytotals_idx
   on oodailytotals (capturedate, facility, custid);

exit;
