create or replace package body alps.zimportprocsip as
--
-- $Id$
--

function lip_expirationdate
(in_lpid varchar2
) return date is

cursor curPlate is
  select expirationdate
    from plate
   where lpid = in_lpid;

cursor curDeletedPlate is
  select expirationdate
    from deletedplate
   where lpid = in_lpid;

out_expirationdate date;

begin

out_expirationdate := null;

open curPlate;
fetch curPlate into out_expirationdate;
close curPlate;
if out_expirationdate is null then
  open curDeletedPlate;
  fetch curDeletedPlate into out_expirationdate;
  close curDeletedPlate;
end if;

return out_expirationdate;

exception when others then
  return null;
end lip_expirationdate;

function order_reference
(in_orderid IN number
,in_shipid IN number
,in_qualifier IN varchar2
) return varchar2 is

cursor curOrderHdr is
  select orderid,
         nvl(ld.prono,oh.prono) as prono,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         hdrpassthruchar19,
         hdrpassthruchar20
    from loads ld, orderhdr oh
   where orderid = in_orderid
     and shipid = in_shipid
     and oh.loadno = ld.loadno(+);
oh curOrderHdr%rowtype;

ix integer;
pos integer;
strlen integer;
qualen integer;
strQualifier varchar2(4);
strData varchar2(255);
out_order_reference varchar2(30);

begin

out_order_reference := null;

open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  return null;
end if;

if in_qualifier = 'BM' then
  out_order_reference := oh.billoflading;
  goto return_reference;
end if;

if in_qualifier = 'CN' then
  out_order_reference := oh.prono;
  goto return_reference;
end if;

strQualifier := '|' || rtrim(in_qualifier) || '|';
qualen := length(rtrim(strQualifier));

pos := instr(oh.hdrpassthruchar19,strQualifier);
if nvl(pos,0) = 0 then
  goto try_passthruchar20;
end if;

pos := pos + qualen;
strLen := nvl(length(rtrim(oh.hdrpassthruchar19)),0);
while (1=1)
loop
  if pos > strLen then
    exit;
  end if;
  if substr(oh.hdrpassthruchar19,pos,1) = '|' then
    exit;
  end if;
  if out_order_reference is null then
    out_order_reference := substr(oh.hdrpassthruchar19,pos,1);
  else
    out_order_reference := out_order_reference || substr(oh.hdrpassthruchar19,pos,1);
  end if;
  pos := pos + 1;
end loop;

goto return_reference;

<< try_passthruchar20 >>

pos := instr(oh.hdrpassthruchar20,strQualifier);
if nvl(pos,0) = 0 then
  goto return_reference;
end if;

pos := pos + qualen;
strLen := length(rtrim(oh.hdrpassthruchar20));
while (1=1)
loop
  if pos > strLen then
    exit;
  end if;
  if substr(oh.hdrpassthruchar20,pos,1) = '|' then
    exit;
  end if;
  if out_order_reference is null then
    out_order_reference := substr(oh.hdrpassthruchar20,pos,1);
  else
    out_order_reference := out_order_reference || substr(oh.hdrpassthruchar20,pos,1);
  end if;
  pos := pos + 1;
end loop;

<< return_reference >>

return out_order_reference;

exception when others then
  return null;
end order_reference;

function shipment_identifier
(in_orderid IN number
,in_shipid IN number
) return varchar2 is

str_orderid varchar2(9);
str_shipid varchar2(2);
out_shipment_identifier varchar2(11);

begin

out_shipment_identifier := null;

str_orderid := to_char(in_orderid);
while length(rtrim(str_orderid)) < 9
loop
  str_orderid := '0' || rtrim(str_orderid);
end loop;
str_shipid := to_char(in_shipid);
while length(rtrim(str_shipid)) < 2
loop
  str_shipid := '0' || rtrim(str_shipid);
end loop;

out_shipment_identifier := str_orderid || str_shipid;

return out_shipment_identifier;

exception when others then
  return null;
end shipment_identifier;

FUNCTION tradingpartnerid_to_custid
(in_sip_tradingpartnerid IN varchar2
) return varchar2 is

cursor curCustTradingPartner(in_sip_tradingpartnerid varchar2) is
  select custid
    from customer
   where sip_tradingpartnerid = in_sip_tradingpartnerid;

out_custid customer.custid%type;

begin

out_custid := null;

open curCustTradingPartner(in_sip_tradingpartnerid);
fetch curCustTradingPartner into out_custid;
close curCustTradingPartner;

return out_custid;

exception when others then
  return null;
end tradingpartnerid_to_custid;

function sip_consignee_tradingpartnerid
(in_custid IN varchar2
,in_consignee IN varchar2
) return varchar2 is

cursor curConsigneeTradingPartner is
  select sip_tradingpartnerid
    from custconsignee
   where custid = in_custid
     and consignee = in_consignee;

out_tradingpartnerid custconsignee.sip_tradingpartnerid%type;

begin

out_tradingpartnerid := null;

open curConsigneeTradingPartner;
fetch curConsigneeTradingPartner into out_tradingpartnerid;
close curConsigneeTradingPartner;

return out_tradingpartnerid;

exception when others then
  return null;
end sip_consignee_tradingpartnerid;

function sip_consignee_match
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
) return varchar2 is

cursor curCustomer is
  select custid,
         nvl(sipconsigneematchfield,'SHIPTONAME') sipfield,
         nvl(sipconsigneematchlength,20) siplength
    from customer
   where custid = in_custid;

CUS curCustomer%rowtype;


cursor curCustConsigneeSipName is
  select N.consignee
    from orderhdr O, custconsigneesipnameview N
   where N.custid = in_custid
     and O.orderid = in_orderid
     and O.shipid = in_shipid
     and (rtrim(N.sipname) = rtrim(substr(upper(
            decode(CUS.sipfield,
                    'SHIPTONAME', O.shiptoname,
                    'HDRPASSTHRUCHAR01', O.hdrpassthruchar01,
                    'HDRPASSTHRUCHAR02', O.hdrpassthruchar02,
                    'HDRPASSTHRUCHAR03', O.hdrpassthruchar03,
                    'HDRPASSTHRUCHAR04', O.hdrpassthruchar04,
                    'HDRPASSTHRUCHAR05', O.hdrpassthruchar05,
                    'HDRPASSTHRUCHAR06', O.hdrpassthruchar06,
                    'HDRPASSTHRUCHAR07', O.hdrpassthruchar07,
                    'HDRPASSTHRUCHAR08', O.hdrpassthruchar08,
                    'HDRPASSTHRUCHAR09', O.hdrpassthruchar09,
                    'HDRPASSTHRUCHAR10', O.hdrpassthruchar10,
                    'HDRPASSTHRUCHAR11', O.hdrpassthruchar11,
                    'HDRPASSTHRUCHAR12', O.hdrpassthruchar12,
                    'HDRPASSTHRUCHAR13', O.hdrpassthruchar13,
                    'HDRPASSTHRUCHAR14', O.hdrpassthruchar14,
                    'HDRPASSTHRUCHAR15', O.hdrpassthruchar15,
                    'HDRPASSTHRUCHAR16', O.hdrpassthruchar16,
                    'HDRPASSTHRUCHAR17', O.hdrpassthruchar17,
                    'HDRPASSTHRUCHAR18', O.hdrpassthruchar18,
                    'HDRPASSTHRUCHAR19', O.hdrpassthruchar19,
                    'HDRPASSTHRUCHAR20', O.hdrpassthruchar20,
                    'HDRPASSTHRUCHAR21', O.hdrpassthruchar21,
                    'HDRPASSTHRUCHAR22', O.hdrpassthruchar22,
                    'HDRPASSTHRUCHAR23', O.hdrpassthruchar23,
                    'HDRPASSTHRUCHAR24', O.hdrpassthruchar24,
                    'HDRPASSTHRUCHAR25', O.hdrpassthruchar25,
                    'HDRPASSTHRUCHAR26', O.hdrpassthruchar26,
                    'HDRPASSTHRUCHAR27', O.hdrpassthruchar27,
                    'HDRPASSTHRUCHAR28', O.hdrpassthruchar28,
                    'HDRPASSTHRUCHAR29', O.hdrpassthruchar29,
                    'HDRPASSTHRUCHAR30', O.hdrpassthruchar30,
                    'HDRPASSTHRUCHAR31', O.hdrpassthruchar31,
                    'HDRPASSTHRUCHAR32', O.hdrpassthruchar32,
                    'HDRPASSTHRUCHAR33', O.hdrpassthruchar33,
                    'HDRPASSTHRUCHAR34', O.hdrpassthruchar34,
                    'HDRPASSTHRUCHAR35', O.hdrpassthruchar35,
                    'HDRPASSTHRUCHAR36', O.hdrpassthruchar36,
                    'HDRPASSTHRUCHAR37', O.hdrpassthruchar37,
                    'HDRPASSTHRUCHAR38', O.hdrpassthruchar38,
                    'HDRPASSTHRUCHAR39', O.hdrpassthruchar39,
                    'HDRPASSTHRUCHAR40', O.hdrpassthruchar40,
                    'HDRPASSTHRUCHAR41', O.hdrpassthruchar41,
                    'HDRPASSTHRUCHAR42', O.hdrpassthruchar42,
                    'HDRPASSTHRUCHAR43', O.hdrpassthruchar43,
                    'HDRPASSTHRUCHAR44', O.hdrpassthruchar44,
                    'HDRPASSTHRUCHAR45', O.hdrpassthruchar45,
                    'HDRPASSTHRUCHAR46', O.hdrpassthruchar46,
                    'HDRPASSTHRUCHAR47', O.hdrpassthruchar47,
                    'HDRPASSTHRUCHAR48', O.hdrpassthruchar48,
                    'HDRPASSTHRUCHAR49', O.hdrpassthruchar49,
                    'HDRPASSTHRUCHAR50', O.hdrpassthruchar50,
                    'HDRPASSTHRUCHAR51', O.hdrpassthruchar51,
                    'HDRPASSTHRUCHAR52', O.hdrpassthruchar52,
                    'HDRPASSTHRUCHAR53', O.hdrpassthruchar53,
                    'HDRPASSTHRUCHAR54', O.hdrpassthruchar54,
                    'HDRPASSTHRUCHAR55', O.hdrpassthruchar55,
                    'HDRPASSTHRUCHAR56',
                                         O.hdrpassthruchar56,
                    'HDRPASSTHRUCHAR57', O.hdrpassthruchar57,
                    'HDRPASSTHRUCHAR58', O.hdrpassthruchar58,
                    'HDRPASSTHRUCHAR59', O.hdrpassthruchar59,
                    'HDRPASSTHRUCHAR60', O.hdrpassthruchar60,
                                         O.shiptoname
                )),
                            1,CUS.siplength))
        or
          N.sipname =
            decode(CUS.sipfield,
                    'HDRPASSTHRUNUM01', to_char(O.hdrpassthrunum01),
                    'HDRPASSTHRUNUM02', to_char(O.hdrpassthrunum02),
                    'HDRPASSTHRUNUM03', to_char(O.hdrpassthrunum03),
                    'HDRPASSTHRUNUM04', to_char(O.hdrpassthrunum04),
                    'HDRPASSTHRUNUM05', to_char(O.hdrpassthrunum05),
                    'HDRPASSTHRUNUM06', to_char(O.hdrpassthrunum06),
                    'HDRPASSTHRUNUM07', to_char(O.hdrpassthrunum07),
                    'HDRPASSTHRUNUM08', to_char(O.hdrpassthrunum08),
                    'HDRPASSTHRUNUM09', to_char(O.hdrpassthrunum09),
                    'HDRPASSTHRUNUM10', to_char(O.hdrpassthrunum10),
                            'xxxx'));


out_consignee consignee.consignee%type;

begin

out_consignee := null;


CUS := null;
OPEN curCustomer;
FETCH curCustomer into CUS;
CLOSE curCustomer;

if CUS.custid is null then
    return null;
end if;


open curCustConsigneeSipName;
fetch curCustConsigneeSipName into out_consignee;
close curCustConsigneeSipName;

return out_consignee;

exception when others then
  return null;
end sip_consignee_match;

procedure import_order_header_sip_wso_ho
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_record_type IN varchar2
,in_po IN varchar2
,in_order_status IN varchar2
,in_tran_type IN varchar2
,in_action_code IN varchar2
,in_link_sequence IN number          --hdrpassthrunum01
,in_master_link_number IN varchar2   --hdrpassthruchar09
,in_payment_method IN varchar2       --map shipterms
,in_trans_method IN varchar2         --map shiptype
,in_pallet_exchange IN varchar2
,in_unit_load_option IN varchar2
,in_carrier_routing IN varchar2     --hdrpassthruchar17
,in_fob_location_qualifier IN varchar2
,in_fob_location_descr IN varchar2
,in_cod_method IN varchar2           --map cod
,in_amount IN number
,in_carrier IN varchar2
,in_flex_field1 IN varchar2
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,in_flex_field6 IN varchar2
,in_flex_field7 IN varchar2
,in_flex_field8 IN varchar2
,in_importfileid IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is


cursor curOrderHdr(in_custid varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select C.custid, nvl(resubmitorder,'N') as resubmitorder,
         sip_default_fromfacility,
        unique_order_identifier
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cntRows integer;
tp customer%rowtype;

procedure delete_old_order(in_orderid number, in_shipid number) is
begin
  delete from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
end;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  if nvl(cs.unique_order_identifier,'R') = 'P' then
    out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference)
        ||' PO. '||rtrim(in_po)|| ': ' || out_msg;
  else
    out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference)
        || ': ' || out_msg;
  end if;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr(tp.custid);
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if rtrim(in_func) = 'D' then -- cancel function
  if out_orderid = 0 then
    out_errorno := 3;
    out_msg := 'Order to be cancelled not found';
    order_msg('E');
    return;
  end if;
end if;

open curCustomer(tp.custid);
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.resubmitorder := 'N';
  cs.sip_default_fromfacility := null;
end if;
close curCustomer;
if rtrim(in_func) = 'A' then
  if out_orderid != 0 then
    if (cs.resubmitorder = 'N') or
       (oh.orderstatus != 'X') then
      out_msg := 'Add request rejected--order already on file';
      order_msg('W');
      return;
    else
      delete_old_order(out_orderid,out_shipid);
      out_msg := 'Resubmit of rejected order';
      order_msg('I');
    end if;
  end if;
end if;

if rtrim(in_func) = 'U' then
  if out_orderid = 0 then
    out_msg := 'Update requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status for update: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
  end if;
end if;

if rtrim(in_func) = 'R' then
  if out_orderid = 0 then
    out_msg := 'Replace requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status for replace: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
    delete_old_order(out_orderid,out_shipid);
    out_msg := 'Order replace transaction processed';
    order_msg('I');
  end if;
end if;

if out_orderid = 0 then
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
end if;

if rtrim(in_func) in ('A','R') then
  insert into orderhdr
  (orderid,shipid,fromfacility,
   custid,ordertype,
   reference,po,
   priority,orderstatus,commitstatus,
   shipterms,shiptype,
   cod,amtcod,
   carrier,source,
   hdrpassthrunum01,
   hdrpassthruchar09,
   hdrpassthruchar17,
   hdrpassthruchar01,hdrpassthruchar02,
   hdrpassthruchar03,hdrpassthruchar04,
   hdrpassthruchar05,hdrpassthruchar06,
   hdrpassthruchar07,hdrpassthruchar08,
   hdrpassthruchar18,
   entrydate,importfileid,
   lastuser,lastupdate
   )
  values
  (out_orderid,out_shipid,cs.sip_default_fromfacility,
   nvl(rtrim(tp.custid),' '),'O',
   rtrim(in_reference),rtrim(in_po),
   'A','0','0',
   rtrim(in_payment_method),rtrim(in_trans_method),
   rtrim(in_cod_method),decode(in_amount,0,null,in_amount),
   rtrim(in_carrier),'EDI',
   decode(in_link_sequence,0,null,in_link_sequence),
   rtrim(in_master_link_number),
   rtrim(in_carrier_routing),
   rtrim(in_flex_field1),rtrim(in_flex_field2),
   rtrim(in_flex_field3),rtrim(in_flex_field4),
   rtrim(in_flex_field5),rtrim(in_flex_field6),
   rtrim(in_flex_field7),rtrim(in_flex_field8),
   rtrim(in_carrier),
   sysdate,upper(rtrim(in_importfileid)),
   'SIPIMP',sysdate
  );
elsif rtrim(in_func) = 'U' then
  update orderhdr
     set orderstatus = '0',
         commitstatus = '0',
         po = nvl(rtrim(in_po),po),
         fromfacility=nvl(cs.sip_default_fromfacility,fromfacility),
         shipterms = nvl(rtrim(in_payment_method),shipterms),
         shiptype = nvl(rtrim(in_trans_method),shiptype),
         cod = nvl(rtrim(in_cod_method),cod),
         amtcod = nvl(decode(in_amount,0,null,in_amount),amtcod),
         carrier = nvl(rtrim(in_carrier),carrier),
         hdrpassthrunum01 = nvl(decode(in_link_sequence,0,null,in_link_sequence),hdrpassthrunum01),
         hdrpassthruchar09 = nvl(rtrim(in_master_link_number),hdrpassthruchar09),
         hdrpassthruchar17 = nvl(rtrim(in_carrier_routing),deliveryservice),
         hdrpassthruchar01 = nvl(rtrim(in_flex_field1),hdrpassthruchar01),
         hdrpassthruchar02 = nvl(rtrim(in_flex_field2),hdrpassthruchar02),
         hdrpassthruchar03 = nvl(rtrim(in_flex_field3),hdrpassthruchar03),
         hdrpassthruchar04 = nvl(rtrim(in_flex_field4),hdrpassthruchar04),
         hdrpassthruchar05 = nvl(rtrim(in_flex_field5),hdrpassthruchar05),
         hdrpassthruchar06 = nvl(rtrim(in_flex_field6),hdrpassthruchar06),
         hdrpassthruchar07 = nvl(rtrim(in_flex_field7),hdrpassthruchar07),
         hdrpassthruchar08 = nvl(rtrim(in_flex_field8),hdrpassthruchar08),
         hdrpassthruchar18 = nvl(rtrim(in_carrier),hdrpassthruchar18),
         lastuser = 'SIPIMP',
         lastupdate = sysdate,
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid)
   where orderid = out_orderid
     and shipid = out_shipid;
elsif rtrim(in_func) = 'D' then
   zoe.cancel_order_request(out_orderid, out_shipid, oh.fromfacility,
       'EDI','SIPIMP', out_msg);
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'sipho ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header_sip_wso_ho;

PROCEDURE get_sipfileseq
(in_custid IN varchar2
,out_sipfileseq OUT varchar2
) is

curSeq integer;
cntRows integer;
cmdSql varchar2(20000);
dbseq integer;
begin

cntRows := 0;
begin
  select count(1)
    into cntRows
    from user_sequences
   where sequence_name = 'SIPFILESEQ_' || 'ALL';
exception when others then
  cntRows := 0;
end;
if cntRows = 0 then
  cmdSql := 'create sequence SIPFILESEQ_' || 'ALL' ||
    ' increment by 1 ' ||
    'start with 1 maxvalue 999999 minvalue 1 nocache cycle ';
  curSeq := dbms_sql.open_cursor;
  dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSeq);
  dbms_sql.close_cursor(curSeq);
end if;
cmdSql := 'select SIPFILESEQ_' || 'ALL' ||
  '.nextval from dual';
curSeq := dbms_sql.open_cursor;
dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSeq,1,dbseq);
cntRows := dbms_sql.execute(curSeq);
cntRows := dbms_sql.fetch_rows(curSeq);
if cntRows <= 0 then
  out_sipfileseq := 0;
else
  dbms_sql.column_value(curSeq,1,dbseq);
end if;
dbms_sql.close_cursor(curSeq);

out_sipfileseq := dbseq;
out_sipfileseq := rtrim(out_sipfileseq);
while length(out_sipfileseq) < 6
loop
  out_sipfileseq := '0' || out_sipfileseq;
end loop;

exception when others then
  out_sipfileseq := '000000';
end get_sipfileseq;

procedure import_sip_wso_rr
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qualifier IN varchar2
,in_data IN varchar2
,in_descr IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype,
         hdrpassthruchar19,
         hdrpassthruchar20
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

lenold integer;
lennew integer;
strNewData varchar2(255);
strOldData varchar2(255);

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

if in_qualifier = 'BM' then --bill of lading
  update orderhdr
     set billoflading = substr(rtrim(in_data),1,40),
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
  goto end_okay;
end if;

if in_qualifier = 'CN' then --pro number
  update orderhdr
     set prono = substr(rtrim(in_data),1,40),
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
  goto end_okay;
end if;

if in_qualifier = 'QY' then --delivery service code
  update orderhdr
     set deliveryservice = substr(rtrim(in_data),1,4),
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
  goto end_okay;
end if;

if rtrim(in_qualifier) is null then
  out_errorno := 3;
  out_msg := 'No value given for reference qualifier';
  order_msg('E');
  return;
end if;

if rtrim(in_data) is null then
  out_errorno := 4;
  out_msg := 'No value given for reference qualifier ' ||
    in_qualifier;
  order_msg('E');
  return;
end if;

if rtrim(oh.hdrpassthruchar19) is null then
  lenold := 0;
  strOldData := null;
else
  lenold := length(rtrim(oh.hdrpassthruchar19));
  strOldData := rtrim(oh.hdrpassthruchar19);
end if;

strNewData := '|' || rtrim(in_qualifier) || '|' || rtrim(in_data);
lennew := length(rtrim(strNewData));
if lenold + lennew > 255 then
  goto try_passthru20;
end if;

if rtrim(strOldData) is null then
  strOldData := strNewData;
else
  strOldData := strOldData || strNewData;
end if;
oh.hdrpassthruchar19 := strOldData;
goto update_orderhdr;

<< try_passthru20 >>

if rtrim(oh.hdrpassthruchar20) is null then
  lenold := 0;
  strOldData := null;
