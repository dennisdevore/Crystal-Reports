create or replace view custitemuomuosview
(
CUSTID,                       
ITEM,                         
UOMSEQ,                       
UNITOFMEASURE,                
UOSSEQ,                       
UNITOFSTORAGE,                
UOMINUOS,                     
LASTUSER,                     
LASTUPDATE,
uomabbrev,
uosabbrev
)
as
select
custitemuomuos.CUSTID,                       
custitemuomuos.ITEM,                         
custitemuomuos.UOMSEQ,                       
custitemuomuos.UNITOFMEASURE,                
custitemuomuos.UOSSEQ,                       
custitemuomuos.UNITOFSTORAGE,                
custitemuomuos.UOMINUOS,                     
custitemuomuos.LASTUSER,                     
custitemuomuos.LASTUPDATE,
unitsofmeasure.abbrev,
unitofstorage.abbrev
from
custitemuomuos, unitsofmeasure, unitofstorage
where custitemuomuos.unitofmeasure = unitsofmeasure.code (+)
and custitemuomuos.unitofstorage = unitofstorage.unitofstorage (+);

comment on table custitemuomuosview is '$Id$';

exit;
