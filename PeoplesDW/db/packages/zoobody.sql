create or replace package body alps.zoperationaloverview as
--
-- $Id: zoobody.sql 8653 2012-07-12 20:37:40Z eric $
--


-- Private functions


function uospct
   (in_facility in varchar2)
return number
is
   l_howmany number;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_cnt pls_integer := 0;
   l_locused number;
   l_facused number := 0;
begin

   for loc in (select locid, unitofstorage uos
                  from location
                  where facility = in_facility
                    and loctype in ('STO','PF')) loop

      l_locused := 0;
      for lp in (select item, custid, unitofmeasure uom, nvl(sum(quantity),0) qty
                  from plate
                  where facility = in_facility
                    and location = loc.locid
                    and type = 'PA'
                  group by item, custid, unitofmeasure) loop

         zput.get_uoms_in_uos (lp.custid, lp.item, lp.uom, loc.uos, l_howmany, l_err, l_msg);

         if l_howmany != 0 then
            l_locused := l_locused + (lp.qty / l_howmany);
         end if;
      end loop;

      l_cnt := l_cnt + 1;
      l_facused := l_facused + l_locused;
   end loop;

   if l_cnt > 0 then
      l_facused := (l_facused / l_cnt) * 100;
   end if;

   return l_facused;

end uospct;


-- Private procedures


procedure rangetotal
   (in_facilities          in varchar2,
    in_custids             in varchar2,
    in_begdate             in date,
    in_enddate             in date,
    out_message            out varchar2,
    out_closedreceipts     out number,
    out_closedloads        out number,
    out_inboundunits       out number,
    out_inboundhours       out number,
    out_ordersshipped      out number,
    out_loadsshipped       out number,
    out_outboundunits      out number,
    out_outboundhours      out number,
    out_receiptrevenue     out number,
    out_renewalrevenue     out number,
    out_accessorialrevenue out number,
    out_miscrevenue        out number,
    out_creditrevenue      out number)
is
   type load_r is record (
      loadtype loads.loadtype%type,
      total number(10));
   type load_t is table of load_r index by pls_integer;

   l_load load_t;
   i pls_integer;
   l_where varchar2(2048);
