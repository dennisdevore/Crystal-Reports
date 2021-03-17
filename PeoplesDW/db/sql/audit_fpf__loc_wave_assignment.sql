/*
*  checks to see if any flex pick front wave assignments are 
*  associated with completed waves.  If so, then clears the fpf values
*  from the location record
*/
set serveroutput on;

declare
l_locid location.locid%type;
l_fromtasks pls_integer;
l_totasks pls_integer;
l_plates pls_integer;
l_wavestatus waves.wavestatus%type;
l_qty pls_integer;
l_wave pls_integer;
out_errorno pls_integer;
out_msg varchar2(4000);

begin

for obj in (select facility,locid,flex_pick_front_wave,
                   flex_pick_front_item,loctype
              from location
             where flex_pick_front_wave > 0
             order by locid)
loop

  begin
    select wavestatus
      into l_wavestatus
      from waves
     where wave = obj.flex_pick_front_wave;
  exception when others then
    l_wavestatus := '?';
  end;
  
  if l_wavestatus = '4' then
    zut.prt(obj.facility || ' ' || obj.locid || ' ' ||
            obj.flex_pick_front_wave || ' ' ||
            obj.flex_pick_front_item || ' ' || obj.loctype || ' ' ||
            l_wavestatus);

    update location
       set flex_pick_front_wave = 0,
           flex_pick_front_item = null,
           lastuser = 'SYNAPSE',
           lastupdate = sysdate
     where facility = obj.facility
       and locid = obj.locid;
  end if;
  
end loop;

end;
/
exit;