else
  lenold := length(rtrim(oh.hdrpassthruchar20));
  strOldData := rtrim(oh.hdrpassthruchar20);
end if;

if lenold + lennew > 255 then
  out_errorno := 5;
  out_msg := 'Cannot load qualifier ' ||  rtrim(in_qualifier) || ' ' ||
    rtrim(in_data);
  order_msg('E');
  return;
end if;

if rtrim(strOldData) is null then
  strOldData := strNewData;
else
  strOldData := strOldData || strNewData;
end if;
oh.hdrpassthruchar20 := strOldData;

<< update_orderhdr >>

update orderhdr
   set hdrpassthruchar19 = oh.hdrpassthruchar19,
       hdrpassthruchar20 = oh.hdrpassthruchar20,
       lastuser = 'SIPIMP',
       lastupdate = sysdate
 where orderid = out_orderid
   and shipid = out_shipid;

<< end_okay >>

out_msg := 'OKAY';

exception when others then
  out_msg := 'siprr ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_rr;

procedure import_sip_wso_dr
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qualifier IN varchar2
,in_date IN date
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;
dteDBDate date;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

begin
  if trunc(in_date) = to_date('12/30/1899','mm/dd/yyyy') then
    dteDBDate := null;
  else
    dteDBDate := in_date;
  end if;
exception when others then
  dteDBDate := null;
end;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

if in_qualifier = '02' then  --requested delivery
  update orderhdr
     set delivery_requested = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '17' then  --estimated delivery
  update orderhdr
     set do_not_deliver_before = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '10' then  --ship or pickup date
  update orderhdr
     set shipdate = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '38' then  --ship no later
  update orderhdr
     set ship_no_later = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '04' then  --po date
  update orderhdr
     set apptdate = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '52' then  --orderered date
  update orderhdr
     set entrydate = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif in_qualifier = '07' then  --effective date
  update orderhdr
     set do_not_deliver_after = dteDBdate,
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
else
  out_errorno := 3;
  out_msg := 'Invalid WSO DR Qualifier: '  || in_qualifier;
  order_msg('E');
  return;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'sipdr ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_dr;

procedure import_sip_wso_ha
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_address_type IN varchar2
,in_location_code IN varchar2    --hdrpassthruchar13
,in_location_number IN varchar2  --hdrpassthruchar11
,in_address_name IN varchar2     --hdrpassthruchar12
,in_address_alternate_name IN varchar2
,in_address1 IN varchar2
,in_address2 IN varchar2
,in_address3 IN varchar2
,in_address4 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode IN varchar2
,in_country IN varchar2
,in_contact IN varchar2
,in_contact_phone IN varchar2
,in_contact_fax IN varchar2
,in_contact_email IN varchar2
,in_tax_id IN varchar2
,in_tax_exempt IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

if in_address_type = 'ST' then
  update orderhdr
     set shiptoname = rtrim(in_address_name),
         shiptoaddr1 = rtrim(in_address1),
         shiptoaddr2 = rtrim(in_address2),
         shiptocity = rtrim(in_city),
         shiptostate = rtrim(in_state),
         shiptopostalcode = rtrim(in_postalcode),
         shiptocountrycode = rtrim(in_country),
         shiptocontact = rtrim(in_contact),
         shiptophone = rtrim(in_contact_phone),
         shiptofax = rtrim(in_contact_fax),
         shiptoemail = rtrim(in_contact_email),
         hdrpassthruchar11 = rtrim(in_location_number),
         hdrpassthruchar12 = rtrim(upper(in_address_name)),
         hdrpassthruchar13 = rtrim(in_location_code),
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
end if;

if in_address_type = 'SF' then
  if in_location_code = '93' then
    update orderhdr
       set fromfacility = substr(upper(rtrim(in_location_number)),1,3),
           lastuser = 'SIMIMP',
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid;
  else
    update orderhdr
       set hdrpassthruchar14 = in_location_code,
           hdrpassthruchar16 = in_location_number
     where orderid = out_orderid
       and shipid = out_shipid;
  end if;
end if;

if in_address_type not in ('DE','BY','ST','SF','WH','RD','CN','EB','SA') then
  out_errorno := 3;
  out_msg := 'Invalid WSO HA Address Type: '  || in_address_type;
  order_msg('E');
  return;
end if;

if in_address_type = 'ST' then --shipto validation
  if sip_consignee_match(tp.custid,out_orderid, out_shipid) = null then
    out_msg := 'Cannot find SIP Consignee.';
    order_msg('E');
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'sipha ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_ha;

procedure import_sip_wso_hn -- header note
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_sequence_number IN number
,in_note1 IN varchar2
,in_note2 IN varchar2
,in_note3 IN varchar2
,in_note4 IN varchar2
,in_note5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype,
         comment1
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curOrderHdrBolComments(in_orderid number, in_shipid number) is
  select orderid,shipid,bolcomment
    from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
bol curOrderHdrBolComments%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

if rtrim(in_note1) is not null then
  if rtrim(in_note2) in ('ALL','WHI','DEL','INT','TRA') then
    if rtrim(oh.comment1) is not null then
      oh.comment1 := rtrim(oh.comment1) || CHR(13) || rtrim(in_note1);
    else
      oh.comment1 := rtrim(in_note1);
    end if;
    update orderhdr
       set comment1 = oh.comment1,
           lastuser = 'SIPIMP',
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid;
  end if;
  if rtrim(in_note2) in ('ALL','BOL') then
    bol := null;
    open curOrderHdrBolComments(out_orderid,out_shipid);
    fetch curOrderHdrBolComments into bol;
    close curOrderHdrBolComments;
    if bol.orderid is null then
      insert into orderhdrbolcomments
      (orderid,shipid,bolcomment,lastuser,lastupdate)
      values
      (out_orderid,out_shipid,rtrim(in_note1),'SIPIMP',sysdate);
    else
      bol.bolcomment := rtrim(bol.bolcomment) || CHR(13) || rtrim(in_note1);
      update orderhdrbolcomments
         set bolcomment = bol.bolcomment,
             lastuser = 'SIMIMP',
             lastupdate = sysdate
       where orderid = out_orderid
         and shipid = out_shipid;
    end if;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'siphn ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_hn;

procedure import_sip_wso_li -- line item
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_line_number IN number
,in_part1_qualifier IN varchar2
,in_part1_item IN varchar2
,in_part2_qualifier IN varchar2
,in_part2_item IN varchar2
,in_part3_qualifier IN varchar2
,in_part3_item IN varchar2
,in_part4_qualifier IN varchar2
,in_part4_item IN varchar2
,in_part_desc1 IN varchar2
,in_part_desc2 IN varchar2
,in_qty_entered IN number
,in_uom_entered IN varchar2
,in_pack IN number
,in_size IN number
,in_uom IN varchar2
,in_weight IN number
,in_weight_qualifier IN varchar2
,in_weight_uom IN varchar2
,in_unit_weight IN number
,in_volume IN number
,in_volume_uom IN varchar2
,in_color IN varchar2
,in_amt1_qualifier in varchar2
,in_amt1 IN number
,in_credit_debit_flag1 IN varchar2
,in_amt2_qualifier in varchar2
,in_amt2 IN number
,in_credit_debit_flag2 IN varchar2
,in_flex_field1 IN varchar2
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;
chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
strConsigneeSku orderdtl.consigneesku%type;
strItemEntered custitem.item%type;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = rtrim(tp.custid);
cs curCustomer%rowtype;

cursor curOrderDtl is
  select linestatus,
         itementered,
         item,
         qtyentered,
         qtyorder,
         lotnumber,
         dtlpassthruchar01,
         dtlpassthruchar02,
         dtlpassthruchar03,
         dtlpassthruchar04,
         dtlpassthruchar05,
         dtlpassthruchar06,
         dtlpassthruchar07,
         dtlpassthruchar08,
         dtlpassthruchar09,
         dtlpassthruchar10,
         dtlpassthruchar11,
         dtlpassthruchar12,
         dtlpassthruchar13,
         dtlpassthruchar14,
         dtlpassthruchar15,
         dtlpassthruchar16,
         dtlpassthruchar17,
         dtlpassthruchar18,
         dtlpassthruchar19,
         dtlpassthruchar20,
         dtlpassthrunum01,
         dtlpassthrunum02,
         dtlpassthrunum03,
         dtlpassthrunum04,
         dtlpassthrunum05,
         dtlpassthrunum06,
         dtlpassthrunum07,
         dtlpassthrunum08,
         dtlpassthrunum09,
         dtlpassthrunum10
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(strItemEntered)
     and nvl(lotnumber,'(none)') = '(none)';
od curOrderDtl%rowtype;

cursor curOrderDtlLineCount(in_item varchar2) is
  select count(1) as count
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = '(none)'
     and nvl(xdock,'N') = 'N';
olc curOrderDtlLineCount%rowtype;

cursor curOrderDtlLine(in_linenumber number) is
  select item,
         lotnumber,
         qty
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and linenumber = in_linenumber;
ol curOrderDtlLine%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom
    from custitemview
   where custid = rtrim(tp.custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
end if;
close curCustomer;

strItemEntered := null;
if rtrim(in_part1_qualifier) = 'VN' then
  strItemEntered := in_part1_item;
elsif rtrim(in_part2_qualifier) = 'VN' then
  strItemEntered := in_part2_item;
elsif rtrim(in_part3_qualifier) = 'VN' then
  strItemEntered := in_part3_item;
elsif rtrim(in_part4_qualifier) = 'VN' then
  strItemEntered := in_part4_item;
end if;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%found then
  chk.item := od.item;
  chk.lotnumber := od.lotnumber;
else
  chk.item := null;
  chk.lotnumber := null;
end if;
close curOrderDtl;

strConsigneeSku := null;
if rtrim(in_part1_qualifier) = 'CB' then
  strConsigneeSku := in_part1_item;
elsif rtrim(in_part2_qualifier) = 'CB' then
  strConsigneeSku := in_part2_item;
elsif rtrim(in_part3_qualifier) = 'CB' then
  strConsigneeSku := in_part3_item;
elsif rtrim(in_part4_qualifier) = 'CB' then
  strConsigneeSku := in_part4_item;
end if;

if rtrim(in_func) = 'D' then -- cancel function
  if chk.item is null then
    out_errorno := 3;
    out_msg := 'Order-line to be cancelled not found';
    order_msg('E');
    return;
  end if;
  if od.linestatus = 'X' then
    out_errorno := 4;
    out_msg := 'Order-line already cancelled';
    order_msg('E');
    return;
  end if;
end if;

zci.get_customer_item(rtrim(tp.custid),rtrim(strItemEntered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_part1_item;
end if;

olc.count := 0;

if cs.linenumbersyn = 'Y' then
  if nvl(in_line_number,0) <= 0 then
    out_errorno := 5;
    out_msg := 'Invalid Line Number: ' || in_line_number;
    order_msg('E');
    return;
  end if;
  open curOrderDtlLineCount(strItem);
  fetch curOrderDtlLineCount into olc;
  if curOrderDtlLineCount%notfound then
    olc.count := 0;
  end if;
  close curOrderDtlLineCount;
  chk.linenumber := null;
  if olc.count != 0 then
    open curOrderDtlLine(in_line_number);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      if (ol.item != strItem) or
         (nvl(ol.lotnumber,'(none)') != '(none)') then
        out_errorno := 6;
        out_msg := 'Line Number Mismatch: ' || in_line_number;
        order_msg('E');
        return;
      else
        chk.linenumber := in_line_number;
      end if;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = in_line_number then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is not null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is not null) ) then
    out_msg := 'Add requested--order-line already on file--update performed';
    order_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is null) ) then
    out_msg := 'Update requested--order-line not on file--add performed';
    order_msg('W');
    in_func := 'A';
  end if;
end if;

ci := null;
open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
end if;
close curCustItem;
if oh.ordertype in ('R','Q','P','A','C','T','U') then
  ci.invstatus := null;
  ci.inventoryclass := null;
end if;

zoe.get_base_uom_equivalent(rtrim(tp.custid),rtrim(stritem),
  nvl(rtrim(in_uom_entered),ci.baseuom),
  in_qty_entered,strItem,strUOMBase,qtyBase,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_part1_item);
  strUOMBase :=  nvl(rtrim(in_uom_entered),ci.baseuom);
  qtyBase := in_qty_entered;
end if;

