--
-- $Id: consignee.sql 1 2005-05-26 12:20:03Z ed $
--
create table consignee_mileage
(consignee varchar2(10) not null
,fromfacility varchar2(3) not null
,mileage number(6)
,lastuser varchar2(12)
,lastupdate date
);

alter table consignee_mileage add
constraint pk_consignee_mileage primary key(consignee,fromfacility);

exit;
