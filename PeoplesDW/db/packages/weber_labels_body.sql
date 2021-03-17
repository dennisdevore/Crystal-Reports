create or replace package body weber_labels as
--
-- $Id$
--

-- Types
type itmrectype is record
        (item shippingplate.item%type,
    descr custitem.descr%type,
    abbrev custitem.abbrev%type,
    cntryof custitem.countryof%type,
    cntryds countrycodes.descr%type,
    sku orderdtl.consigneesku%type,
    pathc01 orderdtl.dtlpassthruchar01%type,
    pathc02 orderdtl.dtlpassthruchar02%type,
    pathc03 orderdtl.dtlpassthruchar03%type,
    pathc06 orderdtl.dtlpassthruchar06%type,
    pathc07 orderdtl.dtlpassthruchar07%type,
    pathc10 orderdtl.dtlpassthruchar10%type,
    pathc11 orderdtl.dtlpassthruchar11%type,
    pathc12 orderdtl.dtlpassthruchar12%type,
    pathn01 orderdtl.dtlpassthrunum01%type,
    upc varchar2(12),
    qtyea shippingplate.quantity%type);

type itmtbltype is table of itmrectype index by binary_integer;

type partcasetype is record
(
lpid shippingplate.lpid%type,
fromlpid shippingplate.fromlpid%type,
item shippingplate.item%type,
qtyavail shippingplate.quantity%type
);

type partcasetbltype is table of partcasetype index by binary_integer;

-- Global variables

itm_tbl itmtbltype;
pc_tbl partcasetbltype;
prev_item shippingplate.item%type;

-- Private


function case_qty(in_custid in varchar2,
                  in_item in varchar2)
return number
is
l_qty shippingplate.quantity%type := 0;

begin

  l_qty := zlbl.uom_qty_conv(in_custid, in_item, 1, 'CS', 'EA');
  if l_qty != 0 then
    return l_qty;
  else
    return 1;
  end if;

end case_qty;


function sscc18_code
   (in_custid   in varchar2,
    in_type     in varchar2,
    in_1stdigit in varchar2)
return varchar2
is
   cursor c_cust is
     select manufacturerucc
       from customer
      where custid = in_custid;
   manucc customer.manufacturerucc%type := null;
   sscc18 varchar2(20);
   seqname varchar2(30);
   seqval varchar2(9);
   ix integer;
   cc integer;
   cnt integer;
begin
   open c_cust;
   fetch c_cust into manucc;
   close c_cust;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   seqname := 'SSCC18_' || in_custid || '_SEQ';
   select count(1)
     into cnt
     from user_sequences
    where sequence_name = seqname;

   if cnt = 0 then
     execute immediate 'create sequence ' || seqname
                || ' increment by 1 start with 1 maxvalue 99999999 minvalue 1 nocache cycle';
   end if;

   execute immediate 'select lpad(' || seqname || '.nextval, 8, ''0'') from dual'
                into seqval;

   sscc18 := '00'|| lpad(substr(in_type, 1, 1), 1, '1') || manucc
                || lpad(substr(in_1stdigit, 1, 1), 1, '8') || seqval;

   cc := 0;
   for cnt in 1..19 loop
      ix := substr(sscc18, cnt, 1);
      if mod(cnt, 2) = 0 then
         cc := cc + ix;
      else
         cc := cc + (3 * ix);
      end if;
   end loop;

   cc := mod(10 - mod(cc, 10), 10);
   sscc18 := sscc18 || to_char(cc);
   return sscc18;

exception when others then
  return '00000000000000000000';
end sscc18_code;

procedure build_itm_tbl
   (in_lpid    in varchar2,
    in_type    in varchar2,
    in_orderid in number,
    in_shipid  in number,
    in_custid  in varchar2,
    in_item    in varchar2,
    in_qty     number)
is

cursor c_sp is
        select SP.item as item,
               CI.descr as descr,
               CI.abbrev as abbrev,
               CI.countryof as cntryof,
               CC.descr as cntryds,
               sum(SP.quantity) as quantity
          from shippingplate SP, custitem CI, countrycodes CC
         where SP.item is not null
           and SP.type != 'M'
           and SP.lpid in (select lpid from shippingplate
                            start with lpid = in_lpid
                          connect by prior lpid = parentlpid)
           and CI.custid = SP.custid
           and CI.item = SP.item
           and CI.countryof = CC.code(+)
         group by SP.Item,CI.descr,CI.abbrev,CI.countryof,CC.descr
         order by SP.Item,CI.descr,CI.abbrev,CI.countryof,CC.descr;

sp c_sp%rowtype;

cursor c_od(p_item in varchar2) is
        select consigneesku as sku,
               rtrim(dtlpassthruchar01) as pathc01,
               rtrim(dtlpassthruchar02) as pathc02,
               rtrim(dtlpassthruchar03) as pathc03,
               rtrim(dtlpassthruchar06) as pathc06,
               rtrim(dtlpassthruchar07) as pathc07,
               rtrim(dtlpassthruchar09) as pathc09,
               rtrim(dtlpassthruchar10) as pathc10,
               rtrim(dtlpassthruchar11) as pathc11,
               rtrim(dtlpassthruchar12) as pathc12,
               dtlpassthrunum01 as pathn01
          from orderdtl
         where orderid = in_orderid
           and shipid = in_shipid
           and item = p_item
         order by lotnumber;
od c_od%rowtype;

cursor c_ia(p_item in varchar2) is
        select itemalias
          from custitemalias
         where custid = in_custid
           and item = p_item
           and aliasdesc = 'UPC';

ia c_ia%rowtype;
l_found boolean;
i binary_integer;
qtyRemain pls_integer;
qtyCase pls_integer;
qtyLbl pls_integer;
cntCase pls_integer;

begin

itm_tbl.delete;
open c_sp;
   loop
      fetch c_sp into sp;
      exit when c_sp%notfound;
      if in_item is null or
         in_item = sp.item then
        i := itm_tbl.count+1;
        itm_tbl(i).item := sp.item;
        itm_tbl(i).descr := sp.descr;
        itm_tbl(i).abbrev := sp.abbrev;
        itm_tbl(i).cntryof := sp.cntryof;
        itm_tbl(i).cntryds := sp.cntryds;

        open c_od(sp.item);
        fetch c_od into od;
        l_found := c_od%found;
        close c_od;
        if l_found then
          itm_tbl(i).sku := od.sku;
          itm_tbl(i).pathc01 := od.pathc01;
          itm_tbl(i).pathc02 := od.pathc02;
          itm_tbl(i).pathc03 := od.pathc03;
          itm_tbl(i).pathc06 := od.pathc06;
          itm_tbl(i).pathc07 := od.pathc07;
          itm_tbl(i).pathc10 := od.pathc10;
          itm_tbl(i).pathc11 := od.pathc11;
          itm_tbl(i).pathc12 := od.pathc12;
          itm_tbl(i).pathn01 := od.pathn01;
          if od.pathc09 is not null then
            itm_tbl(i).upc := substr(od.pathc09,1,12);
          else
            open c_ia(sp.item);
            fetch c_ia into ia;
            l_found := c_ia%found;
            close c_ia;
            if l_found then
              itm_tbl(i).upc := substr(ia.itemalias,1,12);
            end if;
          end if;
        end if;
        if in_qty is not null then
          itm_tbl(i).qtyea := in_qty;
          exit;
        else
          itm_tbl(i).qtyea := sp.quantity;
        end if;
      end if;
      exit when i >= 12;
   end loop;

   while i < 12 loop
      i := itm_tbl.count+1;
      itm_tbl(i) := null;
   end loop;

