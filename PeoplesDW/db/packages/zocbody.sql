create or replace package body alps.zorderchk as
--
-- $Id$
--


-- Private procedures


procedure update_2check_totals
   (in_orderid   in number,
    in_shipid    in number,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotno     in varchar2,
    in_lpid      in varchar2,
    in_qty       in number,
    in_uom       in varchar2,
    in_user      in varchar2,
    out_message  out varchar2)
is
   l_msg varchar2(80);
begin
  out_message := null;

   update orderdtl
      set qty2check = nvl(qty2check, 0) - in_qty,
          weight2check = decode(nvl(qty2check,0), 0, 0,
          (qty2check-in_qty)*(nvl(weight2check,0)/qty2check)),
          cube2check = nvl(cube2check, 0)
               - (zci.item_cube(in_custid, in_item, in_uom) * in_qty),
          amt2check = nvl(amt2check, 0)
               - (zci.item_amt(in_custid, in_orderid, in_shipid, in_item, in_lotno) * in_qty), --prn 25133
          lastuser = in_user,
          lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotno,'(none)');

--  nothing updated, could be a case where no lotnumber was specified during
-- order entry but the product is lot tracked
   if (sql%rowcount = 0) and (in_lotno is not null) then
       update orderdtl
          set qty2check = nvl(qty2check, 0) - in_qty,
             weight2check = decode(nvl(qty2check,0), 0, 0,
             (qty2check-in_qty)*(nvl(weight2check,0)/qty2check)),
             cube2check = nvl(cube2check, 0)
                  - (zci.item_cube(in_custid, in_item, in_uom) * in_qty),
             amt2check = nvl(amt2check, 0)
                  - (zci.item_amt(in_custid, in_orderid, in_shipid, in_item, in_lotno) * in_qty), --prn 25133
             lastuser = in_user,
             lastupdate = sysdate
     where orderid = in_orderid
        and shipid = in_shipid
        and item = in_item
        and lotnumber is null;
    end if;

   zoh.add_orderhistory_item(in_orderid, in_shipid, in_lpid, in_item, in_lotno,
       'Order Check', 'Order Check: Qty:' || in_qty || ' UOM:'|| in_uom,
          in_user, l_msg);
  if l_msg != 'OKAY' then
      out_message := l_msg;
      return;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end update_2check_totals;


-- Public procedures


