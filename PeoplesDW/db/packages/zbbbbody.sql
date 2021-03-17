CREATE OR REPLACE PACKAGE BODY zbedbathbeyond
IS
--
-- $Id: zbbbbody.sql 7277 2011-09-24 06:31:18Z brianb $
--

type pooler_truckload_rcd is record
(loadno loads.loadno%type
,wave waves.wave%type
,shipto_master orderhdr.shipto_master%type
,weightorder loads.weightorder%type
,cubeorder loads.cubeorder%type
,weight_max loads.weightorder%type
,cube_max loads.cubeorder%type
);

type pooler_truckload_tbl is table of pooler_truckload_rcd
  index by binary_integer;
  
ptls pooler_truckload_tbl;
ptlx pls_integer;
ptlfoundx pls_integer;

type pooler_ltl_rcd is record
(loadno loads.loadno%type
,wave waves.wave%type
);

type pooler_ltl_tbl is table of pooler_ltl_rcd
  index by binary_integer;
  
pltls pooler_ltl_tbl;
pltlx pls_integer;
pltlfoundx pls_integer;

bbb_debug_on boolean := False;

cursor curWaves(in_wave number) is
  select wave, bbb_custid_template, facility
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

PROCEDURE set_debug_mode(in_mode boolean)
IS
BEGIN

  bbb_debug_on := nvl(in_mode,False);

END set_debug_mode;

PROCEDURE debug_msg
(in_text varchar2
,in_custid varchar2
,in_facility varchar2
,in_userid varchar2
)

is

l_char_count integer;
l_out_debug_txt varchar2(255);
l_text varchar2(4000);

BEGIN

if not bbb_debug_on then
  return;
end if;

l_text := wv.wave || ' ' || in_text;

l_char_count := 1;
while (l_char_count * 250) < (Length(l_text)+250)
loop
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_facility,
    in_custid   => in_custid,
    in_msgtext  => substr(l_text,((l_char_count-1)*250)+1,250),
    in_msgtype  => 'T',
    in_userid   => in_userid,
    out_msg		=> l_out_debug_txt);
  l_char_count := l_char_count + 1;
end loop;

exception when others then
    null;
END debug_msg;

function routing_control_value
(in_custid varchar2
,in_orderid number
,in_shipid number
) return varchar2

is

l_bbb_control_value_passthru customer_aux.bbb_control_value_passthru_col%type;
l_bbb_control_value orderhdr.hdrpassthruchar01%type;

begin

begin
  select bbb_control_value_passthru_col
    into l_bbb_control_value_passthru
    from customer_aux
   where custid = in_custid;
exception when others then
  return '?';
end;

execute immediate 'select ' || l_bbb_control_value_passthru || 
  ' from orderhdr where orderid = ' || in_orderid ||
  ' and shipid = ' || in_shipid
  into l_bbb_control_value;

return l_bbb_control_value;
  
exception when others then
  return '?';
end;

function is_a_bbb_order
(in_custid varchar2
,in_orderid number
,in_shipid number
) return varchar2

is

l_bbb_passthrufield customer_aux.bbb_passthrufield%type;
l_bbb_passthrufield_value orderhdr.hdrpassthruchar01%type;
l_order_passthrufield_value orderhdr.hdrpassthruchar01%type;

begin

begin
  select bbb_passthrufield, ',' || rtrim(bbb_passthrufield_value) || ','
    into l_bbb_passthrufield, l_bbb_passthrufield_value
    from customer_aux
   where custid = in_custid;
exception when others then
  return 'N';
end;

execute immediate 'select '','' || ' || rtrim(l_bbb_passthrufield) || 
  ' || '','' from orderhdr where orderid = ' || in_orderid ||
  ' and shipid = ' || in_shipid
  into l_order_passthrufield_value;

if instr(l_bbb_passthrufield_value, l_order_passthrufield_value) != 0 then
  return 'Y';
else
  return 'N';
end if;
  
exception when others then
  return 'N';
end is_a_bbb_order;

function distance_to_consignee
(in_shipto varchar2
,in_fromfacility varchar2
) return integer

is

l_out_mileage consignee_mileage.mileage%type;

begin

select mileage
  into l_out_mileage
  from consignee_mileage
 where consignee = in_shipto
   and fromfacility = in_fromfacility;

return l_out_mileage;
   
exception when others then
  return 0;
end;

function oversize_carton_type
(in_custid varchar2
,in_bbb_custid_template varchar2
,in_item varchar2
,in_uom varchar2
)
return varchar2

is

l_out_oversize_carton_type varchar2(3);
l_length custitemuom.length%type;
l_width custitemuom.width%type;
l_height custitemuom.height%type;
l_weight custitemuom.weight%type;
l_girth custitemuom.length%type;
l_girth_plus_length custitemuom.length%type;
l_bbb_oversize_1_min_girth number(3);
l_bbb_oversize_2_min_girth number(3);
l_bbb_oversize_3_min_girth number(3);

begin

l_out_oversize_carton_type := 'NOT';

begin
  select length, width, height, weight
    into l_length, l_width, l_height, l_weight
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_uom;
exception when others then
  return 'NOT';
end;

begin
  select nvl(bbb_oversize_1_min_girth,0),
         nvl(bbb_oversize_2_min_girth,0),
         nvl(bbb_oversize_3_min_girth,0)
    into l_bbb_oversize_1_min_girth,
         l_bbb_oversize_2_min_girth,
         l_bbb_oversize_3_min_girth
    from customer_aux
   where custid = in_bbb_custid_template;
exception when others then
  l_bbb_oversize_1_min_girth := 0;
  l_bbb_oversize_2_min_girth := 0;
  l_bbb_oversize_2_min_girth := 0;
end;

l_girth := (l_width * 2) + (l_height * 2);
l_girth_plus_length := l_girth + l_length;

if (l_girth_plus_length > l_bbb_oversize_3_min_girth) then
  l_out_oversize_carton_type := 'OS3';
elsif (l_girth_plus_length > l_bbb_oversize_2_min_girth) then
  l_out_oversize_carton_type := 'OS2';
elsif (l_girth_plus_length > l_bbb_oversize_3_min_girth) then
  l_out_oversize_carton_type := 'OS1';
end if;

return l_out_oversize_carton_type;
  
exception when others then
  return 'NOT';
end oversize_carton_type;

procedure compute_carton_count
(in_orderid number
,in_shipid number
,in_item varchar2
,in_userid varchar2
,out_carton_uom IN OUT varchar2
,out_carton_count IN OUT number
)
is

cursor curOrderHdr is
  select custid, fromfacility
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl(in_bbb_carton_uom varchar2, in_default_carton_uom varchar2) is
  select od.qtyorder / nvl(decode(ci.baseuom, in_bbb_carton_uom, 1, nvl(ciu.qty,1)), 1) qtycarton
    from orderdtl od, custitem ci, custitemuom ciu
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = nvl(in_item, od.item)
     and ci.custid = od.custid
     and ci.item = od.item
     and ciu.custid = ci.custid
     and ciu.item = ci.item
     and ciu.touom <> 'K'
     and ((ci.baseuom = in_bbb_carton_uom
     and   ciu.fromuom = ci.baseuom)
      or  (ci.baseuom = 'EA'
     and   ciu.touom = nvl(ci.labeluom,in_default_carton_uom)))
     and ciu.sequence=(
       select min(sequence)
         from custitemuom
        where custid=ci.custid
          and item=ci.item
          and touom <> 'K'
          and ((ci.baseuom = in_default_carton_uom
          and   fromuom = ci.baseuom)
           or  (ci.baseuom = 'EA'
          and   touom = nvl(ci.labeluom,in_bbb_carton_uom))))
   union all
  select od.qtyorder qtycarton
    from orderdtl od, custitem ci
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = nvl(in_item, od.item)
     and ci.custid = od.custid
     and ci.item = od.item
     and ci.baseuom = in_bbb_carton_uom
     and not exists(
       select 1
         from custitemuom ciu
        where ciu.custid = ci.custid
          and ciu.item = ci.item
          and ciu.touom <> 'K'
          and ciu.fromuom = ci.baseuom);
od curOrderDtl%rowtype;

l_carton_qty pls_integer;
l_bbb_carton_uom customer_aux.bbb_carton_uom%type := null;
l_default_carton_uom customer_aux.bbb_carton_uom%type := null;
l_out_msg varchar2(255);
l_err_msg varchar2(255);
l_sql varchar2(4000);

begin

out_carton_uom := null;
out_carton_count := 0;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

begin
  select bbb_carton_uom
    into l_bbb_carton_uom
    from customer_aux
   where custid = oh.custid;
exception when others then
  l_bbb_carton_uom := null;
end;

if l_bbb_carton_uom is null then
  begin
    select bbb_carton_uom
      into l_bbb_carton_uom
      from customer_aux
     where custid = wv.bbb_custid_template;
  exception when others then
    l_bbb_carton_uom := null;
  end;
end if;

begin
  select trim(upper(substr(zci.default_value('CARTONSUOM'),1,4)))
    into l_default_carton_uom
    from dual;
exception when others then
  l_bbb_carton_uom := 'CTN';
end;

for od in curOrderDtl(nvl(l_bbb_carton_uom,l_default_carton_uom),l_default_carton_uom)
loop
  out_carton_count := out_carton_count + od.qtycarton;
end loop;

exception when others then
 l_err_msg := 'ccc ' || sqlerrm;
 zms.log_autonomous_msg(	
   in_author   => zbbb.AUTHOR,
   in_facility => wv.facility,
   in_custid   => wv.bbb_custid_template,
   in_msgtext  => l_err_msg,
   in_msgtype  => 'E',
   in_userid   => in_userid,
   out_msg		=> l_out_msg);
end compute_carton_count;

FUNCTION zipcode_matches
(in_zipcode varchar2
,in_zipcode_match varchar2
) return boolean

is

l_length pls_integer;

begin

if in_zipcode_match = '(DEFAULT)' then
  return TRUE;
end if;

l_length := length(trim(in_zipcode_match));

if substr(in_zipcode,1,l_length) = trim(in_zipcode_match) then
  return TRUE;
else
  return FALSE;
end if;

exception when others then
 return FALSE;
end zipcode_matches;

FUNCTION assigned_ltl_carrier
(in_custid varchar2
,in_fromfacility varchar2
,in_shipto varchar2
,in_effdate date
) return varchar2

is

l_fac_countrycode facility.countrycode%type;
l_fac_state facility.state%type;
l_fac_postalcode facility.postalcode%type;
l_con_countrycode consignee.countrycode%type;
l_con_state consignee.state%type;
l_con_postalcode consignee.postalcode%type;

begin

begin
  select countrycode, state, postalcode
    into l_fac_countrycode, l_fac_state, l_fac_postalcode
    from facility
   where facility = in_fromfacility;
exception when others then
  return zbbb.routing_request_carrier(in_custid);
end;

begin
  select countrycode, state, postalcode
    into l_con_countrycode, l_con_state, l_con_postalcode
    from consignee
   where consignee = in_shipto;
exception when others then
  return zbbb.routing_request_carrier(in_custid);
end;

for CA in (select from_zipcode_match, to_zipcode_match, ltl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match like substr(l_fac_postalcode,1,3) || '%'
              and to_zipcode_match like substr(l_con_postalcode,1,3) || '%'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(to_zipcode_match) desc)
loop

  if zbbb.zipcode_matches(l_fac_postalcode,CA.from_zipcode_match) = True and
     zbbb.zipcode_matches(l_con_postalcode,CA.to_zipcode_match) = True then
    return CA.ltl_carrier;
  end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, ltl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match = '(DEFAULT)'
              and to_zipcode_match like substr(l_con_postalcode,1,3) || '%'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(to_zipcode_match) desc)
loop

 if zbbb.zipcode_matches(l_con_postalcode,CA.to_zipcode_match) = True then
   return CA.ltl_carrier;
 end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, ltl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match like substr(l_fac_postalcode,1,3) || '%'
              and to_zipcode_match = '(DEFAULT)'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(from_zipcode_match) desc)
loop

 if zbbb.zipcode_matches(l_fac_postalcode,CA.from_zipcode_match) = True then
   return CA.ltl_carrier;
 end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, ltl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match = '(DEFAULT)'
              and to_zipcode_match = '(DEFAULT)'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate)))
loop

   return CA.ltl_carrier;

end loop;

return zbbb.routing_request_carrier(in_custid);

exception when others then
 return zbbb.routing_request_carrier(in_custid);
end assigned_ltl_carrier;

FUNCTION assigned_tl_carrier
(in_custid varchar2
,in_fromfacility varchar2
,in_shipto varchar2
,in_effdate date
) return varchar2

is

l_fac_countrycode facility.countrycode%type;
l_fac_state facility.state%type;
l_fac_postalcode facility.postalcode%type;
l_con_countrycode consignee.countrycode%type;
l_con_state consignee.state%type;
l_con_postalcode consignee.postalcode%type;

begin

begin
  select countrycode, state, postalcode
    into l_fac_countrycode, l_fac_state, l_fac_postalcode
    from facility
   where facility = in_fromfacility;
exception when others then
  return zbbb.routing_request_carrier(in_custid);
end;

begin
  select countrycode, state, postalcode
    into l_con_countrycode, l_con_state, l_con_postalcode
    from consignee
   where consignee = in_shipto;
exception when others then
  return zbbb.routing_request_carrier(in_custid);
end;

for CA in (select from_zipcode_match, to_zipcode_match, tl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match like substr(l_fac_postalcode,1,3) || '%'
              and to_zipcode_match like substr(l_con_postalcode,1,3) || '%'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(to_zipcode_match))
loop

  if zbbb.zipcode_matches(l_fac_postalcode,CA.from_zipcode_match) = True and
     zbbb.zipcode_matches(l_con_postalcode,CA.to_zipcode_match) = True then
    return CA.tl_carrier;
  end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, tl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match = '(DEFAULT)'
              and to_zipcode_match like substr(l_con_postalcode,1,3) || '%'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(to_zipcode_match))
loop

 if zbbb.zipcode_matches(l_con_postalcode,CA.to_zipcode_match) = True then
   return CA.tl_carrier;
 end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, tl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match like substr(l_fac_postalcode,1,3) || '%'
              and to_zipcode_match = '(DEFAULT)'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate))
            order by length(from_zipcode_match))
loop

 if zbbb.zipcode_matches(l_fac_postalcode,CA.from_zipcode_match) = True then
   return CA.tl_carrier;
 end if;   

end loop;