if rtrim(in_func) in ('A','R') then
  if chk.item is null then
    insert into orderdtl
    (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
    qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
    consigneesku,statususer,
    backorder,allowsub,
    invstatusind,invstatus,
    invclassind,inventoryclass,qtytype,
    dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04, dtlpassthruchar05,
    dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08, dtlpassthruchar09, dtlpassthruchar10,
    dtlpassthrunum10
    )
    values
    (out_orderid,out_shipid,nvl(strItem,' '),null,strUOMBase,'A',
     in_qty_entered,rtrim(strItemEntered),nvl(rtrim(in_uom_entered),ci.baseuom),
     qtyBase,
     zci.item_weight(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
     zci.item_cube(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
     qtyBase*ci.useramt1,'SIPIMP',sysdate,
     strConsigneeSku,'SIPIMP',
     ci.backorder,ci.allowsub,
     ci.invstatusind,ci.invstatus,
     ci.invclassind,ci.inventoryclass,ci.qtytype,
     rtrim(in_part1_qualifier),rtrim(in_part1_item),
     rtrim(in_part2_qualifier),rtrim(in_part2_item),
     rtrim(in_part3_qualifier),rtrim(in_part3_item),
     rtrim(in_part4_qualifier),rtrim(in_part4_item),
     rtrim(in_part_desc1),rtrim(in_part_desc2),
     decode(in_line_number,0,null,in_line_number)
     );
	 
     -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
     -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
     update orderdtl
     set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = nvl(strItem,' ')
       and lotnumber is null;
  else
    if olc.count = 0 then --add line record for item info that is already on file
      insert into orderdtlline
       (orderid,shipid,item,lotnumber,
        linenumber,qty,
        dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04, dtlpassthruchar05,
        dtlpassthrunum10, lastuser, lastupdate
       )
       values
       (out_orderid,out_shipid,nvl(strItem,' '),null,
        od.dtlpassthrunum10,od.qtyorder,
        od.dtlpassthruchar01, od.dtlpassthruchar02, od.dtlpassthruchar03, od.dtlpassthruchar04,
        od.dtlpassthruchar05, od.dtlpassthrunum10, 'SIPIMP', sysdate
       );
    end if;
    insert into orderdtlline
     (orderid,shipid,item,lotnumber,
      linenumber,qty,
      dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
      dtlpassthruchar05, dtlpassthrunum10, lastuser, lastupdate
     )
     values
     (out_orderid,out_shipid,nvl(strItem,' '),null,
      in_line_number,qtyBase,
      decode(nvl(od.dtlpassthruchar01,'x'),nvl(rtrim(in_flex_field1),'x'),
        od.dtlpassthruchar01,nvl(rtrim(in_flex_field1),' ')),
      decode(nvl(od.dtlpassthruchar02,'x'),nvl(rtrim(in_flex_field2),'x'),
        od.dtlpassthruchar02,nvl(rtrim(in_flex_field2),' ')),
      decode(nvl(od.dtlpassthruchar03,'x'),nvl(rtrim(in_flex_field3),'x'),
        od.dtlpassthruchar03,nvl(rtrim(in_flex_field3),' ')),
      decode(nvl(od.dtlpassthruchar04,'x'),nvl(rtrim(in_flex_field4),'x'),
        od.dtlpassthruchar04,nvl(rtrim(in_flex_field4),' ')),
      decode(nvl(od.dtlpassthruchar05,'x'),nvl(rtrim(in_flex_field5),'x'),
        od.dtlpassthruchar05,nvl(rtrim(in_flex_field5),' ')),
      decode(nvl(od.dtlpassthrunum10,0),nvl(in_line_number,0),
        od.dtlpassthrunum10,nvl(in_line_number,0)),
      'SIPIMP', sysdate
     );
    update orderdtl
       set qtyentered = qtyentered + in_qty_entered,
           qtyorder = qtyorder + qtyBase,
           weightorder = weightorder
             + zci.item_weight(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
           cubeorder = cubeorder
             + zci.item_cube(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
           amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = 'SIPIMP',
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = '(none)';
  end if;
elsif rtrim(in_func) = 'U' then
  if (olc.count != 0) and
     (chk.linenumber is not null) then
    update orderdtlline
       set qty = qtyBase,
           lastuser = 'SIPIMP',
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = '(none)'
       and linenumber = chk.linenumber;
    update orderdtl
       set qtyentered = qtyentered + in_qty_entered - ol.qty,
           qtyorder = qtyorder + qtyBase - ol.qty,
           weightorder = weightorder
             + (zci.item_weight(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered)
             - (zci.item_weight(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * ol.qty),
           cubeorder = cubeorder
             + (zci.item_cube(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered)
             - (zci.item_cube(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * ol.qty),
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber),
           lastuser = 'SIPIMP',
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = '(none)';
  else
    update orderdtl
       set uomentered = nvl(rtrim(in_uom_entered),ci.baseuom),
           qtyentered = in_qty_entered,
           uom = strUOMBase,
           qtyorder = qtyBase,
           weightorder = zci.item_weight(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
           cubeorder = zci.item_cube(rtrim(tp.custid),strItem,nvl(rtrim(in_uom_entered),ci.baseuom)) * in_qty_entered,
           amtorder = qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber),
           consigneesku = nvl(strConsigneeSku,consigneesku),
           lastuser = 'SIPIMP',
           lastupdate = sysdate,
           dtlpassthruchar01 = nvl(rtrim(in_flex_field1),dtlpassthruchar01),
           dtlpassthruchar02 = nvl(rtrim(in_flex_field2),dtlpassthruchar02),
           dtlpassthruchar03 = nvl(rtrim(in_flex_field3),dtlpassthruchar03),
           dtlpassthruchar04 = nvl(rtrim(in_flex_field4),dtlpassthruchar04),
           dtlpassthruchar05 = nvl(rtrim(in_flex_field5),dtlpassthruchar05),
           dtlpassthrunum10 = nvl(decode(in_line_number,0,null,in_line_number),dtlpassthrunum10)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = '(none)';
  end if;
elsif rtrim(in_func) = 'D' then -- delete function (do a cancel)
  update orderdtl
     set linestatus = 'X',
         lastuser = 'SIPIMP',
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = '(none)';
  delete from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = '(none)'
     and nvl(xdock,'N') = 'N';
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'sipli ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_li;

procedure import_sip_wso_st --  summary total
(in_func IN OUT varchar2
,in_sip_tradingpartnerid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_record_type IN varchar2
,in_qty_entered IN number
,in_weight IN number
,in_uom IN varchar2
,in_volume_unit_basis IN number
,in_volume IN varchar2
,in_order_sizing_factor IN number
,in_flex_field1 IN varchar2
,in_flex_field2 IN varchar2
,in_flex_field3 IN varchar2
,in_flex_field4 IN varchar2
,in_flex_field5 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

tp customer%rowtype;

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype,
         comment1
    from orderhdr
   where custid = rtrim(tp.custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(tp.custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(tp.custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg('SIPIMP', '', rtrim(tp.custid),
    out_msg, nvl(in_msgtype,'E'), 'SIPIMP', strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
tp := null;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

tp.custid := TradingPartnerID_to_CustId(in_sip_tradingpartnerid);
if tp.custid is null then
  out_msg := 'Cannot locate customer for SIP Trading Partner ' ||
    in_sip_tradingpartnerid;
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  order_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  order_msg('E');
  return;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'sipst ' || sqlerrm;
  out_errorno := sqlcode;
end import_sip_wso_st;

procedure begin_sip_WSA_945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and ordertype in ('O')
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and loadno = in_loadno
   order by orderid,shipid;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30);
sp curShippingPlate%rowtype;

cursor curShippingPlateLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         lotnumber,
         max(fromlpid) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            lotnumber;
spl curShippingPlateLot%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curCustomer is
  select custid,sip_wsa_945_summarize_lots_yn,
         sip_tradingpartnerid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curRRData(in_orderid number, in_shipid number) is
  select nvl(ld.prono,oh.prono) as prono,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         oh.carrier as oh_carrier,
         hdrpassthruchar18 as orig_carrier,
         hdrpassthruchar19,
         hdrpassthruchar20
    from loads ld, orderhdr oh
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno(+);
rr curRRData%rowtype;

cursor curFacility (in_facility varchar2) is
  select *
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

cursor curFreightCharges (in_orderid number, in_shipid number) is
  select sum(cost) as cost
    from multishipdtl
   where orderid = in_orderid
     and shipid = in_shipid;
fc curFreightCharges%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
strShipment_Identifier varchar2(11);
strUcc128 varchar2(20);
strShipment_Status varchar2(2);
strCaseUpc varchar2(255);
cntView integer;
dteTest date;
hc sip_wsa_945_hc%rowtype;
/*
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strshipParm orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
*/
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
qtyShipped shippingplate.quantity%type;
weightshipped orderdtl.weightship%type;
prm licenseplatestatus%rowtype;
strDebug char(1);
dteExpirationDate date;

procedure debugmsg(in_msg varchar2) is
begin
  if nvl(strDebug,'N') != 'Y' then
    return;
  end if;
  zut.prt(in_msg);
end;

procedure add_945_st_row(oh orderhdr%rowtype) is
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_st_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':QTYSHIP,:WEIGHTSHIP,:WEIGHTUOM,:CUBESHIP,:CUBEUOM)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':QTYSHIP', oh.QTYSHIP);
  dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', oh.WEIGHTSHIP);
  dbms_sql.bind_variable(curSql, ':WEIGHTUOM', 'LB');
  dbms_sql.bind_variable(curSql, ':CUBESHIP', oh.CUBESHIP);
  dbms_sql.bind_variable(curSql, ':CUBEUOM', 'CF');
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_945_ha_row(oh orderhdr%rowtype) is
begin
  debugmsg('begin add_945_ha_row-st');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_ha_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
    ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'ST');
  dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', nvl(oh.hdrpassthruchar13,'92'));
  dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar11);
  dbms_sql.bind_variable(curSql, ':NAME', oh.shiptoNAME);
  dbms_sql.bind_variable(curSql, ':ADDR1', oh.shiptoADDR1);
  dbms_sql.bind_variable(curSql, ':ADDR2', oh.shiptoADDR2);
  dbms_sql.bind_variable(curSql, ':CITY', oh.shiptoCITY);
  dbms_sql.bind_variable(curSql, ':STATE', oh.shiptoSTATE);
  dbms_sql.bind_variable(curSql, ':POSTALCODE', oh.shiptoPOSTALCODE);
  dbms_sql.bind_variable(curSql, ':COUNTRYCODE', oh.shiptoCOUNTRYCODE);
  dbms_sql.bind_variable(curSql, ':CONTACT', oh.shiptoCONTACT);
  dbms_sql.bind_variable(curSql, ':PHONE', oh.shiptoPHONE);
  dbms_sql.bind_variable(curSql, ':FAX', oh.shiptoFAX);
  dbms_sql.bind_variable(curSql, ':EMAIL', oh.shiptoEMAIL);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
  debugmsg('end add_945_ha_row-st');
  debugmsg('begin add_945_ha_row-sf');
  fa := null;
  open curFacility(oh.fromfacility);
  fetch curFacility into fa;
  close curFacility;
  debugmsg('begin add_945_ha_row-sf');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_ha_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
    ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SF');
  dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', 'ZZ');
  dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.fromfacility);
  dbms_sql.bind_variable(curSql, ':NAME', fa.NAME);
  dbms_sql.bind_variable(curSql, ':ADDR1', fa.ADDR1);
  dbms_sql.bind_variable(curSql, ':ADDR2', fa.ADDR2);
  dbms_sql.bind_variable(curSql, ':CITY', fa.CITY);
  dbms_sql.bind_variable(curSql, ':STATE', fa.STATE);
  dbms_sql.bind_variable(curSql, ':POSTALCODE', fa.POSTALCODE);
  dbms_sql.bind_variable(curSql, ':COUNTRYCODE', fa.COUNTRYCODE);
  dbms_sql.bind_variable(curSql, ':CONTACT', fa.manager);
  dbms_sql.bind_variable(curSql, ':PHONE', fa.PHONE);
  dbms_sql.bind_variable(curSql, ':FAX', fa.FAX);
  dbms_sql.bind_variable(curSql, ':EMAIL', fa.EMAIL);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
  debugmsg('end add_945_ha_row-sf');
  if rtrim(oh.hdrpassthruchar14) is not null then
    debugmsg('begin add_945_ha_row-sf2');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_wsa_945_ha_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
      ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SF');
    dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', oh.hdrpassthruchar14);
    dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar16);
    dbms_sql.bind_variable(curSql, ':NAME', fa.NAME);
    dbms_sql.bind_variable(curSql, ':ADDR1', fa.ADDR1);
    dbms_sql.bind_variable(curSql, ':ADDR2', fa.ADDR2);
    dbms_sql.bind_variable(curSql, ':CITY', fa.CITY);
    dbms_sql.bind_variable(curSql, ':STATE', fa.STATE);
    dbms_sql.bind_variable(curSql, ':POSTALCODE', fa.POSTALCODE);
    dbms_sql.bind_variable(curSql, ':COUNTRYCODE', fa.COUNTRYCODE);
    dbms_sql.bind_variable(curSql, ':CONTACT', fa.manager);
    dbms_sql.bind_variable(curSql, ':PHONE', fa.PHONE);
    dbms_sql.bind_variable(curSql, ':FAX', fa.FAX);
    dbms_sql.bind_variable(curSql, ':EMAIL', fa.EMAIL);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('end add_945_ha_row-sf2');
  end if;
end;

procedure add_945_hd_row(oh orderhdr%rowtype) is
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_hd_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':SHIPTYPE,:CARRIER,:CARRIER_ROUTING,:SHIPTERMS,:OH_CARRIER,:ORIG_CARRIER)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':SHIPTYPE', oh.shiptype);
  dbms_sql.bind_variable(curSql, ':CARRIER', rr.carrier);
  dbms_sql.bind_variable(curSql, ':CARRIER_ROUTING', oh.deliveryservice);
  dbms_sql.bind_variable(curSql, ':SHIPTERMS', oh.shipterms);
  dbms_sql.bind_variable(curSql, ':OH_CARRIER', rr.oh_carrier);
  dbms_sql.bind_variable(curSql, ':ORIG_CARRIER', rr.orig_carrier);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_945_hc_row(oh orderhdr%rowtype) is
begin
  if (nvl(oh.loadno,0) != 0) and
     (nvl(oh.hdrpassthrunum02,0) != 0) then
    debugmsg('add ltl freight cost');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_wsa_945_hc_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':ALLOWCHRGTYPE,:ALLOWCHRGAMT)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ALLOWCHRGTYPE', '504');
    dbms_sql.bind_variable(curSql, ':ALLOWCHRGAMT', oh.hdrpassthrunum02);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
  end if;
  debugmsg('check for small package charge');
  fc := null;
  open curFreightCharges(oh.orderid,oh.shipid);
  fetch curFreightCharges into fc;
  close curFreightCharges;
  if nvl(fc.cost,0) != 0 then
    debugmsg('add small package freight');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_wsa_945_hc_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':ALLOWCHRGTYPE,:ALLOWCHRGAMT)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ALLOWCHRGTYPE', '04');
    dbms_sql.bind_variable(curSql, ':ALLOWCHRGAMT', fc.cost);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
  end if;
end;

procedure add_945_dr_data(oh orderhdr%rowtype, in_date_qualifier varchar2,
                      in_date_value date) is
begin
  if in_date_value is null then
    return;
  end if;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_dr_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':DATE_QUALIFIER,:DATE_VALUE)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':DATE_QUALIFIER', in_date_qualifier);
  dbms_sql.bind_variable(curSql, ':DATE_VALUE', in_date_value);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_945_dr_rows(oh orderhdr%rowtype) is
begin
  add_945_dr_data(oh, '02', nvl(oh.delivery_requested,trunc(sysdate)+4));
  add_945_dr_data(oh, '17', oh.do_not_deliver_before);
  add_945_dr_data(oh, '10', oh.shipdate);
  add_945_dr_data(oh, '38', oh.ship_no_later);
  add_945_dr_data(oh, '04', oh.apptdate);
  add_945_dr_data(oh, '52', oh.entrydate);
  add_945_dr_data(oh, '07', oh.do_not_deliver_after);
end;

procedure add_945_rr_data(oh orderhdr%rowtype, in_reference_qualifier varchar2,
                      in_reference_id varchar2) is
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_wsa_945_rr_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':REFERENCE_QUALIFIER,:REFERENCE_ID,:REFERENCE_DESCR)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', in_reference_qualifier);
  dbms_sql.bind_variable(curSql, ':REFERENCE_ID', in_reference_id);
  dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_945_rr_rows(oh orderhdr%rowtype) is
pos integer;
ix integer;
len integer;
begin_separator_found boolean;
end_separator_found boolean;
strQualifier varchar2(10);
strValue varchar2(255);
strMaxTrackingNo shippingplate.trackingno%type;

begin
  strMaxTrackingNo := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
  rr := null;
  open curRRData(oh.orderid,oh.shipid);
  fetch curRRdata into rr;
  close curRRdata;
  if rr.prono is not null then
    add_945_rr_data(oh, 'CN', rr.prono);
  elsif strMaxTrackingNo is not null then
    add_945_rr_data(oh, 'CN', strMaxTrackingNo);
  end if;
  if rr.billoflading is not null then
    add_945_rr_data(oh, 'BM', rr.billoflading);
  else
    if strMaxTrackingNo is not null then
      add_945_rr_data(oh, 'BM', strMaxTrackingNo);
    else
      add_945_rr_data(oh, 'BM', strShipment_Identifier);
    end if;
  end if;
  len := length(rtrim(rr.hdrpassthruchar19));
  ix := 1;
  begin_separator_found := false;
  end_separator_found := false;
  strQualifier := null;
  strValue := null;
  while (ix <= len)
  loop
    if substr(rr.hdrpassthruchar19,ix,1) = '|' then
      if end_separator_found then
        if rtrim(strValue) is not null then
          if length(rtrim(strQualifier)) <= 3 then
            add_945_rr_data(oh, strQualifier, strValue);
          end if;
        end if;
        strQualifier := null;
        strValue := null;
        end_separator_found := false;
        begin_separator_found := true;
        goto continue19_loop;
      end if;
      if begin_separator_found then
        end_separator_found := true;
      else
        begin_separator_found := true;
      end if;
      goto continue19_loop;
    end if;
    if end_separator_found then
      if strValue is null then
        strValue := substr(rr.hdrpassthruchar19,ix,1);
      else
        strValue := strValue || substr(rr.hdrpassthruchar19,ix,1);
      end if;
    elsif begin_separator_found then
      if strQualifier is null then
        strQualifier := substr(rr.hdrpassthruchar19,ix,1);
      else
        strQualifier := strQualifier || substr(rr.hdrpassthruchar19,ix,1);
      end if;
    end if;
  << continue19_loop >>
    ix := ix + 1;
  end loop;
  if rtrim(strQualifier) is not null and
     rtrim(strValue) is not null then
    if length(rtrim(strQualifier)) <= 3 then
      add_945_rr_data(oh, strQualifier, strValue);
    end if;
  end if;

  len := length(rtrim(rr.hdrpassthruchar20));
  ix := 1;
  begin_separator_found := false;
  end_separator_found := false;
  strQualifier := null;
  strValue := null;
  while (ix <= len)
  loop
    if substr(rr.hdrpassthruchar20,ix,1) = '|' then
      if end_separator_found then
        if rtrim(strValue) is not null then
          if length(rtrim(strQualifier)) <= 3 then
            add_945_rr_data(oh, strQualifier, strValue);
          end if;
        end if;
        strQualifier := null;
        strValue := null;
        end_separator_found := false;
        begin_separator_found := true;
        goto continue19_loop;
      end if;
      if begin_separator_found then
        end_separator_found := true;
      else
        begin_separator_found := true;
      end if;
      goto continue19_loop;
    end if;
    if end_separator_found then
      if strValue is null then
        strValue := substr(rr.hdrpassthruchar20,ix,1);
      else
        strValue := strValue || substr(rr.hdrpassthruchar20,ix,1);
      end if;
    elsif begin_separator_found then
      if strQualifier is null then
        strQualifier := substr(rr.hdrpassthruchar20,ix,1);
      else
        strQualifier := strQualifier || substr(rr.hdrpassthruchar20,ix,1);
      end if;
    end if;
  << continue19_loop >>
    ix := ix + 1;
  end loop;
  if rtrim(strQualifier) is not null and
     rtrim(strValue) is not null then
    if length(rtrim(strQualifier)) <= 3 then
      add_945_rr_data(oh, strQualifier, strValue);
    end if;
  end if;

  if rtrim(strMaxTrackingNo) is not null then
    add_945_rr_data(oh, '08', strMaxTrackingNo);
  end if;
end;

procedure add_945_dtl_rows_by_lot(oh orderhdr%rowtype) is
strWeight1Qualifier varchar2(1);
strWeight1UnitCode varchar2(1);
begin
  debugmsg('begin add_945_dtl_rows_by_lot');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    spl := null;
    open curShippingPlateLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateLot into spl;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      qtyRemain := ol.qty;
      if spl.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if spl.qty = 0 then
            fetch curShippingPlateLot into spl;
            if curShippingPlateLot%notfound then
              spl := null;
              exit;
            end if;
          end if;
          if spl.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := spl.qty;
          end if;

          if oh.shiptype = 'S' then
            strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'0',spl.parentlpid),1,20);
          else
            strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'1',spl.parentlpid),1,20);
          end if;

          dteExpirationDate := lip_expirationdate(spl.fromlpid);

          curSql := dbms_sql.open_cursor;
          dbms_sql.parse(curSql, 'insert into sip_WSA_945_ad_' || strSuffix ||
            ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
            ':ITEM,:LOTNUMBER,:EXPIRATIONDATE,:LINE_NUMBER,:QTYSHIP,:UCC128,:TRACKINGNO)',
            dbms_sql.native);
          dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
          dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
          dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
          dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
          dbms_sql.bind_variable(curSql, ':ITEM', od.item);
          dbms_sql.bind_variable(curSql, ':LOTNUMBER', spl.lotnumber);
          dbms_sql.bind_variable(curSql, ':EXPIRATIONDATE', dteExpirationDate);
          dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
          dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyLineNumber);
          dbms_sql.bind_variable(curSql, ':UCC128', strUcc128);
          dbms_sql.bind_variable(curSql, ':TRACKINGNO', spl.trackingno);
          cntRows := dbms_sql.execute(curSql);
          dbms_sql.close_cursor(curSql);
  /*
          if rtrim(spl.trackingno) is not null then
            curSql := dbms_sql.open_cursor;
            dbms_sql.parse(curSql, 'insert into sip_WSA_945_lr_' || strSuffix ||
              ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
              ':ITEM,:LOTNUMBER,:LINE_NUMBER,:REFERENCE_QUALIFIER,:REFERENCE_ID,' ||
              ':REFERENCE_DESCR,:UCC128)',
              dbms_sql.native);
            dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
            dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
            dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.SIP_TRADINGPARTNERID);
            dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
            dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
            dbms_sql.bind_variable(curSql, ':LOTNUMBER', spl.LOTNUMBER);
            dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
            dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', 'ZZ');
            dbms_sql.bind_variable(curSql, ':REFERENCE_ID', spl.trackingno);
            dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
            dbms_sql.bind_variable(curSql, ':UCC128', strUcc128);
            cntRows := dbms_sql.execute(curSql);
            dbms_sql.close_cursor(curSql);
          end if;
  */
          qtyRemain := qtyRemain - qtyLineNumber;
          spl.qty := spl.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      qtyShipped := ol.qty - qtyRemain;
      strShipment_Status := '';
      if od.linestatus = 'X' then
        strShipment_Status := 'IC';
      elsif qtyShipped = ol.qty then
        strShipment_Status := 'CC';
      elsif qtyShipped > ol.qty then
        strShipment_Status := 'CM';
      elsif od.backorder in ('X','N') then
        strShipment_Status := 'CL';
      else
        strShipment_Status := 'CP';
      end if;
      begin
        select upc
          into strCaseUpc
          from custitemupcview
         where custid = cu.custid
           and item = od.item;
      exception when others then
        strCaseUpc := '';
      end;
      if rtrim(strCaseUpc) is null then
        strCaseUpc := od.dtlpassthruchar06;
      end if;
      weightshipped := zci.item_weight(cu.custid,od.item,od.uom) * qtyShipped;

     if weightshipped is not null then
       strWeight1Qualifier := 'G';
        strWeight1UnitCode := 'L';
     else
       strWeight1Qualifier := '';
        strWeight1UnitCode := '';
      end if;

      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_WSA_945_li_' || strSuffix ||
        ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
        ':ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,:PART2_QUALIFIER,' ||
        ':PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,:PART4_QUALIFIER,:PART4_ITEM,'||
        ':PART_DESCR1,:PART_DESCR2,' ||
        ':SHIPMENT_STATUS,:QTYORDER,:QTYSHIP,:QTYDIFF,:UOMSHIP,:CASEUPC,:WEIGHTSHIP,' ||
        ':SHIPDATE,:WEIGHT1_QUALIFIER,:WEIGHT1_UNIT_CODE)',
         dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.LOTNUMBER);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.LINENUMBER);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', od.dtlpassthruchar01);
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.dtlpassthruchar02);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strSHIPMENT_STATUS);
      dbms_sql.bind_variable(curSql, ':QTYORDER', ol.QTY);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyShipped);
      dbms_sql.bind_variable(curSql, ':QTYDIFF', qtyRemain);
      dbms_sql.bind_variable(curSql, ':UOMSHIP', od.UOM);
      dbms_sql.bind_variable(curSql, ':CASEUPC', strCASEUPC);
      dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', weightshipped);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':WEIGHT1_QUALIFIER', strWeight1Qualifier);
      dbms_sql.bind_variable(curSql, ':WEIGHT1_UNIT_CODE', strWeight1UnitCode);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
    end loop; -- orderdtlline
    close curShippingPlateLot;
  end loop; -- orderdtl
end;

procedure add_945_dtl_rows_by_item(oh orderhdr%rowtype) is
strWeight1Qualifier varchar2(1);
strWeight1UnitCode varchar2(1);
begin
  debugmsg('begin add_945_dtl_rows_by_item');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('order dtl loop');
    sp := null;
    open curShippingPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlate into sp;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      debugmsg('order line loop');
      qtyRemain := ol.qty;
      if sp.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if sp.qty = 0 then
            debugmsg('get next shipping plate');
            fetch curShippingPlate into sp;
            if curShippingPlate%notfound then
              debugmsg('no more shipping plate');
              sp := null;
              exit;
            end if;
          end if;
          if sp.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := sp.qty;
          end if;
          debugmsg('get ucc128');

          if oh.shiptype = 'S' then
            strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'0',sp.parentlpid),1,20);
          else
            strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'1',sp.parentlpid),1,20);
          end if;

          dteExpirationDate := null;

          debugmsg('get insert ad');
          curSql := dbms_sql.open_cursor;
          dbms_sql.parse(curSql, 'insert into sip_WSA_945_ad_' || strSuffix ||
            ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
            ':ITEM,:LOTNUMBER,:EXPIRATIONDATE,:LINE_NUMBER,:QTYSHIP,:UCC128,:TRACKINGNO)',
            dbms_sql.native);
          dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
          dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
          dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
          dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
          dbms_sql.bind_variable(curSql, ':ITEM', od.item);
          dbms_sql.bind_variable(curSql, ':LOTNUMBER', '');
          dbms_sql.bind_variable(curSql, ':EXPIRATIONDATE', dteExpirationDate);
          dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
          dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyLineNumber);
          dbms_sql.bind_variable(curSql, ':UCC128', strUcc128);
          dbms_sql.bind_variable(curSql, ':TRACKINGNO', sp.trackingno);
          cntRows := dbms_sql.execute(curSql);
          dbms_sql.close_cursor(curSql);
  /*
          if rtrim(sp.trackingno) is not null then
            debugmsg('add lr for trackingno');
            curSql := dbms_sql.open_cursor;
            dbms_sql.parse(curSql, 'insert into sip_WSA_945_lr_' || strSuffix ||
              ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
              ':ITEM,:LOTNUMBER,:LINE_NUMBER,:REFERENCE_QUALIFIER,:REFERENCE_ID,' ||
              ':REFERENCE_DESCR,:UCC128)',
              dbms_sql.native);
            dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
            dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
            dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.SIP_TRADINGPARTNERID);
            dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
            dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
            dbms_sql.bind_variable(curSql, ':LOTNUMBER', '');
            dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
            dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', 'ZZ');
            dbms_sql.bind_variable(curSql, ':REFERENCE_ID', sp.trackingno);
            dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
            dbms_sql.bind_variable(curSql, ':UCC128', strUcc128);
            cntRows := dbms_sql.execute(curSql);
            dbms_sql.close_cursor(curSql);
            debugmsg('added lr');
          end if;
  */
          qtyRemain := qtyRemain - qtyLineNumber;
          sp.qty := sp.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      qtyShipped := ol.qty - qtyRemain;
      strShipment_Status := '';
      if od.linestatus = 'X' then
        strShipment_Status := 'IC';
      elsif qtyShipped = ol.qty then
        strShipment_Status := 'CC';
      elsif qtyShipped > ol.qty then
        strShipment_Status := 'CM';
      elsif od.backorder in ('X','N') then
        strShipment_Status := 'CL';
      else
        strShipment_Status := 'CP';
      end if;
      debugmsg('get upc');
      begin
        select upc
          into strCaseUpc
          from custitemupcview
         where custid = cu.custid
           and item = od.item;
      exception when others then
        debugmsg('upc exception');
        strCaseUpc := '';
      end;
      debugmsg('get weightshipped');
      weightshipped := zci.item_weight(cu.custid,od.item,od.uom) * qtyShipped;

      debugmsg('get weight codes');
      if weightshipped is not null then
        strWeight1Qualifier := 'G';
        strWeight1UnitCode := 'L';
      else
        strWeight1Qualifier := '';
        strWeight1UnitCode := '';
      end if;

      debugmsg('insert 945 li');
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_WSA_945_li_' || strSuffix ||
        ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
        ':ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,:PART2_QUALIFIER,' ||
        ':PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,:PART4_QUALIFIER,:PART4_ITEM,'||
        ':PART_DESCR1,:PART_DESCR2,' ||
        ':SHIPMENT_STATUS,:QTYORDER,:QTYSHIP,:QTYDIFF,:UOMSHIP,:CASEUPC,:WEIGHTSHIP,' ||
        ':SHIPDATE,:WEIGHT1_QUALIFIER,:WEIGHT1_UNIT_CODE)',
         dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.LOTNUMBER);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.LINENUMBER);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', od.dtlpassthruchar01);
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.dtlpassthruchar02);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strSHIPMENT_STATUS);
      dbms_sql.bind_variable(curSql, ':QTYORDER', ol.QTY);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyShipped);
      dbms_sql.bind_variable(curSql, ':QTYDIFF', qtyRemain);
      dbms_sql.bind_variable(curSql, ':UOMSHIP', od.UOM);
      dbms_sql.bind_variable(curSql, ':CASEUPC', strCASEUPC);
      dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', weightshipped);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':WEIGHT1_QUALIFIER', strWeight1Qualifier);
      dbms_sql.bind_variable(curSql, ':WEIGHT1_UNIT_CODE', strWeight1UnitCode);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      debugmsg('inserted li');
    end loop; -- orderdtlline
    close curShippingPlate;
  end loop; -- orderdtl
  debugmsg('end add_945_dtl_rows_by_item');
end;

