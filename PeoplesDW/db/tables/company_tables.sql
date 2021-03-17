create table company
(company varchar2(12) not null
,name varchar2(40)
,addr1 varchar2(40)
,addr2 varchar2(40)
,city varchar2(30)
,state varchar2(5)
,postalcode varchar2(12)
,countrycode varchar2(3)
,phone varchar2(25)
,fax varchar2(25)
,email varchar2(255)
,manager varchar2(40)
,companystatus varchar2(1)
,remitname varchar2(40)
,remitaddr1 varchar2(40)
,remitaddr2 varchar2(40)
,remitcity varchar2(30)
,remitstate varchar2(5)
,remitpostalcode varchar2(12)
,remitcountrycode varchar2(3)
,chgfacility char(1)
,allcusts char(1)
,lastuser varchar2(12)
,lastupdate date
);
create unique index company_idx on company(company);
create table companycustomer
(company varchar2(12) not null
,custid  varchar2(10) not null
,lastuser varchar2(12)
,lastupdate date
);
create unique index companycustomer_idx on companycustomer(company,custid);
create table companyfacility
(company varchar2(12) not null
,facility varchar2(3) not null
,lastuser varchar2(12)
,lastupdate date
);
create unique index companyfacility_idx on companyfacility(company,facility);
create table companyorderlookup
(company varchar2(12) not null
,ordertypes varchar2(255)
,columnname varchar2(32)
,operator varchar2(12)
,columnvalues varchar2(4000)
,lastuser varchar2(12)
,lastupdate date
);
create index companyorderlookup_idx on companyorderlookup(company,ordertypes);
create table companyreports
(company varchar2(12) not null
,objectname varchar2(32) not null
,rptpath varchar2(255)
,lastuser varchar2(12)
,lastupdate date
);
create index companyreports_idx on companyreports(company,objectname);
exit;
