CREATE OR REPLACE PACKAGE BODY zclone
IS
--
-- $Id$
--
-- ******************************************************************
-- *                                                                *
-- *    CONSTANTS                                                   *
-- *                                                                *
-- ******************************************************************

clone_debug_on boolean := False;

-- ******************************************************************
-- *                                                                *
-- *    CURSORS                                                     *
-- *                                                                *
-- ******************************************************************
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

CURSOR C_ITEM(in_cust varchar2, in_item varchar2)
 RETURN custitem%rowtype
IS
    SELECT *
      FROM custitem
     WHERE custid = in_cust
       AND item = in_item;

CURSOR C_RATEGROUP(in_cust varchar2, in_rategroup varchar2)
 RETURN custrategroup%rowtype
IS
    SELECT *
      FROM custrategroup
     WHERE custid = in_cust
       AND rategroup = in_rategroup;

CURSOR C_PG(in_custid varchar2, in_group varchar2)
RETURN custproductgroup%rowtype
IS
    SELECT *
      FROM custproductgroup
     WHERE custid = in_custid
       AND productgroup = in_group;

CURSOR C_BOL(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMBOLCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_OUT(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMOUTCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_IN(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMINCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_WOC(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERCLASSES
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_WOI(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERINSTRUCTIONS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_WOD(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERDESTINATIONS
     WHERE custid = in_custid
       AND item = in_item;

AUTHOR constant        appmsgs.author%type := 'CLONE';

-- ******************************************************************
-- *                                                                *
-- *  MESSAGING FUNCTIONS                                           *
-- *                                                                *
-- ******************************************************************


------------------------------------------------------------------------
--
-- PACKAGE INITIALIZATION CODE
--
------------------------------------------------------------------------

------------------------------------------------------------------------
--
-- clone_all_rows - clone simple rows off simple index
--                  skips any long columns
--
------------------------------------------------------------------------
/*PROCEDURE clone_all_rows
(
    in_table        IN varchar2,    -- table name to clone must be upper
    in_from         IN varchar2,    -- where clause of table rows to clone
    in_to           IN varchar2,    -- to values of new row index
    in_index        IN varchar2,    -- index column
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS

col_list varchar2(10000);
val_list varchar2(10000);

dbsql   varchar2(20000);
long_column varchar2(100);

u_tn varchar2(100);

ll long;
mark varchar2(20);

BEGIN

    out_errmsg := 'OKAY';

    mark := 'start';

    begin
        select column_name
          into long_column
          from cols
         where table_name = in_table
           and data_type = 'LONG';
    exception when others then
        long_column := null;
    end;

    col_list := in_index;
    val_list := in_to;

    for crec in (select column_name from cols
        where table_name = in_table
         order by column_id)
    loop
        if nvl(crec.column_name,'1') = long_column then
            null;
        elsif crec.column_name = 'LASTUSER' then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',''' || in_userid||'''';
        elsif crec.column_name = 'LASTUPDATE' then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',sysdate';
        elsif instr(','||in_index||',', ','||crec.column_name||',') = 0 then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',' || crec.column_name;
        end if;
    end loop;

    dbsql := 'insert into '||in_table||'('||col_list||') select ' || val_list
            || ' from '||in_table||' where '||in_from;

    begin
       EXECUTE IMMEDIATE dbsql;

    exception when others then
        out_errmsg := 'cal: '||in_table||' : '||sqlerrm;
    end;




EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CAR: '||mark||' '||sqlerrm;
END clone_all_rows;
*/

PROCEDURE set_debug_mode(in_mode boolean)
IS
BEGIN
    clone_debug_on := nvl(in_mode,False);
END set_debug_mode;


PROCEDURE debug_msg(in_text varchar2)
IS

cntChar integer;

BEGIN

    if not clone_debug_on then
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
END debug_msg;

------------------------------------------------------------------------
--
-- clone_table_row - generic clone table
--
------------------------------------------------------------------------
PROCEDURE clone_table_row
(
    in_table        IN varchar2,    -- table name to clone must be upper
    in_from         IN varchar2,    -- where clause of table row to clone
    in_to           IN varchar2,    -- to values of new row index
    in_index        IN varchar2,    -- index columns
    in_dblink       IN varchar2,    -- database link where to clone the objects
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
   col_list  varchar2(10000);
   val_list  varchar2(10000);
   dbsql     varchar2(20000);
   u_tn      varchar2(100);
   mark      varchar2(100);
   l_in_dblink varchar2(50);

   TYPE  CUR_TYP is REF CURSOR;
   cdata CUR_TYP;
   crec  cols%rowtype;

BEGIN
  out_errmsg := 'OKAY';

   l_in_dblink := null;
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

    mark := in_table;
    col_list := in_index;
    val_list := in_to;

   -- Select common columns between both databases
    open cdata for 'select column_name from cols' ||l_in_dblink||
         ' where table_name = '||''''||in_table||''''||
         ' and column_name in (select column_name from cols ' ||
         ' where table_name = ' || ''''|| in_table ||''''||')'||
         ' order by column_id';

    loop
      fetch cdata into crec.column_name;
        exit when cdata%notfound;

        if crec.column_name = 'LASTUSER' then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',''' || in_userid||'''';
        elsif crec.column_name = 'LASTUPDATE' then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',sysdate';
        elsif (in_table = 'ORDERDTL') and
              (crec.column_name = 'LINESTATUS') then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',''A''';
        elsif (in_table = 'LOCATION') and
              (crec.column_name in ('LPCOUNT','DROPCOUNT','PICKCOUNT')) then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',0';
        elsif (in_table = 'LOCATION') and
              (crec.column_name = 'STATUS') then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',''E''';
        elsif instr(','||in_index||',', ','||crec.column_name||',') = 0 then
            col_list := col_list ||','||crec.column_name;
            val_list := val_list || ',' || crec.column_name;
        end if;
    end loop;
   close cdata;

    dbsql := 'insert into '||in_table||l_in_dblink||'('||col_list||') select ' || val_list
            || ' from '||in_table||' table_alias where '||in_from;
    --debug_msg(dbsql);

    begin
      execute immediate dbsql;
   exception
      when dup_val_on_index then
         out_errmsg := 'clone_table_row: record already exists in ' || in_table || ' for: '||in_to;
   end;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'clone_table_row: '||mark||' '||sqlerrm;
END clone_table_row;

------------------------------------------------------------------------
--
-- clone_orderhdr -
--
------------------------------------------------------------------------
PROCEDURE clone_orderhdr
(
    in_orderid      IN number,
    in_shipid       IN number,
    in_new_orderid  IN number,
    in_new_shipid   IN number,
   in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
BEGIN
    clone_table_row('ORDERHDR',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        in_new_orderid||','||in_new_shipid||',null,null,null',
        'ORDERID,SHIPID,WAVE,LOADNO,IGNORE_MULTISHIP',
      in_dblink,
        in_userid,
        out_errmsg);

END clone_orderhdr;

------------------------------------------------------------------------
--
-- clone_orderdtl -
--
------------------------------------------------------------------------
PROCEDURE clone_orderdtl
(
    in_orderid      IN number,
    in_shipid       IN number,
    in_item         IN varchar2,
    in_lot          IN varchar2,
    in_new_orderid  IN number,
    in_new_shipid   IN number,
    in_new_item     IN varchar2,
    in_new_lot      IN varchar2,
   in_dblink      IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
BEGIN
    clone_table_row('ORDERDTL',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
            ||' and ITEM = '''||in_item||''''
            ||' and nvl(LOTNUMBER,''(none)'') = '''
                ||nvl(in_lot,'(none)')||'''',
        in_new_orderid||','||in_new_shipid||','''||in_new_item
            ||''','''||in_new_lot||'''',
        'ORDERID,SHIPID,ITEM,LOTNUMBER',
      in_dblink,
        in_userid,
        out_errmsg);

END clone_orderdtl;

------------------------------------------------------------------------
--
-- clone_customer -
--
------------------------------------------------------------------------
PROCEDURE clone_customer
(
   in_customer_flag    IN varchar2,
   in_item_flag        IN varchar2,
   in_rategroup_flag   IN varchar2,
    in_itemalias_flag   IN varchar2,  -- flag to clone item alias
    in_itempickfronts_flag IN varchar2,  -- flag to clone item pickfronts
   in_custid           IN varchar2,
   in_item             IN varchar2,
   in_new_custid       IN varchar2,
   in_new_item         IN varchar2,
   in_dblink           IN varchar2,
   in_userid           IN varchar2,
   out_errmsg          OUT varchar2
)
IS
   FROMCUST              C_CUST%rowtype;
   l_in_dblink           varchar2(50);
   l_count               number;

BEGIN
   out_errmsg := 'OKAY';

   if (in_customer_flag <> 'Y') then
      out_errmsg := 'No data cloned. Customer flag is: '||in_customer_flag;
      return;
   end if;

   if rtrim(in_custid) is null then
      out_errmsg := 'in_custid is null';
      return;
    end if;

   if rtrim(in_new_custid) is null then
      out_errmsg := 'in_new_custid is null';
      return;
    end if;

   l_in_dblink := null;
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   -- check in_custid is valid
   FROMCUST := null;
   OPEN C_CUST(in_custid);
   FETCH C_CUST into FROMCUST;
   CLOSE C_CUST;
   if FROMCUST.custid is null then
     out_errmsg := 'Invalid ''from'' Customer ID:'|| in_custid;
     return;
   end if;

   -- check in_new_custid doesn't exist
   l_count := 0;
   execute immediate 'select count(1) from customer'||l_in_dblink||' where custid=:1'
   into l_count
   using in_new_custid;

   if l_count <> 0 then
      out_errmsg := 'customer id: '||in_new_custid||' already exists';
      return;
   end if;

    clone_table_row('CUSTOMER',
        'CUSTID = '''||in_custid||'''',
        ''''||in_new_custid||'''',
        'CUSTID',
      in_dblink,
        in_userid,
        out_errmsg);
    if out_errmsg <> 'OKAY' then
       out_errmsg := 'customer: ' || out_errmsg;
       return;
    end if;

   clone_table_row('CUSTOMER_AUX',
        'CUSTID = '''||in_custid||'''',
        ''''||in_new_custid||'''',
        'CUSTID',
      in_dblink,
        in_userid,
        out_errmsg);
    if out_errmsg <> 'OKAY' then
       out_errmsg := 'customer_aux: ' || out_errmsg;
       return;
    end if;

    clone_table_row('CUSTRETURNREASONS',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);

    clone_table_row('CUSTSHIPPER',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);

    /*
   Do not clone since we do not have a facility associated
   with the location so we have no way to verify
   clone_table_row('CUSTDISPOSITIONFACILITY',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);
   */

    clone_table_row('CUSTITEMINCOMMENTS',
        'CUSTID = '''||in_custid||''' and ITEM is null',
        ''''||in_new_custid||''',null',
        'CUSTID,ITEM',
      in_dblink,
        in_userid,
        out_errmsg);

    clone_table_row('CUSTCONSIGNEE',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);

    for crec in (select * from custitemoutcomments
                   where custid = in_custid
                     and item is null)
    loop
        clone_table_row('CUSTITEMOUTCOMMENTS',
            'CUSTID = '''||crec.custid||''' and ITEM is null and CONSIGNEE = '
                ||''''||crec.consignee||'''',
            ''''||in_new_custid||''',null,'''||crec.consignee||'''',
            'CUSTID,ITEM,CONSIGNEE',
         in_dblink,
            in_userid,
            out_errmsg);

    end loop;

    for crec in (select * from custitembolcomments
                   where custid = in_custid
                     and item is null)
    loop
        clone_table_row('CUSTITEMBOLCOMMENTS',
            'CUSTID = '''||crec.custid||''' and ITEM is null and CONSIGNEE = '
                ||''''||crec.consignee||'''',
            ''''||in_new_custid||''',null,'''||crec.consignee||'''',
            'CUSTID,ITEM,CONSIGNEE',
         in_dblink,
            in_userid,
            out_errmsg);
    end loop;

   -- Only clone when facility or facility/location exist
    for crec in (select * from custauditstageloc
                   where custid = in_custid)
    loop
      execute immediate ' select count(1) from '||
       ' (select distinct locid, facility'||
         ' from location'||
         ' where locid = :1'||
         ' and facility = (select distinct facility'||
                           ' from facility'||
                       ' where facility= :2))'
      into l_count
      using crec.auditstageloc, crec.facility;

      if l_count > 0 then
         clone_table_row('CUSTAUDITSTAGELOC',
            'CUSTID = '''||in_new_custid||''' and FACILITY = '''||crec.facility||'''',
            ''''||in_new_custid||''','''||crec.facility||'''',
            'CUSTID,FACILITY',
            in_dblink,
            in_userid,
            out_errmsg);
      end if;
    end loop;

   -- Only clone wen carrier exist
    for crec in (select * from customercarriers
                   where custid = in_custid)
    loop
      execute immediate 'select count(1) from carrier'||l_in_dblink||
         ' where carrier= :1'
      into l_count
      using crec.carrier;

      if l_count > 0 then
         clone_table_row('CUSTOMERCARRIERS',
            'CUSTID = '''||in_custid||''' and CARRIER = '''||crec.carrier||'''',
            ''''||in_new_custid||''','''||crec.carrier||'''',
            'CUSTID,CARRIER',
            in_dblink,
            in_userid,
            out_errmsg);
      end if;
    end loop;

   clone_table_row('CUSTCONSIGNEENOTICE',
      'CUSTID = '''||in_custid||'''',
      ''''||in_new_custid||'''',
      'CUSTID',
      in_dblink,
      in_userid,
      out_errmsg);

   /*
   -- Do not clone - Synapse Tab dropped in 2.2
   clone_table_row('CUSTVICSBOL',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);

    clone_table_row('CUSTVICSBOLCOPIES',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);
   */

    clone_table_row('CUSTCONSIGNEESIPNAME',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);

    clone_table_row('CUSTDICT',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
         in_dblink,
            in_userid,
            out_errmsg);


    clone_table_row('CUSTITEMLABELPROFILES',
            'CUSTID = '''||in_custid||''' and ITEM is null',
            ''''||in_new_custid||''', null',
            'CUSTID,ITEM',
         in_dblink,
            in_userid,
            out_errmsg);

   for crec in (select * from custfacility
                   where custid = in_custid)
    loop
      execute immediate 'select count(1) from facility'||l_in_dblink||
         ' where facility= :1'
      into l_count
      using crec.facility;

      if l_count > 0 then
         clone_table_row('CUSTFACILITY',
            'CUSTID = '''||in_custid||''' and FACILITY = '''||crec.facility||'''',
            ''''||in_new_custid||''','''||crec.facility||'''',
            'CUSTID,FACILITY',
            in_dblink,
            in_userid,
            out_errmsg);
      end if;
    end loop;

   clone_table_row('CUSTACTVFACILITIES',
      'CUSTID = '''||in_custid||'''',
      ''''||in_new_custid||'''',
      'CUSTID',
      in_dblink,
      in_userid,
      out_errmsg);

   /*
   Cannot clone since trading partner has a unique index
    clone_table_row('CUSTTRADINGPARTNER',
            'CUSTID = '''||in_custid||'''',
            ''''||in_new_custid||'''',
            'CUSTID',
            out_errmsg);
   */

   clone_table_row('CUSTINVSTATUSCHANGE',
      'CUSTID = '''||in_custid||'''',
      ''''||in_new_custid||'''',
      'CUSTID',
      in_dblink,
      in_userid,
      out_errmsg);

   -- Only clone when carrier/servicecode exist
    for crec in (select * from custpacklist
                   where custid = in_custid)
    loop
      execute immediate 'select count(1) from carrierservicecodes'||l_in_dblink||
         ' where carrier= :1 and servicecode= :2'
      into l_count
      using crec.carrier, crec.servicecode;
      if l_count > 0 then
         clone_table_row('CUSTPACKLIST',
            'CUSTID = '''||in_new_custid||''' and CARRIER = '''||crec.carrier||''' and SERVICECODE = '''||crec.servicecode||'''',
            ''''||in_new_custid||''','''||crec.carrier||''','''||crec.servicecode||'''',
            'CUSTID,CARRIER,SERVICECODE',
            in_dblink,
            in_userid,
            out_errmsg);
      end if;
    end loop;

   /*
   -- Only clone when carrier exist
    for crec in (select * from custcarriernotice
                   where custid = in_custid)
    loop
      execute immediate 'select count(1) from carrier'||l_in_dblink||
         ' where carrier= :1'
      into l_count
      using crec.carrier;

      if l_count > 0 then
         clone_table_row('CUSTCARRIERNOTICE',
            'CUSTID = '''||in_new_custid||''' and CARRIER = '''||crec.carrier||'''',
            ''''||in_new_custid||''','''||crec.carrier||'''',
            'CUSTID,CARRIER',
            in_dblink,
            in_userid,
            out_errmsg);
      end if;
    end loop;
   */

   -- clone rategroups for customer
   if out_errmsg = 'OKAY' and in_rategroup_flag = 'Y' then
        for crec in (select * from custrategroup where custid = in_custid)
      loop
        clone_rategroup(crec.custid, crec.rategroup, in_new_custid, crec.rategroup, in_dblink, in_userid, out_errmsg);
          exit when out_errmsg <> 'OKAY';
      end loop;
   end if;

    -- clone productgroups for customer
   if out_errmsg = 'OKAY' then
      clone_productgroup(in_custid, in_new_custid, in_dblink, in_userid, out_errmsg);
   end if;

   -- update customer when cloning accross database
   if out_errmsg = 'OKAY' and in_dblink is not null then
      update_customer(in_custid, in_new_custid, in_dblink, in_userid, out_errmsg);
   end if;

   -- validate customer when cloning accross database
   if out_errmsg = 'OKAY' and in_dblink is not null then
      validate_customer(in_custid, in_new_custid, in_dblink, in_userid, out_errmsg);
   end if;

   -- clone items and kitting for customer
   if out_errmsg = 'OKAY' and in_item_flag = 'Y' then
          
      begin
        execute immediate 'call ztbl.disable_triggers'||l_in_dblink||'(''custitemalias'')';
      exception when others then
        null;
      end ;
    
      for crec in (select * from custitem where custid = in_custid)
      loop
         clone_custitem(in_custid, crec.item, in_new_custid, crec.item, in_itemalias_flag, in_itempickfronts_flag, in_dblink, in_userid, out_errmsg);
         exit when out_errmsg <> 'OKAY';
      end loop;

     -- validate item when cloning accross database
     if out_errmsg = 'OKAY' then
        validate_item(in_custid, in_new_custid, in_dblink, in_userid, out_errmsg);
     end if;

     commit;
      
      begin
        execute immediate 'call ztbl.enable_triggers'||l_in_dblink||'(''custitemalias'')';
      exception when others then
        null;
      end ;
      
   end if;

EXCEPTION
   WHEN OTHERS THEN
      out_errmsg := 'clone_customer: ' || sqlerrm;
END clone_customer;

------------------------------------------------------------------------
-- clone_rategroup
------------------------------------------------------------------------
PROCEDURE clone_rategroup
(
   in_custid        IN varchar2,
 in_rategroup     IN varchar2,
   in_new_custid    IN varchar2,
 in_new_rategroup IN varchar2,
   in_dblink        IN varchar2,
   in_userid        IN varchar2,
   out_errmsg       OUT varchar2
)
IS
    FROMCUST C_CUST%rowtype;
   FROMRATEGROUP C_RATEGROUP%rowtype;

   l_in_dblink varchar2(50);
   l_count number;

BEGIN

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if rtrim(in_custid) is null then
       out_errmsg := 'in_custid is null';
       return;
    end if;

   if rtrim(in_new_custid) is null then
       out_errmsg := 'in_new_custid is null';
       return;
    end if;

    if rtrim(in_rategroup) is null then
       out_errmsg := 'in_rategroup is null';
       return;
   end if;

    if rtrim(in_new_rategroup) is null then
       out_errmsg := 'in_new_rategroup is null';
       return;
   end if;

    -- check in_custid is valid
   FROMCUST := null;
   OPEN C_CUST(in_custid);

   FETCH C_CUST into FROMCUST;
   CLOSE C_CUST;
   if FROMCUST.custid is null then
     out_errmsg := 'clone_rategroup -Invalid ''from'' Customer ID:'|| in_custid;
     return;
   end if;

   -- check in_rategroup is valid
   OPEN C_RATEGROUP(in_custid, in_rategroup);
   FETCH C_RATEGROUP into FROMRATEGROUP;
   CLOSE C_RATEGROUP;
   if FROMRATEGROUP.rategroup is null then
     out_errmsg := 'Invalid ''from'' Rategroup:'|| in_rategroup;
     return;
   end if;

    -- check in_new_custid is valid
   l_count := 0;
   execute immediate 'select count(1) from customer'||l_in_dblink||' where custid=:1'
   into l_count
   using in_new_custid;
   if l_count = 0 then
      out_errmsg := 'Invalid ''to'' Customer ID:'|| in_new_custid;
      return;
   end if;

   -- check in_new_rategroup does not exist yet
   l_count := 0;
   execute immediate ' select count(1) from custrategroup'||l_in_dblink||
     ' where custid = (select custid from customer'||l_in_dblink||' where custid=:1)'||
     ' and rategroup = :2'
   into l_count
   using in_new_custid, in_new_rategroup;
   if l_count != 0 then
      out_errmsg := 'Invalid ''to'' Customer ID/Rategroup: '|| in_new_custid||'/'||in_new_rategroup;
      return;
   end if;

   clone_table_row('CUSTRATEGROUP',
   'CUSTID = '''||in_custid||''' and RATEGROUP = '''||in_rategroup||'''',
   ''''||in_new_custid||''','''||in_new_rategroup||'''',
   'CUSTID,RATEGROUP',
   in_dblink,
   in_userid,
   out_errmsg);
    if out_errmsg <> 'OKAY' then
      out_errmsg := 'custrategroup: ' || out_errmsg;
      return;
    end if;

    for crec in (select * from custratewhen
         where custid=in_custid and rategroup=in_rategroup)
    loop
        if (crec.billmethod is not null) then
         if (validate_billmethod(crec.billmethod, in_dblink) < 1) then
          out_errmsg := 'custratewhen: billmethod <'||crec.billmethod||
                        '> does not exist in destination database.';
           return;
        end if;
      end if;

        if (crec.businessevent is not null) then
          if (validate_businessevent(crec.businessevent, in_dblink) < 1) then
          out_errmsg := 'custratewhen: businessevent <'||crec.businessevent||
                        '> does not exist in destination database.';
            return;
        end if;
      end if;

      clone_table_row('CUSTRATEWHEN',
      'CUSTID = '''||in_custid||
      ''' and RATEGROUP = '''||in_rategroup||
        ''' and EFFDATE = '''||crec.effdate||
      ''' and ACTIVITY = '''||crec.activity||
      ''' and BILLMETHOD = '''||crec.billmethod||
      ''' and BUSINESSEVENT = '''||crec.businessevent||'''',
        ''''||in_new_custid||''','''||in_new_rategroup||''','''||crec.effdate||
       ''','''||crec.activity||''','''||crec.billmethod||''','''||crec.businessevent||'''',
      'CUSTID,RATEGROUP,EFFDATE,ACTIVITY,BILLMETHOD,BUSINESSEVENT',
      in_dblink,
      in_userid,
      out_errmsg);
    end loop;

    for crec in (select * from custratebreak
         where custid=in_custid and rategroup=in_rategroup)
    loop
        if (crec.billmethod is not null) then
          if (validate_billmethod(crec.billmethod, in_dblink) < 1) then
          out_errmsg := 'custratebreak: billmethod <'||crec.billmethod||
                        '> does not exist in destination database.';
            return;
        end if;
      end if;

      clone_table_row('CUSTRATEBREAK',
      'CUSTID = '''||in_custid||
      ''' and RATEGROUP = '''||in_rategroup||
        ''' and EFFDATE = '''||crec.effdate||
        ''' and ACTIVITY = '''||crec.activity||
        ''' and BILLMETHOD = '''||crec.billmethod||
        ''' and QUANTITY = '''||crec.quantity||'''',
      ''''||in_new_custid||''','''||in_new_rategroup||''','''||crec.effdate||''',
         '''||crec.activity||''','''||crec.billmethod||''','''||crec.quantity||'''',
      'CUSTID,RATEGROUP,EFFDATE,ACTIVITY,BILLMETHOD,QUANTITY',
      in_dblink,
      in_userid,
      out_errmsg);
    end loop;

    for crec in (select * from custrate
         where custid=in_custid and rategroup=in_rategroup)
    loop
        if (crec.billmethod is not null) then
          if (validate_billmethod(crec.billmethod, in_dblink) < 1) then
          out_errmsg := 'custrate: billmethod <'||crec.billmethod||
                        '> does not exist in destination database.';
            return;
        end if;
      end if;

        if (crec.activity is not null) then
          if (validate_activity(crec.activity, in_dblink) < 1) then
          out_errmsg := 'custrate: activity <'||crec.activity||
                        '> does not exist in destination database.';
            return;
          end if;
        end if;

        if (crec.uom is not null) then
          if (validate_uom(crec.uom, in_dblink) < 1) then
          out_errmsg := 'custrate: uom <'||crec.uom||
                        '> does not exist in destination database.';
            return;
        end if;
      end if;

      clone_table_row('CUSTRATE',
      'CUSTID = '''||in_custid||
      ''' and RATEGROUP = '''||in_rategroup||
      ''' and EFFDATE = '''||crec.effdate||
      ''' and ACTIVITY = '''||crec.activity||
      ''' and BILLMETHOD = '''||crec.billmethod||'''',
      ''''||in_new_custid||''','''||in_new_rategroup||''',
         '''||crec.effdate||''','''||crec.activity||''','''||crec.billmethod||'''',
      'CUSTID,RATEGROUP,EFFDATE,ACTIVITY,BILLMETHOD',
      in_dblink,
      in_userid,
      out_errmsg);
   end loop;

EXCEPTION
   WHEN OTHERS THEN
      out_errmsg := 'clone_rategroup: ' || sqlerrm;
END clone_rategroup;

------------------------------------------------------------------------
-- clone_productgroup
------------------------------------------------------------------------
PROCEDURE clone_productgroup
(
   in_custid        IN varchar2,
   in_new_custid    IN varchar2,
   in_dblink        IN varchar2,
   in_userid        IN varchar2,
   out_errmsg       OUT varchar2
)
IS
   FROMCUST C_CUST%rowtype;
   l_in_item custitem.item%type;
   l_in_dblink varchar2(50);
   l_count number;

BEGIN

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if rtrim(in_custid) is null then
       out_errmsg := 'in_custid is null';
       return;
    end if;

   if rtrim(in_new_custid) is null then
       out_errmsg := 'in_new_custid is null';
       return;
    end if;

   -- check in_custid is valid
   FROMCUST := null;
   OPEN C_CUST(in_custid);
   FETCH C_CUST into FROMCUST;
   CLOSE C_CUST;
   if FROMCUST.custid is null then
     out_errmsg := 'Invalid ''from'' Customer ID:'|| in_custid;
     return;
   end if;

   -- check in_new_custid is valid
   l_count := 0;
   execute immediate 'select count(1) from customer'||l_in_dblink||' where custid=:1'
   into l_count
   using in_new_custid;
   if l_count = 0 then
      out_errmsg := 'clone_productgroup - Invalid ''to'' Customer ID:'|| in_new_custid;
      return;
   end if;

   clone_table_row('CUSTPRODUCTGROUP',
   'CUSTID = '''||in_custid||'''',
   ''''||in_new_custid||'''',
   'CUSTID',
   in_dblink,
   in_userid,
   out_errmsg);

   clone_table_row('CUSTPRODUCTGROUPFACILITY',
   'CUSTID = '''||in_custid||'''',
   ''''||in_new_custid||'''',
   'CUSTID',
   in_dblink,
   in_userid,
   out_errmsg);

   -- validate lot sequence for productgroup
   l_in_item := null;
   for crec in (select * from custproductgroup where custid = in_custid)
   loop
      execute immediate 'call zci.validate_auto_seq'||l_in_dblink||'(:in_custid, :in_productgroup, :in_item , :out_msg)'
      using in in_new_custid, in crec.productgroup, in l_in_item, in out out_errmsg;
   end loop;

EXCEPTION
   WHEN OTHERS THEN
       out_errmsg := 'clone_productgroup: ' || sqlerrm;
END clone_productgroup;

------------------------------------------------------------------------
--
-- clone_custitem -
--
------------------------------------------------------------------------
PROCEDURE clone_custitem
(
    in_custid       IN varchar2,
    in_item         IN varchar2,
    in_new_custid   IN varchar2,
    in_new_item     IN varchar2,
    in_itemalias_flag IN varchar2,
    in_itempickfronts_flag IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      IN OUT varchar2
)
IS
   TYPE  CUR_TYP is REF CURSOR;
   cdata CUR_TYP;

   CURSOR C_ALIAS(in_custid varchar2, in_item varchar2)
   RETURN custitemalias%rowtype
   IS
   SELECT *
     FROM custitemalias
    WHERE custid = in_custid
      AND itemalias = in_item;

   FROMITEM       C_ITEM%rowtype;
   TOITEM         C_ITEM%rowtype;
   TOCUST         C_CUST%rowtype;
   ALIAS          C_ALIAS%rowtype;

   l_in_dblink    varchar2(50);
   l_count        number;

BEGIN

  debug_msg('clone_custitem: in_custid-in_item/in_new_custid-in_new_item = '||
                  in_custid||' - '||in_item||'/'||in_new_custid||' - '||in_new_item);

   out_errmsg := 'OKAY';

   l_in_dblink := null;
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if rtrim(in_new_custid) is null then
      out_errmsg := 'A new Customer ID must be specified';
      return;
   end if;

   if rtrim(in_new_item) is null then
      out_errmsg := 'A new Item identifier must be specified';
      return;
   end if;

   -- validate in_custid/in_item
    FROMITEM := null;
    open C_ITEM(in_custid, in_item);
    fetch C_ITEM into FROMITEM;
    close C_ITEM;

    if FROMITEM.item is null then
       out_errmsg := 'Invalid in_custid/in_item: '||
               in_custid||'/'||in_item||' does not exist.';
       return;
    end if;

   -- validate in_new_custid
   open cdata for 'select custid from customer'||l_in_dblink||
      ' where custid=:1'
   using in_new_custid;
   fetch cdata into TOCUST.custid;
   close cdata;

   if TOCUST.custid is null then
      out_errmsg := 'Invalid ''to'' Customer ID:'|| in_new_custid;
      return;
   end if;

   -- validate in_new_item
   open cdata for 'select item from custitem'||l_in_dblink||
      ' where custid=:1 and item=:2'
   using in_new_custid, in_new_item;
   fetch cdata into TOITEM.item;
   close cdata;

   if TOITEM.item is not null then
      out_errmsg := 'Invalid ''to'' custid/item: '
            ||in_new_custid||'/'||in_new_item||' already exists.';
      return;
   end if;

   clone_table_row('CUSTITEM',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
      ''''||in_new_custid||''','''||in_new_item||'''',
      'CUSTID,ITEM',
      in_dblink,
      in_userid,
      out_errmsg);
  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitem: ' || out_errmsg;
    return;
  end if;

    -- Only clone item alias if cloning accross db
    if nvl(rtrim(in_dblink), 'none') != 'none' and
       nvl(rtrim(in_itemalias_flag), 'N') = 'Y' then
          for crec in (select * from custitemalias
                       where custid = in_custid
                         and item = in_item
                         and aliasdesc not like 'UPC%'
                       union
                       select * from custitemalias
                       where custid = in_custid
                         and item = in_item
                         and aliasdesc like 'UPC%'
                         and rownum = 1)
          loop
            clone_table_row('CUSTITEMALIAS',
                'CUSTID = '''||in_custid||''' and ITEM = '''||crec.item
                ||''' and ITEMALIAS = '''||crec.itemalias||'''',
                ''''||in_new_custid||''','''||in_new_item||''','''||crec.itemalias||'''',
                'CUSTID,ITEM,ITEMALIAS',
                in_dblink,
                in_userid,
                out_errmsg);
            if out_errmsg <> 'OKAY' then
                out_errmsg := 'custitemalias: ' || out_errmsg;
                zms.log_autonomous_msg(
                in_author   => AUTHOR,
                in_facility => null,
                in_custid   => in_new_custid,
                in_msgtext  => out_errmsg,
                in_msgtype  => 'W',
                in_userid   => in_userid,
                out_msg    => out_errmsg);
            end if;
          end loop;
    end if;

   clone_table_row('CUSTITEMUOM',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
      ''''||in_new_custid||''','''||in_new_item||'''',
      'CUSTID,ITEM',
      in_dblink,
      in_userid,
      out_errmsg);

  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitemuom: ' || out_errmsg;
    return;
  end if;

   clone_table_row('CUSTITEMUOMUOS',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
      ''''||in_new_custid||''','''||in_new_item||'''',
      'CUSTID,ITEM',
      in_dblink,
      in_userid,
      out_errmsg);

  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitemuomuos: ' || out_errmsg;
    return;
  end if;

   clone_table_row('CUSTITEMSUBS',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
      ''''||in_new_custid||''','''||in_new_item||'''',
      'CUSTID,ITEM',
      in_dblink,
      in_userid,
      out_errmsg);

  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitemsubs: ' || out_errmsg;
    return;
  end if;

    -- Only clone item pickfronts if cloning accross db
    if nvl(rtrim(in_dblink), 'none') != 'none' and
       nvl(rtrim(in_itempickfronts_flag), 'N') = 'Y' then
            for crec in (select * from itempickfronts
                       where custid = in_custid
                         and item = in_item)
            loop
              clone_table_row('ITEMPICKFRONTS',
                'CUSTID = '''||in_custid||''' and ITEM = '''||crec.item||''' and FACILITY = '''||crec.facility
                ||''' and PICKFRONT = '''||crec.pickfront||''' and PICKUOM = '''||crec.pickuom||'''',
                ''''||in_new_custid||''','''||in_new_item||''','''||crec.facility||''','''||
                crec.pickfront||''','''||crec.pickuom||'''',
                'CUSTID,ITEM,FACILITY,PICKFRONT,PICKUOM',
                in_dblink,
                in_userid,
                out_errmsg);
                if out_errmsg <> 'OKAY' then
                   out_errmsg := 'itempickfronts: ' || out_errmsg;
                   zms.log_autonomous_msg(
                   in_author   => AUTHOR,
                   in_facility => null,
                   in_custid   => in_new_custid,
                   in_msgtext  => out_errmsg,
                   in_msgtype  => 'W',
                   in_userid   => in_userid,
                   out_msg    => out_errmsg);
                end if;
            end loop;
    end if;

   for crec in (select * from custitemlabelprofiles
               where custid = in_custid
                and item = in_item)
   loop
   clone_table_row('CUSTITEMLABELPROFILES',
      'CUSTID = '''||in_custid||''' and ITEM = '''||crec.item
      ||''' and CONSIGNEE = '''||crec.consignee||'''',
      ''''||in_new_custid||''','''||in_new_item||''','''||crec.consignee||'''',
      'CUSTID,ITEM,CONSIGNEE',
      in_dblink,
      in_userid,
      out_errmsg);
  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitemlableprofiles: ' || out_errmsg;
    return;
  end if;
   end loop;

   clone_table_row('CUSTITEMINCOMMENTS',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
      ''''||in_new_custid||''','''||in_new_item||'''',
      'CUSTID,ITEM',
      in_dblink,
      in_userid,
      out_errmsg);
  if out_errmsg <> 'OKAY' then
    out_errmsg := 'custitemincomments: ' || out_errmsg;
    return;
  end if;

   for crec in (select * from custitemoutcomments
               where custid = in_custid
                and item = in_item)
   loop
      clone_table_row('CUSTITEMOUTCOMMENTS',
         'CUSTID = '''||crec.custid||''' and ITEM = '''||crec.item
            ||''' and CONSIGNEE = '''||crec.consignee||'''',
         ''''||in_new_custid||''','''||in_new_item||''','''
            ||crec.consignee||'''',
         'CUSTID,ITEM,CONSIGNEE',
         in_dblink,
         in_userid,
         out_errmsg);
    if out_errmsg <> 'OKAY' then
      out_errmsg := 'custitemoutcomments: ' || out_errmsg;
      return;
    end if;
   end loop;

   for crec in (select * from custitembolcomments
               where custid = in_custid
                and item = in_item)
   loop
      clone_table_row('CUSTITEMBOLCOMMENTS',
         'CUSTID = '''||crec.custid||''' and ITEM = '''||crec.item
            ||''' and CONSIGNEE = '''||crec.consignee||'''',
         ''''||in_new_custid||''','''||in_new_item||''','''
            ||crec.consignee||'''',
         'CUSTID,ITEM,CONSIGNEE',
         in_dblink,
         in_userid,
         out_errmsg);
    if out_errmsg <> 'OKAY' then
      out_errmsg := 'custitembolcomments: ' || out_errmsg;
      return;
    end if;
   end loop;

   for crec in (select * from custitemfacility
               where custid = in_custid
                and item = in_item)
   loop
   clone_table_row('CUSTITEMFACILITY',
      'CUSTID = '''||in_custid||''' and ITEM = '''||crec.item
      ||''' and FACILITY = '''||crec.facility||'''',
      ''''||in_new_custid||''','''||in_new_item||''','''||crec.facility||'''',
      'CUSTID,ITEM,FACILITY',
      in_dblink,
      in_userid,
      out_errmsg);
    if out_errmsg <> 'OKAY' then
      out_errmsg := 'custitemfacility: ' || out_errmsg;
      return;
    end if;
   end loop;

   /*
   for crec in (select * from custitemconsignee
               where custid = in_custid
                and item = in_item)
   loop
      clone_table_row('CUSTITEMCONSIGNEE',
      'CUSTID = '''||in_custid||''' and ITEM = '''||in_item
      ||''' and CONSIGNEE = '''||crec.consignee||'''',
      ''''||in_new_custid||''','''||in_new_item||''','''||crec.consignee||'''',
      'CUSTID,ITEM,CONSIGNEE',
      in_dblink,
      in_userid,
      out_errmsg);
    if out_errmsg <> 'OKAY' then
      out_errmsg := 'custitemconsignee: ' || out_errmsg;
      return;
    end if;
   end loop;
   */

  debug_msg('out_errmsg before update_custitem is >' || out_errmsg || '<');

   -- update the new item when cloning accross database.
   if out_errmsg = 'OKAY' and in_dblink is not null then
    debug_msg('exec update custitem');
      update_custitem(in_custid, in_item, in_new_custid, in_new_item, in_dblink, in_userid, out_errmsg);
   end if;

  debug_msg('out_errmsg before validate_custitem is >' || out_errmsg || '<');

   -- validate the new item when cloning accross database.
   if out_errmsg = 'OKAY' and in_dblink is not null then
    debug_msg('exec validate custitem');
      validate_custitem(in_custid, in_item, in_new_custid, in_new_item, in_dblink, in_userid, out_errmsg);
   end if;

  debug_msg('out_errmsg before clone_kit is >' || out_errmsg || '<');

   -- Kitting
   if out_errmsg = 'OKAY' then
    debug_msg('exec clone kit');
      clone_kit(in_custid, in_item, in_new_custid, in_new_item, in_dblink, in_userid, out_errmsg);
   end if;

  debug_msg('out_errmsg after clone_kit is >' || out_errmsg || '<');

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'clone_custitem: ' || sqlerrm;
END clone_custitem;

------------------------------------------------------------------------
--
-- clone_kit -
--
------------------------------------------------------------------------
PROCEDURE clone_kit
(
    in_custid       IN      varchar2,
    in_item         IN      varchar2,
    in_new_custid   IN      varchar2,
    in_new_item     IN      varchar2,
    in_dblink       IN      varchar2,
    in_userid       IN      varchar2,
    out_errmsg      OUT     varchar2
) is

   FROMCUST        C_CUST%rowtype;
   TOCUST          C_CUST%rowtype;
   FROMITM         C_ITEM%rowtype;
   TOITM           C_ITEM%rowtype;
   l_in_dblink     varchar2(50);
   l_count         number;

BEGIN
   out_errmsg := 'OKAY';

      l_in_dblink := null;
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if rtrim(in_custid) is null then
     out_errmsg := 'A ''from'' Customer ID must be specified';
     return;
   end if;

   if rtrim(in_item) is null then
     out_errmsg := 'A ''from'' Item identifier must be specified';
     return;
   end if;

   if rtrim(in_new_custid) is null then
     out_errmsg := 'A ''to'' Customer ID must be specified';
     return;
   end if;

   if rtrim(in_new_item) is null then
     out_errmsg := 'A ''to'' Item identifier must be specified';
     return;
   end if;

   if rtrim(in_dblink) is null then
      if in_custid = in_new_custid and
        in_item = in_new_item then
       out_errmsg := 'The ''from'' and ''to'' items must be different';
       return;
      end if;
   end if;

   begin
      FROMCUST := null;
      open C_CUST(in_custid);
      fetch C_CUST into FROMCUST;
      close C_CUST;
      if FROMCUST.custid is null then
        out_errmsg := 'Invalid ''from'' Customer ID: <'||in_custid||'> does not exits';
        return;
      end if;

      FROMITM := null;
      open C_ITEM(in_custid, in_item);
      fetch C_ITEM into FROMITM;
      close C_ITEM;

      if FROMITM.item is null then
        out_errmsg := 'Invalid ''from'' Item: '||in_item||' does not exit';
        return;
      end if;

       execute immediate 'select custid from customer'||l_in_dblink||
         ' where custid=:1'
      into TOCUST.custid
      using in_new_custid;
      if TOCUST.custid is null then
         out_errmsg := 'clone_kit - Invalid ''to'' Customer ID:'|| in_new_custid;
          return;
      end if;

      execute immediate 'select item, iskit from custitem'||l_in_dblink||
         ' where custid=:1 and item=:2'
      into TOITM.item, TOITM.iskit
      using in_new_custid, in_new_item;

      if TOITM.item is null then
         out_errmsg := 'Invalid ''to'' item: does not exist.';
         return;
      end if;

      if FROMITM.iskit <> TOITM.iskit then
       out_errmsg := 'The ''from'' and ''to'' items must have the same kit type';
       return;
      end if;

   exception
     when others then
        out_errmsg := sqlerrm;
        return;
   end;

   delete from workorderclasses
         where custid = in_new_custid
           and item = in_new_item;

   delete from workordercomponents
         where custid = in_new_custid
           and item = in_new_item;

   delete from workorderinstructions
         where custid = in_new_custid
           and item = in_new_item;

   delete from workorderdestinations
         where custid = in_new_custid
           and item = in_new_item;

   delete from custitemminmax
         where custid = in_new_custid
           and item = in_new_item;

   clone_table_row('CUSTITEMMINMAX',
        'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
        ''''||in_new_custid||''','''||in_new_item||'''',
        'CUSTID,ITEM',
            in_dblink,
        in_userid,
        out_errmsg);

   clone_table_row('WORKORDERCOMPONENTS',
        'CUSTID = '''||in_custid||''' and ITEM = '''||in_item||'''',
        ''''||in_new_custid||''','''||in_new_item||'''',
        'CUSTID,ITEM',
            in_dblink,
        in_userid,
        out_errmsg);

   for crec in C_WOC(in_custid, in_item)
   loop
   clone_table_row('WORKORDERCLASSES',
        'CUSTID = '''||crec.custid||
         ''' and ITEM = '''||crec.item||
         ''' and KITTED_CLASS = '''||crec.kitted_class||'''',
        ''''||in_new_custid||''','''||in_new_item||'''',
        'CUSTID,ITEM',
            in_dblink,
        in_userid,
        out_errmsg);
   end loop;

   for crec in C_WOI(in_custid, in_item)
   loop
   clone_table_row('WORKORDERINSTRUCTIONS',
        'CUSTID = '''||crec.custid||
         ''' and ITEM = '''||crec.item||
         ''' and KITTED_CLASS = '''||crec.kitted_class||
         ''' and SEQ = '''||crec.seq||'''',
        ''''||in_new_custid||''','''||in_new_item||'''',
        'CUSTID,ITEM',
            in_dblink,
        in_userid,
        out_errmsg);
   end loop;

   for crec in C_WOD(in_custid, in_item)
   loop
   clone_table_row('WORKORDERDESTINATIONS',
        'CUSTID = '''||crec.custid||
         ''' and ITEM = '''||crec.item||
         ''' and KITTED_CLASS = '''||crec.kitted_class||
         ''' and SEQ = '''||crec.seq||
         ''' and FACILITY = '''||crec.facility||'''',
        ''''||in_new_custid||''','''||in_new_item||'''',
        'CUSTID,ITEM',
            in_dblink,
        in_userid,
        out_errmsg);
   end loop;

EXCEPTION WHEN OTHERS THEN
  out_errmsg := 'clone_kit: ' || sqlerrm;
END clone_kit;

------------------------------------------------------------------------
--
-- clone_receipt_order -
--
------------------------------------------------------------------------
PROCEDURE clone_receipt_order
(
    in_orderid      IN number,
    in_shipid       IN number,
      in_dblink       IN varchar2,
    in_userid       IN varchar2,
    in_new_orderid  IN OUT number,
    in_new_shipid   IN OUT number,
    out_errmsg      OUT varchar2
)
IS

CURSOR C_ORD(in_orderid number, in_shipid number)
IS
 SELECT *
   FROM orderhdr
  WHERE orderid = in_orderid
    AND shipid = in_shipid;

ORD orderhdr%rowtype;


cursor C_CUS(in_custid varchar2) is
  select linenumbersyn
    from customer
   where custid = in_custid;
CU C_CUS%rowtype;


errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- Verify order is correct
    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order to clone does not exist';
        return;
    end if;

    if ORD.ordertype <> 'R' then
        out_errmsg := 'Order to clone is not a receipt order';
        return;
    end if;

-- Setup new orderid shipid of not provided by calling routine
    if in_new_orderid is null then
        in_new_orderid := in_orderid;
    end if;

    if in_new_shipid is null then
      begin
        select max(shipid) + 1
          into in_new_shipid
          from orderhdr
         where orderid = in_orderid;
      exception when others then
        in_new_shipid := in_shipid + 1;
      end;
    end if;


    CU := null;
    open C_CUS(ORD.custid);
    fetch C_CUS into CU;
    close C_CUS;

    zcl.clone_orderhdr(in_orderid, in_shipid, in_new_orderid, in_new_shipid,
        in_dblink, in_userid, out_errmsg);

    if out_errmsg <> 'OKAY' then
        return;
    end if;


    clone_table_row('ORDERHDRBOLCOMMENTS',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        in_new_orderid||','||in_new_shipid,
        'ORDERID,SHIPID',
      in_dblink,
        in_userid,
        out_errmsg);

    if out_errmsg <> 'OKAY' then
        return;
    end if;


    update  orderhdr
       set  orderstatus = '0',
            commitstatus = '0',
            loadno = null,
            stopno = null,
            shipno = null,
            qtyorder = 0,
            weightorder = 0,
            cubeorder = 0,
            amtorder = 0,
            qtycommit = null,
            weightcommit = null,
            cubecommit = null,
            amtcommit = null,
            qtyship = null,
            weightship = null,
            cubeship = null,
            amtship = null,
            qtytotcommit = null,
            weighttotcommit = null,
            cubetotcommit = null,
            amttotcommit = null,
            qtyrcvd = null,
            weightrcvd = null,
            cubercvd = null,
            amtrcvd = null,
            statusupdate = sysdate,
            lastupdate = sysdate,
            wave = null,
            qtypick = null,
            weightpick = null,
            cubepick = null,
            amtpick = null,
            staffhrs = null,
            qty2sort = null,
            weight2sort = null,
            cube2sort = null,
            amt2sort = null,
            qty2pack = null,
            weight2pack = null,
            cube2pack = null,
            amt2pack = null,
            qty2check = null,
            weight2check = null,
            cube2check = null,
            amt2check = null,
            confirmed = null,
            rejectcode = null,
            rejecttext = null,
            dateshipped = null,
            origorderid = null,
            origshipid = null,
            bulkretorderid = null,
            bulkretshipid = null,
            returntrackingno = null,
            packlistshipdate = null,
            edicancelpending = null,
            backorderyn = 'N',
            tms_status = decode(nvl(ORD.tms_status,'X'),'X','X','1'),
            tms_status_update = sysdate,
            tms_shipment_id = null,
            tms_release_id = null,
            seal_verification_attempts = null,
            seal_verified = null
     where orderid = in_new_orderid
       and shipid = in_new_shipid;


    for cod in (select * from orderdtl
                 where orderid = in_orderid
                  and shipid = in_shipid)
    loop
        clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
                ||' and ITEM = '''||cod.item||''''
                ||' and nvl(LOTNUMBER,''(none)'') = '''
                    ||nvl(cod.lotnumber,'(none)')||'''',
            in_new_orderid||','||in_new_shipid||','''||cod.item
                ||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
         in_dblink,
            in_userid,
            out_errmsg);

        zcl.clone_orderdtl(in_orderid, in_shipid, cod.item, cod.lotnumber,
                      in_new_orderid, in_new_shipid, cod.item, cod.lotnumber,
                 in_dblink, in_userid, errmsg);

        update  orderdtl
           set  linestatus = 'A',
                commitstatus = null,
                qtycommit = null,
                weightcommit = null,
                cubecommit = null,
                amtcommit = null,
                qtyship = null,
                weightship = null,
                cubeship = null,
                amtship = null,
                qtytotcommit = null,
                weighttotcommit = null,
                cubetotcommit = null,
                amttotcommit = null,
                qtyrcvd = null,
                weightrcvd = null,
                cubercvd = null,
                amtrcvd = null,
                qtyrcvdgood = null,
                weightrcvdgood = null,
                cubercvdgood = null,
                amtrcvdgood = null,
                qtyrcvddmgd = null,
                weightrcvddmgd = null,
                cubercvddmgd = null,
                amtrcvddmgd = null,
                qtypick = null,
                weightpick = null,
                cubepick = null,
                amtpick = null,
                childorderid = null,
                childshipid = null,
                staffhrs = null,
                qty2sort = null,
                weight2sort = null,
                cube2sort = null,
                amt2sort = null,
                qty2pack = null,
                weight2pack = null,
                cube2pack = null,
                amt2pack = null,
                qty2check = null,
                weight2check = null,
                cube2check = null,
                amt2check = null,
                asnvariance = null
         where orderid = in_new_orderid
           and shipid = in_new_shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');



        if CU.linenumbersyn = 'Y' then
          for ol in (select *
                   from orderdtlline
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and item = cod.item
                    and nvl(lotnumber,'(none)') =
                        nvl(cod.lotnumber,'(none)')
                    and nvl(xdock,'N') = 'N')
          loop
            zcl.clone_table_row('ORDERDTLLINE',
                'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
                    ||' and ITEM = '''||ol.item||''''
                    ||' and nvl(LOTNUMBER,''(none)'') = '''
                        ||nvl(ol.lotnumber,'(none)')||''''
                    ||' and LINENUMBER = '|| ol.linenumber,
                in_new_orderid||','||in_new_shipid||','''||ol.item
                    ||''','''||ol.lotnumber||''','||ol.linenumber,
                'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER',
            in_dblink, in_userid, errmsg);
          end loop;
        end if;


    end loop;



EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
END clone_receipt_order;


------------------------------------------------------------------------
--
-- clone_outbound_order -
--
------------------------------------------------------------------------
PROCEDURE clone_outbound_order
(
    in_orderid      IN number,
    in_shipid       IN number,
      in_dblink       IN varchar2,
    in_userid       IN varchar2,
    in_reference    IN varchar2,
    out_new_orderid OUT number,
    out_new_shipid  OUT number,
    out_errmsg      OUT varchar2)
is

   cursor c_ord(p_orderid number, p_shipid number) is
      select OH.orderid, OH.ordertype, OH.custid, OH.tms_status,
             nvl(CU.linenumbersyn,'N') as linenumbersyn,
             trim(OH.hdrpassthruchar27) as hdrpassthruchar27,
             reduceorderqtybycancel
         from orderhdr OH, customer CU, customer_aux CA
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and CU.custid = OH.custid
           and CA.custid = OH.custid;
   ord c_ord%rowtype := null;
   l_msg varchar2(255);
   l_orderid orderhdr.orderid%type;
   l_shipid orderhdr.shipid%type := 1;
begin
   out_new_orderid := null;
   out_new_shipid := null;
   out_errmsg := 'OKAY';

-- Verify order is correct
   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;

   if ord.orderid is null then
      out_errmsg := 'Order to duplicate does not exist';
      return;
   end if;

   if ord.ordertype <> 'O' then
      out_errmsg := 'Order to duplicate is not an outbound shipment order';
      return;
   end if;

-- Get next available orderid
   zoe.get_next_orderid(l_orderid, l_msg);
   if l_msg <> 'OKAY' then
      out_errmsg := 'No next orderid: ' || l_msg;
      return;
   end if;

-- Clone header related data
   zcl.clone_orderhdr(in_orderid, in_shipid, l_orderid, l_shipid,
         in_dblink, in_userid, out_errmsg);
   if out_errmsg <> 'OKAY' then
      return;
   end if;

   clone_table_row('ORDERHDRBOLCOMMENTS',
         'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
         l_orderid||','||l_shipid,
         'ORDERID,SHIPID',
       in_dblink,
         in_userid,
         out_errmsg);
   if out_errmsg <> 'OKAY' then
      return;
   end if;

-- Update header
   update orderhdr
      set orderstatus = '0',
          commitstatus = '0',
          loadno = null,
          stopno = null,
          shipno = null,
          qtyorder = 0,
          weightorder = 0,
          cubeorder = 0,
          amtorder = 0,
          qtycommit = null,
          weightcommit = null,
          cubecommit = null,
          amtcommit = null,
          qtyship = null,
          weightship = null,
          cubeship = null,
          amtship = null,
          qtytotcommit = null,
          weighttotcommit = null,
          cubetotcommit = null,
          amttotcommit = null,
          qtyrcvd = null,
          weightrcvd = null,
          cubercvd = null,
          amtrcvd = null,
          wave = null,
          qtypick = null,
          weightpick = null,
          cubepick = null,
          amtpick = null,
          parentorderid = null,
          parentshipid = null,
          parentorderitem = null,
          parentorderlot = null,
          workorderseq = null,
          staffhrs = null,
          qty2sort = null,
          weight2sort = null,
          cube2sort = null,
          amt2sort = null,
          qty2pack = null,
          weight2pack = null,
          cube2pack = null,
          amt2pack = null,
          qty2check = null,
          weight2check = null,
          cube2check = null,
          amt2check = null,
          confirmed = null,
          rejectcode = null,
          rejecttext = null,
          dateshipped = null,
          origorderid = null,
          origshipid = null,
          bulkretorderid = null,
          bulkretshipid = null,
          returntrackingno = null,
          packlistshipdate = null,
          edicancelpending = null,
          backorderyn = 'N',
          tms_status = decode(nvl(ord.tms_status,'X'),'X','X','1'),
          tms_status_update = sysdate,
          tms_shipment_id = null,
          tms_release_id = null,
          shippingcost = null,
          reference = in_reference,
          xdockorderid = null,
          xdockshipid = null,
          prono = null,
          invoicenumber810 = null,
          autostagemixzone_yn = null,
          tms_carrier_optimized_yn = 'N',
          original_wave_before_combine = null,
          autogenerated_vicsbol = null
      where orderid = l_orderid
        and shipid = l_shipid;

-- hdrpassthruchar27 should be cleared 
-- if it's populated with a generated VISC BOL number
   if (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') in ('Y','L')) then
     if ((length(ord.hdrpassthruchar27) = 17) and
         (ord.hdrpassthruchar27 = zld.calccheckdigit(substr(ord.hdrpassthruchar27,1,16)))) then
       update orderhdr
          set hdrpassthruchar27 = null
        where orderid = l_orderid
          and shipid = l_shipid;
     end if;
   end if;

-- Clone detail related data

   update customer_aux
   set reduceorderqtybycancel = 'N'
   where custid = ord.custid;

   for cod in (select item, lotnumber from orderdtl
               where orderid = in_orderid
                 and shipid = in_shipid) loop

      clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
               ||' and ITEM = '''||cod.item||''''
               ||' and nvl(LOTNUMBER,''(none)'') = '''||nvl(cod.lotnumber,'(none)')||'''',
            l_orderid||','||l_shipid||','''||cod.item||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
         in_dblink, in_userid, out_errmsg);
      if out_errmsg <> 'OKAY' then
         return;
      end if;

      zcl.clone_orderdtl(in_orderid, in_shipid, cod.item, cod.lotnumber,
            l_orderid, l_shipid, cod.item, cod.lotnumber, in_dblink, in_userid, out_errmsg);
      if out_errmsg <> 'OKAY' then
         return;
      end if;

      update orderdtl
         set linestatus = 'A',
             commitstatus = null,
             qtycommit = null,
             weightcommit = null,
             cubecommit = null,
             amtcommit = null,
             qtyship = null,
             weightship = null,
             cubeship = null,
             amtship = null,
             qtytotcommit = null,
             weighttotcommit = null,
             cubetotcommit = null,
             amttotcommit = null,
             qtyrcvd = null,
             weightrcvd = null,
             cubercvd = null,
             amtrcvd = null,
             qtyrcvdgood = null,
             weightrcvdgood = null,
             cubercvdgood = null,
             amtrcvdgood = null,
             qtyrcvddmgd = null,
             weightrcvddmgd = null,
             cubercvddmgd = null,
             amtrcvddmgd = null,
             qtypick = null,
             weightpick = null,
             cubepick = null,
             amtpick = null,
             childorderid = null,
             childshipid = null,
             staffhrs = null,
             qty2sort = null,
             weight2sort = null,
             cube2sort = null,
             amt2sort = null,
             qty2pack = null,
             weight2pack = null,
             cube2pack = null,
             amt2pack = null,
             qty2check = null,
             weight2check = null,
             cube2check = null,
             amt2check = null,
             asnvariance = null,
             xdockorderid = null,
             xdockshipid = null,
             xdocklocid = null
         where orderid = l_orderid
           and shipid = l_shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');

      if ord.linenumbersyn = 'Y' then
         for ol in (select item, lotnumber, linenumber
                     from orderdtlline
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and item = cod.item
                       and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
                       and nvl(xdock,'N') = 'N') loop

            zcl.clone_table_row('ORDERDTLLINE',
                  'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
                     ||' and ITEM = '''||ol.item||''''
                     ||' and nvl(LOTNUMBER,''(none)'') = '''||nvl(ol.lotnumber,'(none)')||''''
                     ||' and LINENUMBER = '|| ol.linenumber,
                  l_orderid||','||l_shipid||','''||ol.item
                     ||''','''||ol.lotnumber||''','||ol.linenumber,
                  'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER',
               in_dblink, in_userid, out_errmsg);
            if out_errmsg <> 'OKAY' then
               return;
            end if;
         end loop;
      end if;
   end loop;
   
   update customer_aux
   set reduceorderqtybycancel = ord.reduceorderqtybycancel
   where custid = ord.custid;

   zoh.add_orderhistory(l_orderid, l_shipid,
         'Order duplicated',
         'Order duplicated from: '||in_orderid||'-'||in_shipid,
       in_userid, out_errmsg);

   out_new_orderid := l_orderid;
   out_new_shipid := l_shipid;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
END clone_outbound_order;


procedure clone_ownerxfer_order
(
   in_orderid      in number,
   in_shipid       in number,
   in_dblink       in varchar2,
   in_userid       in varchar2,
   out_new_orderid out number,
   out_new_shipid  out number,
   out_errmsg      out varchar2)
is
   cursor c_ord(p_orderid number, p_shipid number) is
      select custid, ordertype, tms_status, xfercustid, loadno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   ord c_ord%rowtype := null;
   cursor c_cus(p_custid varchar2) is
      select linenumbersyn
         from customer
         where custid = p_custid;
   cu c_cus%rowtype := null;
   l_errmsg varchar2(200);
begin
   out_errmsg := 'OKAY';

-- Verify order is correct
   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;

   if ord.custid is null then
      out_errmsg := 'Order to clone does not exist';
      return;
   end if;

   if ord.ordertype <> 'U' then
      out_errmsg := 'Order to clone is not a transfer of ownership order';
      return;
   end if;

   zoe.get_next_orderid(out_new_orderid, l_errmsg);
   if l_errmsg <> 'OKAY' then
      out_errmsg := 'Unable to get next orderid';
      return;
   end if;
   out_new_shipid := 1;

   open c_cus(ord.custid);
   fetch c_cus into cu;
   close c_cus;

   zcl.clone_orderhdr(in_orderid, in_shipid, out_new_orderid, out_new_shipid,
         in_dblink, in_userid, out_errmsg);
   if out_errmsg <> 'OKAY' then
      return;
   end if;

   clone_table_row('ORDERHDRBOLCOMMENTS',
         'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
         out_new_orderid||','||out_new_shipid,
         'ORDERID,SHIPID',
       in_dblink,
         in_userid,
         out_errmsg);
   if out_errmsg <> 'OKAY' then
      return;
   end if;

   update orderhdr
      set custid = ord.xfercustid,
          orderstatus = 'A',
          commitstatus = '0',
          loadno = ord.loadno,
          qtyorder = 0,
          weightorder = 0,
          cubeorder = 0,
          amtorder = 0,
          qtycommit = null,
          weightcommit = null,
          cubecommit = null,
          amtcommit = null,
          qtyship = null,
          weightship = null,
          cubeship = null,
          amtship = null,
          qtytotcommit = null,
          weighttotcommit = null,
          cubetotcommit = null,
          amttotcommit = null,
          qtyrcvd = null,
          weightrcvd = null,
          cubercvd = null,
          amtrcvd = null,
          statusupdate = sysdate,
          lastupdate = sysdate,
          wave = null,
          qtypick = null,
          weightpick = null,
          cubepick = null,
          amtpick = null,
          staffhrs = null,
          qty2sort = null,
          weight2sort = null,
          cube2sort = null,
          amt2sort = null,
          qty2pack = null,
          weight2pack = null,
          cube2pack = null,
          amt2pack = null,
          qty2check = null,
          weight2check = null,
          cube2check = null,
          amt2check = null,
          confirmed = null,
          rejectcode = null,
          rejecttext = null,
          dateshipped = null,
          origorderid = null,
          origshipid = null,
          bulkretorderid = null,
          bulkretshipid = null,
          returntrackingno = null,
          packlistshipdate = null,
          edicancelpending = null,
          backorderyn = 'N',
          tms_status = decode(nvl(ord.tms_status,'X'),'X','X','1'),
          tms_status_update = sysdate,
          tms_shipment_id = null,
          tms_release_id = null,
          seal_verification_attempts = null,
          seal_verified = null,
          xfercustid =ord.custid,
          prono = null,
          tms_carrier_optimized_yn = 'N'
          --ownerxferorderid =in_orderid,
          --ownerxfershipid =in_shipid,
       where orderid =out_new_orderid
         and shipid =out_new_shipid;

   --update orderhdr
   --   set ownerxferorderid = out_new_orderid,
   --       ownerxfershipid = out_new_shipid,
   --   where orderid = in_orderid,
   --     and shipid = in_shipid;

   for cod in (select item, lotnumber, qtyship, weightship, cubeship, amtship
                 from orderdtl
                 where orderid = in_orderid
                  and shipid = in_shipid) loop
      clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
               ||' and ITEM = '''||cod.item||''''
               ||' and nvl(LOTNUMBER,''(none)'') = '''
               ||nvl(cod.lotnumber,'(none)')||'''',
            out_new_orderid||','||out_new_shipid||','''||cod.item
               ||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
         in_dblink,
            in_userid,
            out_errmsg);
      if out_errmsg <> 'OKAY' then
         return;
      end if;

      zcl.clone_orderdtl(in_orderid, in_shipid, cod.item, cod.lotnumber,
            out_new_orderid, out_new_shipid, cod.item, cod.lotnumber,
            in_dblink, in_userid, out_errmsg);
      if out_errmsg <> 'OKAY' then
         return;
      end if;

      update orderdtl
         set custid = ord.xfercustid,
             linestatus = 'A',
             commitstatus = null,
             qtycommit = null,
             weightcommit = null,
             cubecommit = null,
             amtcommit = null,
             qtyship = null,
             weightship = null,
             cubeship = null,
             amtship = null,
             qtytotcommit = null,
             weighttotcommit = null,
             cubetotcommit = null,
             amttotcommit = null,
             qtyrcvd = cod.qtyship,
             weightrcvd = cod.weightship,
             cubercvd = cod.cubeship,
             amtrcvd = cod.amtship,
             qtyrcvdgood = cod.qtyship,
             weightrcvdgood = cod.weightship,
             cubercvdgood = cod.cubeship,
             amtrcvdgood = cod.amtship,
             qtyrcvddmgd = null,
             weightrcvddmgd = null,
             cubercvddmgd = null,
             amtrcvddmgd = null,
             qtypick = null,
             weightpick = null,
             cubepick = null,
             amtpick = null,
             childorderid = null,
             childshipid = null,
             staffhrs = null,
             qty2sort = null,
             weight2sort = null,
             cube2sort = null,
             amt2sort = null,
             qty2pack = null,
             weight2pack = null,
             cube2pack = null,
             amt2pack = null,
             qty2check = null,
             weight2check = null,
             cube2check = null,
             amt2check = null,
             asnvariance = null
         where orderid = out_new_orderid
           and shipid = out_new_shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');

      if cu.linenumbersyn = 'Y' then
         for ol in (select item, lotnumber, linenumber
                     from orderdtlline
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and item = cod.item
                       and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
                       and nvl(xdock,'N') = 'N') loop
            zcl.clone_table_row('ORDERDTLLINE',
                  'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
                     ||' and ITEM = '''||ol.item||''''
                     ||' and nvl(LOTNUMBER,''(none)'') = '''
                     ||nvl(ol.lotnumber,'(none)')||''''
                     ||' and LINENUMBER = '|| ol.linenumber,
                  out_new_orderid||','||out_new_shipid||','''||ol.item
                     ||''','''||ol.lotnumber||''','||ol.linenumber,
                  'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER',
               in_dblink, in_userid, out_errmsg);
         end loop;
      end if;
      if out_errmsg <> 'OKAY' then
         return;
      end if;
   end loop;

exception
   when OTHERS then
      out_errmsg := sqlerrm;
end clone_ownerxfer_order;


------------------------------------------------------------------------
--
-- update_custitem -
--
------------------------------------------------------------------------
PROCEDURE update_custitem
(
    in_custid       IN varchar2,
    in_item         IN varchar2,
    in_new_custid   IN varchar2,
    in_new_item     IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
   TYPE  CUR_TYP is REF CURSOR;
   cdata CUR_TYP;
   crec_custitem  custitem%rowtype;
   l_in_dblink    varchar2(50);

BEGIN
-- dbms_output.put_line('update_custitem:  in_new_custid/in_new_item = '||
--                in_new_custid||' / '||in_new_item);
   out_errmsg := 'OKAY';

   l_in_dblink := null;
    if in_dblink is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   -- validate rategroup and productgroup for new item
   crec_custitem := null;
   open cdata for 'select rategroup, productgroup from custitem'||l_in_dblink||
      ' where custid= :1 and item= :2'
      using in_new_custid, in_new_item;

   fetch cdata into crec_custitem.rategroup, crec_custitem.productgroup;
   close cdata;

   open cdata for 'select rategroup from custrate'||l_in_dblink||
      ' where custid= :1 and rategroup= :2'
      using in_new_custid, crec_custitem.rategroup;
   fetch cdata into crec_custitem.rategroup;
   close cdata;

   open cdata for 'select productgroup from custproductgroup'||l_in_dblink||
      ' where custid= :1 and productgroup= :2'
      using crec_custitem.custid, crec_custitem.productgroup;
   fetch cdata into crec_custitem.productgroup;
   close cdata;

   execute immediate 'update custitem'||l_in_dblink||
      ' set rategroup      = :rategroup,'||
         ' productgroup   = :productgroup,'||
         ' lastuser       = :in_userid,'||
         ' lastupdate     = sysdate,'||
         ' lastcount      = null'||
      ' where  custid       = :custid'||
         ' and item       = :item'
   using crec_custitem.rategroup,
      crec_custitem.productgroup,
      in_userid,
      in_new_custid,
      in_new_item;

   -- validate lot sequence for item
   execute immediate 'call zci.validate_auto_seq'||l_in_dblink||'(:in_custid, :in_productgroup, :in_item , :out_msg)'
   using in crec_custitem.custid, in crec_custitem.rategroup, in crec_custitem.item, in out out_errmsg;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'update_custitem: '|| sqlerrm;
END update_custitem;

------------------------------------------------------------------------
--
-- validate_custitem -
--
------------------------------------------------------------------------
PROCEDURE validate_custitem
(
    in_custid       IN varchar2,
    in_item         IN varchar2,
    in_new_custid   IN varchar2,
    in_new_item     IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
   TYPE  CUR_TYP is REF CURSOR;
   cdata CUR_TYP;

   crec_custitem              custitem%rowtype;
 crec_custitem_tmp          custitem%rowtype;
   crec_custitembolcomments   custitembolcomments%rowtype;
   crec_custitemlabelprofiles custitemlabelprofiles%rowtype;
   crec_custitemuomuos        custitemuomuos%rowtype;
   crec_itempickfronts        itempickfronts%rowtype;
   crec_custitemfacility      custitemfacility%rowtype;
   in_msgtext                 appmsgs.msgtext%type;
   l_in_dblink                varchar2(50);
   l_count                    number;

BEGIN
  debug_msg('validate_custitem:  in_new_custid/in_new_item = '||
               in_new_custid||' / '||in_new_item);
   out_errmsg := 'OKAY';

   l_in_dblink := null;
  if in_dblink is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

-- Retrieve new item
   crec_custitem := null;
   open cdata for
   'select '||
      ' rategroup, custid, productgroup, baseuom, item, '||
      ' cartontype, pallet_uom, expiryaction, labeluom, nmfc, ltlfc, countryof,'||
      ' recvinvstatus, parseruleid, returnsdisposition,'||
      ' lotfmtruleid,  serialfmtruleid, user1fmtruleid, user2fmtruleid, user3fmtruleid,'||
      ' invstatus, inventoryclass, primaryhazardclass, primarychemcode, secondarychemcode,'||
      ' tertiarychemcode, quaternarychemcode, imoprimarychemcode, imosecondarychemcode,'||
      ' imotertiarychemcode, imoquaternarychemcode, iatasecondarychemcode, iatatertiarychemcode,'||
      ' iataquaternarychemcode, sara_ct_container, sara_ct_pressure, sara_ct_temperature,'||
      ' sara_cas_number1'||
   ' from CUSTITEM'||l_in_dblink||
   ' where custid= :1 and item= :2'
   using in_new_custid, in_new_item;

   fetch cdata into
      crec_custitem.rategroup, crec_custitem.custid, crec_custitem.productgroup,
      crec_custitem.baseuom, crec_custitem.item, crec_custitem.cartontype,
      crec_custitem.pallet_uom, crec_custitem.expiryaction, crec_custitem.labeluom,
      crec_custitem.nmfc, crec_custitem.ltlfc, crec_custitem.countryof,
      crec_custitem.recvinvstatus, crec_custitem.parseruleid, crec_custitem.returnsdisposition,
      crec_custitem.lotfmtruleid, crec_custitem.serialfmtruleid, crec_custitem.user1fmtruleid,
      crec_custitem.user2fmtruleid, crec_custitem.user3fmtruleid, crec_custitem.invstatus,
      crec_custitem.inventoryclass, crec_custitem.primaryhazardclass, crec_custitem.primarychemcode,
      crec_custitem.secondarychemcode, crec_custitem.tertiarychemcode, crec_custitem.quaternarychemcode,
      crec_custitem.imoprimarychemcode, crec_custitem.imosecondarychemcode, crec_custitem.imotertiarychemcode,
      crec_custitem.imoquaternarychemcode, crec_custitem.iatasecondarychemcode, crec_custitem.iatatertiarychemcode,
      crec_custitem.iataquaternarychemcode, crec_custitem.sara_ct_container, crec_custitem.sara_ct_pressure,
      crec_custitem.sara_ct_temperature, crec_custitem.sara_cas_number1;
   close cdata;

-- Validate BASEUOM
   if crec_custitem.BASEUOM is not null then
      execute immediate 'select count(1) from unitsofmeasure'||l_in_dblink||' where code= :1'
      into l_count
      using crec_custitem.BASEUOM;

      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Base UOM: '||crec_custitem.BASEUOM||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate CARTONTYPE
   if crec_custitem.CARTONTYPE is not null then
      execute immediate 'select count(1) from cartontypes'||l_in_dblink||' where code= :1'
      into l_count
      using crec_custitem.CARTONTYPE;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'CARTONTYPE: '||crec_custitem.CARTONTYPE||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

  debug_msg('after cartontype valid >' || out_errmsg || '<');

-- Validate PALLET_UOM
   if crec_custitem.PALLET_UOM is not null then
      execute immediate 'select count(1) from unitsofmeasure'||l_in_dblink||' where code= :1'
      into l_count
      using crec_custitem.PALLET_UOM;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'PALLET_UOM: '||crec_custitem.PALLET_UOM||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate EXPIRYACTION
   if crec_custitem.EXPIRYACTION is not null then
      execute immediate 'select count(1) from expirationactions'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.EXPIRYACTION;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'EXPIRYACTION: '||crec_custitem.EXPIRYACTION||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate LABELUOM
   if crec_custitem.LABELUOM is not null then
      execute immediate 'select count(1) from unitsofmeasure'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.LABELUOM;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'LABELUOM: '||crec_custitem.LABELUOM||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate NMFC
   if crec_custitem.NMFC is not null then
      execute immediate 'select count(1) from NMFCLASSCODES'||l_in_dblink||' where NMFC=:1'
      into l_count
      using crec_custitem.NMFC;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'NMFC: '||crec_custitem.NMFC||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate LTLFC
   if crec_custitem.LTLFC is not null then
      execute immediate 'select count(1) from LTLFREIGHTCLASS'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.LTLFC;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'LTLFC: '||crec_custitem.LTLFC||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
-- Validate UNITSOFSTORAGE

-- Validate Country of Origin
   if crec_custitem.COUNTRYOF is not null then
      execute immediate 'select count(1) from countrycodes'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.COUNTRYOF;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Country of Origin: '||crec_custitem.COUNTRYOF||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate Default Receiving Status
   if crec_custitem.RECVINVSTATUS is not null then
      execute immediate 'select count(1) from inventorystatus'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.RECVINVSTATUS;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Default Receiving Status: '||crec_custitem.RECVINVSTATUS||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate ParseRule
   if crec_custitem.PARSERULEID is not null then
      execute immediate 'select count(1) from parserule'||l_in_dblink||' where ruleid=:1'
      into l_count
      using crec_custitem.PARSERULEID;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'ParseRule: '||crec_custitem.PARSERULEID||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate RETURNSDISPOSITION
   if crec_custitem.RETURNSDISPOSITION is not null then
      execute immediate 'select count(1) from RETURNSDISPOSITION'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.RETURNSDISPOSITION;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'RETURNSDISPOSITION: '||crec_custitem.RETURNSDISPOSITION||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate Receiving/Format Rules Validation
   if crec_custitem.lotfmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_custitem.lotfmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_custitem.lotfmtruleid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_custitem.serialfmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_custitem.serialfmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_custitem.serialfmtruleid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_custitem.user1fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_custitem.user1fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_custitem.user1fmtruleid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_custitem.user2fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_custitem.user2fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_custitem.user2fmtruleid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_custitem.user3fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_custitem.user3fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_custitem.user3fmtruleid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

--  Validate Shipping/Default Inventory Status
   if crec_custitem.invstatus is not null then
      execute immediate 'select count(1) from inventorystatus'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.invstatus;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Default Inventory Status: '||crec_custitem.invstatus||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate Shipping/Default Inventory Class
   if crec_custitem.inventoryclass is not null then
      execute immediate 'select count(1) from inventoryclass'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.inventoryclass;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Default Inventory Class: '||crec_custitem.inventoryclass||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;


-- Validate BOL COMMENTS
-- Add consignee to consignee table if not already present
   open cdata for 'select consignee from CUSTITEMBOLCOMMENTS'||l_in_dblink||
      ' where custid= :1 and item= :2'
      using crec_custitem.custid, crec_custitem.item;
   loop
      fetch cdata into crec_custitembolcomments.consignee;
      exit when cdata%notfound;

      if crec_custitembolcomments.consignee is not null then
         execute immediate 'select count(1) from consignee'||l_in_dblink||'
            where consignee= :1'
         into l_count
         using crec_custitembolcomments.consignee;
         if l_count = 0 then
            clone_table_row('CONSIGNEE',
               'CONSIGNEE = '''||crec_custitembolcomments.consignee||'''',
               ''''||crec_custitembolcomments.consignee||'''',
               'CONSIGNEE',
               in_dblink,
               in_userid,
               out_errmsg);
            if out_errmsg <> 'OKAY' then
          out_errmsg := 'consignee: ' || out_errmsg;
               return;
            end if;
         end if;
      end if;

   end loop;
   close cdata;

-- validate Label Profile
   open cdata for 'select distinct profid from custitemlabelprofiles'||l_in_dblink||
      ' where custid= :1 and item= :2'||
      '   and item is not null'
   using crec_custitem.custid, crec_custitem.item;

   loop
      fetch cdata into crec_custitemlabelprofiles.profid;
      exit when cdata%notfound;

      execute immediate 'select count(1) from labelprofiles'||l_in_dblink||
         ' where code= :1'
      into l_count
      using crec_custitemlabelprofiles.profid;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Label Profile: '||crec_custitemlabelprofiles.profid||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end loop;
   close cdata;

-- Validate Hazardous Class for Storage
   if crec_custitem.primaryhazardclass is not null then
      execute immediate 'select count(1) from hazardousclasses'||l_in_dblink||
         ' where code= :1'
      into l_count
      using crec_custitem.primaryhazardclass;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Hazardous Class for Storage: '||crec_custitem.primaryhazardclass||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

  debug_msg('before chemical codes >' || out_errmsg || '<');

-- Validate chemical codes
   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.PRIMARYCHEMCODE;
   validate_chemical_codes(crec_custitem.primarychemcode, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);
  debug_msg('after primary chem code >' || out_errmsg || '<');

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.SECONDARYCHEMCODE;
   validate_chemical_codes(crec_custitem.SECONDARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.TERTIARYCHEMCODE;
   validate_chemical_codes(crec_custitem.TERTIARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.QUATERNARYCHEMCODE;
   validate_chemical_codes(crec_custitem.QUATERNARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IMOPRIMARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IMOPRIMARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IMOSECONDARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IMOSECONDARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IMOTERTIARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IMOTERTIARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IMOQUATERNARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IMOQUATERNARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IATASECONDARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IATASECONDARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IATATERTIARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IATATERTIARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.IATAQUATERNARYCHEMCODE;
   validate_chemical_codes(crec_custitem.IATAQUATERNARYCHEMCODE, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

  debug_msg('after chemical codes >' || out_errmsg || '<');

-- Validate SARA containertypes
   if crec_custitem.SARA_CT_CONTAINER is not null then
      execute immediate 'select count(1) from containertypes'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.SARA_CT_CONTAINER;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'SARA containertypes: '||crec_custitem.SARA_CT_CONTAINER||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate SARA pressures
   if crec_custitem.SARA_CT_PRESSURE is not null then
      execute immediate 'select count(1) from sarapressures'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.SARA_CT_PRESSURE;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'SARA containertypes: '||crec_custitem.SARA_CT_PRESSURE||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate SARA temperatures
   if crec_custitem.SARA_CT_TEMPERATURE is not null then
      execute immediate 'select count(1) from saratemperatures'||l_in_dblink||' where code=:1'
      into l_count
      using crec_custitem.SARA_CT_TEMPERATURE;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'SARA containertypes: '||crec_custitem.SARA_CT_TEMPERATURE||
                        ' does not exist in destination database for custid/item: '
                        ||crec_custitem.custid||'/'||crec_custitem.item,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

-- Validate SARA CASNUMBERS
   in_msgtext :=  'Chemical Code does not exist for custid/item/code:  '
               ||crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_custitem.SARA_CAS_NUMBER1;
   validate_sara_casnumbers(crec_custitem.SARA_CAS_NUMBER1, in_new_custid, in_dblink, in_msgtext, in_userid, out_errmsg);

  debug_msg('before uom/uos ' || out_errmsg);

-- Validate UNITOFMEASURE and UNITOFSTORAGE
   open cdata for 'select unitofmeasure from custitemuomuos'||l_in_dblink||
      ' where custid= :1 and item= :2'
   using crec_custitem.custid, crec_custitem.item;

   loop
      fetch cdata into crec_custitemuomuos.unitofmeasure;
      exit when cdata%notfound;

      execute immediate 'select count(1) from unitsofmeasure'||l_in_dblink||
         ' where code= :1'
      into l_count
      using crec_custitemuomuos.unitofmeasure;
      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'UNITOFMEASURE: '||crec_custitemuomuos.unitofmeasure||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;

      execute immediate 'select count(1) from unitofstorage'||l_in_dblink||
         ' where unitofstorage= :1'
      into l_count
      using crec_custitemuomuos.unitofstorage;
      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'UNITOFSTORAGE: '||crec_custitemuomuos.unitofstorage||
                        ' does not exist in destination database for custid: '||crec_custitem.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;

   end loop;
   close cdata;

  debug_msg('before pick fronts >' || out_errmsg || '<');

-- Validate Item PickFronts
   open cdata for 'select facility, pickfront from itempickfronts'||l_in_dblink||
      ' where custid= :1 and item= :2'
   using crec_custitem.custid, crec_custitem.item;

   loop
      fetch cdata into crec_itempickfronts.facility, crec_itempickfronts.pickfront;
      exit when cdata%notfound;

      execute immediate 'select count(1) from location'||l_in_dblink||
         ' where locid= :1 and facility= :2'
      into l_count
      using crec_itempickfronts.pickfront, crec_itempickfronts.facility;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Item PickFronts: '||crec_itempickfronts.pickfront||
                        ' does not exist in destination database for custid/item/facility: '||
                        crec_custitem.custid||'/'||crec_custitem.item||'/'||crec_itempickfronts.facility,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end loop;
   close cdata;

-- validate Facility Settings
   open cdata for 'select distinct facility, allocrule from custitemfacility'||l_in_dblink||
      ' where custid = :1'
      using crec_custitem.custid;
   loop
      fetch cdata into  crec_custitemfacility.facility, crec_custitemfacility.allocrule;
      exit when cdata%notfound;

      -- validate Facility Settings - Allocation Rule
    if nvl(rtrim(crec_custitemfacility.allocrule),'C') != 'C' then
      execute immediate 'select count(1) from allocruleshdr'||l_in_dblink||
        ' where allocrule= :1 and facility= :2'
      into l_count
      using crec_custitemfacility.allocrule, crec_custitemfacility.facility;
      if (l_count = 0) then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custitemfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Allocation Rule: '||crec_custitemfacility.allocrule||
                  ' does not exist in destination database for custid: '||crec_custitem.custid||
                  ' and facility: '||crec_custitemfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;

      --  validate Facility Settings - Replenishnment Rule
    if nvl(rtrim(crec_custitemfacility.replallocrule),'C') != 'C' then
      execute immediate 'select count(1) from allocruleshdr'||l_in_dblink||
        ' where allocrule= :1 and facility= :2'
      into l_count
      using crec_custitemfacility.replallocrule, crec_custitemfacility.facility;
      if (l_count = 0) and
         (crec_custitemfacility.replallocrule != 'C')    then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custitemfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Replenishment Rule: '||crec_custitemfacility.replallocrule||
                  ' does not exist in destination database for custid: '||crec_custitem.custid||
                  ' and facility: '||crec_custitemfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;

--  validate Facility Settings - Putaway Profile
    if nvl(rtrim(crec_custitemfacility.profid),'C') != 'C' then
      execute immediate 'select count(1) from putawayprof'||l_in_dblink||
        ' where profid= :1 and facility= :2'
      into l_count
      using crec_custitemfacility.profid, crec_custitemfacility.facility;
      if l_count = 0  then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custitemfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Putaway Rule: '||crec_custitemfacility.profid||
                  ' does not exist in destination database for custid: '||crec_custitemfacility.custid||
                  ' and facility: '||crec_custitemfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;
   end loop;
   close cdata;

  debug_msg('exiting validate custitem >' || out_errmsg || '<');

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'validate_custitem: '|| sqlerrm;
END validate_custitem;

------------------------------------------------------------------------
--
-- validate_chemical_codes -
--
------------------------------------------------------------------------
PROCEDURE validate_chemical_codes
(
   in_chemcode        IN chemicalcodes.chemcode%type,
   in_new_custid      IN customer.custid%type,
 in_dblink          IN varchar2,
   in_msgtext         IN varchar2,
 in_userid          IN varchar2,
 out_errmsg         IN OUT varchar2
)
IS
 l_in_dblink varchar2(50);
   l_count number;
BEGIN
  debug_msg('enter validate chem ' || out_errmsg);
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_chemcode is not null then
      execute immediate 'select count(1) from CHEMICALCODES'||l_in_dblink||
         ' where chemcode= :in_chemcode'
      into l_count
      using in_chemcode;

      if l_count = 0  then
      debug_msg('chem not found ' || out_errmsg);
      zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => in_msgtext,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      debug_msg('chem not found after ' || out_errmsg);
      end if;
   end if;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'validate_chemical_codes - '||in_chemcode||' - '|| sqlerrm;
END validate_chemical_codes;

------------------------------------------------------------------------
--
-- validate_sara_casnumbers -
--
------------------------------------------------------------------------
PROCEDURE validate_sara_casnumbers
(
   in_cas             IN casnumbers.cas%type,
   in_new_custid      IN customer.custid%type,
 in_dblink          IN varchar2,
   in_msgtext         IN varchar2,
 in_userid          IN varchar2,
 out_errmsg         IN OUT varchar2
)
IS
 l_in_dblink varchar2(50);
   l_count number;
BEGIN
   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_cas is not null then
      execute immediate 'select count(1) from CASNUMBERS'||l_in_dblink||
         ' where cas = :in_cas'
      into l_count
      using in_cas;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => in_msgtext,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'validate_sara_casnumbers - in_cas: '|| sqlerrm;
END validate_sara_casnumbers;

------------------------------------------------------------------------
--
-- update_customer -
--
------------------------------------------------------------------------
PROCEDURE update_customer
(
    in_custid       IN varchar2,
    in_new_custid   IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
    TYPE            CUR_TYP is REF CURSOR;
    cdata           CUR_TYP;

   crec_shipper       custshipper%rowtype;
   crec_consignee     custconsignee%rowtype;
   l_in_productgroup  custproductgroup.productgroup%type;
   l_in_item          custitem.item%type;
   l_in_dblink        varchar2(50);
   l_count            number;

BEGIN
-- dbms_output.put_line('update_customer:  in_new_custid = '||in_new_custid);
   out_errmsg := 'OKAY';

   l_in_dblink := null;
    if in_dblink is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   -- update shipper information for new customer
   open cdata for
      'select shipper'||
      ' from CUSTSHIPPER'||l_in_dblink||
      ' where custid = '||''''||in_new_custid||'''';
    loop
      fetch cdata into crec_shipper.shipper;
      exit when cdata%notfound;
      execute immediate
         'select count(1)'||
         ' from SHIPPER'||l_in_dblink||
         ' where shipper=:1'
      into l_count
      using crec_shipper.shipper;

      if l_count = 0 then
            clone_table_row('SHIPPER',
               'SHIPPER = '''||crec_shipper.shipper||'''',
               ''''||crec_shipper.shipper||'''',
               'SHIPPER',
               in_dblink,
               in_userid,
               out_errmsg);
            if out_errmsg <> 'OKAY' then
               return;
            end if;
      end if;
   end loop;
   close cdata;

   -- update consignee information for new customer
   open cdata for
      'select consignee'||
      ' from CUSTCONSIGNEE'||l_in_dblink||
      ' where custid = '||''''||in_new_custid||'''';
    loop
      fetch cdata into crec_consignee.consignee;
      exit when cdata%notfound;
      execute immediate
         'select count(1)'||
         ' from CONSIGNEE'||l_in_dblink||
         ' where consignee=:1'
      into l_count
      using crec_consignee.consignee;
      if l_count = 0 then
         clone_table_row('CONSIGNEE',
            'CONSIGNEE = '''||crec_consignee.consignee||'''',
            ''''||crec_consignee.consignee||'''',
            'CONSIGNEE',
            in_dblink,
            in_userid,
            out_errmsg);
         if out_errmsg <> 'OKAY' then
            return;
         end if;
      end if;
    end loop;
   close cdata;

   -- validate lot sequence for customer
   l_in_productgroup := null;
   l_in_item := null;
   execute immediate 'call zci.validate_auto_seq'||l_in_dblink||'(:in_custid, :in_productgroup, :in_item , :out_msg)'
   using in in_new_custid, in l_in_productgroup, in l_in_item, in out out_errmsg;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'update_customer: '|| sqlerrm;
END update_customer;

------------------------------------------------------------------------
--
-- validate_customer -
--
------------------------------------------------------------------------
PROCEDURE validate_customer
(
    in_custid       IN varchar2,
    in_new_custid   IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS
 TYPE                        CUR_TYP is REF CURSOR;
 cdata                       CUR_TYP;
   crec_customer_aux           customer_aux%rowtype;
 crec_custcarriernotice      custcarriernotice%rowtype;
   crec_custfacility           custfacility%rowtype;
   crec_customer               customer%rowtype;
   crec_customer_tmp           customer%rowtype;
   crec_statreason             custinvstatuschange%rowtype;
   crec_custconsigneenotice    custconsigneenotice%rowtype;
   crec_customercarriers       customercarriers%rowtype;
   crec_custitemlabelprofiles  custitemlabelprofiles%rowtype;
   crec_custauditstageloc      custauditstageloc%rowtype;
   l_count                     number;
   l_in_dblink                 varchar2(50);

BEGIN

   out_errmsg := 'OKAY';

   l_in_dblink := null;
    if in_dblink is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   crec_customer := null;
   crec_customer_tmp := null;

   -- Retrieve new customer
   open cdata for 'select '||
      'custid,
      consume_owner,
      lotfmtruleid,
      serialfmtruleid,
      user1fmtruleid,
      user2fmtruleid,
      user3fmtruleid,
      parseruleid,
      pomapfile,
      invstatus,
      inventoryclass,
      outconfirmbatchmap,
      outrejectbatchmap,
      defcarrier,
      defservicelevel,
      outackbatchmap ,
      pallet_tracking_export_map,
      freight_bill_export_format,
      outshipsumbatchmap,
      outstatusbatchmap,
      tms_item_format,
      tms_orders_to_plan_format,
      tms_status_changes_format,
      tms_actual_ship_format,
      billfreightto
   from CUSTOMER'||l_in_dblink||
   ' where custid = :1'
   using in_new_custid;

   fetch cdata into
      crec_customer.custid,
      crec_customer.consume_owner,
      crec_customer.lotfmtruleid,
      crec_customer.serialfmtruleid,
      crec_customer.user1fmtruleid,
      crec_customer.user2fmtruleid,
      crec_customer.user3fmtruleid,
      crec_customer.parseruleid,
      crec_customer.pomapfile,
      crec_customer.invstatus,
      crec_customer.inventoryclass,
      crec_customer.outconfirmbatchmap,
      crec_customer.outrejectbatchmap,
      crec_customer.defcarrier,
      crec_customer.defservicelevel,
      crec_customer.outackbatchmap,
      crec_customer.pallet_tracking_export_map,
      crec_customer.freight_bill_export_format,
      crec_customer.outshipsumbatchmap,
      crec_customer.outstatusbatchmap,
      crec_customer.tms_item_format,
      crec_customer.tms_orders_to_plan_format,
      crec_customer.tms_status_changes_format,
      crec_customer.tms_actual_ship_format,
      crec_customer.billfreightto;
   close cdata;
   if crec_customer.custid is null then
      out_errmsg := 'validate_customer: Customer ID <'||in_new_custid||'> does not exist';
      return;
   end if;

   open cdata for
      'select custid,inv_adj_export_format'||
      ' from customer_aux'||l_in_dblink||
      ' where custid= :1'
      using crec_customer.custid;
   fetch cdata into crec_customer_aux.custid,
       crec_customer_aux.inv_adj_export_format;
   close cdata;

   if crec_customer_aux.custid is null then
      out_errmsg := 'validate_customer: Customer ID <'||in_new_custid||'> does not exist';
      return;
   end if;

   -- validate Name/consume_owner
   if crec_customer.consume_owner is not null then
      execute immediate 'select count(1)'||' from customer'||l_in_dblink||' where custid=:1'
      into l_count
      using crec_customer.consume_owner;

      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Name/consume_owner: '||crec_customer.consume_owner||
                     ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Receiving/Format Rules Validation
   if crec_customer.lotfmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_customer.lotfmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_customer.lotfmtruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.serialfmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_customer.serialfmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_customer.serialfmtruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.user1fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_customer.user1fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_customer.user1fmtruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.user2fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_customer.user2fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_customer.user2fmtruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.user3fmtruleid is not null then
      execute immediate ' select count(1) from formatvalidationrule'||l_in_dblink||
         ' where ruleid=:1'
         into l_count
         using crec_customer.user3fmtruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Format Rules Validation: '||crec_customer.user3fmtruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
 debug_msg('After Format Rules Validation');

   -- validate Receiving/Parseruleid
   if crec_customer.parseruleid is not null then
      execute immediate 'select count(1) from parserule'||l_in_dblink||
            ' where ruleid=:1'
      into l_count
      using crec_customer.parseruleid;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Parse Rule: '||crec_customer.parseruleid||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
 debug_msg('After Parseruleid Validation');

   -- validate Receiving/EDI Mapping Format
   if crec_customer.pomapfile is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and  name=:1'
      into l_count
      using crec_customer.POMAPFILE;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/EDI Mapping Format: '||crec_customer.pomapfile||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
 debug_msg('After EDI Mapping Format Validation');

   -- validate Receiving/Inventory Adjustment Export Format
   if crec_customer_aux.inv_adj_export_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and name=:1'
      into l_count
      using crec_customer_aux.inv_adj_export_format;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Inventory Adjustment Export Format: '||crec_customer_aux.inv_adj_export_format||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
 debug_msg('After Inventory Adjustment Export Format Validation');

   -- validate Receiving Inventory
   open cdata for 'select distinct fromstatus, tostatus, adjreason'||
      ' from custinvstatuschange'||l_in_dblink||
      ' where custid = '||''''||crec_customer.custid||'''';
   loop
      fetch cdata into crec_statreason.fromstatus,
         crec_statreason.tostatus,
         crec_statreason.adjreason;

      exit when cdata%notfound;

   -- validate Receiving / Inventory - FromStatus
      execute immediate  'select count(1) from inventorystatus'||l_in_dblink||
      ' where code = :1'
      into l_count
      using crec_statreason.fromstatus;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Inventory FromStatus: '||crec_statreason.fromstatus||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;

   -- validate Receiving / Inventory - ToStatus
      execute immediate  'select count(1) from inventorystatus'||l_in_dblink||
      ' where code = :1'
      into l_count
      using crec_statreason.tostatus;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Inventory ToStatus: '||crec_statreason.tostatus||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
  debug_msg('After Inventory Status Validation');

   -- validate Receiving / Inventory - Adjustment Reason
      execute immediate  'select count(1) from adjustmentreasons'||l_in_dblink||
      ' where code = :1'
      into l_count
      using crec_statreason.adjreason;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Receiving/Inventory Adjustment Reason: '||crec_statreason.adjreason||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
      debug_msg('After Inventory Adjustment Reason Validation');

   end loop;
   close cdata;

   --  validate Shipping / Option1 - Default Inventory Status
   if crec_customer.invstatus is not null then
      execute immediate 'select count(1) from inventorystatus'||l_in_dblink||' where code=:1'
      into l_count
      using crec_customer.invstatus;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping Option1/Default Inventory Status: '||crec_customer.invstatus||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping / Option1 - Default Inventory Class
   if crec_customer.inventoryclass is not null then
      execute immediate 'select count(1) from inventoryclass'||l_in_dblink||' where code=:1'
      into l_count
      using crec_customer.inventoryclass;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping Option1/Default Inventory Class: '||crec_customer.inventoryclass||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate billfreightto.
   if crec_customer.billfreightto is not null then
      execute immediate 'select count(1) from consignee'||l_in_dblink||' where consignee=:1'
      into l_count
      using crec_customer.billfreightto;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/billfreightto: '||crec_customer.billfreightto||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   --  validate Shipping / Option2 - Order Confirmation Export Format
   if crec_customer.outconfirmbatchmap is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||' where name=:1'
      into l_count
      using crec_customer.outconfirmbatchmap;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Order Confirmation Export Format: '||crec_customer.outconfirmbatchmap||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping / Option2 - Reject Notification Export Format
   if crec_customer.outrejectbatchmap is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||' where name=:1'
      into l_count
      using crec_customer.outrejectbatchmap;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Reject Notification Export Format: '||crec_customer.outrejectbatchmap||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping / Option2 - Consolidated Waves Template Defaults
   if crec_customer.defcarrier is not null or
      crec_customer.defservicelevel is not null then
      execute immediate 'select count(1) from carrierservicecodes'||l_in_dblink||
         ' where carrier=:1 and servicecode=:2'
      into l_count
      using crec_customer.defcarrier, crec_customer.defservicelevel;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Consolidated Waves Template(carrier/service): '||
                        crec_customer.defcarrier||'/'||crec_customer.defservicelevel||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);

         crec_customer_tmp.defconsolidated := null;
         crec_customer_tmp.defshiptype := null;
         crec_customer_tmp.defshipcost := null;
         crec_customer_tmp.defcarrier := null;
         crec_customer_tmp.defservicelevel := null;
      end if;
   end if;

   --  validate Shipping / Option3 - EDI Export Formats
   if crec_customer.outackbatchmap is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
      ' where name= :1 '
      into l_count
      using crec_customer.outackbatchmap ;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/EDI Export Mapping Format <'||crec_customer.outackbatchmap||
                        '> does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.pallet_tracking_export_map is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
      ' where name= :1 '
      into l_count
      using crec_customer.pallet_tracking_export_map ;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/EDI Export Mapping Format <'||crec_customer.pallet_tracking_export_map||
                        '> does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.freight_bill_export_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
      ' where name= :1 '
      into l_count
      using crec_customer.freight_bill_export_format ;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/EDI Export Mapping Format <'||crec_customer.freight_bill_export_format||
                        '> does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.outshipsumbatchmap is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
      ' where name= :1 '
      into l_count
      using crec_customer.outshipsumbatchmap ;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/EDI Export Mapping Format <'||crec_customer.outshipsumbatchmap||
                        '> does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;
   if crec_customer.outstatusbatchmap is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
      ' where name= :1 '
      into l_count
      using crec_customer.outstatusbatchmap ;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/EDI Export Mapping Format <'||crec_customer.outstatusbatchmap||
                        '> does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping / Audit Location
   open cdata for 'select auditstageloc, facility'||
      ' from   custauditstageloc'||l_in_dblink||
      ' where custid = :1'
   using crec_customer.custid;
   loop
      fetch cdata into crec_custauditstageloc.auditstageloc, crec_custauditstageloc.facility;
      exit when cdata%notfound;

      execute immediate ' select count(1) from '||
       ' (select distinct locid, facility'||
         ' from location'||
         ' where locid = :1'||
         ' and facility = (select distinct facility'||
                           ' from facility'||
                       ' where facility= :2))'
      into l_count
      using crec_custauditstageloc.auditstageloc, crec_custauditstageloc.facility;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => crec_custauditstageloc.facility,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping/Audit Location: '||
                        crec_custauditstageloc.auditstageloc||'/'||crec_custauditstageloc.facility||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end loop;
   close cdata;

   -- validate Shipping / Carriers
   open cdata for 'select distinct carrier from customercarriers'||l_in_dblink||
      ' where custid=:1'
      using crec_customer.custid;
   loop
      fetch cdata into crec_customercarriers.carrier;
      exit when cdata%notfound;

      execute immediate ' select count(1) from carrier'||l_in_dblink||
      ' where carrier= :1'
      into l_count
      using crec_customercarriers.carrier;

      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => crec_custfacility.facility,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping / Carrier: '||crec_customercarriers.carrier||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end loop;
   close cdata;

   -- validate Shipping / Notification
   open cdata for 'select distinct formatname'||
      ' from custconsigneenotice'||l_in_dblink||
      ' where custid = '||''''||crec_customer.custid||'''';
   loop
      fetch cdata into crec_custconsigneenotice.formatname;
      exit when cdata%notfound;

      -- Export Mapping Format
      if crec_custconsigneenotice.formatname is not null then
         execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
            ' where deftype = ''E'' and  name=:1'
         into l_count
         using crec_custconsigneenotice.formatname;
         if l_count = 0 then
            zms.log_autonomous_msg(
               in_author   => author,
               in_facility => null,
               in_custid   => in_new_custid,
               in_msgtext  => 'Shipping / Notification - Export Mapping Format: '||crec_custconsigneenotice.formatname||
                           ' does not exist in destination database for custid: '||crec_customer.custid,
               in_msgtype  => 'w',
               in_userid   => in_userid,
               out_msg     => out_errmsg);
         end if;
      end if;
   end loop;
   close cdata;

   -- validate Shipping TMS / Item Information Export Format
   if crec_customer.tms_item_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and  name=:1'
      into l_count
      using crec_customer.tms_item_format;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping TMS / Item Information Export Format: '||crec_customer.tms_item_format||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping TMS / Order Plan Export Format
   if crec_customer.tms_orders_to_plan_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and  name=:1'
      into l_count
      using crec_customer.tms_orders_to_plan_format;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping TMS / Order Plan Export Format: '||crec_customer.tms_orders_to_plan_format||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping TMS / Status Change Export Format
   if crec_customer.tms_status_changes_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and  name=:1'
      into l_count
      using crec_customer.tms_status_changes_format;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping TMS / Status Change Export Format: '||crec_customer.tms_status_changes_format||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping TMS / Actual Shipment Export Format
   if crec_customer.tms_actual_ship_format is not null then
      execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
         ' where deftype = ''E'' and  name=:1'
      into l_count
      using crec_customer.tms_actual_ship_format;
      if l_count = 0 then
         zms.log_autonomous_msg(
            in_author   => author,
            in_facility => null,
            in_custid   => in_new_custid,
            in_msgtext  => 'Shipping TMS / Actual Shipment Export Format: '||crec_customer.tms_actual_ship_format||
                        ' does not exist in destination database for custid: '||crec_customer.custid,
            in_msgtype  => 'w',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end if;

   -- validate Shipping Carrier Note
   open cdata for 'select distinct formatname from custcarriernotice'||l_in_dblink||
      ' where custid = '||''''||crec_customer.custid||'''';
   loop
      fetch cdata into crec_custcarriernotice.formatname;
      exit when cdata%notfound;

      -- Export Mapping Format
      if crec_custcarriernotice.formatname is not null then
         execute immediate 'select count(1) from impexp_definitions'||l_in_dblink||
            ' where deftype = ''E'' and  name=:1'
         into l_count
         using crec_custcarriernotice.formatname;
         if l_count = 0 then
            zms.log_autonomous_msg(
               in_author   => author,
               in_facility => null,
               in_custid   => in_new_custid,
               in_msgtext  => 'Shipping Carrier Note/Export Mapping Format: '||crec_custcarriernotice.formatname||
                           ' does not exist in destination database for custid: '||crec_customer.custid,
               in_msgtype  => 'w',
               in_userid   => in_userid,
               out_msg     => out_errmsg);
         end if;
      end if;
   end loop;
   close cdata;

   -- validate Label Profile
   open cdata for 'select distinct profid from custitemlabelprofiles'||l_in_dblink||
      ' where custid = :1 and item is null'
   using crec_customer.custid;
   loop
      fetch cdata into crec_custitemlabelprofiles.profid;
      exit when cdata%notfound;

      execute immediate 'select count(1) from labelprofiles'||l_in_dblink||
         ' where code= :1'
      into l_count
      using crec_custitemlabelprofiles.profid;

      -- skip validation for customer default
      if crec_custitemlabelprofiles.profid not in ('C') then
         if l_count = 0  then
            zms.log_autonomous_msg(
               in_author   => AUTHOR,
               in_facility => null,
               in_custid   => in_new_custid,
               in_msgtext  => 'Label Profile: '||crec_custitemlabelprofiles.profid||
                           ' does not exist in destination database for custid: '||crec_customer.custid,
               in_msgtype  => 'W',
               in_userid   => in_userid,
               out_msg     => out_errmsg);
         end if;
      end if;

   end loop;
   close cdata;

   -- validate Facility Settings
   open cdata for 'select distinct custid, facility, allocrule, replallocrule, returnslocation'||
      ' from custfacility'||l_in_dblink||
      ' where custid = :1'
   using crec_customer.custid;
   loop
      fetch cdata into
         crec_custfacility.custid,
         crec_custfacility.facility,
         crec_custfacility.allocrule,
         crec_custfacility.replallocrule,
         crec_custfacility.returnslocation;
      exit when cdata%notfound;

      -- validate Facility Settings - Allocation Rule-
    if nvl(rtrim(crec_custfacility.allocrule),'C') != 'C' then
      execute immediate 'select count(1) from allocruleshdr'||l_in_dblink||
        ' where allocrule= :1 and facility= :2'
      into l_count
      using crec_custfacility.allocrule, crec_custfacility.facility;
      if l_count = 0  then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Allocation Rule: '||crec_custfacility.allocrule||
                  ' does not exist in destination database for custid: '||crec_customer.custid||
                  ' and facility: '||crec_custfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;

      --  validate Facility Settings - Replenishnment Rule
    if nvl(rtrim(crec_custfacility.replallocrule),'C') != 'C' then
      execute immediate 'select count(1) from allocruleshdr'||l_in_dblink||
        ' where allocrule= :1 and facility= :2'
      into l_count
      using crec_custfacility.replallocrule, crec_custfacility.facility;
      if l_count = 0  then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Replenishment Rule: '||crec_custfacility.replallocrule||
                  ' does not exist in destination database for custid: '||crec_customer.custid||
                  ' and facility: '||crec_custfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;

      --  validate Facility Settings - Putaway Profile
    if nvl(rtrim(crec_custfacility.profid),'C') != 'C' then
      execute immediate 'select count(1) from putawayprof'||l_in_dblink||
        ' where allocrule= :1 and facility= :2'
      into l_count
      using crec_custfacility.profid, crec_custfacility.facility;
      if l_count = 0  then
        zms.log_autonomous_msg(
          in_author   => AUTHOR,
          in_facility => crec_custfacility.facility,
          in_custid   => in_new_custid,
          in_msgtext  => 'Facility Settings / Putaway Rule: '||crec_custfacility.profid||
                  ' does not exist in destination database for custid: '||crec_customer.custid||
                  ' and facility: '||crec_custfacility.facility,
          in_msgtype  => 'W',
          in_userid   => in_userid,
          out_msg     => out_errmsg);
      end if;
    end if;

      --  validate Facility Settings - Wave Profile Rule
      execute immediate ' select count(1) from waveprofilehdr'||l_in_dblink||
         ' where profile= :1 and facility= :2'
      into l_count
      using crec_custfacility.profid, crec_custfacility.facility;
      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => crec_custfacility.facility,
            in_custid   => in_new_custid,
            in_msgtext  => 'Facility Settings / Wave Profile: '||crec_custfacility.profid||
                        ' does not exist in destination database for custid: '||crec_customer.custid||
                        ' and facility: '||crec_custfacility.facility,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;

      --  validate Facility Settings - Return Location
      execute immediate ' select count(1) from location'||l_in_dblink||
         ' where locid= :1 and facility= :2'
      into l_count
      using crec_custfacility.returnslocation, crec_custfacility.facility;
      if l_count = 0  then
         zms.log_autonomous_msg(
            in_author   => AUTHOR,
            in_facility => crec_custfacility.facility,
            in_custid   => in_new_custid,
            in_msgtext  => 'Facility Settings / Return location: '||crec_custfacility.returnslocation||
                        ' does not exist in destination database for custid: '||crec_customer.custid||
                        ' and facility: '||crec_custfacility.facility,
            in_msgtype  => 'W',
            in_userid   => in_userid,
            out_msg     => out_errmsg);
      end if;
   end loop;
   close cdata;

   -- Update customer table
   execute immediate 'update customer'||l_in_dblink||
   ' set defconsolidated      = :defconsolidated,'||
      ' defshiptype        = :defshiptype,'||
      ' defshipcost        = :defshipcost,'||
      ' defcarrier         = :defcarrier,'||
      ' defservicelevel    = :defservicelevel,'||
      ' returnsdisposition = null,'||
      ' prono_summary_column  = null,'||
      ' rnewlastbilled     = null,'||
      ' misclastbilled     = null,'||
      ' rcptlastbilled     = null,'||
      ' outblastbilled     = null,'||
      ' mastlastbilled     = null' ||
   ' where  custid = :custid'
   using crec_customer_tmp.defconsolidated,
      crec_customer_tmp.defshiptype,
      crec_customer_tmp.defshipcost,
      crec_customer_tmp.defcarrier,
      crec_customer_tmp.defservicelevel,
      crec_customer.custid;

exception when others then
    out_errmsg := 'validate_customer: '|| sqlerrm;
end validate_customer;

------------------------------------------------------------------------
--
-- Validate BASEUOM
--
------------------------------------------------------------------------
FUNCTION validate_uom
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN  NUMBER
IS
    l_in_dblink  varchar2(50);
    l_count number;

BEGIN
    l_in_dblink := null;
    l_count := 0;

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_code is not null then
      execute immediate 'select count(1) from unitsofmeasure'||l_in_dblink||' where code= :1'
      into l_count
      using in_code;
    end if;

    return l_count;
end validate_uom;

------------------------------------------------------------------------
--
-- Validate BILLMETHOD
--
------------------------------------------------------------------------
FUNCTION validate_billmethod
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN  NUMBER
IS
    l_in_dblink  varchar2(50);
    l_count number;

BEGIN
    l_in_dblink := null;
    l_count := 0;

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_code is not null then
      execute immediate 'select count(1) from billingmethod'||l_in_dblink||' where code= :1'
      into l_count
      using in_code;
    end if;

    return l_count;
end validate_billmethod;

------------------------------------------------------------------------
--
-- Validate BUSINESSEVENT
--
------------------------------------------------------------------------
FUNCTION validate_businessevent
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN  NUMBER
IS
    l_in_dblink  varchar2(50);
    l_count number;

BEGIN
    l_in_dblink := null;
    l_count := 0;

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_code is not null then
      execute immediate 'select count(1) from businessevents'||l_in_dblink||' where code= :1'
      into l_count
      using in_code;
    end if;

    return l_count;
end validate_businessevent;

------------------------------------------------------------------------
--
-- Validate ACTIVITY
--
------------------------------------------------------------------------
FUNCTION validate_activity
(
    in_code         IN varchar2,
    in_dblink       IN varchar2
)
RETURN  NUMBER
IS
    l_in_dblink  varchar2(50);
    l_count number;

BEGIN
    l_in_dblink := null;
    l_count := 0;

   if rtrim(in_dblink) is not null then
      l_in_dblink := '@'||in_dblink;
   end if;

   if in_code is not null then
      execute immediate 'select count(1) from activity'||l_in_dblink||' where code= :1'
      into l_count
      using in_code;
    end if;

    return l_count;
end validate_activity;

------------------------------------------------------------------------
--
-- clone_facility -
--
------------------------------------------------------------------------
PROCEDURE clone_facility
(
    in_facility                   IN varchar2,  -- facility to clone from
    in_new_facility               IN varchar2,  -- new facility to clone to
    in_dblink                     IN varchar2,  -- database link where to clone the objects
    in_copy_missing_carriers      in varchar2,
    in_carrier_prono_zone_flag    in varchar2,
    in_carrier_tender_flag        in varchar2,
    in_equipment_cost_flag        in varchar2,
    in_ship_days_flag             in varchar2,
    in_alloc_rules_flag           IN varchar2, -- flag on whether to clone allocation rules
    in_locations_flag             in varchar2,
    in_goaltime_flag              in varchar2,
    in_copy_missing_customers     in varchar2,
    in_printers_flag              in varchar2,
    in_putaway_profile_flag       in varchar2,
    in_wave_profile_flag          in varchar2,
    in_requests_flag              in varchar2,
    in_userid                     IN varchar2,
    out_msg                       OUT varchar2
)
IS
   l_in_dblink           varchar2(50);
   l_count               number;
  type t_cursor is ref cursor;

  -- for the carrier and customer loops
  c_cursor              t_cursor;
  c_cursor_2            t_cursor;
  v_sql                 varchar2(1000);
  v_carrier             carrier.carrier%type;
  v_custid              customer.custid%type;
  v_map_name            facilitycarriertender.tendermapname%type;
BEGIN
    out_msg := 'OKAY';

    -- standard parameter validations
    if rtrim(in_facility) is null then
        out_msg := 'in_facility is null';
        return;
    end if;

    if rtrim(in_new_facility) is null then
        out_msg := 'in_new_facility is null';
        return;
    end if;

    l_in_dblink := null;
    if rtrim(in_dblink) is not null then
        l_in_dblink := '@'||in_dblink;
    end if;

    -- check in_facility is valid
    select count(1)
    into l_count
    from facility
    where facility = in_facility;

    if (l_count = 0) then
        out_msg := 'Invalid ''from'' Facility:'|| in_facility;
        return;
    end if;

    /* FACILITY - ENTER THE NEW ROW IF IT DOESN'T ALREADY EXIST (NO UPDATING OF EXISTING ROWS WILL BE DONE */
    clone_table_row('FACILITY',
        'facility = ' || quote(in_facility) || ' and not exists (select 1 from facility' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ')',
        quote(in_new_facility),
        'FACILITY',
        in_dblink,
        in_userid,
        out_msg);

    if out_msg <> 'OKAY' then
        out_msg := 'facility: ' || out_msg;
        return;
    end if;

    /* COPY THE MISSING CARRIERS TO REMOTE DATABASE NEEDED FOR FACILITY CARRIER PRONO ZONE AND FACILITY CARRIER TENDER
          THIS INCLUDES THE FOLLOWING TABLES: CARRIER, CARRIERSTAGELOC, CARRIERSERVICECODES, CARRIERSPECIALSERVICE, CARRIERPRONO, CARRIERZONE
          IF WE END UP HAVING A SEPERATE CLONE CARRIER OPTION IN SYNAPSE, THIS CAN EASILY BE REFACTORED OUT INTO A SEPERATE PROCEDURE
    */
    if (in_dblink is not null and enabled(in_copy_missing_carriers) and (enabled(in_carrier_prono_zone_flag) or enabled(in_carrier_tender_flag)))
    then
        v_sql := 'select distinct a.carrier
                  from carrier a,
                    (select distinct carrier from facilitycarrierpronozone where facility = ' || quote(in_facility) || '
                     union
                     select distinct carrier from facilitycarriertender where facility = ' || quote(in_facility) || ') b
                  where a.carrier = b.carrier
                    and not exists (select 1 from carrier' || l_in_dblink || ' where carrier = a.carrier)';

        open c_cursor for v_sql;
        loop
            fetch c_cursor into v_carrier;
            exit when c_cursor%notfound;

            clone_table_row('CARRIER',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrier: ' || out_msg;
                return;
            end if;

            clone_table_row('CARRIERSTAGELOC',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrierstageloc: ' || out_msg;
                return;
            end if;

            clone_table_row('CARRIERSERVICECODES',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrierservicecodes: ' || out_msg;
                return;
            end if;

            clone_table_row('CARRIERSPECIALSERVICE',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrierspecialservice: ' || out_msg;
                return;
            end if;

            clone_table_row('CARRIERPRONO',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrierprono: ' || out_msg;
                return;
            end if;

            clone_table_row('CARRIERZONE',
                'carrier = ' || quote(v_carrier),
                quote(v_carrier),
                'CARRIER',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'carrierzone: ' || out_msg;
                return;
            end if;
        end loop;
        close c_cursor;
    end if;

    /* COPY THE MISSING CUSTOMERS TO REMOTE DATABASE NEEDED FOR GOALTIME
          TODO: TALK ABOUT THE NEED FOR THIS.  IF COPYING A FACILITY ON THE SAME DATABASE, THIS WON'T GET CALLED.  IF COPYING ON REMOTE DATABASE, PROBABLY BETTER FOR
          CUSTOMER TO GO TO CUSTOMER SETUP SCREEN, AND CLONE FROM THERE WITH WHATEVER OPTIONS THEY WANT.  THEN, THEY CAN RUN THIS AGAIN, AND GET THE GOALTIMES ADDED (ONLY SELECT GOALTIME CHECKBOX)
    */
    if (in_dblink is not null and enabled(in_copy_missing_customers) and enabled(in_goaltime_flag))
    then
        v_sql := 'select distinct a.custid
                  from goaltime a, customer b
                  where a.custid = b.custid
                    and a.facility = ' || quote(in_facility) || '
                    and not exists (select 1 from customer' || l_in_dblink || ' where custid = a.custid)';

        open c_cursor for v_sql;
        loop
            fetch c_cursor into v_custid;
            exit when c_cursor%notfound;

            -- TODO:  PUT THE CUSTOMER COPY LOGIC HERE
        end loop;
        close c_cursor;
    end if;

    /* CARRIERPRONOZONE - INSERT INTO TARGET TABLE IF FACILITY, CARRIER COMBO DOESN'T ALREADY EXIST
          CARRIER MUST EXIST ON REMOTE DATABASE IF USING A DBLINK (SEPERATE SECTION ABOVE COPIES CARRIERS)
    */
    if enabled(in_carrier_prono_zone_flag)
    then
        v_sql := 'select distinct a.carrier
                  from facilitycarrierpronozone a, carrier' || l_in_dblink || ' b
                  where a.carrier = b.carrier and facility = ' || quote(in_facility);
        open c_cursor for v_sql;
        loop
            fetch c_cursor into v_carrier;
            exit when c_cursor%notfound;

            clone_table_row('FACILITYCARRIERPRONOZONE',
                'facility = ' || quote(in_facility) || ' and carrier = ' || quote(v_carrier) ||
                  ' and not exists (select 1 from facilitycarrierpronozone' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and carrier = ' || quote(v_carrier) || ')',
                quote(in_new_facility),
                'FACILITY',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'facilitycarrierpronozone: ' || out_msg;
                return;
            end if;

        end loop;
        close c_cursor;
    end if;

    /* CARRIERTENDER - INSERT INTO THE TABLE IF THE FACILITY, CARRIER, MAPNAME COMBO DOESN'T ALREADY EXIST
          CARRIER MUST EXIST ON REMOTE DATABASE IF USING A DBLINK (SEPERATE SECTION ABOVE COPIES CARRIERS)
          ALSO, COPY OVER ANY NEW MAPS IF A REMOTE DATABASE THAT DON'T EXIST
    */
    if enabled(in_carrier_tender_flag)
    then
        v_sql := 'select distinct a.carrier
                  from facilitycarriertender a, carrier' || l_in_dblink || ' b
                  where a.carrier = b.carrier and facility = ' || quote(in_facility);
        open c_cursor for v_sql;
        loop
            fetch c_cursor into v_carrier;
            exit when c_cursor%notfound;

            clone_table_row('FACILITYCARRIERTENDER',
                'facility = ' || quote(in_facility) || ' and carrier = ' || quote(v_carrier) ||
                  ' and not exists (select 1 from facilitycarriertender' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and carrier = ' || quote(v_carrier) ||
                  '   and tendermapname = table_alias.tendermapname)',
                quote(in_new_facility),
                'FACILITY',
                in_dblink,
                in_userid,
                out_msg);

            if out_msg <> 'OKAY' then
                out_msg := 'facilitycarriertender: ' || out_msg;
                return;
            end if;

            -- IF COPYING TO ANOTHER DATABASE, COPY THE MAP OVER IF NEEDED
            if (l_in_dblink is not null)
            then
                v_sql := 'select distinct tendermapname
                          from facilitycarriertender a
                          where facility = ' || quote(in_facility) || ' and carrier = ' || quote(v_carrier) ||
                            ' and not exists (select 1 from impexp_definitions' || l_in_dblink || ' where upper(name) = upper(a.tendermapname))';

                open c_cursor_2 for v_sql;
                loop
                    fetch c_cursor_2 into v_map_name;
                    exit when c_cursor_2%notfound;

                    zclone.clone_map(v_map_name, v_map_name, in_dblink, in_userid, out_msg);

                    if out_msg <> 'OKAY' then
                        out_msg := 'equipmentcost: ' || out_msg;
                        return;
                    end if;
                end loop;
                close c_cursor_2;

            end if; -- copying the maps
        end loop; -- loop over the carriers to copy information for
        close c_cursor;
    end if;

    /* EQUIPMENTCOST - INSERT INTO THE TARGET TABLE IF THE FACILITY, EQUIPID COMBO DOESN'T ALREADY EXIST */
    if enabled(in_equipment_cost_flag)
    then
        clone_table_row('EQUIPMENTCOST',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from equipmentcost' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and equipid = table_alias.equipid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'equipmentcost: ' || out_msg;
            return;
        end if;
    end if;

    /* SHIPDAYS - INSERT INTO THE TARGET TABLE IF THE FACILITY, POSTALKEY COMBO DOESN'T ALREADY EXIST */
    if enabled(in_ship_days_flag)
    then
        clone_table_row('SHIPDAYS',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from shipdays' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and postalkey = table_alias.postalkey)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'equipmentcost: ' || out_msg;
            return;
        end if;
    end if;

    /* ALLOCRULESHDR, DTL - INSERT INTO TARGET TABLES IF THE FACILITY, ALLOCRULE COMBO DOESN'T ALREADY EXIST */
    if enabled(in_alloc_rules_flag)
    then
        -- clone allocation rules header
        clone_table_row('ALLOCRULESHDR',
        'facility = ' || quote(in_facility) ||
          ' and not exists (select 1 from allocruleshdr' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and allocrule = table_alias.allocrule)',
        quote(in_new_facility),
        'FACILITY',
        in_dblink,
        in_userid,
        out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'allocruleshdr: ' || out_msg;
            return;
        end if;

        -- clone allocation rules detail
        -- if they already have details for the allocation rule in their table already, don't mess with it
        -- to copy in that situation, the best thing to do is delete the rule altogether from the target, and then call the clone again
        -- too many situations (changed priorities, etc..) that make updating ambiguous
        clone_table_row('ALLOCRULESDTL',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from allocrulesdtl' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and allocrule = table_alias.allocrule)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'allocrulesdtl: ' || out_msg;
            return;
        end if;
    end if;

    /* COPY THE LOCATIONS, SECTIONS, AND ZONES */
    if enabled(in_locations_flag)
    then
        clone_table_row('ZONE',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from zone' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and zoneid = table_alias.zoneid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'zones: ' || out_msg;
            return;
        end if;

        clone_table_row('SECTION',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from section' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and sectionid = table_alias.sectionid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'sections: ' || out_msg;
            return;
        end if;

        clone_table_row('LOCATION',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from location' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and locid = table_alias.locid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'locations: ' || out_msg;
            return;
        end if;

        v_sql := 'begin zbm.build_map' || l_in_dblink || '( :in_new_facility, :in_userid, :out_msg); end;';
        execute immediate v_sql using in_new_facility, in_userid, in out out_msg;

        if out_msg <> 'OKAY' then
            out_msg := 'zbm.build_map: ' || out_msg;
            return;
        end if;
    end if;

    /* GOALTIME - INSERT INTO TARGET TABLE IF THE FACILITY, CUSTID, CATEGORY COMBO DOESN'T ALREADY EXIST
          IF USING A DBLINK, ONLY INSERT FOR THE CUSTOMERS THAT EXIST IN THAT DATABASE (SEPERATE SECTION ABOVE COPIES MISSING CUSTOMERS IF FLAG ENABLED)
    */
    if enabled(in_goaltime_flag)
    then
        clone_table_row('GOALTIME',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from goaltime' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and custid = table_alias.custid and category = table_alias.category)
                and exists (select 1 from customer' || l_in_dblink || ' where custid = table_alias.custid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'goaltime: ' || out_msg;
            return;
        end if;
    end if;

    /* PRINTER - INSERT INTO TARGET TABLE IF THE FACILITY, PRTID COMBO DOESN'T ALREADY EXIST */
    if enabled(in_printers_flag)
    then
        clone_table_row('PRINTER',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from printer' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and prtid = table_alias.prtid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'printers: ' || out_msg;
            return;
        end if;
    end if;

    /* PUTAWAYPROF, LINE - INSERT INTO THE TARGET TABLE IF THE FACILITY, PROFID COMBO DOESN'T ALREADY EXIST */
    if enabled(in_putaway_profile_flag)
    then
        clone_table_row('PUTAWAYPROF',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from putawayprof' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and profid = table_alias.profid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'putawayprof: ' || out_msg;
            return;
        end if;

        -- clone putaway profile lines
        -- if they already have lines for the putaway profile in their table already, don't mess with it
        -- to copy in that situation, the best thing to do is delete the profile altogether from the target, and then call the clone again
        -- too many situations (changed priorities, etc..) that make updating ambiguous
        clone_table_row('PUTAWAYPROFLINE',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from putawayprofline' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and profid = table_alias.profid)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'putawayprofline: ' || out_msg;
            return;
        end if;
    end if;

    /* WAVEPROFILEHDR, DTL - INSERT INTO TARGET TABLE IF THE FACILITY, PROFILE COMBO DOESN'T ALREADY EXIST */
    if enabled(in_wave_profile_flag)
    then
        clone_table_row('WAVEPROFILEHDR',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from waveprofilehdr' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and profile = table_alias.profile)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'waveprofilehdr: ' || out_msg;
            return;
        end if;

        -- clone wave profile details
        -- if they already have lines for the wave profile in their table already, don't mess with it
        -- to copy in that situation, the best thing to do is delete the profile altogether from the target, and then call the clone again
        -- too many situations (changed priorities, etc..) that make updating ambiguous
        clone_table_row('WAVEPROFILEDTL',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from waveprofiledtl' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and profile = table_alias.profile)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'waveprofiledtl: ' || out_msg;
            return;
        end if;
    end if;

    /* REQUESTS - INSERT INTO THE TARGET TABLE IF THE FACILITY, REQTYPE, DESCR COMBO DOESN'T ALREADY EXIST */
    if enabled(in_requests_flag)
    then
        clone_table_row('REQUESTS',
            'facility = ' || quote(in_facility) ||
              ' and not exists (select 1 from requests' || l_in_dblink || ' where facility = ' || quote(in_new_facility) || ' and reqtype = table_alias.reqtype and descr = table_alias.descr)',
            quote(in_new_facility),
            'FACILITY',
            in_dblink,
            in_userid,
            out_msg);

        if out_msg <> 'OKAY' then
            out_msg := 'requests: ' || out_msg;
            return;
        end if;
    end if;

exception
  when others then
    out_msg := 'zclone.clone_facility: ' || sqlerrm;
end clone_facility;

------------------------------------------------------------------------
--
-- clone_map -
--
------------------------------------------------------------------------
PROCEDURE clone_map
(
    in_map                        in varchar2,
    in_new_map                    in varchar2,
    in_dblink                     in varchar2,
    in_userid                     in varchar2,
    out_msg                       out varchar2
)
is
  v_dblink          varchar2(50);
  v_sql             varchar2(1000);
  v_from_inc        integer;
  v_new_inc         integer;
  v_new_line_inc    integer;
  v_count           integer;
begin

  out_msg := 'OKAY';

  v_dblink := null;
   if rtrim(in_dblink) is not null then
      v_dblink := '@'||in_dblink;
   end if;

  -- validate the map you are cloning from exists
  begin
    select definc
    into v_from_inc
    from impexp_definitions
    where upper(name) = upper(in_map);
  exception
    when others then
      out_msg := 'From format not found: ' || in_map;
      return;
  end;

  if (v_count = 0)
  then
      out_msg := 'From format not found: ' || in_map;
      return;
  end if;


  -- validate the map you are cloning to does not already exist
  v_sql := 'select count(1)
            from impexp_definitions' || v_dblink || '
            where upper(name) = upper(:in_new_map)';

  execute immediate v_sql into v_count using in_new_map;

  if (v_count > 0)
  then
      out_msg := 'To format already exists: ' || in_new_map;
      if (v_dblink is not null)
      then
          out_msg := out_msg || ' (on ' || v_dblink || ')';
      end if;
      return;
  end if;

  -- get the next available definc
  v_sql := 'select max(definc)+1
            from impexp_definitions' || v_dblink;

  execute immediate v_sql into v_new_inc;

  -- delete from other impexp tables for this definc (data shouldn't exist anyways, but make sure)
  v_sql := 'delete from impexp_afterprocessprocparams' || v_dblink || ' where definc = :newinc';
  execute immediate v_sql using v_new_inc;

  v_sql := 'delete from impexp_chunks' || v_dblink || ' where definc = :newinc';
  execute immediate v_sql using v_new_inc;

  v_sql := 'delete from impexp_lines' || v_dblink || ' where definc = :newinc';
  execute immediate v_sql using v_new_inc;

  -- copy the impexp_definition
  clone_table_row('IMPEXP_DEFINITIONS',
      'definc = ' || v_from_inc,
      v_new_inc || ',' || quote(in_new_map),
      'DEFINC,NAME',
      in_dblink,
      in_userid,
      out_msg);

  if out_msg <> 'OKAY' then
      out_msg := 'impexp_definitions: ' || out_msg;
      return;
  end if;

  -- copy the impexp_lines
  clone_table_row('IMPEXP_LINES',
      'definc = ' || v_from_inc,
      v_new_inc,
      'DEFINC',
      in_dblink,
      in_userid,
      out_msg);

  if out_msg <> 'OKAY' then
      out_msg := 'impexp_lines: ' || out_msg;
      return;
  end if;

  -- copy the impexp_afterprocessprocparams
  clone_table_row('IMPEXP_AFTERPROCESSPROCPARAMS',
      'definc = ' || v_from_inc,
      v_new_inc,
      'DEFINC',
      in_dblink,
      in_userid,
      out_msg);

  if out_msg <> 'OKAY' then
      out_msg := 'impexp_afterprocessprocparams: ' || out_msg;
      return;
  end if;

  -- copy the impexp_afterprocessprocparams
  clone_table_row('IMPEXP_CHUNKS',
      'definc = ' || v_from_inc,
      v_new_inc,
      'DEFINC',
      in_dblink,
      in_userid,
      out_msg);

  if out_msg <> 'OKAY' then
      out_msg := 'impexp_chunks: ' || out_msg;
      return;
  end if;

exception
  when others then
    out_msg := 'zclone.clone_map: ' || sqlerrm;
end clone_map;

------------------------------------------------------------------------
--
-- quote -
--
------------------------------------------------------------------------
function quote (in_string in varchar2) return varchar2
is
begin
    return '''' || in_string || '''';
end quote;

------------------------------------------------------------------------
--
-- enabled -
--
------------------------------------------------------------------------
function enabled (in_string in varchar2) return boolean
is
begin
    return nvl(upper(in_string),'N') = 'Y';
end enabled;

------------------------------------------------------------------------
--
-- validate_item -
--
------------------------------------------------------------------------
PROCEDURE validate_item
(
    in_custid       IN varchar2,
    in_new_custid   IN varchar2,
    in_dblink       IN varchar2,
    in_userid       IN varchar2,
    out_errmsg      OUT varchar2
)
IS

begin

 -- validate Item alias
  for crec in (select item, count(1)
                 from custitemalias
                where custid = in_custid
                  and aliasdesc like 'UPC%'
             group by item
             having count(1) > 1)            
  loop
      zms.log_autonomous_msg(
      in_author   => AUTHOR,
      in_facility => null,
      in_custid   => in_new_custid,
      in_msgtext  => 'custitemalias: Only one alias can be designated as a UPC code - Item: '||crec.item,
      in_msgtype  => 'W',
      in_userid   => in_userid,
      out_msg    => out_errmsg);
  end loop;

exception when others then
    out_errmsg := 'validate_item: '|| sqlerrm;
end validate_item;

END zclone;
/

show errors package body zclone;
exit;