procedure add_945_hdr_rows(oh orderhdr%rowtype) is
begin
  strShipment_Identifier :=
    substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,11);
  debugmsg('exec add_rr');
  add_945_rr_rows(oh);
  debugmsg('exec add_945_dr');
  add_945_dr_rows(oh);
  debugmsg('exec add_hd');
  add_945_hd_row(oh);
  debugmsg('exec add_ha');
  add_945_ha_row(oh);
  debugmsg('exec add_hc');
  add_945_hc_row(oh);
  if cu.sip_wsa_945_summarize_lots_yn = 'Y' then
    debugmsg('exec add_by_item');
    add_945_dtl_rows_by_item(oh);
  else
    debugmsg('exec add_by_lot');
    add_945_dtl_rows_by_lot(oh);
  end if;
  debugmsg('exec add_st');
  add_945_st_row(oh);
end;

begin

if out_errorno = -12345 then
  strDebug := 'Y';
else
  strDebug := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'SIP_WSA_945_RR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

cmdSql := 'create table SIP_WSA_945_RR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),reference_qualifier varchar2(3), ' ||
 ' reference_id varchar2(20), reference_descr varchar2(45) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_DR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),date_qualifier varchar2(3), ' ||
 ' date_value date ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_HD_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),shiptype varchar2(1), ' ||
 ' carrier varchar2(10), carrier_routing varchar2(255), shipterms varchar2(3), ' ||
 ' oh_carrier varchar2(10), orig_carrier varchar2(255) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_HC_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11), ' ||
 ' allowchrgtype char(4), allowchrgamt number(16,4) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_HA_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),address_type varchar2(2), ' ||
 ' location_qualifier char(2), location_number varchar2(255), name varchar2(40), ' ||
 ' addr1 varchar2(40), addr2 varchar2(40), city varchar2(30), ' ||
 ' state varchar2(5), postalcode varchar2(12), countrycode varchar2(3), ' ||
 ' contact varchar2(40), phone varchar2(25), fax varchar2(25), email varchar2(255) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_LI_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),item varchar2(50), lotnumber varchar2(30), ' ||
 ' line_number number(16,4), part1_qualifier varchar2(255), part1_item varchar2(255), ' ||
 ' part2_qualifier varchar2(255), part2_item varchar2(255), ' ||
 ' part3_qualifier varchar2(255), part3_item varchar2(255), ' ||
 ' part4_qualifier varchar2(255), part4_item varchar2(255), ' ||
 ' part_descr1 varchar2(255),part_descr2 varchar2(255), shipment_status char(2), ' ||
 ' qtyorder number(7), qtyship number(7),qtydiff number, uomship varchar2(4), ' ||
 ' caseupc varchar2(20), weightship number(17,8), shipdate date, ' ||
 ' weight1_qualifier varchar2(1), weight1_unit_code varchar2(1) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_AD_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),item varchar2(50), lotnumber varchar2(30), ' ||
 ' expirationdate date, line_number number(16,4), qtyship number(7), ' ||
 ' ucc128 varchar2(20), trackingno varchar2(30) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_LR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),item varchar2(50), lotnumber varchar2(30), ' ||
 ' line_number number(16,4), reference_qualifier varchar2(3), ' ||
 ' reference_id varchar2(20), reference_descr varchar2(45), ucc128 varchar2(20) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_WSA_945_ST_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),qtyship number(7), weightship number(17,8), ' ||
 ' weightuom char(2), cubeship number(10,4), cubeuom char(2) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('creating view');

cmdSql := 'create view sip_WSA_945_ho_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,po,statusupdate,reference,' ||
 ' shiptoname,shiptoaddr1,shiptoaddr2,shiptocity,shiptostate,' ||
 ' shiptopostalcode,shiptocountrycode,' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,orderstatus,qtyship,weightship, ' ||
 ' cubeship,carrier,shipto,trailer,seal,' ||
 ' sip_consignee,sip_tradingpartnerid,sip_shipment_identifier) ' ||
 ' as select distinct oh.custid,oh.loadno,oh.orderid,oh.shipid,oh.po,' ||
 ' oh.statusupdate,oh.reference,' ||
 ' decode(oh.shipto,null,oh.shiptoname,cn.name),' ||
 ' decode(oh.shipto,null,oh.shiptoaddr1,cn.addr1),' ||
 ' decode(oh.shipto,null,oh.shiptoaddr2,cn.addr2),' ||
 ' decode(oh.shipto,null,oh.shiptocity,cn.city),' ||
 ' decode(oh.shipto,null,oh.shiptostate,cn.state),' ||
 ' decode(oh.shipto,null,oh.shiptopostalcode,cn.postalcode),' ||
 ' decode(oh.shipto,null,oh.shiptocountrycode,cn.countrycode),' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,orderstatus,oh.qtyship,oh.weightship, ' ||
 ' oh.cubeship,nvl(ld.carrier,oh.carrier),oh.shipto,ld.trailer,ld.seal, ' ||
 ' zimsip.sip_consignee_match(oh.custid,oh.orderid,oh.shipid), ' ||
 ' cu.sip_tradingpartnerid, ' ||
 ' substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,11) ' ||
 '  from customer cu, consignee cn, loads ld, orderhdr oh, sip_wsa_945_li_' ||
 strSuffix || ' li ' ||
 ' where oh.orderid = li.orderid and ' ||
 ' oh.shipid = li.shipid and ' ||
 ' oh.loadno = ld.loadno(+) and ' ||
 ' oh.custid = cu.custid(+) and ' ||
 ' oh.shipto = cn.consignee(+)';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('view created checking orderid');
if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_945_hdr_rows(oh);
  end loop;
elsif in_loadno != 0 then
  for oh in curOrderHdrByLoad
  loop
    if oh.ordertype = 'O' then
      add_945_hdr_rows(oh);
    end if;
  end loop;
elsif rtrim(in_begdatestr) is not null then
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    if oh.ordertype = 'O' then
      add_945_hdr_rows(oh);
    end if;
  end loop;
end if;

debugmsg('reached okay');
out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbsipwsa945 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_sip_WSA_945;

procedure end_sip_WSA_945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view sip_wsa_945_ho_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_dr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_hd_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_hc_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_ha_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_li_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_ad_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_lr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_st_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_wsa_945_rr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zesip945wsa ' || sqlerrm;
  out_errorno := sqlcode;
end end_sip_WSA_945;

procedure begin_sip_asn_856
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_shipto IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_default_carton_uom IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curLoads(in_loadno number) is
  select billoflading,prono,trailer,carrier,seal,
         qtyorder,qtyship,statusupdate,weightship
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curCustConsignee(in_custid varchar2, in_shipto varchar2) is
  select custid,sip_tradingpartnerid
    from custconsignee
   where custid = in_custid
     and consignee = in_shipto;
cc curCustConsignee%rowtype;

cursor curParentPlates(in_orderid number,in_shipid number) is
  select *
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH'
     and parentlpid is null
   order by lpid;
sp ShippingPlate%rowtype;

cursor curShipTypeSum(in_orderid number,in_shipid number) is
  select type,
         count(1) as count
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH'
     and parentlpid is null
   group by type;

cursor curSumOrderDtlOLD(in_parentlpid varchar2,in_orderid number, in_shipid number) is
  select orderitem,
         orderlot,
         sum(quantity) as quantity
    from shippingplate
   where parentlpid = in_parentlpid
     and orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P')
   group by orderitem,orderlot
   order by orderitem,orderlot;

cursor curSumOrderDtl(in_parentlpid varchar2,in_orderid number, in_shipid number) is
  select orderitem,
         orderlot,
         sum(quantity) as quantity
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P')
    start with lpid = in_parentlpid
    connect by prior lpid = parentlpid
   group by orderitem,orderlot
   order by orderitem,orderlot;

cursor curShippingPlateDtl(in_parentlpid varchar2, in_orderid number, in_shipid number,
                           in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from shippingplate
   where parentlpid = in_parentlpid
     and orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'x') = nvl(in_orderlot,'x')
     and type in ('F','P')
     and serialnumber is not null;

cursor curOrderDtl(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curFacility (in_facility varchar2) is
  select *
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

cursor curCustItem(in_custid varchar2, in_item varchar2) is
  select *
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

type line_rcd is record (
  orderitem     orderdtl.item%type,
  orderlot      orderdtl.lotnumber%type,
  linenumber    orderdtl.dtlpassthrunum10%type,
  qtyapplied    orderdtl.qtyorder%type
);

type line_tbl is table of line_rcd
     index by binary_integer;

lines line_tbl;
linex integer;
linefound boolean;
curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
strShipTo consignee.consignee%type;
strShipment_Identifier varchar2(11);
strUcc128 varchar2(20);
strShipment_Status varchar2(2);
strCaseUpc varchar2(255);
cntView integer;
dteTest date;
dteNotice date;
/*
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
*/
qtyRemain shippingplate.quantity%type;
qtyToApply shippingplate.quantity%type;
qtyToSkip shippingplate.quantity%type;
qtyApplied shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
qtyShipped shippingplate.quantity%type;
weightshipped orderdtl.weightship%type;
prm licenseplatestatus%rowtype;
strDebug char(1);
dteExpirationDate date;
intPkgCount integer;
cntHOrows integer;
cntLIrows integer;
totqtyShipped shippingplate.quantity%type;
totweightshipped orderdtl.weightship%type;
strBillofLading orderhdr.billoflading%type;
strMaxTrackingNo shippingplate.trackingno%type;
strProNo orderhdr.prono%type;
strSipStatus sip_asn_856_ho.orderstatus%type;
strPacking_Code sip_asn_856_hs.packing_code%type;
strPack_Level_Type sip_asn_856_po.pack_level_type%type;
str_loadno varchar2(9);
numFirstOrderId orderhdr.orderid%type;
numFirstShipId orderhdr.shipid%type;
qty856 shippingplate.quantity%type;
cartons856 integer;
tcart   number;
strVendor varchar2(255);

procedure debugmsg(in_msg varchar2) is
begin
  if nvl(strDebug,'N') != 'Y' then
    return;
  end if;
  zut.prt(in_msg);
end;

procedure add_856_hs_row(oh orderhdr%rowtype) is
begin
  debugmsg('begin add_856_hs_row');

  strPacking_Code := 'PLT94';
  cntRows := 0;
  intPkgCount := 0;
  for ss in curShipTypeSum(oh.orderid,oh.shipid)
  loop
    cntRows := cntRows + 1;
    intPkgCount := intPkgCount + ss.count;
  end loop;

  dteNotice := sysdate;

  if oh.shiptype = 'S' then
    strPacking_Code := 'CTN25';
  else
    strPacking_Code := 'PLT94';
  end if;

  if nvl(ld.qtyorder,oh.qtyorder) <= nvl(ld.qtyship,nvl(oh.qtyship,0)) then
    strShipment_Status := 'CC';
  else
    strShipment_Status := 'PR';
  end if;

  strVendor := order_reference(oh.orderid,oh.shipid,'IA');

  strMaxTrackingNo := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
  strBillofLading := nvl(rtrim(ld.billoflading),oh.billoflading);
  if rtrim(strBillOfLading) is null then
    strBillOfLading := strMaxTrackingNo;
  end if;
  if rtrim(strBillofLading) is null then
      strBillOfLading :=
        substr(zimsip.shipment_identifier(numfirstorderid,numfirstshipid),1,11);
  end if;
  if rtrim(ld.prono) is null and
     rtrim(oh.prono) is null then
    strProNo := strMaxTrackingNo;
  else
    strProNo := nvl(ld.prono,oh.prono);
  end if;

if cntHOrows = 0 then
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_asn_856_hs_' || strSuffix ||
' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SHIPTO,:SIP_TRADINGPARTNERID,' ||
':SIP_SHIPMENT_IDENTIFIER,:SHIP_DATE,:SHIP_TIME,:VENDOR,:SHIP_NOTICE_DATE,' ||
':SHIP_NOTICE_TIME,:ASN_STRUCTURE_CODE,:STATUS_REASON_CODE,:PACKING_CODE,' ||
':LADING_QUANTITY,:GROSS_WEIGHT_QUALIFIER,:SHIPMENT_WEIGHT,:SHIPMENT_WEIGHT_UOM,' ||
':EQUIP_DESCR_CODE,:CARRIER_EQUIP_INITIAL,:CARRIER_EQUIP_NUMBER,:CARRIER_ALPHA_CODE,' ||
':CARRIER_TRANS_METHOD,:CARRIER_ROUTING,:ORDER_STATUS,:BILL_OF_LADING,' ||
':PRO_NUMBER,:SEAL_NUMBER,:FOB_PAY_CODE,:FOB_LOCATION_QUALIFIER,:FOB_LOCATION_DESCR,' ||
':FOB_TITLE_PASSAGE_CODE,:FOB_TITLE_PASSAGE_LOCATION,:APPT_NUMBER,' ||
':PICKUP_NUMBER,:REQ_PICKUP_DATE,:REQ_PICKUP_TIME,:FLEX_FIELD_1,:FLEX_FIELD_2,' ||
':FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5, :SCHED_SHIP_DATE, :SCHED_SHIP_TIME,' ||
':SCHED_DELIVERY_DATE, :SCHED_DELIVERY_TIME)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
  dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
  dbms_sql.bind_variable(curSql, ':SHIPTO', oh.SHIPTO);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER',strSHIPMENT_IDENTIFIER);
  dbms_sql.bind_variable(curSql, ':SHIP_DATE', nvl(ld.statusupdate,oh.statusupdate));
  dbms_sql.bind_variable(curSql, ':SHIP_TIME', nvl(ld.statusupdate,oh.statusupdate));
  dbms_sql.bind_variable(curSql, ':VENDOR', strVendor);
  dbms_sql.bind_variable(curSql, ':SHIP_NOTICE_DATE', dteNotice);
  dbms_sql.bind_variable(curSql, ':SHIP_NOTICE_TIME', dteNotice);
  dbms_sql.bind_variable(curSql, ':ASN_STRUCTURE_CODE', '0001');
  dbms_sql.bind_variable(curSql, ':STATUS_REASON_CODE', '');
  dbms_sql.bind_variable(curSql, ':PACKING_CODE', strPacking_Code);
  dbms_sql.bind_variable(curSql, ':LADING_QUANTITY', intPkgCount);
  dbms_sql.bind_variable(curSql, ':GROSS_WEIGHT_QUALIFIER', 'G');
  dbms_sql.bind_variable(curSql, ':SHIPMENT_WEIGHT', nvl(ld.weightship,oh.weightship));
  dbms_sql.bind_variable(curSql, ':SHIPMENT_WEIGHT_UOM', 'LB');
  dbms_sql.bind_variable(curSql, ':EQUIP_DESCR_CODE', 'TL');
  dbms_sql.bind_variable(curSql, ':CARRIER_EQUIP_INITIAL', substr(ld.trailer,1,4));
  dbms_sql.bind_variable(curSql, ':CARRIER_EQUIP_NUMBER', substr(ld.trailer,1,10));
  dbms_sql.bind_variable(curSql, ':CARRIER_ALPHA_CODE', nvl(ld.carrier,oh.carrier));
  dbms_sql.bind_variable(curSql, ':CARRIER_TRANS_METHOD', oh.shiptype);
  dbms_sql.bind_variable(curSql, ':CARRIER_ROUTING', oh.deliveryservice);
  dbms_sql.bind_variable(curSql, ':ORDER_STATUS', strShipment_STATUS);
  dbms_sql.bind_variable(curSql, ':BILL_OF_LADING', strBillofLading);
  dbms_sql.bind_variable(curSql, ':PRO_NUMBER', strProNo);
  dbms_sql.bind_variable(curSql, ':SEAL_NUMBER', ld.seal);
  dbms_sql.bind_variable(curSql, ':FOB_PAY_CODE', oh.shipterms);
  dbms_sql.bind_variable(curSql, ':FOB_LOCATION_QUALIFIER', '');
  dbms_sql.bind_variable(curSql, ':FOB_LOCATION_DESCR', '');
  dbms_sql.bind_variable(curSql, ':FOB_TITLE_PASSAGE_CODE', '');
  dbms_sql.bind_variable(curSql, ':FOB_TITLE_PASSAGE_LOCATION', '');
  dbms_sql.bind_variable(curSql, ':APPT_NUMBER', '');
  dbms_sql.bind_variable(curSql, ':PICKUP_NUMBER', '');
  dbms_sql.bind_variable(curSql, ':REQ_PICKUP_DATE', oh.apptdate);
  dbms_sql.bind_variable(curSql, ':REQ_PICKUP_TIME', oh.apptdate);
  dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', oh.hdrpassthruchar01);
  dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', oh.hdrpassthruchar02);
  dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', oh.hdrpassthruchar03);
  dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', oh.hdrpassthruchar04);
  dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', oh.hdrpassthruchar05);
  dbms_sql.bind_variable(curSql, ':SCHED_SHIP_DATE', oh.shipdate);
  dbms_sql.bind_variable(curSql, ':SCHED_SHIP_TIME', oh.shipdate);
  dbms_sql.bind_variable(curSql, ':SCHED_DELIVERY_DATE',
    nvl(oh.delivery_requested,trunc(sysdate)+4));
  dbms_sql.bind_variable(curSql, ':SCHED_DELIVERY_TIME',
    nvl(oh.delivery_requested,trunc(sysdate)+4));
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end if;
debugmsg('end add_856_hs_row');
end;

procedure add_856_ha_row(oh orderhdr%rowtype) is
begin
  if cntHOrows = 0 then
    debugmsg('begin add_856_ha_row-st');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_asn_856_ha_' || strSuffix ||
  ' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
  ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
  ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
    dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'ST');
    dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', nvl(oh.hdrpassthruchar13,'92'));
    dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar11);
    dbms_sql.bind_variable(curSql, ':NAME', oh.shiptoNAME);
    dbms_sql.bind_variable(curSql, ':ADDR1', oh.shiptoADDR1);
    dbms_sql.bind_variable(curSql, ':ADDR2', oh.shiptoADDR2);
    dbms_sql.bind_variable(curSql, ':CITY', oh.shiptoCITY);
    dbms_sql.bind_variable(curSql, ':STATE', oh.shiptoSTATE);
    dbms_sql.bind_variable(curSql, ':POSTALCODE', oh.shiptoPOSTALCODE);
    dbms_sql.bind_variable(curSql, ':COUNTRYCODE', oh.shiptoCOUNTRYCODE);
    dbms_sql.bind_variable(curSql, ':CONTACT', oh.shiptoCONTACT);
    dbms_sql.bind_variable(curSql, ':PHONE', oh.shiptoPHONE);
    dbms_sql.bind_variable(curSql, ':FAX', oh.shiptoFAX);
    dbms_sql.bind_variable(curSql, ':EMAIL', oh.shiptoEMAIL);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('end add_856_ha_row-st');
    debugmsg('begin add_856_ha_row-sf');
    fa := null;
    open curFacility(oh.fromfacility);
    fetch curFacility into fa;
    close curFacility;
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_asn_856_ha_' || strSuffix ||
  ' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
  ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
  ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
    dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SF');
    dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', 'ZZ');
    dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.fromfacility);
    dbms_sql.bind_variable(curSql, ':NAME', fa.NAME);
    dbms_sql.bind_variable(curSql, ':ADDR1', fa.ADDR1);
    dbms_sql.bind_variable(curSql, ':ADDR2', fa.ADDR2);
    dbms_sql.bind_variable(curSql, ':CITY', fa.CITY);
    dbms_sql.bind_variable(curSql, ':STATE', fa.STATE);
    dbms_sql.bind_variable(curSql, ':POSTALCODE', fa.POSTALCODE);
    dbms_sql.bind_variable(curSql, ':COUNTRYCODE', fa.COUNTRYCODE);
    dbms_sql.bind_variable(curSql, ':CONTACT', fa.manager);
    dbms_sql.bind_variable(curSql, ':PHONE', fa.PHONE);
    dbms_sql.bind_variable(curSql, ':FAX', fa.FAX);
    dbms_sql.bind_variable(curSql, ':EMAIL', fa.EMAIL);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('end add_856_ha_row-sf');
    if rtrim(oh.hdrpassthruchar14) is not null then
      debugmsg('begin add_856_ha_row-sf2');
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_ha_' || strSuffix ||
    ' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
    ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
        dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
      dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.sip_tradingpartnerid);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
      dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SF');
      dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', oh.hdrpassthruchar14);
      dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar16);
      dbms_sql.bind_variable(curSql, ':NAME', fa.NAME);
      dbms_sql.bind_variable(curSql, ':ADDR1', fa.ADDR1);
      dbms_sql.bind_variable(curSql, ':ADDR2', fa.ADDR2);
      dbms_sql.bind_variable(curSql, ':CITY', fa.CITY);
      dbms_sql.bind_variable(curSql, ':STATE', fa.STATE);
      dbms_sql.bind_variable(curSql, ':POSTALCODE', fa.POSTALCODE);
      dbms_sql.bind_variable(curSql, ':COUNTRYCODE', fa.COUNTRYCODE);
      dbms_sql.bind_variable(curSql, ':CONTACT', fa.manager);
      dbms_sql.bind_variable(curSql, ':PHONE', fa.PHONE);
      dbms_sql.bind_variable(curSql, ':FAX', fa.FAX);
      dbms_sql.bind_variable(curSql, ':EMAIL', fa.EMAIL);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      debugmsg('end add_856_ha_row-sf2');
    end if;
  end if;
end;

