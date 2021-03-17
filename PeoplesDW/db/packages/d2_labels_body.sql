create or replace package body d2_labels as

strDebugYN char(1) := 'Y';
strMsg varchar2(255);


procedure debugmsg(in_text varchar2) is

cntChar integer;

begin
if strDebugYN <> 'Y' then
  return;
end if;


cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;





procedure verify_order
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_orderid   out number,
    out_shipid    out number,
    out_order_cnt out number,
    out_label_cnt out number)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct orderid, shipid
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   l_lpid shippingplate.lpid%type := in_lpid;
begin
   out_orderid := 0;
   out_shipid := 0;
   out_order_cnt := 0;
   out_label_cnt := 0;
   debugmsg('l_lpid ' || l_lpid);
   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then
            out_order_cnt := 1;
            out_orderid := inp.orderid;
            out_shipid := inp.shipid;
            fetch c_inf into inp;
            if c_inf%found then  -- orderid/shipid not unique
               out_order_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         out_order_cnt := 1;
         out_orderid := inp.orderid;
         out_shipid := inp.shipid;
      end if;
      close c_inp;
   end if;

   if (in_func = 'Q') and (in_action = 'P') then
      select count(1) into out_label_cnt
         from LBL_ADDR_SHIP_D2K_VIEW
         where orderid = inp.orderid
           and shipid = inp.shipid;
   end if;

end verify_order;

-- public
procedure d2_plate
   (in_lpid       in varchar2,
    in_func       in varchar2,
    in_action     in varchar2,
    out_stmt      out varchar2)

is
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_order_cnt number;
   l_label_cnt number;
   l_retailer_cnt number;
   l_cnt pls_integer := 0;
   l_msg varchar2(1024);
   l_seq number;
   l_lpid varchar2(15);
   TYPE cur_type is REF CURSOR;
   crt cur_type;
   cmdSql varchar2(2000);
   cursor c_sp(p_orderid number, p_shipid number, p_lpid varchar2) is
      select distinct lpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and fromlpid = p_lpid;

begin
   out_stmt := null;
   debugmsg('plate_generic');
   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);

   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         else
            out_stmt := 'Order not unique';
         end if;
      end if;
      return;
   end if;
   if in_func = 'Q' then
      if l_retailer_cnt = 0 then
         out_stmt := 'Nothing for order';
      else
         out_stmt := 'OKAY';
      end if;
      return;
   end if;


   out_stmt := 'select * from LBL_ADDR_SHIP_D2K_VIEW ' ||
                'where lpid = ''' || in_lpid ||'''';


end d2_plate;


procedure d2_order
      (in_lpid   in varchar2,
       in_func   in varchar2,
       in_action in varchar2,
       out_stmt  out varchar2)
is
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_order_cnt number;
l_label_cnt number;
l_cnt pls_integer := 0;
lineCnt pls_integer := 0;
l_seq number;
l_qty number;
a_msg varchar2(180);
spCnt pls_integer;


begin
   out_stmt := null;
   debugmsg('d2_order');
   verify_order(in_lpid, in_func, in_action, l_orderid, l_shipid, l_order_cnt, l_label_cnt);
   if l_order_cnt != 1 then
      if in_func = 'Q' then
         if l_order_cnt = 0 then
            out_stmt := 'Order not found';
         else
            out_stmt := 'Order not unique';
         end if;
      end if;
      return;
   end if;


   if in_func = 'Q' then
      if in_action = 'A' then
         out_stmt := 'OKAY';
      elsif in_action = 'P' then
         if l_label_cnt = 0 then
            out_stmt := 'Nothing for order';
         else
            out_stmt := 'OKAY';
         end if;
      else
         out_stmt := 'Unsupported Action';
      end if;
      return;
   end if;

   out_stmt := 'select * from LBL_ADDR_SHIP_D2K_VIEW ' ||
                'where orderid = ' || l_orderid ||
                 ' and shipid = ' || l_shipid;

end d2_order;

end d2_labels;
/

show errors package body d2_labels;
exit;