for CA in (select from_zipcode_match, to_zipcode_match, tl_carrier
             from bbb_carrier_assignment a
            where custid = in_custid
              and from_countrycode = l_fac_countrycode
              and from_state = l_fac_state
              and to_countrycode = l_con_countrycode
              and to_state = l_con_state
              and from_zipcode_match = '(DEFAULT)'
              and to_zipcode_match = '(DEFAULT)'
              and effdate = 
                  (select max(effdate)
                     from bbb_carrier_assignment b
                    where custid = in_custid
                      and from_countrycode = l_fac_countrycode
                      and from_state = l_fac_state
                      and to_countrycode = l_con_countrycode
                      and to_state = l_con_state
                      and b.from_zipcode_match = a.from_zipcode_match
                      and b.to_zipcode_match = a.to_zipcode_match
                      and b.effdate <= trunc(in_effdate)))
loop

   return CA.tl_carrier;

end loop;

return zbbb.routing_request_carrier(in_custid);

exception when others then
  return zbbb.routing_request_carrier(in_custid);
end assigned_tl_carrier;

PROCEDURE submit_uncommit_wave_job
(in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what like 'zbbb.uncommit_wave%' || in_wave || '%';
 
JB user_jobs%rowtype;

l_cnt pls_integer;
l_msg varchar2(255);
l_cmd varchar2(1000);

begin

  out_msg := 'OKAY';
  out_errorno := 0;
  
  l_cmd := 'zbbb.uncommit_wave(' ||
            in_wave || ',''' ||
            in_userid || ''');';

  JB := null;

  OPEN C_JOB;
  FETCH C_JOB into JB;
  CLOSE C_JOB;

  if JB.job is null then
    dbms_job.submit(JB.job, l_cmd, sysdate);
  else
    out_errorno := -1;
    out_msg := 'The uncommit of wave ' || in_wave ||
               'is already in progess. (Job number: ' ||
               JB.job || ')';
  end if;

  
exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end submit_uncommit_wave_job;

PROCEDURE uncommit_wave
(in_wave number
,in_userid varchar2
)

is

l_msg varchar2(255);
l_outmsg varchar2(255);

begin

for oh in (select orderid,shipid,fromfacility,custid
             from orderhdr
            where wave = in_wave)
loop

  l_msg := 'uncommitjob';
  zcm.uncommit_order(oh.orderid,oh.shipid,oh.fromfacility,
    in_userid,'1',in_wave,l_msg);
  if l_msg <> 'OKAY' then
    zms.log_autonomous_msg(	
      in_author   => zbbb.AUTHOR,
      in_facility => oh.fromfacility,
      in_custid   => oh.custid,
      in_msgtext  => 'zbbb.uw ' || substr(l_msg,1,200),
      in_msgtype  => 'E',
      in_userid   => in_userid,
      out_msg		=> l_outmsg);
  end if;
  
end loop;

exception when others then
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => '',
    in_custid   => '',
    in_msgtext  => 'zbbb.uw ' || substr(sqlerrm,1,200),
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end uncommit_wave;

PROCEDURE assign_pool_tl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,in_bbb_pooler_shipto varchar2
,in_generate_p_and_c_waves_by varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_msg varchar2(255);
l_split_truck_msg varchar2(255);
l_wave waves.wave%type;
l_bbb_small_package_carrier customer_aux.bbb_small_package_carrier%type;
l_wave_descr waves.descr%type;
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_carrier carrier.carrier%type;
l_delpointtype loadstop.delpointtype%type;
l_weight_to_exclude orderhdr.weightorder%type;
l_cube_to_exclude orderhdr.cubeorder%type;
l_multi_truck_count pls_integer;

cursor curOrderToExcludeCubeDesc(in_shipto varchar2,
                                 in_shiptocountrycode varchar2,
                                 in_cube_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and cubeorder <= in_cube_to_exclude
   order by cubeorder desc;
exohc curOrderToExcludeCubeDesc%rowtype;

cursor curOrderToExcludeWeightDesc(in_shipto varchar2,
                                   in_shiptocountrycode varchar2,
                                   in_weight_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and weightorder <= in_weight_to_exclude
   order by weightorder desc;
exohw curOrderToExcludeWeightDesc%rowtype;
   

cursor curOrderToExcludeCubeAsc(in_shipto varchar2,
                                in_shiptocountrycode varchar2,
                                in_cube_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and cubeorder >= in_cube_to_exclude
   order by cubeorder;

cursor curOrderToExcludeWeightAsc(in_shipto varchar2,
                                  in_shiptocountrycode varchar2,
                                  in_weight_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and weightorder >= in_weight_to_exclude
   order by weightorder;
   

begin

out_errorno := 0;
out_msg := 'OKAY';

delete from bbb_excluded_orders_tmp;

l_multi_truck_count := 0;
   
for shp in (select *
              from bbb_routing_shipment_tmp
             where routing_status = 'TRUCK'
             order by bbb_shipto_master,order_shipto_master)
loop

  debug_msg('assign pool tl shipment ' || 
            shp.bbb_shipto_master || ' ' ||
            shp.order_shipto_master || ' ' ||
            shp.weight || ' ' ||
            shp.weight_max || ' ' ||
            shp.cube || ' ' ||
            shp.cube_max || ' ' ||
            shp.carton_count || ' ' ||
            shp.direct_to_store_yn,
            wv.bbb_custid_template,wv.facility,'debug');
            
  if (shp.cube > shp.cube_max) or
     (shp.weight > shp.weight_max) then  

    l_multi_truck_count := l_multi_truck_count + 1;
    
    debug_msg('MultiTruck Pool Store Shipment for ' || shp.bbb_shipto_master ||
              ' ' || shp.weight || ' ' || shp.cube || ' ' || shp.weight_max ||
              ' ' || shp.cube_max,
              wv.bbb_custid_template,wv.facility,'debug');
      
    while (shp.cube > shp.cube_max)
    loop
      debug_msg('pool tl overcube ' || 
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.cube || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
      l_cube_to_exclude := shp.cube - shp.cube_max;
      exohc := null;
      open curOrderToExcludeCubeDesc(shp.bbb_shipto_master,
                                     shp.shiptocountrycode,l_cube_to_exclude);
      fetch curOrderToExcludeCubeDesc into exohc;
      close curOrderToExcludeCubeDesc;
      if exohc.cubeorder is null then
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohc.orderid,exohc.shipid);
      debug_msg('pool exordcubedesc ' || 
                exohc.orderid || '-' ||
                exohc.shipid || ' ' ||
                shp.bbb_shipto_master || ' ' ||
                shp.order_shipto_master || ' ' ||
                shp.weight || ' ' ||
                shp.cube || ' ' ||
                shp.weight_max || ' ' ||
                shp.cube_max || ' ' ||
                shp.carton_count || ' ' ||
                shp.direct_to_store_yn,
                wv.bbb_custid_template,wv.facility,'debug');
      l_cube_to_exclude := l_cube_to_exclude - exohc.cubeorder;
      shp.weight := shp.weight - exohc.weightorder;
      shp.cube := shp.cube - exohc.cubeorder;
    end loop;
    
    while (shp.weight > shp.weight_max)
    loop
      debug_msg('pool tl overweight ' || 
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.cube || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
      l_weight_to_exclude := shp.weight - shp.weight_max;
      exohw := null;
      open curOrderToExcludeWeightDesc(shp.bbb_shipto_master,
                                       shp.shiptocountrycode,l_cube_to_exclude);
      fetch curOrderToExcludeWeightDesc into exohw;
      close curOrderToExcludeWeightDesc;
      if exohw.weightorder is null then
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohw.orderid,exohw.shipid);
      debug_msg('pool exordweightdesc ' || 
                exohw.orderid || ' ' ||
                shp.bbb_shipto_master || ' ' ||
                shp.weight || ' ' ||
                shp.cube || ' ' ||
                shp.order_shipto_master || ' ' ||
                shp.weight_max || ' ' ||
                shp.cube_max || ' ' ||
                shp.carton_count || ' ' ||
                shp.direct_to_store_yn,
                wv.bbb_custid_template,wv.facility,'debug');
      l_weight_to_exclude := l_weight_to_exclude - exohw.cubeorder;
      shp.weight := shp.weight - exohw.weightorder;
      shp.cube := shp.cube - exohw.cubeorder;
    end loop;
    
    while (shp.cube > shp.cube_max)
    loop
      debug_msg('pool tl overcube ' || 
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.cube || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
      l_cube_to_exclude := shp.cube - shp.cube_max;
      exohc := null;
      open curOrderToExcludeCubeAsc(shp.bbb_shipto_master,shp.shiptocountrycode,
                                    l_cube_to_exclude);
      fetch curOrderToExcludeCubeAsc into exohc;
      close curOrderToExcludeCubeAsc;
      if (exohc.cubeorder is null) or
         (exohc.cubeorder = shp.cube) then
        l_split_truck_msg := 'Unable to split off order for cube ' || shp.bbb_shipto_master ||
          ' Cube: ' || shp.cube || ' Max Cube: ' || shp.cube_max || ' (' ||
          l_cube_to_exclude || ')';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => l_split_truck_msg,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohc.orderid,exohc.shipid);
      debug_msg('pool exordcubeasc ' || 
                exohc.orderid || '-' ||
                exohc.shipid || ' ' ||
                shp.bbb_shipto_master || ' ' ||
                shp.order_shipto_master || ' ' ||
                shp.weight || ' ' ||
                shp.cube || ' ' ||
                shp.weight_max || ' ' ||
                shp.cube_max || ' ' ||
                shp.carton_count || ' ' ||
                shp.direct_to_store_yn,
                wv.bbb_custid_template,wv.facility,'debug');
      l_cube_to_exclude := l_cube_to_exclude - exohc.cubeorder;
      shp.weight := shp.weight - exohc.weightorder;
      shp.cube := shp.cube - exohc.cubeorder;
    end loop;
    
    while (shp.weight > shp.weight_max)
    loop
      debug_msg('pool tl overweight ' || 
              shp.cube || ' ' ||
              shp.bbb_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.cube || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
      l_weight_to_exclude := shp.weight - shp.weight_max;
      exohw := null;
      open curOrderToExcludeWeightAsc(shp.bbb_shipto_master,shp.shiptocountrycode,
                                      l_cube_to_exclude);
      fetch curOrderToExcludeWeightAsc into exohw;
      close curOrderToExcludeWeightAsc;
      if exohw.weightorder is null then
        l_split_truck_msg := 'Unable to split off order for weight ' || shp.bbb_shipto_master ||
          ' Weight: ' || shp.weight || ' Max Weight: ' || shp.weight_max || ' (' ||
          l_weight_to_exclude || ')';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => l_split_truck_msg,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohw.orderid,exohw.shipid);
      debug_msg('pool exordweightasc ' || 
                exohw.orderid || ' ' ||
                shp.bbb_shipto_master || ' ' ||
                shp.weight || ' ' ||
                shp.cube || ' ' ||
                shp.order_shipto_master || ' ' ||
                shp.weight_max || ' ' ||
                shp.cube_max || ' ' ||
                shp.carton_count || ' ' ||
                shp.direct_to_store_yn,
                wv.bbb_custid_template,wv.facility,'debug');
      l_weight_to_exclude := l_weight_to_exclude - exohw.cubeorder;
      shp.weight := shp.weight - exohw.weightorder;
      shp.cube := shp.cube - exohw.cubeorder;
    end loop;
    
  end if;
  
  l_wave := 0;
  l_loadno := 0;
  
  if (in_bbb_pooler_shipto = shp.bbb_shipto_master) then
    ptlfoundx := 0;
    if in_generate_p_and_c_waves_by = 'L' then
      for ptlx in 1..ptls.count
      loop
        if (shp.weight + ptls(ptlx).weightorder <= ptls(ptlx).weight_max) and
           (shp.cube + ptls(ptlx).cubeorder <= ptls(ptlx).cube_max) then
          ptlfoundx := ptlx;
          exit;
        end if;        
      end loop;
    else
      for ptlx in 1..ptls.count
      loop
        if (shp.weight + ptls(ptlx).weightorder <= ptls(ptlx).weight_max) and
           (shp.cube + ptls(ptlx).cubeorder <= ptls(ptlx).cube_max) and
           (shp.order_shipto_master = ptls(ptlx).shipto_master) then
          ptlfoundx := ptlx;
          exit;
        end if;        
      end loop;
    end if;
    if ptlfoundx != 0 then
      ptlx := ptlfoundx;
      l_wave := ptls(ptlx).wave;
      l_loadno := ptls(ptlx).loadno;
    else
      ptlx := ptls.count + 1;
      ptls(ptlx).shipto_master := shp.order_shipto_master;
      ptls(ptlx).weightorder := 0;
      ptls(ptlx).cubeorder := 0;
      ptls(ptlx).weight_max := shp.weight_max;
      ptls(ptlx).cube_max := shp.cube_max;
    end if;
    ptls(ptlx).weightorder := ptls(ptlx).weightorder + shp.weight;
    ptls(ptlx).cubeorder := ptls(ptlx).cubeorder + shp.cube;
  end if;

  if l_wave = 0 then
    zwv.get_next_wave(l_wave, l_msg);
    if substr(l_msg, 1, 4) = 'OKAY' then
       if (in_bbb_pooler_shipto = shp.bbb_shipto_master) then
         ptls(ptlx).wave := l_wave;
       end if;       
       l_wave_descr := rtrim(in_control_value) || ' Pooler Truckload Shipment to ' ||
                       shp.bbb_shipto_master;
       insert into waves
          (wave, descr, wavestatus, schedrelease, actualrelease,
           facility, lastuser, lastupdate, stageloc, picktype,
           taskpriority, sortloc, job, childwave, batchcartontype,
           fromlot, tolot, orderlimit, openfacility, cntorder,
           qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
           cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
           consolidated, shiptype, carrier, servicelevel, shipcost,
           weight, tms_status, tms_status_update, mass_manifest,
           pick_by_zone, master_wave,
           bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
       select l_wave, l_wave_descr, '2', null, null,
           in_fromfacility, in_userid, sysdate, null, 'BAT', -- batch pick type
           W.taskpriority, null, null, null, W.batchcartontype,
           W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
           null, null, null, null, null,
           null, null, null, null, null,
           'Y', -- consolidated order pick
           W.shiptype, W.carrier, W.servicelevel, W.shipcost,
           null, W.tms_status, W.tms_status_update, W.mass_manifest,
           W.pick_by_zone, in_wave,
           bbb_custid_template, 'Y', nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
         from waves W
        where W.wave = in_wave;
    else
      out_errorno := -1;
      out_msg := 'Unable to assign truckload wave number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

  end if;

  if (shp.bbb_shipto_master = in_bbb_pooler_shipto) and
     (shp.direct_to_store_yn = 'N')  then
    l_carrier := in_bbb_pooler_shipto;
    debug_msg('apts carrier ps ' || l_carrier || ' ' || shp.bbb_shipto_master || ' ' || in_bbb_pooler_shipto,
              in_custid, in_fromfacility, 'carrier');
  else
    l_carrier := zbbb.assigned_tl_carrier(in_custid,in_fromfacility,
                                          shp.bbb_shipto_master,sysdate);
    debug_msg('apts carrier pa ' || l_carrier, in_custid, in_fromfacility, 'carrier');
  end if;
                                        
  if l_loadno = 0 then  
  
    zld.get_next_loadno(l_loadno, l_msg);
    if l_msg != 'OKAY' then
      out_errorno := -2;
      out_msg := 'Unable to get truckload load number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;
    
    if (in_bbb_pooler_shipto = shp.bbb_shipto_master) then
      ptls(ptlx).loadno := l_loadno;
    end if;
    
    insert into loads
      (loadno, entrydate, loadstatus, facility, carrier,
       statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
    values
        (l_loadno, sysdate, '2', in_fromfacility, l_carrier,
         in_userid, sysdate, in_userid, sysdate, 'OUTC', 'T');

  end if;
  
  l_stopno := 1;
  if shp.direct_to_store_yn = 'Y' then
    l_delpointtype := 'C';
  else
    l_delpointtype := 'D';
  end if;

  begin
    insert into loadstop
      (loadno, stopno, entrydate, loadstopstatus,
       statususer, statusupdate, lastuser, lastupdate, facility,
       delpointtype, shipto)
      values
      (l_loadno, l_stopno, sysdate, '2',
       in_userid, sysdate, in_userid, sysdate, wv.facility,
       l_delpointtype, shp.order_shipto_master);
  exception when dup_val_on_index then
    null;
  end;
  
  for oh in (select orderid,shipid,shipto,rowid
               from orderhdr
              where wave = in_wave
                and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master)
                and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
                and (orderid,shipid) not in
                      (select orderid,shipid
                        from bbb_excluded_orders_tmp))
  loop
    
    l_shipno := 1;
    begin
      insert into loadstopship
        (loadno, stopno, shipno, entrydate,
         qtyorder, weightorder, cubeorder, amtorder,
         qtyship, weightship, cubeship, amtship,
         qtyrcvd, weightrcvd, cubercvd, amtrcvd,
         lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
        values
        (l_loadno, l_stopno, l_shipno, sysdate,
         0, 0, 0, 0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         in_userid, sysdate, 0, 0);
    exception when dup_val_on_index then
      null;
    end;
    
    update orderhdr
       set wave = l_wave,
           shiptype = 'T',
           carrier = l_carrier
     where rowid = oh.rowid;
       
    zld.assign_outbound_order_to_load(oh.orderid,oh.shipid,l_carrier,null,
            null,null,null,null,in_fromfacility,zbbb.AUTHOR,
            l_loadno,l_stopno,l_shipno,l_msg);
    
    if substr(l_msg,1,4) <> 'OKAY' then
      out_errorno := -4;
      out_msg := 'Unable to assign order ' || oh.orderid || '-' || oh.shipid ||
          ' to load ' || l_loadno || '. ' || chr(13) || l_msg;
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;
    
  end loop;

  update waves
     set consolidated = 'Y'
   where wave = l_wave;
   
  if l_multi_truck_count != 0 then
    debug_msg('Rerouting after pooled multitruck store shipment',
              wv.bbb_custid_template,wv.facility,'debug');
    return;
  end if;
  
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_fromfacility,
    in_custid   => in_custid,
    in_msgtext  => out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end assign_pool_tl_shipments;

PROCEDURE assign_pool_ltl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_generate_p_and_c_waves_by varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_msg varchar2(255);
l_wave waves.wave%type;
l_count pls_integer;
l_bbb_small_package_carrier customer_aux.bbb_small_package_carrier%type;
l_wave_descr waves.descr%type;
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_prev_carrier carrier.carrier%type;
l_cube_max bbb_routing_shipment_tmp.cube_max%type;
l_weight_max bbb_routing_shipment_tmp.weight_max%type;
l_cube_accum loads.cubeorder%type;
l_weight_accum loads.weightorder%type;
l_delpointtype loadstop.delpointtype%type;
l_wave_consolidated waves.consolidated%type;
l_wave_picktype waves.picktype%type;
l_loop_count pls_integer;
l_wave_batch_pick_by_item_yn waves.batch_pick_by_item_yn%type;

begin

out_errorno := 0;
out_msg := 'OKAY';
l_prev_carrier := 'x';

l_loop_count := 0;

delete from bbb_excluded_shipments_tmp;
   
for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where routing_status = 'LTL'
             order by carrier, mileage)
loop

  debug_msg('pool ltl shipment ' || 
          shp.bbb_shipto_master || ' ' ||
          shp.weight || ' ' ||
          shp.cube || ' ' ||
          shp.order_shipto_master || ' ' ||
          shp.weight_max || ' ' ||
          shp.cube_max || ' ' ||
          shp.carton_count || ' ' ||
          shp.direct_to_store_yn || ' ' ||
          shp.carrier,
          wv.bbb_custid_template,wv.facility,'debug');
          
  l_loop_count := l_loop_count + 1;
  
  if (shp.carrier != l_prev_carrier) or
     (shp.direct_to_store_yn = 'Y') then

    select count(1)
      into l_count
      from bbb_excluded_shipments_tmp;
    if l_count != 0 then
      return;
    end if;
    
    zld.get_next_loadno(l_loadno, l_msg);
    if l_msg != 'OKAY' then
      out_errorno := -2;
      out_msg := 'Unable to assign ltl load number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

    insert into loads
      (loadno, entrydate, loadstatus, facility, carrier,
       statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
    values
        (l_loadno, sysdate, '2', in_fromfacility, shp.carrier,
         in_userid, sysdate, in_userid, sysdate, 'OUTC', 'L');

    l_stopno := 0;
    l_cube_accum := 0;
    l_weight_accum := 0;
    l_prev_carrier := shp.carrier;
    
    debug_msg('ltlp-insert loads ' ||
              l_loadno || ' ' ||
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
              
  elsif (l_weight_accum + shp.weight > shp.weight_max) or
        (l_cube_accum + shp.cube > shp.cube_max) then
        
    insert into bbb_excluded_shipments_tmp
      (shiptocountrycode,bbb_shipto_master,order_shipto_master,
       weight,cube)
      values
      (shp.shiptocountrycode,shp.bbb_shipto_master,shp.order_shipto_master,
       shp.weight,shp.cube);
       
    goto continue_shipment_loop;
    
  end if;

  l_weight_accum := l_weight_accum + shp.weight;
  l_cube_accum := l_cube_accum + shp.cube;

  l_wave := 0;
  
  if in_generate_p_and_c_waves_by = 'L' then
    pltlfoundx := 0;
    for pltlx in 1..pltls.count
    loop
      if (l_loadno = pltls(pltlx).loadno) then
        pltlfoundx := pltlx;
        exit;
      end if;
    end loop;
    if pltlfoundx != 0 then
      pltlx := pltlfoundx;
      l_wave := pltls(pltlx).wave;
    else
      pltlx := pltls.count + 1;
      pltls(pltlx).loadno := l_loadno;
      pltls(pltlx).wave := 0;
    end if;
  end if;
  
  debug_msg('ltlp-wave is ' || 
          l_wave || ' ' ||
          shp.bbb_shipto_master || ' ' ||
          shp.weight || ' ' ||
          shp.cube || ' ' ||
          shp.order_shipto_master || ' ' ||
          shp.weight_max || ' ' ||
          shp.cube_max || ' ' ||
          shp.carton_count || ' ' ||
          shp.direct_to_store_yn || ' ' ||
          shp.carrier,
          wv.bbb_custid_template,wv.facility,'debug');
          
  if l_wave = 0 then
  
    zwv.get_next_wave(l_wave, l_msg);
    
    if in_generate_p_and_c_waves_by = 'L' then
      pltls(pltlx).wave := l_wave;
   end if;
    
    if (shp.direct_to_store_yn = 'Y') or
       (substr(zbbb.is_consolidator(shp.bbb_shipto_master),1,1) = 'N') then
      l_wave_consolidated := 'N';
      l_wave_picktype := 'ORDR';
      l_wave_batch_pick_by_item_yn := 'N';
    else
      l_wave_consolidated := 'Y';
      l_wave_picktype := 'BAT';
      l_wave_batch_pick_by_item_yn := 'Y';
    end if;
    
    if substr(l_msg, 1, 4) = 'OKAY' then
       l_wave_descr := rtrim(in_control_value) || ' Pooler LTL Shipment to ' || 
                       shp.bbb_shipto_master;
       if shp.bbb_shipto_master != shp.order_shipto_master then
         l_wave_descr := l_wave_descr || ' (' || shp.order_shipto_master || ')';
       end if;
       insert into waves
          (wave, descr, wavestatus, schedrelease, actualrelease,
           facility, lastuser, lastupdate, stageloc, picktype,
           taskpriority, sortloc, job, childwave, batchcartontype,
           fromlot, tolot, orderlimit, openfacility, cntorder,
           qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
           cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
           consolidated, shiptype, carrier, servicelevel, shipcost,
           weight, tms_status, tms_status_update, mass_manifest,
           pick_by_zone, master_wave,
           bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
       select l_wave, l_wave_descr, '2', null, null,
           in_fromfacility, in_userid, sysdate, null, l_wave_picktype,
           W.taskpriority, null, null, null, W.batchcartontype,
           W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
           null, null, null, null, null,
           null, null, null, null, null,
           'N', W.shiptype, W.carrier, W.servicelevel, W.shipcost,
           null, W.tms_status, W.tms_status_update, W.mass_manifest,
           W.pick_by_zone, in_wave,
           W.bbb_custid_template, l_wave_batch_pick_by_item_yn, nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
         from waves W
        where W.wave = in_wave;
    else
      out_errorno := -1;
      out_msg := 'Unable to assign pooler ltl wave number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;
    
  end if;
  
  if (shp.direct_to_store_yn = 'Y') then
    l_delpointtype := 'C';
  else
    l_delpointtype := 'D';
  end if;

  l_stopno := l_stopno + 1;
  
  debug_msg('ltlp-stop is ' || 
          l_stopno || ' ' ||
          shp.bbb_shipto_master || ' ' ||
          shp.weight || ' ' ||
          shp.cube || ' ' ||
          shp.order_shipto_master || ' ' ||
          shp.weight_max || ' ' ||
          shp.cube_max || ' ' ||
          shp.carton_count || ' ' ||
          shp.direct_to_store_yn || ' ' ||
          shp.carrier,
          wv.bbb_custid_template,wv.facility,'debug');
          
  begin  
    insert into loadstop
      (loadno, stopno, entrydate, loadstopstatus,
       statususer, statusupdate, lastuser, lastupdate, facility,
       delpointtype, shipto)
      values
      (l_loadno, l_stopno, sysdate, '2',
       in_userid, sysdate, in_userid, sysdate, in_fromfacility,
       l_delpointtype, shp.order_shipto_master);
  exception when dup_val_on_index then
    null;
  end;
  
  for oh in (select orderid,shipid,shipto,shipto_master,rowid
               from orderhdr
              where wave = in_wave
                and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
                and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master))
  loop
    
    l_shipno := 1;
  
    debug_msg('pool ltl orderhdr update ' || 
            oh.orderid || ' ' ||
            oh.shipid || ' ' ||
            oh.shipto || ' ' ||
            nvl(oh.shipto_master,'(mast)'),
            wv.bbb_custid_template,wv.facility,'debug');
            
    begin  
      insert into loadstopship
        (loadno, stopno, shipno, entrydate,
         qtyorder, weightorder, cubeorder, amtorder,
         qtyship, weightship, cubeship, amtship,
         qtyrcvd, weightrcvd, cubercvd, amtrcvd,
         lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
        values
        (l_loadno, l_stopno, l_shipno, sysdate,
         0, 0, 0, 0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         in_userid, sysdate, 0, 0);
    exception when dup_val_on_index then
      null;
    end;
    
    update orderhdr
       set wave = l_wave,
           shiptype = 'L',
           carrier = shp.carrier
     where rowid = oh.rowid;
       
    zld.assign_outbound_order_to_load(oh.orderid,oh.shipid,shp.carrier,null,
            null,null,null,null,in_fromfacility,zbbb.AUTHOR,
            l_loadno,l_stopno,l_shipno,l_msg);
    
    if substr(l_msg,1,4) <> 'OKAY' then
      out_errorno := -4;
      out_msg := 'Unable to assign order ' || oh.orderid || '-' || oh.shipid ||
          ' to load ' || l_loadno || '. ' || chr(13) || l_msg;
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

    update bbb_routing_shipment_tmp
       set routing_status = 'ROUTED'
     where rowid = shp.rowid;
     
  end loop;

  update waves
     set consolidated = l_wave_consolidated
   where wave = l_wave;
   
<< continue_shipment_loop >>
  null;
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_fromfacility,
    in_custid   => in_custid,
    in_msgtext  => out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end assign_pool_ltl_shipments;

PROCEDURE assign_small_package_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_bbb_routing_yn varchar2 -- 'P' standard Program, 'V'endor Program
,in_generate_p_and_c_waves_by varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_msg varchar2(255);
l_wave waves.wave%type;
l_bbb_small_package_carrier customer_aux.bbb_small_package_carrier%type;
l_wave_descr waves.descr%type;
TYPE cur_type is REF CURSOR;
OHC cur_type;
OH orderdtl%rowtype;
l_cmd varchar2(255);
l_rowid rowid;

begin

out_errorno := 0;
out_msg := 'OKAY';

l_bbb_small_package_carrier := null;
l_wave := 0;

begin
  select bbb_small_package_carrier
    into l_bbb_small_package_carrier
    from customer_aux
   where custid = in_custid;
exception when others then
  l_bbb_small_package_carrier := zbbb.routing_request_carrier(in_custid);
end;

if l_bbb_small_package_carrier is null then
  l_bbb_small_package_carrier := zbbb.routing_request_carrier(in_custid);
end if;

for shp in (select *
              from bbb_routing_shipment_tmp
             where routing_status = 'SMALLPKG'
               and direct_to_store_yn = 'Y')
loop

  if l_wave != 0 then
    if (in_bbb_routing_yn = 'P') and
       (in_generate_p_and_c_waves_by = 'S') then
      l_wave := 0;
    end if;
  end if;
  
  if l_wave = 0 then
  
    zwv.get_next_wave(l_wave, l_msg);
    
    if substr(l_msg, 1, 4) = 'OKAY' then
       l_wave_descr := rtrim(in_control_value) || ' Small Package Shipment to ' ||
                       nvl(shp.order_shipto_master,shp.bbb_shipto_master);
       insert into waves
          (wave, descr, wavestatus, schedrelease, actualrelease,
           facility, lastuser, lastupdate, stageloc, picktype,
           taskpriority, sortloc, job, childwave, batchcartontype,
           fromlot, tolot, orderlimit, openfacility, cntorder,
           qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
           cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
           consolidated, shiptype, carrier, servicelevel, shipcost,
           weight, tms_status, tms_status_update, mass_manifest,
           pick_by_zone, master_wave,
           bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
       select l_wave, l_wave_descr, '2', null, null,
           in_fromfacility, in_userid, sysdate, null, 'ORDR',
           W.taskpriority, null, null, null, W.batchcartontype,
           W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
           null, null, null, null, null,
           null, null, null, null, null,
           'N', W.shiptype, W.carrier, W.servicelevel, W.shipcost,
           null, W.tms_status, W.tms_status_update, W.mass_manifest,
           W.pick_by_zone, in_wave,
           bbb_custid_template, 'N', nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
         from waves W
        where W.wave = in_wave;
    else
      out_errorno := -1;
      out_msg := 'Unable to assign small package wave number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;
  end if;
  
  l_cmd := 'select rowid from orderhdr where wave = ' || in_wave ||
           ' and nvl(shiptocountrycode,''USA'') = ''' || shp.shiptocountrycode || ''''  ||
           ' and shipto_master is null ' ||
           ' and shipto = ''' || nvl(shp.order_shipto_master,shp.bbb_shipto_master) || '''';

  open OHC for l_cmd;
  loop

    fetch OHC into l_rowid;
    exit when OHC%notfound;

    update orderhdr
       set wave = l_wave,
           shiptype = 'S',
           carrier = l_bbb_small_package_carrier
     where rowid = l_rowid;
    
  end loop;

  if OHC%isopen then
    close OHC;
  end if;
  
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_fromfacility,
    in_custid   => in_custid,
    in_msgtext  => out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
  if OHC%isopen then
    close OHC;
  end if;
end assign_small_package_shipments;

PROCEDURE split_consolidated_to_stores
(in_wave number
,in_shipment_rowid rowid
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

cursor curShipment is
  select *
    from bbb_routing_shipment_tmp
   where rowid = in_shipment_rowid;
shp curShipment%rowtype;

l_bbb_carton_uom customer_aux.bbb_carton_uom%type := null;
l_carton_count pls_integer;
l_msg varchar2(255);

begin

shp := null;
open curShipment;
fetch curShipment into shp;
close curShipment;
if shp.bbb_shipto_master is null then
  out_errorno := -1;
  out_msg := 'Shipment row not found for Wave '  || in_wave;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => wv.facility,
    in_custid   => wv.bbb_custid_template,
    in_msgtext  => out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
  return;
end if;

update bbb_routing_shipment_tmp
   set routing_status = 'SPLIT'
 where rowid = in_shipment_rowid;

debug_msg('Shipment ' || shp.bbb_shipto_master || ' split to ship direct to stores ',
          wv.bbb_custid_template, wv.facility, in_userid);
 
for oh in (select orderid,shipid,custid,fromfacility,
                  shipto, weightorder,cubeorder,rowid,
                  shipto_master
             from orderhdr
            where wave = in_wave
              and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
              and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master))
loop

  debug_msg('Direct to store ' || oh.orderid || '-' || oh.shipid ||
            shp.bbb_shipto_master || ' ' || oh.shipto,
            wv.bbb_custid_template, wv.facility, in_userid);
            
  zbbb.compute_carton_count(oh.orderid,oh.shipid,null,in_userid,
                            l_bbb_carton_uom,l_carton_count);
                            
  begin
    insert into bbb_routing_shipment_tmp
     (shiptocountrycode,bbb_shipto_master,order_shipto_master,
      direct_to_store_yn,weight,cube,carton_count,routing_status)
     values
     (shp.shiptocountrycode,oh.shipto,null,
      'Y',oh.weightorder,oh.cubeorder,l_carton_count,'NOTROUTED'
     );
  exception when dup_val_on_index then
    update bbb_routing_shipment_tmp
       set weight = weight + oh.weightorder,
           cube = cube + oh.cubeorder,
           carton_count = carton_count + l_carton_count
     where shiptocountrycode = shp.shiptocountrycode
       and bbb_shipto_master = oh.shipto
       and order_shipto_master is null;
  end;

  update orderhdr
     set shipto_master = null
   where rowid = oh.rowid;
   
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => wv.facility,
    in_custid   => wv.bbb_custid_template,
    in_msgtext  => 'split_con ' || out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end split_consolidated_to_stores;

PROCEDURE route_wave
(in_func varchar2 /* 'CHECK'--check for shortages only; 'ROUTE'--route the wave */
,in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is
   
l_cancel_qty orderdtl.qtyorder%type;
l_count pls_integer;
l_carton_count pls_integer;
l_loop_cnt pls_integer;
l_truckload_cnt pls_integer;
l_bbb_carton_uom customer_aux.bbb_carton_uom%type := null;
l_oversize_carton_type varchar2(3);
l_oversize_os3_cnt pls_integer;
l_carton_count_min bbb_routing_parms.carton_count_min%type;
l_weight_min bbb_routing_parms.weight_min%type;
l_errorno pls_integer;
l_msg varchar2(255);
l_prm bbb_routing_today_view%rowtype;
l_control_value orderhdr.hdrpassthruchar01%type := null;
l_carrier carrier.carrier%type;
l_mileage consignee_mileage.mileage%type;
l_bbb_routing_yn customer_aux.bbb_routing_yn%type;
l_customer_bbb_routing_yn customer_aux.bbb_routing_yn%type;
l_prev_custid customer.custid%type := null;
l_bbb_pooler_shipto customer_aux.bbb_pooler_shipto%type;
l_bbb_shipto_master bbb_routing_shipment_tmp.bbb_shipto_master%type;
l_order_shipto_master bbb_routing_shipment_tmp.order_shipto_master%type;
l_direct_to_store_yn bbb_routing_shipment_tmp.direct_to_store_yn%type;
l_cnt pls_integer;
l_tot_order_count pls_integer := 0;
l_tot_qtyorder orderhdr.qtyorder%type := 0;
l_tot_cubeorder orderhdr.cubeorder%type := 0;
l_tot_weightorder orderhdr.weightorder%type := 0;
l_short_order_found boolean := false;
l_short_count pls_integer;
l_tot_msg varchar2(255);
l_p_and_c_pass_number pls_integer; -- pass one use shipto_master from order to build truckloads
                                   -- pass two use bbb_pooler_and_consolidator to build ltl loads to pooler
l_generate_p_and_c_waves_by customer_aux.bbb_generate_p_and_c_waves_by%type; -- 'L'oad; 'S'hip-to

begin

out_errorno := 0;
out_msg := 'OKAY';

wv := null;
open curWaves(in_wave);
fetch curWaves into wv;
close curWaves;
if wv.wave is null then
  out_errorno := -111;
  out_msg := 'Wave not found: ' || in_wave;
  return;
end if;

if trim(wv.bbb_custid_template) is null then
  out_errorno := -112;
  out_msg := 'Wave ' || in_wave || ' requires a ''BBB Routing Parameter Customer ID''';
  return;
end if;

begin
  select bbb_routing_yn, bbb_pooler_shipto, bbb_generate_p_and_c_waves_by
    into l_bbb_routing_yn, l_bbb_pooler_shipto, l_generate_p_and_c_waves_by
    from customer_aux
   where custid = wv.bbb_custid_template;
exception when others then
  out_errorno := -113;
  out_msg := 'Wave ' || in_wave || ': Invalid BBB Routing Parameter Customer ID ' || wv.bbb_custid_template;
  return;
end;

if nvl(l_bbb_routing_yn,'N') = 'N' then
  out_errorno := -114;
  out_msg := 'Wave ' || in_wave || ': BBB Routing Parameter Customer ID ' ||
              wv.bbb_custid_template || ' is not specified as ''P and C'' or ''VDP'' type';
  return;
end if;

for oh in (select custid,orderid,shipid,qtyorder,cubeorder,weightorder
             from orderhdr oh
            where wave = in_wave)
loop

  l_tot_order_count := l_tot_order_count + 1;
  l_tot_qtyorder := l_tot_qtyorder + oh.qtyorder;
  l_tot_cubeorder := l_tot_cubeorder + oh.cubeorder;
  l_tot_weightorder := l_tot_weightorder + oh.weightorder;

  if zbbb.is_a_bbb_order(oh.custid,oh.orderid,oh.shipid) != 'Y' then
    out_errorno := -187;
    out_msg := 'Order ' || oh.orderid || '-' || oh.shipid || ' is not a BBB order';
    return;
  end if;

  if nvl(l_prev_custid,'x') != oh.custid then
    begin
      select bbb_routing_yn
        into l_customer_bbb_routing_yn
        from customer_aux
       where custid = oh.custid;
    exception when others then
      out_errorno := -119;
      out_msg := 'Order ' || oh.orderid || '-' || oh.shipid || ' has Invalid Customer ID: ' || oh.custid;
      return;
    end;
    l_prev_custid := oh.custid;
    if nvl(l_customer_bbb_routing_yn,'x') != l_bbb_routing_yn then
      out_errorno := -119;
      out_msg := 'Order ' || oh.orderid || '-' || oh.shipid || ' BBB Routing Type mismatch for customer: ' || oh.custid;
      return;
    end if;
  end if;
  
  if l_short_order_found = false then
    select count(1)
      into l_short_count
      from orderdtl
     where orderid = oh.orderid
       and shipid = oh.shipid
       and nvl(qtyorder,0) > nvl(qtycommit,0)
       and linestatus != 'X';
    if l_short_count != 0 then
      l_short_order_found := true;
    end if;
  end if;
  
end loop;

l_tot_msg := chr(13) || 'Orders: ' || to_char(l_tot_order_count,'FM999,999') ||
             chr(13) || 'Quantity: ' || to_char(l_tot_qtyorder,'FM999,999,999') ||
             chr(13) || 'Cube: ' || to_char(l_tot_cubeorder,'FM999,999,999.99') ||
             chr(13) || 'Weight: ' || to_char(l_tot_weightorder,'FM999,999,999.99');
             
if l_short_order_found = true then
  out_errorno := -1;
  out_msg := 'There are short orders on this wave.' || l_tot_msg;
  return;
end if;

if nvl(in_func,'x') != 'ROUTE' then
  out_msg := l_tot_msg;
  return;
end if;

zms.log_autonomous_msg(	
  in_author   => zbbb.AUTHOR,
  in_facility => wv.facility,
  in_custid   => wv.bbb_custid_template,
  in_msgtext  => 'Beginning wave routing... (Wave ' || in_wave || ')' || l_tot_msg,
  in_msgtype  => 'I',
  in_userid   => in_userid,
  out_msg		=> l_msg);

ptls.delete;

l_p_and_c_pass_number := 1;

<< reroute_shipments >>

l_loop_cnt := 0;

for oh in (select orderid,shipid,custid,fromfacility,
                  nvl(shiptocountrycode,'USA') as shiptocountrycode,
                  shipto_master,shipto,
                  weightorder,cubeorder
             from orderhdr
            where wave = in_wave)
loop

  l_loop_cnt := l_loop_cnt + 1;
  if (l_loop_cnt = 1) then
    debug_msg('Begin Re-route ',wv.bbb_custid_template,wv.facility,'debug');
    delete from bbb_routing_shipment_tmp;
    delete from bbb_oversize_packages_tmp;
  end if;

  l_control_value := zbbb.routing_control_value(oh.custid,oh.orderid,oh.shipid);

  debug_msg('accum order ' ||
            oh.custid || ' ' ||  
            oh.orderid || '-' ||
            oh.shipid || ' ' ||
            oh.shiptocountrycode || ' ' ||
            oh.shipto || ' ' ||
            nvl(oh.shipto_master,'(mast)') || ' ' ||
            oh.weightorder || ' ' ||
            oh.cubeorder || ' ' ||
            l_control_value,
            oh.custid,oh.fromfacility,'debug');
            
  zbbb.compute_carton_count(oh.orderid,oh.shipid,null,in_userid,
                            l_bbb_carton_uom,l_carton_count);

  l_direct_to_store_yn := 'N';

  if oh.shipto_master is null then
    l_bbb_shipto_master := oh.shipto;
    l_direct_to_store_yn := 'Y';
  else
    l_bbb_shipto_master := oh.shipto_master;
  end if;
  
  if (l_bbb_routing_yn = 'P') then
    if (l_p_and_c_pass_number = 2) and  
       (l_direct_to_store_yn = 'N') then
      l_bbb_shipto_master := l_bbb_pooler_shipto;
    end if;
    l_order_shipto_master := nvl(oh.shipto_master,oh.shipto);
  else
    l_order_shipto_master := null;
  end if;
  
  begin
    insert into bbb_routing_shipment_tmp
     (shiptocountrycode,bbb_shipto_master,order_shipto_master,
      direct_to_store_yn,weight,cube,carton_count,
      routing_status
      )
     values
     (oh.shiptocountrycode,l_bbb_shipto_master,l_order_shipto_master,
      l_direct_to_store_yn,oh.weightorder,oh.cubeorder,l_carton_count,
      'NOTROUTED'
      );
      debug_msg('insertshp ' || 
              oh.orderid || '-' ||
              oh.shipid || ' ' ||
              wv.bbb_custid_template || ' ' ||
              wv.facility || ' ' ||
              oh.shiptocountrycode || ' ' ||
              oh.shipto || ' ' ||
              nvl(oh.shipto_master,'(mast)') || ' ' ||
              l_bbb_shipto_master || ' ' ||
              l_order_shipto_master || ' ' ||
              oh.weightorder || ' ' ||
              oh.cubeorder || ' ' ||
              l_direct_to_store_yn || ' ' ||
              l_carton_count,
              oh.custid,oh.fromfacility,'debug');
  exception when dup_val_on_index then
    update bbb_routing_shipment_tmp
       set weight = weight + oh.weightorder,
           cube = cube + oh.cubeorder,
           carton_count = carton_count + l_carton_count
     where shiptocountrycode = oh.shiptocountrycode
       and bbb_shipto_master = l_bbb_shipto_master
       and nvl(order_shipto_master,'x') = nvl(l_order_shipto_master,'x');
    debug_msg('updateshp ' || 
              oh.orderid || '-' ||
              oh.shipid || ' ' ||
              wv.bbb_custid_template || ' ' ||
              wv.facility || ' ' ||
              oh.shiptocountrycode || ' ' ||
              oh.shipto || ' ' ||
              nvl(oh.shipto_master,'(mast)') || ' ' ||
              l_bbb_shipto_master || ' ' ||
              l_order_shipto_master || ' ' ||
              oh.weightorder || ' ' ||
              oh.cubeorder || ' ' ||
              l_direct_to_store_yn || ' ' ||
              l_carton_count,
              oh.custid,oh.fromfacility,'debug');
  end;

  for od in (select distinct item, uom
               from orderdtl
              where orderid = oh.orderid
                and shipid = oh.shipid
                and linestatus != 'X')
  loop
  
    zbbb.compute_carton_count(oh.orderid,oh.shipid,od.item,in_userid,
                              l_bbb_carton_uom,l_carton_count);
    
    if l_carton_count != 0 then
      l_oversize_carton_type
        := zbbb.oversize_carton_type(oh.custid,wv.bbb_custid_template,od.item,l_bbb_carton_uom);
      if l_oversize_carton_type != 'NOT' then
        begin
          insert into bbb_oversize_packages_tmp
            (shiptocountrycode,bbb_shipto_master,order_shipto_master,
             oversize_carton_type,oversize_carton_count)
          values
            (oh.shiptocountrycode,l_bbb_shipto_master,nvl(oh.shipto_master,oh.shipto),
             l_oversize_carton_type,l_carton_count);
        exception when dup_val_on_index then
          update bbb_oversize_packages_tmp
             set oversize_carton_count = oversize_carton_count + l_carton_count
           where shiptocountrycode = oh.shiptocountrycode
             and bbb_shipto_master = l_bbb_shipto_master
             and order_shipto_master = nvl(oh.shipto_master,oh.shipto)
             and oversize_carton_type = l_oversize_carton_type;
        end;
      end if;
    end if;
  
  end loop;
  
end loop;

-- for Vendor Program, split the consolidated shipment to individual store orders
-- if minimum carton count and weight are not met for an LTL shipment
if (l_bbb_routing_yn = 'V') then
  for shp in (select rowid,bbb_routing_shipment_tmp.*
                from bbb_routing_shipment_tmp
               where routing_status = 'NOTROUTED'
                 and direct_to_store_yn = 'N')
  loop

    l_prm := null;
    for prm in (select *
                  from bbb_routing_today_view
                 where custid = wv.bbb_custid_template
                   and fromfacility = wv.facility
                   and shiptocountrycode = shp.shiptocountrycode
                   and shipto = shp.bbb_shipto_master
                   and shiptype = 'L')
    loop
      l_prm := prm;
      goto check_mins;
    end loop;
    
    for prm in (select *
                  from bbb_routing_today_view
                 where custid = wv.bbb_custid_template
                   and fromfacility = wv.facility
                   and shiptocountrycode = shp.shiptocountrycode
                   and shipto = '(DEFAULT)'
                   and shiptype = 'L')
    loop
      l_prm := prm;
      goto check_mins;
    end loop;
    
    for prm in (select *
                  from bbb_routing_today_view
                 where custid = wv.bbb_custid_template
                   and fromfacility = wv.facility
                   and shiptocountrycode = '(DEFAULT)'
                   and shipto = '(DEFAULT)'
                   and shiptype = 'L')
    loop
      l_prm := prm;
      goto check_mins;
    end loop;

  << check_mins >>

    if l_prm.custid is null then
      l_prm.carton_count_min := 16;
      l_prm.weight_min := 151;
    end if;
    
    if (shp.carton_count < l_prm.carton_count_min) and
       (shp.weight < l_prm.weight_min) and
       (shp.cube < l_prm.cube_min) then
      zbbb.split_consolidated_to_stores(in_wave,shp.rowid,in_userid,l_errorno, l_msg);
    end if;

  << skip_min_ltl_check >>
    null;
    
  end loop;
end if;

l_truckload_cnt := 0;
-- find eligible truckload shipments
for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where routing_status = 'NOTROUTED')
loop

  l_prm := null;
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = shp.bbb_shipto_master
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto check_truckload_threshold;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = '(DEFAULT)'
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto check_truckload_threshold;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = '(DEFAULT)'
                 and shipto = '(DEFAULT)'
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto check_truckload_threshold;
  end loop;