end build_itm_tbl;

procedure find_partial_cases
(in_lpid in varchar2
,in_fromlpid in varchar2
,in_custid in varchar2
,in_item in varchar2
,in_qtyneeded in number
,io_qtyfound in out number
)
is

qtyRemain pls_integer;
qtyUsed pls_integer;
ix binary_integer;
done boolean;
begin

io_qtyfound := 0;
qtyRemain := in_qtyneeded;

-- first try to find on same fromlpid
done := false;
while qtyRemain > 0
loop
  if pc_tbl.count = 0 then
    done := true;
  else
    for ix in 1..pc_tbl.count
    loop
      if ix = pc_tbl.count then
        done := true;
      end if;
      if pc_tbl(ix).item = in_item and
         pc_tbl(ix).qtyavail > 0 and
         pc_tbl(ix).fromlpid = in_fromlpid then
        if pc_tbl(ix).qtyavail > qtyRemain then
          qtyUsed := qtyRemain;
        else
          qtyUsed := pc_tbl(ix).qtyavail;
        end if;
        pc_tbl(ix).qtyavail := pc_tbl(ix).qtyavail - qtyused;
        io_qtyfound := io_qtyfound + qtyused;
      end if;
    end loop;
  end if;
  if done then
    exit;
  end if;
end loop;

-- next try to find exact qty needed
done := false;
while qtyRemain > 0
loop
  if pc_tbl.count = 0 then
    done := true;
  else
    for ix in 1..pc_tbl.count
    loop
      if ix = pc_tbl.count then
        done := true;
      end if;
      if pc_tbl(ix).item = in_item and
         pc_tbl(ix).qtyavail = qtyRemain then
        qtyUsed := qtyRemain;
        pc_tbl(ix).qtyavail := pc_tbl(ix).qtyavail - qtyused;
        io_qtyfound := io_qtyfound + qtyused;
        qtyRemain := qtyRemain - qtyUsed;
        exit;
      end if;
    end loop;
  end if;
  if done then
    exit;
  end if;
end loop;

-- next try to find smaller quantities
done := false;
while qtyRemain > 0
loop
  if pc_tbl.count = 0 then
    done := true;
  else
    for ix in 1..pc_tbl.count
    loop
      if ix = pc_tbl.count then
        done := true;
      end if;
      if pc_tbl(ix).item = in_item and
         pc_tbl(ix).qtyavail > 0 and
         pc_tbl(ix).qtyavail < qtyRemain then
        if pc_tbl(ix).qtyavail > qtyRemain then
          qtyUsed := qtyRemain;
        else
          qtyUsed := pc_tbl(ix).qtyavail;
        end if;
        pc_tbl(ix).qtyavail := pc_tbl(ix).qtyavail - qtyused;
        io_qtyfound := io_qtyfound + qtyused;
        qtyRemain := qtyRemain - qtyUsed;
        exit;
      end if;
    end loop;
  end if;
  if done then
    exit;
  end if;
end loop;

-- lastly accept any quantity
done := false;
while qtyRemain > 0
loop
  if pc_tbl.count = 0 then
    done := true;
  else
    for ix in 1..pc_tbl.count
    loop
      if ix = pc_tbl.count then
        done := true;
      end if;
      if pc_tbl(ix).item = in_item and
         pc_tbl(ix).qtyavail > 0 then
        if pc_tbl(ix).qtyavail > qtyRemain then
          qtyUsed := qtyRemain;
        else
          qtyUsed := pc_tbl(ix).qtyavail;
        end if;
        pc_tbl(ix).qtyavail := pc_tbl(ix).qtyavail - qtyused;
        io_qtyfound := io_qtyfound + qtyused;
        qtyRemain := qtyRemain - qtyUsed;
        exit;
      end if;
    end loop;
  end if;
  if done then
    exit;
  end if;
end loop;

end find_partial_cases;

procedure build_pallet_labels
         (in_lpid     in varchar2,
          in_orderid  in number,
          in_shipid   in number,
          in_custid   in varchar2,
          in_fromlpid in varchar2,
          in_item     in varchar2,
          io_seq      in out varchar2,
          io_bigseq   in out number,
          in_type     in varchar2,
          in_quantity in number,
          in_do_partials in varchar2)
is

cursor c_it is
  select CI.item as item,
         CI.descr as descr,
         CI.abbrev as abbrev,
         CI.countryof as countryof,
         CI.descr as cntryds
    from custitem CI, countrycodes CC
   where CI.custid = in_custid
     and CI.item = in_item
     and CI.countryof = CC.code(+);
itm c_it%rowtype;

cursor c_od is
        select consigneesku as sku,
               rtrim(dtlpassthruchar01) as pathc01,
               rtrim(dtlpassthruchar02) as pathc02,
               rtrim(dtlpassthruchar03) as pathc03,
               rtrim(dtlpassthruchar06) as pathc06,
               rtrim(dtlpassthruchar07) as pathc07,
               rtrim(dtlpassthruchar09) as pathc09,
               rtrim(dtlpassthruchar10) as pathc10,
               rtrim(dtlpassthruchar11) as pathc11,
               rtrim(dtlpassthruchar12) as pathc12,
               dtlpassthrunum01 as pathn01
          from orderdtl
         where orderid = in_orderid
           and shipid = in_shipid
           and item = in_item
         order by lotnumber;
od c_od%rowtype;

cursor c_ia is
        select itemalias
          from custitemalias
         where custid = in_custid
           and item = in_item
           and aliasdesc = 'UPC';

ia c_ia%rowtype;

ix integer;
i binary_integer;
l_sscc18 varchar2(20);
l_found boolean;
strUpc varchar2(12);
qtyRemain pls_integer;
qtyCase pls_integer;
qtyLbl pls_integer;
qtyNeeded pls_integer;
qtyFound pls_integer;
cntRows integer;
done boolean;
begin

if in_item != prev_item then
  if prev_item != 'x' then
    done := false;
    if pc_tbl.count != 0 then
      while not done
      loop
        for ix in 1..pc_tbl.count
        loop
          if ix = pc_tbl.count then
            done := true;
          end if;
          if pc_tbl(ix).item = prev_item and
             pc_tbl(ix).qtyavail > 0 then
            build_pallet_labels(pc_tbl(ix).lpid, in_orderid, in_shipid, in_custid,
              pc_tbl(ix).fromlpid, prev_item,
              io_seq, io_bigseq, 'P', pc_tbl(ix).qtyavail, 'Y');
            exit;
          end if;
        end loop;
      end loop;
    end if;
    update weber_eso_ordlbl_table
       set seqof = io_seq - 1
     where orderid = in_orderid
       and shipid = in_shipid
       and seqof = 0;
  end if;
  io_seq := 1;
  prev_item := in_item;
end if;

qtyRemain := in_quantity;
qtyCase := case_qty(in_custid, in_item);

