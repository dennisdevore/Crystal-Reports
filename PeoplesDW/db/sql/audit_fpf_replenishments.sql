/*
*  checks to see if any flex pick fronts need replenishing.  If so,
*  then generates a replenishment request
*/
set serveroutput on;

declare
l_locid location.locid%type;
l_fromtasks pls_integer;
l_totasks pls_integer;
l_fromtasksqty pls_integer;
l_totasksqty pls_integer;
l_plates pls_integer;
l_platesqty pls_integer;
l_minqty pls_integer;
l_wave pls_integer;
l_repl_cnt pls_integer := 0;
l_baseuom custitem.baseuom%type;
out_errorno pls_integer;
out_msg varchar2(4000);

begin

for wv in (select wave, fpf_minqty, fpf_minuom
             from waves
			where facility = 'D2'
        and wavestatus = '3'
        and use_flex_pick_fronts_yn = 'Y')
loop
  for obj in
    (select distinct oh.fromfacility, oh.custid, od.item,
       lpad(nvl(trim(ci.stacking_factor),'ZZZZZZZZZZZZ'),12,' ') stacking_factor
    from orderhdr oh, orderdtl od, custitem ci
     where oh.wave = wv.wave
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and ci.item = od.item
     order by lpad(nvl(trim(ci.stacking_factor),'ZZZZZZZZZZZZ'),12,' '), od.item)
  loop

    begin
      select locid
       into l_locid
       from location
      where facility = obj.fromfacility
        and nvl(flex_pick_front_wave,0) = wv.wave
        and flex_pick_front_item = obj.item;
    exception when others then
       l_locid := '?';
    end;

    begin
      select count(1), nvl(sum(qty),0)
        into l_fromtasks, l_fromtasksqty
        from subtasks
       where facility = obj.fromfacility
         and fromloc = l_locid;
    exception when others then
        l_fromtasks := 0;
        l_fromtasksqty := 0;
    end;
    
    begin
        select count(1), nvl(sum(qty),0)
        into l_totasks, l_totasksqty
        from subtasks
       where facility = obj.fromfacility
         and toloc = l_locid;
    exception when others then
        l_totasks := 0;
        l_totasksqty := 0;
    end;

    begin
      select count(1), nvl(sum(quantity),0)
        into l_plates, l_platesqty
        from plate
       where facility = obj.fromfacility
         and custid = obj.custid
         and item = obj.item
         and location = l_locid
         and type = 'PA';
    exception when others then
      l_plates := 0;
      l_platesqty := 0;
    end;
    
    begin
      select baseuom
        into l_baseuom
        from custitem
       where custid = obj.custid
         and item = obj.item;
    exception when others then
      l_baseuom := 'EA';
    end;
    
    if l_baseuom = wv.fpf_minuom then
      l_minqty := wv.fpf_minqty;
    else
      zbut.translate_uom(obj.custid,obj.item,wv.fpf_minqty,
           wv.fpf_minuom,l_baseuom,l_minqty,out_msg);
    end if;
    
    dbms_output.put_line(wv.wave || ' ' ||obj.custid || ' ' ||
            obj.item || ' ' || l_locid || ' ' ||
            l_fromtasks || '-' || l_fromtasksqty || ' ' ||
            l_totasks || '-' || l_totasksqty || ' ' ||
            l_plates || '-' || l_platesqty || ' ' || l_minqty);
                
    if (l_locid != '?') and
       (l_fromtasksqty > (l_totasksqty + l_platesqty)) and
       (l_platesqty < l_minqty) then
      zrp.send_replenish_msg_no_commit('REPLPP', obj.fromfacility, obj.custid, obj.item,
          l_locid, 'SYNAPSE', 'Y', out_errorno, out_msg);
      commit;
      zut.prt('Request repl: ' || out_errorno || ' ' || out_msg);
      l_repl_cnt := l_repl_cnt + 1;
    end if;
    
  end loop;
  
end loop;

zut.prt('repl requested: ' || l_repl_cnt);

end;
/
exit;