procedure check_order
  (in_orderid  in number,
    in_shipid   in number,
    in_custid   in varchar2,
    in_user     in varchar2,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_oc is
      select entitem, entlot, entqty, entuom, lpid, rowid
         from ordercheck
         where orderid = in_orderid
           and shipid = in_shipid;
   cursor c_suborders(p_item varchar2, p_lotno varchar2) is
      select OD.orderid, OD.shipid, OD.qty2check
        from orderhdr OH, orderdtl OD
         where OH.wave = in_orderid
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = p_item
           and nvl(OD.lotnumber, '(none)') = nvl(p_lotno, '(none)')
           and nvl(OD.qty2check, 0) > 0;
   l_msg varchar2(80);
   l_qty number;
begin
   out_error := 'N';
   out_message := null;

   for oc in c_oc loop
    if in_orderid != zcord.cons_orderid(in_orderid, in_shipid) then
       update_2check_totals(in_orderid, in_shipid, in_custid, oc.entitem,
             oc.entlot, oc.lpid, oc.entqty, oc.entuom, in_user, l_msg);
       if l_msg is not null then
            out_error := 'Y';
            out_message := l_msg;
            return;
       end if;
    else
      for s in c_suborders(oc.entitem, oc.entlot) loop
           l_qty := least(s.qty2check, oc.entqty);

          update_2check_totals(s.orderid, s.shipid, in_custid, oc.entitem,
                oc.entlot, oc.lpid, l_qty, oc.entuom, in_user, l_msg);
          if l_msg != 'OKAY' then
              out_error := 'Y';
              out_message := l_msg;
               return;
            end if;

          oc.entqty := oc.entqty - l_qty;
            exit when oc.entqty = 0;
        end loop;
    end if;

      update ordercheck
        set complete = 'Y'
         where rowid = oc.rowid;
  end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end check_order;


procedure check_plate
  (in_lpid     in varchar2,
    in_facility in varchar2,
    in_location in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_lotno    in varchar2,
    in_qty      in number,
    in_uom      in varchar2,
    in_user     in varchar2,
    in_opcode   in number,
    out_error   out varchar2,
    out_message out varchar2)
is
   cursor c_slp(p_lpid varchar2) is
      select facility, location, status, orderid, shipid, item, lotnumber,
             quantity, unitofmeasure, rowid
         from shippingplate
         where lpid = p_lpid;
   sp c_slp%rowtype;
   cursor c_orc(p_lpid varchar2) is
      select rowid
      from ordercheck
      where orderid = sp.orderid
        and shipid = sp.shipid
        and lpid = p_lpid
        and entitem = in_item
        and nvl(entlot, '(none)') = nvl(in_lotno, '(none)')
        and entuom = in_uom;
   orc c_orc%rowtype;
   shlpid plate.lpid%type;
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   msg varchar(80);
   rowfound boolean;
begin
   out_error := 'N';
   out_message := null;

   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);
   if (msg is not null) then
      out_error := 'Y';
      out_message := msg;
      return;
   end if;

   if (lptype = '?') then
      out_error := 'Y';
      out_message := 'Unknown plate';
      return;
   end if;

   if (lptype = 'DP') then
      out_error := 'Y';
      out_message := 'LP is deleted';
      return;
   end if;

   if (lptype = 'XP') then
      shlpid := xrefid;
      lptype := xreftype;
   elsif (lptype = 'PA') then
      shlpid := nvl(xrefid, in_lpid);
      lptype := nvl(xreftype, lptype);
   else
      shlpid := in_lpid;
   end if;

   if (lptype not in ('C', 'F', 'M', 'P')) then
      out_error := 'Y';
      out_message := 'Not an outbound plate type';
      return;
   end if;

   if ((lptype in ('F', 'P')) and (nvl(toptype, '?') = 'C')) then
      out_error := 'Y';
      out_message := 'Use carton LP';
      return;
   end if;

   if ((lptype in ('F', 'P')) and (nvl(toptype, '?') = 'M')) then
      out_error := 'Y';
      out_message := 'Use master LP';
      return;
   end if;

   open c_slp(shlpid);
   fetch c_slp into sp;
   close c_slp;

   if ((sp.facility != in_facility) or (sp.location != in_location)) then
      out_message := 'Not at location';
      return;
   end if;

   if ((sp.orderid != in_orderid) or (sp.shipid != in_shipid)) then
      out_error := 'Y';
      out_message := 'Not for order';
      return;
   end if;

   if (sp.status != 'S') then
      out_error := 'Y';
      out_message := 'Not staged';
      return;
   end if;

   if (lptype in ('C', 'M')) then
      select nvl(sum(quantity), 0)
         into sp.quantity
         from shippingplate
         where custid = in_custid
           and item = in_item
           and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and unitofmeasure = in_uom
           and type in ('F','P')
         start with rowid = sp.rowid
         connect by prior lpid = parentlpid;
      sp.item := in_item;
      sp.lotnumber := in_lotno;
      sp.unitofmeasure := in_uom;
   end if;

   open c_orc(shlpid);
   fetch c_orc into orc;
   rowfound := c_orc%found;
   close c_orc;

   if rowfound then
     if (in_opcode = OP_INSERT) then
        out_error := 'D';
      elsif (in_opcode = OP_DELETE) then
         delete ordercheck
           where rowid = orc.rowid;
      else
          update ordercheck
            set lpitem = sp.item,
                lplot = sp.lotnumber,
                lpqty = sp.quantity,
                lpuom = sp.unitofmeasure,
                entqty = in_qty,
                lastuser = in_user,
                lastupdate = sysdate
           where rowid = orc.rowid;
       end if;
  else
     if (in_opcode = OP_INSERT) then
        insert into ordercheck
            (facility, location, orderid, shipid, lpid, lpitem,
             lplot, lpqty, lpuom, entlpid, entitem, entlot,
             entqty, entuom, lastuser, lastupdate, complete)
         values
            (sp.facility, sp.location, sp.orderid, sp.shipid, shlpid, sp.item,
             sp.lotnumber, sp.quantity, sp.unitofmeasure, in_lpid, in_item, in_lotno,
             in_qty, in_uom, in_user, sysdate, 'N');
      else
        out_message := 'LP not entered';
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end check_plate;

procedure order_check_required (
  in_orderid in number,
  in_shipid in number,
  out_message out varchar2
)
is
  v_count number;
  v_qty2check number;
begin
  out_message := 'OKAY';
  select count(1) into v_count
  from ordercheck
  where orderid = in_orderid and shipid = in_shipid
    and nvl(complete, 'N') = 'Y';
  if (v_count > 0) then
    return;
  end if;
  select nvl(zcord.cons_qty2check(in_orderid, in_shipid),0)  into v_qty2check
  from dual;
  if (v_qty2check > 0) then
    out_message := 'Order Check Required';
  end if;
end order_check_required;

end zorderchk;
/

show errors package body zorderchk;
exit;
