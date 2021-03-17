create or replace PACKAGE BODY alps.zcustomer
IS
--
-- $Id$
--

FUNCTION lot_label
(in_custid IN varchar2
) return varchar2 is

out custdict%rowtype;

begin

out.labelvalue := 'Lot';
select labelvalue
  into out.labelvalue
  from custdict
 where custid = in_custid
   and fieldname = 'LOTNUMBER';

return out.labelvalue;

exception when others then
  return 'Lot';
end lot_label;

FUNCTION item_label
(in_custid IN varchar2
) return varchar2 is

out custdict%rowtype;

begin

out.labelvalue := 'Item';
select labelvalue
  into out.labelvalue
  from custdict
 where custid = in_custid
   and fieldname = 'ITEM';

return out.labelvalue;

exception when others then
  return 'Item';
end item_label;

FUNCTION po_label
(in_custid IN varchar2
) return varchar2 is

out custdict%rowtype;

begin

out.labelvalue := 'PO';
select labelvalue
  into out.labelvalue
  from custdict
 where custid = in_custid
   and fieldname = 'PO';

return out.labelvalue;

exception when others then
  return 'PO';
end po_label;

FUNCTION equiv_uom_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_fromuom IN varchar2
,in_qty IN number
,in_touom IN varchar2
) return number is

rc number;


FUNCTION euq
(in_custid IN varchar2
,in_item IN varchar2
,in_fromuom IN varchar2
,in_qty IN number
,in_touom IN varchar2
,in_depth IN number
,in_skips in varchar2
) return number is

curruom varchar2(4);
rqty number;
rc number;
begin

if nvl(in_qty,0) = 0 then
  return 0;
end if;

if in_fromuom = in_touom then
  return in_qty;
end if;

if in_depth > 10 then
  return -1;
end if;

if instr(in_skips,'|'||in_fromuom||'|') > 0 then
  return -1;
end if;

curruom := in_fromuom;

for crec in (select * from custitemuom
              where custid = in_custid
                and item = in_item
                and (fromuom = in_fromuom
                    or touom = in_fromuom))
loop

  if in_fromuom = crec.fromuom then
    curruom := crec.touom;
    rqty := in_qty/crec.qty;
  else
    curruom := crec.fromuom;
    rqty := in_qty * crec.qty;
  end if;

  rc := euq(in_custid, in_item, curruom, rqty, in_touom,
        in_depth+1,nvl(in_skips,'|')||in_fromuom||'|');
  if rc > 0 then
    return rc;
  end if;

end loop;

return -1;

exception when others then
  return in_qty;
end euq;

begin

  rc := euq(in_custid, in_item, in_fromuom, in_qty, in_touom, 1, '');

  if rc < 0 then
    return in_qty;
  end if;

  return rc;

exception when others then
  return in_qty;
end equiv_uom_qty;


FUNCTION equiv_uom_qty_old
(in_custid IN varchar2
,in_item IN varchar2
,in_fromuom IN varchar2
,in_qty IN number
,in_touom IN varchar2
) return number is

cursor equivuom(in_uom varchar2) is
  select touom, qty
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_uom;
e equivuom%rowtype;

loopcount integer;
curruom varchar2(4);
returnqty number;

begin

if nvl(in_qty,0) = 0 then
  return 0;
end if;

if in_fromuom = in_touom then
  return in_qty;
end if;

loopcount := 0;
returnqty := in_qty;
curruom := in_fromuom;
while curruom != in_touom
loop
  if loopcount > 255 then
    return in_qty;
  end if;
  open equivuom(curruom);
  fetch equivuom into e;
  if equivuom%notfound then
    close equivuom;
    return in_qty;
  end if;
  close equivuom;
  curruom := e.touom;
  returnqty := returnqty / to_number(e.qty);
  loopcount := loopcount + 1;
end loop;

return returnqty;

exception when others then
  return in_qty;
end equiv_uom_qty_old;

procedure pack_list_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
) is

cursor curOrderHdr is
  select custid,carrier,deliveryservice,nvl(shipto, shiptoname) shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curorderhdr%rowtype;

cursor curPackListOrderHdr is
  select defaultvalue as packlist_field
    from systemdefaults
   where defaultid='PACKINGLISTFIELD';

cursor curCustPackList is
  select packlist_field1,packlist_field2
    from customer_aux
   where custid = oh.custid;