<< check_truckload_threshold >>

  if l_prm.weight_max is null then
    l_prm.weight_max := 40000;
    l_prm.cube_max := 3816;
    l_prm.carton_count_min := 16;
  end if;

  l_mileage := zbbb.distance_to_consignee(shp.bbb_shipto_master,wv.facility);
  
  debug_msg('truckcheck ' || 
            shp.bbb_shipto_master || ' ' ||
            shp.order_shipto_master || ' ' ||
            shp.weight || ' ' ||
            l_prm.weight_min || ' ' ||
            shp.cube || ' ' ||
            l_prm.cube_min || ' ' ||
            shp.carton_count || ' ' ||
            l_prm.carton_count_min,
            wv.bbb_custid_template,wv.facility,'debug');
            
  if (trunc(shp.weight) >= l_prm.weight_min) and
     (trunc(shp.cube) >= l_prm.cube_min) and
     (shp.carton_count >= l_prm.carton_count_min) then
    update bbb_routing_shipment_tmp
       set routing_status = 'TRUCK',
           weight_max = l_prm.weight_max,
           cube_max = l_prm.cube_max,
           mileage = l_mileage
     where rowid = shp.rowid;
    l_truckload_cnt := l_truckload_cnt + 1;
  end if;
  
end loop;

l_cnt := 0;
for shp in (select *
              from bbb_routing_shipment_tmp
             where routing_status = 'TRUCK'
             order by bbb_shipto_master,order_shipto_master)
