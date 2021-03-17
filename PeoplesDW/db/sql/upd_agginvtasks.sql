--
-- $Id$
--
insert into agginvtasks
   (shippinglpid, lpid, qty)
select SP.lpid, SP.fromlpid, SP.quantity
   from shippingplate SP, customer CU, orderhdr OH
   where CU.custid = SP.custid
     and nvl(CU.paperbased,'N') != 'N'
     and OH.orderid = SP.orderid
     and OH.shipid = SP.shipid
     and OH.ordertype = 'O'
     and SP.type in ('P','F')
     and SP.status = 'U'
     and (SP.lpid, SP.fromlpid) not in
      (select shippinglpid, lpid
         from agginvtasks);
