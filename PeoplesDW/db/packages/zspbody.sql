create or replace package body alps.sp as
--
-- $Id$
--


procedure get_next_shippinglpid(out_shippinglpid    out varchar2,
                        out_message out varchar2) is
   cnt integer := 1;
   wk_lpid shippingplate.lpid%type;
begin
   out_message := null;

   while (cnt = 1)
   loop
      select lpad(shippinglpidseq.nextval, 14, '0') || 'S'
         into wk_lpid
         from dual;
      select count(1)
        into cnt
        from shippingplate
       where lpid = wk_lpid;
   end loop;
   out_shippinglpid := wk_lpid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_next_shippinglpid;


FUNCTION carrierused
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return varchar2 is

out_carrierused multishipdtl.carrierused%type;

begin

out_carrierused := '';

select carrierused
  into out_carrierused
  from multishipdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and cartonid = zmp.shipplate_mstrplt_label(in_lpid);

return out_carrierused;

exception when others then
  return out_carrierused;
end carrierused;

FUNCTION reason
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return varchar2 is

out_reason multishipdtl.reason%type;

begin

out_reason := '';

select reason
  into out_reason
  from multishipdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and cartonid = in_lpid;

return out_reason;

exception when others then
  return out_reason;
end reason;


FUNCTION cost
(in_orderid IN number
,in_shipid IN number
,in_lpid IN varchar2
) return number is

out_cost multishipdtl.cost%type;

begin

out_cost := 0;

select cost
  into out_cost
  from multishipdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and cartonid = in_lpid;

return out_cost;

exception when others then
  return out_cost;
end cost;

FUNCTION mp_count
(in_orderid IN number
,in_shipid IN number
) return number is

out_mp_count number(7);

begin

out_mp_count := 0;

select count(1)
  into out_mp_count
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and parentlpid is null
   and status = 'SH';

return out_mp_count;

exception when others then
  return out_mp_count;
end mp_count;

end sp;
/
show error package body alps.sp;
exit;
