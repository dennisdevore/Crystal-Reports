--
-- $Id$
--
alter table oldorderhdr add
(shippername varchar2(40)
,shippercontact varchar2(40)
,shipperaddr1 varchar2(40)
,shipperaddr2 varchar2(40)
,shippercity varchar2(30)
,shipperstate varchar2(2)
,shipperpostalcode varchar2(12)
,shippercountrycode varchar2(3)
,shipperphone varchar2(15)
,shipperfax varchar2(15)
,shipperemail varchar2(255)
);
exit;
