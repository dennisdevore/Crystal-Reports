drop table bbb_routing_shipment;
drop table bbb_routing_shipment_tmp;
create global temporary table bbb_routing_shipment_tmp
(shiptocountrycode    varchar2(3) not null
,bbb_shipto_master    varchar2(10) not null
,order_shipto_master  varchar2(10)
,direct_to_store_yn   char(1) not null
,weight               number(17,8) not null
,cube                 number(10,4) not null
,carton_count         integer not null
,routing_status       varchar2(12) not null
,weight_max           number(17,8)
,cube_max             number(10,4)  
,carrier              varchar2(4)
,mileage              number(6)
) on commit delete rows;

create unique index bbb_routing_shipment_tmp_idx on
  bbb_routing_shipment_tmp(shiptocountrycode,bbb_shipto_master,order_shipto_master);
                       
drop table bbb_oversize_packages;                    
drop table bbb_oversize_packages_tmp;                    
create global temporary table bbb_oversize_packages_tmp
(shiptocountrycode    varchar2(3) not null
,bbb_shipto_master    varchar2(10) not null
,order_shipto_master  varchar2(10)
,oversize_carton_type varchar2(3) not null
,oversize_carton_count integer not null
) on commit delete rows;

create unique index bbb_oversize_packages_tmp_idx on
  bbb_oversize_packages_tmp(shiptocountrycode,bbb_shipto_master,order_shipto_master,
                        oversize_carton_type);

drop table bbb_excluded_orders;                        
drop table bbb_excluded_orders_tmp;                        
create global temporary table bbb_excluded_orders_tmp
(orderid              number(9) not null
,shipid               number(2) not null
) on commit delete rows;

create unique index bbb_excluded_orders_tmp_idx on
  bbb_excluded_orders_tmp(orderid,shipid);

drop table bbb_excluded_shipments;                      
drop table bbb_excluded_shipments_tmp;                      
create global temporary table bbb_excluded_shipments_tmp
(shiptocountrycode    varchar2(3) not null
,bbb_shipto_master    varchar2(10) not null
,order_shipto_master  varchar2(10)
,weight               number(17,8) not null
,cube                 number(10,4) not null
) on commit delete rows;

create unique index bbb_excluded_shipments_tmp_idx on
  bbb_excluded_shipments_tmp(shiptocountrycode,bbb_shipto_master,order_shipto_master);
                    
exit;
