--
-- $Id: bbb_routing_parms.sql 1 2005-05-26 12:20:03Z ed $
--
create table bbb_routing_parms
(custid               varchar2(10) not null
,fromfacility         varchar2(3) not null
,shiptocountrycode    varchar2(10) not null
,shipto               varchar2(10) not null
,shiptype             char(1) not null
,effdate              date not null
,carton_count_min     number(6)
,carton_count_max     number(6)
,weight_min           number(6)
,weight_max           number(6)
,cube_min             number(6)
,cube_max             number(6)
,lastuser             varchar2(12)
,lastupdate           date
);

alter table bbb_routing_parms
  add constraint pk_bbb_routing_parms
  primary key(custid,fromfacility,shiptocountrycode,shipto,shiptype,effdate);

exit;