procedure add_856_ho_row(oh orderhdr%rowtype) is
begin

  debugmsg('begin add_856_ho_row');

  strSipStatus := 'CC'; -- ship complete
  if oh.orderstatus = 'X' then
    strSipStatus := 'ID';
  elsif oh.qtyship < oh.qtyorder then
    strSipStatus := 'BP';
  end if;

  if oh.shiptype != 'S' then
        -- Determine Carton Count for the Order
      cartons856 := 0;
      for csp in (select S.custid, S.item, S.unitofmeasure,
                         nvl(I.sip_carton_uom,in_default_carton_uom)
                         sip_carton_uom, sum(S.quantity) quantity
                    from custitem I, shippingplate S, shippingplate M
                   where I.custid = S.custid
                     and I.item = S.item
                     and S.type in ('F','P')
                     and S.orderid = OH.orderid
                     and S.shipid = OH.shipid
                     and M.lpid(+) = S.parentlpid
                     and nvl(M.type,'X') != 'C'
                   group by S.custid, S.item, S.unitofmeasure, I.sip_carton_uom)
      loop
        debugmsg('Calc Cartons:'||csp.item||' Q:'||csp.quantity);
        tcart := zcu.equiv_uom_qty(csp.custid, csp.item,
                     csp.unitofmeasure, csp.quantity,
                     nvl(csp.sip_carton_uom,'CS'));
        if tcart < 0 then
            cartons856 := cartons856 + 1;
        end if;
        debugmsg('Calc Cartons:'||csp.item||' C:'||tcart);
        cartons856 := cartons856 + tcart;
      end loop;

    -- Determine Cartons
      for cc in (select lpid
                   from shippingplate
                  where orderid = OH.orderid
                    and shipid = OH.shipid
                    and type = 'C')
      loop
          tcart := 0;
          for csp in (select S.custid, S.item, S.unitofmeasure,
                             nvl(I.sip_carton_uom,in_default_carton_uom)
                             sip_carton_uom, sum(S.quantity) quantity
                        from custitem I, shippingplate S
                       where I.custid = S.custid
                         and I.item = S.item
                         and S.type in ('F','P')
                         and S.parentlpid = CC.lpid
                       group by S.custid, S.item, S.unitofmeasure, I.sip_carton_uom)
          loop
            debugmsg('Calc Cartons on:'||csp.item||' Q:'||csp.quantity);
            tcart := tcart + zcu.equiv_uom_qty(csp.custid, csp.item,
                         csp.unitofmeasure, csp.quantity,
                         nvl(csp.sip_carton_uom,'CS'));
            if tcart < 0 then
                exit;
            end if;
          end loop;

          if tcart < 1 then
            cartons856 := cartons856 + 1;
          else
            cartons856 := cartons856 + tcart;
          end if;
      end loop;
      debugmsg('Total Cartons:'||cartons856);
  end if;

  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_asn_856_ho_' || strSuffix ||
' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
':PO,:ENTRYDATE,:STATUSUPDATE,:REFERENCE,:ORDERSTATUS,:QTYSHIP,:WEIGHTSHIP,' ||
':CUBESHIP,:PKGCOUNT,:VENDOR,:PRONO,:PACKING_CODE,:APPTDATE)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
  dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
  dbms_sql.bind_variable(curSql, ':PO', oh.PO);
  dbms_sql.bind_variable(curSql, ':ENTRYDATE', oh.ENTRYDATE);
  dbms_sql.bind_variable(curSql, ':STATUSUPDATE', oh.STATUSUPDATE);
  dbms_sql.bind_variable(curSql, ':REFERENCE', oh.REFERENCE);
  dbms_sql.bind_variable(curSql, ':ORDERSTATUS', strSipStatus);
  dbms_sql.bind_variable(curSql, ':QTYSHIP', oh.qtyship);
  dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', oh.WEIGHTSHIP);
  dbms_sql.bind_variable(curSql, ':CUBESHIP', oh.CUBESHIP);
  if OH.shiptype = 'S' or in_default_carton_uom is null then
    dbms_sql.bind_variable(curSql, ':PKGCOUNT', intPKGCOUNT);
  else
    dbms_sql.bind_variable(curSql, ':PKGCOUNT', cartons856);
  end if;
  dbms_sql.bind_variable(curSql, ':VENDOR', strVendor);
  dbms_sql.bind_variable(curSql, ':PRONO', strProNo);
  dbms_sql.bind_variable(curSql, ':PACKING_CODE', strPacking_Code);
  dbms_sql.bind_variable(curSql, ':APPTDATE', oh.APPTDATE);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
  cntHOrows := cntHoRows + 1;
  totqtyshipped := totqtyshipped + oh.qtyship;
  totweightshipped := totweightshipped + oh.weightship;
  debugmsg('begin end_ho_row');
  if rtrim(oh.hdrpassthruchar11) is not null then
    debugmsg('begin end_oa_row');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_asn_856_oa_' || strSuffix ||
  ' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
  ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
  ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
    dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
    dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'BY');
    dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', 'ST');
    dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar11);
    dbms_sql.bind_variable(curSql, ':NAME', oh.shiptoNAME);
    dbms_sql.bind_variable(curSql, ':ADDR1', oh.shiptoADDR1);
    dbms_sql.bind_variable(curSql, ':ADDR2', oh.shiptoADDR2);
    dbms_sql.bind_variable(curSql, ':CITY', oh.shiptoCITY);
    dbms_sql.bind_variable(curSql, ':STATE', oh.shiptoSTATE);
    dbms_sql.bind_variable(curSql, ':POSTALCODE', oh.shiptoPOSTALCODE);
    dbms_sql.bind_variable(curSql, ':COUNTRYCODE', oh.shiptoCOUNTRYCODE);
    dbms_sql.bind_variable(curSql, ':CONTACT', oh.hdrpassthruchar12);
    dbms_sql.bind_variable(curSql, ':PHONE', oh.shiptoPHONE);
    dbms_sql.bind_variable(curSql, ':FAX', oh.shiptoFAX);
    dbms_sql.bind_variable(curSql, ':EMAIL', oh.shiptoEMAIL);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('begin end_oa_row');
  end if;
end;

procedure add_856_lk_row(oh orderhdr%rowtype,od curorderdtl%rowtype,
                     ol curorderdtlline%rowtype, sp ShippingPlate%rowtype) is
begin
debugmsg('begin add_856_lk_row');

dteExpirationDate := lip_expirationdate(sp.fromlpid);

curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, 'insert into sip_asn_856_lk_' || strSuffix ||
' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
':PART_DESCR2,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,:PRODUCT_COLOR_DESCR,' ||
':PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
':PRODUCT_PROCESS_DESC,:QTY_PER,:QTY_PER_UOM,:UNIT_PRICE,:UNIT_PRICE_BASIS,' ||
':SERIALNUMBER,:WARRANTY_DATE,:EFFECTIVE_DATE,:LOT_EXPIRATION_DATE)',
    dbms_sql.native);
dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curSql, ':LOTNUMBER', sp.LOTNUMBER);
dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', nvl(od.dtlpassthruchar01,'N'));
dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.itementered);
dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
dbms_sql.bind_variable(curSql, ':PRODUCT_SIZE', '');
dbms_sql.bind_variable(curSql, ':product_size_descr', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR_DESCR', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_CODE', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_DESCR', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_CODE', '');
dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_DESC', '');
dbms_sql.bind_variable(curSql, ':QTY_PER', 0);
dbms_sql.bind_variable(curSql, ':QTY_PER_UOM', 0);
dbms_sql.bind_variable(curSql, ':UNIT_PRICE', ci.useramt2);
dbms_sql.bind_variable(curSql, ':UNIT_PRICE_BASIS', 'RE');
dbms_sql.bind_variable(curSql, ':SERIALNUMBER', sp.SERIALNUMBER);
dbms_sql.bind_variable(curSql, ':WARRANTY_DATE', '');
dbms_sql.bind_variable(curSql, ':EFFECTIVE_DATE', '');
dbms_sql.bind_variable(curSql, ':LOT_EXPIRATION_DATE', dteExpirationDate);
debugmsg('end add_856_lk_row');
end;

procedure add_856_dl_row(oh orderhdr%rowtype,od curorderdtl%rowtype,
                     ol curorderdtlline%rowtype) is
begin
  debugmsg('begin add_856_dl_row');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_asn_856_dl_' || strSuffix ||
' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:CANCEL_AFTER,:DO_NOT_DELIVER_BEFORE,' ||
':DO_NOT_DELIVER_AFTER,:REQUESTED_DELIVERY,:REQUESTED_PICKUP,:REQUESTED_SHIP,' ||
':SHIP_NO_LATER,:SHIP_NOT_BEFORE,:PROMO_START,:PROMO_END,:ADDL_DATE1_QUALIFIER,' ||
':ADDL_DATE1,:ADDL_DATE2_QUALIFIER,:ADDL_DATE2,:ADDL_DATE3_QUALIFIER,' ||
':ADDL_DATE3)',
    dbms_sql.native);
dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.LOTNUMBER);
dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curSql, ':CANCEL_AFTER', oh.CANCEL_AFTER);
dbms_sql.bind_variable(curSql, ':DO_NOT_DELIVER_BEFORE', oh.DO_NOT_DELIVER_BEFORE);
dbms_sql.bind_variable(curSql, ':DO_NOT_DELIVER_AFTER', oh.DO_NOT_DELIVER_AFTER);
dbms_sql.bind_variable(curSql, ':REQUESTED_DELIVERY', nvl(oh.delivery_requested,trunc(sysdate)+4));
dbms_sql.bind_variable(curSql, ':REQUESTED_PICKUP', oh.shipdate);
dbms_sql.bind_variable(curSql, ':REQUESTED_SHIP', oh.SHIPdate);
dbms_sql.bind_variable(curSql, ':SHIP_NO_LATER', oh.SHIP_NO_LATER);
dbms_sql.bind_variable(curSql, ':SHIP_NOT_BEFORE', oh.SHIP_NOT_BEFORE);
dbms_sql.bind_variable(curSql, ':PROMO_START', '');
dbms_sql.bind_variable(curSql, ':PROMO_END', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE1_QUALIFIER', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE1', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE2_QUALIFIER', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE2', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE3_QUALIFIER', '');
dbms_sql.bind_variable(curSql, ':ADDL_DATE3', '');
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);
debugmsg('begin end_dl_row');
end;

procedure add_856_li_rows_old(oh orderhdr%rowtype, sp ShippingPlate%rowtype) is
begin
debugmsg('begin add_856_li_rows');
if sp.type in ('F','P') then
  debugmsg('Lip:'||sp.lpid||' Qty:'||sp.quantity);
  qtyRemain := sp.quantity;
  for od in curOrderDtl(oh.orderid,oh.shipid,sp.orderitem,sp.orderlot)
  loop
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,sp.orderitem,sp.orderlot)
    loop
      debugmsg('Line:'||ol.linenumber||' OL Qty:'||ol.qty||' QtyRemain:'||qtyremain);

      if qtyRemain <= 0 then
        exit;
      end if;
      qtyApplied := 0;
      linefound := false;
      for linex in 1..lines.count
      loop
        if lines(linex).orderitem = od.item and
           nvl(lines(linex).orderlot,'x') = nvl(od.lotnumber,'x') and
           lines(linex).linenumber = ol.linenumber then
          qtyApplied := lines(linex).qtyapplied;
          linefound := true;
          exit;
        end if;
      end loop;
      if linefound then
        debugmsg('Line Found QtyApplied:'||qtyApplied);

        ol.qty := ol.qty - qtyApplied;
        if ol.qty <= 0 then
          goto continue_line_loop;
        end if;
      end if;
      if qtyRemain >= ol.qty then
        qtyToApply := ol.qty;
      else
        qtyToApply := qtyRemain;
      end if;
      if linefound then
        lines(linex).qtyApplied := lines(linex).qtyApplied + qtyToApply;
      else
        debugmsg('Add Line:'||ol.linenumber||' QtyApplied:'||qtytoapply);
        linex := lines.count + 1;
        lines(linex).orderitem := od.item;
        lines(linex).orderlot := od.lotnumber;
        lines(linex).linenumber := ol.linenumber;
        lines(linex).qtyApplied := qtyToApply;
      end if;
      add_856_dl_row(oh,od,ol);
      ci := null;
      open curCustItem(oh.custid,od.item);
      fetch curCustItem into ci;
      close curCustItem;
      if od.linestatus = 'X' then
        strShipment_Status := 'ID';
      elsif nvl(od.qtyship,0) >= od.qtyorder then
        strShipment_Status := 'CC';
      elsif qtyToApply >= ol.qty then
        strShipment_Status := 'CC';
      else
        strShipment_Status := 'BP';
      end if;
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
      dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.lotnumber);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', nvl(od.dtlpassthruchar01,'N'));
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.itementered);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':QTYORDER', od.qtyorder);
      dbms_sql.bind_variable(curSql, ':QTYORDER_UOM', od.UOM);
      dbms_sql.bind_variable(curSql, ':PRICE', zci.item_amt(oh.custid, oh.orderid, oh.shipid, od.item, od.lotnumber));
      dbms_sql.bind_variable(curSql, ':PRICE_BASIS', '');
      dbms_sql.bind_variable(curSql, ':RETAIL_PRICE', ci.useramt2);
      dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':PACK_UOM', ci.baseuom);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT', 0);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT_UOM', 'LB');
      dbms_sql.bind_variable(curSql, ':PACK_CUBE', 0);
      dbms_sql.bind_variable(curSql, ':PACK_CUBE_UOM', 'CF');
      dbms_sql.bind_variable(curSql, ':PACK_LENGTH', ci.length);
      dbms_sql.bind_variable(curSql, ':PACK_WIDTH', ci.width);
      dbms_sql.bind_variable(curSql, ':PACK_HEIGHT', ci.height);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyToApply);
      dbms_sql.bind_variable(curSql, ':QTYSHIP_UOM', od.uom);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':QTYREMAIN', (nvl(od.qtyorder,0)-nvl(od.qtyship,0)));
      dbms_sql.bind_variable(curSql, ':ITEM_TOTAL', 0);
      dbms_sql.bind_variable(curSql, ':PRODUCT_SIZE', '');
      dbms_sql.bind_variable(curSql, ':product_size_descr', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_DESC', '');
      dbms_sql.bind_variable(curSql, ':DEPT', '');
      dbms_sql.bind_variable(curSql, ':CLASS', '');
      dbms_sql.bind_variable(curSql, ':GENDER', '');
      dbms_sql.bind_variable(curSql, ':SELLER_DATE_CODE', '');
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strShipment_Status);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', od.dtlpassthruchar11);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', od.dtlpassthruchar12);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', od.dtlpassthruchar13);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', od.dtlpassthruchar14);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', od.dtlpassthruchar15);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      cntLIRows := cntLiRows + 1;
      qtyRemain := qtyRemain - qtyToApply;
      if sp.serialnumber is not null then
        add_856_lk_row(oh,od,ol,sp);
      end if;
    << continue_line_loop >>
      null;
    end loop;
  end loop;
else
 for os in curSumOrderDtl(sp.lpid,oh.orderid,oh.shipid)
 loop
  qtytoSkip := 0;
  qtyRemain := os.quantity;
  for od in curOrderDtl(oh.orderid,oh.shipid,os.orderitem,os.orderlot)
  loop
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,os.orderitem,os.orderlot)
    loop
      if qtyRemain <= 0 then
        exit;
      end if;
      qtyApplied := 0;
      linefound := false;
      for linex in 1..lines.count
      loop
        if lines(linex).orderitem = od.item and
           nvl(lines(linex).orderlot,'x') = nvl(od.lotnumber,'x') and
           lines(linex).linenumber = ol.linenumber then
          qtyApplied := lines(linex).qtyapplied;
          linefound := true;
          exit;
        end if;
      end loop;
      if linefound then
        ol.qty := ol.qty - qtyApplied;
        if ol.qty <= 0 then
          goto continue_line_loop2;
        end if;
      end if;
      if qtyRemain >= ol.qty then
        qtyToApply := ol.qty;
      else
        qtyToApply := qtyRemain;
      end if;
      if linefound then
        lines(linex).qtyApplied := lines(linex).qtyApplied + qtyToApply;
      else
        linex := lines.count + 1;
        lines(linex).orderitem := od.item;
        lines(linex).orderlot := od.lotnumber;
        lines(linex).linenumber := ol.linenumber;
        lines(linex).qtyApplied := qtyToApply;
      end if;
      add_856_dl_row(oh,od,ol);
      ci := null;
      open curCustItem(oh.custid,od.item);
      fetch curCustItem into ci;
      close curCustItem;
      if od.linestatus = 'X' then
        strShipment_Status := 'ID';
      elsif nvl(od.qtyship,0) >= od.qtyorder then
        strShipment_Status := 'CC';
      elsif qtyToApply >= ol.qty then
        strShipment_Status := 'CC';
      else
        strShipment_Status := 'BP';
      end if;
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
      dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.lotnumber);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', od.dtlpassthruchar01);
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.dtlpassthruchar02);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':QTYORDER', od.qtyorder);
      dbms_sql.bind_variable(curSql, ':QTYORDER_UOM', od.UOM);
      dbms_sql.bind_variable(curSql, ':PRICE', zci.item_amt(oh.custid, oh.orderid, oh.shipid, od.item, od.lotnumber));
      dbms_sql.bind_variable(curSql, ':PRICE_BASIS', '');
      dbms_sql.bind_variable(curSql, ':RETAIL_PRICE', ci.useramt2);
      dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':PACK_UOM', ci.baseuom);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT', 0);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT_UOM', 'LB');
      dbms_sql.bind_variable(curSql, ':PACK_CUBE', 0);
      dbms_sql.bind_variable(curSql, ':PACK_CUBE_UOM', 'CF');
      dbms_sql.bind_variable(curSql, ':PACK_LENGTH', ci.length);
      dbms_sql.bind_variable(curSql, ':PACK_WIDTH', ci.width);
      dbms_sql.bind_variable(curSql, ':PACK_HEIGHT', ci.height);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyToApply);
      dbms_sql.bind_variable(curSql, ':QTYSHIP_UOM', od.uom);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':QTYREMAIN', (nvl(od.qtyorder,0)-nvl(od.qtyship,0)));
      dbms_sql.bind_variable(curSql, ':ITEM_TOTAL', 0);
      dbms_sql.bind_variable(curSql, ':PRODUCT_SIZE', '');
      dbms_sql.bind_variable(curSql, ':product_size_descr', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_DESC', '');
      dbms_sql.bind_variable(curSql, ':DEPT', '');
      dbms_sql.bind_variable(curSql, ':CLASS', '');
      dbms_sql.bind_variable(curSql, ':GENDER', '');
      dbms_sql.bind_variable(curSql, ':SELLER_DATE_CODE', '');
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strShipment_Status);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', od.dtlpassthruchar11);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', od.dtlpassthruchar12);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', od.dtlpassthruchar13);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', od.dtlpassthruchar14);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', od.dtlpassthruchar15);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      cntLiRows := cntLiRows + 1;
      qtyRemain := qtyRemain - qtyToApply;
      cntRows := 1;
      debugmsg('begin serial loop to master pallet');
      for sps in curShippingPlateDtl(sp.lpid,oh.orderid,oh.shipid,od.item,
                                     od.lotnumber)
      loop
        cntRows := cntRows + 1;
        if cntRows <= qtyToSkip then
          goto continue_serial_loop;
        end if;
        add_856_lk_row(oh,od,ol,sps);
        qtyToApply := qtyToApply - 1;
        if qtyToApply <= 0 then
          exit;
        end if;
      << continue_serial_loop >>
        null;
      end loop;
      qtyToSkip := qtyToSkip + qtyToApply;
    << continue_line_loop2 >>
      null;
    end loop;
  end loop;
 end loop;
end if;
debugmsg('end add_856_li_rows');
end;

