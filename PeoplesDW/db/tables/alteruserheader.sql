--
-- $Id$
--
alter table userheader add
(title varchar2(40)
,addr1 varchar2(40)
,addr2 varchar2(40)
,city varchar2(30)
,state varchar2(2)
,postalcode varchar2(12)
,countrycode varchar2(3)
,phone varchar2(15)
,fax varchar2(15)
,email varchar2(255)
,tasktypeindicator varchar2(1)
,tasktypes varchar2(255)
);
exit;
