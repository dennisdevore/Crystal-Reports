--
-- $Id$
--
set serveroutput on
declare

type item_status is record (
     item       custitem.item%type,
     type       char(1),
     serial     char(1),
     user1      char(1),
     user2      char(1),
     user3      char(1)
);

type item_statustbl is table of item_status
     index by binary_integer;

item_tbl item_statustbl;

CURSOR C_ITEMS(in_custid varchar2)
IS
 select *
   from custitemview I
  where I.custid = in_custid;

CURSOR C_PLATES(in_custid varchar2)
IS
 select *
   from plate
  where custid = in_custid
    and parentlpid is null;

CURSOR C_PLTITEMS(in_lpid varchar2)
IS
 select item, unitofmeasure uom, invstatus, inventoryclass, lotnumber,
        status, sum(quantity) qty, sum(qtyrcvd) qtyrcvd, min(lastcountdate) lcd
   from plate
  where parentlpid = in_lpid
  group by item, unitofmeasure, invstatus, inventoryclass, lotnumber, 
           status;

NP C_PLTITEMS%rowtype;

ix integer;

is_ok char;
has_item char;


qty number(7);

errno number;
errmsg varchar2(200);

FUNCTION check_item
(in_item in varchar2
) return char
is
begin

   for ix in 1..item_tbl.count loop
      if in_item = item_tbl(ix).item then
         return item_tbl(ix).type;
      end if;
   end loop;

   return 'N';

end check_item;


procedure prt(in_text in varchar2 := null)
is

datestr varchar2(17);

begin

  select to_char(sysdate, 'mm/dd/yy hh24:mi:ss')
    into datestr
    from dual;
--  dbms_output.put_line(datestr || ' ' || in_text);
  dbms_output.put_line('> '||in_text);

end prt;


begin



   dbms_output.enable(1000000);


-- Create table of whats what
   for crec in C_ITEMS('&&1') loop
     ix := item_tbl.count + 1;
     item_tbl(ix).item := crec.item;
     item_tbl(ix).type := 'N';
     item_tbl(ix).serial := 'N';
     item_tbl(ix).user1 := 'N';
     item_tbl(ix).user2 := 'N';
     item_tbl(ix).user3 := 'N';

     if (crec.serialrequired != 'Y'
           and crec.serialasncapture = 'Y') then
       item_tbl(ix).type := 'Y';
       item_tbl(ix).serial := 'Y';
     end if;
     if (crec.user1required != 'Y'
           and crec.user1asncapture = 'Y') then
       item_tbl(ix).type := 'Y';
       item_tbl(ix).user1 := 'Y';
     end if;
     if (crec.user2required != 'Y'
           and crec.user2asncapture = 'Y') then
       item_tbl(ix).type := 'Y';
       item_tbl(ix).user2 := 'Y';
     end if;
     if (crec.user3required != 'Y'
           and crec.user3asncapture = 'Y') then
       item_tbl(ix).type := 'Y';
       item_tbl(ix).user3 := 'Y';
     end if;


   end loop;

-- check for Plates with no parents

   for crec in C_PLATES('&&1') loop
       is_ok := 'Y';
       has_item := 'N';
       if crec.type = 'MP' then
          prt('LPID:'||crec.lpid||' Type:'||crec.type);
          zasn.check_plate(crec.lpid,'Y',errno, errmsg);
          prt('      errno:'||errno||' errmsg:'||errmsg);


          if errno = -2310.5 then
             -- zasn.consolidate_plate(crec.lpid, 'RON', errno, errmsg);
            prt(' FIX  errno:'||errno||' errmsg:'||errmsg);

          end if;
          prt(' ');
       end if;
   end loop;

/*
   for ix in 1..item_tbl.count loop
       prt('Item:'||item_tbl(ix).item||'/'||item_tbl(ix).type);
       if check_item(item_tbl(ix).item) = 'Y' then
          prt('   This is one that needs checking');
          prt('      SN:'||item_tbl(ix).serial
           ||' U1:'||item_tbl(ix).user1
           ||' U2:'||item_tbl(ix).user2
           ||' U3:'||item_tbl(ix).user3);

       end if;
   end loop;
*/

-- For fix
--     Multiple
--      UOM
--      Item
--      Qty
--     User1 User2 User3 SN
--     

end;

/