while qtyRemain > 0
loop
  if qtyCase < qtyRemain then
    qtyLbl := qtyCase;
  else
    qtyLbl := qtyRemain;
  end if;
  if qtyLbl != qtyCase then
    if in_do_partials = 'N' then
      exit;
    end if;
    if pc_tbl.count = 0 then
      qtyLbl := 0;
    else
      for ix in 1..pc_tbl.count
      loop
        if pc_tbl(ix).lpid = in_lpid and
           pc_tbl(ix).fromlpid = in_fromlpid and
           pc_tbl(ix).item = in_item then
          qtyLbl := pc_tbl(ix).qtyavail;
          pc_tbl(ix).qtyavail := 0;
          exit;
        end if;
      end loop;
    end if;
    if qtyLbl = 0 then
      exit;
    end if;
    for ix in 1..pc_tbl.count
    loop
      if pc_tbl(ix).lpid = in_lpid and
         pc_tbl(ix).fromlpid = in_fromlpid and
         pc_tbl(ix).item = in_item then
        pc_tbl(ix).qtyavail := pc_tbl(ix).qtyavail - qtyLbl;
        exit;
      end if;
    end loop;
    qtyNeeded := qtyCase - qtyLbl;
    find_partial_cases(in_lpid, in_fromlpid, in_custid, in_item, qtyNeeded, qtyFound);
    qtyLbl := qtyLbl + qtyFound;
  end if;
  build_itm_tbl(in_lpid, in_type, in_orderid, in_shipid, in_custid, in_item, qtyLbl);
  itm := null;
  od := null;
  if itm_tbl(2).item is null then
    open c_it;
    fetch c_it into itm;
    close c_it;
    od := null;
    open c_od;
    fetch c_od into od;
    l_found := c_od%found;
    close c_od;
    if l_found then
      if od.pathc09 is not null then
        strUpc := substr(od.pathc09,1,12);
      else
        open c_ia;
        fetch c_ia into ia;
        l_found := c_ia%found;
        close c_ia;
        if l_found then
          strUpc := substr(ia.itemalias,1,12);
        end if;
      end if;
    end if;
  else
    itm.item := 'Mixed';
    itm.descr := 'Mixed';
    itm.abbrev := 'Mixed';
  end if;
  l_sscc18 := sscc18_code(in_custid, '0', '8');
  insert into weber_eso_ordlbl_table
      (orderid, shipid, lpid, sscc18,
       scc14, item1, item2, item3,
       item4, item5, item6, item7,
       item8, item9, item10, item11,
       item12, itemdescr1, itemdescr2, itemdescr3,
       itemdescr4, itemdescr5, itemdescr6, itemdescr7,
       itemdescr8, itemdescr9, itemdescr10, itemdescr11,
       itemdescr12, itemabbrev1, itemabbrev2, itemabbrev3,
       itemabbrev4, itemabbrev5, itemabbrev6, itemabbrev7,
       itemabbrev8, itemabbrev9, itemabbrev10, itemabbrev11,
       itemabbrev12, consigneeitem1, consigneeitem2, consigneeitem3,
       consigneeitem4, consigneeitem5, consigneeitem6, consigneeitem7,
       consigneeitem8, consigneeitem9, consigneeitem10, consigneeitem11,
       consigneeitem12, qtyeaitem1, qtyeaitem2, qtyeaitem3,
       qtyeaitem4, qtyeaitem5, qtyeaitem6, qtyeaitem7,
       qtyeaitem8, qtyeaitem9, qtyeaitem10, qtyeaitem11,
       qtyeaitem12, upc1, upc2,
       upc3, upc4, upc5, upc6,
       upc7, upc8, upc9, upc10,
       upc11, upc12, countryof1, countryof2,
       countryof3, countryof4, countryof5, countryof6,
       countryof7, countryof8, countryof9, countryof10,
       countryof11, countryof12, countryofabbrev1, countryofabbrev2,
       countryofabbrev3, countryofabbrev4, countryofabbrev5, countryofabbrev6,
       countryofabbrev7, countryofabbrev8, countryofabbrev9, countryofabbrev10,
       countryofabbrev11, countryofabbrev12, dtlpassthruchar01_1, dtlpassthruchar01_2,
       dtlpassthruchar01_3, dtlpassthruchar01_4, dtlpassthruchar01_5, dtlpassthruchar01_6,
       dtlpassthruchar01_7, dtlpassthruchar01_8, dtlpassthruchar01_9, dtlpassthruchar01_10,
       dtlpassthruchar01_11, dtlpassthruchar01_12, dtlpassthruchar06_1, dtlpassthruchar06_2,
       dtlpassthruchar06_3, dtlpassthruchar06_4, dtlpassthruchar06_5, dtlpassthruchar06_6,
       dtlpassthruchar06_7, dtlpassthruchar06_8, dtlpassthruchar06_9, dtlpassthruchar06_10,
       dtlpassthruchar06_11, dtlpassthruchar06_12, dtlpassthruchar07_1, dtlpassthruchar07_2,
       dtlpassthruchar07_3, dtlpassthruchar07_4, dtlpassthruchar07_5, dtlpassthruchar07_6,
       dtlpassthruchar07_7, dtlpassthruchar07_8, dtlpassthruchar07_9, dtlpassthruchar07_10,
       dtlpassthruchar07_11, dtlpassthruchar07_12, dtlpassthruchar10_1, dtlpassthruchar10_2,
       dtlpassthruchar10_3, dtlpassthruchar10_4, dtlpassthruchar10_5, dtlpassthruchar10_6,
       dtlpassthruchar10_7, dtlpassthruchar10_8, dtlpassthruchar10_9, dtlpassthruchar10_10,
       dtlpassthruchar10_11, dtlpassthruchar10_12, dtlpassthruchar11_1, dtlpassthruchar11_2,
       dtlpassthruchar11_3, dtlpassthruchar11_4, dtlpassthruchar11_5, dtlpassthruchar11_6,
       dtlpassthruchar11_7, dtlpassthruchar11_8, dtlpassthruchar11_9, dtlpassthruchar11_10,
       dtlpassthruchar11_11, dtlpassthruchar11_12, dtlpassthruchar12_1, dtlpassthruchar12_2,
       dtlpassthruchar12_3, dtlpassthruchar12_4, dtlpassthruchar12_5, dtlpassthruchar12_6,
       dtlpassthruchar12_7, dtlpassthruchar12_8, dtlpassthruchar12_9, dtlpassthruchar12_10,
       dtlpassthruchar12_11, dtlpassthruchar12_12, dtlpassthrunum01_1, dtlpassthrunum01_2,
       dtlpassthrunum01_3, dtlpassthrunum01_4, dtlpassthrunum01_5, dtlpassthrunum01_6,
       dtlpassthrunum01_7, dtlpassthrunum01_8, dtlpassthrunum01_9, dtlpassthrunum01_10,
       dtlpassthrunum01_11, dtlpassthrunum01_12, seq, seqof,
       bigseq, bigseqof,
       item, itemdescr, itemabbrev, consigneeitem,
       qtyeaitem, countryofabbrev, dtlpassthruchar01,
       dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar06,
       dtlpassthruchar07, dtlpassthruchar10, dtlpassthruchar11,
       dtlpassthruchar12, dtlpassthrunum01, upc, countryof,
       type)
        values
                (in_orderid, in_shipid, in_fromlpid, l_sscc18,
                 zedi.get_sscc14_code('0',itm_tbl(1).upc), itm_tbl(1).item, itm_tbl(2).item, itm_tbl(3).item,
       itm_tbl(4).item, itm_tbl(5).item, itm_tbl(6).item, itm_tbl(7).item,
       itm_tbl(8).item, itm_tbl(9).item, itm_tbl(10).item, itm_tbl(11).item,
       itm_tbl(12).item, itm_tbl(1).descr, itm_tbl(2).descr, itm_tbl(3).descr,
       itm_tbl(4).descr, itm_tbl(5).descr, itm_tbl(6).descr, itm_tbl(7).descr,
       itm_tbl(8).descr, itm_tbl(9).descr, itm_tbl(10).descr, itm_tbl(11).descr,
       itm_tbl(12).descr, itm_tbl(1).abbrev, itm_tbl(2).abbrev, itm_tbl(3).abbrev,
       itm_tbl(4).abbrev, itm_tbl(5).abbrev, itm_tbl(6).abbrev, itm_tbl(7).abbrev,
       itm_tbl(8).abbrev, itm_tbl(9).abbrev, itm_tbl(10).abbrev, itm_tbl(11).abbrev,
       itm_tbl(12).abbrev, itm_tbl(1).sku, itm_tbl(2).sku, itm_tbl(3).sku,
       itm_tbl(4).sku, itm_tbl(5).sku, itm_tbl(6).sku, itm_tbl(7).sku,
       itm_tbl(8).sku, itm_tbl(9).sku, itm_tbl(10).sku, itm_tbl(11).sku,
       itm_tbl(12).sku, itm_tbl(1).qtyea, itm_tbl(2).qtyea, itm_tbl(3).qtyea,
       itm_tbl(4).qtyea, itm_tbl(5).qtyea, itm_tbl(6).qtyea, itm_tbl(7).qtyea,
       itm_tbl(8).qtyea, itm_tbl(9).qtyea, itm_tbl(10).qtyea, itm_tbl(11).qtyea,
       itm_tbl(12).qtyea, itm_tbl(1).upc, itm_tbl(2).upc,
       itm_tbl(3).upc, itm_tbl(4).upc, itm_tbl(5).upc, itm_tbl(6).upc,
       itm_tbl(7).upc, itm_tbl(8).upc, itm_tbl(9).upc, itm_tbl(10).upc,
       itm_tbl(11).upc, itm_tbl(12).upc, itm_tbl(1).cntryof, itm_tbl(2).cntryof,
       itm_tbl(3).cntryof, itm_tbl(4).cntryof, itm_tbl(5).cntryof, itm_tbl(6).cntryof,
       itm_tbl(7).cntryof, itm_tbl(8).cntryof, itm_tbl(9).cntryof, itm_tbl(10).cntryof,
       itm_tbl(11).cntryof, itm_tbl(12).cntryof, itm_tbl(1).cntryds, itm_tbl(2).cntryds,
       itm_tbl(3).cntryds, itm_tbl(4).cntryds, itm_tbl(5).cntryds, itm_tbl(6).cntryds,
       itm_tbl(7).cntryds, itm_tbl(8).cntryds, itm_tbl(9).cntryds, itm_tbl(10).cntryds,
       itm_tbl(11).cntryds, itm_tbl(12).cntryds, itm_tbl(1).pathc01, itm_tbl(2).pathc01,
       itm_tbl(3).pathc01, itm_tbl(4).pathc01, itm_tbl(5).pathc01, itm_tbl(6).pathc01,
       itm_tbl(7).pathc01, itm_tbl(8).pathc01, itm_tbl(9).pathc01, itm_tbl(10).pathc01,
       itm_tbl(11).pathc01, itm_tbl(12).pathc01, itm_tbl(1).pathc06, itm_tbl(2).pathc06,
       itm_tbl(3).pathc06, itm_tbl(4).pathc06, itm_tbl(5).pathc06, itm_tbl(6).pathc06,
       itm_tbl(7).pathc06, itm_tbl(8).pathc06, itm_tbl(9).pathc06, itm_tbl(10).pathc06,
       itm_tbl(11).pathc06, itm_tbl(12).pathc06, itm_tbl(1).pathc07, itm_tbl(2).pathc07,
       itm_tbl(3).pathc07, itm_tbl(4).pathc07, itm_tbl(5).pathc07, itm_tbl(6).pathc07,
       itm_tbl(7).pathc07, itm_tbl(8).pathc07, itm_tbl(9).pathc07, itm_tbl(10).pathc07,
       itm_tbl(11).pathc07, itm_tbl(12).pathc07, itm_tbl(1).pathc10, itm_tbl(2).pathc10,
       itm_tbl(3).pathc10, itm_tbl(4).pathc10, itm_tbl(5).pathc10, itm_tbl(6).pathc10,
       itm_tbl(7).pathc10, itm_tbl(8).pathc10, itm_tbl(9).pathc10, itm_tbl(10).pathc10,
       itm_tbl(11).pathc10, itm_tbl(12).pathc10, itm_tbl(1).pathc11, itm_tbl(2).pathc11,
       itm_tbl(3).pathc11, itm_tbl(4).pathc11, itm_tbl(5).pathc11, itm_tbl(6).pathc11,
       itm_tbl(7).pathc11, itm_tbl(8).pathc11, itm_tbl(9).pathc11, itm_tbl(10).pathc11,
       itm_tbl(11).pathc11, itm_tbl(12).pathc11, itm_tbl(1).pathc12, itm_tbl(2).pathc12,
       itm_tbl(3).pathc12, itm_tbl(4).pathc12, itm_tbl(5).pathc12, itm_tbl(6).pathc12,
       itm_tbl(7).pathc12, itm_tbl(8).pathc12, itm_tbl(9).pathc12, itm_tbl(10).pathc12,
       itm_tbl(11).pathc12, itm_tbl(12).pathc12, itm_tbl(1).pathn01, itm_tbl(2).pathn01,
       itm_tbl(3).pathn01, itm_tbl(4).pathn01, itm_tbl(5).pathn01, itm_tbl(6).pathn01,
       itm_tbl(7).pathn01, itm_tbl(8).pathn01, itm_tbl(9).pathn01, itm_tbl(10).pathn01,
       itm_tbl(11).pathn01, itm_tbl(12).pathn01, io_seq, 0,
       io_bigseq, 0,
       itm.item, itm.descr, itm.abbrev, od.sku, qtyLbl,
       itm.cntryds, od.pathc01, od.pathc02, od.pathc03,
       od.pathc06, od.pathc07, od.pathc10,
       od.pathc11, od.pathc12, od.pathn01, strUpc, itm.countryof,
       in_type);
  commit;
  io_seq := io_seq + 1;
  io_bigseq := io_bigseq + 1;
  qtyRemain := qtyRemain - qtyLbl;
