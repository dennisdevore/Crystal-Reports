--
-- $Id$
--
delete from conversions where fromuom = 'LBS' and touom = 'KG';
insert into conversions(fromuom, touom, qty, lastuser, lastupdate)
values ('LBS','KG',2.20462,'SYSTEM',sysdate);
insert into conversions(fromuom, touom, qty, lastuser, lastupdate)
values ('LBS','TON',2000,'SYSTEM',sysdate);
insert into conversions(fromuom, touom, qty, lastuser, lastupdate)
values ('LBS','CWT',100,'SYSTEM',sysdate);
