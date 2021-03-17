create or replace view invalidformatview
(
LPID,
ITEM,
CUSTID,
FACILITY,
LOCATION,
STATUS,
UNITOFMEASURE,
QUANTITY,
TYPE,
SERIALNUMBER,
LOTNUMBER,
EXPIRATIONDATE,
EXPIRYACTION,
PO,
RECMETHOD,
CONDITION,
LASTOPERATOR,
LASTTASK,
FIFODATE,
PARENTLPID,
USERITEM1,
USERITEM2,
USERITEM3,
INVSTATUS,
INVENTORYCLASS,
statusabbrev,
unitofmeasureabbrev,
recmethodabbrev,
invstatusabbrev,
inventoryclassabbrev,
itemdescr,
platetypeabbrev,
hazardous,
conditionabbrev,
loadno,
orderid,
shipid,
weight,
loterror,
serialerror,
user1error,
user2error,
user3error
)
as
select
plate.LPID,
plate.ITEM,
plate.CUSTID,
plate.FACILITY,
plate.LOCATION,
plate.STATUS,
plate.UNITOFMEASURE,
plate.QUANTITY,
plate.TYPE,
plate.SERIALNUMBER,
plate.LOTNUMBER,
plate.EXPIRATIONDATE,
plate.EXPIRYACTION,
plate.PO,
plate.RECMETHOD,
plate.CONDITION,
plate.LASTOPERATOR,
plate.LASTTASK,
plate.FIFODATE,
plate.PARENTLPID,
plate.USERITEM1,
plate.USERITEM2,
plate.USERITEM3,
plate.INVSTATUS,
plate.INVENTORYCLASS,
substr(zlp.platestatus_abbrev(plate.status),1,12),
substr(zit.uom_abbrev(plate.unitofmeasure),1,12),
substr(zlp.handlingtype_abbrev(plate.recmethod),1,12),
substr(zlp.invstatus_abbrev(plate.invstatus),1,12),
substr(zlp.inventoryclass_abbrev(plate.inventoryclass),1,12),
substr(zit.item_descr(plate.custid,plate.item),1,255),
substr(zlp.platetype_abbrev(plate.type),1,12),
substr(zci.hazardous_item(plate.custid,plate.item),1,1),
substr(zlp.condition_abbrev(plate.condition),1,12),
plate.loadno,
plate.orderid,
plate.shipid,
plate.weight,
zfmt.is_valid_format(plate.custid,plate.item,'L',plate.lotnumber),
zfmt.is_valid_format(plate.custid,plate.item,'S',plate.serialnumber),
zfmt.is_valid_format(plate.custid,plate.item,'1',plate.useritem1),
zfmt.is_valid_format(plate.custid,plate.item,'2',plate.useritem2),
zfmt.is_valid_format(plate.custid,plate.item,'3',plate.useritem3)
from custitem, plate
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+)
and plate.type = 'PA'
and plate.status != 'D'
and (
(zfmt.is_valid_format(plate.custid,plate.item,'L',plate.lotnumber) is not null)
or
(zfmt.is_valid_format(plate.custid,plate.item,'S',plate.serialnumber) is not null)
or
(zfmt.is_valid_format(plate.custid,plate.item,'1',plate.useritem1) is not null)
or
(zfmt.is_valid_format(plate.custid,plate.item,'2',plate.useritem2) is not null)
or
(zfmt.is_valid_format(plate.custid,plate.item,'3',plate.useritem3) is not null)
)
;

comment on table invalidformatview is '$Id$';

exit;
