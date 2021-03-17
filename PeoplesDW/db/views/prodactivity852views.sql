create or replace view prodactv852hdr
(
    custid,
    start_date,
    end_date,
    warehouse_name,
    warehouse_id
)
as
select custid,
    start_date,
    end_date,
    warehouse_name,
    warehouse_id
  from prodactivity852hdrex;

comment on table prodactv852hdr is '$Id$';

create or replace view prodactv852dtl
(
   custid,
   warehouse_id,
   item
)
as
select distinct
   custid,
   warehouse_id,
   item
  from prodactivity852dtlex;

comment on table prodactv852dtl is '$Id$';

create or replace view prodactv852par
(
   custid,
   warehouse_id,
   item,
   activity_code,
   sequence,
   quantity,
   uom,
   ref_id_qualifier,
   ref_id,
   qty_qualifier
)
as
select
   custid,
   warehouse_id,
   item,
   activity_code,
   sequence,
   quantity,
   uom,
   ref_id_qualifier,
   ref_id,
   qty_qualifier
 from prodactivity852dtlex;

comment on table prodactv852par is '$Id$';

create or replace view prodactv852prq
(
   custid,
   warehouse_id,
   item,
   activity_code,
   sequence,
   assigned_number,
   dt_qualifier,
   activity_date,
   activity_time
)
as
select
   custid,
   warehouse_id,
   item,
   activity_code,
   sequence,
   assigned_number,
   dt_qualifier,
   activity_date,
   activity_time
 from prodactivity852dtlex;

comment on table prodactv852prq is '$Id$';

exit;


