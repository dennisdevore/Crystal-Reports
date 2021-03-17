create or replace view custrcptview
(
custid,
name,
contact,
addr1,
addr2,
city,
state,
postalcode,
countrycode,
phone,
fax,
email,
tracktrailertemps
)
as
select
custid,
decode(rcptname,null,name,rcptname),
decode(rcptname,null,contact,rcptcontact),
decode(rcptname,null,addr1,rcptaddr1),
decode(rcptname,null,addr2,rcptaddr2),
decode(rcptname,null,city,rcptcity),
decode(rcptname,null,state,rcptstate),
decode(rcptname,null,postalcode,rcptpostalcode),
decode(rcptname,null,countrycode,rcptcountrycode),
decode(rcptname,null,phone,rcptphone),
decode(rcptname,null,fax,rcptfax),
decode(rcptname,null,email,rcptemail),
nvl(tracktrailertemps,'N')
from customer;

comment on table custrcptview is '$Id$';

exit;
