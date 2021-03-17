create or replace PACKAGE BODY alps.zrate
IS
--
-- $Id$
--

FUNCTION handling_abbrev
(in_handling IN varchar2
) return varchar2 is

out handlingtypes%rowtype;

begin

select abbrev
  into out.abbrev
  from handlingtypes
 where code = in_handling;

return out.abbrev;

exception when others then
  return in_handling;
end handling_abbrev;

FUNCTION activity_abbrev
(in_activity IN varchar2
) return varchar2 is

out activity%rowtype;

begin

select abbrev
  into out.abbrev
  from activity
 where code = in_activity;

return out.abbrev;

exception when others then
  return in_activity;
end activity_abbrev;

FUNCTION rategroup_abbrev
(in_custid IN varchar2
,in_rategroup IN varchar2
) return varchar2 is

out custrategroup%rowtype;

begin

select abbrev
  into out.abbrev
  from custrategroup
 where custid = in_custid
   and rategroup = in_rategroup;

return out.abbrev;

exception when others then
  return in_rategroup;
end rategroup_abbrev;

FUNCTION rategroup_descr
(in_custid IN varchar2
,in_rategroup IN varchar2
) return varchar2 is

out custrategroup%rowtype;

begin

select descr
  into out.descr
  from custrategroup
 where custid = in_custid
   and rategroup = in_rategroup;

return out.descr;

exception when others then
  return in_rategroup;
end rategroup_descr;

FUNCTION billmethod_abbrev
(in_billmethod IN varchar2
) return varchar2 is

out billingmethod%rowtype;

begin

select abbrev
  into out.abbrev
  from billingmethod
 where code = in_billmethod;

return out.abbrev;

exception when others then
  return in_billmethod;
end billmethod_abbrev;

PROCEDURE rate_change
(in_custid varchar2
,in_rategroup varchar2
,in_effdate date
,in_activity varchar2
,in_billmethod varchar2
,in_userid varchar2
,in_new_effdate date
,in_new_rate number
,out_msg IN OUT varchar2
) is

cursor curRate is
  select *
    from custrate
   where custid = in_custid
     and rategroup = in_rategroup
     and effdate = in_effdate
     and activity = in_activity
     and billmethod = in_billmethod;
cr curRate%rowtype;

begin

out_msg := '';
open curRate;
fetch curRate into cr;
if curRate%notfound then
  close curRate;
  out_msg := 'Rate change base record not found' || to_char(in_effdate,'yymmdd');
  return;
end if;
close curRate;

-- clone rate record with new effdate/rate
insert into custrate
  (custid, rategroup, effdate, activity, billmethod, uom,
   rate, gracedays, calctype, moduom, annvdays, lastuser, lastupdate, 
   anvdate_grace)
values
  (cr.custid, cr.rategroup, in_new_effdate, cr.activity, cr.billmethod, cr.uom,
   in_new_rate, cr.gracedays, cr.calctype, cr.moduom, cr.annvdays,
   in_userid, sysdate, cr.anvdate_grace);

-- clone event trigger rows
insert into custratewhen
  select custid, rategroup, in_new_effdate, activity, billmethod,
         businessevent, automatic, in_userid, sysdate
    from custratewhen
   where custid = in_custid
     and rategroup = in_rategroup
     and effdate = in_effdate
     and activity = in_activity
     and billmethod = in_billmethod;

out_msg := 'OKAY';
exception when others then
  out_msg := sqlerrm;
end rate_change;

end zrate;
/
show error package body zrate;
exit;
