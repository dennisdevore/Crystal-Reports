--
-- $Id: alter_tbl_caselabels03.sql 644 2006-02-27 21:34:33Z ed $
--
alter table caselabels add
(
   mixedorderorderid  number(9),
   mixedordershipid   number(2)
);


alter table caselabels_temp add
(
   mixedorderorderid  number(9),
   mixedordershipid   number(2)
);

exit;