loop
    l_cnt := l_cnt + 1;
    debug_msg('truckloads ' || l_cnt || ' ' ||
              shp.shiptocountrycode || ' ' ||
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.cube || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count,
              wv.bbb_custid_template,wv.facility,'debug');
end loop;

if l_truckload_cnt <> 0 then

  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => wv.facility,
    in_custid   => wv.bbb_custid_template,
    in_msgtext  => 'Assigning Truckload Shipments... (Wave ' || in_wave || ' BBB Type: ' || l_bbb_routing_yn || ')',
    in_msgtype  => 'I',
    in_userid   => in_userid,
    out_msg		=> l_msg);

  if l_bbb_routing_yn = 'P' then
    zbbb.assign_pool_tl_shipments(in_wave,wv.bbb_custid_template,wv.facility,l_control_value,
                                  l_bbb_pooler_shipto, l_generate_p_and_c_waves_by, in_userid, l_errorno, l_msg);
  else
    zbbb.assign_vendor_tl_shipments(in_wave,wv.bbb_custid_template,wv.facility,l_control_value,
                                    in_userid, l_errorno, l_msg);
  end if;
   
  if l_errorno != 0 then
    out_msg := 'Unable to assign truckload shipments ' || l_errorno;
    out_errorno := -4;
    return;
  end if;
  
  goto reroute_shipments;  -- loop back and see if any truckloads remain
  
