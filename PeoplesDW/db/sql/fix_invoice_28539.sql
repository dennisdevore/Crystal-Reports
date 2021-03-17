--
-- $Id$
--
update invoicedtl
   set billstatus = '3'
   where invoice = 28539
     and billstatus = '0';