begin
   out_message := 'OKAY';

   l_where := ' where capturedate between ''' || in_begdate || ''' and ''' || in_enddate || ''''
             || ' and facility in (''' || replace(in_facilities, ',', ''',''') || ''')'
             || ' and custid in (''' || replace(in_custids, ',', ''',''') || ''')';

   execute immediate
      'select nvl(sum(closedreceipts),0),'
         || ' nvl(sum(inboundunits),0),'
         || ' nvl(sum(inboundhours),0),'
         || ' nvl(sum(ordersshipped),0),'
         || ' nvl(sum(outboundunits),0),'
         || ' nvl(sum(outboundhours),0),'
         || ' nvl(sum(receiptrevenue),0),'
         || ' nvl(sum(renewalrevenue),0),'
         || ' nvl(sum(accessorialrevenue),0),'
         || ' nvl(sum(miscrevenue),0),'
         || ' nvl(sum(creditrevenue),0)'
         || ' from oodailytotals' || l_where
      into out_closedreceipts,
           out_inboundunits,
           out_inboundhours,
           out_ordersshipped,
           out_outboundunits,
           out_outboundhours,
           out_receiptrevenue,
           out_renewalrevenue,
           out_accessorialrevenue,
           out_miscrevenue,
           out_creditrevenue;

   execute immediate
      'select LD.loadtype, count(1) from'
         || ' (select loadno, loadtype, count(*)'
         || '  from oodailyloads' || l_where
         || '  group by loadno, loadtype'
         || '  having count(*) between 1 and '
         || to_char(length(in_custids)-length(replace(in_custids, ',', ''))+1) || ') LD'
         || ' group by LD.loadtype'
         || ' order by LD.loadtype' bulk collect into l_load;

   out_closedloads := 0;
   out_loadsshipped := 0;
   for i in 1..l_load.count loop
      if l_load(i).loadtype = 'I' then
         out_closedloads := l_load(i).total;
      else
         out_loadsshipped := l_load(i).total;
      end if;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end rangetotal;


procedure add_today
  (in_facility           in varchar2,
   in_custid             in varchar2,
   in_closedreceipts     in number,
   in_inboundunits       in number,
   in_inboundhours       in number,
   in_ordersshipped      in number,
   in_outboundunits      in number,
   in_outboundhours      in number,
   in_receiptrevenue     in number,
   in_renewalrevenue     in number,
   in_accessorialrevenue in number,
   in_miscrevenue        in number,
   in_creditrevenue      in number)
is
  sendstatus integer;
  l_msg varchar2(400);
  v_stop_enqueue systemdefaults.defaultvalue%type;
begin

  begin
    select defaultvalue into v_stop_enqueue
    from systemdefaults
    where defaultid = 'STOPOODAILYENQUEUE';
  exception
    when others then
      v_stop_enqueue := 'Y';
  end;
  
  if (nvl(v_stop_enqueue,'Y') = 'Y') then 
    return;
  end if;
  
  l_msg := to_char(sysdate,'YYYYMMDD') || chr(9) ||
         in_facility || chr(9) ||
         in_custid || chr(9) ||
         to_char(in_closedreceipts) || chr(9) ||
         to_char(in_inboundunits) || chr(9) ||
         to_char(in_inboundhours) || chr(9) ||
         to_char(in_ordersshipped) || chr(9) ||
         to_char(in_outboundunits) || chr(9) ||
         to_char(in_outboundhours) || chr(9) ||
         to_char(in_receiptrevenue) || chr(9) ||
         to_char(in_renewalrevenue) || chr(9) ||
         to_char(in_accessorialrevenue) || chr(9) ||
         to_char(in_miscrevenue) || chr(9) ||
         to_char(in_creditrevenue) || chr(9);
  
  sendstatus := zqm.send(OODAILY_DEFAULT_QUEUE,'ADD',l_msg,1,null);

end add_today;


-- Public procedures


procedure pctfull
   (in_facilities in varchar2,
    out_pctfull   out number,
    out_message   out varchar2)
is
   type facility_r is record (
      fac facility.facility%type,            -- can't use facility here else oracle complains
      storage facility.storage%type);
   type facility_t is table of facility_r index by pls_integer;
   l_fac facility_t;

   cursor c_cube(p_facility varchar2) is
      select round((sum((select nvl(sum(quantity * zci.item_cube(custid, item, unitofmeasure)),0)
                  from plate
                  where facility = L.facility
                    and location = L.locid
                    and type = 'PA'))
               / sum(nvl(U.depth*U.width*U.height,0)/1728)) * 100.0, 4)
         from location L, unitofstorage U
         where L.facility = p_facility
           and L.loctype in ('STO','PF')
           and U.unitofstorage = L.unitofstorage;

   cursor c_weight(p_facility varchar2) is
      select round((sum((select nvl(sum(weight),0)
                  from plate
                  where facility = L.facility
                    and location = L.locid
                    and type = 'PA'))
               / sum(L.weightlimit)) * 100.0, 4)
         from location L
         where L.facility = p_facility
           and L.loctype in ('STO','PF');

   i pls_integer;
   l_facpct number(10,4);
   l_totpct number(10,4) := 0;
begin
   out_pctfull := 0;
   out_message := 'OKAY';

   execute immediate
      'select facility, storage from facility where facility in ('''
            || replace(in_facilities, ',', ''',''')
            || ''')' bulk collect into l_fac;

   for i in 1..l_fac.count loop

      if l_fac(i).storage = 'C' then
         open c_cube(l_fac(i).fac);
         fetch c_cube into l_facpct;
         close c_cube;

      elsif l_fac(i).storage = 'U' then
         l_facpct := uospct(l_fac(i).fac);

      else
         open c_weight(l_fac(i).fac);
         fetch c_weight into l_facpct;
         close c_weight;

      end if;

      l_totpct := l_totpct + l_facpct;
   end loop;

   if l_totpct != 0 then
      out_pctfull := l_totpct / l_fac.count;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end pctfull;


procedure closereceipt
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_units     in number)
is
begin
   add_today(in_facility, in_custid, 1, in_units, 0, 0, 0, 0, 0, 0, 0, 0, 0);
exception
   when OTHERS then
      null;
end closereceipt;


procedure inboundactivity
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_hours     in number)
is
begin
   add_today(in_facility, in_custid, 0, 0, in_hours, 0, 0, 0, 0, 0, 0, 0, 0);
exception
   when OTHERS then
      null;
end inboundactivity;


procedure shiporder
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_units     in number)
is
begin
   add_today(in_facility, in_custid, 0, 0, 0, 1, in_units, 0, 0, 0, 0, 0, 0);
exception
   when OTHERS then
      null;
end shiporder;


procedure outboundactivity
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_hours     in number)
is
begin
   add_today(in_facility, in_custid, 0, 0, 0, 0, 0, in_hours, 0, 0, 0, 0, 0);
exception
   when OTHERS then
      null;
end outboundactivity;


procedure addrevenue
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_invtype   in varchar2,
    in_amount    in number)
is
begin
   if in_invtype = 'R' then
      add_today(in_facility, in_custid, 0, 0, 0, 0, 0, 0, in_amount, 0, 0, 0, 0);
   elsif in_invtype = 'S' then
      add_today(in_facility, in_custid, 0, 0, 0, 0, 0, 0, 0, in_amount, 0, 0, 0);
   elsif in_invtype = 'A' then
      add_today(in_facility, in_custid, 0, 0, 0, 0, 0, 0, 0, 0, in_amount, 0, 0);
   elsif in_invtype = 'M' then
      add_today(in_facility, in_custid, 0, 0, 0, 0, 0, 0, 0, 0, 0, in_amount, 0);
   else
      add_today(in_facility, in_custid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, in_amount);
   end if;
exception
   when OTHERS then
      null;
end addrevenue;


procedure closeload
   (in_facility  in varchar2,
    in_loadno    in number,
    in_loadtype  in varchar2)
is
   type custid_t is table of customer.custid%type index by pls_integer;
   l_cus custid_t;
   i pls_integer;
   l_loadtype char(1);
   l_date date;
begin
   if in_loadtype in ('INC','OUTC') then
      l_loadtype := substr(in_loadtype,1,1);
      l_date := trunc(sysdate);

      select distinct custid
         bulk collect into l_cus
         from orderhdr
         where loadno = in_loadno;

      for i in 1..l_cus.count loop

         insert into oodailyloads
            (capturedate,
             facility,
             custid,
             loadno,
             loadtype)
         values
            (l_date,
             in_facility,
             l_cus(i),
             in_loadno,
             l_loadtype);
      end loop;
   end if;

exception
   when OTHERS then
      null;
end closeload;


procedure gettotals
   (in_facilities          in varchar2,
    in_custids             in varchar2,
    in_timeframe           in varchar2,
    out_message            out varchar2,
    out_closedreceipts     out number,
    out_closedloads        out number,
    out_inboundunits       out number,
    out_inboundhours       out number,
    out_ordersshipped      out number,
    out_loadsshipped       out number,
    out_outboundunits      out number,
    out_outboundhours      out number,
    out_receiptrevenue     out number,
    out_renewalrevenue     out number,
    out_accessorialrevenue out number,
    out_miscrevenue        out number,
    out_creditrevenue      out number)
is
   l_timeframe varchar2(10);
   l_begdate date;
   l_enddate date;
begin
   out_message := 'OKAY';

   l_timeframe := lower(in_timeframe);
   if l_timeframe = 't' then
      l_begdate := trunc(sysdate);
      l_enddate := trunc(sysdate);

   elsif l_timeframe = 'w' then
      l_begdate := trunc(sysdate+(1-to_char(sysdate,'d')));
      l_enddate := trunc(sysdate);

   elsif l_timeframe = 'm' then
      l_begdate := trunc(sysdate,'mm');
      l_enddate := trunc(sysdate);

   elsif l_timeframe = 'q' then
      l_begdate := trunc(sysdate,'q');
      l_enddate := trunc(sysdate);

   elsif l_timeframe = 'y' then
      l_begdate := trunc(sysdate,'yyyy');
      l_enddate := trunc(sysdate);

   elsif l_timeframe = 'pt' then
      l_begdate := trunc(sysdate-1);
      l_enddate := trunc(sysdate-1);

   elsif l_timeframe = 'pw' then
      l_begdate := trunc(sysdate-to_char(sysdate,'d')-6);
      l_enddate := trunc(sysdate-to_char(sysdate,'d'));

   elsif l_timeframe = 'pm' then
      l_enddate := trunc(sysdate,'mm')-1;
      l_begdate := trunc(l_enddate,'mm');

   elsif l_timeframe = 'pq' then
      l_enddate := trunc(sysdate,'q')-1;
      l_begdate := trunc(l_enddate,'q');

   elsif l_timeframe = 'py' then
      l_enddate := trunc(sysdate,'yyyy')-1;
      l_begdate := trunc(l_enddate,'yyyy');

   else
      out_message := 'Invalid timeframe';
      return;
   end if;

   rangetotal(in_facilities,
       in_custids,
       l_begdate,
       l_enddate,
       out_message,
       out_closedreceipts,
       out_closedloads,
       out_inboundunits,
       out_inboundhours,
       out_ordersshipped,
       out_loadsshipped,
       out_outboundunits,
       out_outboundhours,
       out_receiptrevenue,
       out_renewalrevenue,
       out_accessorialrevenue,
       out_miscrevenue,
       out_creditrevenue);

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end gettotals;


procedure getaverage
   (in_facilities          in varchar2,
    in_custids             in varchar2,
    in_timeframe           in varchar2,
    in_avg_months          in number,
    out_message            out varchar2,
    out_closedreceipts     out number,
    out_closedloads        out number,
    out_inboundunits       out number,
    out_inboundhours       out number,
    out_ordersshipped      out number,
    out_loadsshipped       out number,
    out_outboundunits      out number,
    out_outboundhours      out number,
    out_receiptrevenue     out number,
    out_renewalrevenue     out number,
    out_accessorialrevenue out number,
    out_miscrevenue        out number,
    out_creditrevenue      out number)
is
   l_timeframe varchar2(10);
   l_begdate date;
   l_enddate date;
   l_days pls_integer;
   l_divisor number;
begin
   out_message := 'OKAY';

   if in_avg_months <= 0 then
      out_message := 'Invalid average option';
      return;
   end if;

   l_enddate := trunc(sysdate,'mm')-1;
   l_begdate := trunc(add_months(l_enddate, 1-in_avg_months),'mm');
   l_days := l_enddate - l_begdate + 1;

   l_timeframe := lower(in_timeframe);
   if l_timeframe = 't' then
      l_divisor := l_days;

   elsif l_timeframe = 'w' then
      l_divisor := l_days / 7;

   elsif l_timeframe = 'm' then
      l_divisor := in_avg_months;

   elsif l_timeframe = 'q' then
      l_divisor := in_avg_months / 3;

   elsif l_timeframe = 'y' then
      l_divisor := in_avg_months / 12;

   else
      out_message := 'Invalid timeframe';
      return;
   end if;

   rangetotal(in_facilities,
       in_custids,
       l_begdate,
       l_enddate,
       out_message,
       out_closedreceipts,
       out_closedloads,
       out_inboundunits,
       out_inboundhours,
       out_ordersshipped,
       out_loadsshipped,
       out_outboundunits,
       out_outboundhours,
       out_receiptrevenue,
       out_renewalrevenue,
       out_accessorialrevenue,
       out_miscrevenue,
       out_creditrevenue);

   out_closedreceipts := out_closedreceipts / l_divisor;
   out_closedloads := out_closedloads / l_divisor;
   out_inboundunits := out_inboundunits / l_divisor;
   out_inboundhours := out_inboundhours / l_divisor;
   out_ordersshipped := out_ordersshipped / l_divisor;
   out_loadsshipped := out_loadsshipped / l_divisor;
   out_outboundunits := out_outboundunits / l_divisor;
   out_outboundhours := out_outboundhours / l_divisor;
   out_receiptrevenue := out_receiptrevenue / l_divisor;
   out_renewalrevenue := out_renewalrevenue / l_divisor;
   out_accessorialrevenue := out_accessorialrevenue / l_divisor;
   out_miscrevenue := out_miscrevenue / l_divisor;
   out_creditrevenue := out_creditrevenue / l_divisor;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end getaverage;

procedure getothercounts
   (in_facilities         in varchar2,
    in_customers          in varchar2,
    out_ob_unshipped      out number,
    out_ob_active         out number,
    out_ib_active         out number,
    out_ob_shipped_late   out number)
is
    l_facilities   varchar2(4000);
    l_customers    varchar2(4000);
    l_sql          varchar2(1024);
begin
  l_facilities := ''''||replace(in_facilities, ',' , ''',''')||'''';
  l_customers  := ''''||replace(in_customers, ',' , ''',''')||'''';

  -- Outbound Unshipped count
  l_sql := 'select count(o.orderid) ' ||
           'from orderhdr o ' ||
           'where o.orderstatus < ''9'' ' ||
           'and o.ordertype in (''O'', ''V'') ' ||
           'and o.dateshipped is null ';
           
  if in_facilities <> '*' then
    l_sql :=  l_sql || 'and o.fromfacility in ('|| l_facilities||') ';
  end if;  
  if in_customers <> '*' then
    l_sql :=  l_sql || 'and o.custid in ('|| l_customers||') ';
  end if;  
   
  execute immediate l_sql into out_ob_unshipped;


  -- Active Inbound
  l_sql := 'select count(o.orderid) ' ||
           'from orderhdr o ' ||
           'where o.orderstatus = ''A'' ' ||
           'and o.ordertype in (''R'',''C'',''Q'') ';

  if in_facilities <> '*' then
    l_sql :=  l_sql || 'and o.fromfacility in ('|| l_facilities||') ';
  end if;  
  if in_customers <> '*' then
    l_sql :=  l_sql || 'and o.custid in ('|| l_customers||') ';
  end if;  
           
  execute immediate l_sql into out_ib_active;


  -- Active Outbound
  l_sql := 'select count(o.orderid) ' ||
           'from orderhdr o' ||
           'where o.orderstatus in (''4'',''5'',''6'',''7'',''8'')' ||
           'and o.ordertype in (''O'', ''V'') ';
           
  if in_facilities <> '*' then
    l_sql :=  l_sql || 'and o.fromfacility in ('|| l_facilities||') ';
  end if;  
  if in_customers <> '*' then
    l_sql :=  l_sql || 'and o.custid in ('|| l_customers||') ';
  end if;  
           
  execute immediate l_sql into out_ob_active;
     
 -- Orders shipped late
  l_sql := 'select count(o.orderid) ' ||
           'from orderhdr o ' ||
           'where o.orderstatus = ''9'' ' ||
           'and o.ordertype in (''O'', ''V'') ' ||
           'and o.dateshipped > o.shipdate ';
           
  if in_facilities <> '*' then
    l_sql :=  l_sql || 'and o.fromfacility in ('|| l_facilities||') ';
  end if;  
  if in_customers <> '*' then
    l_sql :=  l_sql || 'and o.custid in ('|| l_customers||') ';
  end if;  

  execute immediate l_sql into out_ob_shipped_late;     
  
