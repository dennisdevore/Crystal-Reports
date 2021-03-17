--
-- $Id$
--
update orderdtl
   set qtyship = qtypick,
       amtship = amtpick,
       cubeship = cubepick,
       weightship = weightpick
   where orderid = 132003
     and shipid = 1
     and item = 'HIRZN14GR'
     and lotnumber = '31B88003';

update loadstopship
   set qtyship = qtyorder,
       amtship = amtorder,
       cubeship = cubeorder,
       weightship = weightorder
   where loadno = 26623
     and stopno = 1
     and shipno = 1;
