create or replace package body alps.zimportproc11 as
--
-- $Id$
--

procedure import_carrier
(in_carrier IN varchar2
,in_carrierstatus IN varchar2
,in_scac IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_carriertype IN varchar2
,in_multiship IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_carrier) is null then
   out_errorno := -1;
   out_msg := 'Carrier value is required';
   return;
   end if;

insert into carrier
(carrier, carrierstatus, scac, name, contact, addr1, addr2, city,
state, postalcode, countrycode, phone, fax, email, carriertype, multiship, lastuser, lastupdate)
values
(in_carrier, in_carrierstatus, in_scac, in_name, in_contact, in_addr1, in_addr2,
 in_city, in_state, in_postalcode, in_countrycode, in_phone, in_fax, in_email,
 in_carriertype, in_multiship, 'CONV', sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
 out_msg := 'zimic' || sqlerrm;
 out_errorno := sqlcode;
end import_carrier;

procedure import_section
(in_facility IN varchar2
,in_sectionid IN varchar2
,in_sectionnw IN varchar2
,in_sectionn IN varchar2
,in_sectionne IN varchar2
,in_sectione IN varchar2
,in_sectionse IN varchar2
,in_sections IN varchar2
,in_sectionsw IN varchar2
,in_sectionw IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_sectionid) is null then
     out_errorno := -1;
     out_msg := 'Section ID value is required';
     return;
end if;

insert into section
(facility, sectionid, sectionnw, sectionn, sectionne, sectione, sectionse, sections, sectionsw, sectionw, lastuser, lastupdate)
values
(in_facility, in_sectionid, in_sectionnw, in_sectionn, in_sectionne, in_sectione, in_sectionse, in_sections, in_sectionsw, in_sectionw, 'CONV', sysdate);


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'simis' || sqlerrm;
  out_errorno := sqlcode;
end import_section;

procedure import_zones
(in_facility IN varchar2
,in_zoneid IN varchar2
,in_description IN varchar2
,in_panddlocation IN varchar2
,in_picktype IN varchar2
,in_pickdirection IN varchar2
,in_nextlinepickby IN varchar2
,in_abbrev IN varchar2
,in_pickconfirmlocation IN varchar2
,in_pickconfirmitem IN varchar2
,in_pickconfirmcontainer IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_zoneid) is null then
    out_errorno := -1;
    out_msg := 'Zone ID value is required';
    return;
end if;

insert into zone
(facility, zoneid, description, panddlocation, lastuser, lastupdate, picktype, pickdirection, nextlinepickby, abbrev, pickconfirmlocation, pickconfirmitem, pickconfirmcontainer)
values
(in_facility, in_zoneid, in_description, in_panddlocation, 'CONV', sysdate, in_picktype, in_pickdirection, in_nextlinepickby, in_abbrev, in_pickconfirmlocation, in_pickconfirmitem, in_pickconfirmcontainer);


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
   out_msg := 'zimiz' || sqlerrm;
   out_errorno := sqlcode;
end import_zones;

procedure import_customernames
(in_custid IN varchar2
,in_status IN varchar2
,in_name IN varchar2
,in_lookup IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_csr IN varchar2
,in_dup_reference_ynw IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
   out_errorno := -1;
   out_msg := 'Customer ID value is required';
   return;
end if;

if rtrim(in_name) is null then
   out_errorno := -1;
   out_msg := 'Name value is required';
   return;
end if;

insert into customer
(custid, status, name, lookup, contact, addr1, addr2, city, state, postalcode,
countrycode, phone, fax, email, csr, lastuser, lastupdate, dup_reference_ynw)
values
(in_custid, in_status, in_name, in_lookup, in_contact, in_addr1, in_addr2,
 in_city, in_state, in_postalcode, in_countrycode, in_phone, in_fax, in_email,
 in_csr, 'CONV', sysdate, in_dup_reference_ynw);


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
   out_msg := 'zimicn' || sqlerrm;
   out_errorno := sqlcode;
end import_customernames;

procedure import_shippingoptions1
(in_custid IN varchar2
,in_item IN varchar2
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_fifowindowdays IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;

if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

update custitem
set backorder = in_backorder,
    allowsub = in_allowsub,
    invstatusind = in_invstatusind,
    invstatus = in_invstatus,
    invclassind = in_invclassind,
    inventoryclass = in_inventoryclass,
    fifowindowdays = in_fifowindowdays
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimis1' || sqlerrm;
    out_errorno := sqlcode;
end import_shippingoptions1;

procedure import_itemshipopt1_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_fifowindowdays IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_shipopt1_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_shipopt1_table
  (load_sequence, record_sequence, custid, item,
   backorder,allowsub,invstatusind,invstatus,
   invclassind,inventoryclass,fifowindowdays)
  values
  (0, recseq, in_custid, in_item,
   in_backorder,in_allowsub,in_invstatusind,in_invstatus,
   in_invclassind,in_inventoryclass,in_fifowindowdays);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimis1v ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemshipopt1_validation;
procedure end_itemshipopt1_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_shipopt1_table%rowtype
is
  select *
    from import_item_shipopt1_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_shipopt1_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_shipopt1_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_shipopt1_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.allowsub is not null then
   if ii.allowsub not in    ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Allowsub: ' || ii.allowsub);
   end if;
end if;
if ii.invstatusind is not null then
   if ii.invstatusind not in    ('I','E','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Inventory Status Indicator: ' || ii.invstatusind);
   end if;
end if;
if ii.invclassind is not null then
   if ii.invclassind not in    ('I','E','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Inventory class Indicator: ' || ii.invclassind);
   end if;
end if;
if ii.backorder is not null then
   select count(1) into cntRows
      from backorderpolicy
      where code = ii.backorder;
   if cntRows = 0 then
      out_err := out_err + 1;
     err_msg(ii, 'Invalid backorder policy: ' || ii.backorder);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpis1 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_shipopt1_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set backorder = ii.backorder,
    allowsub = ii.allowsub,
    invstatusind = ii.invstatusind,
    invstatus = ii.invstatus,
    invclassind = ii.invclassind,
    inventoryclass = ii.inventoryclass,
    fifowindowdays = ii.fifowindowdays,
	lastupdate = sysdate,
	lastuser = 'IMPEXP-IS1'
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_shipopt1_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_shipopt1_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemship1', 0, ' ', 'Item Receipt Options 1 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemship1', strMsg);
   update import_item_shipopt1_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
   -- perform validation
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('impitemship1', 0, ' ', 'Item Receipt Options 1 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemship1', strMsg);
end end_itemshipopt1_validation;
procedure import_custdictionary
(in_custid IN varchar2
,in_fieldname IN varchar2
,in_labelvalue IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;

if rtrim(in_fieldname) is null then
    out_errorno := -1;
    out_msg := 'Fieldname value is required';
    return;
end if;

if rtrim(in_labelvalue) is null then
   out_errorno := -1;
   out_msg := 'Labelvalue value is required';
   return;
end if;

insert into custdict
(custid, fieldname, labelvalue, lastuser, lastupdate)
values
(in_custid, in_fieldname, in_labelvalue, 'CONV', sysdate);

 out_msg := 'OKAY';
 out_errorno := 0;

exception when others then
   out_msg := 'zimicd' || sqlerrm;
   out_errorno := sqlcode;
end import_custdictionary;

procedure import_consigneename
(in_consignee IN varchar2
,in_consigneestatus IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_countrycode IN varchar2
,in_phone IN varchar2
,in_fax IN varchar2
,in_email IN varchar2
,in_billto IN varchar2
,in_shipto IN varchar2
,in_billtoconsignee IN varchar2
,in_shiptype IN varchar2
,in_shipterms IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_consignee) is null then
    out_errorno := -1;
    out_msg := 'Consignee value is required';
    return;
end if;

insert into consignee
(consignee, consigneestatus, name, contact, addr1, addr2, city, state, postalcode, countrycode, phone, fax, email, billto, shipto, billtoconsignee, shiptype, shipterms, lastuser, lastupdate)
values
(in_consignee, in_consigneestatus, in_name, in_contact, in_addr1, in_addr2, in_city, in_state, in_postalcode, in_countrycode, in_phone, in_fax, in_email, in_billto, in_shipto, in_billtoconsignee, in_shiptype, in_shipterms, 'CONV', sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimicn' || sqlerrm;
  out_errorno := sqlcode;
end import_consigneename;

procedure import_consigneecarriers
(in_consignee IN varchar2
,in_tlcarrier IN varchar2
,in_ltlcarrier IN varchar2
,in_spscarrier IN varchar2
,in_railcarrier IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_consignee) is null then
    out_errorno := -1;
    out_msg := 'Consignee value is required';
    return;
end if;

update consignee
set tlcarrier = in_tlcarrier,
    ltlcarrier = in_ltlcarrier,
    spscarrier = in_spscarrier,
    railcarrier = in_railcarrier,
    lastuser = 'sup',
    lastupdate = sysdate
where consignee = in_consignee;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimicc' || sqlerrm;
    out_errorno := sqlcode;
end import_consigneecarriers;

procedure import_itemname
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_rategroup IN varchar2
,in_status IN varchar2
,in_needs_review_yn IN varchar2
,in_iskit IN varchar2
,in_require_cyclecount_item IN varchar2
,in_require_cyclecount_lot IN varchar2
,in_require_phyinv_item IN varchar2
,in_require_phyinv_lot IN varchar2 
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


if rtrim(in_descr) is  null then
    out_errorno := -1;
    out_msg := 'Description value is required';
    return;
end if;


if rtrim(in_rategroup) is null then
    out_errorno := -1;
    out_msg := 'Rategroup value is required';
    return;
end if;


if rtrim(in_status) is null then
    out_errorno := -1;
    out_msg := 'Status value is required';
    return;
end if;

insert into custitem
(custid, item, descr, abbrev, status, rategroup, hazardous, iskit, needs_review_yn, 
 require_cyclecount_item, require_cyclecount_lot, require_phyinv_item, 
 require_phyinv_lot, lastuser, lastupdate)
select in_custid,
       in_item,
       in_descr,
       in_abbrev,
       in_status,
       in_rategroup,
       'N',
       'N',
       in_needs_review_yn,
       in_require_cyclecount_item, 
	   in_require_cyclecount_lot, 
	   in_require_phyinv_item, 
	   in_require_phyinv_lot,
       'CONV',
       sysdate
from dual;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'ziminm' || sqlerrm;
    out_errorno := sqlcode;
end import_itemname;

procedure import_itemname_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_rategroup IN varchar2
,in_status IN varchar2
,in_needs_review_yn IN varchar2
,in_iskit IN varchar2
,in_require_cyclecount_item IN varchar2
,in_require_cyclecount_lot IN varchar2
,in_require_phyinv_item IN varchar2
,in_require_phyinv_lot IN varchar2 
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_name_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_name_table
  (load_sequence, record_sequence, custid, item,
   descr,abbrev,rategroup,status,needs_review_yn,
   iskit,require_cyclecount_item,require_cyclecount_lot,
   require_phyinv_item,require_phyinv_lot)
  values
  (0, recseq, in_custid, in_item,
   in_descr,in_abbrev,in_rategroup,in_status,in_needs_review_yn,
   in_iskit,in_require_cyclecount_item,in_require_cyclecount_lot,
   in_require_phyinv_item,in_require_phyinv_lot);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'ziminmv' || sqlerrm;
    out_errorno := sqlcode;
end import_itemname_validation;
procedure end_itemname_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_name_table%rowtype
is
  select *
    from import_item_name_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_name_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_name_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_name_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows > 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item already exists. ');
end if;
if ii.rategroup is null then
  out_err := out_err + 1;
  err_msg(ii, 'Rategroup value is required. ');
end if;
if ii.rategroup is not null and
   ii.rategroup <> 'C' then
   select count(1) into cntRows
      from custrategroup
      where custid = ii.custid
        and rategroup = ii.rategroup;
  if cntRows = 0 then
     out_err := out_err + 1;
     err_msg(ii, 'Invalid Rategroup: ' || ii.rategroup);
  end if;
end if;
select count(1) into cntRows
   from itemstatus
   where code = nvl(ii.status, 'ACTV');
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Status: ' || ii.status);
end if;
if nvl(ii.needs_review_yn,'N') not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Needs Review: ' || ii.needs_review_yn);
end if;
if ii.iskit is not null and
   ii.iskit not in ('K','C','S','I','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Is Kit: ' || ii.iskit);
end if;
if ii.require_cyclecount_item is not null and
   ii.require_cyclecount_item not in ('Y','N','C') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Require Cycle Count Item: ' || ii.require_cyclecount_item);
end if;
if ii.require_cyclecount_lot is not null and
   ii.require_cyclecount_lot not in ('Y','N','C') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Require Cycle Count Lot: ' || ii.require_cyclecount_lot);
end if;
if ii.require_phyinv_item is not null and
   ii.require_phyinv_item not in ('Y','N','C') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Require Phyinv Item: ' || ii.require_phyinv_item);
end if;
if ii.require_phyinv_lot is not null and
   ii.require_phyinv_lot not in ('Y','N','C') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Require Phyinv Lot: ' || ii.require_phyinv_lot);
end if;
return out_err;
exception when others then
  out_msg := 'zimpinm ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_name_table%rowtype)
is
out_err integer;
cntRows integer;
begin
insert into custitem
(custid, item, descr, abbrev, status, rategroup, hazardous,
 needs_review_yn, iskit, require_cyclecount_item, require_cyclecount_lot,
 require_phyinv_item, require_phyinv_lot, lastuser, lastupdate)
values
(ii.custid, ii.item, ii.descr, ii.abbrev, nvl(ii.status,'ACTV'), ii.rategroup, 'N',
 nvl(ii.needs_review_yn,'N'), 'N', ii.require_cyclecount_item, ii.require_cyclecount_lot,
 ii.require_phyinv_item, ii.require_phyinv_lot, 'CONV', sysdate);
 end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_name_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_name_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemname', 0, ' ', 'Item Name Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemname', strMsg);
   update import_item_name_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIname', 0, ' ', 'Item Name Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemname', strMsg);
end end_itemname_validataion;
procedure import_itemspecs
(in_custid IN varchar2
,in_item IN varchar2
,in_shelflife IN number
,in_expiryaction IN varchar2
,in_profid IN varchar2
,in_labeluom IN varchar2
,in_productgroup IN varchar2
,in_nmfc IN varchar2
,in_lotsumreceipt IN varchar2
,in_lotsumrenewal IN varchar2
,in_lotsumbol IN varchar2
,in_lotsumaccess IN varchar2
,in_ltlfc IN varchar2
,in_countryof IN varchar2
,in_hazardous IN varchar2
,in_stackheight IN number
,in_stackheightuom in varchar2
,in_reorderqty IN number
,in_unitsofstorage IN varchar2
,in_nmfc_article IN varchar2
,in_tms_commodity_code IN varchar2
,in_itmpassthruchar01 IN varchar2
,in_itmpassthruchar02 IN varchar2
,in_itmpassthruchar03 IN varchar2
,in_itmpassthruchar04 IN varchar2
,in_itmpassthruchar05 IN varchar2
,in_itmpassthruchar06 IN varchar2
,in_itmpassthruchar07 IN varchar2
,in_itmpassthruchar08 IN varchar2
,in_itmpassthruchar09 IN varchar2
,in_itmpassthruchar10 IN varchar2
,in_itmpassthrunum01 IN number
,in_itmpassthrunum02 IN number
,in_itmpassthrunum03 IN number
,in_itmpassthrunum04 IN number
,in_itmpassthrunum05 IN number
,in_itmpassthrunum06 IN number
,in_itmpassthrunum07 IN number
,in_itmpassthrunum08 IN number
,in_itmpassthrunum09 IN number
,in_itmpassthrunum10 IN number
,in_use_fifo IN varchar2
,in_labelqty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

update custitem
set shelflife = in_shelflife,
    expiryaction = in_expiryaction,
    profid = in_profid,
    labeluom = in_labeluom,
    productgroup = in_productgroup,
    nmfc = in_nmfc,
    lotsumreceipt = nvl(rtrim(in_lotsumreceipt),'N'),
    lotsumrenewal = nvl(rtrim(in_lotsumrenewal),'N'),
    lotsumbol = nvl(rtrim(in_lotsumbol),'N'),
    lotsumaccess = nvl(rtrim(in_lotsumaccess),'N'),
    ltlfc = in_ltlfc,
    countryof = in_countryof,
    hazardous = nvl(rtrim(in_hazardous),'N'),
    stackheight = in_stackheight,
    stackheightuom = in_stackheightuom,
    reorderqty = in_reorderqty,
    --iskit = 'N',
    unitsofstorage = in_unitsofstorage,
    nmfc_article = in_nmfc_article,
    tms_commodity_code = in_tms_commodity_code,
    itmpassthruchar01 = in_itmpassthruchar01,
    itmpassthruchar02 = in_itmpassthruchar02,
    itmpassthruchar03 = in_itmpassthruchar03,
    itmpassthruchar04 = in_itmpassthruchar04,
    itmpassthruchar05 = in_itmpassthruchar05,
    itmpassthruchar06 = in_itmpassthruchar06,
    itmpassthruchar07 = in_itmpassthruchar07,
    itmpassthruchar08 = in_itmpassthruchar08,
    itmpassthruchar09 = in_itmpassthruchar09,
    itmpassthruchar10 = in_itmpassthruchar10,
    itmpassthrunum01 = in_itmpassthrunum01,
    itmpassthrunum02 = in_itmpassthrunum02,
    itmpassthrunum03 = in_itmpassthrunum03,
    itmpassthrunum04 = in_itmpassthrunum04,
    itmpassthrunum05 = in_itmpassthrunum05,
    itmpassthrunum06 = in_itmpassthrunum06,
    itmpassthrunum07 = in_itmpassthrunum07,
    itmpassthrunum08 = in_itmpassthrunum08,
    itmpassthrunum09 = in_itmpassthrunum09,
    itmpassthrunum10 = in_itmpassthrunum10,
	use_fifo = in_use_fifo,
	labelqty = in_labelqty
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimisp1' || sqlerrm;
    out_errorno := sqlcode;
end import_itemspecs;

procedure import_itemspecs_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_shelflife IN number
,in_expiryaction IN varchar2
,in_profid IN varchar2
,in_labeluom IN varchar2
,in_productgroup IN varchar2
,in_nmfc IN varchar2
,in_lotsumreceipt IN varchar2
,in_lotsumrenewal IN varchar2
,in_lotsumbol IN varchar2
,in_lotsumaccess IN varchar2
,in_ltlfc IN varchar2
,in_countryof IN varchar2
,in_hazardous IN varchar2
,in_stackheight IN number
,in_stackheightuom in varchar2
,in_reorderqty IN number
,in_unitsofstorage IN varchar2
,in_nmfc_article IN varchar2
,in_tms_commodity_code IN varchar2
,in_itmpassthruchar01 IN varchar2
,in_itmpassthruchar02 IN varchar2
,in_itmpassthruchar03 IN varchar2
,in_itmpassthruchar04 IN varchar2
,in_itmpassthruchar05 IN varchar2
,in_itmpassthruchar06 IN varchar2
,in_itmpassthruchar07 IN varchar2
,in_itmpassthruchar08 IN varchar2
,in_itmpassthruchar09 IN varchar2
,in_itmpassthruchar10 IN varchar2
,in_itmpassthrunum01 IN number
,in_itmpassthrunum02 IN number
,in_itmpassthrunum03 IN number
,in_itmpassthrunum04 IN number
,in_itmpassthrunum05 IN number
,in_itmpassthrunum06 IN number
,in_itmpassthrunum07 IN number
,in_itmpassthrunum08 IN number
,in_itmpassthrunum09 IN number
,in_itmpassthrunum10 IN number
,in_use_fifo IN varchar2
,in_labelqty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_specs_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_specs_table
  (load_sequence,  record_sequence, custid, item,
   shelflife, expiryaction,profid,labeluom,productgroup,nmfc,
   lotsumreceipt,lotsumrenewal,lotsumbol,lotsumaccess,ltlfc,
   countryof,hazardous,stackheight,stackheightuom,reorderqty,
   unitsofstorage,nmfc_article,tms_commodity_code,
   itmpassthruchar01,itmpassthruchar02,itmpassthruchar03,itmpassthruchar04,itmpassthruchar05,
   itmpassthruchar06,itmpassthruchar07,itmpassthruchar08,itmpassthruchar09,itmpassthruchar10,
   itmpassthrunum01,itmpassthrunum02,itmpassthrunum03,itmpassthrunum04,itmpassthrunum05,
   itmpassthrunum06,itmpassthrunum07,itmpassthrunum08,itmpassthrunum09,itmpassthrunum10,
   use_fifo, labelqty)
  values
  (0, recseq, in_custid, in_item,
   in_shelflife, in_expiryaction,in_profid,in_labeluom,in_productgroup,in_nmfc,
   in_lotsumreceipt,in_lotsumrenewal,in_lotsumbol,in_lotsumaccess,in_ltlfc,
   in_countryof,in_hazardous,in_stackheight,in_stackheightuom,in_reorderqty,
   in_unitsofstorage,in_nmfc_article,in_tms_commodity_code,
   in_itmpassthruchar01,in_itmpassthruchar02,in_itmpassthruchar03,in_itmpassthruchar04,in_itmpassthruchar05,
   in_itmpassthruchar06,in_itmpassthruchar07,in_itmpassthruchar08,in_itmpassthruchar09,in_itmpassthruchar10,
   in_itmpassthrunum01,in_itmpassthrunum02,in_itmpassthrunum03,in_itmpassthrunum04,in_itmpassthrunum05,
   in_itmpassthrunum06,in_itmpassthrunum07,in_itmpassthrunum08,in_itmpassthrunum09,in_itmpassthrunum10,
   in_use_fifo, in_labelqty);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimisp1v' || sqlerrm;
    out_errorno := sqlcode;
end import_itemspecs_validation;
procedure end_itemspecs_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_specs_table%rowtype
is
  select *
    from import_item_specs_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_specs_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_specs_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_specs_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.expiryaction is not null then
   select count(1) into cntRows
      from expirationactions
      where code = ii.expiryaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Expiry Action ' || ii.expiryaction);
   end if;
end if;
if ii.productgroup is not null then
   select count(1) into cntRows
      from custproductgroup
      where productgroup = ii.productgroup
        and custid = ii.custid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Product Group: ' || ii.productgroup);
   end if;
end if;
if ii.nmfc is not null then
   select count(1) into cntRows
      from nmfclasscodes
      where nmfc = ii.nmfc;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid NMFC: ' || ii.nmfc);
   end if;
end if;
if ii.lotsumreceipt is not null and
   ii.lotsumreceipt not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid LotSumReceipt: ' || ii.lotsumreceipt);
end if;
if ii.lotsumrenewal is not null and
   ii.lotsumrenewal not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid lotsumrenewal: ' || ii.lotsumrenewal);
end if;
if ii.lotsumbol is not null and
   ii.lotsumbol not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid lotsumbol: ' || ii.lotsumbol);
end if;
if ii.lotsumaccess is not null and
   ii.lotsumaccess not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid lotsumaccess: ' || ii.lotsumaccess);
end if;
if ii.hazardous is not null and
   ii.hazardous not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid hazardous: ' || ii.hazardous);
end if;
if ii.ltlfc is not null then
   select count(1) into cntRows
      from ltlfreightclass
      where code = ii.ltlfc;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid LTLFC: ' || ii.ltlfc);
   end if;
end if;
if ii.countryof is not null then
   select count(1) into cntRows
      from countrycodes
      where code = ii.countryof;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Country Of: ' || ii.countryof);
   end if;
end if;
if ii.labeluom is not null then
   select count(1) into cntRows
      from unitsofmeasure
      where code = ii.labeluom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Label Uom: ' || ii.labeluom);
   end if;
end if;
if ii.stackheightuom is not null then
   select count(1) into cntRows
      from unitsofmeasure
      where code = ii.stackheightuom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Stackheight Uom: ' || ii.stackheightuom);
   end if;
end if;
if ii.use_fifo is not null then
   if ii.use_fifo not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Use FIFO: ' || ii.use_fifo);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpisp1 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_specs_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set shelflife = ii.shelflife,
    expiryaction = ii.expiryaction,
    profid = ii.profid,
    labeluom = ii.labeluom,
    productgroup = ii.productgroup,
    nmfc = ii.nmfc,
    lotsumreceipt = nvl(rtrim(ii.lotsumreceipt),'N'),
    lotsumrenewal = nvl(rtrim(ii.lotsumrenewal),'N'),
    lotsumbol = nvl(rtrim(ii.lotsumbol),'N'),
    lotsumaccess = nvl(rtrim(ii.lotsumaccess),'N'),
    ltlfc = ii.ltlfc,
    countryof = ii.countryof,
    hazardous = nvl(rtrim(ii.hazardous),'N'),
    stackheight = ii.stackheight,
    stackheightuom = ii.stackheightuom,
    reorderqty = ii.reorderqty,
    --iskit = 'N',
    unitsofstorage = ii.unitsofstorage,
    nmfc_article = ii.nmfc_article,
    tms_commodity_code = ii.tms_commodity_code,
    itmpassthruchar01 = ii.itmpassthruchar01,
    itmpassthruchar02 = ii.itmpassthruchar02,
    itmpassthruchar03 = ii.itmpassthruchar03,
    itmpassthruchar04 = ii.itmpassthruchar04,
    itmpassthruchar05 = ii.itmpassthruchar05,
    itmpassthruchar06 = ii.itmpassthruchar06,
    itmpassthruchar07 = ii.itmpassthruchar07,
    itmpassthruchar08 = ii.itmpassthruchar08,
    itmpassthruchar09 = ii.itmpassthruchar09,
    itmpassthruchar10 = ii.itmpassthruchar10,
    itmpassthrunum01 = ii.itmpassthrunum01,
    itmpassthrunum02 = ii.itmpassthrunum02,
    itmpassthrunum03 = ii.itmpassthrunum03,
    itmpassthrunum04 = ii.itmpassthrunum04,
    itmpassthrunum05 = ii.itmpassthrunum05,
    itmpassthrunum06 = ii.itmpassthrunum06,
    itmpassthrunum07 = ii.itmpassthrunum07,
    itmpassthrunum08 = ii.itmpassthrunum08,
    itmpassthrunum09 = ii.itmpassthrunum09,
    itmpassthrunum10 = ii.itmpassthrunum10,
	use_fifo = ii.use_fifo,
	labelqty = ii.labelqty
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_specs_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_specs_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impispec', 0, ' ', 'Item Spec Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impispec', strMsg);
   update import_item_specs_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpISpec', 0, ' ', 'Item Specs Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impispec', strMsg);
end end_itemspecs_validataion;
procedure import_itemspecs2
(in_custid                  IN varchar2
,in_item                    IN varchar2
,in_allow_uom_chgs          IN varchar2
,in_min_sale_life           IN number
,in_min0qtysuspenseweight   IN number
,in_stacking_factor         IN varchar2
,in_treat_labeluom_separate IN varchar2
,out_errorno                IN OUT number
,out_msg                    IN OUT varchar2
) is
begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;
if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;
update custitem
set allow_uom_chgs = in_allow_uom_chgs,
    min_sale_life = in_min_sale_life,
    min0qtysuspenseweight = in_min0qtysuspenseweight,
    stacking_factor = in_stacking_factor,
    treat_labeluom_separate = nvl(rtrim(in_treat_labeluom_separate),'N')
where custid = in_custid
  and item = in_item;
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimisp2' || sqlerrm;
    out_errorno := sqlcode;
end import_itemspecs2;
procedure import_itemspecs2_validation
(in_custid                  IN varchar2
,in_item                    IN varchar2
,in_allow_uom_chgs          IN varchar2
,in_min_sale_life           IN number 
,in_min0qtysuspenseweight   IN number
,in_stacking_factor         IN varchar2
,in_treat_labeluom_separate IN varchar2
,out_errorno                IN OUT number
,out_msg                    IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
  from import_item_specs2_table
 where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_specs2_table
  (load_sequence, record_sequence, custid, item,
   allow_uom_chgs, min_sale_life, min0qtysuspenseweight,
   stacking_factor, treat_labeluom_separate)
  values
  (0, recseq, in_custid, in_item,
   in_allow_uom_chgs, in_min_sale_life, in_min0qtysuspenseweight,
   in_stacking_factor, in_treat_labeluom_separate);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimisp2v' || sqlerrm;
    out_errorno := sqlcode;
end import_itemspecs2_validation;
procedure end_itemspecs2_validataion
(in_update   IN varchar2
,out_errorno IN OUT number
,out_msg     IN OUT varchar2
) is
ii_max  integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg  varchar2(255);
cursor C_II(in_seq integer)
return import_item_specs2_table%rowtype
is
  select *
    from import_item_specs2_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_specs2_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_specs2_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_specs2_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.allow_uom_chgs is not null then
   if ii.allow_uom_chgs not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Allow UOM Changs: ' || ii.allow_uom_chgs);
   end if;
end if;
if ii.treat_labeluom_separate is not null then
   if ii.treat_labeluom_separate not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Treat Label UOM Separate: ' || ii.treat_labeluom_separate);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpispec2 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_specs2_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set allow_uom_chgs = ii.allow_uom_chgs,
    min_sale_life = ii.min_sale_life,
    min0qtysuspenseweight = ii.min0qtysuspenseweight,
    stacking_factor = ii.stacking_factor,
    treat_labeluom_separate = ii.treat_labeluom_separate,
	lastupdate = sysdate,
	lastuser = 'IMPEXP-ISP2'
where custid = ii.custid
  and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_specs2_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_specs2_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impispec2', 0, ' ', 'Item Spec2 Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impispec', strMsg);
   update import_item_specs2_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpISpec2', 0, ' ', 'Item Specs2 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impispec2', strMsg);
end end_itemspecs2_validataion;
procedure import_itembaseuom
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_weight IN number
,in_cube IN number
,in_useramt1 IN number
,in_useramt2 IN number
,in_tareweight IN number
,in_velocity IN varchar2
,in_picktotype IN varchar2
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_pallet_qty IN number
,in_pallet_uom IN varchar2
,in_pallet_name IN varchar2
,in_limit_pallet_to_qty_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set baseuom = in_baseuom,
    weight = in_weight,
    cube = in_cube,
    useramt1 = in_useramt1,
    useramt2 = in_useramt2,
    tareweight = in_tareweight,
    velocity = in_velocity,
    picktotype = in_picktotype,
    cartontype = in_cartontype,
    length = in_length,
    width = in_width,
    height = in_height,
	pallet_qty = in_pallet_qty,
	pallet_uom = in_pallet_uom,
	pallet_name = in_pallet_name,
	limit_pallet_to_qty_yn = nvl(rtrim(in_limit_pallet_to_qty_yn),'N')
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimibu' || sqlerrm;
    out_errorno := sqlcode;
end import_itembaseuom;

procedure import_itembaseuom_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_weight IN number
,in_cube IN number
,in_useramt1 IN number
,in_useramt2 IN number
,in_tareweight IN number
,in_velocity IN varchar2
,in_picktotype IN varchar2
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_pallet_qty IN number
,in_pallet_uom IN varchar2
,in_pallet_name IN varchar2
,in_limit_pallet_to_qty_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_baseuom_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_baseuom_table
  (load_sequence,  record_sequence,  custid,
   item, baseuom, weight, cube, useramt1,
   useramt2, tareweight, velocity, picktotype,
   cartontype, length, width, height,
   pallet_qty, pallet_uom, pallet_name, limit_pallet_to_qty_yn)
  values
  (0, recseq, in_custid,
   in_item, in_baseuom, in_weight, in_cube, in_useramt1,
   in_useramt2, in_tareweight, in_velocity, in_picktotype,
   in_cartontype, in_length, in_width, in_height,
   in_pallet_qty, in_pallet_uom, in_pallet_name, in_limit_pallet_to_qty_yn);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimibuv' || sqlerrm;
    out_errorno := sqlcode;
end import_itembaseuom_validation;
procedure end_itembaseuom_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_baseuom_table%rowtype
is
  select *
    from import_item_baseuom_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_baseuom_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_baseuom_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_baseuom_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
select count(1) into cntRows
   from unitsofmeasure
   where code = ii.baseuom;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Base Uom: ' || ii.baseuom);
end if;
if ii.velocity is not null then
   select count(1) into cntRows
     from itemvelocitycodes
     where code = ii.velocity;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Velocity: ' || ii.velocity);
   end if;
else
   out_err := out_err + 1;
   err_msg(ii, 'Velocity is required ');
end if;
if ii.weight is null or ii.weight = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Weight is required ');
end if;
if ii.cube is null or ii.cube = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Cube is required ');
end if;
if ii.cartontype is null then
   out_err := out_err + 1;
   err_msg(ii, 'Carton (container) Type is required ');
else
   select count(1) into cntRows
     from cartontypes
     where code = ii.cartontype;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Carton (container) Type: ' || ii.cartontype);
   end if;
end if;
if ii.picktotype is null then
   out_err := out_err + 1;
   err_msg(ii, 'Pick to Type is required ');
else
   select count(1) into cntRows
     from picktotypes
     where code = ii.picktotype;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Pick to Type: ' || ii.picktotype);
   end if;
end if;
if ii.pallet_qty is null and
   (ii.pallet_UOM is not null or ii.limit_pallet_to_qty_yn = 'Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Pallet To Quantity: ' || ii.pallet_qty);
end if;
if ii.pallet_uom is not null then
   select count(1) into cntRows
     from unitsofmeasure
     where code = ii.pallet_uom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Pallet UOM: ' || ii.pallet_uom);
   end if;
end if;
if ii.pallet_name is not null then
   select count(1) into cntRows
     from pallettypes
     where abbrev = ii.pallet_name;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Pallet Name: ' || ii.pallet_name);
   end if;
end if;
if ii.limit_pallet_to_qty_yn is not null and
   ii.limit_pallet_to_qty_yn not in ('Y','N') then
     out_err := out_err + 1;
     err_msg(ii, 'Invalid Pallet To Quantity: ' || ii.limit_pallet_to_qty_yn);
end if;
return out_err;
exception when others then
  out_msg := 'zimpiuom ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_baseuom_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set baseuom = ii.baseuom,
    weight = ii.weight,
    cube = ii.cube,
    useramt1 = ii.useramt1,
    useramt2 = ii.useramt2,
    tareweight = ii.tareweight,
    velocity = ii.velocity,
    picktotype = ii.picktotype,
    cartontype = ii.cartontype,
    length = ii.length,
    width = ii.width,
    height = ii.height,
	pallet_qty = ii.pallet_qty,
	pallet_uom = ii.pallet_uom,
	pallet_name = ii.pallet_name,
	limit_pallet_to_qty_yn = ii.limit_pallet_to_qty_yn
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_baseuom_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_baseuom_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemuom', 0, ' ', 'Item Base Uom Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemuom', strMsg);
   update import_item_baseuom_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIBuom', 0, ' ', 'Item Baseuom Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemuom', strMsg);
end end_itembaseuom_validataion;
procedure import_itemuomsequences
(in_custid IN varchar2
,in_item IN varchar2
,in_sequence IN number
,in_qty IN number
,in_fromuom IN varchar2
,in_touom IN varchar2
,in_cube IN number
,in_picktotype IN varchar2
,in_velocity IN varchar2
,in_weight IN number
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

if nvl(in_qty,0) = 0 then
    out_errorno := -1;
    out_msg := 'Quantity is required';
    return;
end if;

insert into custitemuom
(custid, item, sequence, qty, fromuom, touom, cube, picktotype, velocity,
 weight, cartontype, lastuser, lastupdate, length, width, height)
values
(in_custid, in_item, in_sequence, in_qty, in_fromuom, in_touom, in_cube,
 in_picktotype, in_velocity, in_weight, in_cartontype, 'CONV', sysdate,
 in_length, in_width, in_height);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimiius' || sqlerrm;
    out_errorno := sqlcode;
end import_itemuomsequences;
procedure import_itemuomseq_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_sequence IN number
,in_qty IN number
,in_fromuom IN varchar2
,in_touom IN varchar2
,in_cube IN number
,in_picktotype IN varchar2
,in_velocity IN varchar2
,in_weight IN number
,in_cartontype IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_uomseq_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_uomseq_table
  (load_sequence,  record_sequence,  custid, item, sequence,
   qty, fromuom, touom, cube, picktotype, velocity,
   weight, cartontype, length, width, height)
values
  (0,recseq, in_custid, in_item, in_sequence, in_qty, in_fromuom, in_touom, in_cube,
   in_picktotype, in_velocity, in_weight, in_cartontype,
   in_length, in_width, in_height);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimiius' || sqlerrm;
    out_errorno := sqlcode;
end import_itemuomseq_validation;
procedure end_itemuomseq_validataion
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_uomseq_table%rowtype
is
  select *
    from import_item_uomseq_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_uomseq_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_uomseq_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_uomseq_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
select count(1) into cntRows
   from custitemuom
   where custid = ii.custid
     and item = ii.item
     and sequence = ii.sequence;
if cntRows > 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer Uom Sequence already exists. ');
end if;
select count(1) into cntRows
   from import_item_uomseq_table
   where custid = ii.custid
     and item = ii.item
     and load_sequence = ii.load_sequence
     and sequence = ii.sequence;
if cntRows > 1 then
   out_err := out_err + 1;
   err_msg(ii, 'Duplicate Customer Item Uom Sequence in file. ');
end if;
select count(1) into cntRows
   from unitsofmeasure
   where code = ii.fromuom;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid From Uom: ' || ii.fromuom);
end if;
select count(1) into cntRows
   from unitsofmeasure
   where code = ii.touom;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid To Uom: ' || ii.touom);
end if;
if ii.sequence is null or ii.sequence = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Sequence is required ');
end if;
if ii.qty is null or ii.qty = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Quantity is required ');
end if;
if ii.picktotype is null then
   out_err := out_err + 1;
   err_msg(ii, 'Pick to Type is required ');
else
   select count(1) into cntRows
     from picktotypes
     where code = ii.picktotype;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Pick to Type: ' || ii.picktotype);
   end if;
end if;
if ii.velocity is not null then
   select count(1) into cntRows
     from itemvelocitycodes
     where code = ii.velocity;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Velocity: ' || ii.velocity);
   end if;
else
   out_err := out_err + 1;
   err_msg(ii, 'Velocity is required ');
end if;
if ii.cartontype is null then
   out_err := out_err + 1;
   err_msg(ii, 'Carton Type is required ');
else
   select count(1) into cntRows
     from cartontypes
     where code = ii.cartontype;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Carton Type: ' || ii.cartontype);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpiuom ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_uomseq_table%rowtype)
is
out_err integer;
cntRows integer;
begin
delete from custitemuom where custid = ii.custid and item = ii.item and sequence = ii.sequence;
insert into custitemuom
(custid, item, sequence, qty, fromuom, touom, cube, picktotype, velocity,
 weight, cartontype, lastuser, lastupdate, length, width, height)
values
(ii.custid, ii.item, ii.sequence, ii.qty, ii.fromuom, ii.touom, ii.cube,
 ii.picktotype, ii.velocity, ii.weight, ii.cartontype, 'CONV', sysdate,
 ii.length, ii.width, ii.height);
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_uomseq_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_uomseq_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemuom', 0, ' ', 'Item Base Uom Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemuom', strMsg);
   update import_item_uomseq_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIBuom', 0, ' ', 'Item Uomseq Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemuom', strMsg);
end end_itemuomseq_validataion;

procedure import_itemrecoptions1
(in_custid IN varchar2
,in_item IN varchar2
,in_lotrequired IN varchar2
,in_lotrftag IN varchar2
,in_serialrequired IN varchar2
,in_serialrftag IN varchar2
,in_user1required IN varchar2
,in_user1rftag IN varchar2
,in_user2required IN varchar2
,in_user2rftag IN varchar2
,in_user3required IN varchar2
,in_user3rftag IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_use_catch_weights IN varchar2
,in_catch_weight_in_cap_type IN varchar2
,in_catch_weight_out_cap_type IN varchar2
,in_capture_pickuom IN varchar2
,in_bulkcount_expdaterequired IN varchar2
,in_bulkcount_mfgdaterequired IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set lotrequired = in_lotrequired,
    lotrftag = in_lotrftag,
    serialrequired = in_serialrequired,
    serialrftag = in_serialrftag,
    user1required = in_user1required,
    user1rftag = in_user1rftag,
    user2required = in_user2required,
    user2rftag = in_user2rftag,
    user3required = in_user3required,
    user3rftag = in_user3rftag,
    mfgdaterequired = in_mfgdaterequired,
    expdaterequired = in_expdaterequired,
    countryrequired = in_countryrequired,
	use_catch_weights = in_use_catch_weights,
	catch_weight_in_cap_type = nvl(rtrim(in_catch_weight_in_cap_type),'G'),
	catch_weight_out_cap_type = in_catch_weight_out_cap_type,
	capture_pickuom = nvl(rtrim(in_capture_pickuom),'C'),
	bulkcount_expdaterequired = in_bulkcount_expdaterequired,
	bulkcount_mfgdaterequired = in_bulkcount_mfgdaterequired
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimir1' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecoptions1;

procedure import_itemrecopt1_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotrequired IN varchar2
,in_lotrftag IN varchar2
,in_serialrequired IN varchar2
,in_serialrftag IN varchar2
,in_user1required IN varchar2
,in_user1rftag IN varchar2
,in_user2required IN varchar2
,in_user2rftag IN varchar2
,in_user3required IN varchar2
,in_user3rftag IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_use_catch_weights IN varchar2
,in_catch_weight_in_cap_type IN varchar2
,in_catch_weight_out_cap_type IN varchar2
,in_capture_pickuom IN varchar2
,in_bulkcount_expdaterequired IN varchar2
,in_bulkcount_mfgdaterequired IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_name_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_recopt1_table
  (load_sequence, record_sequence, custid, item,
   lotrequired,lotrftag,serialrequired,serialrftag,user1required,
   user1rftag,user2required,user2rftag,user3required,user3rftag,
   mfgdaterequired,expdaterequired,countryrequired,
   use_catch_weights,catch_weight_in_cap_type,
   catch_weight_out_cap_type,capture_pickuom,
   bulkcount_expdaterequired,bulkcount_mfgdaterequired)
  values
  (0, recseq, in_custid, in_item,
   in_lotrequired,in_lotrftag,in_serialrequired,in_serialrftag,in_user1required,
   in_user1rftag,in_user2required,in_user2rftag,in_user3required,in_user3rftag,
   in_mfgdaterequired,in_expdaterequired,in_countryrequired,
   in_use_catch_weights,in_catch_weight_in_cap_type,
   in_catch_weight_out_cap_type,in_capture_pickuom,
   in_bulkcount_expdaterequired,in_bulkcount_mfgdaterequired);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimir1v ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecopt1_validation;
procedure end_itemrecopt1_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_recopt1_table%rowtype
is
  select *
    from import_item_recopt1_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_recopt1_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_recopt1_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_recopt1_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.lotrequired is not null then
   select count(1) into cntRows
      from lotrequiredoptions
      where code = ii.lotrequired;
   if cntRows = 0 then
      out_err := out_err + 1;
     err_msg(ii, 'Invalid lot required: ' || ii.lotrequired);
   end if;
end if;
if ii.serialrequired is not null then
   if ii.serialrequired not in    ('A','C','N','P','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid serial required: ' || ii.serialrequired);
   end if;
end if;
if ii.user1required is not null then
   if ii.user1required not in    ('A','C','N','P','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid user1 required: ' || ii.user1required);
   end if;
end if;
if ii.user2required is not null then
   if ii.user2required not in    ('A','C','N','P','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid user2 required: ' || ii.user2required);
   end if;
end if;
if ii.user3required is not null then
   if ii.user3required not in    ('A','C','N','P','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid user3 required: ' || ii.user3required);
   end if;
end if;
if ii.mfgdaterequired is not null then
   if ii.mfgdaterequired not in   ('C','N','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid mfgdate required: ' || ii.mfgdaterequired);
   end if;
end if;
if ii.expdaterequired is not null then
   if ii.expdaterequired not in   ('C','N','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid expdate required: ' || ii.expdaterequired);
   end if;
end if;
if ii.countryrequired is not null then
   if ii.countryrequired not in   ('C','N','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid country required: ' || ii.countryrequired);
   end if;
end if;
if ii.use_catch_weights is not null then
   if ii.use_catch_weights not in   ('C','N','Y') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid catch weights: ' || ii.use_catch_weights);
   end if;
end if;
if ii.catch_weight_in_cap_type is not null then
   if ii.catch_weight_in_cap_type not in ('G','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid catch weight in cap type: ' || ii.catch_weight_in_cap_type);
   end if;
end if;
if ii.catch_weight_out_cap_type is not null then
   if ii.catch_weight_out_cap_type not in ('G','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid catch_weight_out_cap_type: ' || ii.catch_weight_out_cap_type);
   end if;
end if;
if ii.capture_pickuom is not null then
   if ii.capture_pickuom not in ('C','Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid capture pickuom: ' || ii.capture_pickuom);
   end if;
end if;
if ii.bulkcount_expdaterequired is not null then
   if ii.bulkcount_expdaterequired not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid bulkcount expdaterequired: ' || ii.bulkcount_expdaterequired);
   end if;
end if;
if ii.bulkcount_mfgdaterequired is not null then
   if ii.bulkcount_mfgdaterequired not in   ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid bulkcount mfgdaterequired: ' || ii.bulkcount_mfgdaterequired);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpir1 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_recopt1_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set lotrequired = ii.lotrequired,
    lotrftag = ii.lotrftag,
    serialrequired = ii.serialrequired,
    serialrftag = ii.serialrftag,
    user1required = ii.user1required,
    user1rftag = ii.user1rftag,
    user2required = ii.user2required,
    user2rftag = ii.user2rftag,
    user3required = ii.user3required,
    user3rftag = ii.user3rftag,
    mfgdaterequired = ii.mfgdaterequired,
    expdaterequired = ii.expdaterequired,
    countryrequired = ii.countryrequired,
	use_catch_weights = ii.use_catch_weights,
	catch_weight_in_cap_type = ii.catch_weight_in_cap_type,
	catch_weight_out_cap_type = ii.catch_weight_out_cap_type,
	capture_pickuom = ii.capture_pickuom,
	bulkcount_expdaterequired = ii.bulkcount_expdaterequired,
	bulkcount_mfgdaterequired = ii.bulkcount_mfgdaterequired
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_recopt1_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_recopt1_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemRec1', 0, ' ', 'Item Receipt Options 1 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemRec1', strMsg);
   update import_item_recopt1_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIRec1', 0, ' ', 'Item Receipt Options 1 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemRec1', strMsg);
end end_itemrecopt1_validation;
procedure import_itemvalidation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotfmtruleid IN varchar2
,in_lotfmtaction IN varchar2
,in_serialfmtruleid IN varchar2
,in_serialfmtaction IN varchar2
,in_user1fmtruleid IN varchar2
,in_user1fmtaction IN varchar2
,in_user2fmtruleid IN varchar2
,in_user2fmtaction IN varchar2
,in_user3fmtruleid IN varchar2
,in_user3fmtaction IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set lotfmtruleid = in_lotfmtruleid,
    lotfmtaction = in_lotfmtaction,
    serialfmtruleid = in_serialfmtruleid,
    serialfmtaction = in_serialfmtaction,
    user1fmtruleid = in_user1fmtruleid,
    user1fmtaction = in_user1fmtaction,
    user2fmtruleid = in_user2fmtruleid,
    user2fmtaction = in_user2fmtaction,
    user3fmtruleid = in_user3fmtruleid,
    user3fmtaction = in_user3fmtaction
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimiiv' || sqlerrm;
    out_errorno := sqlcode;
end import_itemvalidation;

procedure import_itemval_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_lotfmtruleid IN varchar2
,in_lotfmtaction IN varchar2
,in_serialfmtruleid IN varchar2
,in_serialfmtaction IN varchar2
,in_user1fmtruleid IN varchar2
,in_user1fmtaction IN varchar2
,in_user2fmtruleid IN varchar2
,in_user2fmtaction IN varchar2
,in_user3fmtruleid IN varchar2
,in_user3fmtaction IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_name_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_validation_table
  (load_sequence, record_sequence, custid, item,
   lotfmtruleid,lotfmtaction,serialfmtruleid,serialfmtaction,
   user1fmtruleid,user1fmtaction,user2fmtruleid,user2fmtaction,
   user3fmtruleid,user3fmtaction)
  values
  (0, recseq, in_custid, in_item,
   in_lotfmtruleid,in_lotfmtaction,in_serialfmtruleid,in_serialfmtaction,
   in_user1fmtruleid,in_user1fmtaction,in_user2fmtruleid,in_user2fmtaction,
   in_user3fmtruleid,in_user3fmtaction);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimiirvv ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemval_validation;
procedure end_itemval_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_validation_table%rowtype
is
  select *
    from import_item_validation_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_validation_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_validation_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_validation_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if nvl(ii.lotfmtaction,'C') <> 'C' then
   select count(1) into cntRows
      from formatvalidationactions
      where code = ii.lotfmtaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Lot Format Action: ' || ii.lotfmtaction);
   end if;
end if;
if ii.lotfmtruleid is not null then
   select count(1) into cntRows
      from formatvalidationrule
      where ruleid = ii.lotfmtruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Lot Format Rule: ' || ii.lotfmtruleid);
   end if;
end if;
if nvl(ii.serialfmtaction,'C') <> 'C' then
   select count(1) into cntRows
      from formatvalidationactions
      where code = ii.serialfmtaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial Format Action: ' || ii.serialfmtaction);
   end if;
end if;
if ii.serialfmtruleid is not null then
   select count(1) into cntRows
      from formatvalidationrule
      where ruleid = ii.serialfmtruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial Format Rule: ' || ii.serialfmtruleid);
   end if;
end if;
if nvl(ii.user1fmtaction,'C') <> 'C' then
   select count(1) into cntRows
      from formatvalidationactions
      where code = ii.user1fmtaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User1 Format Action: ' || ii.user1fmtaction);
   end if;
end if;
if ii.user1fmtruleid is not null then
   select count(1) into cntRows
      from formatvalidationrule
      where ruleid = ii.user1fmtruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User1 Format Rule: ' || ii.user1fmtruleid);
   end if;
end if;
if nvl(ii.user2fmtaction,'C') <> 'C' then
   select count(1) into cntRows
      from formatvalidationactions
      where code = ii.user2fmtaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User2 Format Action: ' || ii.user2fmtaction);
   end if;
end if;
if ii.user2fmtruleid is not null then
   select count(1) into cntRows
      from formatvalidationrule
      where ruleid = ii.user2fmtruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User2 Format Rule: ' || ii.user2fmtruleid);
   end if;
end if;
if nvl(ii.user3fmtaction,'C') <> 'C' then
   select count(1) into cntRows
      from formatvalidationactions
      where code = ii.user3fmtaction;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User3 Format Action: ' || ii.user3fmtaction);
   end if;
end if;
if ii.user3fmtruleid is not null then
   select count(1) into cntRows
      from formatvalidationrule
      where ruleid = ii.user3fmtruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User3 Format Rule: ' || ii.user3fmtruleid);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpiro1 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_validation_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set lotfmtruleid = ii.lotfmtruleid,
    lotfmtaction = nvl(ii.lotfmtaction,'C'),
    serialfmtruleid = ii.serialfmtruleid,
    serialfmtaction = nvl(ii.serialfmtaction,'C'),
    user1fmtruleid = ii.user1fmtruleid,
    user1fmtaction = nvl(ii.user1fmtaction,'C'),
    user2fmtruleid = ii.user2fmtruleid,
    user2fmtaction = nvl(ii.user2fmtaction,'C'),
    user3fmtruleid = ii.user3fmtruleid,
    user3fmtaction = nvl(ii.user3fmtaction,'C')
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_validation_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_validation_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemname', 0, ' ', 'Item Receipt Options 1 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemname', strMsg);
   update import_item_validation_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIname', 0, ' ', 'Item Receipt Options 1 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemname', strMsg);
end end_itemval_validation;
procedure import_itemrecoptions2
(in_custid IN varchar2
,in_item IN varchar2
,in_nodamaged IN varchar2
,in_recinvstatus IN varchar2
,in_putawayconfirmation IN varchar2
,in_critlevel1 IN number
,in_critlevel2 IN number
,in_critlevel3 IN number
,in_parseruleaction IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_putaway_highest_wholeuom_yn IN varchar2
,in_returnsdisposition IN varchar2
,in_warnshortlp IN varchar2
,in_warnshortlpqty IN number
,in_disallowoverbuiltlp IN varchar2
,in_maxqtyof1 IN varchar2
,in_nomixeditemlp IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set nodamaged = in_nodamaged,
    recvinvstatus = in_recinvstatus,
    putawayconfirmation = in_putawayconfirmation,
	critlevel1 = in_critlevel1,
	critlevel2 = in_critlevel2,
	critlevel3 = in_critlevel3,
	parseruleaction = in_parseruleaction,
	parseruleid = in_parseruleid,
	parseentryfield = in_parseentryfield,
	putaway_highest_whole_uom_yn = in_putaway_highest_wholeuom_yn,
	returnsdisposition = in_returnsdisposition,
	warnshortlp = in_warnshortlp,
	warnshortlpqty = in_warnshortlpqty,
	disallowoverbuiltlp = in_disallowoverbuiltlp,
	maxqtyof1 = in_maxqtyof1,
	nomixeditemlp = in_nomixeditemlp
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimir2' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecoptions2;
procedure import_itemrecopt2_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_nodamaged IN varchar2
,in_recinvstatus IN varchar2
,in_putawayconfirmation IN varchar2
,in_critlevel1 IN number
,in_critlevel2 IN number
,in_critlevel3 IN number
,in_parseruleaction IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_putaway_highest_wholeuom_yn IN varchar2
,in_returnsdisposition IN varchar2
,in_warnshortlp IN varchar2
,in_warnshortlpqty IN NUMBER
,in_disallowoverbuiltlp IN varchar2
,in_maxqtyof1 IN varchar2
,in_nomixeditemlp IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_recopt2_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_recopt2_table
  (load_sequence, record_sequence, custid, item,
   nodamaged, recinvstatus, putawayconfirmation,
   critlevel1, critlevel2, critlevel3, parseruleaction,
   parseruleid, parseentryfield, putaway_highest_wholeuom_yn,
   returnsdisposition, warnshortlp, warnshortlpqty,
   disallowoverbuiltlp, maxqtyof1, nomixeditemlp
   )
values
  (0, recseq, in_custid, in_item,
   in_nodamaged,in_recinvstatus,in_putawayconfirmation,
   in_critlevel1, in_critlevel2, in_critlevel3, in_parseruleaction,
   in_parseruleid, in_parseentryfield, in_putaway_highest_wholeuom_yn,
   in_returnsdisposition, in_warnshortlp, in_warnshortlpqty,
   in_disallowoverbuiltlp, in_maxqtyof1, in_nomixeditemlp);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimir2v ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecopt2_validation;
procedure end_itemrecopt2_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_recopt2_table%rowtype
is
  select *
    from import_item_recopt2_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_recopt2_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_recopt2_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_recopt2_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.recinvstatus is not null then
   select count(1) into cntRows
      from inventorystatus
      where code = ii.recinvstatus;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Rec Inv Status: ' || ii.recinvstatus);
   end if;
end if;
if nvl(ii.nodamaged,'x') not in ('Y','N','C') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid nodamaged: ' || ii.nodamaged);
end if;
if ii.putawayconfirmation is not null then
   select count(1) into cntRows
      from putawayconfirmations
      where code = ii.putawayconfirmation;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid putawayconfirmation: ' || ii.putawayconfirmation);
   end if;
end if;
if ii.parseruleaction is not null then
   if ii.parseruleaction not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Parse Rule Action: ' || ii.parseruleaction);
	  end if;
end if;
if ii.parseruleid is not null then
   select count(1) into cntRows
      from parserule
      where ruleid = ii.parseruleid;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid parserule ID: ' || ii.parseruleid);
   end if;
end if;
if ii.parseentryfield is not null then
   select count(1) into cntRows
      from parseentryfield
      where code = ii.parseentryfield;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Parse Entry Field: ' || ii.parseentryfield);
   end if;
end if;
if ii.putaway_highest_wholeuom_yn is not null then
   if ii.putaway_highest_wholeuom_yn not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Putaway Highest Whole UOM: ' || ii.putaway_highest_wholeuom_yn);
   end if;
end if;
if ii.warnshortlp is not null then
   if ii.warnshortlp not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Warn Short LP: ' || ii.warnshortlp);
   end if;
end if;
if ii.disallowoverbuiltlp is not null then
   if ii.disallowoverbuiltlp not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Disallow Over Built LP: ' || ii.disallowoverbuiltlp);
   end if;
end if;
if ii.maxqtyof1 is not null then
   if ii.maxqtyof1 not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Max Quantity Of 1: ' || ii.maxqtyof1);
   end if;
end if;
if ii.nomixeditemlp is not null then
   if ii.nomixeditemlp not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid No Mixed Item LP: ' || ii.nomixeditemlp);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpir2 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_recopt2_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set nodamaged = ii.nodamaged,
    recvinvstatus = ii.recinvstatus,
    putawayconfirmation = ii.putawayconfirmation,
	critlevel1 = ii.critlevel1,
	critlevel2 = ii.critlevel2,
	critlevel3 = ii.critlevel3,
	parseruleaction = ii.parseruleaction,
	parseruleid = ii.parseruleid,
	parseentryfield = ii.parseentryfield,
	putaway_highest_whole_uom_yn = ii.putaway_highest_wholeuom_yn,
	returnsdisposition = ii.returnsdisposition,
	warnshortlp = ii.warnshortlp,
	warnshortlpqty = ii.warnshortlpqty,
	disallowoverbuiltlp = ii.disallowoverbuiltlp,
	maxqtyof1 = ii.maxqtyof1,
	nomixeditemlp = ii.nomixeditemlp,
	lastupdate = sysdate,
	lastuser = 'IMPEXP-IR2'
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_recopt2_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_recopt2_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemRec2', 0, ' ', 'Item Receipt Options 2 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemRec2', strMsg);
   update import_item_recopt2_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIRec2', 0, ' ', 'Item Receipt Options 2 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemRec2', strMsg);
end end_itemrecopt2_validation;
procedure import_itemrecoptions3
(in_custid             IN varchar2
,in_item               IN varchar2
,in_serialasncapture   IN varchar2
,in_user1asncapture    IN varchar2
,in_user2asncapture    IN varchar2
,in_user3asncapture    IN varchar2
,in_lot_seq_max        IN number
,in_lot_seq_min        IN number
,in_lot_seq_name       IN varchar2
,in_serial_seq_max     IN number
,in_serial_seq_min     IN number
,in_serial_seq_name    IN varchar2
,in_useritem1_seq_max  IN number
,in_useritem1_seq_min  IN number
,in_useritem1_seq_name IN varchar2
,in_useritem2_seq_max  IN number
,in_useritem2_seq_min  IN number
,in_useritem2_seq_name IN varchar2
,in_useritem3_seq_max  IN number
,in_useritem3_seq_min  IN number
,in_useritem3_seq_name IN varchar2
,out_errorno           IN OUT number 
,out_msg               IN OUT varchar2
) is
begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;
if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;
update custitem
set serialasncapture = in_serialasncapture,
    user1asncapture = in_user1asncapture,
    user2asncapture = in_user2asncapture,
	user3asncapture = in_user3asncapture,
	lot_seq_max = in_lot_seq_max,
	lot_seq_min = in_lot_seq_min,
	lot_seq_name = in_lot_seq_name,
	serial_seq_max = in_serial_seq_max,
	serial_seq_min = in_serial_seq_min,
	serial_seq_name = in_serial_seq_name,
	useritem1_seq_max = in_useritem1_seq_max,
	useritem1_seq_min = in_useritem1_seq_min,
	useritem1_seq_name = in_useritem1_seq_name,
	useritem2_seq_max = in_useritem2_seq_max,
	useritem2_seq_min = in_useritem2_seq_min,
	useritem2_seq_name = in_useritem2_seq_name,
	useritem3_seq_max = in_useritem3_seq_max,
	useritem3_seq_min = in_useritem3_seq_min,
	useritem3_seq_name = in_useritem3_seq_name,
	lastupdate = sysdate,
	lastuser = 'IMPEXP-IR3'
where custid = in_custid
  and item = in_item;
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimir3' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecoptions3;
procedure import_itemrecopt3_validation
(in_custid             IN varchar2
,in_item               IN varchar2
,in_serialasncapture   IN varchar2
,in_user1asncapture    IN varchar2
,in_user2asncapture    IN varchar2
,in_user3asncapture    IN varchar2
,in_lot_seq_max        IN number
,in_lot_seq_min        IN number
,in_lot_seq_name       IN varchar2
,in_serial_seq_max     IN number
,in_serial_seq_min     IN number
,in_serial_seq_name    IN varchar2
,in_useritem1_seq_max  IN number
,in_useritem1_seq_min  IN number
,in_useritem1_seq_name IN varchar2
,in_useritem2_seq_max  IN number
,in_useritem2_seq_min  IN number
,in_useritem2_seq_name IN varchar2
,in_useritem3_seq_max  IN number
,in_useritem3_seq_min  IN number
,in_useritem3_seq_name IN varchar2
,out_errorno           IN OUT number
,out_msg               IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
  from import_item_recopt3_table
 where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_recopt3_table
       (load_sequence, record_sequence, custid, item,
        serialasncapture,user1asncapture,user2asncapture,user3asncapture,
        lot_seq_max,lot_seq_min,lot_seq_name,serial_seq_max,serial_seq_min,
        serial_seq_name,useritem1_seq_max,useritem1_seq_min,useritem1_seq_name, 
        useritem2_seq_max,useritem2_seq_min,useritem2_seq_name,useritem3_seq_max,
        useritem3_seq_min,useritem3_seq_name) 
values
  (0, recseq, in_custid, in_item,
   in_serialasncapture,in_user1asncapture,in_user2asncapture,in_user3asncapture,
   in_lot_seq_max,in_lot_seq_min,in_lot_seq_name, in_serial_seq_max,in_serial_seq_min,
   in_serial_seq_name,in_useritem1_seq_max,in_useritem1_seq_min,in_useritem1_seq_name, 
   in_useritem2_seq_max,in_useritem2_seq_min,in_useritem2_seq_name,in_useritem3_seq_max,
   in_useritem3_seq_min,in_useritem3_seq_name);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimir3v' || sqlerrm;
    out_errorno := sqlcode;
end import_itemrecopt3_validation;
procedure end_itemrecopt3_validation
(in_update   IN varchar2
,out_errorno IN OUT NUMBER
,out_msg     IN OUT varchar2
) is
ii_max  integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg  varchar2(255);
cursor C_II(in_seq integer)
return import_item_recopt3_table%rowtype
is
  select *
    from import_item_recopt3_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_recopt3_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_recopt3_error
  (load_sequence, record_sequence, custid, item, comments)
values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_recopt3_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.serialasncapture is not null then
   if ii.serialasncapture not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial ASN Capture: ' || ii.serialasncapture);
   end if;
end if;
if ii.user1asncapture is not null then
   if ii.user1asncapture not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User1 ASN Capture: ' || ii.user1asncapture);
   end if;
end if;
if ii.user2asncapture is not null then
   if ii.user2asncapture not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User2 ASN Capture: ' || ii.user2asncapture);
   end if;
end if;
if ii.user3asncapture is not null then
   if ii.user3asncapture not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User3 ASN Capture: ' || ii.user3asncapture);
   end if;
end if;
if ii.lot_seq_max is not null and
   ii.lot_seq_min is not null and
   ii.lot_seq_max <  ii.lot_seq_min then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Lot Max Sequence Value Must Be Greater Than Min Sequence Value: ' || ii.lot_seq_max);
end if;
if ii.lot_seq_min is not null and
   ii.lot_seq_min <= 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Lot Min Sequence Value Must Be 1 Or Greater: ' || ii.lot_seq_min);
end if;
if ii.lot_seq_max is not null and
   ii.lot_seq_min is not null and
   ii.lot_seq_name is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Lot Sequence Name: ' || ii.lot_seq_name);
end if;
if ii.serial_seq_max is not null and
   ii.serial_seq_min is not null and
   ii.serial_seq_max <  ii.serial_seq_min then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial Max Sequence Value Must Be Greater Than Min Sequence Value: ' || ii.serial_seq_max);
end if;
if ii.serial_seq_min is not null and
   ii.serial_seq_min <= 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial Min Sequence Value Must Be 1 Or Greater: ' || ii.serial_seq_min);
end if;
if ii.serial_seq_max is not null and
   ii.serial_seq_min is not null and
   ii.serial_seq_name is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Serial Sequence Name: ' || ii.serial_seq_name);
end if;
if ii.useritem1_seq_max is not null and
   ii.useritem1_seq_min is not null and
   ii.useritem1_seq_max <  ii.useritem1_seq_min then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item1 Max Sequence Value Must Be Greater Than Min Sequence Value: ' || ii.useritem1_seq_max);
end if;
if ii.useritem1_seq_min is not null and
   ii.useritem1_seq_min <= 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item1 Min Sequence Value Must Be 1 Or Greater: ' || ii.useritem1_seq_min);
end if;
if ii.useritem1_seq_max is not null and
   ii.useritem1_seq_min is not null and
   ii.useritem1_seq_name is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item1 Sequence Name: ' || ii.useritem1_seq_name);
end if;
if ii.useritem2_seq_max is not null and
   ii.useritem2_seq_min is not null and
   ii.useritem2_seq_max <  ii.useritem2_seq_min then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item2 Max Sequence Value Must Be Greater Than Min Sequence Value: ' || ii.useritem2_seq_max);
end if;
if ii.useritem2_seq_min is not null and
   ii.useritem2_seq_min <= 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item2 Min Sequence Value Must Be 1 Or Greater: ' || ii.useritem2_seq_min);
end if;
if ii.useritem2_seq_max is not null and
   ii.useritem2_seq_min is not null and
   ii.useritem2_seq_name is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item2 Sequence Name: ' || ii.useritem2_seq_name);
end if;
if ii.useritem3_seq_max is not null and
   ii.useritem3_seq_min is not null and
   ii.useritem3_seq_max <  ii.useritem3_seq_min then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item3 Max Sequence Value Must Be Greater Than Min Sequence Value: ' || ii.useritem3_seq_max);
end if;
if ii.useritem3_seq_min is not null and
   ii.useritem3_seq_min <= 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item3 Min Sequence Value Must Be 1 Or Greater: ' || ii.useritem3_seq_min);
end if;
if ii.useritem3_seq_max is not null and
   ii.useritem3_seq_min is not null and
   ii.useritem3_seq_name is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid User Item3 Sequence Name: ' || ii.useritem3_seq_name);
end if;
return out_err;
exception when others then
  out_msg := 'zimpir3 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_recopt3_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set serialasncapture = ii.serialasncapture,
    user1asncapture = ii.user1asncapture,
    user2asncapture = ii.user2asncapture,
	user3asncapture = ii.user3asncapture,
	lot_seq_max = ii.lot_seq_max,
	lot_seq_min = ii.lot_seq_min,
	lot_seq_name = ii.lot_seq_name,
	serial_seq_max = ii.serial_seq_max,
	serial_seq_min = ii.serial_seq_min,
	serial_seq_name = ii.serial_seq_name,
	useritem1_seq_max = ii.useritem1_seq_max,
	useritem1_seq_min = ii.useritem1_seq_min,
	useritem1_seq_name = ii.useritem1_seq_name,
	useritem2_seq_max = ii.useritem2_seq_max,
	useritem2_seq_min = ii.useritem2_seq_min,
	useritem2_seq_name = ii.useritem2_seq_name,
	useritem3_seq_max = ii.useritem3_seq_max,
	useritem3_seq_min = ii.useritem3_seq_min,
	useritem3_seq_name = ii.useritem3_seq_name,
	lastupdate = sysdate,
	lastuser = 'IMPEXP-IR3'
where custid = ii.custid
  and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_recopt3_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_recopt3_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemrecopt3', 0, ' ', 'Item Receipt Options 3 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemrecopt3', strMsg);
   update import_item_recopt3_table
      set load_sequence = new_seq
    where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIrec3', 0, ' ', 'Item Receipt Options 3 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemrecopt3', strMsg);
end end_itemrecopt3_validation;

procedure import_itemhazardsettings
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_hazardflag             IN varchar2
,in_hazardclass            IN varchar2
,in_primarychemcode        IN varchar2
,in_secondarychemcode      IN varchar2
,in_tertiarychemcode       IN varchar2
,in_quaternarychemcode     IN varchar2
,in_imoprimarychemcode     IN varchar2
,in_imosecondarychemcode   IN varchar2
,in_imotertiarychemcode    IN varchar2
,in_imoquaternarychemcode  IN varchar2
,in_iataprimarychemcode    IN varchar2
,in_iatasecondarychemcode  IN varchar2
,in_iatatertiarychemcode   IN varchar2
,in_iataquaternarychemcode IN varchar2
,in_printmsds              IN varchar2
,in_msdsformat             IN varchar2
,out_errorno               IN OUT NUMBER
,out_msg                   IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set hazardous = in_hazardflag,
    primaryhazardclass = in_hazardclass,
    primarychemcode = in_primarychemcode,
    secondarychemcode = in_secondarychemcode,
    tertiarychemcode = in_tertiarychemcode,
    quaternarychemcode = in_quaternarychemcode,
    imoprimarychemcode = in_imoprimarychemcode,
    imosecondarychemcode = in_imosecondarychemcode,
    imotertiarychemcode = in_imotertiarychemcode,
    imoquaternarychemcode = in_imoquaternarychemcode,
    iataprimarychemcode = in_iataprimarychemcode,
    iatasecondarychemcode = in_iatasecondarychemcode,
    iatatertiarychemcode = in_iatatertiarychemcode,
    iataquaternarychemcode = in_iataquaternarychemcode,
	printmsds = nvl(rtrim(in_printmsds),'N'),
	msdsformat = in_msdsformat
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimihs' || sqlerrm;
    out_errorno := sqlcode;
end import_itemhazardsettings;

procedure import_itemhazset_validation
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_hazardflag             IN varchar2
,in_hazardclass            IN varchar2
,in_primarychemcode        IN varchar2
,in_secondarychemcode      IN varchar2
,in_tertiarychemcode       IN varchar2
,in_quaternarychemcode     IN varchar2
,in_imoprimarychemcode     IN varchar2
,in_imosecondarychemcode   IN varchar2
,in_imotertiarychemcode    IN varchar2
,in_imoquaternarychemcode  IN varchar2
,in_iataprimarychemcode    IN varchar2
,in_iatasecondarychemcode  IN varchar2
,in_iatatertiarychemcode   IN varchar2
,in_iataquaternarychemcode IN varchar2
,in_printmsds              IN varchar2
,in_msdsformat             IN varchar2
,out_errorno               IN OUT NUMBER
,out_msg                   IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_hazset_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_hazset_table
  (load_sequence, record_sequence, custid, item,
   hazardflag,hazardclass,primarychemcode,secondarychemcode,
   tertiarychemcode,quaternarychemcode,imoprimarychemcode,
   imosecondarychemcode,imotertiarychemcode,imoquaternarychemcode,
   iataprimarychemcode,iatasecondarychemcode,iatatertiarychemcode,
   iataquaternarychemcode,printmsds,msdsformat)
  values
  (0, recseq, in_custid, in_item,
   in_hazardflag,in_hazardclass,in_primarychemcode,in_secondarychemcode,
   in_tertiarychemcode,in_quaternarychemcode,in_imoprimarychemcode,
   in_imosecondarychemcode,in_imotertiarychemcode,in_imoquaternarychemcode,
   in_iataprimarychemcode,in_iatasecondarychemcode,in_iatatertiarychemcode,
   in_iataquaternarychemcode,in_printmsds,in_msdsformat);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimihsv' || sqlerrm;
    out_errorno := sqlcode;
end import_itemhazset_validation;
procedure end_itemhazset_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_II(in_seq integer)
return import_item_hazset_table%rowtype
is
  select *
    from import_item_hazset_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_hazset_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_hazset_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_hazset_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if nvl(ii.hazardflag,'N') not in ('Y','N') then
   out_err := out_err + 1;
   err_msg(ii, 'Invalid Hazard Flag: ' || ii.hazardflag);
end if;
if ii.hazardclass is not null then
   select count(1) into cntRows
      from hazardousclasses
      where code = ii.hazardclass;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Hazard Classs: '||ii.hazardclass);
   end if;
end if;
if ii.primarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.primarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Primary Chem Code: '||ii.primarychemcode);
   end if;
end if;
if ii.secondarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.secondarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Secondary Chem Code: '||ii.secondarychemcode);
   end if;
end if;
if ii.tertiarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.tertiarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Tertiary Chem Code: '||ii.tertiarychemcode);
   end if;
end if;
if ii.quaternarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.quaternarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Quaternary Chem Code: '||ii.quaternarychemcode);
   end if;
end if;
if ii.imoprimarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.imoprimarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IMO Primary Chem Code: '||ii.imoprimarychemcode);
   end if;
end if;
if ii.imosecondarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.imosecondarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IMO Secondary Chem Code: '||ii.imosecondarychemcode);
   end if;
end if;
if ii.imotertiarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.imotertiarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IMO Tertiary Chem Code: '||ii.imotertiarychemcode);
   end if;
end if;
if ii.imoquaternarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.imoquaternarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IMO Quaternary Chem Code: '||ii.imoquaternarychemcode);
   end if;
end if;
if ii.iataprimarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.iataprimarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IATA Primary Chem Code: '||ii.iataprimarychemcode);
   end if;
end if;
if ii.iatasecondarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.iatasecondarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IATA Secondary Chem Code: '||ii.iatasecondarychemcode);
   end if;
end if;
if ii.iatatertiarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.iatatertiarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IATA Tertiary Chem Code: '||ii.iatatertiarychemcode);
   end if;
end if;
if ii.iataquaternarychemcode is not null then
   select count(1) into cntRows
      from chemicalcodes
      where chemcode = ii.iataquaternarychemcode;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid IATA Quaternary Chem Code: '||ii.iataquaternarychemcode);
   end if;
end if;
if ii.printmsds is not null and
   ii.printmsds not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid print MSDS: ' || ii.printmsds);
end if;
return out_err;
exception when others then
  out_msg := 'zimpihs ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_hazset_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set hazardous = ii.hazardflag,
    primaryhazardclass = ii.hazardclass,
    primarychemcode = ii.primarychemcode,
    secondarychemcode = ii.secondarychemcode,
    tertiarychemcode = ii.tertiarychemcode,
    quaternarychemcode = ii.quaternarychemcode,
    imoprimarychemcode = ii.imoprimarychemcode,
    imosecondarychemcode = ii.imosecondarychemcode,
    imotertiarychemcode = ii.imotertiarychemcode,
    imoquaternarychemcode = ii.imoquaternarychemcode,
    iataprimarychemcode = ii.iataprimarychemcode,
    iatasecondarychemcode = ii.iatasecondarychemcode,
    iatatertiarychemcode = ii.iatatertiarychemcode,
    iataquaternarychemcode = ii.iataquaternarychemcode,
	printmsds = ii.printmsds,
	msdsformat = ii.msdsformat
where custid = ii.custid
   and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_hazset_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_hazset_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impitemHazSet', 0, ' ', 'Item Hazardous Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemHazSet', strMsg);
   update import_item_hazset_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIHazSet', 0, ' ', 'Item Hazset Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemHazSet', strMsg);
end end_itemhazset_validation;
procedure import_itemfacilitysettings
(in_custid         IN varchar2
,in_item           IN varchar2
,in_facility       IN varchar2
,in_allocrule      IN varchar2
,in_replenrule     IN varchar2
,in_putawayprofile IN varchar2
,out_errorno       IN OUT NUMBER
,out_msg           IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;
if rtrim(in_facility) is null then
    out_errorno := -1;
    out_msg := 'Facility value is required';
    return;
end if;


insert into custitemfacility(custid, item, facility, allocrule,
                             replallocrule, profid,lastuser,lastupdate)
       values (in_custid, in_item, in_facility, in_allocrule,
                             in_replenrule, in_putawayprofile,
                             'CONV',sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimifs' || sqlerrm;
    out_errorno := sqlcode;
end import_itemfacilitysettings;

procedure import_itemfacset_validation
(in_custid         IN varchar2
,in_item           IN varchar2
,in_facility       IN varchar2
,in_allocrule      IN varchar2
,in_replenrule     IN varchar2
,in_putawayprofile IN varchar2
,out_errorno       IN OUT NUMBER
,out_msg           IN OUT varchar2
) is
recseq integer;

begin
select nvl(max(record_sequence),0) into recseq
   from import_item_facset_table
   where load_sequence = 0;
recseq := recseq + 1;

insert into import_item_facset_table
  (load_sequence, record_sequence, custid, item, facility,
   allocrule, replenrule, putawayprofile)
  values
  (0, recseq, in_custid, in_item, in_facility,
   in_allocrule, in_replenrule, in_putawayprofile);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimifsv' || sqlerrm;
    out_errorno := sqlcode;
end import_itemfacset_validation;

procedure end_itemfacset_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);


cursor C_II(in_seq integer)
return import_item_facset_table%rowtype
is
  select *
    from import_item_facset_table
   where load_sequence = in_seq
   order by record_sequence;


procedure err_msg
(ii in import_item_facset_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_facset_error
  (load_sequence, record_sequence, custid, item, facility, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, ii.facility, error_msg);
end err_msg;

function cii_validation
(ii in import_item_facset_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;

select count(1) into cntRows
   from customer
   where custid = ii.custid;

if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;

if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;

select count(1) into cntRows
   from facility
   where facility = ii.facility;

if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Facility does not exist. ');
end if;

if ii.allocrule is not null and 
   ii.allocrule <> 'C' then
   select count(1) into cntRows
     from allocruleshdr
    where facility = ii.facility
      and allocrule = ii.allocrule;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Alloc Rule does not exist: '||ii.allocrule);
   end if;
end if;

if ii.replenrule is not null and
   ii.replenrule <> 'C' then
   select count(1) into cntRows
     from allocruleshdr
    where facility = ii.facility
      and allocrule = ii.replenrule;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Replen Rule does not exist: '||ii.replenrule);
   end if;
end if;
if ii.putawayprofile is not null and
   ii.putawayprofile <> 'C' then
   select count(1) into cntRows
     from putawayprof
    where facility = ii.facility
      and profid = ii.putawayprofile;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Putaway Profile does not exist: '||ii.putawayprofile);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpifacset ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_facset_table%rowtype)
is
out_err integer;
cntRows integer;
begin
insert into custitemfacility(custid, item, facility, allocrule,
                             replallocrule, profid,lastuser,lastupdate)
       values (ii.custid, ii.item, ii.facility, nvl(ii.allocrule,'C'),
                             nvl(ii.replenrule,'C'), nvl(ii.putawayprofile,'C'),
                             'CONV',sysdate);
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_facset_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_facset_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impispec', 0, ' ', 'Item Facset Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impispec', strMsg);
   update import_item_facset_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
      err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpISpec', 0, ' ', 'Item Facset Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impispec', strMsg);
end end_itemfacset_validation;
procedure import_itemshippingoptions2
(in_custid IN varchar2
,in_item IN varchar2
,in_allocrule IN varchar2
,in_qtytype IN varchar2
,in_variancepct IN number
,in_weightcheckrequired IN varchar2
,in_subslprsnrequired IN varchar2
,in_use_min_units_qty IN varchar2
,in_min_units_qty IN number
,in_use_multiple_units_qty IN varchar2
,in_multiple_units_qty IN number
,in_sip_carton_uom IN varchar2
,in_tms_uom IN varchar2
,in_track_picked_pf_lps IN varchar2
,in_variancepct_use_default IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;


update custitem
set allocrule = in_allocrule,
    qtytype = in_qtytype,
    variancepct = in_variancepct,
    weightcheckrequired = in_weightcheckrequired,
    subslprsnrequired = in_subslprsnrequired,
	use_min_units_qty = nvl(rtrim(in_use_min_units_qty),'C'),
	min_units_qty = in_min_units_qty,
	use_multiple_units_qty = nvl(rtrim(in_use_multiple_units_qty),'C'),
	multiple_units_qty = in_multiple_units_qty,
	sip_carton_uom = in_sip_carton_uom,
	tms_uom = in_tms_uom,
	track_picked_pf_lps = in_track_picked_pf_lps,
	variancepct_use_default = in_variancepct_use_default
where custid = in_custid
   and item = in_item;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimis2' || sqlerrm;
    out_errorno := sqlcode;
end import_itemshippingoptions2;

procedure import_itemshipopt2_validation
(in_custid IN varchar2
,in_item IN varchar2
,in_allocrule IN varchar2
,in_qtytype IN varchar2
,in_variancepct IN number
,in_weightcheckrequired IN varchar2
,in_subslprsnrequired IN varchar2
,in_use_min_units_qty IN varchar2
,in_min_units_qty IN number
,in_use_multiple_units_qty IN varchar2
,in_multiple_units_qty IN number
,in_sip_carton_uom IN varchar2
,in_tms_uom IN varchar2
,in_track_picked_pf_lps IN varchar2
,in_variancepct_use_default IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_item_shipopt2_table
   where load_sequence = 0;
recseq := recseq + 1;

insert into import_item_shipopt2_table
  (load_sequence, record_sequence, custid, item,
   allocrule,qtytype,variancepct,weightcheckrequired,subslprsnrequired,
   use_min_units_qty,min_units_qty,use_multiple_units_qty,multiple_units_qty,
   sip_carton_uom,tms_uom,track_picked_pf_lps,variancepct_use_default)
  values
  (0, recseq, in_custid, in_item,
   in_allocrule,in_qtytype,in_variancepct,in_weightcheckrequired,in_subslprsnrequired,
   in_use_min_units_qty,in_min_units_qty,in_use_multiple_units_qty,in_multiple_units_qty,
   in_sip_carton_uom,in_tms_uom,in_track_picked_pf_lps,in_variancepct_use_default);

out_msg := 'OKAY';
out_errorno := 0;


exception when others then
    out_msg := 'zimis2v ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemshipopt2_validation;

procedure end_itemshipopt2_validation
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

ii_max integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);


cursor C_II(in_seq integer)
return import_item_shipopt2_table%rowtype
is
  select *
    from import_item_shipopt2_table
   where load_sequence = in_seq
   order by record_sequence;


procedure err_msg
(ii in import_item_shipopt2_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_shipopt2_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;

function cii_validation
(ii in import_item_shipopt2_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;

select count(1) into cntRows
   from customer
   where custid = ii.custid;

if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;

select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;

if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.qtytype is not null then
   select count(1) into cntRows
      from orderquantitytypes
      where code = ii.qtytype;
   if cntRows = 0 then
      out_err := out_err + 1;
     err_msg(ii, 'Invalid Quantity Type: ' || ii.qtytype);
   end if;
end if;
if ii.weightcheckrequired is not null then
   if ii.weightcheckrequired not in    ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Weight Check Required: ' || ii.weightcheckrequired);
   end if;
end if;
if ii.subslprsnrequired is not null then
   if ii.subslprsnrequired not in    ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Substitution Reason Required: ' || ii.subslprsnrequired);
   end if;
end if;
if ii.use_min_units_qty is not null then
   if ii.use_min_units_qty not in ('C','Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Use Minimal Units Quantity: ' || ii.use_min_units_qty);
   end if;
end if;
if ii.use_multiple_units_qty is not null then
   if ii.use_multiple_units_qty not in ('C','Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Use Multiple Units Quantity: ' || ii.use_multiple_units_qty);
   end if;
end if;
if ii.sip_carton_uom is not null then
   select count(1) into cntRows
      from unitsofmeasure
      where code = ii.sip_carton_uom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid sip carton uom: ' || ii.sip_carton_uom);
   end if;
end if;
if ii.tms_uom is not null then
   select count(1) into cntRows
      from unitsofmeasure
      where code = ii.tms_uom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid tms uom: ' || ii.tms_uom);
   end if;
end if;
if ii.track_picked_pf_lps is not null then
   if ii.track_picked_pf_lps not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Track Picked PF LPs ' || ii.track_picked_pf_lps);
   end if;
end if;
if ii.variancepct_use_default is not null then
   if ii.variancepct_use_default not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Variancepct Use Default ' || ii.variancepct_use_default);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpis2 ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;

procedure cii_update_item
(ii in import_item_shipopt2_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set allocrule = ii.allocrule,
    qtytype = ii.qtytype,
    variancepct = ii.variancepct,
    weightcheckrequired = ii.weightcheckrequired,
    subslprsnrequired = ii.subslprsnrequired,
	use_min_units_qty = ii.use_min_units_qty,
	min_units_qty = ii.min_units_qty,
	use_multiple_units_qty = ii.use_multiple_units_qty,
	multiple_units_qty = ii.multiple_units_qty,
	sip_carton_uom = ii.sip_carton_uom,
	tms_uom = ii.tms_uom,
	track_picked_pf_lps = ii.track_picked_pf_lps,
	variancepct_use_default = ii.variancepct_use_default
where custid = ii.custid
   and item = ii.item;
end cii_update_item;

begin
   select nvl(max(load_sequence),0) into ii_max from import_item_shipopt2_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_shipopt2_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;

   new_seq := new_seq + 1;


   zms.log_msg('impitemShip2', 0, ' ', 'Item Shipping Options 2 Settings Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impitemShip2', strMsg);

   update import_item_shipopt2_table
      set load_sequence = new_seq
      where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
   -- perform validation
      err_cnt := err_cnt + cii_validation(cii);
   end loop;

   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;

  commit;

  zms.log_msg('ImpIShip2', 0, ' ', 'Item Shipping Options 2 Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impitemShip2', strMsg);

end end_itemshipopt2_validation;


procedure import_itemstorage
(in_custid IN varchar2
,in_item IN varchar2
,in_uomseq IN number
,in_unitofmeasure IN varchar2
,in_uosseq IN number
,in_unitofstorage IN varchar2
,in_uominuos IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

insert into custitemuomuos
(custid , item, uomseq, unitofmeasure, uosseq, unitofstorage, uominuos, lastuser, lastupdate)
values
(in_custid, in_item, in_uomseq, in_unitofmeasure, in_uosseq, in_unitofstorage, in_uominuos, 'CONV', sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimiis' || sqlerrm;
    out_errorno := sqlcode;
end import_itemstorage;

procedure import_itemaliases
(in_custid IN varchar2
,in_item IN varchar2
,in_itemalias IN varchar2
,in_aliasdesc IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

l_duplicate_aliases_allowed customer_aux.duplicate_aliases_allowed%type;
l_alias_count pls_integer;

begin

if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

begin
  select duplicate_aliases_allowed
    into l_duplicate_aliases_allowed
    from customer_aux
   where custid = in_custid;
exception when others then
  l_duplicate_aliases_allowed := 'N';
end;

if l_duplicate_aliases_allowed = 'N' then
  l_alias_count := 0;
  select count(1)
    into l_alias_count
    from custitemalias
   where custid = in_custid
     and itemalias = in_itemalias;
  if l_alias_count != 0 then
    out_errorno := -3;
    out_msg := 'Duplicate aliases are not allowed';
  end if;
end if;

insert into custitemalias
(custid, item, itemalias, aliasdesc, lastuser, lastupdate)
values
(in_custid, in_item, in_itemalias, in_aliasdesc, 'CONV', sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimiia' || sqlerrm;
    out_errorno := sqlcode;
end import_itemaliases;

procedure import_custitemuomuos
(in_custid IN varchar2
,in_item IN varchar2
,in_uomseq IN number
,in_unitofmeasure IN varchar2
,in_uosseq IN number
,in_unitofstorage IN varchar2
,in_uominuos IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;


if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;

insert into custitemuomuos
(custid, item, uomseq, unitofmeasure, uosseq, unitofstorage, uominuos, lastuser, lastupdate)
values
(in_custid, in_item, in_uomseq, in_unitofmeasure, in_uosseq, in_unitofstorage, in_uominuos, 'CONV', sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimiciu' || sqlerrm;
    out_errorno := sqlcode;
end import_custitemuomuos;

procedure import_custitemnmfc
(in_custid IN varchar2
,in_item IN varchar2
,in_NMFC IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
    out_errorno := -1;
        out_msg := 'Customer ID value is required';
            return;
            end if;


            if rtrim(in_item) is null then
                out_errorno := -1;
                    out_msg := 'Item value is required';
                        return;
                        end if;


      update custitem
      set NMFC = in_NMFC
        where custid = in_custid
        and item = in_item;

        out_msg := 'OKAY';
        out_errorno := 0;

     exception when others then
      out_msg := 'zimcin' || sqlerrm;
      out_errorno := sqlcode;

 end import_custitemnmfc;

procedure import_itemhandling
(in_custid                     IN varchar2
,in_item                       IN varchar2
,in_locstchg_loctype           IN varchar2
,in_locstchg_excl_tasktypes    IN varchar2
,in_locstchg_entry_invstatu    IN varchar2
,in_locstchg_entry_adjreasn    IN varchar2
,in_locstchg_exit_invstatus    IN varchar2
,in_locstchg_exit_adjreason    IN varchar2
,out_errorno                   IN OUT NUMBER
,out_msg                       IN OUT varchar2
) is
begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;
if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;
update custitem
set locstatuschg_loctype = in_locstchg_loctype,
    locstatuschg_exclude_tasktypes = in_locstchg_excl_tasktypes,
    locstatuschg_entry_invstatus = in_locstchg_entry_invstatu, 
    locstatuschg_entry_adjreason = in_locstchg_entry_adjreasn,
    locstatuschg_exit_invstatus = in_locstchg_exit_invstatus,
    locstatuschg_exit_adjreason = in_locstchg_exit_adjreason  	
where custid = in_custid
  and item = in_item;
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimihd' || sqlerrm;
    out_errorno := sqlcode;
end import_itemhandling;
procedure import_itemhandling_validation
(in_custid                     IN varchar2
,in_item                       IN varchar2
,in_locstchg_loctype           IN varchar2
,in_locstchg_excl_tasktypes    IN varchar2
,in_locstchg_entry_invstatu    IN varchar2
,in_locstchg_entry_adjreasn    IN varchar2
,in_locstchg_exit_invstatus    IN varchar2
,in_locstchg_exit_adjreason    IN varchar2
,out_errorno                   IN OUT NUMBER
,out_msg                       IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
  from import_item_handling_table
 where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_handling_table
  (load_sequence, record_sequence, custid, item,
   locstchg_loctype, locstchg_excl_tasktypes,
   locstchg_entry_invstatu, locstchg_entry_adjreasn, 
   locstchg_exit_invstatus, locstchg_exit_adjreason
  )
  values
  (0, recseq, in_custid, in_item,
   in_locstchg_loctype, in_locstchg_excl_tasktypes,
   in_locstchg_entry_invstatu, in_locstchg_entry_adjreasn, 
   in_locstchg_exit_invstatus, in_locstchg_exit_adjreason
  );
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimihdv ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemhandling_validation;
procedure end_itemhandling_validation
(in_update   IN varchar2
,out_errorno IN OUT NUMBER
,out_msg     IN OUT varchar2
) is
ii_max  integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg  varchar2(255);
cursor C_II(in_seq integer)
return import_item_handling_table%rowtype
is
  select *
    from import_item_handling_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_handling_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_handling_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_handling_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.locstchg_loctype is not null then
   select count(1) into cntRows
     from locationtypes
    where code = ii.locstchg_loctype;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Location Type: ' || ii.locstchg_loctype);
   end if;
end if;
if ii.locstchg_excl_tasktypes is not null then
   select count(1) into cntRows
     from tasktypes
    where code = ii.locstchg_excl_tasktypes;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Task Types: ' || ii.locstchg_excl_tasktypes);
   end if;
end if; 
if ii.locstchg_entry_invstatu is not null then
   select count(1) into cntRows
     from inventorystatus
    where code = ii.locstchg_entry_invstatu;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Location Entry Invstatus: ' || ii.locstchg_entry_invstatu);
   end if;
end if;
if ii.locstchg_entry_adjreasn is not null then
   select count(1) into cntRows
     from adjustmentreasons
    where code = ii.locstchg_entry_adjreasn;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Entry Adjustment Reasons: ' || ii.locstchg_entry_adjreasn);
   end if;
end if; 
if ii.locstchg_exit_invstatus is not null then
   select count(1) into cntRows
     from inventorystatus
    where code = ii.locstchg_exit_invstatus;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Location Exit Invstatus: ' || ii.locstchg_exit_invstatus);
   end if;
end if;
if ii.locstchg_exit_adjreason is not null then
   select count(1) into cntRows
     from adjustmentreasons
    where code = ii.locstchg_exit_adjreason;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Exit Adjustment Reasons: ' || ii.locstchg_exit_adjreason);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpihd ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_handling_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set locstatuschg_loctype = ii.locstchg_loctype,
    locstatuschg_exclude_tasktypes = ii.locstchg_excl_tasktypes,
    locstatuschg_entry_invstatus = ii.locstchg_entry_invstatu, 
    locstatuschg_entry_adjreason = ii.locstchg_entry_adjreasn,
    locstatuschg_exit_invstatus = ii.locstchg_exit_invstatus,
    locstatuschg_exit_adjreason = ii.locstchg_exit_adjreason 
where custid = ii.custid
  and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_handling_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_handling_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impihd', 0, ' ', 'Item Handling Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impispec', strMsg);
   update import_item_handling_table
      set load_sequence = new_seq
    where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
       err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpIHandling', 0, ' ', 'Item Handling Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impihandling', strMsg);
end end_itemhandling_validation;
procedure import_itemlabel
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_labelprofile           IN varchar2
,in_prtlps_on_load_arrival IN varchar2
,in_system_generated_lps   IN varchar2
,in_prtlps_profid          IN varchar2
,in_prtlps_def_handling    IN varchar2
,in_sscccasepackfromuom    IN varchar2
,in_sscccasepacktouom      IN varchar2
,in_prtlps_putaway_dir     IN varchar2
,out_errorno               IN OUT NUMBER
,out_msg                   IN OUT varchar2
) is
begin
if rtrim(in_custid) is null then
    out_errorno := -1;
    out_msg := 'Customer ID value is required';
    return;
end if;
if rtrim(in_item) is null then
    out_errorno := -1;
    out_msg := 'Item value is required';
    return;
end if;
update custitem
set labelprofile = in_labelprofile,
    prtlps_on_load_arrival = in_prtlps_on_load_arrival, 
    system_generated_lps = in_system_generated_lps,
    prtlps_profid = in_prtlps_profid,
    prtlps_def_handling = in_prtlps_def_handling,
    sscccasepackfromuom = in_sscccasepackfromuom,
	sscccasepacktouom = in_sscccasepacktouom,
	prtlps_putaway_dir = in_prtlps_putaway_dir
where custid = in_custid
  and item = in_item;
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
    out_msg := 'zimilb' || sqlerrm;
    out_errorno := sqlcode;
end import_itemlabel;
procedure import_itemlabel_validation
(in_custid                 IN varchar2
,in_item                   IN varchar2
,in_labelprofile           IN varchar2
,in_prtlps_on_load_arrival IN varchar2
,in_system_generated_lps   IN varchar2
,in_prtlps_profid          IN varchar2
,in_prtlps_def_handling    IN varchar2
,in_sscccasepackfromuom    IN varchar2
,in_sscccasepacktouom      IN varchar2
,in_prtlps_putaway_dir     IN varchar2
,out_errorno               IN OUT NUMBER
,out_msg                   IN OUT varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
  from import_item_label_table
 where load_sequence = 0;
recseq := recseq + 1;
insert into import_item_label_table
  (load_sequence, record_sequence, custid, item,
   labelprofile, prtlps_on_load_arrival, system_generated_lps,
   prtlps_profid, prtlps_def_handling, sscccasepackfromuom,
   sscccasepacktouom, prtlps_putaway_dir)
  values
  (0, recseq, in_custid, in_item,
   in_labelprofile, in_prtlps_on_load_arrival, in_system_generated_lps,
   in_prtlps_profid, in_prtlps_def_handling, in_sscccasepackfromuom,
   in_sscccasepacktouom, in_prtlps_putaway_dir);
   out_msg := 'OKAY';
   out_errorno := 0;
exception when others then
    out_msg := 'zimilbv ' || sqlerrm;
    out_errorno := sqlcode;
end import_itemlabel_validation;
procedure end_itemlabel_validation
(in_update   IN varchar2
,out_errorno IN OUT NUMBER
,out_msg     IN OUT varchar2
) is
ii_max  integer;
iie_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg  varchar2(255);
cursor C_II(in_seq integer)
return import_item_label_table%rowtype
is
  select *
    from import_item_label_table
   where load_sequence = in_seq
   order by record_sequence;
procedure err_msg
(ii in import_item_label_table%rowtype
,error_msg in varchar2) is
begin
insert into import_item_label_error
  (load_sequence, record_sequence, custid, item, comments)
 values
  (ii.load_sequence, ii.record_sequence, ii.custid, ii.item, error_msg);
end err_msg;
function cii_validation
(ii in import_item_label_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from customer
   where custid = ii.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer does not exist. ');
end if;
select count(1) into cntRows
   from custitem
   where custid = ii.custid
     and item = ii.item;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ii, 'Customer item does not exist. ');
end if;
if ii.labelprofile is not null then
   select count(1) into cntRows
     from labelprofiles
    where code = ii.labelprofile;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Label Profile: ' || ii.labelprofile);
   end if;
end if;
if ii.prtlps_on_load_arrival is not null then
   if ii.prtlps_on_load_arrival not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Print LPs On Load Arrival Yes/No: ' || ii.prtlps_on_load_arrival);
   end if;
end if;
if ii.system_generated_lps is not null then
   if ii.system_generated_lps not in ('Y','N','C') then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid System Generated LPs: ' || ii.system_generated_lps);
   end if;
end if;
if ii.prtlps_on_load_arrival = 'Y' and
   ii.prtlps_profid is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid Label Profile ID: ' || ii.prtlps_profid);
end if;
if ii.prtlps_on_load_arrival = 'Y' and
   ii.prtlps_def_handling is null then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid LP Labeling Default Handling Type: ' || ii.prtlps_profid);
end if;
if ii.sscccasepackfromuom is not null then
   select count(1) into cntRows
     from unitsofmeasure
    where code = ii.sscccasepackfromuom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid SSCC Case Pack From UOM: ' || ii.sscccasepackfromuom);
   end if;
end if;
if ii.sscccasepacktouom is not null then
   select count(1) into cntRows
     from unitsofmeasure
    where code = ii.sscccasepacktouom;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ii, 'Invalid SSCC Case Pack To UOM: ' || ii.sscccasepacktouom);
   end if;
end if;
if ii.prtlps_putaway_dir is not null then
   if ii.prtlps_putaway_dir not in ('Y','N') then
      out_err := out_err + 1;
      err_msg(ii, 'invalid Print Lps Putaway Dir.: ' || ii.prtlps_putaway_dir);
   end if;
end if;
return out_err;
exception when others then
  out_msg := 'zimpilb ' || sqlerrm || ii.item;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cii_validation;
procedure cii_update_item
(ii in import_item_label_table%rowtype)
is
out_err integer;
cntRows integer;
begin
update custitem
set labelprofile = ii.labelprofile,
    prtlps_on_load_arrival = ii.prtlps_on_load_arrival, 
    system_generated_lps = ii.system_generated_lps,
    prtlps_profid = ii.prtlps_profid,
    prtlps_def_handling = ii.prtlps_def_handling,
    sscccasepackfromuom = ii.sscccasepackfromuom,
	sscccasepacktouom = ii.sscccasepacktouom,
	prtlps_putaway_dir = ii.prtlps_putaway_dir 
where custid = ii.custid
  and item = ii.item;
end cii_update_item;
begin
   select nvl(max(load_sequence),0) into ii_max from import_item_label_table;
   select nvl(max(load_sequence),0) into iie_max from import_item_label_error;
   if ii_max > iie_max  then
      new_seq := ii_max;
   else
      new_seq := iie_max;
   end if;
   new_seq := new_seq + 1;
   zms.log_msg('impihd', 0, ' ', 'Item Label Import Sequence ' || to_char(new_seq, '9999'),
              'T', 'impilabel', strMsg);
   update import_item_label_table
      set load_sequence = new_seq
    where load_sequence = 0;
   err_cnt := 0;
   for cii in C_II(new_seq) loop
       err_cnt := err_cnt + cii_validation(cii);
   end loop;
   if in_update = 'Y' then
      if err_cnt = 0 then
         for cii in C_II(new_seq) loop
            cii_update_item(cii);
         end loop;
      end if;
   end if;
  commit;
  zms.log_msg('ImpILabel', 0, ' ', 'Item Label Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
             'T', 'impilabel', strMsg);
end end_itemlabel_validation;
end zimportproc11;
/

show error package body zimportproc11;
exit;