procedure add_856_li_rows(oh orderhdr%rowtype, sp ShippingPlate%rowtype) is
begin
debugmsg('begin add_856_li_rows');
if sp.type in ('F','P') then
  qtyRemain := sp.quantity;
  for od in curOrderDtl(oh.orderid,oh.shipid,sp.orderitem,sp.orderlot)
  loop
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,sp.orderitem,sp.orderlot)
    loop
      if qtyRemain <= 0 then
        exit;
      end if;
      qtyApplied := 0;
      linefound := false;
      for linex in 1..lines.count
      loop
        if lines(linex).orderitem = od.item and
           nvl(lines(linex).orderlot,'x') = nvl(od.lotnumber,'x') and
           lines(linex).linenumber = ol.linenumber then
          qtyApplied := lines(linex).qtyapplied;
          linefound := true;
          exit;
        end if;
      end loop;
      if linefound then
        ol.qty := ol.qty - qtyApplied;
        if ol.qty <= 0 then
          goto continue_line_loop;
        end if;
      end if;
      if qtyRemain >= ol.qty then
        qtyToApply := ol.qty;
      else
        qtyToApply := qtyRemain;
      end if;
      if linefound then
        lines(linex).qtyApplied := lines(linex).qtyApplied + qtyToApply;
      else
        linex := lines.count + 1;
        lines(linex).orderitem := od.item;
        lines(linex).orderlot := od.lotnumber;
        lines(linex).linenumber := ol.linenumber;
        lines(linex).qtyApplied := qtyToApply;
      end if;
      add_856_dl_row(oh,od,ol);
      ci := null;
      open curCustItem(oh.custid,od.item);
      fetch curCustItem into ci;
      close curCustItem;
      if od.linestatus = 'X' then
        strShipment_Status := 'ID';
      elsif nvl(od.qtyship,0) >= od.qtyorder then
        strShipment_Status := 'CC';
      elsif qtyToApply >= ol.qty then
        strShipment_Status := 'CC';
      else
        strShipment_Status := 'BP';
      end if;
      if oh.shiptype = 'S' then
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);

      else

        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into sip_asn_856_po2_' || strSuffix ||
        ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
        ':PACK_LEVEL_TYPE,:OUTER_PACK,:INNER_PACK,:INNER_PACK_UOM,:QTYTOTAL,' ||
        ':WEIGHTTOTAL,:WEIGHT_UOM,:EMPTY_PACK_WEIGHT,:CUBETOTAL,:CUBEUOM,:LINEAR_UOM,' ||
        ':LENGTH,:WIDTH,:HEIGHT,:PKG_CHAR_CODE,:PKG_DESCR_CODE,:PKG_DESCR,' ||
        ':MARKS_QUALIFIER1,:MARKS_1,:MARKS_QUALIFIER2,:MARKS_2,:ADDL_DESCR_1,' ||
        ':ADDL_DESCR_2)',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
        dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
        dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
        dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
        dbms_sql.bind_variable(curSql, ':PACK_LEVEL_TYPE', 'P');
        dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
        dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
        dbms_sql.bind_variable(curSql, ':INNER_PACK_UOM', '');
        dbms_sql.bind_variable(curSql, ':QTYTOTAL', qtytoapply);
        dbms_sql.bind_variable(curSql, ':WEIGHTTOTAL',
            qtytoapply*zci.item_weight(oh.custid, od.item, od.uom));
        dbms_sql.bind_variable(curSql, ':WEIGHT_UOM', 'LB');
        dbms_sql.bind_variable(curSql, ':EMPTY_PACK_WEIGHT', 0);
        dbms_sql.bind_variable(curSql, ':CUBETOTAL', 0);
        dbms_sql.bind_variable(curSql, ':CUBEUOM', 'CF');
        dbms_sql.bind_variable(curSql, ':LINEAR_UOM', 'LF');
        dbms_sql.bind_variable(curSql, ':LENGTH', 0);
        dbms_sql.bind_variable(curSql, ':WIDTH', 0);
        dbms_sql.bind_variable(curSql, ':HEIGHT', 0);
        dbms_sql.bind_variable(curSql, ':PKG_CHAR_CODE', '6');
        dbms_sql.bind_variable(curSql, ':PKG_DESCR_CODE', '');
        dbms_sql.bind_variable(curSql, ':PKG_DESCR', '');
        dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER1', 'GM');
        dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
        dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER2', 'UC');
        dbms_sql.bind_variable(curSql, ':MARKS_2', od.dtlpassthruchar08);
        dbms_sql.bind_variable(curSql, ':ADDL_DESCR_1', '');
        dbms_sql.bind_variable(curSql, ':ADDL_DESCR_2', '');
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);


      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li2_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:MARKS_2,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);
      end if;


      dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
      dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
      if OH.shiptype != 'S' then
          dbms_sql.bind_variable(curSql, ':MARKS_2', od.dtlpassthruchar08);
      end if;
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.lotnumber);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', nvl(od.dtlpassthruchar01,'N'));
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.itementered);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':QTYORDER', od.qtyorder);
      dbms_sql.bind_variable(curSql, ':QTYORDER_UOM', od.UOM);
      dbms_sql.bind_variable(curSql, ':PRICE', zci.item_amt(oh.custid, oh.orderid, oh.shipid, od.item, od.lotnumber));
      dbms_sql.bind_variable(curSql, ':PRICE_BASIS', '');
      dbms_sql.bind_variable(curSql, ':RETAIL_PRICE', ci.useramt2);
      dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':PACK_UOM', ci.baseuom);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT', 0);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT_UOM', 'LB');
      dbms_sql.bind_variable(curSql, ':PACK_CUBE', 0);
      dbms_sql.bind_variable(curSql, ':PACK_CUBE_UOM', 'CF');
      dbms_sql.bind_variable(curSql, ':PACK_LENGTH', ci.length);
      dbms_sql.bind_variable(curSql, ':PACK_WIDTH', ci.width);
      dbms_sql.bind_variable(curSql, ':PACK_HEIGHT', ci.height);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyToApply);
      dbms_sql.bind_variable(curSql, ':QTYSHIP_UOM', od.uom);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':QTYREMAIN', (nvl(od.qtyorder,0)-nvl(od.qtyship,0)));
      dbms_sql.bind_variable(curSql, ':ITEM_TOTAL', 0);
      dbms_sql.bind_variable(curSql, ':PRODUCT_SIZE', '');
      dbms_sql.bind_variable(curSql, ':product_size_descr', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_DESC', '');
      dbms_sql.bind_variable(curSql, ':DEPT', '');
      dbms_sql.bind_variable(curSql, ':CLASS', '');
      dbms_sql.bind_variable(curSql, ':GENDER', '');
      dbms_sql.bind_variable(curSql, ':SELLER_DATE_CODE', '');
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strShipment_Status);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', od.dtlpassthruchar11);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', od.dtlpassthruchar12);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', od.dtlpassthruchar13);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', od.dtlpassthruchar14);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', od.dtlpassthruchar15);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      cntLIRows := cntLiRows + 1;
      qtyRemain := qtyRemain - qtyToApply;
      if sp.serialnumber is not null then
        add_856_lk_row(oh,od,ol,sp);
      end if;
    << continue_line_loop >>
      null;
    end loop;
  end loop;
else
 for os in curSumOrderDtl(sp.lpid,oh.orderid,oh.shipid)
 loop
  qtytoSkip := 0;
  qtyRemain := os.quantity;
  for od in curOrderDtl(oh.orderid,oh.shipid,os.orderitem,os.orderlot)
  loop
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,os.orderitem,os.orderlot)
    loop
      if qtyRemain <= 0 then
        exit;
      end if;
      qtyApplied := 0;
      linefound := false;
      for linex in 1..lines.count
      loop
        if lines(linex).orderitem = od.item and
           nvl(lines(linex).orderlot,'x') = nvl(od.lotnumber,'x') and
           lines(linex).linenumber = ol.linenumber then
          qtyApplied := lines(linex).qtyapplied;
          linefound := true;
          exit;
        end if;
      end loop;
      if linefound then
        ol.qty := ol.qty - qtyApplied;
        if ol.qty <= 0 then
          goto continue_line_loop2;
        end if;
      end if;
      if qtyRemain >= ol.qty then
        qtyToApply := ol.qty;
      else
        qtyToApply := qtyRemain;
      end if;
      if linefound then
        lines(linex).qtyApplied := lines(linex).qtyApplied + qtyToApply;
      else
        linex := lines.count + 1;
        lines(linex).orderitem := od.item;
        lines(linex).orderlot := od.lotnumber;
        lines(linex).linenumber := ol.linenumber;
        lines(linex).qtyApplied := qtyToApply;
      end if;
      add_856_dl_row(oh,od,ol);
      ci := null;
      open curCustItem(oh.custid,od.item);
      fetch curCustItem into ci;
      close curCustItem;
      if od.linestatus = 'X' then
        strShipment_Status := 'ID';
      elsif nvl(od.qtyship,0) >= od.qtyorder then
        strShipment_Status := 'CC';
      elsif qtyToApply >= ol.qty then
        strShipment_Status := 'CC';
      else
        strShipment_Status := 'BP';
      end if;
      if oh.shiptype = 'S' then
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);
      else


        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into sip_asn_856_po2_' || strSuffix ||
        ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
        ':PACK_LEVEL_TYPE,:OUTER_PACK,:INNER_PACK,:INNER_PACK_UOM,:QTYTOTAL,' ||
        ':WEIGHTTOTAL,:WEIGHT_UOM,:EMPTY_PACK_WEIGHT,:CUBETOTAL,:CUBEUOM,:LINEAR_UOM,' ||
        ':LENGTH,:WIDTH,:HEIGHT,:PKG_CHAR_CODE,:PKG_DESCR_CODE,:PKG_DESCR,' ||
        ':MARKS_QUALIFIER1,:MARKS_1,:MARKS_QUALIFIER2,:MARKS_2,:ADDL_DESCR_1,' ||
        ':ADDL_DESCR_2)',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
        dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
        dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
        dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
        dbms_sql.bind_variable(curSql, ':PACK_LEVEL_TYPE', 'P');
        dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
        dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
        dbms_sql.bind_variable(curSql, ':INNER_PACK_UOM', '');
        dbms_sql.bind_variable(curSql, ':QTYTOTAL', qtytoapply);
        dbms_sql.bind_variable(curSql, ':WEIGHTTOTAL',
            qtytoapply*zci.item_weight(oh.custid, od.item, od.uom));
        dbms_sql.bind_variable(curSql, ':WEIGHT_UOM', 'LB');
        dbms_sql.bind_variable(curSql, ':EMPTY_PACK_WEIGHT', 0);
        dbms_sql.bind_variable(curSql, ':CUBETOTAL', 0);
        dbms_sql.bind_variable(curSql, ':CUBEUOM', 'CF');
        dbms_sql.bind_variable(curSql, ':LINEAR_UOM', 'LF');
        dbms_sql.bind_variable(curSql, ':LENGTH', 0);
        dbms_sql.bind_variable(curSql, ':WIDTH', 0);
        dbms_sql.bind_variable(curSql, ':HEIGHT', 0);
        dbms_sql.bind_variable(curSql, ':PKG_CHAR_CODE', '6');
        dbms_sql.bind_variable(curSql, ':PKG_DESCR_CODE', '');
        dbms_sql.bind_variable(curSql, ':PKG_DESCR', '');
        dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER1', 'GM');
        dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
        dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER2', 'UC');
        dbms_sql.bind_variable(curSql, ':MARKS_2', od.dtlpassthruchar08);
        dbms_sql.bind_variable(curSql, ':ADDL_DESCR_1', '');
        dbms_sql.bind_variable(curSql, ':ADDL_DESCR_2', '');
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);


      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_asn_856_li2_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':MARKS_1,:MARKS_2,:ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,' ||
      ':PART2_QUALIFIER,:PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,'||
      ':PART4_QUALIFIER,:PART4_ITEM,:PART_DESCR1,' ||
      ':PART_DESCR2,:QTYORDER,:QTYORDER_UOM,:PRICE,:PRICE_BASIS,:RETAIL_PRICE,' ||
      ':OUTER_PACK,:INNER_PACK,:PACK_UOM,:PACK_WEIGHT,:PACK_WEIGHT_UOM,:PACK_CUBE,' ||
      ':PACK_CUBE_UOM,:PACK_LENGTH,:PACK_WIDTH,:PACK_HEIGHT,:QTYSHIP,:QTYSHIP_UOM,' ||
      ':SHIPDATE,:QTYREMAIN,:ITEM_TOTAL,:PRODUCT_SIZE,:product_size_descr,:PRODUCT_COLOR,' ||
      ':PRODUCT_COLOR_DESCR,:PRODUCT_FABRIC_CODE,:PRODUCT_FABRIC_DESCR,:PRODUCT_PROCESS_CODE,' ||
      ':PRODUCT_PROCESS_DESC,:DEPT,:CLASS,:GENDER,:SELLER_DATE_CODE,:SHIPMENT_STATUS,' ||
      ':FLEX_FIELD_1,:FLEX_FIELD_2,:FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
        dbms_sql.native);

      end if;

      dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
      dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
      if OH.shiptype != 'S' then
          dbms_sql.bind_variable(curSql, ':MARKS_2', od.dtlpassthruchar08);
      end if;
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.lotnumber);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', od.dtlpassthruchar01);
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.dtlpassthruchar02);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':QTYORDER', od.qtyorder);
      dbms_sql.bind_variable(curSql, ':QTYORDER_UOM', od.UOM);
      dbms_sql.bind_variable(curSql, ':PRICE', zci.item_amt(oh.custid, oh.orderid, oh.shipid, od.item, od.lotnumber));
      dbms_sql.bind_variable(curSql, ':PRICE_BASIS', '');
      dbms_sql.bind_variable(curSql, ':RETAIL_PRICE', ci.useramt2);
      dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
      dbms_sql.bind_variable(curSql, ':PACK_UOM', ci.baseuom);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT', 0);
      dbms_sql.bind_variable(curSql, ':PACK_WEIGHT_UOM', 'LB');
      dbms_sql.bind_variable(curSql, ':PACK_CUBE', 0);
      dbms_sql.bind_variable(curSql, ':PACK_CUBE_UOM', 'CF');
      dbms_sql.bind_variable(curSql, ':PACK_LENGTH', ci.length);
      dbms_sql.bind_variable(curSql, ':PACK_WIDTH', ci.width);
      dbms_sql.bind_variable(curSql, ':PACK_HEIGHT', ci.height);
      dbms_sql.bind_variable(curSql, ':QTYSHIP', qtyToApply);
      dbms_sql.bind_variable(curSql, ':QTYSHIP_UOM', od.uom);
      dbms_sql.bind_variable(curSql, ':SHIPDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':QTYREMAIN', (nvl(od.qtyorder,0)-nvl(od.qtyship,0)));
      dbms_sql.bind_variable(curSql, ':ITEM_TOTAL', 0);
      dbms_sql.bind_variable(curSql, ':PRODUCT_SIZE', '');
      dbms_sql.bind_variable(curSql, ':product_size_descr', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_COLOR_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_FABRIC_DESCR', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_CODE', '');
      dbms_sql.bind_variable(curSql, ':PRODUCT_PROCESS_DESC', '');
      dbms_sql.bind_variable(curSql, ':DEPT', '');
      dbms_sql.bind_variable(curSql, ':CLASS', '');
      dbms_sql.bind_variable(curSql, ':GENDER', '');
      dbms_sql.bind_variable(curSql, ':SELLER_DATE_CODE', '');
      dbms_sql.bind_variable(curSql, ':SHIPMENT_STATUS', strShipment_Status);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', od.dtlpassthruchar11);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', od.dtlpassthruchar12);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', od.dtlpassthruchar13);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', od.dtlpassthruchar14);
      dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', od.dtlpassthruchar15);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      cntLiRows := cntLiRows + 1;
      qtyRemain := qtyRemain - qtyToApply;
      cntRows := 1;
      debugmsg('begin serial loop to master pallet');
      for sps in curShippingPlateDtl(sp.lpid,oh.orderid,oh.shipid,od.item,
                                     od.lotnumber)
      loop
        cntRows := cntRows + 1;
        if cntRows <= qtyToSkip then
          goto continue_serial_loop;
        end if;
        add_856_lk_row(oh,od,ol,sps);
        qtyToApply := qtyToApply - 1;
        if qtyToApply <= 0 then
          exit;
        end if;
      << continue_serial_loop >>
        null;
      end loop;
      qtyToSkip := qtyToSkip + qtyToApply;
    << continue_line_loop2 >>
      null;
    end loop;
  end loop;
 end loop;
end if;
debugmsg('end add_856_li_rows');
end;

procedure add_856_po_rows(oh orderhdr%rowtype) is
begin
  debugmsg('begin add_856_po_rows');
  lines.delete;

  for sp in curParentPlates(oh.orderid,oh.shipid)
  loop
    if oh.shiptype = 'S' then
      strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'0',sp.lpid),1,20);
      strPack_Level_Type := 'P';
      qty856 := 0;
      cartons856 := 0;
    else
      strUcc128 := substr(zedi.get_sscc18_code(oh.custid,'1',sp.lpid),1,20);
      strPack_Level_type := 'T';
      qty856 := sp.quantity;

    -- Determine Carton Count for the pallet
      cartons856 := 0;
/*
      debugmsg('Carton LPID:'||sp.lpid);
      for csp in (select S.custid, S.item, S.unitofmeasure,
                         I.sip_carton_uom, sum(S.quantity) quantity
                    from custitem I, shippingplate S
                   where I.custid = S.custid
                     and I.item = S.item
                     and S.type in ('F','P')
                     and S.lpid in
                   (select lpid
                      from shippingplate
                      start with lpid = SP.lpid
                    connect by prior lpid = parentlpid)
                   group by S.custid, S.item, S.unitofmeasure, I.sip_carton_uom)
      loop
        debugmsg('Calc Cartons:'||csp.item||' Q:'||csp.quantity);
        if csp.sip_carton_uom is null then
            cartons856 := 1;
            exit;
        end if;
        tcart := zcu.equiv_uom_qty(csp.custid, csp.item,
                     csp.unitofmeasure, csp.quantity, csp.sip_carton_uom);
        if tcart < 0 then
            cartons856 := 1;
            exit;
        end if;
        debugmsg('Calc Cartons:'||csp.item||' C:'||tcart);
        cartons856 := cartons856 + tcart;
      end loop;
      debugmsg('Total Cartons:'||cartons856);

*/
    end if;



    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_asn_856_po_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':PACK_LEVEL_TYPE,:OUTER_PACK,:INNER_PACK,:INNER_PACK_UOM,:QTYTOTAL,' ||
    ':WEIGHTTOTAL,:WEIGHT_UOM,:EMPTY_PACK_WEIGHT,:CUBETOTAL,:CUBEUOM,:LINEAR_UOM,' ||
    ':LENGTH,:WIDTH,:HEIGHT,:PKG_CHAR_CODE,:PKG_DESCR_CODE,:PKG_DESCR,' ||
    ':MARKS_QUALIFIER1,:MARKS_1,:MARKS_QUALIFIER2,:MARKS_2,:ADDL_DESCR_1,' ||
    ':ADDL_DESCR_2)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
    dbms_sql.bind_variable(curSql, ':PACK_LEVEL_TYPE', strPack_Level_Type);
    dbms_sql.bind_variable(curSql, ':OUTER_PACK', 0);
    dbms_sql.bind_variable(curSql, ':INNER_PACK', 0);
    dbms_sql.bind_variable(curSql, ':INNER_PACK_UOM', '');
    dbms_sql.bind_variable(curSql, ':QTYTOTAL', qty856);
    dbms_sql.bind_variable(curSql, ':WEIGHTTOTAL', sp.weight);
    dbms_sql.bind_variable(curSql, ':WEIGHT_UOM', 'LB');
    dbms_sql.bind_variable(curSql, ':EMPTY_PACK_WEIGHT', 0);
    dbms_sql.bind_variable(curSql, ':CUBETOTAL', 0);
    dbms_sql.bind_variable(curSql, ':CUBEUOM', 'CF');
    dbms_sql.bind_variable(curSql, ':LINEAR_UOM', 'LF');
    dbms_sql.bind_variable(curSql, ':LENGTH', 0);
    dbms_sql.bind_variable(curSql, ':WIDTH', 0);
    dbms_sql.bind_variable(curSql, ':HEIGHT', 0);
    dbms_sql.bind_variable(curSql, ':PKG_CHAR_CODE', '6');
    dbms_sql.bind_variable(curSql, ':PKG_DESCR_CODE', '');
    dbms_sql.bind_variable(curSql, ':PKG_DESCR', '');
    dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER1', 'GM');
    dbms_sql.bind_variable(curSql, ':MARKS_1', strUcc128);
    dbms_sql.bind_variable(curSql, ':MARKS_QUALIFIER2', '');
    dbms_sql.bind_variable(curSql, ':MARKS_2', '');
    dbms_sql.bind_variable(curSql, ':ADDL_DESCR_1', '');
    dbms_sql.bind_variable(curSql, ':ADDL_DESCR_2', '');
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    add_856_li_rows(oh,sp);
  end loop;
  debugmsg('begin end_po_rows');
end;

procedure add_856_st_row is
begin
  debugmsg('begin add_856_st_row');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_asn_856_st_' || strSuffix ||
' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
':QTYORDERS,:QTYLINES,:QTYSHIP,:WEIGHTSHIP,:FLEX_FIELD_1,:FLEX_FIELD_2,' ||
':FLEX_FIELD_3,:FLEX_FIELD_4,:FLEX_FIELD_5)',
    dbms_sql.native);
dbms_sql.bind_variable(curSql, ':ORDERID', 0);
dbms_sql.bind_variable(curSql, ':SHIPID', 0);
dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cc.SIP_TRADINGPARTNERID);
dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strSHIPMENT_IDENTIFIER);
dbms_sql.bind_variable(curSql, ':QTYORDERS', cntHOrows);
dbms_sql.bind_variable(curSql, ':QTYLINES', cntLIrows);
dbms_sql.bind_variable(curSql, ':QTYSHIP', totQTYSHIPPED);
dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', totWEIGHTSHIPPED);
dbms_sql.bind_variable(curSql, ':FLEX_FIELD_1', 'LB');
dbms_sql.bind_variable(curSql, ':FLEX_FIELD_2', '');
dbms_sql.bind_variable(curSql, ':FLEX_FIELD_3', '');
dbms_sql.bind_variable(curSql, ':FLEX_FIELD_4', '');
dbms_sql.bind_variable(curSql, ':FLEX_FIELD_5', '');
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);
debugmsg('begin end_st_row');
end;

procedure add_856_hdr_rows(oh orderhdr%rowtype) is
begin

  debugmsg('begin add_856_hdr_rows');

  if numFirstOrderId = 0 then
    numFirstOrderId := oh.orderid;
    numFirstShipId := oh.shipid;
  end if;

  strShipTo := zimsip.sip_consignee_match(oh.custid,oh.orderid,oh.shipid);
  if rtrim(in_shipto) is not null then
    if nvl(strShipTo,'x') != rtrim(in_shipto) then
      debugmsg('no match on shipto ' || strShipTo);
      return;
    end if;
  end if;

  cc :=  null;
  open curCustConsignee(oh.custid,strShipTo);
  fetch curCustConsignee into cc;
  close curCustConsignee;

  ld := null;
  if nvl(oh.loadno,0) != 0 then
    open curLoads(oh.loadno);
    fetch curLoads into ld;
    close curLoads;
  end if;

  if (nvl(in_loadno,0) != 0) then
    str_loadno := to_char(in_loadno);
    while length(rtrim(str_loadno)) < 9
    loop
      str_loadno := '0' || rtrim(str_loadno);
    end loop;
    strShipment_Identifier := str_loadno;
  else
    strShipment_Identifier :=
      substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,11);
  end if;

  debugmsg('exec add_hs');
  add_856_hs_row(oh);
  debugmsg('exec add_ha');
  add_856_ha_row(oh);
  debugmsg('exec add_ho');
  add_856_ho_row(oh);
  debugmsg('exec add_856_po');
  add_856_po_rows(oh);
  debugmsg('end add_856_hdr_rows');

end;

begin

if out_errorno = -12345 then
  strDebug := 'Y';
else
  strDebug := 'N';
end if;

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'SIP_ASN_856_HS_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

