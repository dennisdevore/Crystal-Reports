--
-- $Id:  $
--
insert into systemdefaults(defaultid, defaultvalue, lastuser, lastupdate)
  values('NICEWATCHDELIMITER', '|', 'SUP', sysdate);

commit;

exit;
