create or replace view d_consignee as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.consignee Unique_Key,
  a.consignee,
  a.name,
  a.consigneestatus as status,
  a.contact,
  a.addr1 as address_1,
  a.addr2 as address_2,
  a.city,
  a.state,
  a.postalcode as zip_code,
  a.countrycode as country,
  a.phone,
  a.fax,
  a.email,
  a.billto as bill_to_yn,
  a.shipto as ship_to_yn,
  a.shiptype as shipment_type,
  b.abbrev as shipment_type_desc,
  a.shipterms as shipment_terms,
  c.abbrev as shipment_terms_desc,
  a.apptrequired as appt_required_yn,
  a.billforpallets as bill_for_pallets_yn,
  a.seal_required as seal_required_yn,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.consignee a, alps.shipmenttypes b, alps.shipmentterms c
where a.shiptype = b.code(+) and a.shipterms = c.code(+);