end loop;

end build_pallet_labels;

procedure build_carton_label
         (in_lpid     in varchar2,
          in_orderid  in number,
          in_shipid   in number,
          in_custid   in varchar2,
          in_fromlpid in varchar2,
          in_item     in varchar2,
          in_unitofmeasure in varchar2,
          io_seq      in out number,
          io_bigseq   in out number,
          in_type     in varchar2,
          in_quantity in number)
is

cursor c_it is
  select CI.item as item,
         CI.descr as descr,
         CI.abbrev as abbrev,
         CI.countryof as countryof,
         CI.descr as cntryds
    from custitem CI, countrycodes CC
   where CI.custid = in_custid
     and CI.item = in_item
     and CI.countryof = CC.code(+);
itm c_it%rowtype;

cursor c_od is
        select consigneesku as sku,
               rtrim(dtlpassthruchar01) as pathc01,
               rtrim(dtlpassthruchar02) as pathc02,
               rtrim(dtlpassthruchar03) as pathc03,
               rtrim(dtlpassthruchar06) as pathc06,
               rtrim(dtlpassthruchar07) as pathc07,
               rtrim(dtlpassthruchar09) as pathc09,
               rtrim(dtlpassthruchar10) as pathc10,
               rtrim(dtlpassthruchar11) as pathc11,
               rtrim(dtlpassthruchar12) as pathc12,
               dtlpassthrunum01 as pathn01
          from orderdtl
         where orderid = in_orderid
           and shipid = in_shipid
           and item = in_item
         order by lotnumber;
