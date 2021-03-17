--
-- $Id$
--
update sap_shipto_override_hp
   set abbrev = substr(abbrev,1,3)
 where length(rtrim(abbrev)) = 4
   and substr(abbrev,4,1) = 'K';
update sap_parms_for_hp_hpcd
   set abbrev = substr(abbrev,1,3)
 where length(rtrim(abbrev)) = 4
   and substr(abbrev,4,1) = 'K';
update sap_parms_for_hp_hpc1
   set abbrev = substr(abbrev,1,3)
 where length(rtrim(abbrev)) = 4
   and substr(abbrev,4,1) = 'K';
update sap_parms_for_hp_hnar
   set abbrev = substr(abbrev,1,3)
 where length(rtrim(abbrev)) = 4
   and substr(abbrev,4,1) = 'K';
--exit;
