create or replace PACKAGE BODY alps.zreaddata
IS

-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--

debug_on    BOOLEAN := False;


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- debug_trace - turn on/off debug tracing
--
----------------------------------------------------------------------
PROCEDURE debug_trace(in_mode boolean)
IS
BEGIN
    debug_on := nvl(in_mode,False);
END debug_trace;

----------------------------------------------------------------------
--
-- dbmsg - If in debug mode print message
--
----------------------------------------------------------------------
PROCEDURE dbmsg(in_text varchar2)
IS

cntChar integer;

BEGIN

    if not debug_on then
        return;
    end if;

    cntChar := 1;
    while (cntChar * 60) < (Length(in_text)+60)
    loop
        zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
        cntChar := cntChar + 1;
    end loop;

EXCEPTION WHEN OTHERS THEN
    null;
END dbmsg;


----------------------------------------------------------------------
--
-- get_orderhdr - 
--
----------------------------------------------------------------------
PROCEDURE get_orderhdr(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_orderid OUT number,
    out_shipid OUT number)
IS
cmd varchar2(500);

l_orderid orderhdr.orderid%type;
l_shipid orderhdr.orderid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select /*+ FIRST_ROWS */ orderid, shipid from orderhdr where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (orderid > '||in_orderid
                   ||' or (orderid = '||in_orderid
                    ||' and shipid > '||in_shipid||')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by orderid, shipid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (orderid < '||in_orderid
                   ||' or (orderid = '||in_orderid
                    ||' and shipid < '||in_shipid||')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by orderid desc, shipid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_orderid, l_shipid;
    close cmc;


    out_orderid := nvl(l_orderid,0);
    out_shipid := nvl(l_shipid,0);

EXCEPTION WHEN OTHERS THEN
    out_orderid := 0;
    out_shipid := 0;
    zut.prt(sqlerrm);
END get_orderhdr;

----------------------------------------------------------------------
--
-- get_returns_orderhdr - 
--
----------------------------------------------------------------------
PROCEDURE get_returns_orderhdr(
    in_facility IN  varchar2,
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_orderid OUT number,
    out_shipid OUT number)
IS
cmd varchar2(500);

l_orderid orderhdr.orderid%type;
l_shipid orderhdr.orderid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select orderid, shipid from orderhdr where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (is_returns_order > ''Y'||in_facility
                   || to_char(in_orderid,'FM00000000009')
                   ||'-'||to_char(in_shipid,'FM09')||''')';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by is_returns_order';
    end if;
    if in_action = 'PREV' then

        cmd := cmd ||' (is_returns_order < ''Y'||in_facility
                   || to_char(in_orderid,'FM00000000009')
                   ||'-'||to_char(in_shipid,'FM09')||''')';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by is_returns_order desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_orderid, l_shipid;
    close cmc;


    out_orderid := nvl(l_orderid,0);
    out_shipid := nvl(l_shipid,0);

EXCEPTION WHEN OTHERS THEN
    out_orderid := 0;
    out_shipid := 0;
    zut.prt(sqlerrm);
END get_returns_orderhdr;


----------------------------------------------------------------------
--
-- get_loads - 
--
----------------------------------------------------------------------
PROCEDURE get_loads(
    in_loadno  IN  number,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_loadno OUT number)
IS
cmd varchar2(500);

l_loadno loads.loadno%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select loadno from loads where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (loadno > '||in_loadno||') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by loadno';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (loadno < '||in_loadno||') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by loadno desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_loadno;
    close cmc;


    out_loadno := nvl(l_loadno,0);

EXCEPTION WHEN OTHERS THEN
    out_loadno := 0;
    zut.prt(sqlerrm);
END get_loads;

----------------------------------------------------------------------
--
-- get_plate - 
--
----------------------------------------------------------------------
PROCEDURE get_plate(
    in_table    IN  varchar2,
    in_lpid     IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_lpid OUT varchar2)
IS
cmd varchar2(500);

l_lpid plate.lpid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select lpid from '||in_table||' where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (lpid > '''||in_lpid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by lpid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (lpid < '''||in_lpid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;

                
        cmd := cmd ||' order by lpid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_lpid;
    close cmc;


    out_lpid := l_lpid;

EXCEPTION WHEN OTHERS THEN
    out_lpid := '';
    zut.prt(sqlerrm);
END get_plate;


----------------------------------------------------------------------
--
-- get_shippingplate - 
--
----------------------------------------------------------------------
PROCEDURE get_shippingplate(
    in_lpid     IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_lpid OUT varchar2)
IS
cmd varchar2(500);

l_lpid plate.lpid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select lpid from shippingplate where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (lpid > '''||in_lpid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by lpid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (lpid < '''||in_lpid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by lpid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_lpid;
    close cmc;


    out_lpid := l_lpid;

EXCEPTION WHEN OTHERS THEN
    out_lpid := '';
    zut.prt(sqlerrm);
END get_shippingplate;

----------------------------------------------------------------------
--
-- get_customer - 
--
----------------------------------------------------------------------
PROCEDURE get_customer(
    in_custid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid  OUT varchar2)
IS
cmd varchar2(500);

l_custid customer.custid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select custid from customer where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (custid > '''||in_custid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (custid < '''||in_custid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_custid;
    close cmc;


    out_custid := l_custid;

EXCEPTION WHEN OTHERS THEN
    out_custid := '';
    zut.prt(sqlerrm);
END get_customer;

----------------------------------------------------------------------
--
-- get_label - 
--
----------------------------------------------------------------------
PROCEDURE get_label(
    in_code        IN  varchar2,
    in_action      IN  varchar2,
    in_labelfilter IN varchar2,
    out_code       OUT varchar2,
	out_first      OUT varchar2,	    
	out_last       OUT varchar2)	
IS
cmd  varchar2(500);
cmd1 varchar2(500);					

l_code labelprofiles.code%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select code from labelprofiles where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (code > '''||in_code||''') ';
        if in_labelfilter is not null then
            cmd := cmd || 'and '||in_labelfilter;
        end if;
                
        cmd := cmd ||' order by code';
    end if;	
	
    if in_action = 'PREV' then
        cmd := cmd ||' (code < '''||in_code||''') ';
        if in_labelfilter is not null then
            cmd := cmd || 'and '||in_labelfilter;
        end if;
                
        cmd := cmd ||' order by code desc';
    end if;
	
    if in_action = 'GET' then
	    -- First record
	    cmd1 := cmd || ' rownum = 1';
		dbmsg(cmd1);
        open cmc for cmd1;
        fetch cmc into l_code;
        close cmc;
		out_first := l_code;
		
		-- Last record
		cmd1 := cmd || ' rownum = 1 order by code desc';
		dbmsg(cmd1);
        open cmc for cmd1;
        fetch cmc into l_code;
        close cmc;
		out_last := l_code;
		
		cmd := cmd ||' (code = '''||in_code||''') ';
        if in_labelfilter is not null then
            cmd := cmd || 'and '||in_labelfilter;
        end if;
                
        cmd := cmd ||' order by code';
    end if;	
	
    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_code;
    close cmc;

    out_code := l_code;

EXCEPTION WHEN OTHERS THEN
    out_code := '';
    zut.prt(sqlerrm);
END get_label;

----------------------------------------------------------------------
--
-- get_consignee - 
--
----------------------------------------------------------------------
PROCEDURE get_consignee(
    in_consignee   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_consignee  OUT varchar2)
IS
cmd varchar2(500);

l_consignee consignee.consignee%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select consignee from consignee where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (consignee > '''||in_consignee||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by consignee';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (consignee < '''||in_consignee||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by consignee desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_consignee;
    close cmc;


    out_consignee := l_consignee;

EXCEPTION WHEN OTHERS THEN
    out_consignee := '';
    zut.prt(sqlerrm);
END get_consignee;

----------------------------------------------------------------------
--
-- get_carrier - 
--
----------------------------------------------------------------------
PROCEDURE get_carrier(
    in_carrier   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_carrier  OUT varchar2)
IS
cmd varchar2(500);

l_carrier carrier.carrier%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select carrier from carrier where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (carrier > '''||in_carrier||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by carrier';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (carrier < '''||in_carrier||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by carrier desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_carrier;
    close cmc;


    out_carrier := l_carrier;

EXCEPTION WHEN OTHERS THEN
    out_carrier := '';
    zut.prt(sqlerrm);
END get_carrier;

----------------------------------------------------------------------
--
-- get_userheader - 
--
----------------------------------------------------------------------
PROCEDURE get_userheader(
    in_nameid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_nameid  OUT varchar2)
IS
cmd varchar2(500);

l_nameid userheader.nameid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select nameid from userheader where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (nameid > '''||in_nameid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by nameid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (nameid < '''||in_nameid||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by nameid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_nameid;
    close cmc;


    out_nameid := l_nameid;

EXCEPTION WHEN OTHERS THEN
    out_nameid := '';
    zut.prt(sqlerrm);
END get_userheader;


----------------------------------------------------------------------
--
-- get_location - 
--
----------------------------------------------------------------------
PROCEDURE get_location(
    in_fac   IN  varchar2,
    in_locid   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_fac  OUT varchar2,
    out_locid  OUT varchar2)
IS
cmd varchar2(500);

l_fac   location.facility%type;
l_locid location.locid%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select facility, locid from location where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (facility > '''||in_fac
                   ||''' or (facility = '''||in_fac
                    ||''' and locid > '''||in_locid||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by facility, locid';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (facility < '''||in_fac
                   ||''' or (facility = '''||in_fac
                    ||''' and locid < '''||in_locid||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by facility desc, locid desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_fac, l_locid;
    close cmc;


    out_fac := l_fac;
    out_locid := l_locid;

EXCEPTION WHEN OTHERS THEN
    out_fac := '';
    out_locid := '';
    zut.prt(sqlerrm);
END get_location;

----------------------------------------------------------------------
--
-- get_allocruleshdr - 
--
----------------------------------------------------------------------
PROCEDURE get_allocruleshdr(
    in_fac   IN  varchar2,
    in_allocrule   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_fac  OUT varchar2,
    out_allocrule  OUT varchar2)
IS
cmd varchar2(500);

l_fac   allocruleshdr.facility%type;
l_allocrule allocruleshdr.allocrule%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select facility, allocrule from allocruleshdr where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (facility > '''||in_fac
                   ||''' or (facility = '''||in_fac
                    ||''' and allocrule > '''||in_allocrule||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by facility, allocrule';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (facility < '''||in_fac
                   ||''' or (facility = '''||in_fac
                    ||''' and allocrule < '''||in_allocrule||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by facility desc, allocrule desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_fac, l_allocrule;
    close cmc;


    out_fac := l_fac;
    out_allocrule := l_allocrule;

EXCEPTION WHEN OTHERS THEN
    out_fac := '';
    out_allocrule := '';
    zut.prt(sqlerrm);
END get_allocruleshdr;

----------------------------------------------------------------------
--
-- get_custitem - 
--
----------------------------------------------------------------------
PROCEDURE get_custitem(
    in_custid   IN  varchar2,
    in_item   IN  varchar2,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid  OUT varchar2,
    out_item  OUT varchar2)
IS
cmd varchar2(500);

l_custid   custitem.custid%type;
l_item custitem.item%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select custid, item from custitem where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (custid > '''||in_custid
                   ||''' or (custid = '''||in_custid
                    ||''' and item > '''||in_item||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid, item';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (custid < '''||in_custid
                   ||''' or (custid = '''||in_custid
                    ||''' and item < '''||in_item||''')) ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid desc, item desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_custid, l_item;
    close cmc;


    out_custid := l_custid;
    out_item := l_item;

EXCEPTION WHEN OTHERS THEN
    out_custid := '';
    out_item := '';
    zut.prt(sqlerrm);
END get_custitem;

----------------------------------------------------------------------
--
-- get_pallethistory - 
--
----------------------------------------------------------------------
PROCEDURE get_pallethistory(
    in_custid   IN  varchar2,
    in_facility   IN  varchar2,
    in_pallettype   IN  varchar2,
    in_carrier   IN  varchar2,
    in_lastupdate   IN  date,
    in_action   IN  varchar2,
    in_custfilter IN varchar2,
    out_custid   OUT  varchar2,
    out_facility   OUT  varchar2,
    out_pallettype   OUT  varchar2,
    out_carrier   OUT  varchar2,
    out_lastupdate   OUT  date)
IS
cmd varchar2(500);

l_custid   pallethistory.custid%type;
l_facility   pallethistory.facility%type;
l_pallettype   pallethistory.pallettype%type;
l_carrier   pallethistory.carrier%type;
l_lastupdate   pallethistory.lastupdate%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

    cmd := 'select custid, facility, pallettype, carrier, lastupdate '||
    ' from pallethistory where ';

    if in_action = 'NEXT' then
        cmd := cmd ||' (custid > '''||in_custid
                   ||''' or (custid = '''||in_custid
                    ||''' and facility > '''||in_facility||''') '
                   ||' or (custid = '''||in_custid
                    ||''' and facility = '''||in_facility||''') ';
        cmd := cmd || ' and pallettype||carrier||to_char(lastupdate,''YYYYMMDDHH24MISS'') > '''||in_pallettype||in_carrier||to_char(in_lastupdate,'YYYYMMDDHH24MISS')||''')';

        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid, facility, pallettype, carrier, lastupdate ';
    end if;
    if in_action = 'PREV' then
        cmd := cmd ||' (custid < '''||in_custid
                   ||''' or (custid = '''||in_custid
                    ||''' and facility < '''||in_facility||''') '
                   ||' or (custid = '''||in_custid
                    ||''' and facility = '''||in_facility||''') ';
        cmd := cmd || ' and pallettype||carrier||to_char(lastupdate,''YYYYMMDDHH24MISS'') < '''||in_pallettype||in_carrier||to_char(in_lastupdate,'YYYYMMDDHH24MISS')||''') ';
        if in_custfilter is not null then
            cmd := cmd || 'and '||in_custfilter;
        end if;
                
        cmd := cmd ||' order by custid desc, facility desc, pallettype desc, carrier desc, lastupdate desc';
    end if;

    dbmsg(cmd);
    open cmc for cmd;
    fetch cmc into l_custid, l_facility, l_pallettype, l_carrier, l_lastupdate;
    close cmc;


    out_custid := l_custid;
    out_facility := l_facility;
    out_pallettype := l_pallettype;
    out_carrier := l_carrier;
    out_lastupdate := l_lastupdate;

EXCEPTION WHEN OTHERS THEN
    out_custid := '';
    out_facility := '';
    out_pallettype := '';
    zut.prt(sqlerrm);
END get_pallethistory;

----------------------------------------------------------------------
--
-- get_nmfc- 
--
----------------------------------------------------------------------
PROCEDURE get_nmfc(
    in_nmfc  IN  varchar2,
    in_action   IN  varchar2,
    out_nmfc OUT varchar2)
IS
cmd varchar2(500);

l_nmfc   nmfclasscodes.nmfc%type;

type cur_type is REF CURSOR;

cmc cur_type;

BEGIN

  cmd := 'select nmfc from nmfclasscodes where ';

  if in_action = 'NEXT' then
    cmd := cmd ||' (nmfc > '''||in_nmfc||''') order by nmfc';
  end if;
  if in_action = 'PREV' then
    cmd := cmd ||' (nmfc < '''||in_nmfc||''') order by nmfc desc';
  end if;

  dbmsg(cmd);
  open cmc for cmd;
  fetch cmc into l_nmfc;
  close cmc;

  out_nmfc := l_nmfc;

EXCEPTION WHEN OTHERS THEN
    out_nmfc := '';
    zut.prt(sqlerrm);
END get_nmfc;

END zreaddata;
/

exit;
