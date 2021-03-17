create or replace view custconsigneesipnameview
(custid
,consignee
,sipname
,sipaddr
,sipcity
,sipstate
,sipzip
,sip_tradingpartnerid
)
as
select
cc.custid,
cc.consignee,
nvl(cn.sipname,substr(co.name,1,10)),
nvl(cn.sipaddr,substr(co.addr1,1,4)),
nvl(cn.sipcity,substr(co.city,1,10)),
nvl(cn.sipstate,co.state),
nvl(cn.sipzip,substr(co.postalcode,1,5)),
cc.sip_tradingpartnerid
from consignee co, custconsigneesipname cn, custconsignee cc
where cc.custid = cn.custid
  and cc.consignee = cn.consignee
  and cc.consignee = co.consignee
union
select
cc.custid,
cc.consignee,
substr(upper(co.name),1,10),
substr(upper(co.addr1),1,4),
substr(upper(co.city),1,10),
upper(co.state),
substr(upper(co.postalcode),1,5),
cc.sip_tradingpartnerid
from consignee co, custconsignee cc
where cc.consignee = co.consignee;

comment on table custconsigneesipnameview is '$Id$';

--exit;