end if;

if (l_bbb_routing_yn = 'P') and
   (l_p_and_c_pass_number = 1) then
  l_p_and_c_pass_number := 2;
  debug_msg('re-route pooler and consolidator pass number 2 ',
          wv.bbb_custid_template,wv.facility,'debug');
  goto reroute_shipments;
end if;

--
-- Check for small package eligibility (cannot have more than 
--   one oversize carton)
-- 
for shp in (select rowid, shiptocountrycode, bbb_shipto_master, order_shipto_master
              from bbb_routing_shipment_tmp
             where routing_status = 'NOTROUTED')
loop

  l_oversize_os3_cnt := 0;
  select count(1)
    into l_oversize_os3_cnt
    from bbb_oversize_packages_tmp
   where bbb_shipto_master = shp.bbb_shipto_master
     and nvl(order_shipto_master,'x') = nvl(shp.order_shipto_master,'x')
     and oversize_carton_type = 'OS3';
     
  if (l_oversize_os3_cnt > 1) then
    update bbb_routing_shipment_tmp
       set routing_status = 'NOSMALLPKG'
     where rowid = shp.rowid;
  end if;
  
  if (l_oversize_os3_cnt > 1) then
    zms.log_autonomous_msg(	
      in_author   => zbbb.AUTHOR,
      in_facility => wv.facility,
      in_custid   => wv.bbb_custid_template,
      in_msgtext  => 'Shipment to ' || shp.bbb_shipto_master || 
                     ' cannot be sent small package because it contains ' ||
                     l_oversize_os3_cnt || ' oversize cartons',
      in_msgtype  => 'I',
      in_userid   => in_userid,
      out_msg		=> l_msg);
  end if;
      
end loop;

-- route eligible small package shipments
for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where direct_to_store_yn = 'Y')
loop

  l_prm := null;
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = shp.bbb_shipto_master
                 and shiptype = 'S')
  loop
    l_prm := prm;
    goto check_small_package_threshold;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = '(DEFAULT)'
                 and shiptype = 'S')
  loop
    l_prm := prm;
    goto check_small_package_threshold;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = '(DEFAULT)'
                 and shipto = '(DEFAULT)'
                 and shiptype = 'S')
  loop
    l_prm := prm;
    goto check_small_package_threshold;
  end loop;

<< check_small_package_threshold >>

  if l_prm.carton_count_max is null then
    l_prm.carton_count_max := 30;
  end if;

  debug_msg('smallpkgcheck ' || 
            shp.bbb_shipto_master || ' ' ||
            shp.order_shipto_master || ' ' ||
            shp.weight || ' ' ||
            shp.weight_max || ' ' ||
            shp.cube || ' ' ||
            shp.cube_max || ' ' ||
            shp.carton_count || ' ' ||
            l_prm.carton_count_max || ' ' ||
            shp.direct_to_store_yn,
            wv.bbb_custid_template,wv.facility,'debug');
  
  if shp.carton_count <= l_prm.carton_count_max then
    update bbb_routing_shipment_tmp
       set routing_status = 'SMALLPKG'
     where rowid = shp.rowid;
  end if;
  
end loop;
 
update bbb_routing_shipment_tmp
   set routing_status = 'NOTROUTED'
 where routing_status = 'NOSMALLPKG';

-- route the remaining shipments ltl 
-- and set the max weight/cube based on configured truckload parms
for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where routing_status = 'NOTROUTED')
loop

  l_prm := null;
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = shp.bbb_shipto_master
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto set_truckload_maximums;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = shp.shiptocountrycode
                 and shipto = '(DEFAULT)'
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto set_truckload_maximums;
  end loop;
  
  for prm in (select *
                from bbb_routing_today_view
               where custid = wv.bbb_custid_template
                 and fromfacility = wv.facility
                 and shiptocountrycode = '(DEFAULT)'
                 and shipto = '(DEFAULT)'
                 and shiptype = 'T')
  loop
    l_prm := prm;
    goto set_truckload_maximums;
  end loop;

<< set_truckload_maximums >>

  if l_prm.weight_max is null then
    l_prm.weight_max := 40000;
    l_prm.cube_max := 3816;
  end if;
  
  if l_bbb_routing_yn = 'V' then
    l_carrier := zbbb.routing_request_carrier(wv.bbb_custid_template);
  elsif (l_bbb_routing_yn = 'P') and
        (shp.direct_to_store_yn = 'N') and
        (shp.bbb_shipto_master = l_bbb_pooler_shipto) then
    l_carrier := l_bbb_pooler_shipto;
    debug_msg('ltl carrier pn ' || wv.bbb_custid_template || ' ' ||
              wv.facility || ' ' || nvl(shp.order_shipto_master,'(ostm)') || ' ' ||
              l_carrier, wv.bbb_custid_template, wv.facility, 'carrier');
  else
    l_carrier := zbbb.assigned_ltl_carrier(wv.bbb_custid_template,wv.facility,
                                           shp.order_shipto_master,sysdate);
    debug_msg('ltl carrier py ' || wv.bbb_custid_template || ' ' ||
              wv.facility || ' ' || nvl(shp.order_shipto_master,'(ostm)') || ' ' ||
              l_carrier, wv.bbb_custid_template, wv.facility, 'carrier');
  end if;
                                        
  l_mileage := zbbb.distance_to_consignee(shp.bbb_shipto_master,wv.facility);
  
  update bbb_routing_shipment_tmp
     set routing_status = 'LTL',
         weight_max = l_prm.weight_max,
         cube_max = l_prm.cube_max,
         carrier = l_carrier,
         mileage = l_mileage
   where rowid = shp.rowid;
  
end loop;

l_count := 0;

for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where routing_status = 'NOTROUTED')
loop

  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => wv.facility,
    in_custid   => wv.bbb_custid_template,
    in_msgtext  => 'Not Routed: ' || shp.shiptocountrycode || '/' || shp.bbb_shipto_master || ' '
      || shp.direct_to_store_yn || ' Weight: ' || shp.weight || ' Cube: ' || shp.cube ||
      ' Cartons ' || shp.carton_count || ' MaxWeight: ' || shp.weight_max ||
      ' MaxCube: ' || shp.cube_max,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);

  l_count := l_count + 1;
  
end loop;

if (l_count != 0) then
  out_errorno := -2;
  out_msg := 'There are unrouted shipments for this wave';
  return;
end if;

zms.log_autonomous_msg(	
  in_author   => zbbb.AUTHOR,
  in_facility => wv.facility,
  in_custid   => wv.bbb_custid_template,
  in_msgtext  => 'Assigning Small Package shipments... (Wave ' || in_wave || ')',
  in_msgtype  => 'I',
  in_userid   => in_userid,
  out_msg		=> l_msg);

zbbb.assign_small_package_shipments(in_wave,wv.bbb_custid_template,wv.facility,
   l_control_value,l_bbb_routing_yn,l_generate_p_and_c_waves_by,in_userid,l_errorno,l_msg);
if l_errorno != 0 then
  out_errorno := -3;
  out_msg := 'Unable to assign small package shipments';
  return;
end if;

zms.log_autonomous_msg(	
  in_author   => zbbb.AUTHOR,
  in_facility => wv.facility,
  in_custid   => wv.bbb_custid_template,
  in_msgtext  => 'Assigning LTL shipments... (Wave ' || in_wave || ')',
  in_msgtype  => 'I',
  in_userid   => in_userid,
  out_msg		=> l_msg);

while (1=1)
loop

  if l_bbb_routing_yn = 'P' then
    zbbb.assign_pool_ltl_shipments(in_wave,wv.bbb_custid_template,wv.facility,l_control_value,
                              l_generate_p_and_c_waves_by, in_userid, l_errorno, l_msg);
  else
    zbbb.assign_vendor_ltl_shipments(in_wave,wv.bbb_custid_template,wv.facility,l_control_value,
                              in_userid, l_errorno, l_msg);
  end if;

  if l_errorno != 0 then
    out_errorno := -4;
    out_msg := 'Unable to assign ltl shipments';
    return;
  end if;

  select count(1)
    into l_count
    from bbb_excluded_shipments_tmp;
  if l_count = 0 then
    exit;
  end if;
  
end loop;

select count(1)
  into l_count
  from orderhdr
 where wave = in_wave;
 
if l_count = 0 then
  update waves
     set wavestatus = '4',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = in_wave;
end if;

