CREATE OR REPLACE VIEW ALPS.ORDERCARTONSVIEW 
(
    ORDERID,
    SHIPID,
    TOTELPID,
    LPID,
    QUANTITY,
    WEIGHT,
    STATUS,
    SPLPID
)
AS
select
   orderid,
   shipid,
   totelpid,
   fromlpid,
   quantity,
   weight,
   status,
   lpid
  from shippingplate
 where type = 'C'
   and status = 'PA';
   
comment on table ORDERCARTONSVIEW is '$Id$';
   
exit;
