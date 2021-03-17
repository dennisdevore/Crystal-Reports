--
-- $Id$
--
update location
   set lpcount = 0;

update location
   set lpcount = (select count(1) from plate
         where ((plate.facility = location.facility
               and plate.location = location.locid)
             or (plate.destfacility = location.facility
               and plate.destlocation = location.locid))
           and type = 'PA');
exit;
