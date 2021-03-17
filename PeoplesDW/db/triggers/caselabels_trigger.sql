create or replace trigger caselabels_auid
before insert or update or delete
on caselabels
for each row
declare

cursor c_sp(in_lpid varchar2)
is
select lpid, fromlpid
  from shippingplate
 where lpid = in_lpid;

sp c_sp%rowtype;

l_lpid shippingplate.lpid%type;
l_sscc multishipdtl.sscc%type;

begin

    if :new.labeltype != 'CS' then
        return;
    end if;

    if (deleting) then
       l_lpid := :old.lpid;
       l_sscc := null;
    else
       l_lpid := :new.lpid;
       l_sscc := :new.barcode;
    end if;

    sp := null;
    open c_sp(l_lpid);
    fetch c_sp into sp;
    close c_sp;


    if sp.lpid is not null then
        update multishipdtl
          set sscc = l_sscc
         where cartonid = sp.fromlpid;
    end if;

end;
/
exit;