exception
   when OTHERS then
     null;
end getothercounts;

procedure update_oodailytotals
  (in_capturedate        in date,
   in_facility           in varchar2,
   in_custid             in varchar2,
   in_closedreceipts     in number,
   in_inboundunits       in number,
   in_inboundhours       in number,
   in_ordersshipped      in number,
   in_outboundunits      in number,
   in_outboundhours      in number,
   in_receiptrevenue     in number,
   in_renewalrevenue     in number,
   in_accessorialrevenue in number,
   in_miscrevenue        in number,
   in_creditrevenue      in number)
is
begin

   update oodailytotals
      set closedreceipts = closedreceipts + nvl(in_closedreceipts,0),
          inboundunits = inboundunits + nvl(in_inboundunits,0),
          inboundhours = inboundhours + nvl(in_inboundhours,0),
          ordersshipped = ordersshipped + nvl(in_ordersshipped,0),
          outboundunits = outboundunits + nvl(in_outboundunits,0),
          outboundhours = outboundhours + nvl(in_outboundhours,0),
          receiptrevenue = receiptrevenue + nvl(in_receiptrevenue,0),
          renewalrevenue = renewalrevenue + nvl(in_renewalrevenue,0),
          accessorialrevenue = accessorialrevenue + nvl(in_accessorialrevenue,0),
          miscrevenue = miscrevenue + nvl(in_miscrevenue,0),
          creditrevenue = creditrevenue + nvl(in_creditrevenue,0)
      where capturedate = in_capturedate
        and facility = in_facility
        and custid = in_custid;

   if sql%rowcount = 0 then
      insert into oodailytotals
         (capturedate,
          facility,
          custid,
          closedreceipts,
          inboundunits,
          inboundhours,
          ordersshipped,
          outboundunits,
          outboundhours,
          receiptrevenue,
          renewalrevenue,
          accessorialrevenue,
          miscrevenue,
          creditrevenue)
      values
         (in_capturedate,
          in_facility,
          in_custid,
          nvl(in_closedreceipts,0),
          nvl(in_inboundunits,0),
          nvl(in_inboundhours,0),
          nvl(in_ordersshipped,0),
          nvl(in_outboundunits,0),
          nvl(in_outboundhours,0),
          nvl(in_receiptrevenue,0),
          nvl(in_renewalrevenue,0),
          nvl(in_accessorialrevenue,0),
          nvl(in_miscrevenue,0),
          nvl(in_creditrevenue,0));
   end if;
end update_oodailytotals;

end zoperationaloverview;
/

show errors package body zoperationaloverview;
exit;
