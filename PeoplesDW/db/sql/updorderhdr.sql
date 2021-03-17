--
-- $Id$
--
update orderhdr
   set deliveryservice = decode(hdrpassthruchar07,'F01','PO',
         'F06','SO','ES'),
       saturdaydelivery = decode(hdrpassthruchar04,'Y','Y','N'),
       cod = 'N'
 where custid = 'HP'
   and ordertype = 'O'
   and orderstatus < '9'
   and deliveryservice is null;
commit;
exit;
