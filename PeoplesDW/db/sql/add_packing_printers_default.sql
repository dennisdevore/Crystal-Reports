--
-- $Id:  $
--
insert into systemdefaults(defaultid, defaultvalue, lastuser, lastupdate)
  values('PACKINGPRINTERDISPLAY', 'Y', 'SUP', sysdate);

commit;

exit;
