create or replace package body alps.zimportproc860 as
--
-- $Id: zim860body.sql 864 2006-05-16 20:40:15Z mikeh $
--

IMP_USERID constant varchar2(8) := 'IMP860';
i_seq integer := 0;

procedure import_860_dillards
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_action IN varchar2
,in_shiptoname IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptozip IN varchar2
,in_consignee IN varchar2
,in_datecode37 IN varchar2
,in_date37 IN varchar2
,in_datecode38 IN varchar2
,in_date38 IN varchar2
,in_change_code IN varchar2
,in_orig_qty IN number
,in_qty_change IN number
,in_uom IN varchar2
,in_orig_price IN number
,in_item IN varchar2
,in_adduom IN varchar2
,in_new_price IN number
,in_new_qty IN number
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
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
strMsg appmsgs.msgtext%type;

rowCnt integer;

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;


procedure order_msg(in_msgtype varchar2) is
cntChar integer;
begin

  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  zms.log_msg(IMP_USERID, 'TST', rtrim(in_custid), out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;
end;

procedure cancel_order_860 is
begin

   zoe.cancel_order_request(oh.orderid, oh.shipid, oh.fromfacility,
                           'EDI',IMP_USERID, out_msg);

end cancel_order_860;

procedure change_consignee is
begin
   update orderhdr set shipto = 'DIL' || in_consignee
      where orderid = oh.orderid and
            shipid = oh.shipid;
   commit;

exception when others then
   out_msg := 'Consignee change failed: ' || in_consignee ||' ' ||sqlerrm;
   out_errorno := sqlcode;
   return;
end change_consignee;

procedure change_date is
begin
   if nvl(in_datecode37,'x') = '037' then
      begin
         update orderhdr set shipdate = to_date(in_date37,'YYYYMMDD'),
                             ship_not_before = to_date(in_date37,'YYYYMMDD')
            where orderid = oh.orderid and
                  shipid = oh.shipid;
      exception when others then
         rollback;
      end;
      commit;
   end if;
   if nvl(in_datecode38,'x') = '038' then
      begin
         update orderhdr set ship_no_later = to_date(in_date38,'YYYYMMDD')
             where orderid = oh.orderid and
                  shipid = oh.shipid;
      exception when others then
         rollback;
      end;
      commit;
   end if;

end change_date;

procedure delete_item is
odQty integer;
begin
   begin
      select qtyentered into odQty from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and itementered = in_item;
      exception when others then
         out_msg := 'Delete item - Item not found: ' || in_item;
         return;
   end;
   update orderdtl set linestatus = 'X',
                       lastuser = IMP_USERID,
                       lastupdate = sysdate
      where orderid = oh.orderid
        and shipid = oh.shipid
        and itementered = in_item;

exception when others then
  out_msg := 'Delete Item failed: ' || in_item ||' ' ||sqlerrm;
  out_errorno := sqlcode;
  return;

end delete_item;

procedure qty_increase is
odQty integer;
begin
   if in_qty_change is null then
      out_msg := 'Qty Increase failed: qty change is null';
      out_errorno := -1;
      return;
   end if;
   begin
      select nvl(qtyentered,0) into odQty from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and itementered = in_item;
   exception when others then
      out_msg := 'Item not found: ' || in_item;
      return;
   end;
   update orderdtl set qtyentered = qtyentered + in_qty_change,
                       qtyorder = qtyorder + in_qty_change,
                       weightorder = zci.item_weight(rtrim(in_custid),rtrim(in_item),rtrim(in_uom)) * (odQty + in_qty_change),
                       cubeorder = zci.item_cube(rtrim(in_custid),rtrim(in_item),rtrim(in_uom)) * (odQty + in_qty_change),
                       lastuser = IMP_USERID,
                       lastupdate = sysdate
      where orderid = oh.orderid
        and shipid = oh.shipid
        and itementered = in_item;
exception when others then
  out_msg := 'Qty Increase failed: ' || in_qty_change || ' ' ||sqlerrm;
  out_errorno := sqlcode;
  return;
end qty_increase;

procedure qty_decrease is
odQty integer;
begin
   if in_qty_change is null then
      out_msg := 'Qty Decrease failed: qty change is null';
      out_errorno := -1;
      return;
   end if;
   begin
      select nvl(qtyentered,0) into odQty from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and itementered = in_item;
   exception when others then
      out_msg := 'QD Item not found: ' || in_item;
      return;
   end;
   if odQty - in_qty_change < 1 then
      delete_item;
      return;
   end if;
   update orderdtl set qtyentered = qtyentered - in_qty_change,
                       qtyorder = qtyorder - in_qty_change,
                       weightorder = zci.item_weight(rtrim(in_custid),rtrim(in_item),rtrim(in_uom)) * (odQty - in_qty_change),
                       cubeorder = zci.item_cube(rtrim(in_custid),rtrim(in_item),rtrim(in_uom)) * (odQty - in_qty_change),
                       lastuser = IMP_USERID,
                       lastupdate = sysdate
      where orderid = oh.orderid
        and shipid = oh.shipid
        and itementered = in_item;
exception when others then
  out_msg := 'Qty Decrease failed: ' || in_qty_change || ' ' ||sqlerrm;
  out_errorno := sqlcode;
  return;
end qty_decrease;

procedure add_item is
out_orderid integer;
out_shipid integer;
in_func char(1);
begin
   in_func := 'A';
   zimp.import_order_line(in_func,in_custid,in_reference,in_po, in_item,null,
      in_uom,in_new_qty,'N','N','E','I','AV','I','RG',null,in_dtlpassthruchar01,
      in_dtlpassthruchar02,in_dtlpassthruchar03,in_dtlpassthruchar04,
      in_dtlpassthruchar05,in_dtlpassthruchar06,in_uom,
      in_dtlpassthruchar08,in_dtlpassthruchar09,in_dtlpassthruchar10,
      in_dtlpassthruchar11,in_dtlpassthruchar12,in_dtlpassthruchar13,
      in_dtlpassthruchar14,in_dtlpassthruchar15,in_dtlpassthruchar16,
      in_dtlpassthruchar17,in_dtlpassthruchar18,in_dtlpassthruchar19,
      in_dtlpassthruchar20,
      null,null,null,null,null,null,null,null,null,null,
      null,null,null,null,null,null,null,null,null,null,
      in_orig_price,in_dtlpassthrunum02,
      in_dtlpassthrunum03,in_dtlpassthrunum04,in_dtlpassthrunum05,
      in_dtlpassthrunum06,in_dtlpassthrunum07,in_dtlpassthrunum08,
      in_dtlpassthrunum09,in_dtlpassthrunum10,
      null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,
      'N',null,in_weight_entered_lbs,in_weight_entered_kgs, null, null, null, null, null, null,
      null,null, null,null, null, null, null,null,null, null, null,null,null,null,
      out_orderid ,out_shipid,out_errorno,out_msg);

end add_item;

procedure price_change is
dptn01 number(16,4);
begin
   if in_new_price is null then
      out_msg := 'Price change failed: in_new_price is null';
      out_errorno := -1;
      return;
   end if;
   begin
      select nvl(dtlpassthrunum01,0) into dptn01 from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and item = in_item;
   exception when others then
      out_msg := 'Price Change Item not found: ' || in_item;
      return;
   end;
   update orderdtl set dtlpassthrunum01 = in_new_price,
                       lastuser = IMP_USERID,
                       lastupdate = sysdate
      where orderid = oh.orderid
        and shipid = oh.shipid
        and itementered = in_item;
exception when others then
  out_msg := 'Price Change failed: ' || in_qty_change || ' ' ||sqlerrm;
  out_errorno := sqlcode;
  return;


end price_change;

procedure line_item is
begin
   null;

end line_item;



begin -- import_860_dillards main

out_errorno := 0;


--out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference);
--zms.log_msg(IMP_USERID, 'TST', rtrim(in_custid), out_msg, 'I', IMP_USERID, strMsg);

