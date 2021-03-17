create or replace package body alps.zbillutility as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--
-- Return Status
GOOD            CONSTANT        integer := 1;
BAD             CONSTANT        integer := 0;


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

  CURSOR C_DFLT(in_id varchar2)
  IS
    SELECT to_number(defaultvalue)
      FROM systemdefaults
     WHERE defaultid = in_id;


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************






----------------------------------------------------------------------
--
-- from_uom_to_uom - try to go from one uom to another uom
--
----------------------------------------------------------------------
PROCEDURE from_uom_to_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    in_skips    IN      varchar2,
    io_level    IN OUT  integer,
    io_qty      IN OUT     number,
    io_errmsg   IN OUT     varchar2
)
IS

  t_uom  custitemuom.fromuom%type;

CURSOR C_CNV(in_from_uom varchar2)
RETURN conversions%rowtype
IS
   SELECT *
     FROM conversions
    WHERE (fromuom = in_from_uom
         OR touom = in_from_uom);

my_skips varchar2(4000);
l_cmd_uom varchar2(4000);
ciuom custitemuom%rowtype;
TYPE cur_type is REF CURSOR;
l_cur_uom cur_type;

BEGIN
    io_errmsg := '';
    io_level := nvl(io_level,1) + 1;

    if io_level > 10 THEN
       io_errmsg := 'FAILED: Too many levels';
       return;
    end if;

    if in_from_uom = in_to_uom THEN
        io_qty := in_qty;
        io_errmsg := 'OKAY';
        return;
    end if;

    my_skips := in_skips;
    l_cmd_uom := 'select sequence, fromuom, touom, qty ' ||
                 '  from custitemuom ' ||
                 ' where custid = ''' || in_custid || '''' ||
                 '   and item = ''' || in_item || '''' ||
                 '   and (fromuom = ''' || in_from_uom || '''' ||
                 '     or touom = ''' || in_from_uom || ''')';
    if rtrim(my_skips) is not null then
      l_cmd_uom := l_cmd_uom || ' and sequence ' ||
        zbut.in_num_clause('E', my_skips);
    end if;
    l_cmd_uom := l_cmd_uom || ' order by sequence';
    open l_cur_uom for l_cmd_uom;
    loop
      fetch l_cur_uom into ciuom.sequence, ciuom.fromuom,
        ciuom.touom, ciuom.qty;
      exit when l_cur_uom%notfound;
      -- zut.prt('C_UOM returned From:'||crec.fromuom||' To:'||crec.touom);
      if ciuom.fromuom = in_from_uom then
          if nvl(ciuom.qty,0) = 0 then
              io_qty := null; -- in_qty;
          else
              io_qty := in_qty / ciuom.qty;
          end if;
          t_uom := ciuom.touom;
      else
          t_uom := ciuom.fromuom;
          io_qty := in_qty * ciuom.qty;
      end if;
      if ciuom.touom = in_to_uom THEN
         io_errmsg := 'OKAY';
         return;
      end if;
      if rtrim(my_skips) is not null then
        my_skips := my_skips || ',';
      end if;
      my_skips := my_skips || ciuom.sequence;
      from_uom_to_uom(in_custid, in_item, io_qty,
                    t_uom, in_to_uom,
                    my_skips, io_level,
                    io_qty, io_errmsg);
      if io_errmsg = 'OKAY' THEN
         return;
      end if;
    end loop;

    for crec in C_CNV(in_from_uom) loop
        -- zut.prt('C_UOM returned From:'||crec.fromuom||' To:'||crec.touom);
        if crec.fromuom = in_from_uom then
            if nvl(crec.qty,0) = 0 then
                io_qty := null; -- in_qty;
            else
                io_qty := in_qty / crec.qty;
            end if;
            t_uom := crec.touom;
        else
            t_uom := crec.fromuom;
            io_qty := in_qty * crec.qty;
        end if;
        if crec.touom = in_to_uom THEN
           io_errmsg := 'OKAY';
           return;
        end if;
        from_uom_to_uom(in_custid, in_item, io_qty,
                      t_uom, in_to_uom,
                      my_skips, io_level,
                      io_qty, io_errmsg);
        if io_errmsg = 'OKAY' THEN
           return;
        end if;
    end loop;

    io_errmsg := 'FAILED: Reached end of path';
    return;

END from_uom_to_uom;


----------------------------------------------------------------------
--
-- translate_uom - determine uom qty from one uom to another
--
----------------------------------------------------------------------
PROCEDURE translate_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    out_qty     OUT     number,
    out_errmsg  OUT     varchar2
)
IS
errmsg  varchar2(200);
qty     number;
start_level   integer;
BEGIN
    out_errmsg := '';
    start_level := 1;

    from_uom_to_uom(in_custid, in_item, 1,
                           in_from_uom, in_to_uom, '', start_level,
                           qty, errmsg);

    if errmsg = 'OKAY' THEN
       out_errmsg := 'OKAY';
       out_qty := in_qty * qty;
       if (qty < 1) and (round(mod(out_qty,1),6) = 1) then
         out_qty := floor(out_qty+.000001);
       end if;
       return;
    end if;

    out_errmsg := errmsg;
    out_qty := null;
    return;

END translate_uom;


----------------------------------------------------------------------
--
-- translate_uom_function - determine uom qty from one uom to another
--
----------------------------------------------------------------------
FUNCTION translate_uom_function
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_qty      IN      number,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2
)
RETURN number
IS
errmsg  varchar2(200);
out_qty number;
qty     number;
start_level   integer;
BEGIN
    out_qty := null;
    start_level := 1;

    from_uom_to_uom(in_custid, in_item, 1,
                           in_from_uom, in_to_uom, '', start_level,
                           qty, errmsg);

    if errmsg = 'OKAY' THEN
       out_qty := in_qty * qty;
       if (qty < 1) and (round(mod(out_qty,1),6) = 1) then
         out_qty := floor(out_qty+.000001);
       end if;
    end if;

    return out_qty;

END translate_uom_function;


----------------------------------------------------------------------
--
-- check_uom_to_uom -
--
----------------------------------------------------------------------
FUNCTION check_uom_to_uom
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_from_uom IN      varchar2,
    in_to_uom   IN      varchar2,
    in_level    IN      number,
    in_skips    IN      varchar2
)
RETURN integer
IS
  CURSOR C_UOM(in_cust varchar2,
             in_item varchar2,
             in_from_uom varchar2)
  RETURN custitemuom%rowtype
  IS
   SELECT *
     FROM custitemuom
    WHERE custid = in_cust
      AND item   = in_item
      AND (fromuom = in_from_uom
         OR touom = in_from_uom);
  t_uom  custitemuom.fromuom%type;

  CURSOR C_CNV(in_from_uom varchar2)
  RETURN conversions%rowtype
  IS
   SELECT *
     FROM conversions
    WHERE (fromuom = in_from_uom
         OR touom = in_from_uom);


 my_level number;
 my_skips varchar2(200);

BEGIN

    my_level := nvl(in_level,1) + 1;

    -- zut.prt('Level:'||to_char(my_level)||
    --    ' Trying from:'||in_from_uom||' To:'||in_to_uom);

    if my_level > 10 THEN
       return 0;
    end if;

    if in_from_uom = in_to_uom then
       return 1;
    end if;

    if instr(in_skips,'|'||in_from_uom||'|') > 0 then
       return 0;
    end if;

    my_skips := nvl(in_skips,'|')||in_from_uom||'|';


    for crec in C_UOM(in_custid, in_item, in_from_uom) loop
        if crec.fromuom = in_from_uom then
            t_uom := crec.touom;
        else
            t_uom := crec.fromuom;
        end if;
        if crec.touom = in_to_uom THEN
           return 1;
        end if;
        if check_uom_to_uom(in_custid, in_item,
                      t_uom, in_to_uom,
                      my_level, my_skips) > 0 then
           return 1;
        end if;
    end loop;

    for crec in C_CNV(in_from_uom) loop
        if crec.fromuom = in_from_uom then
            t_uom := crec.touom;
        else
            t_uom := crec.fromuom;
        end if;
        if crec.touom = in_to_uom THEN
           return 1;
        end if;
        if check_uom_to_uom(in_custid, in_item,
                      t_uom, in_to_uom,
                      my_level, my_skips) > 0 then
           return 1;
        end if;
    end loop;


    return 0;



END check_uom_to_uom;


----------------------------------------------------------------------
--
-- invoice_total
--
----------------------------------------------------------------------
FUNCTION invoice_total
(
    in_invoice   IN      number,
    in_invtype   IN     varchar2
)
RETURN number
IS
  invoice_amt number;
BEGIN


    if in_invoice > 0 then
       select sum(nvl(billedamt,(nvl(calcedamt,0))))
         into invoice_amt
         from invoicedtl
        where invoice = in_invoice
          and billstatus != '4';
    else
       select sum(nvl(billedamt,(nvl(calcedamt,0))))
         into invoice_amt
         from invoicedtl
        where invoice = 0
          and orderid = -in_invoice
          and billstatus != '4';
    end if;

    if in_invtype = 'C' then    -- can't use zbill.IT_CREDIT because of pragma
        return -invoice_amt;
    end if;

    return invoice_amt;

END invoice_total;



----------------------------------------------------------------------
--
-- master_invoice_total
--
----------------------------------------------------------------------
FUNCTION master_invoice_total
(
    in_master    IN      varchar2
)
RETURN number
IS
  invoice_amt number;
BEGIN


    select sum(nvl(billedamt,(nvl(calcedamt,0))))
      into invoice_amt
      from invoicedtl D, invoicehdr H
     where H.masterinvoice = in_master
       and D.invoice = H.invoice
       and D.billstatus != '4';

    return invoice_amt;

END master_invoice_total;


----------------------------------------------------------------------
--
-- invoice_check_sum
--
----------------------------------------------------------------------
FUNCTION invoice_check_sum
(
    in_invoice   IN      number
)
RETURN varchar2
IS
  invoice_cnt number;
  limit number;
BEGIN

-- get the actual limit
  BEGIN
    limit := 9999999;
    OPEN C_DFLT('SUMMARIZEASSESSORIALLIMIT');
    FETCH C_DFLT into limit;
  EXCEPTION
    when others then
       limit := 9999999;
  END;
  CLOSE C_DFLT;

    if in_invoice > 0 then
       select count(1)
         into invoice_cnt
         from invoicedtl
        where invoice = in_invoice
          and billstatus != '4';
    else
       select count(1)
         into invoice_cnt
         from invoicedtl
        where invoice = 0
          and orderid = -in_invoice
          and billstatus != '4';
    end if;

    if invoice_cnt > limit then
        return 'Y';
    end if;

    return 'N';

END invoice_check_sum;



----------------------------------------------------------------------
--
-- asof_begin
--
----------------------------------------------------------------------
FUNCTION asof_begin
(
    in_facility  IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_inventoryclass IN      varchar2,
    in_effdate   IN      date
)
RETURN number
IS
 CURSOR C_ASOF
 IS
   SELECT sum(currentqty)
     FROM asofinventory M
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(inventoryclass,'RG') = nvl(in_inventoryclass,'RG')
      and effdate =
      (select max(effdate)
         from asofinventory S
        where S.facility = M.facility
          and custid = M.custid
          and item = M.item
          and nvl(S.lotnumber, 'XXX') = nvl(M.lotnumber,'XXX')
          and nvl(S.uom,'XXX') = nvl(M.uom,'XXX')
          and nvl(S.invstatus,'XXX') = nvl(M.invstatus,'XXX')
          and nvl(S.inventoryclass,'RG') = nvl(M.inventoryclass,'RG')
          and S.effdate < trunc(in_effdate));

c_qty number;

BEGIN

c_qty := 0;

OPEN C_ASOF;
FETCH C_ASOF into c_qty;
CLOSE C_ASOF;

return nvl(c_qty,0);

END asof_begin;


----------------------------------------------------------------------
--
-- asof_end
--
----------------------------------------------------------------------
FUNCTION asof_end
(
    in_facility  IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_inventoryclass IN      varchar2,
    in_effdate   IN      date
)
RETURN number
IS
 CURSOR C_ASOF
 IS
   SELECT sum(currentqty)
     FROM asofinventory M
    WHERE facility = in_facility
      and custid = in_custid
      and item = in_item
      and nvl(inventoryclass,'RG') = nvl(in_inventoryclass,'RG')
      and effdate =
      (select max(effdate)
         from asofinventory S
        where S.facility = M.facility
          and custid = M.custid
          and item = M.item
          and nvl(S.lotnumber, 'XXX') = nvl(M.lotnumber,'XXX')
          and nvl(S.uom,'XXX') = nvl(M.uom,'XXX')
          and nvl(S.invstatus,'XXX') = nvl(M.invstatus,'XXX')
          and nvl(S.inventoryclass,'RG') = nvl(M.inventoryclass,'RG')
          and S.effdate <= trunc(in_effdate));

c_qty number;

BEGIN

c_qty := 0;

OPEN C_ASOF;
FETCH C_ASOF into c_qty;
CLOSE C_ASOF;

return nvl(c_qty,0);

END asof_end;



----------------------------------------------------------------------
--
-- item_rategroup
--
----------------------------------------------------------------------
FUNCTION item_rategroup
(
    in_custid    IN      varchar2,
    in_item      IN      varchar2
)
RETURN rategrouptype
IS
/*
CURSOR C_CIV_9i(in_custid varchar2, in_item varchar2)
   IS
     SELECT decode(nvl(G.linkyn,'N'),
        'Y', rategrouptype('DEFAULT', G.linkrategroup),
             rategrouptype(I.custid, I.rategroup))
       FROM custrategroup G, custitemview I
      WHERE I.custid = in_custid
        AND I.item = in_item
        AND G.custid = I.custid
        AND G.rategroup = I.rategroup;
*/

   CURSOR C_CIV(in_custid varchar2, in_item varchar2)
   IS
     SELECT decode(rategrouptype(nvl(G.linkyn,'N'),'Y'),
        rategrouptype('Y','Y'),
             rategrouptype('DEFAULT', G.linkrategroup),
             rategrouptype(I.custid, I.rategroup))
       FROM custrategroup G, custitemview I
      WHERE I.custid = in_custid
        AND I.item = in_item
        AND G.custid = I.custid
        AND G.rategroup = I.rategroup;


l_rg rategrouptype;
BEGIN

    OPEN C_CIV(in_custid, in_item);
    FETCH C_CIV into l_rg;
    CLOSE C_CIV;

    return l_rg;
EXCEPTION WHEN OTHERS THEN
    l_rg := rategrouptype('CCC','III');
    return l_rg;
END item_rategroup;

----------------------------------------------------------------------
--
-- rategroup
--
----------------------------------------------------------------------
FUNCTION rategroup
(
    in_custid    IN      varchar2,
    in_rategroup IN      varchar2
)
RETURN rategrouptype
IS
/*
CURSOR C_CRG_9i(in_custid varchar2, in_rategroup varchar2)
   IS
     SELECT decode(nvl(linkyn,'N'),
        'Y', rategrouptype('DEFAULT', linkrategroup),
             rategrouptype(custid, rategroup))
       FROM custrategroup
      WHERE custid = in_custid
        AND rategroup = in_rategroup;
*/

   CURSOR C_CRG(in_custid varchar2, in_rategroup varchar2)
   IS
     SELECT decode(rategrouptype(nvl(linkyn,'N'),'Y'),
        rategrouptype('Y','Y'),
             rategrouptype('DEFAULT', linkrategroup),
             rategrouptype(custid, rategroup))
       FROM custrategroup
      WHERE custid = in_custid
        AND rategroup = in_rategroup;


l_rg rategrouptype;
BEGIN

    OPEN C_CRG(in_custid, in_rategroup);
    FETCH C_CRG into l_rg;
    CLOSE C_CRG;

    return l_rg;
EXCEPTION WHEN OTHERS THEN
    l_rg := rategrouptype('CCC','GGG');
    return l_rg;
END rategroup;

----------------------------------------------------------------------
--
-- check_rg_bm_event - determine if a rategroup uses a particular billing 
--                     method for a particular event
--
----------------------------------------------------------------------
function check_rg_bm_event
(
  in_custid in varchar2,
  in_rategroup in varchar2,
  in_billmethod in varchar2,
  in_event in varchar2,
  in_effdate in date
)
return number
is
  v_count number;
begin
  select count(1) into v_count
  from custratewhen a, custrategroup b
  where a.custid = in_custid
    and a.rategroup = in_rategroup
    and a.businessevent  = in_event
    and a.billmethod = in_billmethod
    and a.automatic in ('A','C')
    and b.custid = a.custid
    and b.rategroup = a.rategroup
    and b.status = 'ACTV'
    and a.effdate  =
     (select max(effdate)
      from custrate
      where custid = a.custid
        and activity = a.activity
        and billmethod = a.billmethod
        and rategroup = a.rategroup
        and effdate <= trunc(in_effdate));
  
  return v_count;
end check_rg_bm_event;


----------------------------------------------------------------------
--
-- get_handling_types - return a comma delimited list of all handling types for the plate
--
----------------------------------------------------------------------
function get_handling_types
(
  in_lpid in varchar2
)
return varchar2
as
  v_return_value varchar2(500) := ',';
begin
  
  for rec in (select distinct recmethod
              from plate
              where recmethod is not null
              start with lpid = in_lpid
              connect by prior lpid = parentlpid)
  loop
    v_return_value := v_return_value || rec.recmethod || ',';
  end loop;
  
  for rec in (select distinct recmethod
              from deletedplate
              where recmethod is not null
              start with lpid = in_lpid
              connect by prior lpid = parentlpid)
  loop
    v_return_value := v_return_value || rec.recmethod || ',';
  end loop;
  
  return v_return_value;
              
end get_handling_types;


----------------------------------------------------------------------
--
-- get_lottrack_req
--
----------------------------------------------------------------------
function prnt_get_lottrack_req
(
  in_lpid in varchar2,
  in_event in varchar2,
  in_effdate in date
)
return varchar2
as
  v_tracklot custitem.lotrequired%type;
begin

  if (in_event = zbill.EV_RECEIPT) then
    for rec in (select distinct a.custid, a.item, b.lotrequired as item_lotrequired, 
                  c.lotrequired as cust_lotrequired, b.lotsumreceipt
                from orderdtlrcpt a, custitem b, customer c
                where nvl(parentlpid,lpid) = in_lpid
                  and a.custid = b.custid and a.item = b.item and b.custid = c.custid)
    loop
      if (rec.lotsumreceipt <> 'Y') then
        select decode(nvl(rec.item_lotrequired,'C'),'C',rec.cust_lotrequired,rec.item_lotrequired)
        into v_tracklot
        from dual;
        
        if (v_tracklot in ('Y','O','S','A')) then
          return 'Y';
        end if;
      end if;
    end loop;
  elsif (in_event = zbill.EV_RENEWAL) then
    for rec in (select distinct a.custid, a.item, b.lotrequired as item_lotrequired, 
                  c.lotrequired as cust_lotrequired, b.lotsumreceipt
                from billparentpltcnt a, custitem b, customer c
                where effdate = in_effdate and nvl(parentlpid,lpid) = in_lpid
                  and a.custid = b.custid and a.item = b.item and b.custid = c.custid)
    loop
      if (rec.lotsumreceipt <> 'Y') then
        select decode(nvl(rec.item_lotrequired,'C'),'C',rec.cust_lotrequired,rec.item_lotrequired)
        into v_tracklot
        from dual;
        
        if (v_tracklot in ('Y','O','S','A')) then
          return 'Y';
        end if;
      end if;
    end loop;
  end if;
  
  return 'N';
  
end prnt_get_lottrack_req;


----------------------------------------------------------------------
--
-- get_nextbilldate - determine the next bill date from the billing
--                    cycle information
--
----------------------------------------------------------------------
FUNCTION get_nextbilldate
(
    in_lastbilldate IN      date,
    in_billfreq     IN      varchar2,
    in_billday      IN      number,
    out_nextbilldate OUT    date
)
RETURN integer
IS
  last_bill_date        DATE;
  wk_date                       DATE;
  work_date             varchar2(12);
  tmp_billday  integer;

BEGIN


    last_bill_date := trunc(in_lastbilldate);

    if last_bill_date is null then
    --   last_bill_date := to_date('19990101','YYYYMMDD');
       last_bill_date := trunc(sysdate) - 1;  -- Pretend we just billed
    end if;

    if in_billfreq = 'M' then
        wk_date := add_months(last_bill_date,1);
        work_date := to_char(wk_date, 'YYYYMMDD');
        tmp_billday := to_number(to_char(last_day(wk_date),'DD'));
        if in_billday < tmp_billday then
             tmp_billday := in_billday;
        end if;
        out_nextbilldate := to_date(substr(work_date, 1, 6)
                              || substr(to_char(tmp_billday,'09'),2),
                             'YYYYMMDD');
    elsif in_billfreq = 'E' then
        wk_date := add_months(last_bill_date,1);
        out_nextbilldate := last_day(wk_date);
    elsif in_billfreq = 'W' then
        if in_billday = 1 then
             work_date := 'Monday';
        elsif in_billday = 2 then
             work_date := 'Tuesday';
        elsif in_billday = 3 then
             work_date := 'Wednesday';
        elsif in_billday = 4 then
             work_date := 'Thursday';
        elsif in_billday = 5 then
             work_date := 'Friday';
        elsif in_billday = 6 then
             work_date := 'Saturday';
        else
             work_date := 'Sunday';
        end if;

        out_nextbilldate := next_day(last_bill_date,
                                work_date);
        null;
    elsif in_billfreq = 'D' then
        out_nextbilldate := trunc(sysdate);
    elsif in_billfreq = 'C' then -- Special case for assessorial billing
        out_nextbilldate := trunc(last_bill_date+1);
    else
        return BAD;
    end if;

    return GOOD;
END get_nextbilldate;



----------------------------------------------------------------------
--
-- check_asof - determine if there is inventory in facility for
--      the customer on the specified date
--
----------------------------------------------------------------------
FUNCTION check_asof
(in_facility IN varchar2
,in_custid IN varchar2
,in_billdate IN date
) return varchar2
IS
got_it varchar2(1);

cursor C_ANY
IS
select custid
  from asofinventory
 where facility = in_facility
   and custid = in_custid;

cursor C_DATE(in_sd date)
IS
select custid
  from asofinventory
 where facility = in_facility
   and custid = in_custid
   and currentqty > 0
   and (item, nvl(lotnumber,'(none)'), effdate, invstatus, inventoryclass) in
     (select B.item,
             nvl(B.lotnumber,'(none)'), max(B.effdate),
            B.invstatus, B.inventoryclass
        from asofinventory B
       where B.custid = in_custid
         and B.facility = in_facility
         and B.effdate <= in_billdate
     and B.effdate > in_sd
     group by B.item, nvl(B.lotnumber,'(none)'),
            B.invstatus, B.inventoryclass)
   and rownum < 2;


AI C_DATE%rowtype;

cursor C_INV
IS
select custid
  from invoicedtl
 where facility = in_facility
   and custid = in_custid
   and invoice = 0
   and invtype = 'S'
   and invdate <= in_billdate;

INV C_INV%rowtype;

startdt date;


  CURSOR C_SD(in_id varchar2)
  IS
  SELECT defaultvalue
    FROM systemdefaults
   WHERE defaultid = in_id;

  lrr systemdefaults.defaultvalue%type;

  cnt integer;

 asofeomstart systemdefaults.defaultvalue%type;

CURSOR C_CUST (in_custi varchar2)
IS
SELECT *
  FROM customer
 WHERE custid = in_custid;

CUST customer%rowtype;

 tdate date;
 lastrenewal date;


BEGIN
    got_it := 'N';

    AI := null;
    OPEN C_ANY;
    FETCH C_ANY into AI;
    CLOSE C_ANY;

    if AI.custid is null then
        return 'N';
    end if;

    startdt := in_billdate;

    AI := null;
    OPEN C_DATE(startdt - 1);
    FETCH C_DATE into AI;
    CLOSE C_DATE;

    if AI.custid is not null then
        return 'Y';
    end if;

    AI := null;
    OPEN C_DATE(startdt - 40);
    FETCH C_DATE into AI;
    CLOSE C_DATE;

    if AI.custid is not null then
        return 'Y';
    end if;

-- check for asof eom setup
    asofeomstart := null;
    OPEN C_SD('asofeomstart');
    FETCH C_SD into asofeomstart;
    CLOSE C_SD;

    if to_char(startdt,'YYYYMMDD') < nvl(asofeomstart,'99991231') then
        AI := null;
        OPEN C_DATE(startdt - 1000);
        FETCH C_DATE into AI;
        CLOSE C_DATE;

        if AI.custid is not null then
            return 'Y';
        end if;
    end if;

    INV := null;
    OPEN C_INV;
    FETCH C_INV into INV;
    CLOSE C_INV;

    if INV.custid is not null then
        return 'Y';
    end if;

-- Check for lot renewal customers if have inventory in the range.

-- check for lot receipt renewal processing
    lrr := null;
    OPEN C_SD('LOTRECEIPTRENEWAL');
    FETCH C_SD into lrr;
    CLOSE C_SD;


    if nvl(lrr, 'N') = 'Y' then

      CUST := null;
      OPEN C_CUST(in_custid);
      FETCH C_CUST into CUST;
      CLOSE C_CUST;

      if CUST.custid is null then
         return 'N';
      end if;


      cnt := 0;

      select count(1)
        into cnt
        from custratewhen
       where  (custid,rategroup) in
              (select decode(nvl(linkyn,'N'),'Y','DEFAULT',custid),
                      decode(nvl(linkyn,'N'),'Y',linkrategroup,rategroup)
                 from custrategroup where custid = in_custid)
         and billmethod in ('QTLR','CWLR','WTLR');


      if cnt > 0 then
        null;
    -- Determine last renewal
        lastrenewal := null;

        if CUST.rnewbillfreq in ('M','E') then
            tdate := add_months(in_billdate, -2);

            loop

            if get_nextbilldate(tdate,
                    CUST.rnewbillfreq, CUST.rnewbillday,tdate) = 0
            then
                tdate := in_billdate;
            end if;
            if tdate < in_billdate then
                lastrenewal := tdate;
            end if;
            if trunc(in_billdate) <= tdate then exit; end if;

            end loop;

        else
          select max(billdate)
            into lastrenewal
            from custbillschedule
           where custid = in_custid
             and type = decode(CUST.rnewbillfreq,
                                'C','Renewal',
                                'F','Default',
                                null)
             and billdate < in_billdate;
        end if;


        if lastrenewal is not null then
            cnt := 0;
            select count(1)
              into cnt
              from asofinventory
             where effdate > lastrenewal
               and effdate < in_billdate
               and facility = in_facility
               and custid = in_custid;

            if nvl(cnt,0) > 0 then
                return 'Y';
            end if;
        end if;

      end if;

    end if;

    return 'N';

EXCEPTION WHEN OTHERS THEN
    return got_it||'err';
END check_asof;

----------------------------------------------------------------------
--
-- next_daily_billing - return datetime when daily billing job should run
--
----------------------------------------------------------------------
FUNCTION next_daily_billing
return date
IS
CURSOR C_TIME
IS
select substr(defaultvalue,1,4)
  from systemdefaults
 where defaultid = 'DAILY_BILLING_RUNTIME';

tm varchar2(4);
hh integer;
mi integer;

dt date;

l_date date;

BEGIN
    TM := null;
    OPEN C_TIME;
    FETCH C_TIME into TM;
    CLOSE C_TIME;

    if TM is null then
        TM := '0010';
    else
      begin
        TM := to_char(to_number(TM),'FM0009');
      exception when others then
        TM := '0010';
      end;
    end if;

    hh := to_number(substr(tm,1,2));
    mi := to_number(substr(tm,3,2));

    l_date := trunc(sysdate+1) + hh/24 + mi/1440;

    return l_date;

END next_daily_billing;

----------------------------------------------------------------------
--
-- check_expiregrace - Check if there is any expired grace items
--
----------------------------------------------------------------------
FUNCTION check_expiregrace
(  in_facility IN varchar2
  ,in_custid   IN varchar2
  ,in_billdate IN date
) RETURN varchar2 
IS
  CURSOR C_RS_GRACE(in_facility varchar2,
                    in_custid varchar2,
                    in_billdate date)
  IS
    SELECT facility, rowid
      FROM invoicedtl
     WHERE facility = in_facility
       AND custid = in_custid
       AND billstatus in (zbill.NOT_REVIEWED, zbill.REVIEWED)
       AND invoice = 0
       AND expiregrace <= in_billdate;

  expgraceitems C_RS_GRACE%rowtype;
  
BEGIN
  open C_RS_GRACE(in_facility, in_custid, in_billdate);
  fetch C_RS_GRACE into expgraceitems;
    
  if C_RS_GRACE%notfound then
    return 'N';
  else
    return 'Y';
  end if;
  close C_RS_GRACE;
  
END check_expiregrace;

function in_num_clause
(in_indicator varchar2
,in_values varchar2
) return varchar2 is
returnstr varchar2(255);
wkstr varchar2(255);
position integer;
needcomma boolean;
begin
returnstr := '';
if upper(nvl(rtrim(in_indicator),'I')) = 'E' then
  returnstr := 'not ';
end if;
returnstr := returnstr || 'in (';
wkstr := rtrim(in_values);
needcomma := False;
while length(wkstr) <> 0
loop
  position := instr(wkstr,',');
  if needcomma then
    returnstr := returnstr || ',';
  else
    needcomma := true;
  end if;
  if position = 0 then
    returnstr := returnstr || wkstr;
    wkstr := '';
  else
    returnstr := returnstr || substr(wkstr,1,position-1);
    wkstr := substr(wkstr,position+1,length(wkstr)-position);
  end if;
end loop;
returnstr := returnstr || ')';
return returnstr;
exception when others then
  return returnstr;
end in_num_clause;
end zbillutility;
/
show error package body zbillutility;
exit;
