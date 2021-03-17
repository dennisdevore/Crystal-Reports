--
-- $Id: bbb_carrier_assignment.sql 1 2005-05-26 12:20:03Z ed $
--
create table bbb_carrier_assignment
(custid varchar2(10) not null
,from_countrycode varchar2(3) not null
,from_state varchar2(2) not null
,to_countrycode varchar2(3) not null
,to_state varchar2(2) not null
,from_zipcode_match varchar2(2000) not null
,to_zipcode_match varchar2(2000) not null
,effdate date not null
,ltl_carrier varchar2(4) not null
,tl_carrier varchar2(4) not null
,lastuser varchar2(12)
,lastupdate date
,constraint pk_bbb_carrier_assignment primary key
(custid,from_countrycode,from_state,to_countrycode,to_state,from_zipcode_match,to_zipcode_match,effdate));
exit;