cursor curOrderHdrFieldType(in_column_name varchar2) is
  select data_type
    from user_tab_columns
   where table_name = 'ORDERHDR'
     and column_name = in_column_name;

cursor curCustPackListBycarrier is
  select packlistyn,packlistformat
    from custpacklist
   where custid = oh.custid
     and carrier = oh.carrier
     and ( (servicecode = oh.deliveryservice) or
           (servicecode is null) )
   order by servicecode;

dirprefix varchar2(255);
packlist_field1 varchar2(106);
packlist_field2 varchar2(106);
field_type varchar2(106);
field2_type varchar2(106);
str_field1 varchar2(130);
str_field2 varchar2(130);

begin

out_format := null;
out_format_type := null;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_format := 'Order Not Found ' || in_orderid || '-' || in_shipid;
  return;
end if;

open curPackListOrderHdr;
fetch curPackListOrderHdr into packlist_field1;
close curPackListOrderHdr;

if packlist_field1 is null then
  goto check_custpacklist;
end if;

field_type := null;
open curOrderHdrFieldType(packlist_field1);
fetch curOrderHdrFieldType into field_type;
close curOrderHdrFieldType;

str_field1 := null;

if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
  str_field1 := 'oh.'||packlist_field1;
elsif (field_type = 'DATE') then
  str_field1 := 'TO_CHAR(oh.'||packlist_field1||',''MMDDYYYY'')';
elsif (field_type = 'NUMBER') then
  str_field1 := 'TO_CHAR(oh.'||packlist_field1||')';
end if;

if str_field1 is null then
  goto check_custpacklist;
end if;

begin
  execute immediate 'select pl.packlist_format '
                || ' from orderhdr oh, packinglist pl'
                || ' where oh.orderid = ' || in_orderid
                || ' and oh.shipid = ' || in_shipid
                || ' and ' || str_field1 || ' = pl.packlist_field_value'
                  into out_format;
exception
  when NO_DATA_FOUND then goto check_custpacklist;
end;

if out_format is not null then
  goto check_default;
end if;

<< check_custpacklist >>

open curCustPackList;
fetch curCustPackList into packlist_field1,packlist_field2;
close curCustPackList;

if packlist_field1 is null then
  goto check_custcarrier;
end if;

field_type := null;
open curOrderHdrFieldType(packlist_field1);
fetch curOrderHdrFieldType into field_type;
close curOrderHdrFieldType;

str_field1 := null;

if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
  str_field1 := 'oh.'||packlist_field1;
elsif (field_type = 'DATE') then
  str_field1 := 'TO_CHAR(oh.'||packlist_field1||',''MMDDYYYY'')';
elsif (field_type = 'NUMBER') then
  str_field1 := 'TO_CHAR(oh.'||packlist_field1||')';
end if;

if packlist_field2 is not null then
  field_type := null;
  open curOrderHdrFieldType(packlist_field2);
  fetch curOrderHdrFieldType into field_type;
  close curOrderHdrFieldType;

  str_field2 := null;
  
  if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
    str_field2 := 'oh.'||packlist_field2;
  elsif (field_type = 'DATE') then
    str_field2 := 'TO_CHAR(oh.'||packlist_field2||',''MMDDYYYY'')';
  elsif (field_type = 'NUMBER') then
    str_field2 := 'TO_CHAR(oh.'||packlist_field2||')';
  end if;

  begin
    execute immediate 'select packlist_format '
                  || ' from orderhdr oh, custpacklistbyfield cpl'
                  || ' where oh.orderid = ' || in_orderid
                  || ' and oh.shipid = ' || in_shipid
                  || ' and oh.custid = cpl.custid'
                  || ' and ' || str_field1 || ' = cpl.packlist_field1_value'
                  || ' and ' || str_field2 || ' = cpl.packlist_field2_value'
                    into out_format;
  exception
    when NO_DATA_FOUND then goto check_custcarrier;
  end;
else

  begin
    execute immediate 'select packlist_format '
                  || ' from orderhdr oh, custpacklistbyfield cpl'
                  || ' where oh.orderid = ' || in_orderid
                  || ' and oh.shipid = ' || in_shipid
                  || ' and oh.custid = cpl.custid'
                  || ' and ' || str_field1 || ' = cpl.packlist_field1_value'
                    into out_format;
  exception
    when NO_DATA_FOUND then goto check_custcarrier;
  end;
end if;

if out_format is not null then
  goto check_default;
