create or replace view putawayproflineview
(
FACILITY,                     
PROFID,                       
PRIORITY,                     
MINUOM,                       
MAXUOM,                       
UOM,                          
INVSTATUS,                    
INVENTORYCLASS,               
ZONEID,                       
LOCATTRIBUTE,                 
USEVELOCITY,                  
FITMETHOD,                    
LASTUSER,                     
LASTUPDATE,                   
uomabbrev,
locattributeabbrev,
fitmethodabbrev,
zonedescription,
productgroup,
primaryhazardclass
)
as
select
putawayprofline.FACILITY,
PROFID,
PRIORITY,
MINUOM,
MAXUOM,
UOM,
INVSTATUS,
INVENTORYCLASS,
putawayprofline.ZONEID,
LOCATTRIBUTE,
USEVELOCITY,
FITMETHOD,
putawayprofline.LASTUSER,
putawayprofline.LASTUPDATE,
unitsofmeasure.abbrev,
locationattributes.abbrev,
fitmethods.abbrev,
zone.description,
putawayprofline.productgroup,
putawayprofline.primaryhazardclass
from putawayprofline, unitsofmeasure,
     fitmethods, locationattributes, zone
where uom = unitsofmeasure.code (+)
  and locattribute = locationattributes.code (+)
  and fitmethod = fitmethods.code (+)
  and putawayprofline.facility = zone.facility(+)
  and putawayprofline.zoneid = zone.zoneid(+);
  
comment on table putawayproflineview is '$Id$';
  
exit;