od c_od%rowtype;

cursor c_ia is
        select itemalias
          from custitemalias
         where custid = in_custid
           and item = in_item
           and aliasdesc = 'UPC';

ia c_ia%rowtype;

i binary_integer;
l_sscc18 varchar2(20);
l_found boolean;
strUpc varchar2(12);
qtyRemain pls_integer;
qtyCase pls_integer;
qtyLbl pls_integer;
cntRows integer;
begin

build_itm_tbl(in_lpid, in_type, in_orderid, in_shipid, in_custid, null, null);

l_sscc18 := sscc18_code(in_custid, '0', '8');

itm := null;
od := null;
if itm_tbl(2).item is null then
  open c_it;
  fetch c_it into itm;
  close c_it;
  od := null;
  open c_od;
  fetch c_od into od;
  l_found := c_od%found;
  close c_od;
  if l_found then
    if od.pathc09 is not null then
      strUpc := substr(od.pathc09,1,12);
    else
      open c_ia;
      fetch c_ia into ia;
      l_found := c_ia%found;
      close c_ia;
      if l_found then
        strUpc := substr(ia.itemalias,1,12);
      end if;
    end if;
  end if;
else
  itm.item := 'Mixed';
  itm.descr := 'Mixed';
  itm.abbrev := 'Mixed';
end if;

