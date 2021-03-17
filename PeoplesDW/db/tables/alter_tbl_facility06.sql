alter table facility add 
(
  WorkStart          date,
  WorkFinish         date,
  WorkSunday         char(1),      
  WorkMonday         char(1),
  WorkTuesday        char(1),
  WorkWednesday      char(1),
  WorkThursday       char(1),
  WorkFriday         char(1),
  WorkSaturday       char(1),
  InboundRes         number(2),
  OutboundRes        number(2)        
);

/

update facility  
  set WorkStart = to_date('07:00', 'HH24:MI'), 
  WorkFinish = to_date('17:00', 'HH24:MI'), WorkSunday = 'N', 
  WorkMonday = 'Y', WorkTuesday = 'Y', WorkWednesday = 'Y',
  WorkThursday ='Y', WorkFriday ='Y', WorkSaturday = 'N',
  InboundRes = 3, OutboundRes = 2;
  
/
  
commit;
/

exit;