zms.log_autonomous_msg(	
  in_author   => zbbb.AUTHOR,
  in_facility => wv.facility,
  in_custid   => wv.bbb_custid_template,
  in_msgtext  => 'Wave routing complete. (Wave ' || in_wave || ')',
  in_msgtype  => 'I',
  in_userid   => in_userid,
  out_msg		=> l_msg);

exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end route_wave;

function is_consolidator
(in_shipto varchar2
) return char

is

l_consolidator_yn consignee.consolidator_yn%type;

begin

l_consolidator_yn := 'N';

select nvl(consolidator_yn,'N')
  into l_consolidator_yn
  from consignee
 where consignee = in_shipto;

return l_consolidator_yn;
 
exception when others then
  return 'N';
end is_consolidator;

PROCEDURE unroute_master_wave
(in_master_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_wave_count pls_integer := 0;
l_out_errorno number;
l_out_msg varchar2(255);
l_out_msg2 varchar2(255);

begin

out_errorno := 0;
out_msg := 'OKAY';

for wv in (select wave, wavestatus
             from waves
            where master_wave = in_master_wave)
loop

  if (wv.wavestatus  > '2') then
    goto continue_unroute_loop;
  end if;

  l_wave_count := l_wave_count + 1;

  for oh in (select orderid,shipid,custid,fromfacility,
                    nvl(loadno,0) as loadno
               from orderhdr
              where wave = wv.wave)
  loop

    if oh.loadno != 0 then  
      zld.deassign_order_from_load(oh.orderid,oh.shipid,oh.fromfacility,
        in_userid,'N',l_out_errorno,l_out_msg);
      if (substr(l_out_msg,1,4) != 'OKAY') and
         (instr(l_out_msg, 'Order not assigned to load:') = 0) then -- ignore this message because of consolidated-order waves
                                                                    -- (all orders are de-assigned upon the first call)
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => oh.fromfacility,
          in_custid   => oh.custid,
          in_msgtext  => oh.loadno || ' ' || l_out_msg,
          in_msgtype  => 'E',
          in_userid   => in_userid,
          out_msg		=> l_out_msg2);
      end if;
    end if;
    
    zcm.uncommit_order(oh.orderid,oh.shipid,oh.fromfacility,
      in_userid,'1',wv.wave,l_out_msg);
    if substr(l_out_msg,1,4) != 'OKAY' then
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => oh.fromfacility,
        in_custid   => oh.custid,
        in_msgtext  => 'zbbb.uw ' || l_out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_out_msg2);
    end if;

  end loop;
      
<< continue_unroute_loop >>
  null;
end loop;

out_msg := 'Undo routing wave count: ' || l_wave_count;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end unroute_master_wave;

function routing_request_carrier
(in_custid varchar2
) return varchar2

is

l_bbb_routing_request_carrier customer_aux.bbb_routing_request_carrier%type;

begin

begin
  select bbb_routing_request_carrier
    into l_bbb_routing_request_carrier
    from customer_aux
   where custid = in_custid;
exception when others then
  return 'ROUT';
end;

return l_bbb_routing_request_carrier;

exception when others then
  return 'ROUT';
end routing_request_carrier;

PROCEDURE assign_vendor_tl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_msg varchar2(255);
l_split_truck_msg varchar2(255);
l_wave waves.wave%type;
l_bbb_small_package_carrier customer_aux.bbb_small_package_carrier%type;
l_wave_descr waves.descr%type;
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_carrier carrier.carrier%type;
l_delpointtype loadstop.delpointtype%type;
l_weight_to_exclude orderhdr.weightorder%type;
l_cube_to_exclude orderhdr.cubeorder%type;
l_multi_truck_count pls_integer;
l_prev_custid customer.custid%type := null;

cursor curStoreOrderMultiTruck(in_shipto varchar2,
                               in_shiptocountrycode varchar2,
                               in_weight_max number,
                               in_cube_max number)
is                              
  select nvl(shipto_master,shipto) as shipto,
         sum(weightorder) as weight,
         sum(cubeorder) as cube
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
   group by nvl(shipto_master,shipto)
   having sum(weightorder) > in_weight_max or
          sum(cubeorder) > in_cube_max;
          
