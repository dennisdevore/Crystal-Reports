select
item,
lotnumber,
linenumber,
qtyordered,
qtyshipped,
fromlpid,
inventoryclass
from ship_note_945_dtl_80003
order by item,linenumber;
select
serialnumber,quantity,fromlpid,linenumber
from ship_note_945_sn_80003
where item = 'E0001100-0001'
order by linenumber;
select distinct inventoryclass
from ship_note_945_dtl_80003;
exit;