end if;


<< check_custcarrier >>

open curCustPackListBycarrier;
fetch curCustPackListBycarrier into out_format_type,out_format;
close curCustPackListBycarrier;

if out_format_type is null then
  goto check_customer;
end if;

if out_format_type = 'N' then
  out_format := null;
  return;
else
  goto check_default;
end if;

<< check_customer >>

begin
  select nvl(packlist,'N'),packlistrptfile
    into out_format_type,out_format
    from customer
   where custid = oh.custid;
exception when others then
  null;
end;

if out_format_type = 'N' then
  out_format := null;
  return;
end if;

<< check_default >>

if out_format is null then
  out_format := substr(zci.default_value('PACKLISTREPORT'),1,255);
  goto check_path;
end if;

<<check_path>>

if substr(out_format,1,1) = '\' then
  dirprefix := null;
  begin
    select defaultvalue
      into dirprefix
      from systemdefaults
     where defaultid = 'REPORTSDIRECTORY';
  exception when others then
    null;
  end;
  out_format := dirprefix || out_format;
end if;

return;

exception when others then
  out_format := substr(sqlerrm,1,255);
end pack_list_format;

procedure master_pack_list_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
) is

cursor curOrderHdr is
  select OH.custid, W.carrier,W.servicelevel deliveryservice
    from orderhdr OH, waves W
   where W.wave = in_orderid
     and OH.wave = W.wave;
oh curorderhdr%rowtype;

cursor curCustPackListBycarrier is
  select masterpacklist,masterpacklistrptfile
    from custpacklist
   where custid = oh.custid
     and carrier = oh.carrier
     and ( (servicecode = oh.deliveryservice) or
           (servicecode is null) )
   order by servicecode;

dirprefix varchar2(255);

begin

out_format := null;
out_format_type := null;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_format := 'Order Not Found ' || in_orderid || '-' || in_shipid;
  return;
end if;

open curCustPackListBycarrier;
fetch curCustPackListBycarrier into out_format_type,out_format;
close curCustPackListBycarrier;

if out_format_type is null then
  goto check_customer;
end if;

if out_format_type = 'N' then
  out_format := null;
  return;
else
  goto check_default;
end if;

<< check_customer >>

begin
  select nvl(masterpacklist,'N'),masterpacklistrptfile
    into out_format_type,out_format
    from customer
   where custid = oh.custid;
exception when others then
  null;
end;

if out_format_type = 'N' then
  out_format := null;
  return;
end if;

<< check_default >>

if out_format is null then
  out_format := substr(zci.default_value('MASTERPACKLISTREPORT'),1,255);
  goto check_path;
end if;

<<check_path>>

if substr(out_format,1,1) = '\' then
  dirprefix := null;
  begin
    select defaultvalue
      into dirprefix
      from systemdefaults
     where defaultid = 'REPORTSDIRECTORY';
  exception when others then
    null;
  end;
  out_format := dirprefix || out_format;
end if;

return;

exception when others then
  out_format := substr(sqlerrm,1,255);
end master_pack_list_format;

function bol_rpt_format
(in_orderid in number
,in_shipid in number
) return varchar2 is

cursor curOrderHdr is
  select custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curorderhdr%rowtype;

cursor curCustBolRpt is
  select bolrpt_field1,bolrpt_field2
    from custbolrptbyfield
   where custid = oh.custid
     and bolrpt_field1 is not null
   order by decode(bolrpt_field2,null,2,1), bolrpt_field1, bolrpt_field2;
cbr curCustBolRpt%rowtype;

cursor curOrderHdrFieldType(in_column_name varchar2) is
  select data_type
    from user_tab_columns
   where table_name = 'ORDERHDR'
     and column_name = in_column_name;

dirprefix varchar2(255);
field_type varchar2(106);
str_field1 varchar2(130);
str_field2 varchar2(130);
out_format varchar2(510);

begin

out_format := null;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_format := 'Order Not Found ' || in_orderid || '-' || in_shipid;
  return out_format;
end if;