insert into weber_eso_ordlbl_table
        (orderid, shipid, lpid, sscc18,
         scc14, item1, item2, item3,
         item4, item5, item6, item7,
         item8, item9, item10, item11,
         item12, itemdescr1, itemdescr2, itemdescr3,
         itemdescr4, itemdescr5, itemdescr6, itemdescr7,
         itemdescr8, itemdescr9, itemdescr10, itemdescr11,
         itemdescr12, itemabbrev1, itemabbrev2, itemabbrev3,
         itemabbrev4, itemabbrev5, itemabbrev6, itemabbrev7,
         itemabbrev8, itemabbrev9, itemabbrev10, itemabbrev11,
         itemabbrev12, consigneeitem1, consigneeitem2, consigneeitem3,
         consigneeitem4, consigneeitem5, consigneeitem6, consigneeitem7,
         consigneeitem8, consigneeitem9, consigneeitem10, consigneeitem11,
         consigneeitem12, qtyeaitem1, qtyeaitem2, qtyeaitem3,
         qtyeaitem4, qtyeaitem5, qtyeaitem6, qtyeaitem7,
         qtyeaitem8, qtyeaitem9, qtyeaitem10, qtyeaitem11,
         qtyeaitem12, upc1, upc2,
         upc3, upc4, upc5, upc6,
         upc7, upc8, upc9, upc10,
         upc11, upc12, countryof1, countryof2,
         countryof3, countryof4, countryof5, countryof6,
         countryof7, countryof8, countryof9, countryof10,
         countryof11, countryof12, countryofabbrev1, countryofabbrev2,
         countryofabbrev3, countryofabbrev4, countryofabbrev5, countryofabbrev6,
         countryofabbrev7, countryofabbrev8, countryofabbrev9, countryofabbrev10,
         countryofabbrev11, countryofabbrev12, dtlpassthruchar01_1, dtlpassthruchar01_2,
         dtlpassthruchar01_3, dtlpassthruchar01_4, dtlpassthruchar01_5, dtlpassthruchar01_6,
         dtlpassthruchar01_7, dtlpassthruchar01_8, dtlpassthruchar01_9, dtlpassthruchar01_10,
         dtlpassthruchar01_11, dtlpassthruchar01_12, dtlpassthruchar06_1, dtlpassthruchar06_2,
         dtlpassthruchar06_3, dtlpassthruchar06_4, dtlpassthruchar06_5, dtlpassthruchar06_6,
         dtlpassthruchar06_7, dtlpassthruchar06_8, dtlpassthruchar06_9, dtlpassthruchar06_10,
         dtlpassthruchar06_11, dtlpassthruchar06_12, dtlpassthruchar07_1, dtlpassthruchar07_2,
         dtlpassthruchar07_3, dtlpassthruchar07_4, dtlpassthruchar07_5, dtlpassthruchar07_6,
         dtlpassthruchar07_7, dtlpassthruchar07_8, dtlpassthruchar07_9, dtlpassthruchar07_10,
         dtlpassthruchar07_11, dtlpassthruchar07_12, dtlpassthruchar10_1, dtlpassthruchar10_2,
         dtlpassthruchar10_3, dtlpassthruchar10_4, dtlpassthruchar10_5, dtlpassthruchar10_6,
         dtlpassthruchar10_7, dtlpassthruchar10_8, dtlpassthruchar10_9, dtlpassthruchar10_10,
         dtlpassthruchar10_11, dtlpassthruchar10_12, dtlpassthruchar11_1, dtlpassthruchar11_2,
         dtlpassthruchar11_3, dtlpassthruchar11_4, dtlpassthruchar11_5, dtlpassthruchar11_6,
         dtlpassthruchar11_7, dtlpassthruchar11_8, dtlpassthruchar11_9, dtlpassthruchar11_10,
         dtlpassthruchar11_11, dtlpassthruchar11_12, dtlpassthruchar12_1, dtlpassthruchar12_2,
         dtlpassthruchar12_3, dtlpassthruchar12_4, dtlpassthruchar12_5, dtlpassthruchar12_6,
         dtlpassthruchar12_7, dtlpassthruchar12_8, dtlpassthruchar12_9, dtlpassthruchar12_10,
         dtlpassthruchar12_11, dtlpassthruchar12_12, dtlpassthrunum01_1, dtlpassthrunum01_2,
         dtlpassthrunum01_3, dtlpassthrunum01_4, dtlpassthrunum01_5, dtlpassthrunum01_6,
         dtlpassthrunum01_7, dtlpassthrunum01_8, dtlpassthrunum01_9, dtlpassthrunum01_10,
         dtlpassthrunum01_11, dtlpassthrunum01_12, seq, seqof,
         bigseq, bigseqof,
         item, itemdescr, itemabbrev, consigneeitem,
         qtyeaitem, countryofabbrev, dtlpassthruchar01,
         dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar06,
         dtlpassthruchar07, dtlpassthruchar10, dtlpassthruchar11,
         dtlpassthruchar12, dtlpassthrunum01, upc, countryof,
         type)
          values
        (in_orderid, in_shipid, in_fromlpid, l_sscc18,
         zedi.get_sscc14_code('0',itm_tbl(1).upc), itm_tbl(1).item, itm_tbl(2).item, itm_tbl(3).item,
         itm_tbl(4).item, itm_tbl(5).item, itm_tbl(6).item, itm_tbl(7).item,
         itm_tbl(8).item, itm_tbl(9).item, itm_tbl(10).item, itm_tbl(11).item,
         itm_tbl(12).item, itm_tbl(1).descr, itm_tbl(2).descr, itm_tbl(3).descr,
         itm_tbl(4).descr, itm_tbl(5).descr, itm_tbl(6).descr, itm_tbl(7).descr,
         itm_tbl(8).descr, itm_tbl(9).descr, itm_tbl(10).descr, itm_tbl(11).descr,
         itm_tbl(12).descr, itm_tbl(1).abbrev, itm_tbl(2).abbrev, itm_tbl(3).abbrev,
         itm_tbl(4).abbrev, itm_tbl(5).abbrev, itm_tbl(6).abbrev, itm_tbl(7).abbrev,
         itm_tbl(8).abbrev, itm_tbl(9).abbrev, itm_tbl(10).abbrev, itm_tbl(11).abbrev,
         itm_tbl(12).abbrev, itm_tbl(1).sku, itm_tbl(2).sku, itm_tbl(3).sku,
         itm_tbl(4).sku, itm_tbl(5).sku, itm_tbl(6).sku, itm_tbl(7).sku,
         itm_tbl(8).sku, itm_tbl(9).sku, itm_tbl(10).sku, itm_tbl(11).sku,
         itm_tbl(12).sku, itm_tbl(1).qtyea, itm_tbl(2).qtyea, itm_tbl(3).qtyea,
         itm_tbl(4).qtyea, itm_tbl(5).qtyea, itm_tbl(6).qtyea, itm_tbl(7).qtyea,
         itm_tbl(8).qtyea, itm_tbl(9).qtyea, itm_tbl(10).qtyea, itm_tbl(11).qtyea,
         itm_tbl(12).qtyea, itm_tbl(1).upc, itm_tbl(2).upc,
         itm_tbl(3).upc, itm_tbl(4).upc, itm_tbl(5).upc, itm_tbl(6).upc,
         itm_tbl(7).upc, itm_tbl(8).upc, itm_tbl(9).upc, itm_tbl(10).upc,
         itm_tbl(11).upc, itm_tbl(12).upc, itm_tbl(1).cntryof, itm_tbl(2).cntryof,
         itm_tbl(3).cntryof, itm_tbl(4).cntryof, itm_tbl(5).cntryof, itm_tbl(6).cntryof,
         itm_tbl(7).cntryof, itm_tbl(8).cntryof, itm_tbl(9).cntryof, itm_tbl(10).cntryof,
         itm_tbl(11).cntryof, itm_tbl(12).cntryof, itm_tbl(1).cntryds, itm_tbl(2).cntryds,
         itm_tbl(3).cntryds, itm_tbl(4).cntryds, itm_tbl(5).cntryds, itm_tbl(6).cntryds,
         itm_tbl(7).cntryds, itm_tbl(8).cntryds, itm_tbl(9).cntryds, itm_tbl(10).cntryds,
         itm_tbl(11).cntryds, itm_tbl(12).cntryds, itm_tbl(1).pathc01, itm_tbl(2).pathc01,
         itm_tbl(3).pathc01, itm_tbl(4).pathc01, itm_tbl(5).pathc01, itm_tbl(6).pathc01,
         itm_tbl(7).pathc01, itm_tbl(8).pathc01, itm_tbl(9).pathc01, itm_tbl(10).pathc01,
         itm_tbl(11).pathc01, itm_tbl(12).pathc01, itm_tbl(1).pathc06, itm_tbl(2).pathc06,
         itm_tbl(3).pathc06, itm_tbl(4).pathc06, itm_tbl(5).pathc06, itm_tbl(6).pathc06,
         itm_tbl(7).pathc06, itm_tbl(8).pathc06, itm_tbl(9).pathc06, itm_tbl(10).pathc06,
         itm_tbl(11).pathc06, itm_tbl(12).pathc06, itm_tbl(1).pathc07, itm_tbl(2).pathc07,
         itm_tbl(3).pathc07, itm_tbl(4).pathc07, itm_tbl(5).pathc07, itm_tbl(6).pathc07,
         itm_tbl(7).pathc07, itm_tbl(8).pathc07, itm_tbl(9).pathc07, itm_tbl(10).pathc07,
         itm_tbl(11).pathc07, itm_tbl(12).pathc07, itm_tbl(1).pathc10, itm_tbl(2).pathc10,
         itm_tbl(3).pathc10, itm_tbl(4).pathc10, itm_tbl(5).pathc10, itm_tbl(6).pathc10,
         itm_tbl(7).pathc10, itm_tbl(8).pathc10, itm_tbl(9).pathc10, itm_tbl(10).pathc10,
         itm_tbl(11).pathc10, itm_tbl(12).pathc10, itm_tbl(1).pathc11, itm_tbl(2).pathc11,
         itm_tbl(3).pathc11, itm_tbl(4).pathc11, itm_tbl(5).pathc11, itm_tbl(6).pathc11,
         itm_tbl(7).pathc11, itm_tbl(8).pathc11, itm_tbl(9).pathc11, itm_tbl(10).pathc11,
         itm_tbl(11).pathc11, itm_tbl(12).pathc11, itm_tbl(1).pathc12, itm_tbl(2).pathc12,
         itm_tbl(3).pathc12, itm_tbl(4).pathc12, itm_tbl(5).pathc12, itm_tbl(6).pathc12,
         itm_tbl(7).pathc12, itm_tbl(8).pathc12, itm_tbl(9).pathc12, itm_tbl(10).pathc12,
         itm_tbl(11).pathc12, itm_tbl(12).pathc12, itm_tbl(1).pathn01, itm_tbl(2).pathn01,
         itm_tbl(3).pathn01, itm_tbl(4).pathn01, itm_tbl(5).pathn01, itm_tbl(6).pathn01,
         itm_tbl(7).pathn01, itm_tbl(8).pathn01, itm_tbl(9).pathn01, itm_tbl(10).pathn01,
         itm_tbl(11).pathn01, itm_tbl(12).pathn01, io_seq, 0,
         io_bigseq, 0,
         itm.item, itm.descr, itm.abbrev, od.sku, in_quantity,
         itm.cntryds, od.pathc01, od.pathc02, od.pathc03,
         od.pathc06, od.pathc07, od.pathc10,
         od.pathc11, od.pathc12, od.pathn01, strUpc, itm.countryof,
         in_type);

    commit;

    io_seq := io_seq + 1;
    io_bigseq := io_bigseq + 1;

end build_carton_label;

procedure compute_partial_cases
(in_lpid varchar2
,in_fromlpid varchar2
,in_custid varchar2
,in_item varchar2
,in_quantity number
)
is

ix binary_integer;
qtyRemain pls_integer;
qtyCase pls_integer;
qtyPartial pls_integer;
strlpid shippingplate.lpid%type;
strfromlpid shippingplate.fromlpid%type;
stritem shippingplate.item%type;
qtyavail shippingplate.quantity%type;
pcix binary_integer;

