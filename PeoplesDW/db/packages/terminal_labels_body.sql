create or replace package body terminal_lbls as
--
-- $Id$
--


-- Private


procedure verify_order
   (in_key      in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_orderid out number,
    out_shipid  out number,
    out_msg     out varchar2)
is
   l_pos number;
   l_cnt pls_integer := 0;
begin
   out_msg := null;

   l_pos := instr(in_key, '|');
   if l_pos != 0 then
      out_orderid := to_number(substr(in_key, 1, l_pos-1));
      out_shipid := to_number(substr(in_key, l_pos+1));
      if out_shipid != 0 then
         select count(1) into l_cnt
            from orderhdr
            where orderid = out_orderid
              and shipid = out_shipid;
      else
         select count(1) into l_cnt
            from orderhdr
            where wave = out_orderid;
      end if;
   end if;

   if l_cnt = 0 then
      if in_func = 'Q' then
         out_msg := 'Order not found';
      end if;
      return;
   end if;

   if in_action not in ('A','P') then
      out_msg := 'Unsupported Action';
      return;
   end if;

   if in_func = 'Q' then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end verify_order;


-- Public


procedure addrlabel
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_pos number;
   l_obj varchar2(255);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_msg varchar2(80);
begin
   out_stmt := 'Unknown request';

   l_pos := instr(in_auxdata, '|');
   if l_pos != 0 then
      l_obj := upper(substr(in_auxdata, 1, l_pos-1));
      if l_obj = 'ORDER' then
         verify_order(substr(in_auxdata, l_pos+1), in_func, in_action, l_orderid,
               l_shipid, out_stmt);
      elsif l_obj = 'LOAD' then
         out_stmt := 'Load not supported';
      elsif l_obj = 'WAVE' then
         out_stmt := 'Wave not supported';
      end if;
   end if;

   if nvl(out_stmt, '?') = 'Continue' then
      out_stmt := 'select nvl(CN.name,OH.shiptoname) as shiptoname,'
            || ' nvl(CN.addr1,OH.shiptoaddr1) as shiptoaddr1,'
            || ' nvl(CN.addr2,OH.shiptoaddr2) as shiptoaddr2,'
            || ' nvl(CN.city,OH.shiptocity) as shiptocity,'
            || ' nvl(CN.state,OH.shiptostate) as shiptostate,'
            || ' nvl(CN.postalcode,OH.shiptopostalcode) as shiptopostal,'
            || ' FA.name as fa_name,'
            || ' FA.addr1 as fa_addr1,'
            || ' FA.addr2 as fa_addr2,'
            || ' FA.city as fa_city,'
            || ' FA.state as fa_state,'
            || ' FA.postalcode as fa_postal'
            || ' from orderhdr OH, facility FA, consignee CN'
            || ' where OH.orderid = ' || l_orderid
            || ' and OH.shipid = ' || l_shipid
            || ' and FA.facility = OH.fromfacility'
            || ' and CN.consignee (+) = OH.shipto';
   end if;

end addrlabel;


procedure conssku
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_stmt   out varchar2)
is
   l_pos number;
   l_obj varchar2(255);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type;
   l_msg varchar2(80);
   l_cnt pls_integer;
begin
   out_stmt := 'Unknown request';

   l_pos := instr(in_auxdata, '|');
   if l_pos != 0 then
      l_obj := upper(substr(in_auxdata, 1, l_pos-1));
      if l_obj = 'ORDER' then
         verify_order(substr(in_auxdata, l_pos+1), in_func, in_action, l_orderid,
               l_shipid, out_stmt);
      elsif l_obj = 'LOAD' then
         out_stmt := 'Load not supported';
      elsif l_obj = 'WAVE' then
         out_stmt := 'Wave not supported';
      end if;
   end if;

   if nvl(out_stmt, '?') = 'OKAY' then
      select count(1) into l_cnt
         from orderdtl
         where orderid = l_orderid
           and shipid = l_shipid
           and nvl(linestatus, '?') != 'X'
           and consigneesku is not null;
      if l_cnt = 0 then
         out_stmt := 'Nothing for order';
      end if;
   elsif nvl(out_stmt, '?') = 'Continue' then
      out_stmt := 'select OD.consigneesku'
            || ' from orderdtl OD, zseq Z'
            || ' where OD.orderid = ' || l_orderid
            || ' and OD.shipid = ' || l_shipid
            || ' and nvl(linestatus, ''?'') != ''X'''
            || ' and OD.consigneesku is not null'
            || ' and Z.seq <= OD.qtyorder'
            || ' order by OD.item';
   end if;

end conssku;


end terminal_lbls;
/

show errors package body terminal_lbls;
exit;
