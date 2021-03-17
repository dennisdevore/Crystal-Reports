--drop table weber_tms_214_export;

create table weber_tms_214_export
(
  loadno                        number(7),
  stopno                        number(7),
  shipno                        number(7),
  orderid                       number(9),
  shipid                        number(2),
  orderid_shipid                varchar2(12),
  custid                        varchar2(10),
  facility                      varchar2(3),
  tms_shipment_id               varchar2(20),
  carrier                       varchar2(4),
  origin_alias                  varchar2(3),
  origin_name                   varchar2(40),
  origin_address1               varchar2(15),
  origin_address2               varchar2(40),
  origin_city                   varchar2(30),
  origin_state                  varchar2(5),
  origin_postalcode             varchar2(12),
  origin_countrycode            varchar2(3),
  dest_alias                    varchar2(10),
  dest_name                     varchar2(40),
  dest_address1                 varchar2(40),
  dest_address2                 varchar2(40),
  dest_city                     varchar2(30),
  dest_state                    varchar2(5),
  dest_postalcode               varchar2(12),
  dest_countrycode              varchar2(3),
  order_weight                  number(17,8),
  order_pallets                 number(10),
  order_volume                  number(10,4),
  event_date                    date,
  event_code                    varchar2(2)
);

--
-- $Id$
--
create index weber_tms_214_export_ordidx
   on weber_tms_214_export(orderid, shipid);

create index weber_tms_214_export_loadidx
   on weber_tms_214_export(loadno);

exit;

