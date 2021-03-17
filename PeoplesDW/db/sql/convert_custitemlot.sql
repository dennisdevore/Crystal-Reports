set serveroutput on
set verify off

declare
errmsg varchar2(400);
action varchar2(400);
errno  integer;
warnno  integer;
rc integer;

tbool boolean;

in_func               varchar2(10);

in_abbrev           varchar2(20);

  adj1 varchar2(20);
  adj2 varchar2(20);

chkdate date;

l_mode varchar2(20);

old_custid varchar2(10);
new_custid varchar2(10);

old_item varchar2(50);
new_item varchar2(50); 

old_lot varchar2(30);
new_lot varchar2(30); 

l_lot varchar2(30); 

out_iscc number;

tcnt integer;



procedure prt(in_text in varchar2 := null)
is

datestr varchar2(17);

begin

  dbms_output.put_line(in_text);

end prt;

procedure dump_usage
IS
begin
    prt('Usage: @convert_custitemlot Mode OldCustid OldItem OldLot NewCustid NewItem NewLot');
    prt('.  OldCustid - Required conversion From Customer ID');
    prt('.  OldItem - Required conversion From Item');
    prt('.  OldLot - Required conversion From Lot');
    prt('.           or *NULL* to match only null lotnumbers');
    prt('.           or *ALL* to match all lotnumbers');
    prt('.  NewCustid - Required conversion To Customer ID');
    prt('.  NewItem - Required conversion To Item');
    prt('.  NewLot - Required conversion To Lot');
    prt('.           or *NULL* to set as null lotnumber');
    prt('.           or *ALL* to retain old lotnumber');
end;

begin

    dbms_output.enable(1000000);

    l_mode      := upper('&1');

    old_custid  := upper('&2');
    old_item    := upper('&3');
    old_lot     := upper('&4');

    new_custid  := upper('&5');
    new_item    := upper('&6');
    new_lot     := upper('&7');

    if nvl(l_mode,'x') not in('LIST','TEST','EXECUTE') then
        zut.prt('Mode must be either TEST, LIST or EXECUTE not '||l_mode);
        dump_usage;
        goto skip_it;
    end if;

    if old_custid is null then
        zut.prt('From custid cannot be null.');
        dump_usage;
        goto skip_it;
    end if;

    if old_item is null then
        zut.prt('From item cannot be null.');
        dump_usage;
        goto skip_it;
    end if;

    if old_lot is null then
        zut.prt('From lot must be provided.');
        dump_usage;
        goto skip_it;
    end if;


    if new_custid is null then
        zut.prt('To custid cannot be null.');
        dump_usage;
        goto skip_it;
    end if;

    if new_item is null then
        zut.prt('To item cannot be null.');
        dump_usage;
        goto skip_it;
    end if;

    if new_lot is null then
        zut.prt('To lot must be provided.');
        dump_usage;
        goto skip_it;
    end if;


    if old_custid = new_custid
     and old_item = new_item
     and (old_lot = new_lot
        or new_lot = '*ALL*') then
        zut.prt('That combination of from/to criteria will result in no changes.');
        goto skip_it;
    end if;


    if new_lot = '*NULL*' then
       new_lot := null;
    end if;

    tcnt := 0;

    select count(1)
      into tcnt
      from plate
     where custid = old_custid
       and item = old_item
       and status = 'U';

    if tcnt > 0 then
        zut.prt('Item:'||old_item||' has unreceived plates, status U');
        goto skip_it;
    end if;

    for cpl in (select *
                 from plate
                where custid = old_custid
                 and item = old_item
                 and nvl(lotnumber,'(null)') = 
                        decode(old_lot,'*NULL*', '(null)',
                                '*ALL*',nvl(lotnumber,'(null)'),
                                nvl(old_lot,'(null)'))
                 and type = 'PA')
    loop

        if nvl(new_lot,'x') = '*ALL*' then
            l_lot := cpl.lotnumber;
        else
            l_lot := new_lot;
        end if;

        if l_mode = 'LIST' then
            zut.prt('Convert plate:'||cpl.lpid
                ||' from '||old_custid||'/'||old_item||'/'||cpl.lotnumber
                ||' to '||new_custid||'/'||new_item||'/'||l_lot);
        else


        zia.inventory_adjustment
            (cpl.lpid
            ,new_custid
            ,new_item
            ,cpl.inventoryclass
            ,cpl.invstatus
            ,l_lot
            ,cpl.serialnumber
            ,cpl.useritem1
            ,cpl.useritem2
            ,cpl.useritem3
            ,cpl.location
            ,cpl.expirationdate
            ,cpl.quantity
            ,cpl.custid
            ,cpl.item
            ,cpl.inventoryclass
            ,cpl.invstatus
            ,cpl.lotnumber
            ,cpl.serialnumber
            ,cpl.useritem1
            ,cpl.useritem2
            ,cpl.useritem3
            ,cpl.location
            ,cpl.expirationdate
            ,cpl.quantity
            ,cpl.facility
            ,'PC' -- Per Customer
            ,'CONVERT'
            ,cpl.lasttask
            ,cpl.weight
            ,cpl.weight
            ,adj1
            ,adj2
            ,errno
            ,errmsg
            ,out_iscc);
        end if;


    if errno != 0 then
        zut.prt('Error on plate '||cpl.lpid||':'|| errno||'/'||errmsg);
    end if;

    end loop;

-- Try to fix the MP's
    for cpl in (select *
                 from plate
                where custid = old_custid
                 and item = old_item
                 and nvl(lotnumber,'(null)') = 
                        decode(old_lot,'*NULL*', '(null)',
                                '*ALL*',nvl(lotnumber,'(null)'),
                                nvl(old_lot,'(null)'))
                 and type = 'MP')
    loop
       if nvl(new_lot,'x') = '*ALL*' then
            l_lot := cpl.lotnumber;
       else
            l_lot := new_lot;
       end if;

      if l_mode = 'LIST' then
        zut.prt('Update Master:'||cpl.lpid);
      else
        update plate
           set custid = new_custid,
                 item = new_item,
                lotnumber = l_lot
         where lpid = cpl.lpid;
      end if;
    end loop;

  if upper('&&1') = 'EXECUTE' then
    commit;
  else
    rollback;
  end if;

<<skip_it>>
    null;

end;

/


exit;
