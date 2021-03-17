--
-- $Id: pimevents_trigger.sql
--
create or replace trigger pimevents_ad
after delete
on pimevents
for each row
declare
  currcount integer;
  t_orderid integer;
  t_shipid integer;
begin
 if nvl(:old.loadno, 0) <> 0 then
   select count(1) 
      into currcount
      from loads
     where loadno = :old.loadno and
       ((loadstatus <> 'R') and (loadstatus <> '9'));
  
   if currcount != 0 then  
     update loads
        set apptdate = null,
            lastuser = :old.lastuser,
            lastupdate = sysdate
      where loadno = :old.loadno;
    
     update orderhdr
        set apptdate = null,
            lastuser = :old.lastuser,
            lastupdate = sysdate
      where loadno = :old.loadno;
    end if;  
  else
    if (nvl(:old.ordershipid, 'x') <> 'x') then
      t_orderid := to_number(substr(:old.ordershipid, 1, instr(:old.ordershipid, '-') - 1));
      t_shipid := to_number(substr(:old.ordershipid, instr(:old.ordershipid, '-') + 1));
      update orderhdr
         set apptdate = null,
             lastuser = :old.lastuser,
             lastupdate = sysdate
       where orderid = t_orderid
         and shipid = t_shipid;
    end if;
  end if;               
end;
/

create or replace trigger pimevents_ai
after insert 
on pimevents
for each row
declare
  t_orderid integer;
  t_shipid integer;
begin
  if nvl(:new.loadno, 0) <> 0 then
	  update loads
		   set apptdate = :new.starttime,
           lastuser = :new.lastuser,
           lastupdate = :new.lastupdate
		 where loadno = :new.loadno;
			
		update orderhdr
		   set apptdate = :new.starttime,
           lastuser = :new.lastuser,
           lastupdate = :new.lastupdate
 		 where loadno = :new.loadno;
	else
    if (nvl(:new.ordershipid, 'x') <> 'x') then
      t_orderid := to_number(substr(:new.ordershipid, 1, instr(:new.ordershipid, '-') - 1));
      t_shipid := to_number(substr(:new.ordershipid, instr(:new.ordershipid, '-') + 1));
	    update orderhdr
		     set apptdate = :new.starttime,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
		   where orderid = t_orderid 
		     and shipid = t_shipid;
     end if;	    
	end if;
end;
/

create or replace trigger pimevents_au
after update
on pimevents
for each row
declare
  t_orderid integer;
  t_shipid integer;
  def_date date := to_date('200701010001', 'yyyymmddhh24mi'); 
begin
  if (nvl(:old.loadno, 0) <> nvl(:new.loadno, 0)) or
     (nvl(:old.ordershipid, 'x') <> nvl(:new.ordershipid, 'x')) or
     (nvl(:old.starttime, def_date) <> nvl(:new.starttime, def_date)) then
     
    if ((nvl(:old.loadno, 0) <> 0) and 
       (nvl(:old.loadno, 0) <> nvl(:new.loadno, 0))) then
      update loads
         set apptdate = null,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
       where loadno = :old.loadno;
       
       update orderhdr
          set apptdate = null,
              lastuser = :new.lastuser,
              lastupdate = :new.lastupdate
        where loadno = :old.loadno;
    end if;         
       
    if nvl(:new.loadno, 0) <> 0 then
      update loads
		     set apptdate = :new.starttime,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
		   where loadno = :new.loadno;
			
		  update orderhdr
		     set apptdate = :new.starttime,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
 		   where loadno = :new.loadno;
 		end if;
 		
 		if ((nvl(:old.ordershipid, 'x') <> 'x') and 
       (nvl(:old.ordershipid, 'x') <> nvl(:new.ordershipid, 'x'))) then
      t_orderid := to_number(substr(:old.ordershipid, 1, instr(:old.ordershipid, '-') - 1));
      t_shipid := to_number(substr(:old.ordershipid, instr(:old.ordershipid, '-') + 1)); 
      update orderhdr
         set apptdate = null,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
       where orderid = t_orderid
         and shipid = t_shipid;     
    end if;    
 		
 		if (nvl(:new.ordershipid, 'x') <> 'x') then
 		  t_orderid := to_number(substr(:new.ordershipid, 1, instr(:new.ordershipid, '-') - 1));
      t_shipid := to_number(substr(:new.ordershipid, instr(:new.ordershipid, '-') + 1));
	    update orderhdr
		     set apptdate = :new.starttime,
             lastuser = :new.lastuser,
             lastupdate = :new.lastupdate
		   where orderid = t_orderid 
		     and shipid = t_shipid;     		
 		end if;     
  end if;  
end;
/