for cbr in curCustBolRpt
loop
  field_type := null;
  open curOrderHdrFieldType(cbr.bolrpt_field1);
  fetch curOrderHdrFieldType into field_type;
  close curOrderHdrFieldType;
  
  str_field1 := null;
  
  if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
    str_field1 := 'oh.'||cbr.bolrpt_field1;
  elsif (field_type = 'DATE') then
    str_field1 := 'TO_CHAR(oh.'||cbr.bolrpt_field1||',''MMDDYYYY'')';
  elsif (field_type = 'NUMBER') then
    str_field1 := 'TO_CHAR(oh.'||cbr.bolrpt_field1||')';
  end if;
  
  if cbr.bolrpt_field2 is not null then
    field_type := null;
    open curOrderHdrFieldType(cbr.bolrpt_field2);
    fetch curOrderHdrFieldType into field_type;
    close curOrderHdrFieldType;
  
    str_field2 := null;
    
    if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
      str_field2 := 'oh.'||cbr.bolrpt_field2;
    elsif (field_type = 'DATE') then
      str_field2 := 'TO_CHAR(oh.'||cbr.bolrpt_field2||',''MMDDYYYY'')';
    elsif (field_type = 'NUMBER') then
      str_field2 := 'TO_CHAR(oh.'||cbr.bolrpt_field2||')';
    end if;
  
    begin
      execute immediate 'select bolrpt_format '
                    || ' from orderhdr oh, custbolrptbyfield cbr'
                    || ' where oh.orderid = ' || in_orderid
                    || ' and oh.shipid = ' || in_shipid
                    || ' and oh.custid = cbr.custid'
                    || ' and ''' || cbr.bolrpt_field1 || ''' = cbr.bolrpt_field1'
                    || ' and ''' || cbr.bolrpt_field2 || ''' = cbr.bolrpt_field2'
                    || ' and ' || str_field1 || ' = cbr.bolrpt_field1_value'
                    || ' and ' || str_field2 || ' = cbr.bolrpt_field2_value'
                      into out_format;
    exception
      when NO_DATA_FOUND then goto cbr_loop_end;
    end;
  else
  
    begin
      execute immediate 'select bolrpt_format '
                    || ' from orderhdr oh, custbolrptbyfield cbr'
                    || ' where oh.orderid = ' || in_orderid
                    || ' and oh.shipid = ' || in_shipid
                    || ' and oh.custid = cbr.custid'
                    || ' and ''' || cbr.bolrpt_field1 || ''' = cbr.bolrpt_field1'
                    || ' and ' || str_field1 || ' = cbr.bolrpt_field1_value'
                      into out_format;
    exception
      when NO_DATA_FOUND then goto cbr_loop_end;
    end;
  end if;
  
  if out_format is not null then
    goto check_default;
  end if;
  
<< cbr_loop_end >>
  null;
end loop;
  
<< check_customer >>

begin
  select bolrptfile
    into out_format
    from customer
   where custid = oh.custid;
exception when others then
  null;
end;

<< check_default >>

if out_format is null then
  out_format := substr(zci.default_value('BOLREPORT'),1,255);
end if;

return out_format;

exception when others then
  return substr(sqlerrm,1,255);
end bol_rpt_format;

function bol_rpt_fullpath
(in_orderid in number
,in_shipid in number
) return varchar2 is
directory varchar2(255);
reportformat varchar2(255);

begin
	directory := zci.default_value('REPORTSDIRECTORY');
	reportformat := bol_rpt_format(in_orderid, in_shipid);
	
	if (substr(directory,-1,1) != '\') and (substr(reportformat,1,1) != '\') then
	  return directory || '\' || reportformat;
	end if;
	
	return directory || reportformat;
	  
exception when others then
  return substr(sqlerrm,1,255);
end bol_rpt_fullpath;

function mbol_rpt_format
(in_orderid in number
,in_shipid in number
) return varchar2 is

cursor curOrderHdr is
  select custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curorderhdr%rowtype;

cursor curCustBolRpt is
  select bolrpt_field1,bolrpt_field2
    from custbolrptbyfield
   where custid = oh.custid
     and bolrpt_field1 is not null
   order by decode(bolrpt_field2,null,2,1), bolrpt_field1, bolrpt_field2;

cursor curOrderHdrFieldType(in_column_name varchar2) is
  select data_type
    from user_tab_columns
   where table_name = 'ORDERHDR'
     and column_name = in_column_name;

dirprefix varchar2(255);
bolrpt_field1 varchar2(106);
bolrpt_field2 varchar2(106);
field_type varchar2(106);
field2_type varchar2(106);
str_field1 varchar2(130);
str_field2 varchar2(130);
out_format varchar2(510);

begin

out_format := null;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_format := 'Order Not Found ' || in_orderid || '-' || in_shipid;
  return out_format;
end if;

open curCustBolRpt;
fetch curCustBolRpt into bolrpt_field1,bolrpt_field2;
close curCustBolRpt;

if bolrpt_field1 is null then
  goto check_customer;
end if;

field_type := null;
open curOrderHdrFieldType(bolrpt_field1);
fetch curOrderHdrFieldType into field_type;
close curOrderHdrFieldType;

str_field1 := null;

if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
  str_field1 := 'oh.'||bolrpt_field1;
elsif (field_type = 'DATE') then
  str_field1 := 'TO_CHAR(oh.'||bolrpt_field1||',''MMDDYYYY'')';
elsif (field_type = 'NUMBER') then
  str_field1 := 'TO_CHAR(oh.'||bolrpt_field1||')';
end if;

if bolrpt_field2 is not null then
  field_type := null;
  open curOrderHdrFieldType(bolrpt_field2);
  fetch curOrderHdrFieldType into field_type;
  close curOrderHdrFieldType;

  str_field2 := null;
  
  if (field_type = 'CHAR' or field_type = 'VARCHAR2') then
    str_field2 := 'oh.'||bolrpt_field2;
  elsif (field_type = 'DATE') then
    str_field2 := 'TO_CHAR(oh.'||bolrpt_field2||',''MMDDYYYY'')';
  elsif (field_type = 'NUMBER') then
    str_field2 := 'TO_CHAR(oh.'||bolrpt_field2||')';
  end if;

  begin
    execute immediate 'select mbolrpt_format '
                  || ' from orderhdr oh, custbolrptbyfield cbr'
                  || ' where oh.orderid = ' || in_orderid
                  || ' and oh.shipid = ' || in_shipid
                  || ' and oh.custid = cbr.custid'
                  || ' and ' || str_field1 || ' = cpl.bolrpt_field1_value'
                  || ' and ' || str_field2 || ' = cpl.bolrpt_field2_value'
                    into out_format;
  exception
    when NO_DATA_FOUND then goto check_customer;
  end;
else

  begin
    execute immediate 'select mbolrpt_format '
                  || ' from orderhdr oh, custbolrptbyfield cbr'
                  || ' where oh.orderid = ' || in_orderid
                  || ' and oh.shipid = ' || in_shipid
                  || ' and oh.custid = cbr.custid'
                  || ' and ' || str_field1 || ' = cbr.bolrpt_field1_value'
                    into out_format;
  exception
    when NO_DATA_FOUND then goto check_customer;
  end;
end if;

if out_format is not null then
  goto check_default;
end if;

<< check_customer >>

begin
  select mastbolrptfile
    into out_format
    from customer
   where custid = oh.custid;
exception when others then
  null;
end;

<< check_default >>

if out_format is null then
  out_format := substr(zci.default_value('MASTERBOLREPORT'),1,255);
end if;

return out_format;

exception when others then
  return substr(sqlerrm,1,255);
end mbol_rpt_format;

FUNCTION next_uom
(in_custid varchar2
,in_item varchar2
,in_fromuom varchar2
,in_next_count number
) return varchar2 is

cursor equivuom(in_uom varchar2) is
  select touom
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_uom;

out_touom custitem.baseuom%type;

begin

out_touom := null;


open equivuom(in_fromuom);
fetch equivuom into out_touom;
close equivuom;

if in_next_count = 0 then
  goto return_out_touom;
end if;

<< return_out_touom >>

return out_touom;

exception when others then
  return null;
end next_uom;


procedure pack_list_audit_format
(in_orderid in number
,in_shipid in number
,out_format in out varchar2
) is

cursor curOrderHdr is
  select custid,carrier,deliveryservice
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curorderhdr%rowtype := null;

cursor curCustPackListBycarrier is
  select packlistformat, packlistafteraudityn
    from custpacklist
   where custid = oh.custid
     and carrier = oh.carrier
     and ( (servicecode = oh.deliveryservice) or
           (servicecode is null) )
   order by servicecode;

dirprefix varchar2(255);
l_yn varchar2(1);

begin

out_format := null;

open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  return;
end if;

open curCustPackListBycarrier;
fetch curCustPackListBycarrier into out_format, l_yn;
close curCustPackListBycarrier;

if nvl(l_yn,'N') = 'N' then
  out_format := null;
  begin
    select packlistrptfile, packlistafteraudityn
      into out_format, l_yn
      from customer
     where custid = oh.custid;
  exception when others then
    null;
  end;
  if nvl(l_yn,'N') = 'N' then
    out_format := null;
    return;
  end if;
end if;

if out_format is null then
  out_format := substr(zci.default_value('PACKLISTREPORT'),1,255);
end if;

if substr(out_format,1,1) = '\' then
  dirprefix := null;
  begin
    select defaultvalue
      into dirprefix
      from systemdefaults
     where defaultid = 'REPORTSDIRECTORY';
  exception when others then
    null;
  end;
  out_format := dirprefix || out_format;
end if;

return;

exception when others then
  out_format := substr(sqlerrm,1,255);
end pack_list_audit_format;

FUNCTION credit_hold
(in_custid IN varchar2
) return varchar2 is

l_credithold customer.credithold%type;

begin

select nvl(credithold,'N')
  into l_credithold
  from customer
 where custid = in_custid;

return nvl(l_credithold,'N');

exception when others then
  return 'N';
end credit_hold;

procedure order_check_format
(in_orderid in number
,in_shipid in number
,out_format_type in out varchar2
,out_format in out varchar2
) is

cursor curOrderHdr is
  select custid, qtyorder, qtypick, qtytotcommit
    from orderhdr OH
   where orderid = in_orderid
     and shipid = in_shipid;
oh curorderhdr%rowtype;

cursor curCustomer is
  select nvl(printordercheck_yn,'N') printordercheck_yn, ordercheckformat,
         decode(nvl(reduceorderqtybycancel,'D'),'D',
         nvl(zci.default_value('REDUCEORDERQTYBYCANCEL'),'N'),'Y','Y','N') reduceorderqtybycancel
    from customer cu, customer_aux ca
   where cu.custid = OH.custid
     and ca.custid = cu.custid;
cu curCustomer%rowtype;

cursor curOrderDtl(in_orderid number, in_shipid number) is
  select qtyorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus = 'X';
dirprefix varchar2(255);
l_qtycancel orderdtl.qtyorder%type;
l_qty_not_staged pls_integer;
begin

out_format := null;
out_format_type := null;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_format := 'Order Not Found ' || in_orderid || '-' || in_shipid;
  return;
end if;

open curCustomer;
fetch curCustomer into out_format_type,out_format,cu.reduceorderqtybycancel;
close curCustomer;

if out_format_type != 'N' then
  l_qtycancel := 0;
  if cu.reduceorderqtybycancel <> 'Y' then
    for od in curOrderDtl(in_orderid,in_shipid)
    loop
      l_qtycancel := l_qtycancel + od.qtyorder;
    end loop;
  end if;
  if oh.qtytotcommit - oh.qtypick - l_qtycancel > 0 then
    out_format_type := 'N';
  end if;
  begin
    select count(1)
      into l_qty_not_staged
      from shippingplate /*+ index(SHIPPINGPLATE SHIPPINGPLATE_ORDER) */
     where orderid = in_orderid
       and shipid = in_shipid
       and status != 'S';
  exception when others then
    l_qty_not_staged := 0;
  end;
  if l_qty_not_staged != 0 then
    out_format_type := 'N';
  end if;
end if;
if out_format_type = 'N' then
  out_format := null;
  return;
end if;


if out_format is null then
  out_format := substr(zci.default_value('ORDERCHECKREPORT'),1,255);
end if;


if substr(out_format,1,1) = '\' then
  dirprefix := null;
  begin
    select defaultvalue
      into dirprefix
      from systemdefaults
     where defaultid = 'REPORTSDIRECTORY';
  exception when others then
    null;
  end;
  out_format := dirprefix || out_format;
end if;

return;

exception when others then
  out_format := substr(sqlerrm,1,255);
end order_check_format;

procedure small_pkg_email_pack_list_fmt
(in_custid in varchar2
,out_format in out varchar2
,out_email_addresses in out varchar2
)
is
begin
out_format := '';
out_email_addresses := '';
select packlist_email_rpt_format, packlist_email_addresses
  into out_format, out_email_addresses
  from customer_aux
 where custid = in_custid
   and packlist_email_yn = 'Y';
exception when others then
  out_format := '';
  out_email_addresses := '';
end small_pkg_email_pack_list_fmt;
end zcustomer;
/
show errors package zcustomer;
show errors package body zcustomer;
exit;