debugmsg('create hs table');
cmdSql := 'create table SIP_asn_856_hs_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,LOADNO NUMBER(7),ORDERID NUMBER(9) not null,' ||
' SHIPID NUMBER(2) not null,SHIPTO VARCHAR2(10),SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),SHIP_DATE DATE,SHIP_TIME DATE,' ||
' VENDOR VARCHAR2(255),SHIP_NOTICE_DATE DATE,SHIP_NOTICE_TIME DATE,' ||
' ASN_STRUCTURE_CODE CHAR(4),STATUS_REASON_CODE CHAR(3),PACKING_CODE CHAR(5),' ||
' LADING_QUANTITY NUMBER(7),GROSS_WEIGHT_QUALIFIER CHAR(2),SHIPMENT_WEIGHT NUMBER(7),' ||
' SHIPMENT_WEIGHT_UOM CHAR(2),EQUIP_DESCR_CODE CHAR(2),CARRIER_EQUIP_INITIAL CHAR(4),' ||
' CARRIER_EQUIP_NUMBER CHAR(10),CARRIER_ALPHA_CODE VARCHAR2(10),CARRIER_TRANS_METHOD VARCHAR2(1),' ||
' CARRIER_ROUTING VARCHAR2(4),ORDER_STATUS CHAR(2),BILL_OF_LADING VARCHAR2(40),' ||
' PRO_NUMBER VARCHAR2(20),SEAL_NUMBER VARCHAR2(15),FOB_PAY_CODE CHAR(4),' ||
' FOB_LOCATION_QUALIFIER CHAR(2),FOB_LOCATION_DESCR CHAR(30),FOB_TITLE_PASSAGE_CODE CHAR(2),' ||
' FOB_TITLE_PASSAGE_LOCATION CHAR(30),APPT_NUMBER CHAR(20),PICKUP_NUMBER CHAR(30),' ||
' REQ_PICKUP_DATE DATE,REQ_PICKUP_TIME DATE,FLEX_FIELD_1 VARCHAR2(255),' ||
' FLEX_FIELD_2 VARCHAR2(255),FLEX_FIELD_3 VARCHAR2(255),FLEX_FIELD_4 VARCHAR2(255),' ||
' FLEX_FIELD_5 VARCHAR2(255), SCHED_SHIP_DATE DATE, SCHED_SHIP_TIME DATE,'||
' SCHED_DELIVERY_DATE DATE, SCHED_DELIVERY_TIME DATE)';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create ha table');
cmdSql := 'create table SIP_asn_856_ha_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,LOADNO NUMBER(7),ORDERID NUMBER(9) not null,' ||
' SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),' ||
' ADDRESS_TYPE CHAR(2),LOCATION_QUALIFIER CHAR(2),LOCATION_NUMBER VARCHAR2(255),' ||
' NAME VARCHAR2(40),ADDR1 VARCHAR2(40),ADDR2 VARCHAR2(40),CITY VARCHAR2(30),' ||
' STATE VARCHAR2(5),POSTALCODE VARCHAR2(12),COUNTRYCODE VARCHAR2(3),' ||
' CONTACT VARCHAR2(40),PHONE VARCHAR2(25),FAX VARCHAR2(25),EMAIL VARCHAR2(255))';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create ho table');
cmdSql := 'create table SIP_asn_856_ho_' || strSuffix ||
' (CUSTID VARCHAR2(10),LOADNO NUMBER(7),ORDERID NUMBER(9),' ||
' SHIPID NUMBER(2),SIP_TRADINGPARTNERID VARCHAR2(15),SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),' ||
' PO VARCHAR2(20),ENTRYDATE DATE,STATUSUPDATE DATE,REFERENCE VARCHAR2(20),' ||
' ORDERSTATUS VARCHAR2(2),QTYSHIP NUMBER(7),WEIGHTSHIP NUMBER(17,8),' ||
' CUBESHIP NUMBER(10,4),PKGCOUNT NUMBER(7),VENDOR VARCHAR2(255), PRONO VARCHAR2(20), ' ||
' PACKING_CODE VARCHAR2(5), APPTDATE DATE )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create oa table');
cmdSql := 'create table SIP_asn_856_oa_' || strSuffix ||
 ' (custid varchar2(10), loadno number(7), orderid number(9),shipid number(2), ' ||
 ' sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),address_type varchar2(2), ' ||
 ' location_qualifier char(2), location_number varchar2(255), name varchar2(40), ' ||
 ' addr1 varchar2(40), addr2 varchar2(40), city varchar2(30), ' ||
 ' state varchar2(5), postalcode varchar2(12), countrycode varchar2(3), ' ||
 ' contact varchar2(40), phone varchar2(25), fax varchar2(25), email varchar2(255) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create po table');
cmdSql := 'create table SIP_asn_856_po_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),PACK_LEVEL_TYPE CHAR(2),OUTER_PACK NUMBER(7),' ||
' INNER_PACK NUMBER(7),INNER_PACK_UOM CHAR(2),QTYTOTAL NUMBER(7),' ||
' WEIGHTTOTAL NUMBER(17,8),WEIGHT_UOM CHAR(2),EMPTY_PACK_WEIGHT NUMBER(17,8),' ||
' CUBETOTAL NUMBER(10,4),CUBEUOM CHAR(2),LINEAR_UOM CHAR(2),LENGTH NUMBER(13,4),' ||
' WIDTH NUMBER(13,4),HEIGHT NUMBER(13,4),PKG_CHAR_CODE CHAR(5),PKG_DESCR_CODE CHAR(7),' ||
' PKG_DESCR VARCHAR2(15),MARKS_QUALIFIER1 CHAR(2),MARKS_1 VARCHAR2(48),' ||
' MARKS_QUALIFIER2 CHAR(2),MARKS_2 VARCHAR2(48),ADDL_DESCR_1 VARCHAR2(80),' ||
' ADDL_DESCR_2 VARCHAR2(80) )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create po2 table');
cmdSql := 'create table SIP_asn_856_po2_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),PACK_LEVEL_TYPE CHAR(2),OUTER_PACK NUMBER(7),' ||
' INNER_PACK NUMBER(7),INNER_PACK_UOM CHAR(2),QTYTOTAL NUMBER(7),' ||
' WEIGHTTOTAL NUMBER(17,8),WEIGHT_UOM CHAR(2),EMPTY_PACK_WEIGHT NUMBER(17,8),' ||
' CUBETOTAL NUMBER(10,4),CUBEUOM CHAR(2),LINEAR_UOM CHAR(2),LENGTH NUMBER(13,4),' ||
' WIDTH NUMBER(13,4),HEIGHT NUMBER(13,4),PKG_CHAR_CODE CHAR(5),PKG_DESCR_CODE CHAR(7),' ||
' PKG_DESCR VARCHAR2(15),MARKS_QUALIFIER1 CHAR(2),MARKS_1 VARCHAR2(48),' ||
' MARKS_QUALIFIER2 CHAR(2),MARKS_2 VARCHAR2(48),ADDL_DESCR_1 VARCHAR2(80),' ||
' ADDL_DESCR_2 VARCHAR2(80) )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create li table');
cmdSql := 'create table SIP_asn_856_LI_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),MARKS_1 VARCHAR2(48),item varchar2(50) not null,' ||
' LOTNUMBER VARCHAR2(30),LINE_NUMBER NUMBER(16,4),PART1_QUALIFIER VARCHAR2(255),' ||
' PART1_ITEM VARCHAR2(255),PART2_QUALIFIER VARCHAR2(255),PART2_ITEM VARCHAR2(255),' ||
' PART3_QUALIFIER VARCHAR2(255),PART3_ITEM VARCHAR2(255),'||
' PART4_QUALIFIER VARCHAR2(255),PART4_ITEM VARCHAR2(255),'||
' PART_DESCR1 VARCHAR2(255),' ||
' PART_DESCR2 VARCHAR2(255),QTYORDER NUMBER(7),QTYORDER_UOM CHAR(4),' ||
' PRICE NUMBER(10,2),PRICE_BASIS CHAR(2),RETAIL_PRICE NUMBER(10,2),' ||
' OUTER_PACK NUMBER(7),INNER_PACK NUMBER(7),PACK_UOM CHAR(4),PACK_WEIGHT NUMBER(17,8),' ||
' PACK_WEIGHT_UOM CHAR(4),PACK_CUBE NUMBER(10,4),PACK_CUBE_UOM CHAR(4),' ||
' PACK_LENGTH NUMBER(10,4),PACK_WIDTH NUMBER(10,4),PACK_HEIGHT NUMBER(10,4),' ||
' QTYSHIP NUMBER(7),QTYSHIP_UOM CHAR(4),SHIPDATE DATE,QTYREMAIN NUMBER(7),' ||
' ITEM_TOTAL NUMBER(7),PRODUCT_SIZE CHAR(2),product_size_descr VARCHAR2(45),' ||
' PRODUCT_COLOR CHAR(2),PRODUCT_COLOR_DESCR VARCHAR2(45),PRODUCT_FABRIC_CODE CHAR(2),' ||
' PRODUCT_FABRIC_DESCR VARCHAR2(45),PRODUCT_PROCESS_CODE CHAR(2),PRODUCT_PROCESS_DESC VARCHAR2(45),' ||
' DEPT CHAR(10),CLASS CHAR(30),GENDER CHAR(30),SELLER_DATE_CODE CHAR(8),' ||
' SHIPMENT_STATUS CHAR(2),FLEX_FIELD_1 VARCHAR2(255),FLEX_FIELD_2 VARCHAR2(255),' ||
' FLEX_FIELD_3 VARCHAR2(255),FLEX_FIELD_4 VARCHAR2(255),FLEX_FIELD_5 VARCHAR2(255))';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create li2 table');
cmdSql := 'create table SIP_asn_856_LI2_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),MARKS_1 VARCHAR2(48),' ||
' MARKS_2 VARCHAR2(48), item varchar2(50) not null,' ||
' LOTNUMBER VARCHAR2(30),LINE_NUMBER NUMBER(16,4),PART1_QUALIFIER VARCHAR2(255),' ||
' PART1_ITEM VARCHAR2(255),PART2_QUALIFIER VARCHAR2(255),PART2_ITEM VARCHAR2(255),' ||
' PART3_QUALIFIER VARCHAR2(255),PART3_ITEM VARCHAR2(255),'||
' PART4_QUALIFIER VARCHAR2(255),PART4_ITEM VARCHAR2(255),'||
' PART_DESCR1 VARCHAR2(255),' ||
' PART_DESCR2 VARCHAR2(255),QTYORDER NUMBER(7),QTYORDER_UOM CHAR(4),' ||
' PRICE NUMBER(10,2),PRICE_BASIS CHAR(2),RETAIL_PRICE NUMBER(10,2),' ||
' OUTER_PACK NUMBER(7),INNER_PACK NUMBER(7),PACK_UOM CHAR(4),PACK_WEIGHT NUMBER(17,8),' ||
' PACK_WEIGHT_UOM CHAR(4),PACK_CUBE NUMBER(10,4),PACK_CUBE_UOM CHAR(4),' ||
' PACK_LENGTH NUMBER(10,4),PACK_WIDTH NUMBER(10,4),PACK_HEIGHT NUMBER(10,4),' ||
' QTYSHIP NUMBER(7),QTYSHIP_UOM CHAR(4),SHIPDATE DATE,QTYREMAIN NUMBER(7),' ||
' ITEM_TOTAL NUMBER(7),PRODUCT_SIZE CHAR(2),product_size_descr VARCHAR2(45),' ||
' PRODUCT_COLOR CHAR(2),PRODUCT_COLOR_DESCR VARCHAR2(45),PRODUCT_FABRIC_CODE CHAR(2),' ||
' PRODUCT_FABRIC_DESCR VARCHAR2(45),PRODUCT_PROCESS_CODE CHAR(2),PRODUCT_PROCESS_DESC VARCHAR2(45),' ||
' DEPT CHAR(10),CLASS CHAR(30),GENDER CHAR(30),SELLER_DATE_CODE CHAR(8),' ||
' SHIPMENT_STATUS CHAR(2),FLEX_FIELD_1 VARCHAR2(255),FLEX_FIELD_2 VARCHAR2(255),' ||
' FLEX_FIELD_3 VARCHAR2(255),FLEX_FIELD_4 VARCHAR2(255),FLEX_FIELD_5 VARCHAR2(255))';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create dl table');
cmdSql := 'create table SIP_asn_856_dl_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),MARKS_1 VARCHAR2(48),item varchar2(50) not null,' ||
' LOTNUMBER VARCHAR2(30),LINE_NUMBER NUMBER(16,4),CANCEL_AFTER DATE,' ||
' DO_NOT_DELIVER_BEFORE DATE,DO_NOT_DELIVER_AFTER DATE,REQUESTED_DELIVERY DATE,' ||
' REQUESTED_PICKUP DATE,REQUESTED_SHIP DATE,SHIP_NO_LATER DATE,SHIP_NOT_BEFORE DATE,' ||
' PROMO_START DATE,PROMO_END DATE,ADDL_DATE1_QUALIFIER CHAR(3),ADDL_DATE1 DATE,' ||
' ADDL_DATE2_QUALIFIER CHAR(3),ADDL_DATE2 DATE,ADDL_DATE3_QUALIFIER CHAR(3),' ||
' ADDL_DATE3 DATE )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create lk table');
cmdSql := 'create table SIP_asn_856_lk_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),MARKS_1 VARCHAR2(48),item varchar2(50) not null,' ||
' LOTNUMBER VARCHAR2(30),LINE_NUMBER NUMBER(16,4),PART1_QUALIFIER VARCHAR2(255),' ||
' PART1_ITEM VARCHAR2(255),PART2_QUALIFIER VARCHAR2(255),PART2_ITEM VARCHAR2(255),' ||
' PART3_QUALIFIER VARCHAR2(255),PART3_ITEM VARCHAR2(255),'||
' PART4_QUALIFIER VARCHAR2(255),PART4_ITEM VARCHAR2(255),'||
' PART_DESCR1 VARCHAR2(255),' ||
' PART_DESCR2 VARCHAR2(255),PRODUCT_SIZE CHAR(3),product_size_descr VARCHAR2(45),' ||
' PRODUCT_COLOR CHAR(3),PRODUCT_COLOR_DESCR VARCHAR2(45),PRODUCT_FABRIC_CODE CHAR(3),' ||
' PRODUCT_FABRIC_DESCR VARCHAR2(45),PRODUCT_PROCESS_CODE CHAR(3),PRODUCT_PROCESS_DESC VARCHAR2(45),' ||
' QTY_PER NUMBER(7),QTY_PER_UOM NUMBER(7),UNIT_PRICE NUMBER(10,2),' ||
' UNIT_PRICE_BASIS CHAR(2),SERIALNUMBER VARCHAR2(30),WARRANTY_DATE DATE,' ||
' EFFECTIVE_DATE DATE,LOT_EXPIRATION_DATE DATE )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create st table');
cmdSql := 'create table SIP_asn_856_ST_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,SIP_TRADINGPARTNERID VARCHAR2(15),' ||
' SIP_SHIPMENT_IDENTIFIER VARCHAR2(11),QTYORDERS NUMBER(7),QTYLINES NUMBER(7),' ||
' QTYSHIP NUMBER(7),WEIGHTSHIP NUMBER(17,8),FLEX_FIELD_1 VARCHAR2(255),' ||
' FLEX_FIELD_2 VARCHAR2(255),FLEX_FIELD_3 VARCHAR2(255),FLEX_FIELD_4 VARCHAR2(255),' ||
' FLEX_FIELD_5 VARCHAR2(255) )';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cntHOrows := 0;
cntLiRows := 0;
numFirstOrderId := 0;
numFirstShipId := 0;
totqtyshipped := 0;
totweightshipped := 0;