begin

qtyRemain := in_quantity;
qtyCase := case_qty(in_custid, in_item);
qtyPartial := mod(qtyRemain, qtyCase);
if qtyPartial = 0 then
  return;
end if;

pcix := 0;
for ix in 1..pc_tbl.count
loop
  if pc_tbl(ix).item = in_item and
     pc_tbl(ix).qtyavail < qtyPartial then
    strLpid := pc_tbl(ix).lpid;
    strfromlpid := pc_tbl(ix).fromlpid;
    strItem := pc_tbl(ix).item;
    qtyavail := pc_tbl(ix).qtyavail;
    pcix := ix;
    exit;
  end if;
end loop;

if pcix != 0 then
  pc_tbl(pcix).lpid := in_lpid;
  pc_tbl(pcix).fromlpid := in_fromlpid;
  pc_tbl(pcix).item := in_item;
  pc_tbl(pcix).qtyavail := qtyPartial;
  ix := pc_tbl.count + 1;
  pc_tbl(ix).lpid := strlpid;
  pc_tbl(ix).fromlpid := strfromlpid;
  pc_tbl(ix).item := stritem;
  pc_tbl(ix).qtyavail := qtyavail;
else
  ix := pc_tbl.count + 1;
  pc_tbl(ix).lpid := in_lpid;
  pc_tbl(ix).fromlpid := in_fromlpid;
  pc_tbl(ix).item := in_item;
  pc_tbl(ix).qtyavail := qtyPartial;
end if;

end compute_partial_cases;


-- Public


procedure eso_order_label
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_stmt   out varchar2)
is

cursor c_inp is
     select orderid, shipid, custid
       from shippingplate
      where lpid = in_lpid;
cursor c_inf is
     select distinct orderid, shipid, custid
       from shippingplate
      where fromlpid = in_lpid;
inp c_inp%rowtype;
l_cnt pls_integer := 0;
l_bigseq pls_integer := 1;
l_seq pls_integer := 1;
l_num_labels pls_integer;
done boolean;
qtyEaches pls_integer;
qtyCase pls_integer;

begin

   out_stmt := null;

   if substr(in_lpid,-1,1) = 'S' then
 		open c_inp;
     	fetch c_inp into inp;
     	if c_inp%found then
      	l_cnt := 1;
		end if;
     	close c_inp;
   else
     	open c_inf;
     	fetch c_inf into inp;
     	if c_inf%found then
         l_cnt := 1;
      	fetch c_inf into inp;
       	if c_inf%found then  -- orderid/shipid not unique
         	l_cnt := 2;
       	end if;
     	end if;
     	close c_inf;
   end if;

   if l_cnt != 1 then
   	if in_func = 'Q' then
			if l_cnt = 0 then
         	out_stmt := 'Order not found';
			else
         	out_stmt := 'Order not unique';
			end if;
    	end if;
      return;
	end if;

   select count(1) into l_cnt
		from shippingplate
    	where orderid = inp.orderid
        and shipid = inp.shipid
        and status in ('U','P');

	if l_cnt != 0 then   -- picks left
   	if in_func = 'Q' then
     		out_stmt := 'Picks remain';
      end if;
      return;
	end if;

   if in_func = 'Q' then
     	out_stmt := 'OKAY';
   	if in_action = 'P' then
      	select count(1) into l_cnt
     			from weber_eso_ordlbl_table
    			where orderid = inp.orderid
      		  and shipid = inp.shipid;
			if l_cnt = 0 then
         	out_stmt := 'Nothing for order';
			end if;
		end if;
     return;
   end if;

	if in_action != 'P' then
		delete from weber_eso_ordlbl_table
			where orderid = inp.orderid
      	  and shipid = inp.shipid;
	   commit;

		l_seq := 1;
	   l_bigseq := 1;
   	for sp in (select lpid, fromlpid, item, unitofmeasure, sum(quantity) as quantity
           			from shippingplate
         	      where orderid = inp.orderid
            	     and shipid = inp.shipid
               	  and type = 'C'
                    and parentlpid is null
                	group by lpid, fromlpid, item, unitofmeasure
   	            order by lpid, fromlpid, item, unitofmeasure) loop
 			build_carton_label(sp.lpid, inp.orderid, inp.shipid, inp.custid, sp.fromlpid, sp.item,
         		sp.unitofmeasure, l_seq, l_bigseq, 'C', sp.quantity);
		end loop;

    	update weber_eso_ordlbl_table
      	set seqof = l_seq - 1
     		where orderid = inp.orderid
           and shipid = inp.shipid;

    	commit;

    	pc_tbl.delete;
    	for sp in (select nvl(parentlpid,lpid) as lpid,
              			zmp.shipplate_fromlpid(nvl(parentlpid,lpid)) as fromlpid,
                  	item, unitofmeasure, sum(quantity) as quantity
                 	from shippingplate
                	where orderid = inp.orderid
                    and shipid = inp.shipid
                    and type in ('F','P','C')
                    and zmp.shipplate_type(nvl(parentlpid,lpid)) != 'C'
                	group by nvl(parentlpid,lpid), zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),
                      		item, unitofmeasure
                 	order by item, fromlpid, lpid) loop
      	if sp.unitofmeasure = 'EA' then
        		qtyEaches := sp.quantity;
      	else
        		qtyCase := case_qty(inp.custid, sp.item);
        		qtyEaches := qtyCase * sp.quantity;
      	end if;
      	compute_partial_cases(sp.lpid, sp.fromlpid, inp.custid, sp.item, qtyEaches);
    	end loop;

    	prev_item := 'x';
    	l_seq := 1;
    	for sp in (select nvl(parentlpid,lpid) as lpid,
               		zmp.shipplate_fromlpid(nvl(parentlpid,lpid)) as fromlpid,
                     item, unitofmeasure, sum(quantity) as quantity
                 	from shippingplate
                	where orderid = inp.orderid
                    and shipid = inp.shipid
                    and type in ('F','P','C')
                    and zmp.shipplate_type(nvl(parentlpid,lpid)) != 'C'
                	group by nvl(parentlpid,lpid), zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),
                      		item, unitofmeasure
                	order by item, fromlpid, lpid, quantity desc) loop
      	if sp.unitofmeasure = 'EA' then
        		qtyEaches := sp.quantity;
      	else
        		qtyCase := case_qty(inp.custid, sp.item);
        		qtyEaches := qtyCase * sp.quantity;
      	end if;
      	build_pallet_labels(sp.lpid, inp.orderid, inp.shipid, inp.custid, sp.fromlpid, sp.item,
         		l_seq, l_bigseq, 'P', qtyEaches, 'N');
    	end loop;

    	if prev_item != 'x' then
      	done := false;
      	while not done
      	loop
        		if pc_tbl.count = 0 then
          		done := true;
        		else
          		for ix in 1..pc_tbl.count
          		loop
            		if ix = pc_tbl.count then
              			done := true;
            		end if;
            		if pc_tbl(ix).item = prev_item and
                     pc_tbl(ix).qtyavail > 0 then
              			build_pallet_labels(pc_tbl(ix).lpid, inp.orderid, inp.shipid, inp.custid,
                				pc_tbl(ix).fromlpid, prev_item,
                				l_seq, l_bigseq, 'P', pc_tbl(ix).qtyavail, 'Y');
              			exit;
            		end if;
          		end loop;
        		end if;
      	end loop;
      	update weber_eso_ordlbl_table
         	set seqof = l_seq - 1
       		where orderid = inp.orderid
         	  and shipid = inp.shipid
         	  and seqof = 0;
    	end if;

    	commit;

    	update weber_eso_ordlbl_table
       	set bigseqof = l_bigseq - 1
     		where orderid = inp.orderid
       	  and shipid = inp.shipid;

    	commit;
	end if;

	out_stmt := 'select * from weber_eso_ordlbl_view where orderid = ' || inp.orderid
   		|| ' and shipid = ' || inp.shipid;

