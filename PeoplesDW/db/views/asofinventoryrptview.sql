  CREATE OR REPLACE FORCE VIEW "ALPS"."ASOFINVENTORYRPTVIEW" ("TRUELINK",
 "FACILITY",
 "CUSTID",
 "ITEM",
 "LOTNUMBER",
 "UOM",
 "EFFDATE",
 "PREVIOUSQTY",
 "CURRENTQTY",
 "LASTUSER",
 "LASTUPDATE",
 "INVSTATUS",
 "INVENTORYCLASS",
 "PREVIOUSWEIGHT",
 "CURRENTWEIGHT") AS  select 1 as truelink, asofinventory."FACILITY",
asofinventory."CUSTID",
asofinventory."ITEM",
asofinventory."LOTNUMBER",
asofinventory."UOM",
asofinventory."EFFDATE",
asofinventory."PREVIOUSQTY",
asofinventory."CURRENTQTY",
asofinventory."LASTUSER",
asofinventory."LASTUPDATE",
asofinventory."INVSTATUS",
asofinventory."INVENTORYCLASS",
asofinventory."PREVIOUSWEIGHT",
asofinventory."CURRENTWEIGHT" from asofinventory ;

exit;
