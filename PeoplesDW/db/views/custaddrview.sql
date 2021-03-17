create or replace view custaddr
(
 custid,
 invtype,
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
 email
)
as
select custid,
       'R',
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
       decode(rcptname,null,email,rcptemail)
  from customer
UNION
select custid,
       'S',
       decode(rnewname,null,name,rnewname),
       decode(rnewname,null,contact,rnewcontact),
       decode(rnewname,null,addr1,rnewaddr1),
       decode(rnewname,null,addr2,rnewaddr2),
       decode(rnewname,null,city,rnewcity),
       decode(rnewname,null,state,rnewstate),
       decode(rnewname,null,postalcode,rnewpostalcode),
       decode(rnewname,null,countrycode,rnewcountrycode),
       decode(rnewname,null,phone,rcptphone),
       decode(rnewname,null,fax,rnewfax),
       decode(rnewname,null,email,rnewemail)
  from customer
UNION
select custid,
       'M',
       decode(miscname,null,name,miscname),
       decode(miscname,null,contact,misccontact),
       decode(miscname,null,addr1,miscaddr1),
       decode(miscname,null,addr2,miscaddr2),
       decode(miscname,null,city,misccity),
       decode(miscname,null,state,miscstate),
       decode(miscname,null,postalcode,miscpostalcode),
       decode(miscname,null,countrycode,misccountrycode),
       decode(miscname,null,phone,rcptphone),
       decode(miscname,null,fax,miscfax),
       decode(miscname,null,email,miscemail)
  from customer
UNION
select custid,
       'A',
       decode(outbname,null,name,outbname),
       decode(outbname,null,contact,outbcontact),
       decode(outbname,null,addr1,outbaddr1),
       decode(outbname,null,addr2,outbaddr2),
       decode(outbname,null,city,outbcity),
       decode(outbname,null,state,outbstate),
       decode(outbname,null,postalcode,outbpostalcode),
       decode(outbname,null,countrycode,outbcountrycode),
       decode(outbname,null,phone,rcptphone),
       decode(outbname,null,fax,outbfax),
       decode(outbname,null,email,outbemail)
  from customer;

comment on table custaddr is '$Id$';


exit;