cursor curOrderToExcludeCubeDesc(in_shipto varchar2,
                                 in_shiptocountrycode varchar2,
                                 in_cube_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and cubeorder <= in_cube_to_exclude
   order by cubeorder desc;
exohc curOrderToExcludeCubeDesc%rowtype;
   
cursor curOrderToExcludeWeightDesc(in_shipto varchar2,
                                   in_shiptocountrycode varchar2,
                                   in_weight_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and weightorder <= in_weight_to_exclude
   order by weightorder desc;
exohw curOrderToExcludeWeightDesc%rowtype;
   
cursor curOrderToExcludeCubeAsc(in_shipto varchar2,
                                in_shiptocountrycode varchar2,
                                in_cube_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and cubeorder >= in_cube_to_exclude
   order by cubeorder;
   
cursor curOrderToExcludeWeightAsc(in_shipto varchar2,
                                  in_shiptocountrycode varchar2,
                                  in_weight_to_exclude number)
is
  select orderid,
         shipid,
         weightorder,
         cubeorder
    from orderhdr
   where wave = in_wave
     and nvl(shipto_master,shipto) = in_shipto
     and nvl(shiptocountrycode,'USA') = in_shiptocountrycode
     and (orderid,shipid) not in
           (select orderid,shipid
              from bbb_excluded_orders_tmp)
     and weightorder >= in_weight_to_exclude
   order by weightorder;
   
begin

out_errorno := 0;
out_msg := 'OKAY';

delete from bbb_excluded_orders_tmp;

l_multi_truck_count := 0;
   
for shp in (select *
              from bbb_routing_shipment_tmp
             where routing_status = 'TRUCK')
loop

  for mt in curStoreOrderMultiTruck(shp.bbb_shipto_master,shp.shiptocountrycode,
                                    shp.weight_max, shp.cube_max)
  loop
  
    debug_msg('MultiTruck Vendor Store Shipment for ' || mt.shipto ||
              ' ' || mt.weight || ' ' || mt.cube || ' ' || shp.weight_max ||
              ' ' || shp.cube_max,
              wv.bbb_custid_template,wv.facility,'debug');
      
    zld.get_next_loadno(l_loadno, l_msg);
    
    if l_msg != 'OKAY' then
      out_errorno := -2;
      out_msg := 'Unable to assign truckload load number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

    l_multi_truck_count := l_multi_truck_count + 1;
    
    while (mt.cube > shp.cube_max)
    loop
      l_cube_to_exclude := mt.cube - shp.cube_max;
      exohc := null;
      open curOrderToExcludeCubeDesc(mt.shipto,shp.shiptocountrycode,l_cube_to_exclude);
      fetch curOrderToExcludeCubeDesc into exohc; -- exclude largest order to get at/under max
      close curOrderToExcludeCubeDesc;
      if exohc.cubeorder is null then
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohc.orderid,exohc.shipid);
      l_cube_to_exclude := l_cube_to_exclude - exohc.cubeorder;
      mt.weight := mt.weight - exohc.weightorder;
      mt.cube := mt.cube - exohc.cubeorder;
      debug_msg('Excluded order cube ' || exohc.cubeorder || ' for ' ||
                shp.bbb_shipto_master || ' ' || mt.shipto || '-' || shp.shiptocountrycode || ' new cube ' ||
                mt.cube || ' max ' || shp.cube_max,
                wv.bbb_custid_template, wv.facility, in_userid);
    end loop;
    
    debug_msg('Weight Check 1 ' || mt.shipto ||
               ' ' || mt.weight || ' ' || mt.cube || ' ' || shp.weight_max ||
               ' ' || shp.cube_max,
              wv.bbb_custid_template,wv.facility,'debug');
      
    while (mt.weight > shp.weight_max)
    loop
      l_weight_to_exclude := mt.weight - shp.weight_max;
      exohw := null;
      debug_msg('Find Desc Excluded weight for ' ||
                shp.bbb_shipto_master || '/' || mt.shipto || ' ' || shp.shiptocountrycode ||
                ' weight to exclude ' || l_weight_to_exclude,
                wv.bbb_custid_template, wv.facility, in_userid);
      open curOrderToExcludeWeightDesc(mt.shipto,shp.shiptocountrycode,l_weight_to_exclude);
      fetch curOrderToExcludeWeightDesc into exohw; -- exclude largest order to get at/under max
      close curOrderToExcludeWeightDesc;
      if exohw.weightorder is null then
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohw.orderid,exohw.shipid);
      l_weight_to_exclude := l_weight_to_exclude - exohw.weightorder;
      mt.weight := mt.weight - exohw.weightorder;
      mt.cube := mt.cube - exohw.cubeorder;
      debug_msg('Excluded weight ' || exohw.weightorder || ' for ' ||
                shp.bbb_shipto_master || ' ' || mt.shipto || '-' || shp.shiptocountrycode || ' new weight ' ||
                mt.weight || ' max ' || shp.weight_max,
                wv.bbb_custid_template, wv.facility, in_userid);
    end loop;

    while (mt.cube > shp.cube_max)
    loop
      l_cube_to_exclude := mt.cube - shp.cube_max;
      exohc := null;
      open curOrderToExcludeCubeAsc(mt.shipto,shp.shiptocountrycode,l_cube_to_exclude);
      fetch curOrderToExcludeCubeAsc into exohc; -- exclude smallest order to get at/under max
      close curOrderToExcludeCubeAsc;
      if (exohc.cubeorder is null) or
         (exohc.cubeorder = mt.cube) then
        l_split_truck_msg := 'Unable to split off order for max cube ' || mt.shipto ||
          ' Cube: ' || mt.cube || ' Max Cube: ' || shp.cube_max || ' (' ||
          l_cube_to_exclude || ')';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => l_split_truck_msg,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohc.orderid,exohc.shipid);
      l_cube_to_exclude := l_cube_to_exclude - exohc.cubeorder;
      mt.weight := mt.weight - exohc.weightorder;
      mt.cube := mt.cube - exohc.cubeorder;
      debug_msg('Excluded order cube ' || exohc.cubeorder || ' for ' ||
                shp.bbb_shipto_master || ' ' || mt.shipto || '-' || shp.shiptocountrycode || ' new cube ' ||
                mt.cube || ' max ' || shp.cube_max,
                wv.bbb_custid_template, wv.facility, in_userid);
    end loop;

    debug_msg('Weight Check 2 ' || mt.shipto ||
              ' ' || mt.weight || ' ' || mt.cube || ' ' || shp.weight_max ||
              ' ' || shp.cube_max,
              wv.bbb_custid_template,wv.facility,'debug');
      
    while (mt.weight > shp.weight_max)
    loop
      l_weight_to_exclude := mt.weight - shp.weight_max;
      debug_msg('Find Asc Excluded weight for ' ||
                shp.bbb_shipto_master || '/' || mt.shipto || ' ' || shp.shiptocountrycode ||
                ' weight to exclude ' || l_weight_to_exclude,
                wv.bbb_custid_template, wv.facility, in_userid);
      exohw := null;
      open curOrderToExcludeWeightAsc(mt.shipto,shp.shiptocountrycode,l_weight_to_exclude);
      fetch curOrderToExcludeWeightAsc into exohw; -- exclude smallest order to get at/under max
      close curOrderToExcludeWeightAsc;
      if (exohw.weightorder is null) or
         (exohw.weightorder = mt.weight) then
        l_split_truck_msg := 'Unable to split off order for max weight ' || mt.shipto ||
          ' Weight: ' || mt.weight || ' Max Weight: ' || shp.weight_max || ' (' ||
          l_weight_to_exclude || ')';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => l_split_truck_msg,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        exit;
      end if;
      insert into bbb_excluded_orders_tmp
        (orderid,shipid)
        values
        (exohw.orderid,exohw.shipid);
      l_weight_to_exclude := l_weight_to_exclude - exohw.weightorder;
      mt.weight := mt.weight - exohw.weightorder;
      mt.cube := mt.cube - exohw.cubeorder;
      debug_msg('Excluded weight ' || exohw.weightorder || ' for ' ||
                shp.bbb_shipto_master || ' ' || mt.shipto || '-' || shp.shiptocountrycode || ' new weight ' ||
                mt.weight || ' max ' || shp.weight_max,
                wv.bbb_custid_template, wv.facility, in_userid);
    end loop;

    l_carrier := zbbb.routing_request_carrier(in_custid);
    debug_msg('avts carrier v ' || l_carrier, in_custid, in_fromfacility, 'carrier');
                                          
    insert into loads
      (loadno, entrydate, loadstatus, facility, carrier,
       statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
    values
        (l_loadno, sysdate, '2', in_fromfacility, l_carrier,
         in_userid, sysdate, in_userid, sysdate, 'OUTC', 'T');

    l_stopno := 1;
    if shp.direct_to_store_yn = 'Y' then
      l_delpointtype := 'C';
    else
      l_delpointtype := 'D';
    end if;

    l_prev_custid := 'x';
    l_shipno := 0;
    
    insert into loadstop
      (loadno, stopno, entrydate, loadstopstatus,
       statususer, statusupdate, lastuser, lastupdate, facility,
       delpointtype, shipto)
      values
      (l_loadno, l_stopno, sysdate, '2',
       in_userid, sysdate, in_userid, sysdate, in_fromfacility,
       l_delpointtype, shp.bbb_shipto_master);

    for oh in (select orderid,shipid,shipto,rowid,custid
                 from orderhdr
                where wave = in_wave
                  and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
                  and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master)
                  and (orderid,shipid) not in
                        (select orderid,shipid
                           from bbb_excluded_orders_tmp)
                order by custid)
    loop
      
      if l_prev_custid != oh.custid then
      
        zwv.get_next_wave(l_wave, l_msg);
        
        if substr(l_msg, 1, 4) = 'OKAY' then
           l_wave_descr := rtrim(in_control_value) || ' Vendor Truckload Shipment to ' ||
                           mt.shipto || ' (' || oh.custid || ')';
           insert into waves
              (wave, descr, wavestatus, schedrelease, actualrelease,
               facility, lastuser, lastupdate, stageloc, picktype,
               taskpriority, sortloc, job, childwave, batchcartontype,
               fromlot, tolot, orderlimit, openfacility, cntorder,
               qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
               cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
               consolidated, shiptype, carrier, servicelevel, shipcost,
               weight, tms_status, tms_status_update, mass_manifest,
               pick_by_zone, master_wave,
               bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
           select l_wave, l_wave_descr, '2', null, null,
               in_fromfacility, in_userid, sysdate, null, 'BAT', -- batch pick type
               W.taskpriority, null, null, null, W.batchcartontype,
               W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
               null, null, null, null, null,
               null, null, null, null, null,
               'Y', -- consolidated order pick
               W.shiptype, W.carrier, W.servicelevel, W.shipcost,
               null, W.tms_status, W.tms_status_update, W.mass_manifest,
               W.pick_by_zone, in_wave,
               bbb_custid_template, 'Y', nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
             from waves W
            where W.wave = in_wave;
        else
          out_errorno := -1;
          out_msg := 'Unable to assign truckload wave number';
          zms.log_autonomous_msg(	
            in_author   => zbbb.AUTHOR,
            in_facility => in_fromfacility,
            in_custid   => in_custid,
            in_msgtext  => out_msg,
            in_msgtype  => 'E',
            in_userid   => in_userid,
            out_msg		=> l_msg);
          return;
        end if;

        l_prev_custid := oh.custid;
        
        l_shipno := l_shipno + 1;
      
      end if;

      begin
        insert into loadstopship
          (loadno, stopno, shipno, entrydate,
           qtyorder, weightorder, cubeorder, amtorder,
           qtyship, weightship, cubeship, amtship,
           qtyrcvd, weightrcvd, cubercvd, amtrcvd,
           lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
          values
          (l_loadno, l_stopno, l_shipno, sysdate,
           0, 0, 0, 0,
           0, 0, 0, 0,
           0, 0, 0, 0,
           in_userid, sysdate, 0, 0);
      exception when dup_val_on_index then
        null;
      end;
      
      update orderhdr
         set wave = l_wave,
             shiptype = 'T',
             carrier = l_carrier
       where rowid = oh.rowid;
         
      zld.assign_outbound_order_to_load(oh.orderid,oh.shipid,l_carrier,null,
              null,null,null,null,in_fromfacility,zbbb.AUTHOR,
              l_loadno,l_stopno,l_shipno,l_msg);
      
      if substr(l_msg,1,4) <> 'OKAY' then
        out_errorno := -4;
        out_msg := 'Unable to assign order ' || oh.orderid || '-' || oh.shipid ||
            ' to load ' || l_loadno || '. ' || chr(13) || l_msg;
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => out_msg,
          in_msgtype  => 'E',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        return;
      end if;
      
    end loop;
    
  end loop;
  
end loop;

if l_multi_truck_count != 0 then
   debug_msg('Rerouting after vendor multitruck store shipment',
             wv.bbb_custid_template,wv.facility,'debug');
  return;
end if;

zms.log_autonomous_msg(	
  in_author   => zbbb.AUTHOR,
  in_facility => in_fromfacility,
  in_custid   => in_custid,
  in_msgtext  => 'Processing Single Truckload Vendor Shipments',
  in_msgtype  => 'I',
  in_userid   => in_userid,
  out_msg		=> l_msg);

for shp in (select *
              from bbb_routing_shipment_tmp
             where routing_status = 'TRUCK')
loop

	zld.get_next_loadno(l_loadno, l_msg);
	if l_msg != 'OKAY' then
    out_errorno := -2;
    out_msg := 'Unable to assign truckload load number';
    zms.log_autonomous_msg(	
      in_author   => zbbb.AUTHOR,
      in_facility => in_fromfacility,
      in_custid   => in_custid,
      in_msgtext  => out_msg,
      in_msgtype  => 'E',
      in_userid   => in_userid,
      out_msg		=> l_msg);
    return;
  end if;

  l_carrier := zbbb.routing_request_carrier(in_custid);
  debug_msg('avts2 carrier v ' || l_carrier, in_custid, in_fromfacility, 'carrier');
  
	insert into loads
		(loadno, entrydate, loadstatus, facility, carrier,
   	 statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
	values
     	(l_loadno, sysdate, '2', in_fromfacility, l_carrier,
       in_userid, sysdate, in_userid, sysdate, 'OUTC', 'T');

  l_stopno := 1;
  if shp.direct_to_store_yn = 'Y' then
    l_delpointtype := 'C';
  else
    l_delpointtype := 'D';
  end if;

  begin
    insert into loadstop
      (loadno, stopno, entrydate, loadstopstatus,
       statususer, statusupdate, lastuser, lastupdate, facility,
       delpointtype, shipto)
      values
      (l_loadno, l_stopno, sysdate, '2',
       in_userid, sysdate, in_userid, sysdate, in_fromfacility,
       l_delpointtype, shp.bbb_shipto_master);
  exception when dup_val_on_index then
    null;
  end;

  l_prev_custid := 'x';
  l_shipno := 0;
  
  for oh in (select orderid,shipid,shipto,rowid,custid
               from orderhdr
              where wave = in_wave
                and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
                and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master)
              order by custid)
  loop
    
    if l_prev_custid != oh.custid then
    
      zwv.get_next_wave(l_wave, l_msg);
      
      if substr(l_msg, 1, 4) = 'OKAY' then
         l_wave_descr := rtrim(in_control_value) || ' Truckload Shipment ' ||
                         'to ' || shp.bbb_shipto_master || ' (' || oh.custid || ')';
         insert into waves
            (wave, descr, wavestatus, schedrelease, actualrelease,
             facility, lastuser, lastupdate, stageloc, picktype,
             taskpriority, sortloc, job, childwave, batchcartontype,
             fromlot, tolot, orderlimit, openfacility, cntorder,
             qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
             cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
             consolidated, shiptype, carrier, servicelevel, shipcost,
             weight, tms_status, tms_status_update, mass_manifest,
             pick_by_zone, master_wave,
             bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
         select l_wave, l_wave_descr, '2', null, null,
             in_fromfacility, in_userid, sysdate, null, 'BAT', -- batch pick
             W.taskpriority, null, null, null, W.batchcartontype,
             W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
             null, null, null, null, null,
             null, null, null, null, null,
             'Y', -- consolidated order pick
             W.shiptype, W.carrier, W.servicelevel, W.shipcost,
             null, W.tms_status, W.tms_status_update, W.mass_manifest,
             W.pick_by_zone, in_wave,
             bbb_custid_template, 'Y', nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
           from waves W
          where W.wave = in_wave;
      else
        out_errorno := -1;
        out_msg := 'Unable to assign truckload wave number';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => out_msg,
          in_msgtype  => 'E',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        return;
      end if;

      l_prev_custid := oh.custid;
      
      l_shipno := l_shipno + 1;
      
    end if;
    
    begin
      insert into loadstopship
        (loadno, stopno, shipno, entrydate,
         qtyorder, weightorder, cubeorder, amtorder,
         qtyship, weightship, cubeship, amtship,
         qtyrcvd, weightrcvd, cubercvd, amtrcvd,
         lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
        values
        (l_loadno, l_stopno, l_shipno, sysdate,
         0, 0, 0, 0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         in_userid, sysdate, 0, 0);
    exception when dup_val_on_index then
      null;
    end;
    
    update orderhdr
       set wave = l_wave,
           shiptype = 'T',
           carrier = l_carrier
     where rowid = oh.rowid;
       
    zld.assign_outbound_order_to_load(oh.orderid,oh.shipid,l_carrier,null,
            null,null,null,null,in_fromfacility,zbbb.AUTHOR,
            l_loadno,l_stopno,l_shipno,l_msg);
    
    if substr(l_msg,1,4) <> 'OKAY' then
      out_errorno := -4;
      out_msg := 'Unable to assign order ' || oh.orderid || '-' || oh.shipid ||
          ' to load ' || l_loadno || '. ' || chr(13) || l_msg;
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;
    
  end loop;

end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_fromfacility,
    in_custid   => in_custid,
    in_msgtext  => 'avtse ' || out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end assign_vendor_tl_shipments;

PROCEDURE assign_vendor_ltl_shipments
(in_wave number
,in_custid varchar2
,in_fromfacility varchar2
,in_control_value varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

l_msg varchar2(255);
l_wave waves.wave%type;
l_count pls_integer;
l_bbb_small_package_carrier customer_aux.bbb_small_package_carrier%type;
l_wave_descr waves.descr%type;
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;
l_cube_max bbb_routing_shipment_tmp.cube_max%type;
l_weight_max bbb_routing_shipment_tmp.weight_max%type;
l_cube_accum loads.cubeorder%type;
l_weight_accum loads.weightorder%type;
l_delpointtype loadstop.delpointtype%type;
l_wave_consolidated waves.consolidated%type;
l_wave_picktype waves.picktype%type;
l_wave_batch_pick_by_item_yn waves.batch_pick_by_item_yn%type;
l_prev_custid orderhdr.shipto%type;
l_prev_bbb_shipto_master bbb_routing_shipment_tmp.bbb_shipto_master%type;

begin

out_errorno := 0;
out_msg := 'OKAY';

l_prev_bbb_shipto_master := 'x';
l_loadno := 0;

delete from bbb_excluded_shipments_tmp;
   
for shp in (select rowid,bbb_routing_shipment_tmp.*
              from bbb_routing_shipment_tmp
             where routing_status = 'LTL'
             order by bbb_shipto_master, mileage)
loop

  debug_msg('vendor ltl shipment ' || 
          shp.bbb_shipto_master || ' ' ||
          shp.order_shipto_master || ' ' ||
          shp.weight || ' ' ||
          shp.cube || ' ' ||
          shp.weight_max || ' ' ||
          shp.cube_max || ' ' ||
          shp.carton_count || ' ' ||
          shp.direct_to_store_yn || ' ' ||
          shp.carrier,
          wv.bbb_custid_template,wv.facility,'debug');
              
  if (l_loadno != 0) and
     (shp.bbb_shipto_master != l_prev_bbb_shipto_master) then
    insert into bbb_excluded_shipments_tmp
      (shiptocountrycode,bbb_shipto_master,order_shipto_master,
       weight,cube)
      values
      (shp.shiptocountrycode,shp.bbb_shipto_master,shp.order_shipto_master,
       shp.weight,shp.cube);
    return;
  end if;
  
  if (l_loadno = 0) then

    zld.get_next_loadno(l_loadno, l_msg);
    if l_msg != 'OKAY' then
      out_errorno := -2;
      out_msg := 'Unable to assign ltl load number';
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

    insert into loads
      (loadno, entrydate, loadstatus, facility, carrier,
       statususer, statusupdate, lastuser, lastupdate, loadtype, shiptype)
    values
        (l_loadno, sysdate, '2', in_fromfacility, shp.carrier,
         in_userid, sysdate, in_userid, sysdate, 'OUTC', 'L');

    l_stopno := 0;
    l_cube_accum := 0;
    l_weight_accum := 0;
    l_prev_bbb_shipto_master := shp.bbb_shipto_master;
    
    debug_msg('ltlv-insert loads ' ||
              l_loadno || ' ' ||
              shp.bbb_shipto_master || ' ' ||
              shp.order_shipto_master || ' ' ||
              shp.weight || ' ' ||
              shp.weight_max || ' ' ||
              shp.cube || ' ' ||
              shp.cube_max || ' ' ||
              shp.carton_count || ' ' ||
              shp.direct_to_store_yn,
              wv.bbb_custid_template,wv.facility,'debug');
              
  elsif (l_weight_accum + shp.weight > shp.weight_max) or
        (l_cube_accum + shp.cube > shp.cube_max) then
        
    insert into bbb_excluded_shipments_tmp
      (shiptocountrycode,bbb_shipto_master,order_shipto_master,
       weight,cube)
      values
      (shp.shiptocountrycode,shp.bbb_shipto_master,shp.order_shipto_master,
       shp.weight,shp.cube);
       
    goto continue_shipment_loop;
    
  end if;

  l_weight_accum := l_weight_accum + shp.weight;
  l_cube_accum := l_cube_accum + shp.cube;
  
  if (shp.direct_to_store_yn = 'Y') or
     (substr(zbbb.is_consolidator(shp.bbb_shipto_master),1,1) = 'N') then
    l_wave_consolidated := 'N';
    l_wave_picktype := 'ORDR';
    l_wave_batch_pick_by_item_yn := 'N';
  else
    l_wave_consolidated := 'Y';
    l_wave_picktype := 'BAT';
    l_wave_batch_pick_by_item_yn := 'Y';
  end if;
  
  if (shp.direct_to_store_yn = 'Y') then
    l_delpointtype := 'C';
  else
    l_delpointtype := 'D';
  end if;

  l_stopno := l_stopno + 1;
   
  insert into loadstop
    (loadno, stopno, entrydate, loadstopstatus,
     statususer, statusupdate, lastuser, lastupdate, facility,
     delpointtype, shipto)
    values
    (l_loadno, l_stopno, sysdate, '2',
     in_userid, sysdate, in_userid, sysdate, in_fromfacility,
     l_delpointtype, shp.bbb_shipto_master);

  l_prev_custid := 'x';
  l_shipno := 0;
  
  for oh in (select orderid,shipid,shipto,shipto_master,rowid,custid
               from orderhdr
              where wave = in_wave
                and nvl(shiptocountrycode,'USA') = shp.shiptocountrycode
                and nvl(shipto_master,shipto) = nvl(shp.order_shipto_master,shp.bbb_shipto_master)
              order by custid)
  loop
    
    if l_prev_custid != oh.custid then
    
      zwv.get_next_wave(l_wave, l_msg);
      
      if substr(l_msg, 1, 4) = 'OKAY' then
         l_wave_descr := rtrim(in_control_value) || ' Vendor LTL Shipment to ' || shp.bbb_shipto_master ||
                         ' (' || oh.custid || ')';
         insert into waves
            (wave, descr, wavestatus, schedrelease, actualrelease,
             facility, lastuser, lastupdate, stageloc, picktype,
             taskpriority, sortloc, job, childwave, batchcartontype,
             fromlot, tolot, orderlimit, openfacility, cntorder,
             qtyorder, weightorder, cubeorder, qtycommit, weightcommit,
             cubecommit, staffhrs, qtyhazardousorders, qtyhotorders, replanned,
             consolidated, shiptype, carrier, servicelevel, shipcost,
             weight, tms_status, tms_status_update, mass_manifest,
             pick_by_zone, master_wave,
             bbb_custid_template, batch_pick_by_item_yn, task_assignment_sequence)
         select l_wave, l_wave_descr, '2', null, null,
             in_fromfacility, in_userid, sysdate, null, l_wave_picktype,
             W.taskpriority, null, null, null, W.batchcartontype,
             W.fromlot, W.tolot, W.orderlimit, in_fromfacility, 0,
             null, null, null, null, null,
             null, null, null, null, null,
             l_wave_consolidated, W.shiptype, W.carrier, W.servicelevel, W.shipcost,
             null, W.tms_status, W.tms_status_update, W.mass_manifest,
             W.pick_by_zone, in_wave,
             W.bbb_custid_template, l_wave_batch_pick_by_item_yn, nvl(zci.default_value('WAVEPICKASSIGNMENTSEQ'),'CUBE')
           from waves W
          where W.wave = in_wave;
      else
        out_errorno := -1;
        out_msg := 'Unable to assign vendor ltl wave number';
        zms.log_autonomous_msg(	
          in_author   => zbbb.AUTHOR,
          in_facility => in_fromfacility,
          in_custid   => in_custid,
          in_msgtext  => out_msg,
          in_msgtype  => 'E',
          in_userid   => in_userid,
          out_msg		=> l_msg);
        return;
      end if;
      
      l_prev_custid := oh.custid;
      
      l_shipno := l_shipno + 1;
      
    end if;
    
    debug_msg('vendor ltl orderhdr update ' || 
            oh.orderid || ' ' ||
            oh.shipid || ' ' ||
            oh.shipto || ' ' ||
            nvl(oh.shipto_master,'(mast)') || ' ' ||
            l_shipno,
            wv.bbb_custid_template,wv.facility,'debug');
            
    begin  
      insert into loadstopship
        (loadno, stopno, shipno, entrydate,
         qtyorder, weightorder, cubeorder, amtorder,
         qtyship, weightship, cubeship, amtship,
         qtyrcvd, weightrcvd, cubercvd, amtrcvd,
         lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
        values
        (l_loadno, l_stopno, l_shipno, sysdate,
         0, 0, 0, 0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         in_userid, sysdate, 0, 0);
    exception when dup_val_on_index then
      null;
    end;
    
    update orderhdr
       set wave = l_wave,
           shiptype = 'L',
           carrier = shp.carrier
     where rowid = oh.rowid;
       
    zld.assign_outbound_order_to_load(oh.orderid,oh.shipid,shp.carrier,null,
            null,null,null,null,in_fromfacility,zbbb.AUTHOR,
            l_loadno,l_stopno,l_shipno,l_msg);
    
    if substr(l_msg,1,4) <> 'OKAY' then
      out_errorno := -4;
      out_msg := 'Unable to assign order ' || oh.orderid || '-' || oh.shipid ||
          ' to load ' || l_loadno || '. ' || chr(13) || l_msg;
      zms.log_autonomous_msg(	
        in_author   => zbbb.AUTHOR,
        in_facility => in_fromfacility,
        in_custid   => in_custid,
        in_msgtext  => out_msg,
        in_msgtype  => 'E',
        in_userid   => in_userid,
        out_msg		=> l_msg);
      return;
    end if;

    update bbb_routing_shipment_tmp
       set routing_status = 'ROUTED'
     where rowid = shp.rowid;
     
  end loop;

<< continue_shipment_loop >>
  null;
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  zms.log_autonomous_msg(	
    in_author   => zbbb.AUTHOR,
    in_facility => in_fromfacility,
    in_custid   => in_custid,
    in_msgtext  => out_msg,
    in_msgtype  => 'E',
    in_userid   => in_userid,
    out_msg		=> l_msg);
end assign_vendor_ltl_shipments;

PROCEDURE combine_waves
(in_included_wave_rowids clob
,in_fromfacility varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is 
type cur_type is ref cursor;
l_wave_cur cur_type;
l_wave_sql varchar2(4000);
l_order_cur cur_type;
l_order_sql varchar2(4000);
l_loop_count pls_integer;
l_rowid_length pls_integer := 18;
l_ai_count pls_integer := 0;
l_non_bbb_count pls_integer := 0;
l_bbb_vdp_count pls_integer := 0;
l_bbb_pac_count pls_integer := 0;
l_tot_count pls_integer := 0;
l_wave waves.wave%type;
l_wavestatus waves.wavestatus%type;
l_wave_picktype waves.picktype%type;
l_wave_combined_wave waves.combined_wave%type;
l_custid customer.custid%type;
l_paperbased customer.paperbased%type;
l_tms_format customer.tms_orders_to_plan_format%type := null;
l_tms_format_save customer.tms_orders_to_plan_format%type := null;
l_tms_status orderhdr.tms_status%type := null;
l_tms_status_save orderhdr.tms_status%type := null;
l_xdockorderid orderhdr.xdockorderid%type;
l_bbb_routing_yn customer_aux.bbb_routing_yn%type;
l_combined_wave_count pls_integer := 0;
l_new_wave waves.wave%type := 0;
l_out_msg varchar2(255);
i pls_integer;
l_orderhdr_rowid rowid;
l_wv wavesview%rowtype;

begin

out_errorno := 0;
out_msg := 'OKAY';

l_loop_count := length(in_included_wave_rowids) - length(replace(in_included_wave_rowids, ',', ''));

i := 1;

while (i <= l_loop_count)
loop 

  l_wave_sql := 'select wave, wavestatus, nvl(picktype,''x''), nvl(combined_wave,''N'') ' ||
                 ' from waves ' ||
                ' where rowid in (';

  while length(l_wave_sql) < 3975 -- 4000 character limit for open cursor command
  loop
    l_wave_sql := l_wave_sql || '''' || substr(in_included_wave_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_wave_sql) < 3975) then
      l_wave_sql := l_wave_sql || ',';
    else
      exit;
    end if;
  end loop;
  
  l_wave_sql := l_wave_sql || ')';
  
  open l_wave_cur for l_wave_sql;
  loop

    fetch l_wave_cur into l_wave, l_wavestatus, l_wave_picktype, l_wave_combined_wave;
    exit when l_wave_cur%notfound;

    if l_wavestatus > '2' then
      out_errorno := -1;
      out_msg := 'Cannot combine.  Wave ' || l_wave || ' has invalid status: ' || l_wavestatus;
      goto end_of_combine;
    end if;

    if l_wave_combined_wave = 'N' and
       l_wave_picktype not in ('LINE','ORDR') then
      out_errorno := -11;
      out_msg := 'Cannot combine.  Wave ' || l_wave || ' must be an ORDR or LINE pick type.';
      goto end_of_combine;
    end if;
    
    l_order_sql := 'select oh.custid, nvl(cu.paperbased,''N''), cu.tms_orders_to_plan_format,' ||
                   'oh.tms_status, oh.xdockorderid, nvl(ca.bbb_routing_yn,''N'') ' ||
                    ' from customer cu, customer_aux ca, orderhdr oh ' ||
                    'where oh.custid = cu.custid(+) ' ||
                    '  and oh.custid = ca.custid(+) ' ||
                    '  and oh.wave = ' || l_wave ||
                    '  and oh.orderstatus != ''X''';
    
    open l_order_cur for l_order_sql;
    loop
      fetch l_order_cur into l_custid, l_paperbased, l_tms_format, l_tms_status,
           l_xdockorderid, l_bbb_routing_yn;
      exit when l_order_cur%notfound;
      if nvl(l_xdockorderid,0) != 0 then
        out_errorno := -100;
        out_msg := 'Wave may not contain outbound Transload orders.';
        return;
      end if;
      
      l_tot_count := l_tot_count + 1;
      
      if l_paperbased = 'Y' then
        l_ai_count := l_ai_count + 1;
      elsif l_bbb_routing_yn = 'V' then
        l_bbb_vdp_count := l_bbb_vdp_count + 1;
      elsif l_bbb_routing_yn = 'P' then
        l_bbb_pac_count := l_bbb_pac_count + 1;
      else      
        l_non_bbb_count := l_non_bbb_count + 1;
      end if;    

      if l_tms_format_save is null then
        l_tms_format_save :=  l_tms_format;
        l_tms_status_save := l_tms_status;
      end if;
      
      if (nvl(l_tms_format_save,'x') != nvl(l_tms_format,'x') ) then
        out_errorno := -300;
        out_msg  := 'TMS formats mismatch. Customer ' || l_custid || ' Format: ' ||
                    l_tms_format || chr(13) ||
                    'does not match ' || l_tms_format_save;
        goto end_of_combine;
      end if;
        
    end loop;

    close l_order_cur;

  end loop;

  close l_wave_cur;

end loop;

if l_ai_count != l_tot_count and
   l_bbb_vdp_count != l_tot_count and
   l_bbb_pac_count != l_tot_count and
   l_non_bbb_count != l_tot_count then
  out_errorno := -222;
  out_msg := 'The selected waves contain a mix of the following order types: ';
  if l_ai_count != 0 then
    out_msg := out_msg || chr(13) || 'Aggregate Inventory ';
  end if;
  if l_bbb_vdp_count != 0 then
    out_msg := out_msg || chr(13) || 'BBB-Vendor Program ';
  end if;
  if l_bbb_pac_count != 0 then
    out_msg := out_msg || chr(13) || 'BBB-Pooler and Consolidator';
  end if;
  if l_non_bbb_count != 0 then
    out_msg := out_msg || chr(13) || 'Non-BBB';
  end if;
  out_msg := out_msg || chr(13) || 'They cannot be combined.';
  goto end_of_combine;
end if;

l_loop_count := length(in_included_wave_rowids) - length(replace(in_included_wave_rowids, ',', ''));

i := 1;

while (i <= l_loop_count)
loop 

  l_wave_sql := 'select * ' ||
                 ' from wavesview ' ||
                ' where waves_rowid in (';

  while length(l_wave_sql) < 3975 -- 4000 character limit for open cursor command
  loop
    l_wave_sql := l_wave_sql || '''' || substr(in_included_wave_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_wave_sql) < 3975) then
      l_wave_sql := l_wave_sql || ',';
    else
      exit;
    end if;
  end loop;
  
  l_wave_sql := l_wave_sql || ')';
  
  open l_wave_cur for l_wave_sql;
  loop

    fetch l_wave_cur into l_wv;
    exit when l_wave_cur%notfound;
    
    if l_wv.combined_wave = 'Y' then
      l_new_wave := l_wv.wave;
      l_combined_wave_count := l_combined_wave_count + 1;
    end if;

  end loop;

  close l_wave_cur;

end loop;

if l_combined_wave_count > 1 then
  out_errorno := -1111;
  out_msg :=  'Combined waves cannot be combined.';
  goto end_of_combine;
end if;

if l_new_wave = 0 then
  zwv.get_next_wave(l_new_wave,out_msg);
  insert into waves
      (wave, descr, wavestatus,
       facility, lastuser, lastupdate, stageloc, picktype,
       taskpriority, sortloc, batchcartontype,
       openfacility, consolidated, combined_wave, batch_pick_by_item_yn, task_assignment_sequence
       )
   values
   (l_new_wave, 'Combined Wave', '2',
    in_fromfacility, in_userid, sysdate, null, l_wv.picktype,
    l_wv.taskpriority, l_wv.sortloc, l_wv.batchcartontype,
    in_fromfacility, l_wv.consolidated, 'Y', l_wv.batch_pick_by_item_yn, l_wv.task_assignment_sequence);
end if;

l_loop_count := length(in_included_wave_rowids) - length(replace(in_included_wave_rowids, ',', ''));

i := 1;

while (i <= l_loop_count)
loop 

  l_wave_sql := 'select wave, wavestatus' ||
                 ' from waves ' ||
                 ' where rowid in (';

  while length(l_wave_sql) < 3975 -- 4000 character limit for open cursor command
  loop
    l_wave_sql := l_wave_sql || '''' || substr(in_included_wave_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_wave_sql) < 3975) then
      l_wave_sql := l_wave_sql || ',';
    else
      exit;
    end if;
  end loop;
  
  l_wave_sql := l_wave_sql || ')';
  
  open l_wave_cur for l_wave_sql;
  loop

    fetch l_wave_cur into l_wave, l_wavestatus;
    exit when l_wave_cur%notfound;

     if l_wave != l_new_wave then
    
      l_order_sql := 'select oh.rowid ' ||
                       'from orderhdr oh ' ||
                       'where oh.wave = ' || l_wave ||
                       '  and oh.orderstatus != ''X''';
      
      open l_order_cur for l_order_sql;
      loop
      
        fetch l_order_cur into l_orderhdr_rowid;
        exit when l_order_cur%notfound;
        
        update orderhdr
           set wave = l_new_wave,
               original_wave_before_combine = l_wave,
               lastuser = in_userid,
               lastupdate = sysdate
         where rowid = l_orderhdr_rowid;
         
      end loop;

      close l_order_cur;
      
      update waves
         set wavestatus = '4',
             lastuser = in_userid,
             lastupdate = sysdate
       where wave = l_wave;
       
    end if;
     
  end loop;

  close l_wave_cur;

end loop;

out_errorno := l_new_wave;

<< end_of_combine >>

if l_wave_cur%isopen then
  close l_wave_cur;
end if;
  
if l_order_cur%isopen then
  close l_order_cur;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  if l_wave_cur%isopen then
    close l_wave_cur;
  end if;
  if l_order_cur%isopen then
    close l_order_cur;
  end if;
end combine_waves;

PROCEDURE uncombine_wave
(in_wave number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is 

l_wavestatus waves.wavestatus%type;
l_combined_wave waves.combined_wave%type;

begin

out_errorno := 0;
out_msg := 'OKAY';

begin
  select wavestatus, nvl(combined_wave,'N')
    into l_wavestatus, l_combined_wave
    from waves
   where wave = in_wave;
exception when others then
  out_errorno := -1;
  out_msg := 'Wave ' || in_wave || ' not found';
  return;
end;

if l_wavestatus > '2' then
  out_errorno := -2;
  out_msg := 'Wave ' || in_wave || ' invalid status for uncombine: ' || l_wavestatus;
  return;
end if;

if l_combined_wave != 'Y' then
  out_errorno := -3;
  out_msg := 'Wave ' || in_wave || ' is not a combined wave';
  return;
end if;

for oh in (select rowid,original_wave_before_combine
             from orderhdr
            where wave = in_wave
              and orderstatus != 'X')
loop

  update waves
     set wavestatus = '1',
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.original_wave_before_combine
     and wavestatus > '1';
     
  update orderhdr
     set wave = oh.original_wave_before_combine,
         original_wave_before_combine = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where rowid = oh.rowid;
   
end loop;

update waves
   set wavestatus = '4',
       lastuser = in_userid,
       lastupdate = sysdate
 where wave = in_wave;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end uncombine_wave;

function tasksview_item
(in_wave number
,in_taskid number
,in_tasktype varchar2
,in_item varchar2
) return varchar2

is

l_batch_pick_by_item_yn waves.batch_pick_by_item_yn%type;
l_out_item custitem.item%type;

begin

if (nvl(in_tasktype,'x') != 'BP') or
   (in_item is not null) then
  return in_item;
end if;

l_out_item := in_item;

begin
  select nvl(batch_pick_by_item_yn,'N')
    into l_batch_pick_by_item_yn
    from waves
   where wave = in_wave;
exception when others then
  l_batch_pick_by_item_yn := 'N';
end;

if l_batch_pick_by_item_yn = 'Y' then
  begin
    select item
      into l_out_item
      from subtasks
     where taskid = in_taskid
       and rownum < 2;
  exception when others then
    null;
  end;
end if;

return l_out_item;

exception when others then
  return in_item;
end tasksview_item;

END zbedbathbeyond;
/
show errors package body zbedbathbeyond;

exit;
