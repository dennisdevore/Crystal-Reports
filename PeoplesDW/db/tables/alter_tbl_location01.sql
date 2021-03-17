--
-- $Id$
--
alter table location add
(
   stackheight    number(3)
);

update location LO
   set LO.stackheight =
      (select min(CI.stackheight)
         from custitem CI, plate PL
         where PL.facility = LO.facility
           and PL.location = LO.locid
           and CI.custid = PL.custid
           and CI.item = PL.item);

exit;