debugmsg('tables created checking orderid');
if in_orderid != 0 then
  debugmsg('export order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    add_856_hdr_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('export load ' || in_loadno);
  for oh in curOrderHdrByLoad
  loop
    add_856_hdr_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('processing by date ' || in_begdatestr || '-' || in_enddatestr);
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    add_856_hdr_rows(oh);
  end loop;
end if;

if cntHoRows != 0 then
  add_856_st_row;
end if;

debugmsg('reached okay');
out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbsipwsa856 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_sip_asn_856;

procedure end_sip_asn_856
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop table sip_asn_856_ha_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_ho_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_oa_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_po_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_po2_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_li_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_li2_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_dl_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_lk_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_st_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_asn_856_hs_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zesip856wsa ' || sqlerrm;
  out_errorno := sqlcode;
end end_sip_asn_856;

procedure begin_sip_str_944
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('R','X')
     and ordertype in ('R','C')
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('R','X')
     and ordertype in ('R','C')
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('R','X')
     and ordertype in ('R','C')
     and loadno = in_loadno
   order by orderid,shipid;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curReceiptPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select lpid,
         lotnumber,
         serialnumber,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
   group by lpid,lotnumber,serialnumber
   order by lpid,lotnumber,serialnumber;
rp curReceiptPlate%rowtype;

cursor curOrderDtlLineCount(in_orderid number, in_shipid number,
  in_orderitem varchar2, in_orderlot varchar2) is
  select count(1) as count
    from orderdtlline ol
   where ol.orderid = in_orderid
     and ol.shipid = in_shipid
     and ol.item = in_orderitem
     and nvl(ol.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and nvl(ol.xdock,'N') = 'N';
olc curOrderDtlLineCount%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curCustomer is
  select custid,
         sip_tradingpartnerid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curRRData(in_orderid number, in_shipid number) is
  select nvl(ld.prono,oh.prono) as prono,
         nvl(ld.billoflading,oh.billoflading) as billoflading,
         nvl(ld.carrier,oh.carrier) as carrier,
         oh.carrier as oh_carrier,
         hdrpassthruchar18 as orig_carrier,
         hdrpassthruchar19,
         hdrpassthruchar20
    from loads ld, orderhdr oh
   where oh.orderid = in_orderid
     and oh.shipid = in_shipid
     and oh.loadno = ld.loadno(+);
rr curRRData%rowtype;

cursor curFacility (in_facility varchar2) is
  select *
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

cursor curPlateAdjReason (in_orderid number,in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select adjreason
    from plate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
par curPlateAdjReason%rowtype;

cursor curDeletedPlateAdjReason (in_orderid number,in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select adjreason
    from deletedplate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
strShipment_Identifier varchar2(11);
strCaseUpc varchar2(255);
cntView integer;
dteTest date;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
qtyDmgd shippingplate.quantity%type;
li sip_str_944_li%rowtype;
cntLot integer;
prm licenseplatestatus%rowtype;
strDebug char(1);
dteExpirationDate date;
cntLi integer;

procedure debugmsg(in_msg varchar2) is
begin
  if nvl(strDebug,'N') != 'Y' then
    return;
  end if;
  zut.prt(in_msg);
end;

procedure add_944_st_row(oh orderhdr%rowtype) is
qtyRcvdDmgd orderdtl.qtyrcvddmgd%type;
begin
  begin
    select sum(nvl(qtyrcvddmgd,0))
      into qtyRcvdDmgd
      from orderdtl
     where orderid = oh.orderid
       and shipid = oh.shipid;
  exception when others then
    qtyRcvdDmgd := 0;
  end;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_st_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':QTYRCVD,:WEIGHTRCVD,:WEIGHTUOM,:CUBERCVD,:CUBEUOM,:QTYRCVDDMGD)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':QTYrcvd', oh.QTYrcvd);
  dbms_sql.bind_variable(curSql, ':WEIGHTrcvd', oh.WEIGHTrcvd);
  dbms_sql.bind_variable(curSql, ':WEIGHTUOM', 'LB');
  dbms_sql.bind_variable(curSql, ':CUBErcvd', oh.CUBErcvd);
  dbms_sql.bind_variable(curSql, ':CUBEUOM', 'CF');
  dbms_sql.bind_variable(curSql, ':QTYrcvddmgd', qtyRcvdDmgd);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_944_ha_row(oh orderhdr%rowtype) is
begin
  debugmsg('begin add_944_ha_row-st');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_ha_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
    ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SU');
  dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', nvl(oh.hdrpassthruchar13,'92'));
  dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar11);
  dbms_sql.bind_variable(curSql, ':NAME', oh.shipperNAME);
  dbms_sql.bind_variable(curSql, ':ADDR1', oh.shipperADDR1);
  dbms_sql.bind_variable(curSql, ':ADDR2', oh.shipperADDR2);
  dbms_sql.bind_variable(curSql, ':CITY', oh.shipperCITY);
  dbms_sql.bind_variable(curSql, ':STATE', oh.shipperSTATE);
  dbms_sql.bind_variable(curSql, ':POSTALCODE', oh.shipperPOSTALCODE);
  dbms_sql.bind_variable(curSql, ':COUNTRYCODE', oh.shipperCOUNTRYCODE);
  dbms_sql.bind_variable(curSql, ':CONTACT', oh.shipperCONTACT);
  dbms_sql.bind_variable(curSql, ':PHONE', oh.shipperPHONE);
  dbms_sql.bind_variable(curSql, ':FAX', oh.shipperFAX);
  dbms_sql.bind_variable(curSql, ':EMAIL', oh.shipperEMAIL);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
  debugmsg('end add_944_ha_row-st');
  debugmsg('begin add_944_ha_row-sf');
  fa := null;
  open curFacility(oh.tofacility);
  fetch curFacility into fa;
  close curFacility;
  debugmsg('begin add_944_ha_row-sf');
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_ha_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
    ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'WH');
  dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', 'ZZ');
  dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.fromfacility);
  dbms_sql.bind_variable(curSql, ':NAME', fa.NAME);
  dbms_sql.bind_variable(curSql, ':ADDR1', fa.ADDR1);
  dbms_sql.bind_variable(curSql, ':ADDR2', fa.ADDR2);
  dbms_sql.bind_variable(curSql, ':CITY', fa.CITY);
  dbms_sql.bind_variable(curSql, ':STATE', fa.STATE);
  dbms_sql.bind_variable(curSql, ':POSTALCODE', fa.POSTALCODE);
  dbms_sql.bind_variable(curSql, ':COUNTRYCODE', fa.COUNTRYCODE);
  dbms_sql.bind_variable(curSql, ':CONTACT', fa.manager);
  dbms_sql.bind_variable(curSql, ':PHONE', fa.PHONE);
  dbms_sql.bind_variable(curSql, ':FAX', fa.FAX);
  dbms_sql.bind_variable(curSql, ':EMAIL', fa.EMAIL);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
  debugmsg('end add_944_ha_row-sf');
  if rtrim(oh.hdrpassthruchar14) is not null then
    debugmsg('begin add_944_ha_row-sf2');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into sip_str_944_ha_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
      ':ADDRESS_TYPE,:LOCATION_QUALIFIER,:LOCATION_NUMBER,:NAME,:ADDR1,:ADDR2,' ||
      ':CITY,:STATE,:POSTALCODE,:COUNTRYCODE,:CONTACT,:PHONE,:FAX,:EMAIL)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
    dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
    dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
    dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
    dbms_sql.bind_variable(curSql, ':ADDRESS_TYPE', 'SF');
    dbms_sql.bind_variable(curSql, ':LOCATION_QUALIFIER', oh.hdrpassthruchar14);
    dbms_sql.bind_variable(curSql, ':LOCATION_NUMBER', oh.hdrpassthruchar16);
    dbms_sql.bind_variable(curSql, ':NAME', '');
    dbms_sql.bind_variable(curSql, ':ADDR1', '');
    dbms_sql.bind_variable(curSql, ':ADDR2', '');
    dbms_sql.bind_variable(curSql, ':CITY', '');
    dbms_sql.bind_variable(curSql, ':STATE', '');
    dbms_sql.bind_variable(curSql, ':POSTALCODE', '');
    dbms_sql.bind_variable(curSql, ':COUNTRYCODE', '');
    dbms_sql.bind_variable(curSql, ':CONTACT', '');
    dbms_sql.bind_variable(curSql, ':PHONE', '');
    dbms_sql.bind_variable(curSql, ':FAX', '');
    dbms_sql.bind_variable(curSql, ':EMAIL', '');
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('end add_944_ha_row-sf2');
  end if;
end;

procedure add_944_hd_row(oh orderhdr%rowtype) is
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_hd_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':SHIPTYPE,:CARRIER,:CARRIER_ROUTING,:SHIPTERMS,:OH_CARRIER,:ORIG_CARRIER)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':SHIPTYPE', oh.shiptype);
  dbms_sql.bind_variable(curSql, ':CARRIER', rr.carrier);
  dbms_sql.bind_variable(curSql, ':CARRIER_ROUTING', oh.deliveryservice);
  dbms_sql.bind_variable(curSql, ':SHIPTERMS', oh.shipterms);
  dbms_sql.bind_variable(curSql, ':OH_CARRIER', rr.oh_carrier);
  dbms_sql.bind_variable(curSql, ':ORIG_CARRIER', rr.orig_carrier);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_944_dr_data(oh orderhdr%rowtype, in_date_qualifier varchar2,
                      in_date_value date) is
begin
  if in_date_value is null then
    return;
  end if;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_dr_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':DATE_QUALIFIER,:DATE_VALUE)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':DATE_QUALIFIER', in_date_qualifier);
  dbms_sql.bind_variable(curSql, ':DATE_VALUE', in_date_value);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_944_dr_rows(oh orderhdr%rowtype) is
begin
  add_944_dr_data(oh, '19', oh.statusupdate);
end;

procedure add_944_rr_data(oh orderhdr%rowtype, in_reference_qualifier varchar2,
                      in_reference_id varchar2) is
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into sip_str_944_rr_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
    ':REFERENCE_QUALIFIER,:REFERENCE_ID,:REFERENCE_DESCR)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
  dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
  dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
  dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
  dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', in_reference_qualifier);
  dbms_sql.bind_variable(curSql, ':REFERENCE_ID', in_reference_id);
  dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end;

procedure add_944_rr_rows(oh orderhdr%rowtype) is
pos integer;
ix integer;
len integer;
begin_separator_found boolean;
end_separator_found boolean;
strQualifier varchar2(10);
strValue varchar2(255);
strMaxTrackingNo shippingplate.trackingno%type;

begin
  strMaxTrackingNo := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
  rr := null;
  open curRRData(oh.orderid,oh.shipid);
  fetch curRRdata into rr;
  close curRRdata;
  if rr.prono is not null then
    add_944_rr_data(oh, 'CN', rr.prono);
  elsif strMaxTrackingNo is not null then
    add_944_rr_data(oh, 'CN', strMaxTrackingNo);
  end if;
  if rr.billoflading is not null then
    add_944_rr_data(oh, 'BM', rr.billoflading);
  else
    if strMaxTrackingNo is not null then
      add_944_rr_data(oh, 'BM', strMaxTrackingNo);
    else
      add_944_rr_data(oh, 'BM', strShipment_Identifier);
    end if;
  end if;
  len := length(rtrim(rr.hdrpassthruchar19));
  ix := 1;
  begin_separator_found := false;
  end_separator_found := false;
  strQualifier := null;
  strValue := null;
  while (ix <= len)
  loop
    if substr(rr.hdrpassthruchar19,ix,1) = '|' then
      if end_separator_found then
        if rtrim(strValue) is not null then
          if length(rtrim(strQualifier)) <= 3 then
            add_944_rr_data(oh, strQualifier, strValue);
          end if;
        end if;
        strQualifier := null;
        strValue := null;
        end_separator_found := false;
        begin_separator_found := true;
        goto continue19_loop;
      end if;
      if begin_separator_found then
        end_separator_found := true;
      else
        begin_separator_found := true;
      end if;
      goto continue19_loop;
    end if;
    if end_separator_found then
      if strValue is null then
        strValue := substr(rr.hdrpassthruchar19,ix,1);
      else
        strValue := strValue || substr(rr.hdrpassthruchar19,ix,1);
      end if;
    elsif begin_separator_found then
      if strQualifier is null then
        strQualifier := substr(rr.hdrpassthruchar19,ix,1);
      else
        strQualifier := strQualifier || substr(rr.hdrpassthruchar19,ix,1);
      end if;
    end if;
  << continue19_loop >>
    ix := ix + 1;
  end loop;
  if rtrim(strQualifier) is not null and
     rtrim(strValue) is not null then
    if length(rtrim(strQualifier)) <= 3 then
      add_944_rr_data(oh, strQualifier, strValue);
    end if;
  end if;

  len := length(rtrim(rr.hdrpassthruchar20));
  ix := 1;
  begin_separator_found := false;
  end_separator_found := false;
  strQualifier := null;
  strValue := null;
  while (ix <= len)
  loop
    if substr(rr.hdrpassthruchar20,ix,1) = '|' then
      if end_separator_found then
        if rtrim(strValue) is not null then
          if length(rtrim(strQualifier)) <= 3 then
            add_944_rr_data(oh, strQualifier, strValue);
          end if;
        end if;
        strQualifier := null;
        strValue := null;
        end_separator_found := false;
        begin_separator_found := true;
        goto continue19_loop;
      end if;
      if begin_separator_found then
        end_separator_found := true;
      else
        begin_separator_found := true;
      end if;
      goto continue19_loop;
    end if;
    if end_separator_found then
      if strValue is null then
        strValue := substr(rr.hdrpassthruchar20,ix,1);
      else
        strValue := strValue || substr(rr.hdrpassthruchar20,ix,1);
      end if;
    elsif begin_separator_found then
      if strQualifier is null then
        strQualifier := substr(rr.hdrpassthruchar20,ix,1);
      else
        strQualifier := strQualifier || substr(rr.hdrpassthruchar20,ix,1);
      end if;
    end if;
  << continue19_loop >>
    ix := ix + 1;
  end loop;
  if rtrim(strQualifier) is not null and
     rtrim(strValue) is not null then
    if length(rtrim(strQualifier)) <= 3 then
      add_944_rr_data(oh, strQualifier, strValue);
    end if;
  end if;

  if rtrim(strMaxTrackingNo) is not null then
    add_944_rr_data(oh, '08', strMaxTrackingNo);
  end if;
end;

procedure add_944_dtl_rows_by_item(oh orderhdr%rowtype) is
begin
  debugmsg('begin add_944_dtl_rows_by_item');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('order dtl loop');
    olc.count := 1;
    cntLi := 0;
    open curOrderDtlLineCount(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curOrderDtlLineCount into olc;
    close curOrderDtlLineCount;
    rp := null;
    open curReceiptPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curReceiptPlate into rp;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      cntLi := cntLi + 1;
      debugmsg('order line loop');
      qtyRemain := ol.qty;
      qtyDmgd := 0;
      while (qtyRemain > 0 and cntLi < olc.count) or
            (cntLi = olc.count)
      loop
        if rp.qtyrcvd = 0 then
          debugmsg('get next receipt plate');
          fetch curReceiptPlate into rp;
          if curReceiptPlate%notfound then
            debugmsg('no more receipt plates');
            rp := null;
            exit;
          end if;
        end if;
        if (rp.qtyrcvd >= qtyRemain and cntLi < olc.count) then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := rp.qtyrcvd;
        end if;
        if rp.qtyrcvddmgd > 0 then
          if rp.qtyrcvddmgd <= qtyLineNumber then
            qtyDmgd := qtyDmgd + rp.qtyrcvddmgd;
          else
            qtyDmgd := qtyDmgd + qtyLineNumber;
          end if;
        end if;
        if rtrim(rp.serialnumber) is not null then
          debugmsg('add lr for serialnumber');
          curSql := dbms_sql.open_cursor;
          dbms_sql.parse(curSql, 'insert into sip_str_944_lr_' || strSuffix ||
            ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
            ':ITEM,:LOTNUMBER,:LINE_NUMBER,:REFERENCE_QUALIFIER,:REFERENCE_ID,' ||
            ':REFERENCE_DESCR)',
            dbms_sql.native);
          dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
          dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
          dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.SIP_TRADINGPARTNERID);
          dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
          dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
          dbms_sql.bind_variable(curSql, ':LOTNUMBER', rp.lotnumber);
          dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
          dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', 'ZZ');
          dbms_sql.bind_variable(curSql, ':REFERENCE_ID', rp.serialnumber);
          dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
          cntRows := dbms_sql.execute(curSql);
          dbms_sql.close_cursor(curSql);
          debugmsg('added lr for serialnumber');
        end if;
        if rtrim(rp.lotnumber) is not null then
          cntLot := 0;
          execute immediate
            'select count(1) from sip_str_944_lr_' || strSuffix  ||
            ' where orderid = :orderid and shipid = :shipid and ' ||
            'line_number = :line_number and lotnumber = :lotnumber'
              into cntLot
            using oh.orderid, oh.shipid, ol.linenumber, rp.lotnumber;
          debugmsg('cntLot is ' || cntLot);
          if cntLot = 0 then
            debugmsg('add lr for lotnumber');
            curSql := dbms_sql.open_cursor;
            dbms_sql.parse(curSql, 'insert into sip_str_944_lr_' || strSuffix ||
              ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
              ':ITEM,:LOTNUMBER,:LINE_NUMBER,:REFERENCE_QUALIFIER,:REFERENCE_ID,' ||
              ':REFERENCE_DESCR)',
              dbms_sql.native);
            dbms_sql.bind_variable(curSql, ':ORDERID', oh.ORDERID);
            dbms_sql.bind_variable(curSql, ':SHIPID', oh.SHIPID);
            dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.SIP_TRADINGPARTNERID);
            dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
            dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
            dbms_sql.bind_variable(curSql, ':LOTNUMBER', rp.lotnumber);
            dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.linenumber);
            dbms_sql.bind_variable(curSql, ':REFERENCE_QUALIFIER', 'LT');
            dbms_sql.bind_variable(curSql, ':REFERENCE_ID', rp.lotnumber);
            dbms_sql.bind_variable(curSql, ':REFERENCE_DESCR', '');
            cntRows := dbms_sql.execute(curSql);
            dbms_sql.close_cursor(curSql);
            debugmsg('added lr');
          end if;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        rp.qtyrcvd := rp.qtyrcvd - qtyLineNumber;
      end loop; -- ReceiptPlate
      li := null;
      li.qtyrcvd := ol.qty - qtyRemain;
      debugmsg('get upc');
      begin
        select upc
          into li.CaseUpc
          from custitemupcview
         where custid = cu.custid
           and item = od.item;
      exception when others then
        debugmsg('upc exception');
        li.CaseUpc := '';
      end;
      debugmsg('get weightreceived');
      li.weightrcvd := zci.item_weight(cu.custid,od.item,od.uom) * li.qtyrcvd;
      if li.qtydiff > 0 then
        li.qtydiff := qtyRemain;
        li.uomdiff := od.uom;
        li.condition_code := '03';
      elsif li.qtydiff < 0 then
        li.qtydiff := qtyRemain;
        li.uomdiff := od.uom;
        li.condition_code := '02';
      elsif qtyDmgd != 0 then
        li.qtydiff := qtyDmgd;
        li.uomdiff := od.uom;
        li.condition_code := '01';
        par := null;
        open curPlateAdjReason(oh.orderid,oh.shipid,od.item,od.lotnumber);
        fetch curPlateAdjReason into par;
        close curPlateAdjReason;
        if par.adjreason is null then
          open curDeletedPlateAdjReason(oh.orderid,oh.shipid,od.item,od.lotnumber);
          fetch curDeletedPlateAdjReason into par;
          close curDeletedPlateAdjReason;
        end if;
        li.dmgreason := par.adjreason;
      end if;
      debugmsg('insert 944 li');
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into sip_str_944_li_' || strSuffix ||
        ' values (:ORDERID,:SHIPID,:SIP_TRADINGPARTNERID,:SIP_SHIPMENT_IDENTIFIER,' ||
        ':ITEM,:LOTNUMBER,:LINE_NUMBER,:PART1_QUALIFIER,:PART1_ITEM,:PART2_QUALIFIER,' ||
        ':PART2_ITEM,:PART3_QUALIFIER,:PART3_ITEM,:PART4_QUALIFIER,:PART4_ITEM,'||
        ':PART_DESCR1,:PART_DESCR2,' ||
        ':QTYORDER,:QTYRCVD,:QTYDIFF,:UOMRCVD,:CASEUPC,:WEIGHTRCVD,' ||
        ':RCVDDATE,:UOMDIFF,:CONDITION_CODE,:DMGREASON)',
         dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':ORDERID', oh.orderid);
      dbms_sql.bind_variable(curSql, ':SHIPID', oh.shipid);
      dbms_sql.bind_variable(curSql, ':SIP_TRADINGPARTNERID', cu.sip_tradingpartnerid);
      dbms_sql.bind_variable(curSql, ':SIP_SHIPMENT_IDENTIFIER', strShipment_Identifier);
      dbms_sql.bind_variable(curSql, ':ITEM', od.item);
      dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.LOTNUMBER);
      dbms_sql.bind_variable(curSql, ':LINE_NUMBER', ol.LINENUMBER);
      dbms_sql.bind_variable(curSql, ':PART1_QUALIFIER', od.dtlpassthruchar01);
      dbms_sql.bind_variable(curSql, ':PART1_ITEM', od.dtlpassthruchar02);
      dbms_sql.bind_variable(curSql, ':PART2_QUALIFIER', od.dtlpassthruchar03);
      dbms_sql.bind_variable(curSql, ':PART2_ITEM', od.dtlpassthruchar04);
      dbms_sql.bind_variable(curSql, ':PART3_QUALIFIER', od.dtlpassthruchar05);
      dbms_sql.bind_variable(curSql, ':PART3_ITEM', od.dtlpassthruchar06);
      dbms_sql.bind_variable(curSql, ':PART4_QUALIFIER', od.dtlpassthruchar07);
      dbms_sql.bind_variable(curSql, ':PART4_ITEM', od.dtlpassthruchar08);
      dbms_sql.bind_variable(curSql, ':PART_DESCR1', od.dtlpassthruchar09);
      dbms_sql.bind_variable(curSql, ':PART_DESCR2', od.dtlpassthruchar10);
      dbms_sql.bind_variable(curSql, ':QTYORDER', ol.QTY);
      dbms_sql.bind_variable(curSql, ':QTYRCVD', li.qtyrcvd);
      dbms_sql.bind_variable(curSql, ':QTYDIFF', li.qtydiff);
      dbms_sql.bind_variable(curSql, ':UOMRCVD', od.UOM);
      dbms_sql.bind_variable(curSql, ':CASEUPC', li.CASEUPC);
      dbms_sql.bind_variable(curSql, ':WEIGHTRCVD', li.weightrcvd);
      dbms_sql.bind_variable(curSql, ':RCVDDATE', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':UOMDIFF', li.UOMDIFF);
      dbms_sql.bind_variable(curSql, ':CONDITION_CODE', li.condition_code);
      dbms_sql.bind_variable(curSql, ':DMGREASON', li.dmgreason);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
      debugmsg('inserted li');
    end loop; -- orderdtlline
    close curReceiptPlate;
  end loop; -- orderdtl
  debugmsg('end add_944_dtl_rows_by_item');
end;

procedure add_944_hdr_rows(oh orderhdr%rowtype) is
begin
  strShipment_Identifier :=
    substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,11);
  debugmsg('exec add_rr');
  add_944_rr_rows(oh);
  debugmsg('exec add_944_dr');
  add_944_dr_rows(oh);
  debugmsg('exec add_hd');
  add_944_hd_row(oh);
  debugmsg('exec add_ha');
  add_944_ha_row(oh);
  add_944_dtl_rows_by_item(oh);
  debugmsg('exec add_st');
  add_944_st_row(oh);
end;

begin

if out_errorno = -12345 then
  strDebug := 'Y';
else
  strDebug := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'SIP_STR_944_RR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

cmdSql := 'create table SIP_str_944_RR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),reference_qualifier varchar2(3), ' ||
 ' reference_id varchar2(20), reference_descr varchar2(45) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_DR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),date_qualifier varchar2(3), ' ||
 ' date_value date ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_HD_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),shiptype varchar2(1), ' ||
 ' carrier varchar2(10), carrier_routing varchar2(255), shipterms varchar2(3), ' ||
 ' oh_carrier varchar2(10), orig_carrier varchar2(255) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_HA_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),address_type varchar2(2), ' ||
 ' location_qualifier char(2), location_number varchar2(255), name varchar2(40), ' ||
 ' addr1 varchar2(40), addr2 varchar2(40), city varchar2(30), ' ||
 ' state varchar2(5), postalcode varchar2(12), countrycode varchar2(3), ' ||
 ' contact varchar2(40), phone varchar2(25), fax varchar2(25), email varchar2(255) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_LI_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),item varchar2(50), lotnumber varchar2(30), ' ||
 ' line_number number(16,4), part1_qualifier varchar2(255), part1_item varchar2(255), ' ||
 ' part2_qualifier varchar2(255), part2_item varchar2(255), ' ||
 ' part3_qualifier varchar2(255), part3_item varchar2(255), ' ||
 ' part4_qualifier varchar2(255), part4_item varchar2(255), ' ||
 ' part_descr1 varchar2(255),part_descr2 varchar2(255), ' ||
 ' qtyorder number(7), qtyrcvd number(7),qtydiff number, uomrcvd varchar2(4), ' ||
 ' caseupc varchar2(20), weightrcvd number(17,8), rcvddate date, ' ||
 ' uomdiff varchar2(4), condition_code varchar2(4), dmgreason varchar2(4) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_LR_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),item varchar2(50), lotnumber varchar2(30), ' ||
 ' line_number number(16,4), reference_qualifier varchar2(3), ' ||
 ' reference_id varchar2(30), reference_descr varchar2(45) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create table SIP_str_944_ST_' || strSuffix ||
 ' (orderid number(9),shipid number(2),sip_tradingpartnerid varchar2(15),' ||
 ' sip_shipment_identifier varchar2(11),qtyrcvd number(7), weightrcvd number(17,8), ' ||
 ' weightuom char(2), cubercvd number(10,4), cubeuom char(2), qtyrcvddmgd number ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('creating view');

cmdSql := 'create view sip_str_944_ho_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,po,statusupdate,reference,' ||
 ' shippername,shipperaddr1,shipperaddr2,shippercity,shipperstate,' ||
 ' shipperpostalcode,shippercountrycode,' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,orderstatus,qtyrcvd,weightrcvd, ' ||
 ' cubercvd,carrier,shipper,trailer,seal,' ||
 ' sip_tradingpartnerid,sip_shipment_identifier,reporting_code) ' ||
 ' as select distinct oh.custid,oh.loadno,oh.orderid,oh.shipid,oh.po,' ||
 ' oh.statusupdate,oh.reference,' ||
 ' decode(oh.shipper,null,oh.shippername,cn.name),' ||
 ' decode(oh.shipper,null,oh.shipperaddr1,cn.addr1),' ||
 ' decode(oh.shipper,null,oh.shipperaddr2,cn.addr2),' ||
 ' decode(oh.shipper,null,oh.shippercity,cn.city),' ||
 ' decode(oh.shipper,null,oh.shipperstate,cn.state),' ||
 ' decode(oh.shipper,null,oh.shipperpostalcode,cn.postalcode),' ||
 ' decode(oh.shipper,null,oh.shippercountrycode,cn.countrycode),' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,orderstatus,oh.qtyrcvd,oh.weightrcvd, ' ||
 ' oh.cubercvd,nvl(ld.carrier,oh.carrier),oh.shipper,ld.trailer,ld.seal, ' ||
 ' cu.sip_tradingpartnerid, ' ||
 ' substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,11), ''F'' ' ||
 '  from customer cu, shipper cn, loads ld, ' ||
 '  orderhdr oh, sip_str_944_li_' || strSuffix || ' li ' ||
 ' where oh.orderid = li.orderid and ' ||
 ' oh.shipid = li.shipid and ' ||
 ' oh.loadno = ld.loadno(+) and ' ||
 ' oh.custid = cu.custid(+) and ' ||
 ' oh.shipper = cn.shipper(+) ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('view created checking orderid');
if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_944_hdr_rows(oh);
  end loop;
elsif in_loadno != 0 then
  for oh in curOrderHdrByLoad
  loop
    add_944_hdr_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    add_944_hdr_rows(oh);
  end loop;
end if;

debugmsg('reached okay');
out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbsipwsa944 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_sip_str_944;

procedure end_sip_str_944
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view sip_str_944_ho_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_dr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_hd_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_ha_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_li_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_lr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_st_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table sip_str_944_rr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zesip944wsa ' || sqlerrm;
  out_errorno := sqlcode;
end end_sip_str_944;

end zimportprocsip;
/
show error package body zimportprocsip;
exit;