select count(1) into rowCnt from customer
   where custid = in_custid;

if rowCnt = 0 then
  out_msg := 'Invalid Custid';
  order_msg('E');
  out_errorno := -1;
  return;
end if;

select count(1) into rowCnt from orderhdr
   where custid = in_custid
     and reference = in_reference
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po);


if rowCnt = 0 then
  out_msg := 'Unable to find order';
  order_msg('E');
  out_errorno := -1;
  return;
else
   if rowCnt > 1 then
      out_msg := 'Reference returns multiple orders';
      order_msg('E');
      out_errorno := -1;
      return;
   end if;
end if;
open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%notfound then
   out_msg := 'Unable to find order';
   order_msg('E');
   out_errorno := -1;
   return;
end if;

if oh.orderstatus != '0' and oh.orderstatus != '1' then
   out_msg := 'Invalid order status for change: ' || oh.orderstatus;
   order_msg('E');
   out_errorno := -1;
   return;
end if;


if in_action = '01' then -- cancel order
   cancel_order_860;
   return;
end if;

if in_consignee is not null then
   out_msg := null;
   change_consignee;
   if out_msg is not null  then
      return;
   end if;
end if;

if in_datecode37 is not null or in_datecode38 is not null then
   out_msg := null;
   change_date;
   if out_msg is not null  then
      return;
   end if;
end if;

out_msg := null;

case in_change_code
   when 'QI' then qty_increase;
   when 'QD' then qty_decrease;
   when 'AI' then add_item;
   when 'DI' then delete_item;
   when 'PC' then price_change;
   when 'CA' then line_item;
   else out_msg := 'Invalid change code: ' || in_change_code;
end case;

if out_msg is not null and out_msg != 'OKAY' then
   order_msg('E');
   out_errorno := -1;
   return;
end if;
commit;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zi860 ' || sqlerrm;
  out_errorno := sqlcode;
end import_860_dillards;

end zimportproc860;
/
show error package body zimportproc860;
exit;

