begin
  execute immediate 'drop view custfacilityview';
exception when others then
  null;
end;
/
begin
  execute immediate 'drop view custpgfacview';
exception when others then
  null;
end;
/
begin
  execute immediate 'drop view custitemprodfacilityview';
exception when others then
  null;
end;
/
create or replace view custproductgroupfacilityview
(custid
,productgroup
,facility
,profid
,allocrule
,replallocrule
)
as
select
cf.custid,
cf.productgroup,
cf.facility,
substr(zcf.group_profid(cf.facility,cf.custid,cf.productgroup),1,2),
substr(zcf.group_allocrule(cf.facility,cf.custid,cf.productgroup),1,10),
substr(zcf.group_replallocrule(cf.facility,cf.custid,cf.productgroup),1,10)
from (select custfacility.custid,productgroup,facility
        from custfacility, custproductgroup
       where custfacility.custid = custproductgroup.custid) cf
union
select
cf.custid,
null,
cf.facility,
cf.profid,
cf.allocrule,
cf.replallocrule
from custfacility cf;

comment on table custproductgroupfacilityview is '$Id$';

create or replace view custitemfacilityview
(custid
,item
,facility
,profid
,allocrule
,replallocrule
)
as
select
cf.custid,
cf.item,
cf.facility,
substr(zcf.profid(cf.facility,cf.custid,cf.item),1,2),
substr(zcf.allocrule(cf.facility,cf.custid,cf.item),1,10),
substr(zcf.replallocrule(cf.facility,cf.custid,cf.item),1,10)
from (select custid,item,facility from facility,custitem) cf;

comment on table custitemfacilityview is '$Id$';

exit;

