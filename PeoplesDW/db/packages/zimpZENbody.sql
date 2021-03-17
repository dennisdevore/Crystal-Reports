create or replace package body alps.zimportprocsZEN as

IMP_USERID constant varchar2(8) := 'IMPORDER';


procedure import_order_line_ZEN
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_rfautodisplay varchar2
,in_comment  long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
   order by orderstatus;
oh curOrderHdr%rowtype;
l_linenumber number;
l_ptn10 number;
procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin
/* Thomasville order imports the line number in dtlpassthrunum10 is moved to dtlpassthrunum09
   a unique line number is then genereated. */


out_errorno := 0;
out_msg := '';

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

select nvl(dtlpassthrunum10,-1) into l_ptn10 /* get the assigned line number */
   from orderdtlline
   where orderid = oh.orderid
     and shipid = oh.shipid
     and item = in_itementered
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and dtlpassthrunum09 = in_dtlpassthrunum10;     /* 9 has thomasville line number, 10 our assigned line number */

if l_ptn10 > 0 then
   l_linenumber := l_ptn10;
else
   select nvl(max(linenumber),0) into l_linenumber
      from orderdtlline
      where orderid = oh.orderid
        and shipid = oh.shipid;

      l_linenumber := l_linenumber + 1;
end if;

zimp.import_order_line(in_func,in_custid,in_reference,in_po,
    in_itementered,in_lotnumber,
    in_uomentered, in_qtyentered,
    in_backorder,in_allowsub,in_qtytype,
    in_invstatusind,in_invstatus,in_invclassind,in_inventoryclass,
    in_consigneesku,
    in_dtlpassthruchar01,in_dtlpassthruchar02,
    in_dtlpassthruchar03,in_dtlpassthruchar04,
    in_dtlpassthruchar05,in_dtlpassthruchar06,
    in_dtlpassthruchar07,in_dtlpassthruchar08,
    in_dtlpassthruchar09,in_dtlpassthruchar10,
    in_dtlpassthruchar11,in_dtlpassthruchar12,
    in_dtlpassthruchar13,in_dtlpassthruchar14,
    in_dtlpassthruchar15,in_dtlpassthruchar16,
    in_dtlpassthruchar17,in_dtlpassthruchar18,
    in_dtlpassthruchar19,in_dtlpassthruchar20,
    null,null,null,null,null,null,null,null,null,null,
    null,null,null,null,null,null,null,null,null,null,
    in_dtlpassthrunum01,in_dtlpassthrunum02,
    in_dtlpassthrunum03,in_dtlpassthrunum04,
    in_dtlpassthrunum05,in_dtlpassthrunum06,
    in_dtlpassthrunum07,in_dtlpassthrunum08,
    in_dtlpassthrunum10,
    null,null,null,null,null,null,null,null,null,null,l_linenumber,
    in_dtlpassthrudate01,in_dtlpassthrudate02,
    in_dtlpassthrudate03,in_dtlpassthrudate04,
    in_dtlpassthrudoll01,in_dtlpassthrudoll02,
    in_rfautodisplay,in_comment,in_weight_entered_lbs,in_weight_entered_kgs,null,null,null,null,null,null,
    null, null, null, null, null, null, null, null, null, null, null,null,null,null,
    out_orderid,out_shipid,out_errorno,out_msg);


if out_errorno != 0 then
    order_msg('E');
    return;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziozl ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_ZEN;


end zimportprocsZEN;
/
show error package body zimportprocsZEN;
exit;

