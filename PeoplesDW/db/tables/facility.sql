--
-- $Id$
--
drop table facility;

create table facility
(facility varchar2(3) not null
,name varchar2(40)
,addr1 varchar2(40)
,addr2 varchar2(40)
,city varchar2(30)
,state varchar2(2)
,postalcode varchar2(12)
,countrycode varchar2(3)
,phone varchar2(15)
,fax varchar2(15)
,lastuser varchar2(12)
,lastupdate date
,email varchar2(255)
,glid varchar2(20)
,campus varchar2(3)
);

create unique index facility_unique on
  facility(facility);