end eso_order_label;


procedure eso_load_label
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_stmt   out varchar2)
is
	cursor c_inp is
     select loadno
       from shippingplate
      where lpid = in_lpid;
	cursor c_inf is
     select distinct loadno
       from shippingplate
      where fromlpid = in_lpid;
	inp c_inp%rowtype;
   cursor c_sp(p_orderid number, p_shipid number) is
   	select lpid
      	from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid;
	sp c_sp%rowtype;
	l_cnt pls_integer := 0;
   l_msg varchar2(81);
begin

   out_stmt := null;

   if substr(in_lpid,-1,1) = 'S' then
 		open c_inp;
     	fetch c_inp into inp;
     	if c_inp%found then
      	l_cnt := 1;
		end if;
     	close c_inp;
   else
     	open c_inf;
     	fetch c_inf into inp;
     	if c_inf%found then
         l_cnt := 1;
      	fetch c_inf into inp;
       	if c_inf%found then  -- load not unique
         	l_cnt := 2;
       	end if;
     	end if;
     	close c_inf;
   end if;

   if l_cnt != 1 then
   	if in_func = 'Q' then
			if l_cnt = 0 then
         	out_stmt := 'Load not found';
			else
         	out_stmt := 'Load not unique';
			end if;
    	end if;
      return;
	end if;

   if inp.loadno = 0 then
   	if in_func = 'Q' then
   		out_stmt := 'No load assigned';
    	end if;
      return;
	end if;

  	if in_func = 'Q' then
   	if in_action = 'P' then
      	select count(1) into l_cnt
     			from weber_eso_ordlbl_table
    			where (orderid, shipid) in (select orderid, shipid
            				from orderhdr where loadno = inp.loadno);
			if l_cnt = 0 then
         	out_stmt := 'Nothing for load';
            return;
			end if;
		end if;

     	out_stmt := 'OKAY';
		for oh in (select orderid, shipid from orderhdr
   	            where loadno = inp.loadno) loop
			open c_sp(oh.orderid, oh.shipid);
   	  	fetch c_sp into sp;
     		close c_sp;
			eso_order_label(sp.lpid, in_func, '?', l_msg);		-- avoid "nothing for order" msg
         if l_msg != 'OKAY' then
         	out_stmt := l_msg;
            exit;
			end if;
   	end loop;
      return;
 	end if;

	if in_action != 'P' then
	   for oh in (select orderid, shipid from orderhdr
  	               where loadno = inp.loadno) loop
		   open c_sp(oh.orderid, oh.shipid);
  	  	   fetch c_sp into sp;
  		   close c_sp;
         if in_action = 'N' then
      	   select count(1) into l_cnt
         	   from weber_eso_ordlbl_table
         	   where orderid = oh.orderid
                 and shipid = oh.shipid;
		   else
      	   l_cnt := 0;
		   end if;

         if l_cnt = 0 then
			   eso_order_label(sp.lpid, in_func, in_action, l_msg);
		   end if;
  	   end loop;
	end if;

	out_stmt := 'select * from weber_eso_ordlbl_view where loadno = ' || inp.loadno;

end eso_load_label;


procedure eso_wave_label
   (in_lpid    in varchar2,
    in_func    in varchar2,
    in_action  in varchar2,
    out_stmt   out varchar2)
is
	cursor c_inp is
     select H.wave
       from shippingplate S, orderhdr H
      where S.lpid = in_lpid
        and H.orderid = S.orderid
        and H.shipid = S.shipid;
	cursor c_inf is
     select distinct H.wave
       from shippingplate S, orderhdr H
      where S.fromlpid = in_lpid
        and H.orderid = S.orderid
        and H.shipid = S.shipid;
	inp c_inp%rowtype;
   cursor c_sp(p_orderid number, p_shipid number) is
   	select lpid
      	from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid;
	sp c_sp%rowtype;
	l_cnt pls_integer := 0;
   l_msg varchar2(81);
begin

   out_stmt := null;

   if substr(in_lpid,-1,1) = 'S' then
 		open c_inp;
     	fetch c_inp into inp;
     	if c_inp%found then
      	l_cnt := 1;
		end if;
     	close c_inp;
   else
     	open c_inf;
     	fetch c_inf into inp;
     	if c_inf%found then
         l_cnt := 1;
      	fetch c_inf into inp;
       	if c_inf%found then  -- wave not unique
         	l_cnt := 2;
       	end if;
     	end if;
     	close c_inf;
   end if;

   if l_cnt != 1 then
   	if in_func = 'Q' then
			if l_cnt = 0 then
         	out_stmt := 'Wave not found';
			else
         	out_stmt := 'Wave not unique';
			end if;
    	end if;
      return;
	end if;

   if inp.wave = 0 then
   	if in_func = 'Q' then
   		out_stmt := 'No wave assigned';
    	end if;
      return;
	end if;

  	if in_func = 'Q' then
   	if in_action = 'P' then
      	select count(1) into l_cnt
     			from weber_eso_ordlbl_table
    			where (orderid, shipid) in (select orderid, shipid
            				from orderhdr where wave = inp.wave);
			if l_cnt = 0 then
         	out_stmt := 'Nothing for wave';
            return;
			end if;
		end if;

     	out_stmt := 'OKAY';
		for oh in (select orderid, shipid from orderhdr
   	            where wave = inp.wave) loop
			open c_sp(oh.orderid, oh.shipid);
   	  	fetch c_sp into sp;
     		close c_sp;
			eso_order_label(sp.lpid, in_func, '?', l_msg);		-- avoid "nothing for order" msg
         if l_msg != 'OKAY' then
         	out_stmt := l_msg;
            exit;
			end if;
   	end loop;
      return;
 	end if;

	if in_action != 'P' then
	   for oh in (select orderid, shipid from orderhdr
  	               where wave = inp.wave) loop
		   open c_sp(oh.orderid, oh.shipid);
  	  	   fetch c_sp into sp;
  		   close c_sp;
         if in_action = 'N' then
      	   select count(1) into l_cnt
         	   from weber_eso_ordlbl_table
         	   where orderid = oh.orderid
                 and shipid = oh.shipid;
		   else
      	   l_cnt := 0;
		   end if;

         if l_cnt = 0 then
			   eso_order_label(sp.lpid, in_func, in_action, l_msg);
		   end if;
  	   end loop;
	end if;

	out_stmt := 'select * from weber_eso_ordlbl_view V, orderhdr H where H.wave = '
   		|| inp.wave || ' and V.orderid = H.orderid and V.shipid = H.shipid';

end eso_wave_label;


end weber_labels;
/

show errors package body weber_labels;
exit;
