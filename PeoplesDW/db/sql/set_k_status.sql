--
-- $Id$
--
update plate
   set status = 'K',
       lastupdate = sysdate,
       lastuser = 'KitFix'
   where status = 'U'
     and workorderseq is not null
     and workordersubseq is not null
     and (facility, location) in (select facility, locid from location);

commit;
exit;
