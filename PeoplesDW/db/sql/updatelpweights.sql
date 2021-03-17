--
-- $Id$
--
update plate P
   set P.weight =
   (select nvl(P.quantity, 0) * nvl(I.weight, 0)
      from custitem I
      where I.custid = P.custid
        and I.item = P.item);

commit;

exit;
