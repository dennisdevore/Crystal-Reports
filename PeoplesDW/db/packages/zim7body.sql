create or replace package body alps.zimportproc7 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';
last_orderid    orderhdr.orderid%type;

----------------------------------------------------------------------
-- begin_lawson
----------------------------------------------------------------------
function pallet_count
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_type IN varchar2 default null
) return integer

is

out_pallet_count integer;

begin

out_pallet_count := 0;




if nvl(in_type, 'a') = 'R' then
   if nvl(in_orderid,0) <> 0 then
     select sum(nvl(inpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility;
   else
     select sum(nvl(inpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and orderid = in_orderid
        and shipid = in_shipid;
   end if;
else
   if nvl(in_orderid,0) <> 0 then
     select sum(nvl(outpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility;
   else
     select sum(nvl(outpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and orderid = in_orderid
        and shipid = in_shipid;
   end if;
end if;

return nvl(out_pallet_count,0);

exception when others then
  return 0;
end;

function pallet_count_by_type
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_type IN varchar2 default null
,in_pallettype IN varchar2
) return integer
is
out_pallet_count integer;

begin
out_pallet_count := 0;

if nvl(in_type, 'a') = 'R' then
   if nvl(in_orderid,0) <> 0 then
     select sum(nvl(inpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and nvl(pallettype,'none') = nvl(in_pallettype,'none');
   else
     select sum(nvl(inpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and orderid = in_orderid
        and shipid = in_shipid
        and nvl(pallettype,'none') = nvl(in_pallettype,'none');
   end if;
else
   if nvl(in_orderid,0) <> 0 then
     select sum(nvl(outpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and nvl(pallettype,'none') = nvl(in_pallettype,'none');
   else
     select sum(nvl(outpallets,0))
       into out_pallet_count
       from pallethistory
      where loadno = in_loadno
        and custid = in_custid
        and facility = in_facility
        and orderid = in_orderid
        and shipid = in_shipid
        and nvl(pallettype,'none') = nvl(in_pallettype,'none');
   end if;
end if;

return nvl(out_pallet_count,0);

exception when others then
  return 0;
end;

function order_pallet_count_by_type
(in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_pallettype IN varchar2
) return integer
is
out_pallet_count integer;
begin
   select sum(nvl(outpallets,0)) into out_pallet_count
    from pallethistory
    where custid = in_custid
     and facility = in_facility
     and orderid = in_orderid
     and shipid = in_shipid
     and nvl(pallettype,'none') = nvl(in_pallettype,'none');
return nvl(out_pallet_count,0);
exception when others then
  return 0;
end;
function order_pallet_count_by_list
(in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_pallettypes IN varchar2
) return integer
is
out_pallet_count integer;
len integer;
tpos integer;
tcur integer;
tcnt integer;
pType pallethistory.pallettype%type;
begin
   tcur := 1;
   tcnt := 0;
   out_pallet_count := 0;
   while tcur < len loop
      tpos := instr(in_pallettypes, ',', tcur);
      if tpos = 0 then
         pType := substr(in_pallettypes, tcur, len - tcur +1);
         tcur := len;
      else
         pType := substr(in_pallettypes, tcur, tpos - tcur);
         tcur := tpos + 1;
      end if;
      out_pallet_count := out_pallet_count +
                          zim7.order_pallet_count_by_type(in_custid, in_facility,
                                                          in_orderid, in_shipid, pType);
   end loop;
return nvl(out_pallet_count,0);
end order_pallet_count_by_list;
procedure begin_lawson
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_beginvoice IN number
,in_endinvoice IN number
,in_use_date_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

  CURSOR C_PH(in_begin char, in_end char)
  IS
    SELECT *
      FROM posthdr
     WHERE postdate >= to_date(in_begin, 'YYYYMMDDHH24MISS')
       AND postdate < to_date(in_end, 'YYYYMMDDHH24MISS');
  cph C_PH%rowtype;

  CURSOR C_INVOICE(in_master char)
  RETURN invoicehdr%rowtype
  IS
    SELECT *
      FROM invoicehdr
     WHERE masterinvoice = in_master
     ORDER BY invtype, invoice;

  CURSOR C_FACILITY(in_facility char)
  RETURN facility%rowtype
  IS
    SELECT *
      FROM facility
     WHERE facility = in_facility;

  masterinvoice varchar2(8);
  IH invoicehdr%rowtype;
  FA facility%rowtype;
  l_prefix    varchar2(2);

  CURSOR C_INVD(in_invoice number)
  IS
    SELECT D.activity, D.billedqty, D.billedamt, D.billedrate,
           D.item, D.lotnumber, nvl(D.calcedUOM, D.entereduom) uom,
           D.calceduom, D.orderid, D.shipid, nvl(D.minimum,0) minimumord,
           A.descr actdescr, A.glacct, I.descr itemdescr, D.comment1,
           H.reference, H.po
      FROM orderhdr H, custitem I, activity A, invoicedtl D
     WHERE D.invoice = in_invoice
       AND D.custid = I.custid(+)
       AND D.item = I.item(+)
       AND D.activity = A.code(+)
       AND D.orderid = H.orderid(+)
       AND D.shipid = H.shipid(+)
       AND D.billstatus != '4'
      ORDER BY D.item, D.orderid, D.lotnumber, D.activity, nvl(D.minimum,0);

  CURSOR C_DFT(in_id char)
  IS
    SELECT substr(defaultvalue,1,5)
      FROM systemdefaults
     WHERE defaultid = in_id;

l_araccount varchar2(5);

linenum integer;
l_seq integer;
cmt varchar2(4001);
str varchar2(80);

len integer;
tpos integer;
tcur integer;
tcnt integer;

errmsg varchar2(100);
mark varchar2(20);

begin

mark := 'Start';

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'LAWSON_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

if in_custid != 'ALL' then
    out_errorno := -1;
    out_msg := 'Invalid Customer Code';
    return;
end if;

    l_araccount := '';

    OPEN C_DFT('ARACCOUNT');
    FETCH C_DFT into l_araccount;
    CLOSE C_DFT;

    OPEN C_PH(in_begdatestr, in_enddatestr);
    loop
       fetch C_PH into cph;
       exit when C_PH%notfound;
        mark := 'C_PH';

        masterinvoice := substr(to_char(cph.invoice,'09999999'),2);

        IH := null;

        OPEN C_INVOICE(masterinvoice);
        FETCH C_INVOICE into IH;
        CLOSE C_INVOICE;

        OPEN C_FACILITY(IH.facility);
                  FETCH C_FACILITY into FA;
        CLOSE C_FACILITY;

        mark := 'C_INVOICE';

        if cph.amount < 0 then
           l_prefix := 'CM';
        else
           l_prefix := 'IN';
        end if;

        mark := 'BF INS HDR';

        insert into lawsonhdrex
        (
            sessionid,
            postdate,
            prefix,
            invoice,
            facility,
            custid,
            invoicedate,
                                glid
        )
        values
        (
            strSuffix,
            cph.postdate,
            l_prefix,
            cph.invoice,
            IH.facility,
            cph.custid,
            cph.invdate,
                                FA.glid
        );
   -- cursor loop for invoicehdr to place in proper order if multiples
       linenum := 0;

        mark := 'BF C_INVOICE LOOP';
       for cih in C_INVOICE(masterinvoice) loop
           -- zut.prt('  Invoice: '||cih.invoice||' Type:'||cih.invtype);
   -- cursor loop for invoicedtl in the proper sort order !!!!
           mark := 'BF C_INVD';
           for cid in C_INVD(cih.invoice) loop
              linenum := linenum + 1;
              -- zut.prt('      Itm:'||cid.item||'/'||cid.lotnumber
              --     ||' Act:'||cid.activity
              --     ||'/'||cid.actdescr||' - '||cid.itemdescr);
              mark := 'BF INS DTL';

              insert into lawsondtlex
              (
                  sessionid,
                  prefix,
                  invoice,
                  linenumber,
                  facility,
                  item,
                  lotnumber,
                  descr,
                  quantity,
                  price,
                  amount,
                  uom,
                  glaccount,
                  araccount,
                  orderid,
                  activity,
                  activitydesc,
                  reference,
                  po
              )
              values
              (
                  strSuffix,
                  l_prefix,
                  cph.invoice,
                  linenum,
                  IH.facility,
                  cid.item,
                  cid.lotnumber,
                  substr(cid.itemdescr,1,32),
                  cid.billedqty,
                  decode(cih.invtype,'C',-cid.billedrate,cid.billedrate),
                  decode(cih.invtype,'C',-cid.billedamt,cid.billedamt),
                  cid.uom,
                  substr(cid.glacct,1,5),
                  l_araccount,
                  cid.orderid,
                  cid.activity,
                  cid.actdescr,
                  cid.reference,
                  cid.po
              );

   -- insert into lawsondtlex, lawsoncmtex
              mark := 'BF Com';

              if cid.comment1 is not null then
                 l_seq := 0;
                 cmt := substr(cid.comment1,1,4000);
                 len := length(cmt);
                 tcur := 1;
                 while tcur < len loop
                     l_seq := l_seq + 1;
                     tpos := instr(cmt, chr(10), tcur);
                     if tpos = 0 then
                        tpos := len + 2;
                     end if;
                     tcnt := tpos - tcur - 1;
                     -- zut.prt(' tcur:'||tcur||' tpos:'||tpos||' tcnt:'||tcnt);

                     if tcnt > 0 then
                        str := substr(cmt,tcur, least(80,tcnt));
                     else
                        str := ' ';
                     end if;
                     tcur := tpos + 1;
                     insert into lawsoncmtex
                     (
                        sessionid,
                        prefix,
                        invoice,
                        linenumber,
                        sequence,
                        comment1
                     )
                     values
                     (
                        strSuffix,
                        l_prefix,
                        cph.invoice,
                        linenum,
                        l_seq,
                        str
                     );

                     -- zut.prt('   '||str);
                 end loop;

              end if;
           end loop;
       end loop;
    end loop;

cmdSql := 'create view lawson_hdr_' || strSuffix ||
 ' (postdate, prefix, invoice, facility, custid,invoicedate,glid) ' ||
 'as select to_char(postdate,''YYYYMMDD''), prefix, invoice, facility, '||
 ' custid, to_char(invoicedate,''YYYYMMDD''), glid ' ||
 ' from lawsonhdrex ' ||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



-- Create views also for
--        lawson_dtl_
cmdSql := 'create view lawson_dtl_' || strSuffix ||
 ' (prefix, invoice, linenumber, facility, item, descr, ' ||
 'quantity, price, uom, glaccount, araccount) ' ||
 'as select prefix, invoice, linenumber, facility, ' ||
 'nvl(item,''ACT''||activity), descr, '||
 'substr(to_char(quantity*10000,''09999999999999999''),2), '||
 'decode(sign(price),'||
 '  -1,to_char(price*100000,  ''09999999999999999''), ' ||
 ' substr(to_char(price*100000,  ''099999999999999999''),2)), ' ||
 'uom, glaccount, araccount' ||
 ' from lawsondtlex ' ||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

--        lawson_dtlex_
cmdSql := 'create view lawson_dtlex_' || strSuffix ||
 ' (prefix, invoice, linenumber, orderid,activity,activitydesc,reference,po) ' ||
 'as select prefix, invoice, linenumber, orderid, activity,' ||
 'activitydesc,reference,po ' ||
 ' from lawsondtlex ' ||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

--        lawson_cmt_
cmdSql := 'create view lawson_cmt_' || strSuffix ||
 ' (prefix, invoice, linenumber, sequence, comment1) ' ||
 'as select prefix, invoice, linenumber, sequence, comment1 ' ||
 ' from lawsoncmtex ' ||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbir '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_lawson;

----------------------------------------------------------------------
-- end_lawson
----------------------------------------------------------------------
procedure end_lawson
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from lawsonhdrex where sessionid = strSuffix;
delete from lawsondtlex where sessionid = strSuffix;
delete from lawsoncmtex where sessionid = strSuffix;

cmdSql := 'drop VIEW lawson_cmt_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW lawson_dtlex_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW lawson_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW lawson_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeir ' || sqlerrm;
  out_errorno := sqlcode;
end end_lawson;

----------------------------------------------------------------------
-- import_order_hdr_notes
----------------------------------------------------------------------
procedure import_order_hdr_notes
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,in_abc_revision IN varchar2
,in_ordertype IN varchar2
,in_comment_type IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
IS
cursor curCustomer is
  select nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor C_ORDERHDR_TYPE (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(in_ordertype)
   order by orderstatus;

cursor C_ORDERHDR_HOLD (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(in_ordertype)
   order by orderid desc, shipid desc;

cursor C_ORDERHDR (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh C_ORDERHDR%rowtype;

cursor C_ORDERHDRBOL (in_orderid number, in_shipid number) is
  select orderid,
         shipid,
         bolcomment
    from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
ohb C_ORDERHDRBOL%rowtype;

cr varchar2(2);
strReference orderhdr.reference%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin
    out_errorno := 0;
    out_msg := 'OKAY';
    out_orderid := 0;
    out_shipid := 0;

    if in_abc_revision is not null then
       strReference := in_reference || in_abc_revision;
    else
       strReference := in_reference;
    end if;


    if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
       out_errorno := 1;
       out_msg := 'Invalid Function Code';
       order_msg('E');
       return;
    end if;

    open curCustomer;
    fetch curCustomer into cs;
    if curCustomer%notfound then
      cs.dup_reference_ynw := 'N';
    end if;
    close curCustomer;

    if cs.dup_reference_ynw = 'O' then
       if in_ordertype is null then
          out_errorno := 1;
          out_msg := 'IOHN Order Type Required for Dup Ord Order Type';
          order_msg('E');
          return;
       end if;
       open C_ORDERHDR_TYPE(strReference);
       fetch C_ORDERHDR_TYPE into oh;
       if C_ORDERHDR_TYPE%FOUND then
          out_orderid := oh.orderid;
          out_shipid := oh.shipid;
       end if;
       close C_ORDERHDR_TYPE;
    else
       if cs.dup_reference_ynw = 'H' then
          open C_ORDERHDR_HOLD(strReference);
          fetch C_ORDERHDR_HOLD into oh;
          if C_ORDERHDR_HOLD%FOUND then
             out_orderid := oh.orderid;
             out_shipid := oh.shipid;
          end if;
          close C_ORDERHDR_HOLD;
       else
          open C_ORDERHDR(strReference);
          fetch C_ORDERHDR into oh;
          if C_ORDERHDR%FOUND then
             out_orderid := oh.orderid;
             out_shipid := oh.shipid;
          end if;
          close C_ORDERHDR;
       end if;
    end if;

    if out_orderid = 0 then
       out_errorno := 3;
       out_msg := 'Cannot import instructions--order not found';
       order_msg('E');
       return;
    end if;


    if out_orderid != 0 then
      if oh.orderstatus > '1' then
         out_errorno := 2;
         out_msg := 'Invalid Order Header Status (notes):' || oh.orderstatus ;
         order_msg('E');
         last_orderid := out_orderid;
         return;
      end if;
    end if;


    if rtrim(nvl(in_comment_type,'NONE')) = 'NONE' then
       if rtrim(in_func) in ('A','U','R') then
          if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
             oh.comment1 := null;
             last_orderid := out_orderid;
          end if;
          if oh.comment1 is not null then
             cr := chr(13) || chr(10);
          else
             cr := null;
          end if;
          oh.comment1 := oh.comment1 || cr
                         || rtrim(in_qualifier)||'-'||rtrim(in_note);
          update orderhdr
             set comment1 = oh.comment1,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set comment1 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    elsif rtrim(in_comment_type) in ('ORI','WHI') then
       if rtrim(in_func) in ('A','U','R') then
          if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
             oh.comment1 := null;
             last_orderid := out_orderid;
          end if;
          if oh.comment1 is not null then
             cr := chr(13) || chr(10);
          else
             cr := null;
          end if;

          oh.comment1 := oh.comment1 || cr
                         || rtrim(in_note);
          update orderhdr
             set comment1 = oh.comment1,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set comment1 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    elsif rtrim(in_comment_type) in ('DEL','BOL') then
       open C_ORDERHDRBOL(oh.orderid, oh.shipid);
       fetch C_ORDERHDRBOL into ohb;
       close C_ORDERHDRBOL;

       if rtrim(in_func) in ('A','U','R') then
          if ohb.orderid is not null then
             if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
                ohb.bolcomment := null;
                last_orderid := out_orderid;
             end if;
             if ohb.bolcomment is not null then
                cr := chr(13) || chr(10);
             else
                cr := null;
             end if;

             ohb.bolcomment := ohb.bolcomment || cr
                            || rtrim(in_note);
             update orderhdrbolcomments
                set bolcomment = ohb.bolcomment,
                    lastuser = IMP_USERID,
                    lastupdate = sysdate
              where orderid = oh.orderid
                and shipid = oh.shipid;
          else
             insert into orderhdrbolcomments
             (orderid, shipid, bolcomment, lastuser, lastupdate)
             values
             (oh.orderid, oh.shipid, in_note, IMP_USERID, sysdate);
          end if;
       elsif rtrim(in_func) = 'D' then
          delete
            from orderhdrbolcomments
           where orderid = oh.orderid
             and shipid = oh.shipid;
       end if;
    elsif rtrim(in_comment_type) in ('OTH') then
       if rtrim(in_func) in ('A','U','R') then
          update orderhdr
             set hdrpassthruchar56 = in_note,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set hdrpassthruchar56 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    end if;


    last_orderid := out_orderid;

exception when others then
  out_msg := 'zimohn ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_hdr_notes;

procedure begin_stockstat846
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_17_is_available_only_yn IN varchar2
,in_short_names IN varchar2
,in_include_lotnumber IN VARCHAR2
,in_invstatus IN VARCHAR2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_exclude_crossdock IN VARCHAR2
,in_av_status_only_yn IN VARCHAR2
,in_include_lip_details_yn IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

mark varchar2(20);

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
ddltitle varchar2(16);
l_invstatus varchar2(100);
l_17_AV varchar2(20);

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin
/*
if strDebugYN <> 'Y' then
  return;
end if;
*/
cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

procedure update_qty_av_to_allocable
is
l_cmd VARCHAR2(2000);
l_facility custitemtot.facility%type;
l_custid custitemtot.custid%type;
l_item custitemtot.item%type;
l_lotnumber custitemtot.lotnumber%type;
l_qty custitemtot.qty%type;
l_qty_allocable custitemtot.qty%type;
l_qty_av custitemtot.qty%type;
l_qty_cm custitemtot.qty%type;

TYPE cur_type is REF CURSOR;
l_cur cur_type;

begin

l_cmd := 'select facility,custid,item,link_lotnumber,quantity from ' ||
          ddltitle || '_qty_' || strSuffix;
debugmsg(l_cmd);
open l_cur for l_cmd;
loop
  fetch l_cur into l_facility, l_custid, l_item, l_lotnumber, l_qty;
  exit when l_cur%notfound;
  if nvl(in_include_lotnumber,'N') = 'Y' then
    begin
      select nvl(sum(qty),0)
        into l_qty_av
        from custitemtot
         where facility = l_facility
         and custid = l_custid
         and item = l_item
         and invstatus = 'AV'
         and status in ('A','M')
         and lotnumber = l_lotnumber;
    exception when others then
      l_qty_av := 0;
    end;
    begin
      select nvl(sum(qty),0)
        into l_qty_cm
        from custitemtot
         where facility = l_facility
         and custid = l_custid
         and item = l_item
         and invstatus = 'AV'
         and status = 'CM'
         and lotnumber = l_lotnumber;
    exception when others then
      l_qty_cm := 0;
    end;
  else
    begin
      select nvl(sum(qty),0)
        into l_qty_av
        from custitemtot
       where facility = l_facility
         and custid = l_custid
         and item = l_item
         and invstatus = 'AV'
         and status in ('A','M');
    exception when others then
      l_qty_av := 0;
    end;
    begin
      select nvl(sum(qty),0)
        into l_qty_cm
        from custitemtot
       where facility = l_facility
         and custid = l_custid
         and item = l_item
         and invstatus = 'AV'
         and status = 'CM';
    exception when others then
      l_qty_cm := 0;
    end;
  end if;
  l_qty_allocable := l_qty_av - l_qty_cm;
  if l_qty_allocable < 0 then
    l_qty_allocable := 0;
  end if;
  debugmsg(l_item || ' qty ' || l_qty || ' alloc ' || l_qty_allocable || ' av ' ||
           l_qty_av || ' cm ' || l_qty_cm);
  if l_qty_allocable != l_qty then
    if l_qty_allocable = 0 and
      nvl( in_exclude_zero, 'N') = 'Y' then
      l_cmd := 'delete from ' || ddltitle || '_qty_' ||strSuffix
           || ' where facility = '''||l_facility||''' and custid = '''||l_custid
           || ''' and item = '''||l_item||''' and link_lotnumber = ''' ||l_lotnumber||'''';
   else
      l_cmd  := 'update ' || ddltitle || '_qty_' ||strSuffix
             || ' set quantity = ' || l_qty_allocable
             || ' where facility = '''||l_facility||''' and custid = '''||l_custid
             || ''' and item = '''||l_item||''' and link_lotnumber = '''
             ||l_lotnumber||'''';
   end if;
   debugmsg(l_cmd);
   execute immediate l_cmd;
  end if;
end loop;

l_cmd := 'delete from ' || ddltitle || '_dtl_' || strSuffix || ' dtl ' ||
' where not exists (select 1 from ' ||
ddltitle || '_qty_' || strSuffix || ' qty ' ||
' where qty.facility = dtl.facility and ' ||
' qty.custid = dtl.custid and ' ||
' qty.item = dtl.item and ' ||
' qty.link_lotnumber = dtl.link_lotnumber) ';
debugmsg(l_cmd);
execute immediate l_cmd;

end;

PROCEDURE remove_item(in_fac varchar2, in_custid varchar2, in_item varchar2,
    in_lot varchar2, in_qty number)
IS
cFunc INTEGER;
cRows INTEGER;
cSql VARCHAR2(2000);

BEGIN
  cSql := 'update ' || ddltitle || '_qty_' ||strSuffix
        || ' set quantity = quantity - '|| in_qty
        || ' where facility = '''||in_fac||''' and custid = '''||in_custid
        || ''' and item = '''||in_item||''' and link_lotnumber = '''
        || nvl(in_lot,'(none)')||'''';

  cFunc := dbms_sql.open_cursor;
  dbms_sql.parse(cFunc, cSql, dbms_sql.native);
  cRows := dbms_sql.EXECUTE(cFunc);
  dbms_sql.close_cursor(cFunc);

END;

procedure remove_item_status(in_fac varchar2, in_custid varchar2, in_item varchar2,
    in_lot varchar2, in_invstatus varchar2, in_qty number)
is
cfunc integer;
crows integer;
csql varchar2(2000);
cstat varchar2(10);
begin
  select decode(nvl(in_invstatus,'AV'), 'DM','74','AV','17','RW','66','QH') into cstat from dual;

  cSql := 'update ' || ddltitle || '_qty_' ||strSuffix
        || ' set quantity = quantity - '|| in_qty
        || ' where facility = '''||in_fac||''' and custid = '''||in_custid
        || ''' and item = '''||in_item||''' and link_lotnumber = ''' || nvl(in_lot,'(none)')||''''
        || ' and activity = ''' || cstat ||'''';
  --debugmsg(cSql);
  cFunc := dbms_sql.open_cursor;
  dbms_sql.parse(cFunc, cSql, dbms_sql.native);
  cRows := dbms_sql.EXECUTE(cFunc);
  dbms_sql.close_cursor(cFunc);
  if nvl(in_17_is_available_only_yn,'N') != 'Y' and
     cstat != '17' then
     cSql := 'update ' || ddltitle || '_qty_' ||strSuffix
           || ' set quantity = quantity - '|| in_qty
           || ' where facility = '''||in_fac||''' and custid = '''||in_custid
           || ''' and item = '''||in_item||''' and link_lotnumber = ''' || nvl(in_lot,'(none)')||''''
           || ' and activity = ''17''';
     --debugmsg(cSql);
     cFunc := dbms_sql.open_cursor;
     dbms_sql.parse(cFunc, cSql, dbms_sql.native);
     cRows := dbms_sql.EXECUTE(cFunc);
     dbms_sql.close_cursor(cFunc);
     cSql := 'delete from ' || ddltitle || '_qty_' ||strSuffix
           || ' where facility = '''||in_fac||''' and custid = '''||in_custid
           || ''' and item = '''||in_item||''' and link_lotnumber = ''' || nvl(in_lot,'(none)')||''''
           || ' and activity = ''' || cstat ||''' and quantity <= 0';
     cFunc := dbms_sql.open_cursor;
     dbms_sql.parse(cFunc, cSql, dbms_sql.native);
     cRows := dbms_sql.EXECUTE(cFunc);
     dbms_sql.close_cursor(cFunc);

  end if;
end remove_item_status;

begin

out_errorno := 0;
out_msg := '';
mark := 'Start';

if nvl(in_short_names, 'N') != 'Y' then
   ddltitle := 'STOCK_STATUS_846';
else
   ddltitle := 'STKSTAT846';
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = ddltitle || '_HDR_' || strSuffix;

  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

mark := 'Cust Chk';
select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

mark := 'hdr table create';
cmdSql := 'create table ' || ddltitle || '_hdr_' || strSuffix  ||
' (FACILITY VARCHAR2(3) not null ' ||
',CUSTID VARCHAR2(10) not null ' ||
',FACILITY_NAME VARCHAR2(40) ' ||
',FACILITY_ADDR1 VARCHAR2(40) ' ||
',FACILITY_ADDR2 VARCHAR2(40) ' ||
',FACILITY_CITY VARCHAR2(30) ' ||
',FACILITY_STATE VARCHAR2(5) ' ||
',FACILITY_POSTALCODE VARCHAR2(12) ' ||
',FACILITY_COUNTRYCODE VARCHAR2(3) ' ||
',FACILITY_PHONE VARCHAR2(25) ' ||
',CUSTOMER_NAME VARCHAR2(40) not null ' ||
',CUSTOMER_ADDR1 VARCHAR2(40) ' ||
',CUSTOMER_ADDR2 VARCHAR2(40) ' ||
',CUSTOMER_CITY VARCHAR2(30) ' ||
',CUSTOMER_STATE VARCHAR2(5) ' ||
',CUSTOMER_POSTALCODE VARCHAR2(12) ' ||
',CUSTOMER_COUNTRYCODE VARCHAR2(3) ' ||
',CUSTOMER_PHONE VARCHAR2(25) ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'hdr table populate';
cmdSql := 'insert into '|| ddltitle || '_hdr_' || strSuffix ||
 ' select distinct ' ||
 'I.facility,I.custid,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode,' ||
 'F.countrycode,F.phone,C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 'C.countrycode,C.phone '||
 ' from facility F, customer C, custitemtot I ' ||
 ' where I.custid = ''' || rtrim(in_custid) || '''' ||
 ' and I.custid = C.custid ' ||
 ' and I.facility = F.facility(+) ' ||
 ' and I.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 ' and I.status not in (''D'',''P'',''U'',''CM'') ';

--debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'dtl table create';
cmdSql := 'create table ' || ddltitle || '_dtl_' || strSuffix  ||
' (FACILITY VARCHAR2(3) not null ' ||
',CUSTID VARCHAR2(10) not null ' ||
',item varchar2(50) not null ' ||
',LOTNUMBER VARCHAR2(30) ' ||
',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
',UPC VARCHAR2(20) ' ||
',DESCR VARCHAR2(255) not null ' ||
',BASEUOM VARCHAR2(4) ' ||
',ITMPASSTHRUCHAR01 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR02 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR03 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR04 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR05 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR06 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR07 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR08 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR09 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR10 VARCHAR2(255) ' ||
',ITMPASSTHRUNUM01   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM02   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM03   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM04   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM05   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM06   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM07   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM08   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM09   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM10   NUMBER(16,4) ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'dtl table populate';
if nvl(in_include_lotnumber, 'N') != 'Y' then
cmdSql := 'insert into '|| ddltitle || '_dtl_' || strSuffix ||
 ' select distinct S.facility,CI.custid,CI.item,null,''(none)'',' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitemtot T, custitem CI, custitemupcview U, ' ||
   ddltitle ||'_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and S.facility = T.facility ' ||
 '  and CI.custid = T.custid ' ||
 '  and CI.item = T.item ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ';
else
cmdSql := 'insert into '|| ddltitle || '_dtl_' || strSuffix ||
 ' select distinct S.facility,CI.custid,CI.item,' ||
 ' decode(T.lotnumber, ''(none)'',null, T.lotnumber), '||
 ' nvl(T.lotnumber,''(none)''), ' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitemtot T, custitem CI, custitemupcview U, ' ||
   ddltitle ||'_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 '  and S.facility = T.facility ' ||
 '  and S.custid = T.custid '||
 '  and CI.item = T.item ';
if nvl( in_exclude_zero, 'N') != 'Y' then
cmdSql := cmdSql ||
 ' union ' ||
 ' select distinct S.facility,CI.custid,CI.item,' ||
 ' null, '||
 ' ''(none)'', ' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitem CI, custitemupcview U, ' ||
   ddltitle ||'_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 '  and not exists (select item from custitemtot T ' ||
 '   where T.facility = S.facility ' ||
 '     and T.custid = CI.custid ' ||
 '     and T.item = CI.item)';
else
cmdSql := cmdSql ||
 '  and T.status not in (''D'',''P'',''U'',''CM'') ';
end if;
end if;

curFunc := dbms_sql.open_cursor;

dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'qty table create';
cmdSql := 'create table ' || ddltitle || '_qty_' || strSuffix  ||
' (FACILITY VARCHAR2(3) ' ||
',CUSTID VARCHAR2(10) ' ||
',item varchar2(50) ' ||
',LOTNUMBER VARCHAR2(30) ' ||
',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
',ACTIVITY VARCHAR2(2) ' ||
',UOM VARCHAR2(4) ' ||
',QUANTITY NUMBER ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'qty table populate';
if nvl(in_invstatus, 'N') = 'Y' then
  l_invstatus := ' I.invstatus,';
  l_17_AV := '''AV'',';
else
  l_invstatus :=  ' decode(nvl(I.invstatus,''AV''), ''DM'',''74'',''AV'',''02'',''RW'',''66'',''QH''),';
  l_17_AV := '''17'',';
end if;

if nvl(in_include_lotnumber, 'N') != 'Y' then
  cmdSql := 'insert into '|| ddltitle || '_qty_' || strSuffix || ' ';
  if nvl(in_av_status_only_yn, 'N') = 'N' then
      cmdSql := cmdSql ||
   ' select S.facility,S.custid,S.item, null, ''(none)'',' ||
    l_invstatus ||
    ' nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, ' || ddltitle ||'_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility '||
    '  and S.custid = I.custid '||
    '  and S.item = I.item '||
    '  and I.status not in (''D'',''P'',''U'',''CM'') ' ||
    '  and I.invstatus != ''AV'''||
    ' group by S.facility,S.custid,S.item, null, ''(none)'',' ||
    l_invstatus ||
    ' nvl(I.uom,S.baseuom) ' ||
    'union ';
 end if;
   cmdSql := cmdSql ||
    ' select S.facility,S.custid,S.item,null,''(none)'', ' ||
    l_17_AV ||
    ' nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, '|| ddltitle ||'_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility(+)'||
    '  and S.custid = I.custid(+) '||
    '  and S.item = I.item(+) ' ||
    ' and I.status(+) not in (''D'',''P'',''U'',''CM'') ';
   IF NVL(in_17_is_available_only_yn,'N') = 'Y'
   or nvl(in_invstatus, 'N') = 'Y'
   THEN
     cmdSql := cmdSql ||  '  and I.invstatus = ''AV'' ';
   END IF;
   cmdSql := cmdSql ||
    ' group by S.facility,S.custid,S.item,null,''(none)'', ' ||
   -- '  ''17'','||
    l_17_AV ||
    ' nvl(I.uom,S.baseuom) ';

else
  cmdSql := 'insert into '|| ddltitle || '_qty_' || strSuffix || ' ';
  if nvl(in_av_status_only_yn, 'N') = 'N' then
    cmdSql := cmdSql ||
   ' select S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
   -- ' decode(nvl(I.invstatus,''AV''), ''DM'',''74'',''AV'',''02'',''RW'',''66'',''QH''),'||
    l_invstatus ||
    ' nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, ' || ddltitle ||'_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility '||
    '  and S.custid = I.custid '||
    '  and S.item = I.item '||
    '  and nvl(S.lotnumber, ''(none)'') = nvl(I.lotnumber, ''(none)'') ' ||
    '  and I.status not in (''D'',''P'',''U'',''CM'') ' ||
    '  and I.invstatus != ''AV'''||
    ' group by S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
   -- '  decode(nvl(I.invstatus,''AV''), ''DM'',''74'',''AV'',''02'',''RW'',''66'',''QH''),'||
    l_invstatus ||
    ' nvl(I.uom,S.baseuom) ' ||
    'union ';
   end if;
   cmdSql := cmdSql ||
    ' select S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
   -- ' ''17'','||
    l_17_AV ||
    ' nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, '|| ddltitle ||'_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility(+)'||
    '  and S.custid = I.custid(+) '||
    '  and S.item = I.item(+) ' ||
    '  and nvl(S.lotnumber, ''(none)'') = nvl(I.lotnumber(+), ''(none)'') ' ||
    ' and I.status(+) not in (''D'',''P'',''U'',''CM'') ';
   IF NVL(in_17_is_available_only_yn,'N') = 'Y'
   or nvl(in_invstatus, 'N') = 'Y'
   THEN
     cmdSql := cmdSql ||  '  and I.invstatus = ''AV'' ';
   END IF;
   cmdSql := cmdSql ||
    ' group by S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
   -- '  ''17'','||
    l_17_AV ||
    ' nvl(I.uom,S.baseuom) ';

end if;

--debugmsg(cmdSql);


curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



if nvl(in_exclude_open_receipts, 'N') = 'Y' then

    for cur in (select P.facility, P.custid, P.item, P.lotnumber,
                sum(P.quantity) qty
        from orderhdr O, plate P
        where P.custid = in_custid
        and  O.orderid = P.orderid
        and O.shipid = P.shipid
        and O.orderstatus = 'A'
        and P.type != 'MP'
        group by  P.facility, P.custid, P.item, P.lotnumber)
    loop
        --debugmsg('Plate:'||cur.facility||'/'||cur.custid
        --        ||'/'||cur.item||'/'||cur.lotnumber||' Qty:'|| cur.qty);

        remove_item(cur.facility, cur.custid, cur.item, cur.lotnumber,
            cur.qty);
    end loop;


    for cur in (select S.facility, S.custid, S.item, S.lotnumber,
                sum(S.quantity) qty
        from orderhdr O, plate P, shippingplate S
        where S.custid = 'Z123'
        and S.status in ('P','S','L')
        and P.lpid = S.fromlpid
        and O.orderid = P.orderid
        and O.shipid = P.shipid
        and O.orderstatus = 'A'
        group by S.facility, S.custid, S.item, S.lotnumber)
    loop
        --debugmsg('SPlate:'||cur.facility||'/'||cur.custid
        --        ||'/'||cur.item||'/'||cur.lotnumber||' Qty:'|| cur.qty);
        remove_item(cur.facility, cur.custid, cur.item, cur.lotnumber,
            cur.qty);
    end loop;

-- Now clean up the qty and dtl records

    cmdSql := 'delete from '|| ddltitle || '_qty_' || strSuffix ||
        ' where quantity <= 0';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);

    cmdSql := 'delete from '|| ddltitle || '_dtl_' || strSuffix ||
        ' D where not exists (select * from ' || ddltitle || '_qty_'
        || strSuffix || ' Q where Q.facility = D.facility '
        || ' and Q.custid = D.custid '
        || ' and Q.item = D.item '
        || ' and Q.link_lotnumber = D.link_lotnumber) ';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);



end if;

  if nvl(in_exclude_crossdock, 'N') = 'Y' then
    for cur in (select P.facility, P.custid, P.item, P.lotnumber,P.invstatus,
                sum(P.quantity) qty
        from orderhdr O, plate P
        where P.custid = in_custid
        and  O.orderid = P.orderid
        and O.shipid = P.shipid
        and O.ordertype = 'C'
        and P.type != 'MP'
        group by  P.facility, P.custid, P.item, P.lotnumber,P.invstatus)
    loop
        --debugmsg('Plate:'||cur.facility||'/'||cur.custid
                --||'/'||cur.item||'/'||cur.lotnumber||' Qty:'|| cur.qty);
        if nvl(in_include_lotnumber,'N') = 'Y' then
          remove_item_status(cur.facility, cur.custid, cur.item, cur.lotnumber,cur.invstatus,cur.qty);
        else
          remove_item_status(cur.facility, cur.custid, cur.item, null,cur.invstatus,cur.qty);
        end if;



end loop;

end if;

if nvl(in_av_status_only_yn, 'N') = 'A' then  -- use allocable instead of available
  update_qty_av_to_allocable;
end if;

if nvl(in_exclude_zero,'N') = 'Y' then
   -- Now clean up the qty and dtl records

       cmdSql := 'delete from '|| ddltitle || '_qty_' || strSuffix ||
           ' where quantity <= 0';

       curFunc := dbms_sql.open_cursor;
       dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
       cntRows := dbms_sql.EXECUTE(curFunc);
       dbms_sql.close_cursor(curFunc);

    cmdSql := 'delete from '|| ddltitle || '_dtl_' || strSuffix ||
        ' D where not exists (select * from ' || ddltitle || '_qty_'
        || strSuffix || ' Q where Q.facility = D.facility '
        || ' and Q.custid = D.custid '
        || ' and Q.item = D.item '
        || ' and Q.link_lotnumber = D.link_lotnumber) ';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);
end if;

if nvl(in_exclude_zero,'N') = 'Y' then
   -- Now clean up the qty and dtl records

       cmdSql := 'delete from '|| ddltitle || '_qty_' || strSuffix ||
           ' where quantity <= 0';

       curFunc := dbms_sql.open_cursor;
       dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
       cntRows := dbms_sql.EXECUTE(curFunc);
       dbms_sql.close_cursor(curFunc);

    cmdSql := 'delete from '|| ddltitle || '_dtl_' || strSuffix ||
        ' D where not exists (select * from ' || ddltitle || '_qty_'
        || strSuffix || ' Q where Q.facility = D.facility '
        || ' and Q.custid = D.custid '
        || ' and Q.item = D.item '
        || ' and Q.link_lotnumber = D.link_lotnumber) ';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);
end if;

if nvl(in_include_lip_details_yn, 'N') = 'Y' then
    mark := 'lip table create';
cmdSql := 'create table ' || ddltitle || '_lip_' || strSuffix  ||
    '(FACILITY VARCHAR2(3) ' ||
    ',CUSTID VARCHAR2(10) ' ||
    ',LPID VARCHAR2(15) ' ||
    ',item varchar2(50) ' ||
    ',DESCR VARCHAR2(255) ' ||
    ',LOTNUMBER VARCHAR2(30) ' ||
    ',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
    ',QUANTITY NUMBER ' ||
    ',ITMPASSTHRUCHAR01 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR02 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR03 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR04 VARCHAR2(255) ' ||
    ',USERITEM1 VARCHAR2(20) ' ||
    ',USERITEM2 VARCHAR2(20) ' ||
    ',USERITEM3 VARCHAR2(20) ' ||
    ',EXPIRATIONDATE DATE ' ||
    ',INVSTATUS VARCHAR2(255) ' ||
    ',ADJREASON VARCHAR2(2) ' ||
    ',DMGREASON VARCHAR2(2) ' ||
    ',MANUFACTUREDATE DATE ' ||
    ',ITMPASSTHRUCHAR05 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR06 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR07 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR08 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR09 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR10 VARCHAR2(255) ' ||
    ',ITMPASSTHRUNUM01  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM02  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM03  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM04  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM05  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM06  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM07  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM08  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM09  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM10  NUMBER(16,4) ' ||
    ')';
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);
    debugmsg(cmdSql);

    mark := 'lip table populate';
cmdSql := 'insert into '|| ddltitle || '_lip_' || strSuffix ||
    ' select distinct P.facility, P.custid, P.lpid, P.item, D.descr, '||
    ' P.lotnumber, nvl(P.lotnumber,''(none)''), P.quantity, '||
    ' D.itmpassthruchar01, D.itmpassthruchar02, ' ||
    ' D.itmpassthruchar03, D.itmpassthruchar04, ' ||
    ' P.useritem1, P.useritem2, P.useritem3, P.expirationdate, '||
    ' P.invstatus, P.condition, zim7.getdmgreason(P.lpid), '||
    ' P.manufacturedate, ' ||
    ' D.itmpassthruchar05, D.itmpassthruchar06, ' ||
    ' D.itmpassthruchar07, D.itmpassthruchar08, ' ||
    ' D.itmpassthruchar09, D.itmpassthruchar10, ' ||
    ' D.itmpassthrunum01, D.itmpassthrunum02, ' ||
    ' D.itmpassthrunum03, D.itmpassthrunum04, ' ||
    ' D.itmpassthrunum05, D.itmpassthrunum06, ' ||
    ' D.itmpassthrunum07, D.itmpassthrunum08, ' ||
    ' D.itmpassthrunum09, D.itmpassthrunum10 ' ||
    ' from ' ||
    ddltitle ||'_dtl_' || strSuffix || ' D, ' ||
    ' allplateview P '||
    ' where D.facility = P.facility ' ||
    '  and D.custid = P.custid '||
    '  and D.item = P.item '||
    '  and nvl(D.lotnumber,''(none)'') = nvl(P.lotnumber,''(none)'') ' ||
    '  and P.type <> ''MP'' '||
    '  and nvl(P.quantity,0) > 0 ';
    debugmsg(cmdSql);
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);
end if;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss '||mark||':' || sqlerrm;
  out_errorno := sqlcode;
end begin_stockstat846;


procedure end_stockstat846
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;
begin
   cmdSql := 'drop table stock_status_846_lip_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stock_status_846_dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stock_status_846_qty_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stock_status_846_hdr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846_lip_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846_dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846_qty_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846_hdr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_stockstat846;


procedure begin_stockstat846_by_invstat
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_lotnumber IN VARCHAR2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_exclude_crossdock IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

mark varchar2(20);

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
l_17_AV varchar2(20);

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin
/*
if strDebugYN <> 'Y' then
  return;
end if;
*/
cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;


procedure remove_item_status(in_fac varchar2, in_custid varchar2, in_item varchar2,
    in_lot varchar2, in_invstatus varchar2, in_qty number)
is
cfunc integer;
crows integer;
csql varchar2(2000);
begin

  cSql := 'update ' || 'stkstat846byis_qty_' ||strSuffix
        || ' set quantity = quantity - '|| in_qty
        || ' where facility = '''||in_fac||''' and custid = '''||in_custid
        || ''' and item = '''||in_item||''' and link_lotnumber = ''' || nvl(in_lot,'(none)')||''''
        || ' and invstatus = ''' || in_invstatus ||'''';
  --debugmsg(cSql);
  cFunc := dbms_sql.open_cursor;
  dbms_sql.parse(cFunc, cSql, dbms_sql.native);
  cRows := dbms_sql.EXECUTE(cFunc);
  dbms_sql.close_cursor(cFunc);
  cSql := 'delete from ' || 'stkstat846byis_qty_' ||strSuffix
        || ' where facility = '''||in_fac||''' and custid = '''||in_custid
        || ''' and item = '''||in_item||''' and link_lotnumber = ''' || nvl(in_lot,'(none)')||''''
        || ' and invstatus = ''' || in_invstatus ||''' and quantity <= 0';
  cFunc := dbms_sql.open_cursor;
  dbms_sql.parse(cFunc, cSql, dbms_sql.native);
  cRows := dbms_sql.EXECUTE(cFunc);
  dbms_sql.close_cursor(cFunc);

end remove_item_status;

begin

out_errorno := 0;
out_msg := '';
mark := 'Start';

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'STKSTAT846BYIS_HDR_' || strSuffix;

  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

mark := 'Cust Chk';
select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

mark := 'hdr table create';
cmdSql := 'create table ' || 'stkstat846byis_hdr_' || strSuffix  ||
' (FACILITY VARCHAR2(3) not null ' ||
',CUSTID VARCHAR2(10) not null ' ||
',FACILITY_NAME VARCHAR2(40) ' ||
',FACILITY_ADDR1 VARCHAR2(40) ' ||
',FACILITY_ADDR2 VARCHAR2(40) ' ||
',FACILITY_CITY VARCHAR2(30) ' ||
',FACILITY_STATE VARCHAR2(5) ' ||
',FACILITY_POSTALCODE VARCHAR2(12) ' ||
',FACILITY_COUNTRYCODE VARCHAR2(3) ' ||
',FACILITY_PHONE VARCHAR2(25) ' ||
',CUSTOMER_NAME VARCHAR2(40) not null ' ||
',CUSTOMER_ADDR1 VARCHAR2(40) ' ||
',CUSTOMER_ADDR2 VARCHAR2(40) ' ||
',CUSTOMER_CITY VARCHAR2(30) ' ||
',CUSTOMER_STATE VARCHAR2(5) ' ||
',CUSTOMER_POSTALCODE VARCHAR2(12) ' ||
',CUSTOMER_COUNTRYCODE VARCHAR2(3) ' ||
',CUSTOMER_PHONE VARCHAR2(25) ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'hdr table populate';
cmdSql := 'insert into '|| 'stkstat846byis_hdr_' || strSuffix ||
 ' select distinct ' ||
 'I.facility,I.custid,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode,' ||
 'F.countrycode,F.phone,C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 'C.countrycode,C.phone '||
 ' from facility F, customer C, custitemtot I ' ||
 ' where I.custid = ''' || rtrim(in_custid) || '''' ||
 ' and I.custid = C.custid ' ||
 ' and I.facility = F.facility(+) ' ||
 ' and I.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 ' and I.status not in (''D'',''P'',''U'',''CM'') ';

--debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'dtl table create';
cmdSql := 'create table ' || 'stkstat846byis_dtl_' || strSuffix  ||
' (FACILITY VARCHAR2(3) not null ' ||
',CUSTID VARCHAR2(10) not null ' ||
',item varchar2(50) not null ' ||
',LOTNUMBER VARCHAR2(30) ' ||
',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
',UPC VARCHAR2(20) ' ||
',DESCR VARCHAR2(255) not null ' ||
',BASEUOM VARCHAR2(4) ' ||
',ITMPASSTHRUCHAR01 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR02 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR03 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR04 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR05 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR06 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR07 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR08 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR09 VARCHAR2(255) ' ||
',ITMPASSTHRUCHAR10 VARCHAR2(255) ' ||
',ITMPASSTHRUNUM01   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM02   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM03   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM04   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM05   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM06   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM07   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM08   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM09   NUMBER(16,4) ' ||
',ITMPASSTHRUNUM10   NUMBER(16,4) ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'dtl table populate';
if nvl(in_include_lotnumber, 'N') != 'Y' then
cmdSql := 'insert into '|| 'stkstat846byis_dtl_' || strSuffix ||
 ' select distinct S.facility,CI.custid,CI.item,null,''(none)'',' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitemtot T, custitem CI, custitemupcview U, ' ||
   'stkstat846byis_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and S.facility = T.facility ' ||
 '  and CI.custid = T.custid ' ||
 '  and CI.item = T.item ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ';
else
cmdSql := 'insert into '|| 'stkstat846byis_dtl_' || strSuffix ||
 ' select distinct S.facility,CI.custid,CI.item,' ||
 ' decode(T.lotnumber, ''(none)'',null, T.lotnumber), '||
 ' nvl(T.lotnumber,''(none)''), ' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitemtot T, custitem CI, custitemupcview U, ' ||
   'stkstat846byis_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 '  and S.facility = T.facility ' ||
 '  and S.custid = T.custid '||
 '  and CI.item = T.item ';
if nvl( in_exclude_zero, 'N') != 'Y' then
cmdSql := cmdSql ||
 ' union ' ||
 ' select distinct S.facility,CI.custid,CI.item,' ||
 ' null, '||
 ' ''(none)'', ' ||
 ' U.upc,CI.descr,CI.baseuom, ' ||
 ' CI.itmpassthruchar01, CI.itmpassthruchar02, ' ||
 ' CI.itmpassthruchar03, CI.itmpassthruchar04, ' ||
 ' CI.itmpassthruchar05, CI.itmpassthruchar06, ' ||
 ' CI.itmpassthruchar07, CI.itmpassthruchar08, ' ||
 ' CI.itmpassthruchar09, CI.itmpassthruchar10, ' ||
 ' CI.itmpassthrunum01, CI.itmpassthrunum02, ' ||
 ' CI.itmpassthrunum03, CI.itmpassthrunum04, ' ||
 ' CI.itmpassthrunum05, CI.itmpassthrunum06, ' ||
 ' CI.itmpassthrunum07, CI.itmpassthrunum08, ' ||
 ' CI.itmpassthrunum09, CI.itmpassthrunum10 ' ||
 ' from custitem CI, custitemupcview U, ' ||
 ' stkstat846byis_hdr_' || strSuffix || ' S ' ||
 ' where S.custid = CI.custid ' ||
 '  and CI.custid = U.custid(+) ' ||
 '  and CI.item = U.item(+) ' ||
 '  and CI.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 '  and not exists (select item from custitemtot T ' ||
 '   where T.facility = S.facility ' ||
 '     and T.custid = CI.custid ' ||
 '     and T.item = CI.item)';
else
cmdSql := cmdSql ||
 '  and T.status not in (''D'',''P'',''U'',''CM'') ';
end if;
end if;

curFunc := dbms_sql.open_cursor;

dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'qty table create';
cmdSql := 'create table ' || 'stkstat846byis_qty_' || strSuffix  ||
' (FACILITY VARCHAR2(3) ' ||
',CUSTID VARCHAR2(10) ' ||
',item varchar2(50) ' ||
',LOTNUMBER VARCHAR2(30) ' ||
',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
',INVSTATUS VARCHAR2(2) ' ||
',UOM VARCHAR2(4) ' ||
',QUANTITY NUMBER ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'qty table populate';

if nvl(in_include_lotnumber, 'N') != 'Y' then
  cmdSql := 'insert into '|| 'stkstat846byis_qty_' || strSuffix || ' ' ||
   ' select S.facility,S.custid,S.item, null, ''(none)'',' ||
    ' I.invstatus, nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, ' || 'stkstat846byis_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility '||
    '  and S.custid = I.custid '||
    '  and S.item = I.item '||
    '  and I.status not in (''D'',''P'',''U'',''CM'') ' ||
 --   '  and I.invstatus != ''AV'''||
    ' group by S.facility,S.custid,S.item, null, ''(none)'',' ||
    ' I.invstatus, nvl(I.uom,S.baseuom)';
else
  cmdSql := 'insert into '|| 'stkstat846byis_qty_' || strSuffix || ' ' ||
   ' select S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
    ' I.invstatus, nvl(I.uom,S.baseuom),sum(nvl(qty,0)) ' ||
    ' from custitemtot I, ' || 'stkstat846byis_dtl_'||strSuffix || ' S '||
    ' where S.facility = I.facility '||
    '  and S.custid = I.custid '||
    '  and S.item = I.item '||
    '  and nvl(S.lotnumber, ''(none)'') = nvl(I.lotnumber, ''(none)'') ' ||
    '  and I.status not in (''D'',''P'',''U'',''CM'') ' ||
 --   '  and I.invstatus != ''AV'''||
    ' group by S.facility,S.custid,S.item, ' ||
    ' decode(I.lotnumber, ''(none)'',null, I.lotnumber), '||
    ' nvl(I.lotnumber,''(none)''), ' ||
    ' I.invstatus, nvl(I.uom,S.baseuom)';
end if;

--debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

if nvl(in_exclude_crossdock, 'N') = 'Y' then
   for cur in (select P.facility, P.custid, P.item, P.lotnumber,P.invstatus, sum(P.quantity) qty
                 from orderhdr O, plate P
                where P.custid = in_custid
                  and  O.orderid = P.orderid
                  and O.shipid = P.shipid
                  and O.ordertype = 'C'
                  and P.type != 'MP'
                group by  P.facility, P.custid, P.item, P.lotnumber,P.invstatus)
    loop
       --debugmsg('Plate:'||cur.facility||'/'||cur.custid
               --||'/'||cur.item||'/'||cur.lotnumber||' Qty:'|| cur.qty);
       if nvl(in_include_lotnumber,'N') = 'Y' then
         remove_item_status(cur.facility, cur.custid, cur.item, cur.lotnumber,cur.invstatus,cur.qty);
       else
         remove_item_status(cur.facility, cur.custid, cur.item, null,cur.invstatus,cur.qty);
       end if;
       cmdSql := 'delete from '|| 'stkstat846byis_dtl_' || strSuffix ||
           ' D where not exists (select * from ' || 'stkstat846byis_qty_'
           || strSuffix || ' Q where Q.facility = D.facility '
           || ' and Q.custid = D.custid '
           || ' and Q.item = D.item '
           || ' and Q.link_lotnumber = D.link_lotnumber) ';

       curFunc := dbms_sql.open_cursor;
       dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
       cntRows := dbms_sql.EXECUTE(curFunc);
       dbms_sql.close_cursor(curFunc);
end loop;

end if;

mark := 'lip table create';
cmdSql := 'create table ' || 'stkstat846byis_lip_' || strSuffix  ||
    '(FACILITY VARCHAR2(3) ' ||
    ',CUSTID VARCHAR2(10) ' ||
    ',LPID VARCHAR2(15) ' ||
    ',item varchar2(50) ' ||
    ',DESCR VARCHAR2(255) ' ||
    ',LOTNUMBER VARCHAR2(30) ' ||
    ',LINK_LOTNUMBER VARCHAR2(30) not null ' ||
    ',QUANTITY NUMBER ' ||
    ',ITMPASSTHRUCHAR01 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR02 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR03 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR04 VARCHAR2(255) ' ||
    ',USERITEM1 VARCHAR2(20) ' ||
    ',USERITEM2 VARCHAR2(20) ' ||
    ',USERITEM3 VARCHAR2(20) ' ||
    ',EXPIRATIONDATE DATE ' ||
    ',INVSTATUS VARCHAR2(255) ' ||
    ',CONDITION VARCHAR2(2) ' ||
    ',DMGREASON VARCHAR2(2) ' ||
    ',MANUFACTUREDATE DATE ' ||
    ',ITMPASSTHRUCHAR05 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR06 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR07 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR08 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR09 VARCHAR2(255) ' ||
    ',ITMPASSTHRUCHAR10 VARCHAR2(255) ' ||
    ',ITMPASSTHRUNUM01  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM02  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM03  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM04  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM05  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM06  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM07  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM08  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM09  NUMBER(16,4) ' ||
    ',ITMPASSTHRUNUM10  NUMBER(16,4) ' ||
    ')';
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);
    debugmsg(cmdSql);

mark := 'lip table populate';
cmdSql := 'insert into '|| 'stkstat846byis_lip_' || strSuffix ||
    ' select distinct P.facility, P.custid, P.lpid, P.item, D.descr, '||
    ' P.lotnumber, nvl(P.lotnumber,''(none)''), P.quantity, '||
    ' D.itmpassthruchar01, D.itmpassthruchar02, ' ||
    ' D.itmpassthruchar03, D.itmpassthruchar04, ' ||
    ' P.useritem1, P.useritem2, P.useritem3, P.expirationdate, '||
    ' P.invstatus, P.condition, zim7.getdmgreason(P.lpid), '||
    ' P.manufacturedate, ' ||
    ' D.itmpassthruchar05, D.itmpassthruchar06, ' ||
    ' D.itmpassthruchar07, D.itmpassthruchar08, ' ||
    ' D.itmpassthruchar09, D.itmpassthruchar10, ' ||
    ' D.itmpassthrunum01, D.itmpassthrunum02, ' ||
    ' D.itmpassthrunum03, D.itmpassthrunum04, ' ||
    ' D.itmpassthrunum05, D.itmpassthrunum06, ' ||
    ' D.itmpassthrunum07, D.itmpassthrunum08, ' ||
    ' D.itmpassthrunum09, D.itmpassthrunum10 ' ||
    ' from ' ||
    ' stkstat846byis_dtl_' || strSuffix || ' D, ' ||
    ' allplateview P '||
    ' where D.facility = P.facility ' ||
    '  and D.custid = P.custid '||
    '  and D.item = P.item '||
    '  and nvl(D.lotnumber,''(none)'') = nvl(P.lotnumber,''(none)'') ' ||
    '  and P.type <> ''MP'' '||
    '  and nvl(P.quantity,0) > 0 ';
    debugmsg(cmdSql);
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);

if nvl(in_exclude_open_receipts, 'N') = 'Y' then
    for cur in (select distinct P.lpid, P.facility, P.custid, P.item, 
	                   decode(nvl(in_include_lotnumber,'N'), 'Y', P.lotnumber, null) lot, P.invstatus,
					   P.quantity
                  from orderhdr O, plate P
                 where P.custid = in_custid
                   and  O.orderid = P.orderid
                   and O.shipid = P.shipid
                   and O.ordertype = 'R'
                   and O.orderstatus not in ('R', 'X') --= 'A'
                   and P.type != 'MP')
    loop
	   begin
		 cmdSql := 'delete from stkstat846byis_lip_' || strSuffix
	          || ' where lpid = ''' || cur.lpid || '''';
		 
         curFunc := dbms_sql.open_cursor;
         dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
         cntRows := dbms_sql.EXECUTE(curFunc);
         dbms_sql.close_cursor(curFunc);

	     cmdSql := 'update stkstat846byis_qty_' || strSuffix
                || ' set quantity = quantity - ' || cur.quantity
              || ' where facility = ''' || cur.facility || ''' and custid = ''' || cur.custid
              || ''' and item = ''' || cur.item || ''' and link_lotnumber = ''' || nvl(cur.lot, '(none)') || ''''
                || ' and invstatus = ''' || cur.invstatus ||'''';

         curFunc := dbms_sql.open_cursor;
         dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
         cntRows := dbms_sql.EXECUTE(curFunc);
         dbms_sql.close_cursor(curFunc);
       exception 
	     when NO_DATA_FOUND then
	       null;
	     when others then
	       rollback;
	  end;
    end loop;
end if;

if nvl(in_exclude_zero,'N') = 'Y' then
   -- Now clean up the qty and dtl records

   cmdSql := 'delete from '|| 'stkstat846byis_qty_' || strSuffix ||
       ' where quantity <= 0';

   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.EXECUTE(curFunc);
   dbms_sql.close_cursor(curFunc);

   cmdSql := 'delete from '|| 'stkstat846byis_dtl_' || strSuffix ||
        ' D where not exists (select * from ' || 'stkstat846byis_qty_' || strSuffix ||
        ' Q where Q.facility = D.facility ' ||
        ' and Q.custid = D.custid ' ||
        ' and Q.item = D.item ' ||
        ' and Q.link_lotnumber = D.link_lotnumber) ';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);

    cmdSql := 'delete from '|| 'stkstat846byis_lip_' || strSuffix ||
        ' D where not exists (select * from ' || 'stkstat846byis_dtl_' || strSuffix ||
        ' Q where Q.facility = D.facility ' ||
        ' and Q.custid = D.custid ' ||
        ' and Q.item = D.item ' ||
        ' and Q.link_lotnumber = D.link_lotnumber) ';

    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.EXECUTE(curFunc);
    dbms_sql.close_cursor(curFunc);	
end if;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss '||mark||':' || sqlerrm;
  out_errorno := sqlcode;
end begin_stockstat846_by_invstat;

procedure end_stockstat846_by_invstat
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;
begin
   cmdSql := 'drop table stkstat846byis_lip_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846byis_dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846byis_qty_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table stkstat846byis_hdr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_stockstat846_by_invstat;


procedure begin_rcptnote944
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_exclude_ide_av_invstatus_yn IN varchar2
,in_dtv_receipt_or_return_rqn IN varchar2
,in_invclass_yn IN varchar2
,in_ide_use_received_yn IN varchar2
,in_summarize_manu_yn IN varchar2
,in_lip_line_yn IN VARCHAR2
,in_invstatus_yn IN varchar2
,in_shipper_addr_yn IN varchar2
,in_list_serialnumber_yn IN varchar2
,in_dtlrcptlines_yn IN varchar2
,in_exclude_source IN varchar2
,in_create_944_cfs_data_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

cursor C_ORDS_BY_DATE(in_custid char, in_begin date, in_end date)
IS
select *
  from orderhdr
 where custid = in_custid
   and orderstatus in ('R','X')
   and statusupdate >= in_begin
   and statusupdate <= in_end
   and nvl(source,'aaa') <> nvl(in_exclude_source,'zzz');

cursor C_ORDS_BY_ORDERID(in_custid char, in_orderid number, in_shipid number)
is
select *
  from orderhdr
 where custid = in_custid
   and orderstatus in ('R','X')
   and orderid = in_orderid
   and shipid = in_shipid
   and nvl(source,'aaa') <> nvl(in_exclude_source,'zzz');

cursor C_ORDS_BY_LOADNO(in_custid char, in_loadno number)
IS
select *
  from orderhdr
 where custid = in_custid
   and orderstatus in ('R','X')
   and loadno = in_loadno
   and nvl(source,'aaa') <> nvl(in_exclude_source,'zzz');

cursor curLoads(in_loadno number) is
  select *
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

cursor curShipper(in_shipper varchar2) is
  select *
    from shipper
   where shipper = in_shipper;
sh curShipper%rowtype;

cursor curFacility(in_facility varchar2) is
  select *
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

cursor curOrderDtlSum(in_orderid number, in_shipid number) is
  select sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(weightrcvd,0)) as weightrcvd,
         sum(nvl(cubercvd,0)) as cubercvd,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(weightrcvdgood,0)) as weightrcvdgood,
         sum(nvl(cubercvdgood,0)) as cubercvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd,
         sum(nvl(weightrcvddmgd,0)) as weightrcvddmgd,
         sum(nvl(cubercvddmgd,0)) as cubercvddmgd
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
ds curOrderDtlSum%rowtype;

l_seq integer;
cmt varchar2(4001);
str varchar2(100);
len integer;
tpos integer;
tcur integer;
tcnt integer;

qpos integer;
qual varchar2(100);

cursor C_ORDDTL(in_orderid number, in_shipid number)
is
select *
 from orderdtl
where orderid = in_orderid
  and shipid = in_shipid
  and nvl(qtyorder,0) != nvl(qtyrcvd,0);

l_qty number;

cursor C_ORDDTLRCPT(in_orderid number, in_shipid number)
is
select R.item, '                              ' as lotnumber, R.uom, sum(nvl(R.qtyrcvd,0)) qtyrcvd, R.invstatus,
       'NR' cond
 from orderdtlrcpt R
where R.orderid = in_orderid
  and R.shipid = in_shipid
  and R.invstatus != 'AV'
group by R.item,'                              ', R.uom, R.invstatus,
       'NR' ;

cursor C_ORDDTLRCPTLOT(in_orderid number, in_shipid number)
is
select R.item, R.lotnumber, R.uom, sum(nvl(R.qtyrcvd,0)) qtyrcvd, R.invstatus,
       'NR' cond
 from orderdtlrcpt R
where R.orderid = in_orderid
  and R.shipid = in_shipid
  and R.invstatus != 'AV'
group by R.item, R.lotnumber, R.uom, R.invstatus,
       'NR' ;

cursor curCustomer is
  select cu.custid,nvl(cu.recv_line_check_yn,'N') as recv_line_check_yn,
         cu.name,
         nvl(ca.asnlineno,'N') as asnlineno,
         nvl(ca.rcptnote_include_cross_cust_yn,'N') as rcptnote_include_cross_cust_yn
    from customer cu, customer_aux ca
   where cu.custid = in_custid and
         cu.custid = ca.custid(+);
cu curCustomer%rowtype;

cursor curOrderDtl(in_orderid number, in_shipid number) is
  select custid,orderid,shipid,item,
         '                              ' as lotnumber,
         uom,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(qtyorder,0)) as qtyorder,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd,
         sum(nvl(cubercvdgood,0)) as cubercvdgood
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
   group by custid,orderid,shipid,item,'                              ',uom
   order by custid,orderid,shipid,item,'                              ',uom;

cursor curOrderDtlLot(in_orderid number, in_shipid number) is
  select custid,orderid,shipid,item,lotnumber,uom,
        nvl(qtyrcvd,0)  qtyrcvd,
        nvl(qtyorder,0) qtyorder,
        nvl(qtyrcvdgood,0)  qtyrcvdgood,
        nvl(qtyrcvddmgd,0)  qtyrcvddmgd,
        nvl(cubercvdgood,0)  cubercvdgood
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
od curOrderDtlLot%rowtype;

cursor curOrderDtlNoLine(in_orderid number, in_shipid number) is
  select custid,orderid,shipid,item,
         '                              ' as lotnumber,
         uom,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(qtyorder,0)) as qtyorder,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd,
         sum(nvl(cubercvdgood,0)) as cubercvdgood,
         sum(nvl(cubercvddmgd,0)) as cubercvddmgd
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and not exists (select * from orderdtlline
                      where orderdtl.orderid = orderdtlline.orderid
                        and orderdtl.shipid = orderdtlline.shipid
                        and orderdtl.item = orderdtlline.item
                        and nvl(orderdtlline.xdock,'N') = 'N')
   group by custid,orderid,shipid,item,'                              ',uom
   order by custid,orderid,shipid,item,'                              ',uom;

cursor curOrderDtlLineLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.uom as uom,
         od.LOTNUMBER as lotnumber,
         nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
         nvl(OL.qty,nvl(OD.qtyrcvd,0)) as qtyrcvd,
         nvl(ol.DTLPASSTHRUchar01,od.DTLPASSTHRUchar01) as dtlpassthruchar01,
         nvl(ol.DTLPASSTHRUchar02,od.DTLPASSTHRUchar02) as dtlpassthruchar02,
         nvl(ol.DTLPASSTHRUchar03,od.DTLPASSTHRUchar03) as dtlpassthruchar03,
         nvl(ol.DTLPASSTHRUchar04,od.DTLPASSTHRUchar04) as dtlpassthruchar04,
         nvl(ol.DTLPASSTHRUchar05,od.DTLPASSTHRUchar05) as dtlpassthruchar05,
         nvl(ol.DTLPASSTHRUchar06,od.DTLPASSTHRUchar06) as dtlpassthruchar06,
         nvl(ol.DTLPASSTHRUchar07,od.DTLPASSTHRUchar07) as dtlpassthruchar07,
         nvl(ol.DTLPASSTHRUchar08,od.DTLPASSTHRUchar08) as dtlpassthruchar08,
         nvl(ol.DTLPASSTHRUchar09,od.DTLPASSTHRUchar09) as dtlpassthruchar09,
         nvl(ol.DTLPASSTHRUchar10,od.DTLPASSTHRUchar10) as dtlpassthruchar10,
         nvl(ol.DTLPASSTHRUchar11,od.DTLPASSTHRUchar11) as dtlpassthruchar11,
         nvl(ol.DTLPASSTHRUchar12,od.DTLPASSTHRUchar12) as dtlpassthruchar12,
         nvl(ol.DTLPASSTHRUchar13,od.DTLPASSTHRUchar13) as dtlpassthruchar13,
         nvl(ol.DTLPASSTHRUchar14,od.DTLPASSTHRUchar14) as dtlpassthruchar14,
         nvl(ol.DTLPASSTHRUchar15,od.DTLPASSTHRUchar15) as dtlpassthruchar15,
         nvl(ol.DTLPASSTHRUchar16,od.DTLPASSTHRUchar16) as dtlpassthruchar16,
         nvl(ol.DTLPASSTHRUchar17,od.DTLPASSTHRUchar17) as dtlpassthruchar17,
         nvl(ol.DTLPASSTHRUchar18,od.DTLPASSTHRUchar18) as dtlpassthruchar18,
         nvl(ol.DTLPASSTHRUchar19,od.DTLPASSTHRUchar19) as dtlpassthruchar19,
         nvl(ol.DTLPASSTHRUchar20,od.DTLPASSTHRUchar20) as dtlpassthruchar20,
         nvl(ol.DTLPASSTHRUchar21,od.DTLPASSTHRUchar21) as dtlpassthruchar21,
         nvl(ol.DTLPASSTHRUchar22,od.DTLPASSTHRUchar22) as dtlpassthruchar22,
         nvl(ol.DTLPASSTHRUchar23,od.DTLPASSTHRUchar23) as dtlpassthruchar23,
         nvl(ol.DTLPASSTHRUchar24,od.DTLPASSTHRUchar24) as dtlpassthruchar24,
         nvl(ol.DTLPASSTHRUchar25,od.DTLPASSTHRUchar25) as dtlpassthruchar25,
         nvl(ol.DTLPASSTHRUchar26,od.DTLPASSTHRUchar26) as dtlpassthruchar26,
         nvl(ol.DTLPASSTHRUchar27,od.DTLPASSTHRUchar27) as dtlpassthruchar27,
         nvl(ol.DTLPASSTHRUchar28,od.DTLPASSTHRUchar28) as dtlpassthruchar28,
         nvl(ol.DTLPASSTHRUchar29,od.DTLPASSTHRUchar29) as dtlpassthruchar29,
         nvl(ol.DTLPASSTHRUchar30,od.DTLPASSTHRUchar30) as dtlpassthruchar30,
         nvl(ol.DTLPASSTHRUchar31,od.DTLPASSTHRUchar31) as dtlpassthruchar31,
         nvl(ol.DTLPASSTHRUchar32,od.DTLPASSTHRUchar32) as dtlpassthruchar32,
         nvl(ol.DTLPASSTHRUchar33,od.DTLPASSTHRUchar33) as dtlpassthruchar33,
         nvl(ol.DTLPASSTHRUchar34,od.DTLPASSTHRUchar34) as dtlpassthruchar34,
         nvl(ol.DTLPASSTHRUchar35,od.DTLPASSTHRUchar35) as dtlpassthruchar35,
         nvl(ol.DTLPASSTHRUchar36,od.DTLPASSTHRUchar36) as dtlpassthruchar36,
         nvl(ol.DTLPASSTHRUchar37,od.DTLPASSTHRUchar37) as dtlpassthruchar37,
         nvl(ol.DTLPASSTHRUchar38,od.DTLPASSTHRUchar38) as dtlpassthruchar38,
         nvl(ol.DTLPASSTHRUchar39,od.DTLPASSTHRUchar39) as dtlpassthruchar39,
         nvl(ol.DTLPASSTHRUchar40,od.DTLPASSTHRUchar40) as dtlpassthruchar40,
         nvl(ol.DTLPASSTHRUNUM01,od.dtlpassthrunum01) as dtlpassthrunum01,
         nvl(ol.DTLPASSTHRUNUM02,od.dtlpassthrunum02) as dtlpassthrunum02,
         nvl(ol.DTLPASSTHRUNUM03,od.dtlpassthrunum03) as dtlpassthrunum03,
         nvl(ol.DTLPASSTHRUNUM04,od.dtlpassthrunum04) as dtlpassthrunum04,
         nvl(ol.DTLPASSTHRUNUM05,od.dtlpassthrunum05) as dtlpassthrunum05,
         nvl(ol.DTLPASSTHRUNUM06,od.dtlpassthrunum06) as dtlpassthrunum06,
         nvl(ol.DTLPASSTHRUNUM07,od.dtlpassthrunum07) as dtlpassthrunum07,
         nvl(ol.DTLPASSTHRUNUM08,od.dtlpassthrunum08) as dtlpassthrunum08,
         nvl(ol.DTLPASSTHRUNUM09,od.dtlpassthrunum09) as dtlpassthrunum09,
         nvl(ol.DTLPASSTHRUNUM10,od.dtlpassthrunum10) as dtlpassthrunum10,
         nvl(ol.DTLPASSTHRUNUM11,od.dtlpassthrunum11) as dtlpassthrunum11,
         nvl(ol.DTLPASSTHRUNUM12,od.dtlpassthrunum12) as dtlpassthrunum12,
         nvl(ol.DTLPASSTHRUNUM13,od.dtlpassthrunum13) as dtlpassthrunum13,
         nvl(ol.DTLPASSTHRUNUM14,od.dtlpassthrunum14) as dtlpassthrunum14,
         nvl(ol.DTLPASSTHRUNUM15,od.dtlpassthrunum15) as dtlpassthrunum15,
         nvl(ol.DTLPASSTHRUNUM16,od.dtlpassthrunum16) as dtlpassthrunum16,
         nvl(ol.DTLPASSTHRUNUM17,od.dtlpassthrunum17) as dtlpassthrunum17,
         nvl(ol.DTLPASSTHRUNUM18,od.dtlpassthrunum18) as dtlpassthrunum18,
         nvl(ol.DTLPASSTHRUNUM19,od.dtlpassthrunum19) as dtlpassthrunum19,
         nvl(ol.DTLPASSTHRUNUM20,od.dtlpassthrunum20) as dtlpassthrunum20,
         nvl(ol.LASTUSER,od.lastuser) as lastuser,
         nvl(ol.LASTUPDATE,od.lastupdate) as lastupdate,
         nvl(ol.DTLPASSTHRUDATE01,od.dtlpassthrudate01) as dtlpassthrudate01,
         nvl(ol.DTLPASSTHRUDATE02,od.dtlpassthrudate02) as dtlpassthrudate02,
         nvl(ol.DTLPASSTHRUDATE03,od.dtlpassthrudate03) as dtlpassthrudate03,
         nvl(ol.DTLPASSTHRUDATE04,od.dtlpassthrudate04) as dtlpassthrudate04,
         nvl(ol.DTLPASSTHRUDOLL01,od.dtlpassthrudoll01) as dtlpassthrudoll01,
         nvl(ol.DTLPASSTHRUDOLL02,od.dtlpassthrudoll02) as dtlpassthrudoll02,
         nvl(ol.QTYAPPROVED,0) as qtyapproved
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrudate01,od.dtlpassthrudate01),
            nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0));

cursor curOrderDtlInvsts(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.LOTNUMBER as orderlot,
         odr.LOTNUMBER as lotnumber,
         odr.invstatus as invstatus,
         nvl(od.dtlpassthrunum10,0) as linenumber,
         nvl(OD.qtyorder,0) as qty,
         sum(nvl(ODR.qtyrcvd,0)) as qtyrcvd,
         sum(nvl(ODR.qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(ODR.qtyrcvddmgd,0)) as qtyrcvddmgd,
         od.DTLPASSTHRUchar01 as dtlpassthruchar01,
         od.DTLPASSTHRUchar02 as dtlpassthruchar02,
         od.DTLPASSTHRUchar03 as dtlpassthruchar03,
         od.DTLPASSTHRUchar04 as dtlpassthruchar04,
         od.DTLPASSTHRUchar05 as dtlpassthruchar05,
         od.DTLPASSTHRUchar06 as dtlpassthruchar06,
         od.DTLPASSTHRUchar07 as dtlpassthruchar07,
         od.DTLPASSTHRUchar08 as dtlpassthruchar08,
         od.DTLPASSTHRUchar09 as dtlpassthruchar09,
         od.DTLPASSTHRUchar10 as dtlpassthruchar10,
         od.DTLPASSTHRUchar11 as dtlpassthruchar11,
         od.DTLPASSTHRUchar12 as dtlpassthruchar12,
         od.DTLPASSTHRUchar13 as dtlpassthruchar13,
         od.DTLPASSTHRUchar14 as dtlpassthruchar14,
         od.DTLPASSTHRUchar15 as dtlpassthruchar15,
         od.DTLPASSTHRUchar16 as dtlpassthruchar16,
         od.DTLPASSTHRUchar17 as dtlpassthruchar17,
         od.DTLPASSTHRUchar18 as dtlpassthruchar18,
         od.DTLPASSTHRUchar19 as dtlpassthruchar19,
         od.DTLPASSTHRUchar20 as dtlpassthruchar20,
         od.DTLPASSTHRUchar21 as dtlpassthruchar21,
         od.DTLPASSTHRUchar22 as dtlpassthruchar22,
         od.DTLPASSTHRUchar23 as dtlpassthruchar23,
         od.DTLPASSTHRUchar24 as dtlpassthruchar24,
         od.DTLPASSTHRUchar25 as dtlpassthruchar25,
         od.DTLPASSTHRUchar26 as dtlpassthruchar26,
         od.DTLPASSTHRUchar27 as dtlpassthruchar27,
         od.DTLPASSTHRUchar28 as dtlpassthruchar28,
         od.DTLPASSTHRUchar29 as dtlpassthruchar29,
         od.DTLPASSTHRUchar30 as dtlpassthruchar30,
         od.DTLPASSTHRUchar31 as dtlpassthruchar31,
         od.DTLPASSTHRUchar32 as dtlpassthruchar32,
         od.DTLPASSTHRUchar33 as dtlpassthruchar33,
         od.DTLPASSTHRUchar34 as dtlpassthruchar34,
         od.DTLPASSTHRUchar35 as dtlpassthruchar35,
         od.DTLPASSTHRUchar36 as dtlpassthruchar36,
         od.DTLPASSTHRUchar37 as dtlpassthruchar37,
         od.DTLPASSTHRUchar38 as dtlpassthruchar38,
         od.DTLPASSTHRUchar39 as dtlpassthruchar39,
         od.DTLPASSTHRUchar40 as dtlpassthruchar40,
         od.dtlpassthrunum01 as dtlpassthrunum01,
         od.dtlpassthrunum02 as dtlpassthrunum02,
         od.dtlpassthrunum03 as dtlpassthrunum03,
         od.dtlpassthrunum04 as dtlpassthrunum04,
         od.dtlpassthrunum05 as dtlpassthrunum05,
         od.dtlpassthrunum06 as dtlpassthrunum06,
         od.dtlpassthrunum07 as dtlpassthrunum07,
         od.dtlpassthrunum08 as dtlpassthrunum08,
         od.dtlpassthrunum09 as dtlpassthrunum09,
         od.dtlpassthrunum10 as dtlpassthrunum10,
         od.dtlpassthrunum11 as dtlpassthrunum11,
         od.dtlpassthrunum12 as dtlpassthrunum12,
         od.dtlpassthrunum13 as dtlpassthrunum13,
         od.dtlpassthrunum14 as dtlpassthrunum14,
         od.dtlpassthrunum15 as dtlpassthrunum15,
         od.dtlpassthrunum16 as dtlpassthrunum16,
         od.dtlpassthrunum17 as dtlpassthrunum17,
         od.dtlpassthrunum18 as dtlpassthrunum18,
         od.dtlpassthrunum19 as dtlpassthrunum19,
         od.dtlpassthrunum20 as dtlpassthrunum20,
         od.lastuser as lastuser,
         od.lastupdate as lastupdate,
         od.dtlpassthrudate01 as dtlpassthrudate01,
         od.dtlpassthrudate02 as dtlpassthrudate02,
         od.dtlpassthrudate03 as dtlpassthrudate03,
         od.dtlpassthrudate04 as dtlpassthrudate04,
         od.dtlpassthrudoll01 as dtlpassthrudoll01,
         od.dtlpassthrudoll02 as dtlpassthrudoll02
    from orderdtl od, orderdtlrcpt odr
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and odr.orderid(+) = in_orderid
     and odr.shipid(+) = in_shipid
     and odr.orderitem(+) =   in_orderitem
     and nvl(odr.orderlot(+),'(none)') = nvl(in_orderlot,'(none)')
   group by od.ORDERID,
         od.SHIPID,
         od.ITEM,
         od.LOTNUMBER,
         odr.lotnumber,
         odr.invstatus,
         nvl(od.dtlpassthrunum10,0),
         nvl(OD.qtyorder,0),
         od.DTLPASSTHRUchar01,
         od.DTLPASSTHRUchar02,
         od.DTLPASSTHRUchar03,
         od.DTLPASSTHRUchar04,
         od.DTLPASSTHRUchar05,
         od.DTLPASSTHRUchar06,
         od.DTLPASSTHRUchar07,
         od.DTLPASSTHRUchar08,
         od.DTLPASSTHRUchar09,
         od.DTLPASSTHRUchar10,
         od.DTLPASSTHRUchar11,
         od.DTLPASSTHRUchar12,
         od.DTLPASSTHRUchar13,
         od.DTLPASSTHRUchar14,
         od.DTLPASSTHRUchar15,
         od.DTLPASSTHRUchar16,
         od.DTLPASSTHRUchar17,
         od.DTLPASSTHRUchar18,
         od.DTLPASSTHRUchar19,
         od.DTLPASSTHRUchar20,
         od.DTLPASSTHRUchar21,
         od.DTLPASSTHRUchar22,
         od.DTLPASSTHRUchar23,
         od.DTLPASSTHRUchar24,
         od.DTLPASSTHRUchar25,
         od.DTLPASSTHRUchar26,
         od.DTLPASSTHRUchar27,
         od.DTLPASSTHRUchar28,
         od.DTLPASSTHRUchar29,
         od.DTLPASSTHRUchar30,
         od.DTLPASSTHRUchar31,
         od.DTLPASSTHRUchar32,
         od.DTLPASSTHRUchar33,
         od.DTLPASSTHRUchar34,
         od.DTLPASSTHRUchar35,
         od.DTLPASSTHRUchar36,
         od.DTLPASSTHRUchar37,
         od.DTLPASSTHRUchar38,
         od.DTLPASSTHRUchar39,
         od.DTLPASSTHRUchar40,
         od.dtlpassthrunum01,
         od.dtlpassthrunum02,
         od.dtlpassthrunum03,
         od.dtlpassthrunum04,
         od.dtlpassthrunum05,
         od.dtlpassthrunum06,
         od.dtlpassthrunum07,
         od.dtlpassthrunum08,
         od.dtlpassthrunum09,
         od.dtlpassthrunum10,
         od.dtlpassthrunum11,
         od.dtlpassthrunum12,
         od.dtlpassthrunum13,
         od.dtlpassthrunum14,
         od.dtlpassthrunum15,
         od.dtlpassthrunum16,
         od.dtlpassthrunum17,
         od.dtlpassthrunum18,
         od.dtlpassthrunum19,
         od.dtlpassthrunum20,
         od.lastuser,
         od.lastupdate,
         od.dtlpassthrudate01,
         od.dtlpassthrudate02,
         od.dtlpassthrudate03,
         od.dtlpassthrudate04,
         od.dtlpassthrudoll01,
         od.dtlpassthrudoll02
   order by od.dtlpassthrudate01,
            nvl(od.dtlpassthrunum10,0);


cursor curOrderDtlInvstsRtn(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.LOTNUMBER as orderlot,
         odr.lotnumber as lotnumber,
         odr.invstatus as invstatus,
         odr.inventoryclass as invclass,
         nvl(od.dtlpassthrunum10,0) as linenumber,
         nvl(OD.qtyorder,0) as qty,
         sum(nvl(ODR.qtyrcvd,0)) as qtyrcvd,
         sum(nvl(ODR.qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(ODR.qtyrcvddmgd,0)) as qtyrcvddmgd,
         od.DTLPASSTHRUchar01 as dtlpassthruchar01,
         od.DTLPASSTHRUchar02 as dtlpassthruchar02,
         od.DTLPASSTHRUchar03 as dtlpassthruchar03,
         od.DTLPASSTHRUchar04 as dtlpassthruchar04,
         od.DTLPASSTHRUchar05 as dtlpassthruchar05,
         od.DTLPASSTHRUchar06 as dtlpassthruchar06,
         od.DTLPASSTHRUchar07 as dtlpassthruchar07,
         od.DTLPASSTHRUchar08 as dtlpassthruchar08,
         od.DTLPASSTHRUchar09 as dtlpassthruchar09,
         od.DTLPASSTHRUchar10 as dtlpassthruchar10,
         od.DTLPASSTHRUchar11 as dtlpassthruchar11,
         od.DTLPASSTHRUchar12 as dtlpassthruchar12,
         od.DTLPASSTHRUchar13 as dtlpassthruchar13,
         od.DTLPASSTHRUchar14 as dtlpassthruchar14,
         od.DTLPASSTHRUchar15 as dtlpassthruchar15,
         od.DTLPASSTHRUchar16 as dtlpassthruchar16,
         od.DTLPASSTHRUchar17 as dtlpassthruchar17,
         od.DTLPASSTHRUchar18 as dtlpassthruchar18,
         od.DTLPASSTHRUchar19 as dtlpassthruchar19,
         od.DTLPASSTHRUchar20 as dtlpassthruchar20,
         od.DTLPASSTHRUchar21 as dtlpassthruchar21,
         od.DTLPASSTHRUchar22 as dtlpassthruchar22,
         od.DTLPASSTHRUchar23 as dtlpassthruchar23,
         od.DTLPASSTHRUchar24 as dtlpassthruchar24,
         od.DTLPASSTHRUchar25 as dtlpassthruchar25,
         od.DTLPASSTHRUchar26 as dtlpassthruchar26,
         od.DTLPASSTHRUchar27 as dtlpassthruchar27,
         od.DTLPASSTHRUchar28 as dtlpassthruchar28,
         od.DTLPASSTHRUchar29 as dtlpassthruchar29,
         od.DTLPASSTHRUchar30 as dtlpassthruchar30,
         od.DTLPASSTHRUchar31 as dtlpassthruchar31,
         od.DTLPASSTHRUchar32 as dtlpassthruchar32,
         od.DTLPASSTHRUchar33 as dtlpassthruchar33,
         od.DTLPASSTHRUchar34 as dtlpassthruchar34,
         od.DTLPASSTHRUchar35 as dtlpassthruchar35,
         od.DTLPASSTHRUchar36 as dtlpassthruchar36,
         od.DTLPASSTHRUchar37 as dtlpassthruchar37,
         od.DTLPASSTHRUchar38 as dtlpassthruchar38,
         od.DTLPASSTHRUchar39 as dtlpassthruchar39,
         od.DTLPASSTHRUchar40 as dtlpassthruchar40,
         od.dtlpassthrunum01 as dtlpassthrunum01,
         od.dtlpassthrunum02 as dtlpassthrunum02,
         od.dtlpassthrunum03 as dtlpassthrunum03,
         od.dtlpassthrunum04 as dtlpassthrunum04,
         od.dtlpassthrunum05 as dtlpassthrunum05,
         od.dtlpassthrunum06 as dtlpassthrunum06,
         od.dtlpassthrunum07 as dtlpassthrunum07,
         od.dtlpassthrunum08 as dtlpassthrunum08,
         od.dtlpassthrunum09 as dtlpassthrunum09,
         od.dtlpassthrunum10 as dtlpassthrunum10,
         od.dtlpassthrunum11 as dtlpassthrunum11,
         od.dtlpassthrunum12 as dtlpassthrunum12,
         od.dtlpassthrunum13 as dtlpassthrunum13,
         od.dtlpassthrunum14 as dtlpassthrunum14,
         od.dtlpassthrunum15 as dtlpassthrunum15,
         od.dtlpassthrunum16 as dtlpassthrunum16,
         od.dtlpassthrunum17 as dtlpassthrunum17,
         od.dtlpassthrunum18 as dtlpassthrunum18,
         od.dtlpassthrunum19 as dtlpassthrunum19,
         od.dtlpassthrunum20 as dtlpassthrunum20,
         od.lastuser as lastuser,
         od.lastupdate as lastupdate,
         od.dtlpassthrudate01 as dtlpassthrudate01,
         od.dtlpassthrudate02 as dtlpassthrudate02,
         od.dtlpassthrudate03 as dtlpassthrudate03,
         od.dtlpassthrudate04 as dtlpassthrudate04,
         od.dtlpassthrudoll01 as dtlpassthrudoll01,
         od.dtlpassthrudoll02 as dtlpassthrudoll02
    from orderdtl od, orderdtlrcpt odr
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and odr.orderid(+) = in_orderid
     and odr.shipid(+) = in_shipid
     and odr.orderitem(+) =   in_orderitem
     and nvl(odr.orderlot(+),'(none)') = nvl(in_orderlot,'(none)')
   group by od.ORDERID,
         od.SHIPID,
         od.ITEM,
         od.LOTNUMBER,
         odr.lotnumber,
         odr.invstatus,
         odr.inventoryclass,
         nvl(od.dtlpassthrunum10,0),
         nvl(OD.qtyorder,0),
         od.DTLPASSTHRUchar01,
         od.DTLPASSTHRUchar02,
         od.DTLPASSTHRUchar03,
         od.DTLPASSTHRUchar04,
         od.DTLPASSTHRUchar05,
         od.DTLPASSTHRUchar06,
         od.DTLPASSTHRUchar07,
         od.DTLPASSTHRUchar08,
         od.DTLPASSTHRUchar09,
         od.DTLPASSTHRUchar10,
         od.DTLPASSTHRUchar11,
         od.DTLPASSTHRUchar12,
         od.DTLPASSTHRUchar13,
         od.DTLPASSTHRUchar14,
         od.DTLPASSTHRUchar15,
         od.DTLPASSTHRUchar16,
         od.DTLPASSTHRUchar17,
         od.DTLPASSTHRUchar18,
         od.DTLPASSTHRUchar19,
         od.DTLPASSTHRUchar20,
         od.DTLPASSTHRUchar21,
         od.DTLPASSTHRUchar22,
         od.DTLPASSTHRUchar23,
         od.DTLPASSTHRUchar24,
         od.DTLPASSTHRUchar25,
         od.DTLPASSTHRUchar26,
         od.DTLPASSTHRUchar27,
         od.DTLPASSTHRUchar28,
         od.DTLPASSTHRUchar29,
         od.DTLPASSTHRUchar30,
         od.DTLPASSTHRUchar31,
         od.DTLPASSTHRUchar32,
         od.DTLPASSTHRUchar33,
         od.DTLPASSTHRUchar34,
         od.DTLPASSTHRUchar35,
         od.DTLPASSTHRUchar36,
         od.DTLPASSTHRUchar37,
         od.DTLPASSTHRUchar38,
         od.DTLPASSTHRUchar39,
         od.DTLPASSTHRUchar40,
         od.dtlpassthrunum01,
         od.dtlpassthrunum02,
         od.dtlpassthrunum03,
         od.dtlpassthrunum04,
         od.dtlpassthrunum05,
         od.dtlpassthrunum06,
         od.dtlpassthrunum07,
         od.dtlpassthrunum08,
         od.dtlpassthrunum09,
         od.dtlpassthrunum10,
         od.dtlpassthrunum11,
         od.dtlpassthrunum12,
         od.dtlpassthrunum13,
         od.dtlpassthrunum14,
         od.dtlpassthrunum15,
         od.dtlpassthrunum16,
         od.dtlpassthrunum17,
         od.dtlpassthrunum18,
         od.dtlpassthrunum19,
         od.dtlpassthrunum20,
         od.lastuser,
         od.lastupdate,
         od.dtlpassthrudate01,
         od.dtlpassthrudate02,
         od.dtlpassthrudate03,
         od.dtlpassthrudate04,
         od.dtlpassthrudoll01,
         od.dtlpassthrudoll02
   order by od.dtlpassthrudate01,
            nvl(od.dtlpassthrunum10,0);

cursor curOrderDtlLineLotLineno(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2, in_lineno number) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.uom as uom,
         od.LOTNUMBER as lotnumber,
         nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
         nvl(OL.qty,nvl(OD.qtyrcvd,0)) as qtyrcvd,
         nvl(ol.DTLPASSTHRUchar01,od.DTLPASSTHRUchar01) as dtlpassthruchar01,
         nvl(ol.DTLPASSTHRUchar02,od.DTLPASSTHRUchar02) as dtlpassthruchar02,
         nvl(ol.DTLPASSTHRUchar03,od.DTLPASSTHRUchar03) as dtlpassthruchar03,
         nvl(ol.DTLPASSTHRUchar04,od.DTLPASSTHRUchar04) as dtlpassthruchar04,
         nvl(ol.DTLPASSTHRUchar05,od.DTLPASSTHRUchar05) as dtlpassthruchar05,
         nvl(ol.DTLPASSTHRUchar06,od.DTLPASSTHRUchar06) as dtlpassthruchar06,
         nvl(ol.DTLPASSTHRUchar07,od.DTLPASSTHRUchar07) as dtlpassthruchar07,
         nvl(ol.DTLPASSTHRUchar08,od.DTLPASSTHRUchar08) as dtlpassthruchar08,
         nvl(ol.DTLPASSTHRUchar09,od.DTLPASSTHRUchar09) as dtlpassthruchar09,
         nvl(ol.DTLPASSTHRUchar10,od.DTLPASSTHRUchar10) as dtlpassthruchar10,
         nvl(ol.DTLPASSTHRUchar11,od.DTLPASSTHRUchar11) as dtlpassthruchar11,
         nvl(ol.DTLPASSTHRUchar12,od.DTLPASSTHRUchar12) as dtlpassthruchar12,
         nvl(ol.DTLPASSTHRUchar13,od.DTLPASSTHRUchar13) as dtlpassthruchar13,
         nvl(ol.DTLPASSTHRUchar14,od.DTLPASSTHRUchar14) as dtlpassthruchar14,
         nvl(ol.DTLPASSTHRUchar15,od.DTLPASSTHRUchar15) as dtlpassthruchar15,
         nvl(ol.DTLPASSTHRUchar16,od.DTLPASSTHRUchar16) as dtlpassthruchar16,
         nvl(ol.DTLPASSTHRUchar17,od.DTLPASSTHRUchar17) as dtlpassthruchar17,
         nvl(ol.DTLPASSTHRUchar18,od.DTLPASSTHRUchar18) as dtlpassthruchar18,
         nvl(ol.DTLPASSTHRUchar19,od.DTLPASSTHRUchar19) as dtlpassthruchar19,
         nvl(ol.DTLPASSTHRUchar20,od.DTLPASSTHRUchar20) as dtlpassthruchar20,
         nvl(ol.DTLPASSTHRUchar21,od.DTLPASSTHRUchar21) as dtlpassthruchar21,
         nvl(ol.DTLPASSTHRUchar22,od.DTLPASSTHRUchar22) as dtlpassthruchar22,
         nvl(ol.DTLPASSTHRUchar23,od.DTLPASSTHRUchar23) as dtlpassthruchar23,
         nvl(ol.DTLPASSTHRUchar24,od.DTLPASSTHRUchar24) as dtlpassthruchar24,
         nvl(ol.DTLPASSTHRUchar25,od.DTLPASSTHRUchar25) as dtlpassthruchar25,
         nvl(ol.DTLPASSTHRUchar26,od.DTLPASSTHRUchar26) as dtlpassthruchar26,
         nvl(ol.DTLPASSTHRUchar27,od.DTLPASSTHRUchar27) as dtlpassthruchar27,
         nvl(ol.DTLPASSTHRUchar28,od.DTLPASSTHRUchar28) as dtlpassthruchar28,
         nvl(ol.DTLPASSTHRUchar29,od.DTLPASSTHRUchar29) as dtlpassthruchar29,
         nvl(ol.DTLPASSTHRUchar30,od.DTLPASSTHRUchar30) as dtlpassthruchar30,
         nvl(ol.DTLPASSTHRUchar31,od.DTLPASSTHRUchar31) as dtlpassthruchar31,
         nvl(ol.DTLPASSTHRUchar32,od.DTLPASSTHRUchar32) as dtlpassthruchar32,
         nvl(ol.DTLPASSTHRUchar33,od.DTLPASSTHRUchar33) as dtlpassthruchar33,
         nvl(ol.DTLPASSTHRUchar34,od.DTLPASSTHRUchar34) as dtlpassthruchar34,
         nvl(ol.DTLPASSTHRUchar35,od.DTLPASSTHRUchar35) as dtlpassthruchar35,
         nvl(ol.DTLPASSTHRUchar36,od.DTLPASSTHRUchar36) as dtlpassthruchar36,
         nvl(ol.DTLPASSTHRUchar37,od.DTLPASSTHRUchar37) as dtlpassthruchar37,
         nvl(ol.DTLPASSTHRUchar38,od.DTLPASSTHRUchar38) as dtlpassthruchar38,
         nvl(ol.DTLPASSTHRUchar39,od.DTLPASSTHRUchar39) as dtlpassthruchar39,
         nvl(ol.DTLPASSTHRUchar40,od.DTLPASSTHRUchar40) as dtlpassthruchar40,
         nvl(ol.DTLPASSTHRUNUM01,od.dtlpassthrunum01) as dtlpassthrunum01,
         nvl(ol.DTLPASSTHRUNUM02,od.dtlpassthrunum02) as dtlpassthrunum02,
         nvl(ol.DTLPASSTHRUNUM03,od.dtlpassthrunum03) as dtlpassthrunum03,
         nvl(ol.DTLPASSTHRUNUM04,od.dtlpassthrunum04) as dtlpassthrunum04,
         nvl(ol.DTLPASSTHRUNUM05,od.dtlpassthrunum05) as dtlpassthrunum05,
         nvl(ol.DTLPASSTHRUNUM06,od.dtlpassthrunum06) as dtlpassthrunum06,
         nvl(ol.DTLPASSTHRUNUM07,od.dtlpassthrunum07) as dtlpassthrunum07,
         nvl(ol.DTLPASSTHRUNUM08,od.dtlpassthrunum08) as dtlpassthrunum08,
         nvl(ol.DTLPASSTHRUNUM09,od.dtlpassthrunum09) as dtlpassthrunum09,
         nvl(ol.DTLPASSTHRUNUM10,od.dtlpassthrunum10) as dtlpassthrunum10,
         nvl(ol.DTLPASSTHRUNUM11,od.dtlpassthrunum11) as dtlpassthrunum11,
         nvl(ol.DTLPASSTHRUNUM12,od.dtlpassthrunum12) as dtlpassthrunum12,
         nvl(ol.DTLPASSTHRUNUM13,od.dtlpassthrunum13) as dtlpassthrunum13,
         nvl(ol.DTLPASSTHRUNUM14,od.dtlpassthrunum14) as dtlpassthrunum14,
         nvl(ol.DTLPASSTHRUNUM15,od.dtlpassthrunum15) as dtlpassthrunum15,
         nvl(ol.DTLPASSTHRUNUM16,od.dtlpassthrunum16) as dtlpassthrunum16,
         nvl(ol.DTLPASSTHRUNUM17,od.dtlpassthrunum17) as dtlpassthrunum17,
         nvl(ol.DTLPASSTHRUNUM18,od.dtlpassthrunum18) as dtlpassthrunum18,
         nvl(ol.DTLPASSTHRUNUM19,od.dtlpassthrunum19) as dtlpassthrunum19,
         nvl(ol.DTLPASSTHRUNUM20,od.dtlpassthrunum20) as dtlpassthrunum20,
         nvl(ol.LASTUSER,od.lastuser) as lastuser,
         nvl(ol.LASTUPDATE,od.lastupdate) as lastupdate,
         nvl(ol.DTLPASSTHRUDATE01,od.dtlpassthrudate01) as dtlpassthrudate01,
         nvl(ol.DTLPASSTHRUDATE02,od.dtlpassthrudate02) as dtlpassthrudate02,
         nvl(ol.DTLPASSTHRUDATE03,od.dtlpassthrudate03) as dtlpassthrudate03,
         nvl(ol.DTLPASSTHRUDATE04,od.dtlpassthrudate04) as dtlpassthrudate04,
         nvl(ol.DTLPASSTHRUDOLL01,od.dtlpassthrudoll01) as dtlpassthrudoll01,
         nvl(ol.DTLPASSTHRUDOLL02,od.dtlpassthrudoll02) as dtlpassthrudoll02,
         nvl(ol.QTYAPPROVED,0) as qtyapproved
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
     and in_lineno = nvl(OL.linenumber(+),nvl(OD.dtlpassthrunum10,0))
   order by nvl(ol.dtlpassthrudate01,od.dtlpassthrudate01),
            nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0));
OLL curorderDtlLineLotLineNo%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2) is
  select ORDERID,
         SHIPID,
         ITEM,
         '    ' as uom,
         '                              ' as lotnumber,
         linenumber,
         qty,
         qty as qtyrcvd,
         DTLPASSTHRUchar01,
         DTLPASSTHRUchar02,
         DTLPASSTHRUchar03,
         DTLPASSTHRUchar04,
         DTLPASSTHRUchar05,
         DTLPASSTHRUchar06,
         DTLPASSTHRUchar07,
         DTLPASSTHRUchar08,
         DTLPASSTHRUchar09,
         DTLPASSTHRUchar10,
         DTLPASSTHRUchar11,
         DTLPASSTHRUchar12,
         DTLPASSTHRUchar13,
         DTLPASSTHRUchar14,
         DTLPASSTHRUchar15,
         DTLPASSTHRUchar16,
         DTLPASSTHRUchar17,
         DTLPASSTHRUchar18,
         DTLPASSTHRUchar19,
         DTLPASSTHRUchar20,
         DTLPASSTHRUchar21,
         DTLPASSTHRUchar22,
         DTLPASSTHRUchar23,
         DTLPASSTHRUchar24,
         DTLPASSTHRUchar25,
         DTLPASSTHRUchar26,
         DTLPASSTHRUchar27,
         DTLPASSTHRUchar28,
         DTLPASSTHRUchar29,
         DTLPASSTHRUchar30,
         DTLPASSTHRUchar31,
         DTLPASSTHRUchar32,
         DTLPASSTHRUchar33,
         DTLPASSTHRUchar34,
         DTLPASSTHRUchar35,
         DTLPASSTHRUchar36,
         DTLPASSTHRUchar37,
         DTLPASSTHRUchar38,
         DTLPASSTHRUchar39,
         DTLPASSTHRUchar40,
         DTLPASSTHRUNUM01,
         DTLPASSTHRUNUM02,
         DTLPASSTHRUNUM03,
         DTLPASSTHRUNUM04,
         DTLPASSTHRUNUM05,
         DTLPASSTHRUNUM06,
         DTLPASSTHRUNUM07,
         DTLPASSTHRUNUM08,
         DTLPASSTHRUNUM09,
         DTLPASSTHRUNUM10,
         DTLPASSTHRUNUM11,
         DTLPASSTHRUNUM12,
         DTLPASSTHRUNUM13,
         DTLPASSTHRUNUM14,
         DTLPASSTHRUNUM15,
         DTLPASSTHRUNUM16,
         DTLPASSTHRUNUM17,
         DTLPASSTHRUNUM18,
         DTLPASSTHRUNUM19,
         DTLPASSTHRUNUM20,
         LASTUSER,
         LASTUPDATE,
         DTLPASSTHRUDATE01,
         DTLPASSTHRUDATE02,
         DTLPASSTHRUDATE03,
         DTLPASSTHRUDATE04,
         DTLPASSTHRUDOLL01,
         DTLPASSTHRUDOLL02,
         QTYAPPROVED
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(xdock,'N') = 'N'
   order by dtlpassthrudate01,
            linenumber;

cursor curOrderDtlLineNoLine(in_orderid number,in_shipid number,in_orderitem varchar2) is
  select ORDERID,
         SHIPID,
         ITEM,
         '                              ' as lotnumber,
         0 as linenumber,
         nvl(qtyorder,0) as qty,
         nvl(qtyrcvd,0) as qtyrcvd,
         DTLPASSTHRUchar01,
         DTLPASSTHRUchar02,
         DTLPASSTHRUchar03,
         DTLPASSTHRUchar04,
         DTLPASSTHRUchar05,
         DTLPASSTHRUchar06,
         DTLPASSTHRUchar07,
         DTLPASSTHRUchar08,
         DTLPASSTHRUchar09,
         DTLPASSTHRUchar10,
         DTLPASSTHRUchar11,
         DTLPASSTHRUchar12,
         DTLPASSTHRUchar13,
         DTLPASSTHRUchar14,
         DTLPASSTHRUchar15,
         DTLPASSTHRUchar16,
         DTLPASSTHRUchar17,
         DTLPASSTHRUchar18,
         DTLPASSTHRUchar19,
         DTLPASSTHRUchar20,
         DTLPASSTHRUchar21,
         DTLPASSTHRUchar22,
         DTLPASSTHRUchar23,
         DTLPASSTHRUchar24,
         DTLPASSTHRUchar25,
         DTLPASSTHRUchar26,
         DTLPASSTHRUchar27,
         DTLPASSTHRUchar28,
         DTLPASSTHRUchar29,
         DTLPASSTHRUchar30,
         DTLPASSTHRUchar31,
         DTLPASSTHRUchar32,
         DTLPASSTHRUchar33,
         DTLPASSTHRUchar34,
         DTLPASSTHRUchar35,
         DTLPASSTHRUchar36,
         DTLPASSTHRUchar37,
         DTLPASSTHRUchar38,
         DTLPASSTHRUchar39,
         DTLPASSTHRUchar40,
         DTLPASSTHRUNUM01,
         DTLPASSTHRUNUM02,
         DTLPASSTHRUNUM03,
         DTLPASSTHRUNUM04,
         DTLPASSTHRUNUM05,
         DTLPASSTHRUNUM06,
         DTLPASSTHRUNUM07,
         DTLPASSTHRUNUM08,
         DTLPASSTHRUNUM09,
         DTLPASSTHRUNUM10,
         DTLPASSTHRUNUM11,
         DTLPASSTHRUNUM12,
         DTLPASSTHRUNUM13,
         DTLPASSTHRUNUM14,
         DTLPASSTHRUNUM15,
         DTLPASSTHRUNUM16,
         DTLPASSTHRUNUM17,
         DTLPASSTHRUNUM18,
         DTLPASSTHRUNUM19,
         DTLPASSTHRUNUM20,
         LASTUSER,
         LASTUPDATE,
         DTLPASSTHRUDATE01,
         DTLPASSTHRUDATE02,
         DTLPASSTHRUDATE03,
         DTLPASSTHRUDATE04,
         DTLPASSTHRUDOLL01,
         DTLPASSTHRUDOLL02,
         nvl(qtyorder,0) as QTYAPPROVED
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and not exists (select * from orderdtlline
                      where orderdtl.orderid = orderdtlline.orderid
                        and orderdtl.shipid = orderdtlline.shipid
                        and orderdtl.item = orderdtlline.item
                        and nvl(orderdtlline.xdock,'N') = 'N')
   order by dtlpassthrudate01,
            linenumber;

cursor curOrderDtlRcpt(in_orderid number,in_shipid number,
 in_orderitem varchar2)
is
select orderid,'                              ' as lotnumber,invstatus,lpid,sum(qtyrcvd) as qtyrcvd
 from orderdtlrcpt
where orderid = in_orderid
  and shipid = in_shipid
  and orderitem = in_orderitem
group by orderid,'                              ',invstatus,lpid;

cursor curOrderDtlRcptLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select orderid,lotnumber,invstatus,lpid,sum(qtyrcvd) as qtyrcvd
 from orderdtlrcpt
where orderid = in_orderid
  and shipid = in_shipid
  and orderitem = in_orderitem
  and nvl(orderlot,'(null)') = nvl(in_orderlot,'(null)')
group by orderid,lotnumber,invstatus,lpid;
odr curOrderDtlRcptLot%rowtype;

cursor curOrderDtlRcptLotManu(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select O.orderid,O.lotnumber,O.invstatus,O.lpid,
       decode(P.manufacturedate, null, D.manufacturedate, P.manufacturedate) as manufacturedate, sum(O.qtyrcvd) as qtyrcvd
 from orderdtlrcpt O, plate P, deletedplate D
where O.orderid = in_orderid
  and O.shipid = in_shipid
  and O.orderitem = in_orderitem
  and nvl(O.orderlot,'(null)') = nvl(in_orderlot,'(null)')
  and O.lpid = P.lpid(+)
  and O.lpid = D.lpid(+)
group by O.orderid,O.lotnumber,O.invstatus,O.lpid, decode(P.manufacturedate, null, D.manufacturedate, P.manufacturedate)
order by O.orderid,O.lotnumber,decode(P.manufacturedate, null, D.manufacturedate, P.manufacturedate),O.invstatus,O.lpid;


cursor curOrderDtlRcptInvclass(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select orderid,lotnumber,invstatus,lpid,sum(qtyrcvd) as qtyrcvd, inventoryclass
 from orderdtlrcpt
where orderid = in_orderid
  and shipid = in_shipid
  and orderitem = in_orderitem
  and nvl(orderlot,'(null)') = nvl(in_orderlot,'(null)')
group by orderid,lotnumber,invstatus,lpid,inventoryclass;
odric curOrderDtlRcptInvclass%rowtype;

cursor curOrderDtlRcptSerial(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select orderid,lotnumber,serialnumber,useritem1,useritem2,useritem3,
       invstatus,lpid,sum(qtyrcvd) as qtyrcvd, sum(weight) as snweight, 0 as lineno
 from orderdtlrcpt
where orderid = in_orderid
  and shipid = in_shipid
  and orderitem = in_orderitem
  and nvl(orderlot,'(null)') = nvl(in_orderlot,'(null)')
group by orderid,lotnumber,serialnumber,useritem1,useritem2,useritem3,invstatus,lpid;
odrs curOrderDtlRcptSerial%rowtype;


cursor curOrderDtlRcptSerialLineno(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select o.orderid,o.lotnumber,o.serialnumber,o.useritem1,o.useritem2,o.useritem3,
       o.invstatus,o.lpid,sum(o.qtyrcvd) as qtyrcvd, sum(o.weight) as snweight,
       nvl(a.lineno,0) as lineno
 from orderdtlrcpt o, asncartondtl a
where o.orderid = in_orderid
  and o.shipid = in_shipid
  and o.orderitem = in_orderitem
  and nvl(o.orderlot,'(null)') = nvl(in_orderlot,'(null)')
  and o.orderid = a.orderid(+)
  and o.shipid = a.shipid(+)
  and o.orderitem = a.item(+)
  and nvl(o.orderlot,'(null)') = nvl(a.lotnumber(+),'(null)')
  and o.useritem3 = a.trackingno
group by o.orderid,o.lotnumber,o.serialnumber,o.useritem1,o.useritem2,o.useritem3,o.invstatus,o.lpid, lineno
order by lineno;

cursor curOrderDtlRcptSerialLinenoU(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select o.orderid,o.lotnumber,o.serialnumber,o.useritem1,o.useritem2,o.useritem3,
       o.invstatus,o.lpid,sum(o.qtyrcvd) as qtyrcvd, sum(o.weight) as snweight,999 as lineno
 from orderdtlrcpt o
where o.orderid = in_orderid
  and o.shipid = in_shipid
  and o.orderitem = in_orderitem
  and nvl(o.orderlot,'(null)') = nvl(in_orderlot,'(null)')
  and o.useritem3 not in (select trackingno from asncartondtl
                            where orderid = o.orderid and shipid = o.shipid
                              and item = o.orderitem
                              and lotnumber = nvl(o.orderlot,'(null)'))
group by o.orderid,o.lotnumber,o.serialnumber,o.useritem1,o.useritem2,o.useritem3,o.invstatus,o.lpid;

cursor curUPC(in_custid char, in_item char)
IS
 select *
   from custitemupcview
  where custid = in_custid
    and item = in_item;
upc curUPC%rowtype;

cursor curItem(in_custid char, in_item char)
IS
 select *
   from custitemview
  where custid = in_custid
    and item = in_item;
itm curItem%rowtype;

cursor curOrigOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by item,
            serialnumber,useritem1,useritem2,useritem3,
            substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30);
sp curShippingPlate%rowtype;

cursor C_CI(in_custid varchar2, in_item varchar2)
IS
select itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04,
       itmpassthruchar05, itmpassthruchar06, itmpassthruchar07, itmpassthruchar08,
       itmpassthruchar09, itmpassthruchar10, itmpassthrunum01, itmpassthrunum02,
       itmpassthrunum03, itmpassthrunum04, itmpassthrunum05, itmpassthrunum06,
       itmpassthrunum07, itmpassthrunum08, itmpassthrunum09, itmpassthrunum10
   from custitem
   where custid = in_custid
     and item = in_item;
CI C_CI%rowtype;

cursor sn_cur(in_orderid number, in_shipid number, in_orderitem varchar2)
is
  select substr(sys_connect_by_path(serialnumber,'~'),2) snlist
  from (
         select rownum rowno,serialnumber
         from (
              select  distinct serialnumber
                 from orderdtlrcpt
                where orderid = in_orderid
                  and shipid = in_shipid
                  and orderitem = in_orderitem
                  and serialnumber is not null
                  order by serialnumber
              )
       )
  where connect_by_isleaf = 1
  connect by prior rowno = rowno - 1
  start with rowno = 1;
sn sn_cur%rowtype;
cursor curOrderDtlRcptSerialInv(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
is
select orderid,item, lotnumber,serialnumber,useritem1,useritem2,useritem3,
       invstatus,sum(qtyrcvd) as qtyrcvd, sum(weight) as snweight,
       inventoryclass,lpid
 from orderdtlrcpt
where orderid = in_orderid
  and shipid = in_shipid
  and orderitem = in_orderitem
  and nvl(orderlot,'(null)') = nvl(in_orderlot,'(null)')
group by orderid,item,lotnumber,serialnumber,useritem1,useritem2,useritem3,invstatus,inventoryclass,lpid;
odrsinv curOrderDtlRcptSerialInv%rowtype;
cursor od_gtin(in_custid varchar2, in_item varchar2) is
   select substr(itemalias,1,14) as itemalias
     from custitemalias
     where custid = in_custid
       and item = in_item
       and aliasdesc like 'GTIN%';
ODG od_gtin%rowtype;
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
l_condition varchar2(200);
qtyRemain integer;
qtyOrigRemain integer;
qtyOrigLineNumber integer;
LineWeight orderdtl.weightrcvd%type;
LineCube orderdtl.cubercvd%type;
LineWeightGood orderdtl.weightrcvd%type;
LineCubeGood orderdtl.cubercvd%type;
LineWeightDmgd orderdtl.weightrcvd%type;
LineCubeDmgd orderdtl.cubercvd%type;
LineWeightOnHold orderdtl.weightrcvd%type;
LineCubeOnHold orderdtl.cubercvd%type;
strDebugYN char(1);
l_cnt integer := 0;
cntLines integer;
cntApprovals integer;
cntLineSeq integer;
qtyLineNumber integer;
qtyLineGood integer;
qtyLineDmgd integer;
qtyLineOnHold integer;
qtyNoSerialAccum integer;
qtyLineAccum integer;
qtyLineAccumGood integer;
qtyLineAccumDmgd integer;
qtyLineAccumOnHold integer;
qtyExpected integer;
qtyRcvd_invstatus plate.invstatus%type;
strCondition plate.condition%type;
l_loadno orderhdr.loadno%type;
l_custid orderhdr.custid%type;
no_dtl boolean;
l_facility orderhdr.tofacility%type;
strEdiPartner varchar2(25);
strEdiSender varchar2(25);
strEdiBatchRef varchar2(25);
strName carrier.name%type;
iLineseq integer;
strshippername orderhdr.shippername%type;
strShippercontact orderhdr.shippercontact%type;
strShipperaddr1 orderhdr.shipperaddr1%type;
strShipperaddr2 orderhdr.shipperaddr2%type;
strShippercity orderhdr.shippercity%type;
strShipperstate orderhdr.shipperstate%type;
strShipperpostalcode orderhdr.shipperpostalcode%type;
strShippercountrycode orderhdr.shippercountrycode%type;
strShipperphone orderhdr.shipperphone%type;
strShipperfax orderhdr.shipperfax%type;
strShipperemail orderhdr.shipperemail%type;

TYPE cur_type is REF CURSOR;
cl cur_type;
dManufacturedate plate.manufacturedate%type;
nullDate date := null;

type con_rcd is record (
  lotnumber       orderdtlrcpt.lotnumber%type,
  invstatus       orderdtlrcpt.invstatus%type,
  inventoryclass  orderdtlrcpt.inventoryclass%type,
  condition       plate.condition%type,
  qty             orderdtl.qtyorder%type
);

type con_tbl is table of con_rcd
     index by binary_integer;

cons con_tbl;
conx pls_integer;
confoundx pls_integer;

type lineqty_rcd is record (
  linenumber orderdtlline.linenumber%type,
  qtyapplied orderdtlline.qty%type
);

type lineqty_tbl is table of lineqty_rcd
     index by binary_integer;

lineqtys lineqty_tbl;
lqx pls_integer;
lqfoundx pls_integer;

rnide rcptnote944ideex%rowtype;
hdr orderhdr%rowtype;

procedure trace_msg(in_pos varchar2, in_msg varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg('947', in_pos, ' ', substr(in_msg,1,254),
    'T','947', strMsg);
  if length(in_msg) > 254 then
     zms.log_msg('947', in_pos || 'A', ' ', substr(in_msg,255,254),
       'T','947', strMsg);
  end if;
  if length(in_msg) > 508 then
     zms.log_msg('947', in_pos || 'B', ' ', substr(in_msg,509,254),
       'T','947', strMsg);
  end if;
  if length(in_msg) > 764 then
     zms.log_msg('947', in_pos || 'C', ' ', substr(in_msg,763,254),
       'T','947', strMsg);
  end if;
end;

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
--trace_msg('E', substr(in_text, 1, 60));
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  l_cnt := l_cnt + 1;
  zms.log_msg('947', 'I', ' ', to_char(l_cnt,'FM0009') || substr(in_text,((cntChar-1)*60)+1,60),
    'T','947', strMsg);
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

procedure create_944_hdr_data(oh IN OUT orderhdr%rowtype) is

strOrigInstructions varchar(512);
strInstructions varchar(512);
cntCharacters integer;
cx integer;
cntPallets integer;
strReceiptId varchar2(32);
strScac varchar2(4);

begin

debugmsg('create 944 hdr');

ld := null;
if nvl(oh.loadno,0) != 0 then
  debugmsg('fetch loads');
  open curLoads(oh.loadno);
  fetch curLoads into ld;
  close curLoads;
end if;

debugmsg('fetch shipper');
sh := null;
open curShipper(oh.shipper);
fetch curShipper into sh;
close curShipper;

debugmsg('fetch facility');
fa := null;
open curFacility(oh.tofacility);
fetch curFacility into fa;
close curFacility;

debugmsg('fetch rcptsum');
ds := null;
open curOrderDtlSum(oh.orderid,oh.shipid);
fetch curOrderDtlSum into ds;
close curOrderDtlSum;
debugmsg('qtyrcvd is ' || ds.qtyrcvd);

if oh.ordertype = 'Q' then
  debugmsg('flip shipper with shipto');
  oh.shippername := oh.shiptoname;
  oh.shippercontact := oh.shiptocontact;
  oh.shipperaddr1 := oh.shiptoaddr1;
  oh.shipperaddr2 := oh.shiptoaddr2;
  oh.shippercity := oh.shiptocity;
  oh.shipperstate := oh.shiptostate;
  oh.shipperpostalcode := oh.shiptopostalcode;
  oh.shippercountrycode := oh.shiptocountrycode;
  oh.shipperphone := oh.shiptophone;
  oh.shipperfax := oh.shiptofax;
  oh.shipperemail := oh.shiptoemail;
end if;

debugmsg('compute pallets');
cntPallets := zim7.pallet_count(oh.loadno,oh.custid,oh.tofacility,oh.orderid,oh.shipid, 'R');
debugmsg('pallet count is ' || cntPallets);

strOrigInstructions := rtrim(substr(oh.comment1,1,512));
cntCharacters := length(strOrigInstructions);
debugmsg('do instructions ' || cntCharacters || ' ' || strOrigInstructions);
strInstructions := '';
if cntCharacters != 0 then
  for cx in 1..cntCharacters
  loop
    if substr(strOrigInstructions,cx,1) in (CHR(10),CHR(13)) then
      strInstructions := strInstructions || ' ';
    else
      strInstructions := strInstructions || substr(strOrigInstructions,cx,1);
    end if;
  end loop;
  debugmsg('instruction is ' || strInstructions);
end if;

strReceiptId := oh.orderid || '-' || oh.shipid;
if oh.hdrpassthruchar13 is null then
  oh.hdrpassthruchar13 := fa.facility;
end if;

if oh.hdrpassthruchar12 is null then
  oh.hdrpassthruchar12 := cu.name;
end if;

if oh.hdrpassthruchar08 is null then
  oh.hdrpassthruchar08 := cu.custid;
end if;

if oh.prono is null then
  oh.prono := ld.prono;
end if;

begin
   select name, scac into strName, strScac
      from carrier
      where carrier = oh.carrier;
exception when others then
   strName := null;
   strScac := null;
end;
if nvl(in_shipper_addr_yn,'N') = 'Y' then
   strshippername := sh.name;
   strShippercontact := sh.contact;
   strShipperaddr1 := sh.addr1;
   strShipperaddr2 := sh.addr2;
   strShippercity := sh.city;
   strShipperstate := sh.state;
   strShipperpostalcode := sh.postalcode;
   strShippercountrycode := sh.countrycode;
   strShipperphone := sh.phone;
   strShipperfax := sh.fax;
   strShipperemail := sh.email;
else
  strshippername := oh.shippername;
  strShippercontact := oh.shippercontact;
  strShipperaddr1 := oh.shipperaddr1;
  strShipperaddr2 := oh.shipperaddr2;
  strShippercity := oh.shippercity;
  strShipperstate := oh.shipperstate;
  strShipperpostalcode := oh.shipperpostalcode;
  strShippercountrycode := oh.shippercountrycode;
  strShipperphone := oh.shipperphone;
  strShipperfax := oh.shipperfax;
  strShipperemail := oh.shipperemail;

end if;

debugmsg('create header data');
execute immediate 'insert into RCPT_NOTE_944_HDR_' || strSuffix ||
' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:COMPANY,:WAREHOUSE,:CUST_ORDERID,' ||
' :CUST_SHIPID,:SHIPFROM,:SHIPFROMID,:RECEIPT_DATE,:VENDOR,:VENDOR_DESC,' ||
' :BILL_OF_LADING,:CARRIER,:ROUTING,:PO,:ORDER_TYPE,:QTYORDER,:QTYRCVD,' ||
' :QTYRCVDGOOD,:QTYRCVDDMGD,:REPORTING_CODE,:SOME_DATE,:UNLOAD_DATE,' ||
' :WHSE_RECEIPT_NUM,:TRANSMETH_TYPE,:PACKER_NUMBER,:VENDOR_ORDER_NUM,' ||
' :WAREHOUSE_NAME,:WAREHOUSE_ID,:DEPOSITOR_NAME,:DEPOSITOR_ID,' ||
' :HDRPASSTHRUCHAR01,:HDRPASSTHRUCHAR02,:HDRPASSTHRUCHAR03,:HDRPASSTHRUCHAR04,' ||
' :HDRPASSTHRUCHAR05,:HDRPASSTHRUCHAR06,:HDRPASSTHRUCHAR07,:HDRPASSTHRUCHAR08,' ||
' :HDRPASSTHRUCHAR09,:HDRPASSTHRUCHAR10,:HDRPASSTHRUCHAR11,:HDRPASSTHRUCHAR12,' ||
' :HDRPASSTHRUCHAR13,:HDRPASSTHRUCHAR14,:HDRPASSTHRUCHAR15,:HDRPASSTHRUCHAR16,' ||
' :HDRPASSTHRUCHAR17,:HDRPASSTHRUCHAR18,:HDRPASSTHRUCHAR19,:HDRPASSTHRUCHAR20,' ||
' :HDRPASSTHRUCHAR21,:HDRPASSTHRUCHAR22,:HDRPASSTHRUCHAR23,:HDRPASSTHRUCHAR24,' ||
' :HDRPASSTHRUCHAR25,:HDRPASSTHRUCHAR26,:HDRPASSTHRUCHAR27,:HDRPASSTHRUCHAR28,' ||
' :HDRPASSTHRUCHAR29,:HDRPASSTHRUCHAR30,:HDRPASSTHRUCHAR31,:HDRPASSTHRUCHAR32,' ||
' :HDRPASSTHRUCHAR33,:HDRPASSTHRUCHAR34,:HDRPASSTHRUCHAR35,:HDRPASSTHRUCHAR36,' ||
' :HDRPASSTHRUCHAR37,:HDRPASSTHRUCHAR38,:HDRPASSTHRUCHAR39,:HDRPASSTHRUCHAR40,' ||
' :HDRPASSTHRUCHAR41,:HDRPASSTHRUCHAR42,:HDRPASSTHRUCHAR43,:HDRPASSTHRUCHAR44,' ||
' :HDRPASSTHRUCHAR45,:HDRPASSTHRUCHAR46,:HDRPASSTHRUCHAR47,:HDRPASSTHRUCHAR48,' ||
' :HDRPASSTHRUCHAR49,:HDRPASSTHRUCHAR50,:HDRPASSTHRUCHAR51,:HDRPASSTHRUCHAR52,' ||
' :HDRPASSTHRUCHAR53,:HDRPASSTHRUCHAR54,:HDRPASSTHRUCHAR55,:HDRPASSTHRUCHAR56,' ||
' :HDRPASSTHRUCHAR57,:HDRPASSTHRUCHAR58,:HDRPASSTHRUCHAR59,:HDRPASSTHRUCHAR60,' ||
' :HDRPASSTHRUNUM01,:HDRPASSTHRUNUM02,:HDRPASSTHRUNUM03,:HDRPASSTHRUNUM04,:HDRPASSTHRUNUM05,' ||
' :HDRPASSTHRUNUM06,:HDRPASSTHRUNUM07,:HDRPASSTHRUNUM08,:HDRPASSTHRUNUM09,' ||
' :HDRPASSTHRUNUM10,:HDRPASSTHRUDATE01,:HDRPASSTHRUDATE02,:HDRPASSTHRUDATE03,' ||
' :HDRPASSTHRUDATE04,:HDRPASSTHRUDOLL01,:HDRPASSTHRUDOLL02,:PRONO,' ||
' :TRAILER,:SEAL,:PALLETCOUNT,:FACILITY,:SHIPPERNAME,:SHIPPERCONTACT,' ||
' :SHIPPERADDR1,:SHIPPERADDR2,:SHIPPERCITY,:SHIPPERSTATE,:SHIPPERPOSTALCODE,' ||
' :SHIPPERCOUNTRYCODE,:SHIPPERPHONE,:SHIPPERFAX,:SHIPPEREMAIL,:BILLTONAME,' ||
' :BILLTOCONTACT,:BILLTOADDR1,:BILLTOADDR2,:BILLTOCITY,:BILLTOSTATE,' ||
' :BILLTOPOSTALCODE,:BILLTOCOUNTRYCODE,:BILLTOPHONE,:BILLTOFAX,:BILLTOEMAIL,' ||
' :RMA,:ORDERTYPE,:RETURNTRACKINGNO,:STATUSUSER,:INSTRUCTIONS, :CARRIERNAME, ' ||
' :REFERENCE, :SHIPPER, :SUPPLIER,:SCAC,:WEIGHTRCVD,:CUBERCVD,:WEIGHTRCVDGOOD, '||
' :CUBRCVDGOOD,:WEIGHTRCVDDMGD,:CUBERCVDDMGD,:SHIPTERMS,:DOORLOC  )'
using oh.CUSTID,oh.LOADNO,oh.ORDERID,oh.SHIPID,'','',
oh.reference,oh.hdrpassthruchar03,oh.hdrpassthruchar19,oh.hdrpassthruchar04,ld.rcvddate,
oh.shipper,sh.name,oh.BILLOFLADING,oh.CARRIER,oh.hdrpassthruchar18,
oh.PO,oh.ORDERTYPE,oh.QTYORDER,ds.QTYRCVD,ds.QTYRCVDGOOD,ds.QTYRCVDDMGD,
oh.hdrpassthruchar19,sysdate,oh.statusupdate,strReceiptId,
oh.shiptype,oh.hdrpassthruchar11,oh.hdrpassthruchar12,fa.name,
oh.hdrpassthruchar13,oh.hdrpassthruchar12,oh.hdrpassthruchar08,
oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,oh.HDRPASSTHRUCHAR03,oh.HDRPASSTHRUCHAR04,
oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,oh.HDRPASSTHRUCHAR07,oh.HDRPASSTHRUCHAR08,
oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,oh.HDRPASSTHRUCHAR11,oh.HDRPASSTHRUCHAR12,
oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,oh.HDRPASSTHRUCHAR15,oh.HDRPASSTHRUCHAR16,
oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,oh.HDRPASSTHRUCHAR19,oh.HDRPASSTHRUCHAR20,
oh.HDRPASSTHRUCHAR21,oh.HDRPASSTHRUCHAR22,oh.HDRPASSTHRUCHAR23,oh.HDRPASSTHRUCHAR24,
oh.HDRPASSTHRUCHAR25,oh.HDRPASSTHRUCHAR26,oh.HDRPASSTHRUCHAR27,oh.HDRPASSTHRUCHAR28,
oh.HDRPASSTHRUCHAR29,oh.HDRPASSTHRUCHAR30,oh.HDRPASSTHRUCHAR31,oh.HDRPASSTHRUCHAR32,
oh.HDRPASSTHRUCHAR33,oh.HDRPASSTHRUCHAR34,oh.HDRPASSTHRUCHAR35,oh.HDRPASSTHRUCHAR36,
oh.HDRPASSTHRUCHAR37,oh.HDRPASSTHRUCHAR38,oh.HDRPASSTHRUCHAR39,oh.HDRPASSTHRUCHAR40,
oh.HDRPASSTHRUCHAR41,oh.HDRPASSTHRUCHAR42,oh.HDRPASSTHRUCHAR43,oh.HDRPASSTHRUCHAR44,
oh.HDRPASSTHRUCHAR45,oh.HDRPASSTHRUCHAR46,oh.HDRPASSTHRUCHAR47,oh.HDRPASSTHRUCHAR48,
oh.HDRPASSTHRUCHAR49,oh.HDRPASSTHRUCHAR50,oh.HDRPASSTHRUCHAR51,oh.HDRPASSTHRUCHAR52,
oh.HDRPASSTHRUCHAR53,oh.HDRPASSTHRUCHAR54,oh.HDRPASSTHRUCHAR55,oh.HDRPASSTHRUCHAR56,
oh.HDRPASSTHRUCHAR57,oh.HDRPASSTHRUCHAR58,oh.HDRPASSTHRUCHAR59,oh.HDRPASSTHRUCHAR60,
oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,oh.HDRPASSTHRUNUM03,oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,
oh.HDRPASSTHRUNUM06,oh.HDRPASSTHRUNUM07,oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,
oh.HDRPASSTHRUNUM10,oh.HDRPASSTHRUDATE01,oh.HDRPASSTHRUDATE02,oh.HDRPASSTHRUDATE03,
oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,oh.HDRPASSTHRUDOLL02,oh.prono,
ld.TRAILER,ld.SEAL,cntPallets,oh.tofacility,strSHIPPERNAME,strSHIPPERCONTACT,
strSHIPPERADDR1,strSHIPPERADDR2,strSHIPPERCITY,strSHIPPERSTATE,strSHIPPERPOSTALCODE,
strSHIPPERCOUNTRYCODE,strSHIPPERPHONE,strSHIPPERFAX,strSHIPPEREMAIL,
oh.BILLTONAME,oh.BILLTOCONTACT,oh.BILLTOADDR1,oh.BILLTOADDR2,oh.BILLTOCITY,
oh.BILLTOSTATE,oh.BILLTOPOSTALCODE,oh.BILLTOCOUNTRYCODE,oh.BILLTOPHONE,
oh.BILLTOFAX,oh.BILLTOEMAIL,oh.RMA,oh.ORDERTYPE,oh.RETURNTRACKINGNO,
oh.STATUSUSER,strINSTRUCTIONS,strName, oh.reference, oh.shipper, oh.shipper,
strScac,ds.weightrcvd,ds.cubercvd,ds.weightrcvdgood,ds.cubercvdgood,
ds.weightrcvddmgd,ds.cubercvddmgd,oh.shipterms,ld.doorloc;

iLineseq := 0;
end;

function get_944_item_ui2(in_orderid number, in_shipid number, in_item varchar2,
                            in_lotnumber varchar2 )
return varchar2 is

   cursor curOrderDtlRcpt is
      select useritem2
        from orderdtlrcpt
       where orderid = in_orderid
         and shipid = in_shipid
         and item = in_item
         and nvl(in_lotnumber,'(none)') = nvl(lotnumber,'(none)');
   retval varchar2(20);
begin
   retval := null;
   open curOrderDtlRcpt;
   fetch curOrderDtlRcpt into retval;
   close curOrderDtlRcpt;
   return retval;
end get_944_item_ui2;

procedure insert_944_serial_data(oh orderhdr%rowtype,od curOrderDtlLot%rowtype,
                                 ol curOrderDtlLineLot%rowtype) is
begin

debugmsg('insert_944_serial_data');
iLineseq := iLineseq + 1;
upc := null;
open curUpc(od.custid,od.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(od.custid,od.item);
fetch curItem into Itm;
close curItem;
LineWeight := zci.item_weight(od.custid,od.item,od.uom) * qtyLineNumber;
LineCube := zci.item_cube(od.custid,od.item,od.uom) * qtyLineNumber;
LineWeightGood := zci.item_weight(od.custid,od.item,od.uom) * qtyLineGood;
LineCubeGood := zci.item_cube(od.custid,od.item,od.uom) * qtyLineGood;
LineWeightDmgd := zci.item_weight(od.custid,od.item,od.uom) * qtyLineDmgd;
LineCubeDmgd := zci.item_cube(od.custid,od.item,od.uom) * qtyLineDmgd;
LineWeightOnHold := zci.item_weight(od.custid,od.item,od.uom) * qtyLineOnHold;
LineCubeOnHold := zci.item_cube(od.custid,od.item,od.uom) * qtyLineOnHold;
sn := null;
open sn_cur(od.orderid, od.shipid, od.item);
fetch sn_cur into sn;
close sn_cur;

CI := null;
open C_CI(od.custid, od.item);
fetch C_CI into CI;
close C_CI;

ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE, :INVSTATUS, :LINK_LOTNUMBER, '||
':LINESEQ, :SUBPART,:CUBERCVDDMGD, ' ||
':ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', od.CUSTID);
dbms_sql.bind_variable(curFunc, ':ORDERID', od.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', od.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', qtyLineNumber);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', qtyLineGood);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', qtyLineDmgd);
dbms_sql.bind_variable(curFunc, ':QTYORDER', ol.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', ol.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', ol.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', ol.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', ol.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', ol.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', ol.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', ol.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', ol.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', ol.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', ol.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', ol.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', ol.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', ol.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', ol.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', ol.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', ol.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', ol.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', ol.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', ol.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', ol.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', ol.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', ol.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', ol.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', ol.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', ol.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', ol.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', ol.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', ol.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', ol.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', ol.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', qtyRcvd_invstatus);
if nvl(in_list_serialnumber_yn,'N') = 'Y' then
  dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', sn.snlist);
else
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', rnide.serialnumber);
end if;
dbms_sql.bind_variable(curFunc, ':USERITEM1', rnide.useritem1);
dbms_sql.bind_variable(curFunc, ':USERITEM2', rnide.useritem2);
dbms_sql.bind_variable(curFunc, ':USERITEM3', rnide.useritem3);
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', rnide.orig_line_number);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', rnide.condition);
dbms_sql.bind_variable(curFunc, ':INVCLASS', '');
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', nullDate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(od.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(od.orderid, od.shipid, od.item, od.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', LineCubeDmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end insert_944_serial_data;

procedure insert_944_line_data(oh orderhdr%rowtype, od curOrderDtlLot%rowtype,
                               ol curOrderDtlLineLot%rowtype, in_invclass varchar2,
                               in_manufacturedate date) is
begin

debugmsg('insert_944_line_data');
upc := null;
iLineseq := iLineseq + 1;
open curUpc(od.custid,od.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(od.custid,od.item);
fetch curItem into Itm;
close curItem;
LineWeight := zci.item_weight(od.custid,od.item,od.uom) * qtyLineNumber;
LineCube := zci.item_cube(od.custid,od.item,od.uom) * qtyLineNumber;
LineWeightGood := zci.item_weight(od.custid,od.item,od.uom) * qtyLineGood;
LineCubeGood := zci.item_cube(od.custid,od.item,od.uom) * qtyLineGood;
LineWeightDmgd := zci.item_weight(od.custid,od.item,od.uom) * qtyLineDmgd;
LineCubeDmgd := zci.item_cube(od.custid,od.item,od.uom) * qtyLineDmgd;
LineWeightOnHold := zci.item_weight(od.custid,od.item,od.uom) * qtyLineOnHold;
LineCubeOnHold := zci.item_cube(od.custid,od.item,od.uom) * qtyLineOnHold;
CI := null;
open C_CI(od.custid, od.item);
fetch C_CI into CI;
close C_CI;
ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE, :INVSTATUS, :LINK_LOTNUMBER, '||
':LINESEQ, :SUBPART, :CUBERCVDDMGD, :ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', od.CUSTID);
dbms_sql.bind_variable(curFunc, ':ORDERID', od.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', od.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', qtyLineNumber);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', qtyLineGood);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', qtyLineDmgd);
dbms_sql.bind_variable(curFunc, ':QTYORDER', ol.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', ol.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', ol.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', ol.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', ol.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', ol.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', ol.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', ol.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', ol.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', ol.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', ol.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', ol.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', ol.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', ol.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', ol.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', ol.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', ol.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', ol.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', ol.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', ol.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', ol.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', ol.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', ol.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', ol.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', ol.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', ol.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', ol.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', ol.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', ol.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', ol.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', ol.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', '');
dbms_sql.bind_variable(curFunc, ':USERITEM1', '');
dbms_sql.bind_variable(curFunc, ':USERITEM2', '');
dbms_sql.bind_variable(curFunc, ':USERITEM3', '');
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', 0);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', '');
dbms_sql.bind_variable(curFunc, ':INVCLASS', in_invclass);
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', in_manufacturedate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(od.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(od.orderid, od.shipid, od.item, od.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', LineCubeDmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end insert_944_line_data;

procedure insert_944_invstatus_data(oh orderhdr%rowtype, odl curOrderDtlLineLot%rowtype,
                               odr curOrderDtlInvsts%rowtype) is
begin

debugmsg('insert_944_invstatus_data');
if (odr.qtyrcvd = 0)  and
   (upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'N') then
  return;
end if;
upc := null;
iLineseq := iLineseq + 1;
open curUpc(oh.custid,odl.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(oh.custid,odl.item);
fetch curItem into Itm;
close curItem;
LineWeight := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvd;
LineCube := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvd;
LineWeightGood := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvdgood;
LineCubeGood := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvdgood;
LineWeightDmgd := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvddmgd;
LineCubeDmgd := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvddmgd;
if odr.invstatus = 'OH' then
  qtyLineOnHold := odr.qtyrcvd;
  LineWeightOnHold := LineWeight;
  LineCubeOnHold := LineCube;
else
  qtyLineOnHold := 0;
  LineWeightOnHold := 0;
  LineCubeOnHold := 0;
end if;
CI := null;
open C_CI(oh.custid, odl.item);
fetch C_CI into CI;
close C_CI;
ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE, :INVSTATUS, :LINK_LOTNUMBER, ' ||
':LINESEQ, :SUBPART, :CUBERCVDDMGD, :ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.custid);
dbms_sql.bind_variable(curFunc, ':ORDERID', odl.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', odl.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', odl.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', odl.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', odl.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', odl.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', odr.qtyrcvd);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', odr.qtyrcvdgood);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', odr.qtyrcvddmgd);
dbms_sql.bind_variable(curFunc, ':QTYORDER', odr.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', odl.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', odl.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', odl.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', odl.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', odl.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', odl.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', odl.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', odl.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', odl.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', odl.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', odl.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', odl.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', odl.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', odl.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', odl.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', odl.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', odl.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', odl.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', odl.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', odl.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', odl.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', odl.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', odl.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', odl.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', odl.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', odl.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', odl.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', odl.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', odl.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', odl.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', odl.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', odl.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', odl.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', odl.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', odl.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', odl.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', odl.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', odl.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', odl.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', odl.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', odl.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', odl.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', odl.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', odl.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', odl.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', odl.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', odl.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', odl.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', odl.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', odl.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', odl.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', odl.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', odl.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', odl.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', odl.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', odl.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', odl.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', odl.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', odl.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', odl.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', odl.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', odl.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', odl.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', odl.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', odl.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', odl.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', odl.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', '');
dbms_sql.bind_variable(curFunc, ':USERITEM1', '');
dbms_sql.bind_variable(curFunc, ':USERITEM2', '');
dbms_sql.bind_variable(curFunc, ':USERITEM3', '');
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', 0);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', '');
dbms_sql.bind_variable(curFunc, ':INVCLASS', '');
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', nullDate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', odr.invstatus);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(odl.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(odl.orderid, odl.shipid, odl.item, odl.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', LineCubeDmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end insert_944_invstatus_data;

procedure insert_944_noline_data(oh orderhdr%rowtype, od curOrderDtlNoLine%rowtype, ol curOrderDtlLineNoLine%rowtype) is
begin

debugmsg('insert_944_noline_data');
upc := null;
open curUpc(od.custid,od.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(od.custid,od.item);
fetch curItem into Itm;
close curItem;
CI := null;
open C_CI(od.custid, od.item);
fetch C_CI into CI;
close C_CI;
ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;
LineWeight := zci.item_weight(od.custid,od.item,od.uom) * qtyLineNumber;
LineCube := zci.item_cube(od.custid,od.item,od.uom) * qtyLineNumber;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE, :INVSTATUS, :LINK_LOTNUMBER, '||
':LINESEQ, :SUBPART,:CUBERCVDDMGD,:ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', od.CUSTID);
dbms_sql.bind_variable(curFunc, ':ORDERID', od.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', od.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', qtyLineNumber);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', od.QTYRCVDGOOD);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', od.CUBERCVDGOOD);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', od.QTYRCVDDMGD);
dbms_sql.bind_variable(curFunc, ':QTYORDER', ol.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', ol.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', ol.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', ol.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', ol.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', ol.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', ol.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', ol.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', ol.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', ol.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', ol.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', ol.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', ol.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', ol.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', ol.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', ol.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', ol.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', ol.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', ol.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', ol.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', ol.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', ol.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', ol.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', ol.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', ol.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', ol.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', ol.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', ol.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', ol.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', ol.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', ol.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', '');
dbms_sql.bind_variable(curFunc, ':USERITEM1', '');
dbms_sql.bind_variable(curFunc, ':USERITEM2', '');
dbms_sql.bind_variable(curFunc, ':USERITEM3', '');
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', 0);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', '');
dbms_sql.bind_variable(curFunc, ':INVCLASS', '');
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', nullDate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(od.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(od.orderid, od.shipid, od.item, od.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', od.cubercvddmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end insert_944_noline_data;

procedure insert_944_instat_rtn_data(oh orderhdr%rowtype, odl curOrderDtlLineLot%rowtype,
                               odr curOrderDtlInvstsRtn%rowtype) is
begin

debugmsg('insert_944_instat_rtn_data');
if (odr.qtyrcvd = 0)  and
   (upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'N') then
  return;
end if;
upc := null;
open curUpc(oh.custid,odl.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(oh.custid,odl.item);
fetch curItem into Itm;
close curItem;
LineWeight := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvd;
LineCube := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvd;
LineWeightGood := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvdgood;
LineCubeGood := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvdgood;
LineWeightDmgd := zci.item_weight(oh.custid,odl.item,odl.uom) * odr.qtyrcvddmgd;
LineCubeDmgd := zci.item_cube(oh.custid,odl.item,odl.uom) * odr.qtyrcvddmgd;
if odr.invstatus = 'OH' then
  qtyLineOnHold := odr.qtyrcvd;
  LineWeightOnHold := LineWeight;
  LineCubeOnHold := LineCube;
else
  qtyLineOnHold := 0;
  LineWeightOnHold := 0;
  LineCubeOnHold := 0;
end if;
CI := null;
open C_CI(oh.custid, odl.item);
fetch C_CI into CI;
close C_CI;
ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;
debugmsg('++++++++++++++++ ' || odr.invclass);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE, :INVSTATUS, :LINK_LOTNUMBER, '||
':LINESEQ, :SUBPART,:CUBERCVDDMGD,  :ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.custid);
dbms_sql.bind_variable(curFunc, ':ORDERID', odl.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', odl.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', odl.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', odl.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', odl.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', odl.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', odr.qtyrcvd);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', odr.qtyrcvdgood);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', odr.qtyrcvddmgd);
dbms_sql.bind_variable(curFunc, ':QTYORDER', odr.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', odl.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', odl.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', odl.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', odl.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', odl.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', odl.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', odl.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', odl.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', odl.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', odl.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', odl.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', odl.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', odl.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', odl.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', odl.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', odl.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', odl.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', odl.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', odl.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', odl.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', odl.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', odl.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', odl.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', odl.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', odl.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', odl.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', odl.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', odl.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', odl.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', odl.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', odl.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', odl.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', odl.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', odl.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', odl.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', odl.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', odl.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', odl.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', odl.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', odl.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', odl.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', odl.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', odl.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', odl.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', odl.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', odl.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', odl.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', odl.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', odl.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', odl.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', odl.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', odl.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', odl.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', odl.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', odl.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', odl.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', odl.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', odl.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', odl.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', odl.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', odl.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', odl.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', odl.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', odl.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', odl.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', odl.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', odl.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', '');
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', '');
dbms_sql.bind_variable(curFunc, ':USERITEM1', '');
dbms_sql.bind_variable(curFunc, ':USERITEM2', '');
dbms_sql.bind_variable(curFunc, ':USERITEM3', '');
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', 0);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', '');
dbms_sql.bind_variable(curFunc, ':INVCLASS', odr.invclass);
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', nullDate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', odr.invstatus);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(odl.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(oh.orderid, oh.shipid, odl.item, odl.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', LineCubeDmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end insert_944_instat_rtn_data;

procedure insert_944_dtlrcpt_data(oh orderhdr%rowtype,
                                  od curOrderDtlLot%rowtype,
                                  ol curOrderDtlLineLot%rowtype,
                                  odrsinv curOrderDtlRcptSerialInv%rowtype) is
begin
debugmsg('insert_944_dtlrcpt_data');
upc := null;
iLineseq := iLineseq + 1;
open curUpc(od.custid,od.item);
fetch curUpc into upc;
close curUpc;
itm := null;
open curItem(od.custid,od.item);
fetch curItem into Itm;
close curItem;
LineWeight := zci.item_weight(od.custid,od.item,od.uom) * qtyLineNumber;
LineCube := zci.item_cube(od.custid,od.item,od.uom) * qtyLineNumber;
LineWeightGood := zci.item_weight(od.custid,od.item,od.uom) * qtyLineGood;
LineCubeGood := zci.item_cube(od.custid,od.item,od.uom) * qtyLineGood;
LineWeightDmgd := zci.item_weight(od.custid,od.item,od.uom) * qtyLineDmgd;
LineCubeDmgd := zci.item_cube(od.custid,od.item,od.uom) * qtyLineDmgd;
LineWeightOnHold := zci.item_weight(od.custid,od.item,od.uom) * qtyLineOnHold;
LineCubeOnHold := zci.item_cube(od.custid,od.item,od.uom) * qtyLineOnHold;
open sn_cur(od.orderid, od.shipid, od.item);
fetch sn_cur into sn;
close sn_cur;

CI := null;
open C_CI(od.custid, od.item);
fetch C_CI into CI;
close C_CI;

ODG := null;
open od_gtin(od.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into rcpt_note_944_dtl_' || strSuffix ||
' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
':DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
':DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
':DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
':DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
':DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
':DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
':DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :MANUFACTUREDATE,' ||
':INVSTATUS, :LINK_LOTNUMBER, :LINESEQ, :SUBPART,:CUBERCVDDMGD,' ||
':ITMPASSTHRUCHAR01, :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, ' ||
':ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, '||
':ITMPASSTHRUCHAR09, :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, :ITMPASSTHRUNUM08, '||
':ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10,:GTIN)',
          dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':CUSTID', od.CUSTID);
dbms_sql.bind_variable(curFunc, ':ORDERID', od.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', od.SHIPID);
dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':UPC', upc.UPC);
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.LOTNUMBER);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':QTYRCVD', odrsinv.QTYRCVD);
dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', qtyLineGood);
dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', qtyLineDmgd);
dbms_sql.bind_variable(curFunc, ':QTYORDER', ol.QTY);
dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', ol.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', ol.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', ol.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', ol.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', ol.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', ol.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', ol.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', ol.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', ol.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', ol.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', ol.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', ol.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', ol.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', ol.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', ol.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', ol.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', ol.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', ol.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', ol.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', ol.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', ol.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', ol.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', ol.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', ol.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', ol.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', ol.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', ol.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', ol.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', ol.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', ol.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':QTYONHOLD', qtyLineOnHold);
dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', rnide.qtyrcvd_invstatus);
if nvl(in_list_serialnumber_yn,'N') = 'Y' then
  dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', sn.snlist);
else
dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', odrsinv.serialnumber);
end if;
dbms_sql.bind_variable(curFunc, ':USERITEM1',  odrsinv.useritem1);
dbms_sql.bind_variable(curFunc, ':USERITEM2',  odrsinv.useritem2);
dbms_sql.bind_variable(curFunc, ':USERITEM3',  odrsinv.useritem3);
dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', rnide.orig_line_number);
dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', oh.statusupdate);
dbms_sql.bind_variable(curFunc, ':CONDITION', rnide.condition);
dbms_sql.bind_variable(curFunc, ':INVCLASS',  odrsinv.inventoryclass);
dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', nullDate);
dbms_sql.bind_variable(curFunc, ':INVSTATUS', odrsinv.invstatus);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', nvl(ol.LOTNUMBER,'(none)'));
dbms_sql.bind_variable(curFunc, ':LINESEQ', iLineseq);
dbms_sql.bind_variable(curFunc, ':SUBPART', get_944_item_ui2(od.orderid, od.shipid, od.item, od.lotnumber));
dbms_sql.bind_variable(curFunc, ':CUBERCVDDMGD', LineCubeDmgd);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR01', CI.itmpassthruchar01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR02', CI.itmpassthruchar02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR03', CI.itmpassthruchar03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR04', CI.itmpassthruchar04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR05', CI.itmpassthruchar05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR06', CI.itmpassthruchar06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR07', CI.itmpassthruchar07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR08', CI.itmpassthruchar08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR09', CI.itmpassthruchar09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUCHAR10', CI.itmpassthruchar10);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM01', CI.itmpassthrunum01);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM02', CI.itmpassthrunum02);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM03', CI.itmpassthrunum03);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM04', CI.itmpassthrunum04);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM05', CI.itmpassthrunum05);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM06', CI.itmpassthrunum06);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM07', CI.itmpassthrunum07);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM08', CI.itmpassthrunum08);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM09', CI.itmpassthrunum09);
dbms_sql.bind_variable(curFunc, ':ITMPASSTHRUNUM10', CI.itmpassthrunum10);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end insert_944_dtlrcpt_data;

procedure create_944_line_data_receipts(oh orderhdr%rowtype) is

iLineno char(1);
bZeroLine boolean;
iLineCnt integer;
iLineQty integer;
iLinenoCnt integer;
begin
iLineno := 'N';
if cu.asnlineno = 'Y' then -- only orders asn tracking numbers provided
   select count(1) into iLinenoCnt
      from asncartondtl
      where orderid = oh.orderid
      and shipid = oh.shipid
      and nvl(lineno,0) != 0;
   if iLinenoCnt > 0 then
      iLineno := 'Y';
   end if;
end if;

debugmsg('create 944 line data receipts');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  odrs := null;
  if ilineno = 'Y' then
     -- first get the asn receiving pallets
     debugmsg('lineno ' || oh.orderid || ' ' || oh.shipid || ' ' || od.item || ' ' || od.lotnumber);
      for odrs in  curOrderDtlRcptSerialLineno(oh.orderid,oh.shipid,od.item,od.lotnumber) loop
        if odrs.lineno = 0 then
           select max(linenumber) into odrs.lineno
              from orderdtlline
              where orderid = oh.orderid
                and shipid = oh.shipid
                and item = od.item
                and lotnumber = od.lotnumber;
        end if;
        open curOrderDtlLineLotLineno(oh.orderid,oh.shipid,od.item,od.lotnumber,odrs.lineno);
        fetch curOrderDtlLineLotLineno into OLL;
        close curOrderDtlLineLotLineno;
        insert_944_serial_data(oh,od,OLL);
        rnide := null;
        rnide.sessionid := strSuffix;
        rnide.custid := od.custid;
        rnide.orderid := OLL.orderid;
        rnide.shipid := OLL.shipid;
        rnide.item := OLL.item;
        rnide.lotnumber := OLL.lotnumber;
        rnide.qty := odrs.qtyrcvd;
        rnide.uom := od.uom;
        rnide.serialnumber := odrs.serialnumber;
        rnide.useritem1 := odrs.useritem1;
        rnide.useritem2 := odrs.useritem2;
        rnide.useritem3 := odrs.useritem3;
        rnide.line_number := odrs.lineno;
        rnide.condition := null;
        rnide.snweight := odrs.snweight;
        begin
          select condition
            into rnide.condition
            from allplateview
           where lpid = odrs.lpid;
        exception when others then
          null;
        end;
        rnide.damagereason := rnide.condition;
        rnide.qtyrcvd_invstatus := odrs.invstatus;
        if rnide.qtyrcvd_invstatus != 'DM' then
          rnide.qtyrcvd_invstatus := 'AV';
        end if;
        debugmsg('line no insert ideex line ');



        execute immediate 'insert into RCPTNOTE944IDEEX ' ||
        ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
        ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
        ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,:QTYRCVD_INVSTATUS,'||
        ' :ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
        using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
        rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
        rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
        rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,'N';
     end loop;
     --now get any unexpected items
     for odrs in curOrderDtlRcptSerialLinenoU(oh.orderid,oh.shipid,od.item,od.lotnumber) loop
        debugmsg('seriallineno ' || oh.orderid || ' ' || oh.shipid || ' ' || od.item || ' ' || od.lotnumber);
           open curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
           fetch curOrderDtlLineLot into OLL;
           close curOrderDtlLineLot;
           insert_944_serial_data(oh,od,OLL);
           rnide := null;
           rnide.sessionid := strSuffix;
           rnide.custid := od.custid;
           rnide.orderid := OLL.orderid;
           rnide.shipid := OLL.shipid;
           rnide.item := OLL.item;
           rnide.lotnumber := OLL.lotnumber;
           rnide.qty := odrs.qtyrcvd;
           rnide.uom := od.uom;
           rnide.serialnumber := odrs.serialnumber;
           rnide.useritem1 := odrs.useritem1;
           rnide.useritem2 := odrs.useritem2;
           rnide.useritem3 := odrs.useritem3;
           rnide.line_number := odrs.lineno;
           rnide.condition := null;
           rnide.snweight := odrs.snweight;
           begin
             select condition
               into rnide.condition
               from allplateview
              where lpid = odrs.lpid;
           exception when others then
             null;
           end;
           rnide.damagereason := rnide.condition;
           rnide.qtyrcvd_invstatus := odrs.invstatus;
           if rnide.qtyrcvd_invstatus != 'DM' then
             rnide.qtyrcvd_invstatus := 'AV';
           end if;
           debugmsg('lineno u insert ideex line ');
           execute immediate 'insert into RCPTNOTE944IDEEX ' ||
           ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
           ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
           ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,:QTYRCVD_INVSTATUS,'||
           ':ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
           using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
           rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
           rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
           rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,'N';
     end loop;

     --finally any zero lines
     if upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'Y' then
        for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber) loop
           if ol.linenumber is not null and
              ol.linenumber != 0 then
              debugmsg('zol ' || ol.item || ' ' || ol.lotnumber || ' ' || nvl(ol.linenumber,123));
              select count(1) into iLineCnt from RCPTNOTE944IDEEX
                 where sessionid = strSuffix
                   and orderid = ol.orderid
                   and shipid = ol.shipid
                   and item = ol.item
                   and lotnumber = ol.lotnumber
                   and line_number = ol.linenumber;
              if iLineCnt = 0 then
                 begin
                    select useritem1, useritem2, useritem3 into
                           odrs.useritem1, odrs.useritem2, odrs.useritem3
                       from asncartondtl
                       where orderid = ol.orderid
                         and shipid = ol.shipid
                         and item = ol.item
                         and lotnumber = ol.lotnumber
                         and lineno = ol.linenumber;
                 exception when others then
                    odrs.useritem1 := null;
                    odrs.useritem2 := null;
                    odrs.useritem3 := null;
                 end;

                 rnide := null;
                 rnide.sessionid := strSuffix;
                 rnide.custid := od.custid;
                 rnide.orderid := ol.orderid;
                 rnide.shipid := ol.shipid;
                 rnide.item := ol.item;
                 rnide.lotnumber := ol.lotnumber;
                 rnide.qty := qtyLineNumber;
                 rnide.uom := od.uom;
                 rnide.serialnumber := odrs.serialnumber;
                 rnide.useritem1 := odrs.useritem1;
                 rnide.useritem2 := odrs.useritem2;
                 rnide.useritem3 := odrs.useritem3;
                 rnide.line_number := ol.linenumber;
                 rnide.snweight := odrs.snweight;
                 rnide.condition := null;
                 odrs.qtyrcvd := 0;
                 rnide.damagereason := null;
                 rnide.qtyrcvd_invstatus := 'AV';
                 debugmsg('insert ideex 1');
                 execute immediate 'insert into RCPTNOTE944IDEEX ' ||
                 ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
                 ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,:ORIGTRACKINGNO, '||
                 ' :SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,:QTYRCVD_INVSTATUS,'||
                 ':ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
                 using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
                 rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
                 rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
                 rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,'Y';
              end if;
           end if;
        end loop;
     end if;
     -------------------
   else
      cntLines := 0;
      cntLineSeq := 0;
      begin
        select count(1)
          into cntLines
          from orderdtlline ol
         where ol.orderid(+) = od.orderid
           and ol.shipid(+) = od.shipid
           and ol.item(+) = od.item
           and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
           and nvl(ol.xdock,'N') = 'N';
      exception when others then
        cntLines := 1;
      end;
      if cntLines = 0 then
        cntLines := 1;
      end if;
      open curOrderDtlRcptSerial(oh.orderid,oh.shipid,od.item,od.lotnumber);
      fetch curOrderDtlRcptSerial into odrs;
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
        debugmsg('ldr2 ' || ol.item || ' ' || ol.lotnumber || ' ' || ol.linenumber);
    qtyNoSerialAccum := 0;
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cntLineSeq := cntLineSeq + 1;
    debugmsg('cntLineSeq/cntLines  ' ||cntLineSeq||' / '||cntLines);
    if cntLineSeq = cntLines then
      debugmsg('last line');
      qtyRemain := 9999999;
    elsif nvl(in_ide_use_received_yn,'n') = 'Y' then
       qtyRemain := ol.qtyrcvd;
    else
       qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 1 ' || qtyRemain);
    if odrs.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odrs.qtyrcvd = 0 then
          fetch curOrderDtlRcptSerial into odrs;
          if curOrderDtlRcptSerial%notfound then
            odrs := null;
            exit;
          end if;
        end if;
        if odrs.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odrs.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odrs.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odrs.qtyrcvd := odrs.qtyrcvd - qtyLineNumber;
        rnide := null;
        if odrs.serialnumber is not null or
           odrs.useritem1 is not null or
           odrs.useritem2 is not null or
           odrs.useritem3 is not null then
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := qtyLineNumber;
          rnide.uom := od.uom;
          rnide.serialnumber := odrs.serialnumber;
          rnide.useritem1 := odrs.useritem1;
          rnide.useritem2 := odrs.useritem2;
          rnide.useritem3 := odrs.useritem3;
          rnide.line_number := ol.linenumber;
          rnide.condition := null;
          rnide.snweight := odrs.snweight;
          begin
            select condition
              into rnide.condition
              from allplateview
             where lpid = odrs.lpid;
          exception when others then
            null;
          end;
          rnide.damagereason := rnide.condition;
          rnide.qtyrcvd_invstatus := odrs.invstatus;
          if rnide.qtyrcvd_invstatus != 'DM' then
            rnide.qtyrcvd_invstatus := 'AV';
          end if;
          debugmsg('insert ideex 2 ');
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,' ||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER, :SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,'N';
        else
          qtyNoSerialAccum := qtyNoSerialAccum + qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      if qtyLineAccumGood != 0 then
        qtyLineNumber := qtyLineAccum;
        qtyLineGood := qtyLineAccumGood;
        qtyLineDmgd := 0;
        rnide := null;
        qtyRcvd_invstatus := 'AV';
        debugmsg('i9sd 1');
        insert_944_serial_data(oh,od,ol);
        if qtyNoSerialAccum != 0 then
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := qtyLineAccumGood;
          rnide.uom := od.uom;
          rnide.line_number := ol.linenumber;
          rnide.qtyrcvd_invstatus := 'AV';
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        end if;
      end if;
      if qtyLineAccumDmgd != 0 then
        qtyLineNumber := qtyLineAccum;
        qtyLineGood := 0;
        qtyLineDmgd := qtyLineAccumDmgd;
        rnide := null;
        qtyRcvd_invstatus := 'DM';
        insert_944_serial_data(oh,od,ol);
        if qtyNoSerialAccum != 0 then
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := qtyLineAccumDmgd;
          rnide.uom := od.uom;
          rnide.line_number := ol.linenumber;
          rnide.qtyrcvd_invstatus := 'DM';
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,'N';
        end if;
      end if;
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcptSerial;
  end if;
end loop; -- orderdtl

end;

procedure create_944_line_data_returns(oh orderhdr%rowtype) is
begin

debugmsg('create_944_line_data_returns');

for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  odrs := null;
  open curOrderDtlRcptSerial(oh.orderid,oh.shipid,od.item,od.lotnumber);
  fetch curOrderDtlRcptSerial into odrs;
  cntLineSeq := 0;
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    qtyRemain := od.qtyrcvd;
    debugmsg('qty remain set at 2 ' || qtyRemain);
    if odrs.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odrs.qtyrcvd = 0 then
          fetch curOrderDtlRcptSerial into odrs;
          if curOrderDtlRcptSerial%notfound then
            odrs := null;
            exit;
          end if;
        end if;
        debugmsg('odrs.qtyrcvd is ' || odrs.qtyrcvd);
        debugmsg('qtyremain is ' || qtyremain);
        if odrs.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odrs.qtyrcvd;
        end if;
        debugmsg('qtylinenumber is ' || qtylinenumber);
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odrs.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odrs.qtyrcvd := odrs.qtyrcvd - qtyLineNumber;
        rnide := null;
        rnide.sessionid := strSuffix;
        rnide.custid := od.custid;
        rnide.orderid := ol.orderid;
        rnide.shipid := ol.shipid;
        rnide.item := ol.item;
        rnide.lotnumber := ol.lotnumber;
        rnide.qty := qtyLineNumber;
        rnide.uom := od.uom;
        rnide.origtrackingno := zoe.outbound_trackingno(oh.origorderid,oh.origshipid,od.item,
             odrs.lotnumber,odrs.serialnumber,odrs.useritem1,odrs.useritem2,odrs.useritem3);
        rnide.serialnumber := odrs.serialnumber;
        rnide.useritem1 := odrs.useritem1;
        rnide.useritem2 := odrs.useritem2;
        rnide.useritem3 := odrs.useritem3;
        rnide.line_number := ol.linenumber;
        rnide.condition := null;
        begin
          select condition
            into rnide.condition
            from allplateview
           where lpid = odrs.lpid;
        exception when others then
          null;
        end;
        rnide.damagereason := rnide.condition;
        rnide.qtyrcvd_invstatus := odrs.invstatus;
        rnide.orig_line_number := 0;
        open curShippingPlate(oh.origorderid,oh.origshipid,od.item,od.lotnumber);
        fetch curShippingPlate into sp;
        for origol in curOrigOrderDtlLine(oh.origorderid,oh.origshipid,od.item,od.lotnumber)
        loop
          debugmsg('orig_line_number is ' || rnide.orig_line_number);
          if rnide.orig_line_number <> 0 then
            exit;
          end if;
          qtyOrigRemain := origol.qty;
          while (qtyOrigRemain > 0)
          loop
            if sp.qty = 0 then
              fetch curShippingPlate into sp;
              if curShippingPlate%notfound then
                sp := null;
              end if;
            end if;
            if sp.item is null then
              exit;
            end if;
            if sp.qty >= qtyOrigRemain then
              qtyOrigLineNumber := qtyOrigRemain;
            else
              qtyOrigLineNumber := sp.qty;
            end if;
            if nvl(sp.trackingno,'x') = nvl(rnide.origtrackingno,'x') then
              rnide.orig_line_number := origol.linenumber;
              exit;
            end if;
            qtyOrigRemain := qtyOrigRemain - qtyOrigLineNumber;
            sp.qty := sp.qty - qtyOrigLineNumber;
          end loop; -- qtyorigremain > 0
        end loop; -- origorderdtlline
        close curShippingPlate;
        if rnide.origtrackingno is null then
          begin
            select substr(nvl(ooh.billoflading,nvl(old.billoflading,oh.origorderid||'-'||oh.origshipid)),1,30)
              into rnide.origtrackingno
              from loads old, orderhdr ooh
             where ooh.orderid = oh.origorderid
               and ooh.shipid = oh.origshipid
               and ooh.loadno = old.loadno(+);
          exception when others then
            null;
          end;
        end if;
        debugmsg('cldr - insert ideex');
        execute immediate 'insert into RCPTNOTE944IDEEX ' ||
        ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
        ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
        ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
        ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
        using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
        rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
        rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
        rnide.qtyrcvd_invstatus, rnide.orig_line_number,0.0,'N';
        debugmsg('find dtl row');
        begin
          execute immediate
            'select count(1) from rcpt_note_944_dtl_' || strSuffix ||
            ' where orderid = ' || rnide.orderid ||
            '   and shipid = ' || rnide.shipid ||
            '   and item = ''' || rnide.item || '''' ||
            '   and line_number = ''' || rnide.line_number || '''' ||
            '   and nvl(lotnumber,''x'') = nvl(''' || rnide.lotnumber || ''',''x'')' ||
            '   and qtyrcvd_invstatus = ''' || rnide.qtyrcvd_invstatus || '''' ||
            '   and orig_line_number = ' || rnide.orig_line_number
            into cntRows;
        exception when others then
           debugmsg(sqlerrm);
           cntRows := 0;
        end;
        qtyrcvd_invstatus := rnide.qtyrcvd_invstatus;
        if cntRows = 0 then
          debugmsg('new dtl--qtylinenumber is ' || qtylinenumber);
          if qtyrcvd_invstatus = 'AV' then
            qtyLineGood := qtyLineNumber;
            qtyLineDmgd := 0;
            qtyLineOnHold := 0;
            debugmsg('insert AV serial');
            insert_944_serial_data(oh,od,ol);
          else
            qtyLineGood := 0;
            qtyLineDmgd := qtyLineNumber;
            qtyLineOnHold := 0;
            debugmsg('insert DM serial');
            insert_944_serial_data(oh,od,ol);
          end if;
        else
          if qtyrcvd_invstatus = 'AV' then
            debugmsg('update av serial');
            begin
              cmdSql :=
                ' update rcpt_note_944_dtl_' || strSuffix ||
                ' set qtyrcvd = qtyrcvd + ' || qtyLineNumber || ',' ||
                '     cubercvd = zci.item_cube('''||od.custid||''','''||od.item||''','''||od.uom||''') * (qtyrcvd + ' || qtyLineNumber ||'),'||
                '     qtyrcvdgood = qtyrcvdgood + ' || qtyLineNumber || ','||
                '     cubercvdgood = zci.item_cube('''||od.custid||''','''||od.item||''','''||od.uom||''') * (qtyrcvdgood + ' || qtyLineNumber || ')'||
                ' where orderid = ' || rnide.orderid ||
                '   and shipid = ' || rnide.shipid ||
                '   and item = ''' || rnide.item || '''' ||
                '   and line_number = ''' || rnide.line_number || '''' ||
                '   and nvl(lotnumber,''x'') = nvl(''' || rnide.lotnumber || ''',''x'')' ||
                '   and qtyrcvd_invstatus = ''' || rnide.qtyrcvd_invstatus || '''' ||
                '   and orig_line_number = ' || rnide.orig_line_number;
              debugmsg(cmdSql);
              execute immediate
                cmdSql;
            exception when others then
              debugmsg(sqlerrm);
            end;
          else
          null;
            debugmsg('update dm serial');
            begin
              cmdSql :=
                ' update rcpt_note_944_dtl_' || strSuffix ||
                ' set qtyrcvd = qtyrcvd + ' || qtyLineNumber || ',' ||
                '     cubercvd = zci.item_cube('''||od.custid||''','''||od.item||''','''||od.uom||''') * (qtyrcvd + ' || qtyLineNumber ||'),'||
                '     qtyrcvddmgd = qtyrcvdgood + ' || qtyLineNumber || ','||
                '     cubercvddmgd = zci.item_cube('''||od.custid||''','''||od.item||''','''||od.uom||''') * (qtyrcvdgood + ' || qtyLineNumber || ')'||
                ' where orderid = ' || rnide.orderid ||
                '   and shipid = ' || rnide.shipid ||
                '   and item = ''' || rnide.item || '''' ||
                '   and line_number = ''' || rnide.line_number || '''' ||
                '   and nvl(lotnumber,''x'') = nvl(''' || rnide.lotnumber || ''',''x'')' ||
                '   and qtyrcvd_invstatus = ''' || rnide.qtyrcvd_invstatus || '''' ||
                '   and orig_line_number = ' || rnide.orig_line_number;
              debugmsg(cmdSql);
              execute immediate
                cmdSql;
            exception when others then
              debugmsg(sqlerrm);
            end;
          end if;
        end if;
      end loop; -- qtyremain > 0
    end if;
    debugmsg('qtylineaccum is ' || qtyLineAccum);
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      rnide := null;
      debugmsg('call to insert_944_serial for zero qty');
      insert_944_serial_data(oh,od,ol);
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcptSerial;
end loop; -- orderdtl

end;
-->>>>>>>>>>>>>>>>>>>>>>
procedure create_944_line_data_by_manu(oh orderhdr%rowtype) is
odr curOrderDtlRcptLotManu%rowtype;
svManufacturedate date;
begin

debugmsg('create_944_line_data_by_manu');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  odr := null;
  open curOrderDtlRcptLotManu(oh.orderid,oh.shipid,od.item,od.lotnumber);
  fetch curOrderDtlRcptLotManu into odr;
  svManufacturedate := odr.manufacturedate;
  debugmsg('     odr ' || odr.lpid || ' ' || odr.qtyrcvd || ' ' || to_char(odr.manufacturedate,'MM/DD/YYYY'));


  begin
    select count(1)
      into cntLines
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntLines := 1;
  end;
  if cntLines = 0 then
    cntLines := 1;
  end if;
  begin
    select count(1)
      into cntApprovals
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.qtyapproved,0) != 0
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntApprovals := 0;
  end;
  cntLineSeq := 0;
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cons.delete;
    cntLineSeq := cntLineSeq + 1;
    if ol.qtyApproved != 0 then
      qtyExpected := ol.qtyApproved;
    else
      qtyExpected := ol.qty;
    end if;
    if cntLineSeq = cntLines then
      qtyRemain := 9999999;
    elsif ol.qtyApproved != 0 then
      qtyRemain := ol.qtyApproved;
    elsif (cntApprovals = 0) and
          (cu.recv_line_check_yn = 'Y') then
      qtyRemain := 9999999;
    else
      qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 3 ' || qtyRemain);
    if odr.orderid is not null then
      while (qtyRemain > 0)
      loop
        debugmsg('  qtyremain loop ' || odr.qtyrcvd);
        if odr.qtyrcvd = 0 then
          debugmsg('fetch');
          fetch curOrderDtlRcptLotManu into odr;
          if curOrderDtlRcptLotManu%notfound then
            odr := null;
            exit;
          end if;
          debugmsg('     odr ' || odr.lpid || ' ' || odr.qtyrcvd || ' ' || to_char(odr.manufacturedate,'MM/DD/YYYY'));
          if odr.manufacturedate != svManufacturedate or
             (odr.manufacturedate is null and
              svManufacturedate is not null) then
             --debugmsg('date change ');
             --debugmsg('     la  ' || qtyLineAccum );
             --debugmsg('     lag ' || qtyLineAccumGood);
             --debugmsg('     lad ' ||  qtyLineAccumDmgd);
             --debugmsg('     lah ' ||  qtyLineAccumOnHold);
             --debugmsg('      sv ' || to_char(svManufacturedate,'MM/DD/YYYY'));
             --debugmsg('     odr ' || to_char(odr.manufacturedate,'MM/DD/YYYY'));
             qtyLineNumber := qtyLineAccum;
             qtyLineGood := qtyLineAccumGood;
             qtyLineDmgd := qtyLineAccumDmgd;
             qtyLineOnHold := qtyLineAccumOnHold;

             insert_944_line_data(oh,od,ol,'',svManufacturedate);
             svManufacturedate := odr.Manufacturedate;
             qtyLineAccum := 0;
             qtyLineAccumGood := 0;
             qtyLineAccumDmgd := 0;
             qtyLineAccumOnHold := 0;
          end if;
        end if;
        if odr.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odr.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odr.invstatus = 'OH' then
          qtyLineAccumOnHold := qtyLineAccumOnHold + qtyLineNumber;
        elsif odr.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odr.qtyrcvd := odr.qtyrcvd - qtyLineNumber;
        begin
           select condition, manufacturedate
             into strCondition, dManufacturedate
             from plate
            where lpid = odr.lpid;
         exception when others then
           strCondition := null;
           dManufacturedate := null;
         end;
         if strCondition is null and
            dManufacturedate is null then
           begin
             select condition, manufacturedate
               into strCondition, dManufacturedate
               from deletedplate
              where lpid = odr.lpid;
           exception when others then
             strCondition := null;
             dManufacturedate := null;
           end;
           debugmsg(odr.orderid || ' ' || ol.item || ' ' || odr.lotnumber || ' ' || strCondition ||
                    ' ' || odr.invstatus || ' ' || to_char(dManufacturedate,'MM/DD/YYYY'));
        end if;
        confoundx := 0;
        for conx in 1..cons.count
        loop
          if nvl(cons(conx).lotnumber,'x') = nvl(odr.lotnumber,'x') and
             cons(conx).condition = strCondition and
             cons(conx).invstatus = odr.invstatus then
            confoundx := conx;
            exit;
          end if;
        end loop;
        if confoundx != 0 then
          conx := confoundx;
          cons(conx).qty := cons(conx).qty + qtyLineNumber;
        else
          conx := cons.count + 1;
          cons(conx).lotnumber := odr.lotnumber;
          cons(conx).condition := strCondition;
          cons(conx).invstatus := odr.invstatus;
          cons(conx).qty := qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      qtyLineNumber := qtyLineAccum;
      qtyLineGood := qtyLineAccumGood;
      qtyLineDmgd := qtyLineAccumDmgd;
      qtyLineOnHold := qtyLineAccumOnHold;
      insert_944_line_data(oh,od,ol,'',svManufacturedate);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
      for conx in 1..cons.count
      loop
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.qty := cons(conx).qty;
          rnide.uom := od.uom;
          rnide.lotnumber := cons(conx).lotnumber;
          rnide.condition := cons(conx).invstatus;
          rnide.damagereason := cons(conx).condition;
          rnide.line_number := ol.linenumber;
          if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
             (cons(conx).invstatus = 'AV') then
            null;
          else
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
            ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
            ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
            ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
            using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
            rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
            rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
            rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
          end if;
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end loop;
    end if;
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      insert_944_line_data(oh,od,ol,'',svManufacturedate);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcptLotManu;
end loop; -- orderdtl

end;



procedure create_944_line_data_by_lot(oh orderhdr%rowtype) is
begin

debugmsg('create_944_line_data_by_lot');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  odr := null;
  open curOrderDtlRcptLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
  fetch curOrderDtlRcptLot into odr;
  begin
    select count(1)
      into cntLines
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntLines := 1;
  end;
  if cntLines = 0 then
    cntLines := 1;
  end if;
  begin
    select count(1)
      into cntApprovals
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.qtyapproved,0) != 0
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntApprovals := 0;
  end;
  cntLineSeq := 0;
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cons.delete;
    cntLineSeq := cntLineSeq + 1;
    if ol.qtyApproved != 0 then
      qtyExpected := ol.qtyApproved;
    else
      qtyExpected := ol.qty;
    end if;
    if cntLineSeq = cntLines then
      qtyRemain := 9999999;
    elsif ol.qtyApproved != 0 then
      qtyRemain := ol.qtyApproved;
    elsif (cntApprovals = 0) and
          (cu.recv_line_check_yn = 'Y') then
      qtyRemain := 9999999;
    else
      qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 3 ' || qtyRemain);
    if odr.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odr.qtyrcvd = 0 then
          fetch curOrderDtlRcptLot into odr;
          if curOrderDtlRcptLot%notfound then
            odr := null;
            exit;
          end if;
        end if;
        if odr.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odr.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odr.invstatus = 'OH' then
          qtyLineAccumOnHold := qtyLineAccumOnHold + qtyLineNumber;
        elsif odr.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odr.qtyrcvd := odr.qtyrcvd - qtyLineNumber;
        begin
          select condition
            into strCondition
            from plate
           where lpid = odr.lpid;
        exception when others then
          strCondition := null;
        end;
        if strCondition is null then
          begin
            select condition
              into strCondition
              from deletedplate
             where lpid = odr.lpid;
          exception when others then
            strCondition := null;
          end;
        end if;
        confoundx := 0;
        for conx in 1..cons.count
        loop
          if nvl(cons(conx).lotnumber,'x') = nvl(odr.lotnumber,'x') and
             cons(conx).condition = strCondition and
             cons(conx).invstatus = odr.invstatus then
            confoundx := conx;
            exit;
          end if;
        end loop;
        if confoundx != 0 then
          conx := confoundx;
          cons(conx).qty := cons(conx).qty + qtyLineNumber;
        else
          conx := cons.count + 1;
          cons(conx).lotnumber := odr.lotnumber;
          cons(conx).condition := strCondition;
          cons(conx).invstatus := odr.invstatus;
          cons(conx).qty := qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      qtyLineNumber := qtyLineAccum;
      qtyLineGood := qtyLineAccumGood;
      qtyLineDmgd := qtyLineAccumDmgd;
      qtyLineOnHold := qtyLineAccumOnHold;
      insert_944_line_data(oh,od,ol,'',null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
      for conx in 1..cons.count
      loop
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.qty := cons(conx).qty;
          rnide.uom := od.uom;
          rnide.lotnumber := cons(conx).lotnumber;
          rnide.condition := cons(conx).invstatus;
          rnide.damagereason := cons(conx).condition;
          rnide.line_number := ol.linenumber;
          if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
             (cons(conx).invstatus = 'AV') then
            null;
          else
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
            ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
            ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
            ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
            using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
            rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
            rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
            rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
          end if;
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end loop;
    end if;
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      insert_944_line_data(oh,od,ol,'',null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcptLot;
end loop; -- orderdtl

end;

procedure create_944_line_data_by_invcls(oh orderhdr%rowtype) is
l_invclass orderdtlrcpt.inventoryclass%type;
begin

debugmsg('create_944_line_data_by_invcls');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  odric := null;
  open curOrderDtlRcptInvclass(oh.orderid,oh.shipid,od.item,od.lotnumber);
  fetch curOrderDtlRcptInvclass into odric;
  l_invclass := odric.inventoryclass;
  begin
    select count(1)
      into cntLines
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntLines := 1;
  end;
  if cntLines = 0 then
    cntLines := 1;
  end if;
  begin
    select count(1)
      into cntApprovals
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and nvl(ol.qtyapproved,0) != 0
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntApprovals := 0;
  end;
  cntLineSeq := 0;
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cons.delete;
    cntLineSeq := cntLineSeq + 1;
    if ol.qtyApproved != 0 then
      qtyExpected := ol.qtyApproved;
    else
      qtyExpected := ol.qty;
    end if;
    if cntLineSeq = cntLines then
      qtyRemain := 9999999;
    elsif ol.qtyApproved != 0 then
      qtyRemain := ol.qtyApproved;
    elsif (cntApprovals = 0) and
          (cu.recv_line_check_yn = 'Y') then
      qtyRemain := 9999999;
    else
      qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 4 ' || qtyRemain);
    if odric.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odric.qtyrcvd = 0 then
          fetch curOrderDtlRcptInvclass into odric;
          if curOrderDtlRcptInvclass%notfound then
            odric := null;
            exit;
          end if;
                         l_invclass := odric.inventoryclass;
        end if;
        if odric.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odric.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odric.invstatus = 'OH' then
          qtyLineAccumOnHold := qtyLineAccumOnHold + qtyLineNumber;
        elsif odric.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odric.qtyrcvd := odric.qtyrcvd - qtyLineNumber;
        begin
          select condition
            into strCondition
            from plate
           where lpid = odric.lpid;
        exception when others then
          strCondition := null;
        end;
        if strCondition is null then
          begin
            select condition
              into strCondition
              from deletedplate
             where lpid = odric.lpid;
          exception when others then
            strCondition := null;
          end;
        end if;
        confoundx := 0;
        for conx in 1..cons.count
        loop
          if nvl(cons(conx).lotnumber,'x') = nvl(odric.lotnumber,'x') and
             cons(conx).condition = strCondition and
             cons(conx).invstatus = odric.invstatus then
            confoundx := conx;
            exit;
          end if;
        end loop;
        if confoundx != 0 then
          conx := confoundx;
          cons(conx).qty := cons(conx).qty + qtyLineNumber;
        else
          conx := cons.count + 1;
          cons(conx).lotnumber := odric.lotnumber;
          cons(conx).condition := strCondition;
          cons(conx).invstatus := odric.invstatus;
          cons(conx).qty := qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      qtyLineNumber := qtyLineAccum;
      qtyLineGood := qtyLineAccumGood;
      qtyLineDmgd := qtyLineAccumDmgd;
      qtyLineOnHold := qtyLineAccumOnHold;
      insert_944_line_data(oh,od,ol,l_invclass,null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
      for conx in 1..cons.count
      loop
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.qty := cons(conx).qty;
          rnide.uom := od.uom;
          rnide.lotnumber := cons(conx).lotnumber;
          rnide.condition := cons(conx).invstatus;
          rnide.damagereason := cons(conx).condition;
          rnide.line_number := ol.linenumber;
          if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
             (cons(conx).invstatus = 'AV') then
            null;
          else
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
            ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
            ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
            ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
            using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
            rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
            rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
            rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
          end if;
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end loop;
    end if;
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      insert_944_line_data(oh,od,ol,l_invclass,null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcptInvclass;
end loop; -- orderdtl

end;

procedure create_944_line_data_by_invsts(oh orderhdr%rowtype) is
l_qtyrcvd orderdtlrcpt.qtyrcvd%type;
l_qtyrcvdgood orderdtlrcpt.qtyrcvdgood%type;
l_qtyrcvddmgd orderdtlrcpt.qtyrcvddmgd%type;
l_cmd varchar2(4000);

begin

debugmsg('create_944_line_data_by_invsts');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  lineqtys.delete;
  for odr in curOrderDtlInvsts(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    l_qtyrcvd := odr.qtyrcvd;
    l_qtyrcvdgood := odr.qtyrcvdgood;
    l_qtyrcvddmgd := odr.qtyrcvddmgd;
    debugmsg(' orig qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
             ' qtyrcvddmgd ' || l_qtyrcvddmgd);
    begin
      select count(1)
        into cntLines
        from orderdtlline ol
       where ol.orderid = od.orderid
         and ol.shipid = od.shipid
         and ol.item = od.item
         and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
         and nvl(ol.xdock,'N') = 'N';
    exception when others then
      cntLines := 1;
    end;
    if cntLines = 0 then
      cntLines := 1;
    end if;
    cntLineSeq := 0;
    for odl in curOrderDtlLineLot(odr.orderid,odr.shipid,odr.item,odr.orderlot)
    loop
      lqfoundx := 0;
      for lineqtyx in 1..lineqtys.count
      loop
        if odl.linenumber = lineqtys(lqx).linenumber then
          lqfoundx := lqx;
          exit;
        end if;
      end loop;
      if lqfoundx = 0 then
        lqx := lineqtys.count + 1;
        lineqtys(lqx).linenumber := odl.linenumber;
        l_cmd := 'select nvl(sum(qtyrcvd),0) from rcpt_note_944_dtl_' || strSuffix ||
          ' where line_number = ' || lineqtys(lqx).linenumber;
        debugmsg(l_cmd);
        execute immediate l_cmd into lineqtys(lqx).qtyapplied;
        debugmsg('line ' || lineqtys(lqx).linenumber || ' initial applied is ' || lineqtys(lqx).qtyapplied);
      end if;
      cntLineSeq := cntLineSeq + 1;
      debugmsg('ldbi line ' || odl.linenumber || ' seq ' || cntLineSeq || ' tot ' || cntLines || ' odlqty ' || odl.qty ||
              ' odrqty ' || odr.qtyrcvd || ' applied ' || lineqtys(lqx).qtyapplied);
      if cntLineSeq != cntLines then
        odl.qty := odl.qty - lineqtys(lqx).qtyapplied;
      end if;
      debugmsg(' curr qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
              ' qtyrcvddmgd ' || l_qtyrcvddmgd);
      if (cntLineSeq != cntLines) and
         (odl.qty < l_qtyrcvd) then
        odr.qtyrcvd := odl.qty;
      else
        odr.qtyrcvd := l_qtyrcvd;
      end if;
      debugmsg('ldbi ' || odl.linenumber || ' insert invstatus data--seq ' || cntLineSeq || ' tot ' || cntLines || ' odlqty ' || odl.qty ||
            ' odrqty ' || odr.qtyrcvd || ' applied ' || lineqtys(lqx).qtyapplied);
      odr.qtyrcvddmgd := least(odr.qtyrcvd,l_qtyrcvddmgd);
      odr.qtyrcvdgood := least(odr.qtyrcvd,l_qtyrcvdgood);
      insert_944_invstatus_data(oh,odl,odr);
      lineqtys(lqx).qtyapplied := lineqtys(lqx).qtyapplied + odr.qtyrcvd;
      odl.qty := odl.qty - odr.qtyrcvd;
      l_qtyrcvd := l_qtyrcvd - odr.qtyrcvd;
      l_qtyrcvddmgd := l_qtyrcvddmgd - odr.qtyrcvddmgd;
      l_qtyrcvdgood := l_qtyrcvdgood - odr.qtyrcvdgood;
      debugmsg('  new qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
              ' qtyrcvddmgd ' || l_qtyrcvddmgd);
    end loop;
  end loop;
end loop;

end;

procedure create_944_line_data_by_item(oh orderhdr%rowtype) is
begin

debugmsg('create 944 line data by item');

for od in curOrderDtl(oh.orderid,oh.shipid)
loop
  debugmsg('processing line ' || od.item || '/' || od.lotnumber);
  odr := null;
  open curOrderDtlRcpt(oh.orderid,oh.shipid,od.item);
  fetch curOrderDtlRcpt into odr;
  debugmsg('first rcpt qty is ' || odr.qtyrcvd);
  begin
    select count(1)
      into cntLines
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntLines := 1;
  end;
  if cntLines = 0 then
    cntLines := 1;
  end if;
  debugmsg('cntlines is ' || cntLines);
  begin
    select count(1)
      into cntApprovals
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.qtyapproved,0) != 0
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntApprovals := 0;
  end;
  debugmsg('cntApprovals is ' || cntApprovals);
  cntLineSeq := 0;
  for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item)
  loop
    debugmsg('processing line number ' || ol.linenumber || ' qty ' || ol.qty);
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cons.delete;
    cntLineSeq := cntLineSeq + 1;
    if ol.qtyApproved != 0 then
      qtyExpected := ol.qtyApproved;
    else
      qtyExpected := ol.qty;
    end if;
    if cntLineSeq = cntLines then
      debugmsg('last line');
      qtyRemain := 9999999;
    elsif ol.qtyApproved != 0 then
      debugmsg('qtyApproved is ' || ol.qtyApproved);
      qtyRemain := ol.qtyApproved;
    elsif (cntApprovals = 0) and
          (cu.recv_line_check_yn = 'Y') then
      debugmsg('no approvals');
      qtyRemain := 9999999;
    else
      qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 5 ' || qtyRemain);
    if odr.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odr.qtyrcvd = 0 then
          fetch curOrderDtlRcpt into odr;
          if curOrderDtlRcpt%notfound then
            odr := null;
            exit;
          end if;
         debugmsg('next rcpt qty is ' || odr.qtyrcvd);
        end if;
        if odr.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odr.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odr.invstatus = 'OH' then
          qtyLineAccumOnHold := qtyLineAccumOnHold + qtyLineNumber;
        elsif odr.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odr.qtyrcvd := odr.qtyrcvd - qtyLineNumber;
        begin
          select condition
            into strCondition
            from plate
           where lpid = odr.lpid;
        exception when others then
          strCondition := null;
        end;
        if strCondition is null then
          begin
            select condition
              into strCondition
              from deletedplate
             where lpid = odr.lpid;
          exception when others then
            strCondition := null;
          end;
        end if;
        confoundx := 0;
        for conx in 1..cons.count
        loop
          if cons(conx).condition = strCondition and
             cons(conx).invstatus = odr.invstatus then
            confoundx := conx;
            exit;
          end if;
        end loop;
        if confoundx != 0 then
          conx := confoundx;
          cons(conx).qty := cons(conx).qty + qtyLineNumber;
        else
          conx := cons.count + 1;
          cons(conx).lotnumber := '';
          cons(conx).condition := strCondition;
          cons(conx).invstatus := odr.invstatus;
          cons(conx).qty := qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      qtyLineNumber := qtyLineAccum;
      qtyLineGood := qtyLineAccumGood;
      qtyLineDmgd := qtyLineAccumDmgd;
      qtyLineOnHold := qtyLineAccumOnHold;
      insert_944_line_data(oh,od,ol,'',null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := '';
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
      for conx in 1..cons.count
      loop
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.qty := cons(conx).qty;
          rnide.uom := od.uom;
          rnide.lotnumber := cons(conx).lotnumber;
          rnide.condition := cons(conx).invstatus;
          rnide.damagereason := cons(conx).condition;
          rnide.line_number := ol.linenumber;
          if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
             (cons(conx).invstatus = 'AV') then
            null;
          else
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
          end if;
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end loop;
    end if;
    debugmsg('qtylineaccum is ' || qtyLineAccum);
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      insert_944_line_data(oh,od,ol,'',null);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := ol.lotnumber;
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
    end if;
  end loop; -- orderdtlline
  close curOrderDtlRcpt;
end loop; -- orderdtl

for od in curOrderDtlNoLine(oh.orderid,oh.shipid)
loop
  debugmsg('processing no line ' || od.item || '/' || od.lotnumber);
  odr := null;
  open curOrderDtlRcpt(oh.orderid,oh.shipid,od.item);
  fetch curOrderDtlRcpt into odr;
  debugmsg('first rcpt qty is ' || odr.qtyrcvd);
  begin
    select count(1)
      into cntLines
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntLines := 1;
  end;
  if cntLines = 0 then
    cntLines := 1;
  end if;
  debugmsg('cntlines is ' || cntLines);
  begin
    select count(1)
      into cntApprovals
      from orderdtlline ol
     where ol.orderid = od.orderid
       and ol.shipid = od.shipid
       and ol.item = od.item
       and nvl(ol.qtyapproved,0) != 0
       and nvl(ol.xdock,'N') = 'N';
  exception when others then
    cntApprovals := 0;
  end;
  debugmsg('cntApprovals is ' || cntApprovals);
  cntLineSeq := 0;
  for ol in curOrderDtlLineNoLine(oh.orderid,oh.shipid,od.item)
  loop
    debugmsg('processing no line number ' || ol.linenumber || ' qty ' || ol.qty);
    qtyLineAccum := 0;
    qtyLineAccumGood := 0;
    qtyLineAccumDmgd := 0;
    qtyLineAccumOnHold := 0;
    cons.delete;
    cntLineSeq := cntLineSeq + 1;
    if ol.qtyApproved != 0 then
      qtyExpected := ol.qtyApproved;
    else
      qtyExpected := ol.qty;
    end if;
    if cntLineSeq = cntLines then
      debugmsg('last line');
      qtyRemain := 9999999;
    elsif ol.qtyApproved != 0 then
      debugmsg('qtyApproved is ' || ol.qtyApproved);
      qtyRemain := ol.qtyApproved;
    elsif (cntApprovals = 0) and
          (cu.recv_line_check_yn = 'Y') then
      debugmsg('no approvals');
      qtyRemain := 9999999;
    else
      qtyRemain := ol.qty;
    end if;
    debugmsg('qty remain set at 6 ' || qtyRemain);
    if odr.orderid is not null then
      while (qtyRemain > 0)
      loop
        if odr.qtyrcvd = 0 then
          fetch curOrderDtlRcpt into odr;
          if curOrderDtlRcpt%notfound then
            odr := null;
            exit;
          end if;
         debugmsg('next rcpt qty is ' || odr.qtyrcvd);
        end if;
        if odr.qtyrcvd >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := odr.qtyrcvd;
        end if;
        qtyLineAccum := qtyLineAccum + qtyLineNumber;
        if odr.invstatus = 'OH' then
          qtyLineAccumOnHold := qtyLineAccumOnHold + qtyLineNumber;
        elsif odr.invstatus = 'DM' then
          qtyLineAccumDmgd := qtyLineAccumDmgd + qtyLineNumber;
        else
          qtyLineAccumGood := qtyLineAccumGood + qtyLineNumber;
        end if;
        qtyRemain := qtyRemain - qtyLineNumber;
        odr.qtyrcvd := odr.qtyrcvd - qtyLineNumber;
        begin
          select condition
            into strCondition
            from plate
           where lpid = odr.lpid;
        exception when others then
          strCondition := null;
        end;
        if strCondition is null then
          begin
            select condition
              into strCondition
              from deletedplate
             where lpid = odr.lpid;
          exception when others then
            strCondition := null;
          end;
        end if;
        confoundx := 0;
        for conx in 1..cons.count
        loop
          if cons(conx).condition = strCondition and
             cons(conx).invstatus = odr.invstatus then
            confoundx := conx;
            exit;
          end if;
        end loop;
        if confoundx != 0 then
          conx := confoundx;
          cons(conx).qty := cons(conx).qty + qtyLineNumber;
        else
          conx := cons.count + 1;
          cons(conx).lotnumber := '';
          cons(conx).condition := strCondition;
          cons(conx).invstatus := odr.invstatus;
          cons(conx).qty := qtyLineNumber;
        end if;
      end loop; -- qtyremain > 0
    end if;
    if qtyLineAccum != 0 then
      qtyLineNumber := qtyLineAccum;
      qtyLineGood := qtyLineAccumGood;
      qtyLineDmgd := qtyLineAccumDmgd;
      qtyLineOnHold := qtyLineAccumOnHold;
      insert_944_noline_data(oh,od,ol);
      if qtyLineNumber != qtyExpected then
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.lotnumber := '';
          rnide.qty := abs(qtyLineNumber - qtyExpected);
          rnide.uom := od.uom;
          if qtyLineNumber > qtyExpected then
            rnide.condition := '03';
          else
            rnide.condition := '02';
          end if;
          rnide.line_number := ol.linenumber;
          execute immediate 'insert into RCPTNOTE944IDEEX ' ||
          ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end if;
      for conx in 1..cons.count
      loop
        begin
          rnide := null;
          rnide.sessionid := strSuffix;
          rnide.custid := od.custid;
          rnide.orderid := ol.orderid;
          rnide.shipid := ol.shipid;
          rnide.item := ol.item;
          rnide.qty := cons(conx).qty;
          rnide.uom := od.uom;
          rnide.lotnumber := cons(conx).lotnumber;
          rnide.condition := cons(conx).invstatus;
          rnide.damagereason := cons(conx).condition;
          rnide.line_number := ol.linenumber;
          if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
             (cons(conx).invstatus = 'AV') then
            null;
          else
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
          ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,'||
          ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
          ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
          using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
          rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
          rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
          rnide.qtyrcvd_invstatus,rnide.orig_line_number,0.0,'N';
          end if;
        exception when others then
          debugmsg('line insert of ide short over');
          debugmsg(sqlerrm);
        end;
      end loop;
    end if;
    debugmsg('qtylineaccum is ' || qtyLineAccum);
    if qtyLineAccum = 0 and
       upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' then
      qtyLineNumber := 0;
      qtyLineGood := 0;
      qtyLineDmgd := 0;
      qtyLineOnHold := 0;
      insert_944_noline_data(oh,od,ol);
    end if;
  end loop; -- orderdtllinenoline
  close curOrderDtlRcpt;
end loop; -- orderdtlnoline

end;

procedure create_944_line_data_by_is_rtn(oh orderhdr%rowtype) is
l_qtyrcvd orderdtlrcpt.qtyrcvd%type;
l_qtyrcvdgood orderdtlrcpt.qtyrcvdgood%type;
l_qtyrcvddmgd orderdtlrcpt.qtyrcvddmgd%type;
l_cmd varchar2(4000);

begin

debugmsg('create_944_line_data_by_is_rtn');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  lineqtys.delete;
  for odr in curOrderDtlInvstsRtn(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    l_qtyrcvd := odr.qtyrcvd;
    l_qtyrcvdgood := odr.qtyrcvdgood;
    l_qtyrcvddmgd := odr.qtyrcvddmgd;
    debugmsg(' orig qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
             ' qtyrcvddmgd ' || l_qtyrcvddmgd);
    begin
      select count(1)
        into cntLines
        from orderdtlline ol
       where ol.orderid = od.orderid
         and ol.shipid = od.shipid
         and ol.item = od.item
         and nvl(ol.lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
         and nvl(ol.xdock,'N') = 'N';
    exception when others then
      cntLines := 1;
    end;
    if cntLines = 0 then
      cntLines := 1;
    end if;
    cntLineSeq := 0;
    for odl in curOrderDtlLineLot(odr.orderid,odr.shipid,odr.item,odr.orderlot)
    loop
      lqfoundx := 0;
      for lineqtyx in 1..lineqtys.count
      loop
        if odl.linenumber = lineqtys(lqx).linenumber then
          lqfoundx := lqx;
          exit;
        end if;
      end loop;
      if lqfoundx = 0 then
        lqx := lineqtys.count + 1;
        lineqtys(lqx).linenumber := odl.linenumber;
        l_cmd := 'select nvl(sum(qtyrcvd),0) from rcpt_note_944_dtl_' || strSuffix ||
          ' where line_number = ' || lineqtys(lqx).linenumber;
        debugmsg(l_cmd);
        execute immediate l_cmd into lineqtys(lqx).qtyapplied;
        debugmsg('line ' || lineqtys(lqx).linenumber || ' initial applied is ' || lineqtys(lqx).qtyapplied);
      end if;
      cntLineSeq := cntLineSeq + 1;
      debugmsg('ldbi line ' || odl.linenumber || ' seq ' || cntLineSeq || ' tot ' || cntLines || ' odlqty ' || odl.qty ||
              ' odrqty ' || odr.qtyrcvd || ' applied ' || lineqtys(lqx).qtyapplied);
      if cntLineSeq != cntLines then
        odl.qty := odl.qty - lineqtys(lqx).qtyapplied;
      end if;
      debugmsg(' curr qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
              ' qtyrcvddmgd ' || l_qtyrcvddmgd);
      if (cntLineSeq != cntLines) and
         (odl.qty < l_qtyrcvd) then
        odr.qtyrcvd := odl.qty;
      else
        odr.qtyrcvd := l_qtyrcvd;
      end if;
      debugmsg('ldbi ' || odl.linenumber || ' insert invstatus data--seq ' || cntLineSeq || ' tot ' || cntLines || ' odlqty ' || odl.qty ||
            ' odrqty ' || odr.qtyrcvd || ' applied ' || lineqtys(lqx).qtyapplied);
      odr.qtyrcvddmgd := least(odr.qtyrcvd,l_qtyrcvddmgd);
      odr.qtyrcvdgood := least(odr.qtyrcvd,l_qtyrcvdgood);
      insert_944_instat_rtn_data(oh,odl,odr);
      lineqtys(lqx).qtyapplied := lineqtys(lqx).qtyapplied + odr.qtyrcvd;
      odl.qty := odl.qty - odr.qtyrcvd;
      l_qtyrcvd := l_qtyrcvd - odr.qtyrcvd;
      l_qtyrcvddmgd := l_qtyrcvddmgd - odr.qtyrcvddmgd;
      l_qtyrcvdgood := l_qtyrcvdgood - odr.qtyrcvdgood;
      debugmsg('  new qtyrcvd ' || l_qtyrcvd || ' qtyrcvdgood ' || l_qtyrcvdgood ||
              ' qtyrcvddmgd ' || l_qtyrcvddmgd);
    end loop;
  end loop;
end loop;

end create_944_line_data_by_is_rtn;

procedure create_944_line_data_dtlrcptq(oh orderhdr%rowtype) is
begin
debugmsg('create_944_line_data_dtlrcptq');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    for odrsinv in curOrderDtlRcptSerialInv(oh.orderid,oh.shipid,ol.item,ol.lotnumber)
    loop
        debugmsg('orderid/shipid/item/lotnumber/qtyorder/qtyrcvd/serialnumber/invstatus/inventoryclass/lpid: '||
          ol.orderid||'/'||ol.shipid||'/'||ol.item||'/'||
          ol.lotnumber||'/'||ol.qty||'/'||odrsinv.qtyrcvd||'/'||
          odrsinv.serialnumber||'/'||odrsinv.invstatus||'/'||odrsinv.inventoryclass||'/'||odrsinv.lpid);
        if odrsinv.orderid is not null then
            rnide := null;
            rnide.sessionid := strSuffix;
            rnide.custid := od.custid;
            rnide.orderid := ol.orderid;
            rnide.shipid := ol.shipid;
            rnide.item := ol.item;
            rnide.lotnumber := ol.lotnumber;
            rnide.qty := odrsinv.qtyrcvd;
            rnide.uom := od.uom;
            rnide.origtrackingno := zoe.outbound_trackingno(oh.origorderid,oh.origshipid,od.item,
                 odrsinv.lotnumber,odrsinv.serialnumber,odrsinv.useritem1,odrsinv.useritem2,odrsinv.useritem3);
            rnide.serialnumber := odrsinv.serialnumber;
            rnide.useritem1 := odrsinv.useritem1;
            rnide.useritem2 := odrsinv.useritem2;
            rnide.useritem3 := odrsinv.useritem3;
            rnide.line_number := ol.linenumber;
            rnide.condition := null;
            begin
              select condition
                into rnide.condition
                from allplateview
               where lpid = odrsinv.lpid;
            exception when others then
              null;
            end;
            rnide.damagereason := rnide.condition;
            rnide.qtyrcvd_invstatus := odrsinv.invstatus;
            rnide.orig_line_number := 0;
            rnide.zeroqty := null;
            open curShippingPlate(oh.origorderid,oh.origshipid,od.item,od.lotnumber);
            fetch curShippingPlate into sp;
            for origol in curOrigOrderDtlLine(oh.origorderid,oh.origshipid,od.item,od.lotnumber)
            loop
              debugmsg('orig_line_number is ' || rnide.orig_line_number);
              if rnide.orig_line_number <> 0 then
                exit;
              end if;
              qtyOrigRemain := origol.qty;
              while (qtyOrigRemain > 0)
              loop
                if sp.qty = 0 then
                  fetch curShippingPlate into sp;
                  if curShippingPlate%notfound then
                    sp := null;
                  end if;
                end if;
                if sp.item is null then
                  exit;
                end if;
                if sp.qty >= qtyOrigRemain then
                  qtyOrigLineNumber := qtyOrigRemain;
                else
                  qtyOrigLineNumber := sp.qty;
                end if;
                if nvl(sp.trackingno,'x') = nvl(rnide.origtrackingno,'x') then
                  rnide.orig_line_number := origol.linenumber;
                  exit;
                end if;
                qtyOrigRemain := qtyOrigRemain - qtyOrigLineNumber;
                sp.qty := sp.qty - qtyOrigLineNumber;
              end loop; -- qtyorigremain > 0
            end loop; -- origorderdtlline
            close curShippingPlate;
            if rnide.origtrackingno is null then
              begin
                select substr(nvl(ooh.billoflading,nvl(old.billoflading,oh.origorderid||'-'||oh.origshipid)),1,30)
                  into rnide.origtrackingno
                  from loads old, orderhdr ooh
                 where ooh.orderid = oh.origorderid
                   and ooh.shipid = oh.origshipid
                   and ooh.loadno = old.loadno(+);
              exception when others then
                null;
              end;
            end if;
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
            ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
            ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,:QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER,:SNWEIGHT,:ZEROQTY)'
            using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
            rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
            rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
            rnide.qtyrcvd_invstatus, rnide.orig_line_number,0.0,rnide.zeroqty;
            qtyrcvd_invstatus := rnide.qtyrcvd_invstatus;
            if qtyrcvd_invstatus = 'AV' then
               qtyLineGood := odrsinv.qtyrcvd;
               qtyLineDmgd := 0;
               qtyLineOnHold := 0;
            else
              qtyLineGood := 0;
              qtyLineDmgd := odrsinv.qtyrcvd;
              qtyLineOnHold := 0;
            end if;
            qtyLineNumber :=  odrsinv.qtyrcvd;
            if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' and
              qtyLineNumber = 0 then
                qtyLineGood := 0;
                qtyLineDmgd := 0;
                qtyLineOnHold := 0;
                rnide := null;
            end if;
            insert_944_dtlrcpt_data(oh,od,ol,odrsinv);
        end if;
        debugmsg('qtyLineNumber is ' || qtyLineNumber);
    end loop; -- curOrderDtlRcptSerialInv
  end loop; -- curOrderDtlLineLot
end loop; -- orderdtl
end create_944_line_data_dtlrcptq;
procedure create_944_line_data_dtlrcptr(oh orderhdr%rowtype) is
begin
debugmsg('create_944_line_data_dtlrcptr');
for od in curOrderDtlLot(oh.orderid,oh.shipid)
loop
  for ol in curOrderDtlLineLot(oh.orderid,oh.shipid,od.item,od.lotnumber)
  loop
    for odrsinv in curOrderDtlRcptSerialInv(oh.orderid,oh.shipid,ol.item,ol.lotnumber)
    loop
        debugmsg('orderid/shipid/item/lotnumber/qtyorder/qtyrcvd/serialnumber/invstatus/inventoryclass/lpid: '||
              ol.orderid||'/'||ol.shipid||'/'||ol.item||'/'||
              ol.lotnumber||'/'||ol.qty||'/'||odrsinv.qtyrcvd||'/'||
              odrsinv.serialnumber||'/'||odrsinv.invstatus||'/'||odrsinv.inventoryclass||'/'||odrsinv.lpid);
        if nvl(in_ide_use_received_yn,'n') = 'Y' then
           qtyLineNumber := odrsinv.qtyrcvd;
        else
           qtyLineNumber := ol.qty;
        end if;
        if odrsinv.orderid is not null then
            rnide := null;
            rnide.sessionid := strSuffix;
            rnide.custid := od.custid;
            rnide.orderid := ol.orderid;
            rnide.shipid := ol.shipid;
            rnide.item := ol.item;
            rnide.lotnumber := ol.lotnumber;
            rnide.qty := qtyLineNumber;
            rnide.uom := od.uom;
            rnide.serialnumber := odrsinv.serialnumber;
            rnide.useritem1 := odrsinv.useritem1;
            rnide.useritem2 := odrsinv.useritem2;
            rnide.useritem3 := odrsinv.useritem3;
            rnide.line_number := ol.linenumber;
            rnide.condition := null;
            begin
              select condition
              into rnide.condition
              from allplateview
             where lpid = odrsinv.lpid;
            exception when others then
              null;
            end;
            rnide.snweight := odrsinv.snweight;
            rnide.damagereason := rnide.condition;
            rnide.zeroqty := null;
            if nvl(odrsinv.invstatus,'none') != 'DM' then
              rnide.qtyrcvd_invstatus := 'AV';
              qtyrcvd_invstatus := 'AV';
              qtyLineGood := qtyLineNumber;
              qtyLineDmgd := 0;
              qtyLineOnHold := 0;
            else
              rnide.qtyrcvd_invstatus := odrsinv.invstatus;
              qtyrcvd_invstatus := odrsinv.invstatus;
              qtyLineGood := 0;
              qtyLineDmgd := qtyLineNumber;
              qtyLineOnHold := 0;
            end if;
            execute immediate 'insert into RCPTNOTE944IDEEX ' ||
            ' values (:SESSIONID,:CUSTID,:ORDERID,:SHIPID,:ITEM,:LOTNUMBER,:QTY,' ||
            ' :UOM,:CONDITION,:DAMAGEREASON,:LINE_NUMBER,' ||
            ' :ORIGTRACKINGNO,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,' ||
            ' :QTYRCVD_INVSTATUS,:ORIG_LINE_NUMBER, :SNWEIGHT,:ZEROQTY)'
            using rnide.SESSIONID,rnide.CUSTID,rnide.ORDERID,rnide.SHIPID,rnide.ITEM,rnide.LOTNUMBER,
            rnide.QTY,rnide.UOM,rnide.CONDITION,rnide.DAMAGEREASON,rnide.LINE_NUMBER,
            rnide.origtrackingno, rnide.serialnumber,rnide.useritem1,rnide.useritem2,rnide.useritem3,
            rnide.qtyrcvd_invstatus,rnide.orig_line_number,rnide.snweight,rnide.zeroqty;
            insert_944_dtlrcpt_data(oh,od,ol,odrsinv);
        end if;
        debugmsg('qtyLineNumber is '||qtyLineNumber);
    end loop; -- curOrderDtlRcptSerialInv
  end loop; -- orderdtlline
end loop; -- orderdtl
end create_944_line_data_dtlrcptr;

procedure create_944_cfs_data(hdr orderhdr%rowtype) is
strother_data laboractivityview.other_data%type;

begin
cmdSql := 'create table RCPT_NOTE_944_CFS_' ||strSuffix ||
  '(CUSTID VARCHAR2(10),ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null, '||
  ' LOADNO NUMBER(7),FACILITY VARCHAR2(3),item varchar2(50) not null, '||
  ' LOTNUMBER VARCHAR2(30), ARRIVALDATE varchar2(36), UNLOAD_DATE varchar2(36), '||
  ' QTYRCVD NUMBER, UOM VARCHAR2(4), OPLTPALLETTQTY NUMBER, SPLTPALLETTQTY NUMBER, '||
  ' HDRPASSTHRUCHAR01 VARCHAR2(255), QTYRCVD_EXCEPTIONS NUMBER, INVSTATUS_EXCEPTIONS VARCHAR2(12), '||
  ' OVERDIM VARCHAR2(255), HAZARDOUS VARCHAR2(1), DTLPASSTHRUCHAR01 VARCHAR2(255), WHSELOC VARCHAR2(255), '||
  ' DTLPASSTHRUCHAR08 VARCHAR2(255), TOTALWEIGHT NUMBER(17,8))';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

begin
   execute immediate 'select count(1) from rcpt_note_944_dtl_'|| strSuffix into cntRows;
exception when others then
   return;
end;

strother_data := 'loadno='||hdr.loadno;

cmdSql := 'insert into  RCPT_NOTE_944_CFS_' ||strSuffix ||
  ' select custid, orderid, shipid, loadno, facility, item, lotnumber, arrivaldate, '||
  ' unload_date, qtyrcvd, uom, opltpallettqty, spltpallettqty, hdrpassthruchar01, '||
  ' qtyrcvd_exceptions, invstatus_exceptions, overdim, hazardous, dtlpassthruchar01, whseloc, '||
  ' dtlpassthruchar08, totalweight '||
  ' from '||
  ' ( '||
      ' select oh.custid CUSTID ,oh.orderid ORDERID ,oh.shipid SHIPID , '||
      ' oh.loadno LOADNO, oh.facility FACILITY, od.item ITEM, od.lotnumber LOTNUMBER, '||
      ' (select to_char(rcvddate,''DD-MON-YYYY HH:MI:SS AM'') '||
      ' from loads where loadno = '||
      '       (select nvl(loadno,0) from orderhdr '||
      '        where orderid=oh.orderid and shipid=oh.shipid) '||
      ' ) ARRIVALDATE, '||
      ' (select min(to_char(end_time,''DD-MON-YYYY HH:MI:SS AM'')) '||
      '   from laboractivityview '||
      '  where custid = oh.custid '||
      '    and facility = oh.facility '||
      '    and event = ''MTTR'' '||
      '    and other_data = '''||strother_data||''''||
      ' )UNLOAD_DATE, '||
      ' od.qtyrcvd QTYRCVD, od.uom UOM, '||
      ' zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, ''R'', ''OPLT'') OPLTPALLETTQTY, '||
      ' zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, ''R'', ''SPLT'') SPLTPALLETTQTY, '||
      ' oh.hdrpassthruchar01 HDRPASSTHRUCHAR01, '||
      ' null QTYRCVD_EXCEPTIONS, '||
      ' null INVSTATUS_EXCEPTIONS, '||
      ' null OVERDIM, '||
      ' (select hazardous from custitem where custid=oh.custid and item=od.item) HAZARDOUS, '||
      ' od.dtlpassthruchar01 DTLPASSTHRUCHAR01,null WHSELOC, od.DTLPASSTHRUCHAR08 DTLPASSTHRUCHAR08, '||
      ' (od.weightitem * od.qtyrcvd) TOTALWEIGHT '||
      ' from  rcpt_note_944_hdr_'|| strSuffix || ' oh, '||
      '      rcpt_note_944_dtl_'|| strSuffix || ' od '||
      ' where oh.orderid = od.orderid '||
      '  and oh.shipid = od.shipid ' ||
  ' ) '||
  ' group by custid, orderid, shipid, loadno, facility, item, lotnumber, arrivaldate, unload_date, qtyrcvd, uom, '||
  '    opltpallettqty, spltpallettqty, hdrpassthruchar01, invstatus_exceptions, overdim, hazardous, dtlpassthruchar01, whseloc, '||
  '    dtlpassthruchar08, totalweight';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'insert into  RCPT_NOTE_944_CFS_' ||strSuffix ||
  ' select distinct custid, orderid, shipid, loadno, facility, item, lotnumber, arrivaldate, unload_date, qtyrcvd, uom, '||
  ' opltpallettqty, spltpallettqty, hdrpassthruchar01, sum(nvl(qtyrcvd_exceptions,0)),nvl(invstatus_exceptions,''none''), '||
  ' overdim, hazardous, dtlpassthruchar01, whseloc, dtlpassthruchar08, totalweight '||
  ' from '||
  ' ( '||
      ' select oh.custid CUSTID ,oh.orderid ORDERID ,oh.shipid SHIPID, '||
      ' oh.loadno LOADNO ,oh.facility FACILITY ,od.item ITEM ,od.lotnumber LOTNUMBER, '||
      ' (select to_char(rcvddate,''DD-MON-YYYY HH:MI:SS AM'') '||
      ' from loads where loadno = '||
      '       (select nvl(loadno,0) from orderhdr '||
      '        where orderid=oh.orderid and shipid=oh.shipid) '||
      ' ) ARRIVALDATE, '||
      ' (select min(to_char(end_time,''DD-MON-YYYY HH:MI:SS AM'')) '||
      '   from laboractivityview '||
      '  where custid = oh.custid '||
      '    and facility = oh.facility '||
      '    and event = ''MTTR'' '||
      '    and other_data = '''||strother_data||''''||
      ' )UNLOAD_DATE, '||
      ' null QTYRCVD, od.uom UOM, '||
      ' zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, ''R'', ''OPLT'') OPLTPALLETTQTY, '||
      ' zim7.pallet_count_by_type(oh.loadno,oh.custid,oh.facility,oh.orderid,oh.shipid, ''R'', ''SPLT'') SPLTPALLETTQTY, '||
      ' oh.hdrpassthruchar01 HDRPASSTHRUCHAR01, '||
      ' oc.qtyrcvd QTYRCVD_EXCEPTIONS, '||
      ' oc.invstatus INVSTATUS_EXCEPTIONS, '||
      ' null OVERDIM, '||
      ' (select hazardous from custitem where custid=oh.custid and item=od.item) as HAZARDOUS, '||
      ' od.dtlpassthruchar01 DTLPASSTHRUCHAR01,null WHSELOC, od.dtlpassthruchar08 DTLPASSTHRUCHAR08, '||
      ' (od.weightitem * od.qtyrcvd) TOTALWEIGHT '||
      ' from  rcpt_note_944_hdr_'|| strSuffix || ' oh, '||
      '       rcpt_note_944_dtl_'|| strSuffix || ' od, '||
      '       orderdtlrcpt oc '||
      ' where oh.orderid = od.orderid '||
      '  and  oh.shipid  = od.shipid '||
      '  and  oh.orderid = oc.orderid '||
      '  and  oh.shipid  = oc.shipid '||
      '  and  od.item    = oc.item '||
      '  and  nvl(od.lotnumber, ''none'') = nvl(oc.lotnumber,''none'') '||
      '  and  oc.invstatus != ''AV'' '||
      '  and rownum < 5 '||
  ' ) '||
  ' group by custid, orderid, shipid, loadno, facility, item, lotnumber, arrivaldate, unload_date, qtyrcvd, uom, '||
  '    opltpallettqty, spltpallettqty, hdrpassthruchar01, invstatus_exceptions, overdim, hazardous, dtlpassthruchar01, whseloc, '||
  '    dtlpassthruchar08, totalweight';

debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end create_944_cfs_data;

procedure create_944_line_data(oh orderhdr%rowtype) is
begin

debugmsg('create line data');
debugmsg('create 944_dtl table');
select count(1)
  into cntRows
  from user_tables
 where table_name = 'RCPT_NOTE_944_DTL_' || strSuffix;
if cntRows = 0 then
  cmdSql := 'create table RCPT_NOTE_944_DTL_' || strSuffix ||
  ' (CUSTID VARCHAR2(10),ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,' ||
  ' LINE_NUMBER VARCHAR2(255),item varchar2(50) not null,UPC VARCHAR2(20),' ||
  ' DESCRIPTION VARCHAR2(255) not null,LOTNUMBER VARCHAR2(30),UOM VARCHAR2(4),' ||
  ' QTYRCVD NUMBER,CUBERCVD NUMBER,QTYRCVDGOOD NUMBER,CUBERCVDGOOD NUMBER,' ||
  ' QTYRCVDDMGD NUMBER,QTYORDER NUMBER,WEIGHTITEM NUMBER(17,8),WEIGHTQUALIFIER CHAR(1),' ||
  ' WEIGHTUNITCODE CHAR(1),VOLUME NUMBER,UOM_VOLUME CHAR(2), ' ||
  ' DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),DTLPASSTHRUCHAR03 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR04 VARCHAR2(255),DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),DTLPASSTHRUCHAR09 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR10 VARCHAR2(255),DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),DTLPASSTHRUCHAR15 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR16 VARCHAR2(255),DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
   'DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255), ' ||
  ' DTLPASSTHRUCHAR21 VARCHAR2(255),DTLPASSTHRUCHAR22 VARCHAR2(255),DTLPASSTHRUCHAR23 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR24 VARCHAR2(255),DTLPASSTHRUCHAR25 VARCHAR2(255),DTLPASSTHRUCHAR26 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR27 VARCHAR2(255),DTLPASSTHRUCHAR28 VARCHAR2(255),DTLPASSTHRUCHAR29 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR30 VARCHAR2(255),DTLPASSTHRUCHAR31 VARCHAR2(255),DTLPASSTHRUCHAR32 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR33 VARCHAR2(255),DTLPASSTHRUCHAR34 VARCHAR2(255),DTLPASSTHRUCHAR35 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR36 VARCHAR2(255),DTLPASSTHRUCHAR37 VARCHAR2(255),DTLPASSTHRUCHAR38 VARCHAR2(255),' ||
   'DTLPASSTHRUCHAR39 VARCHAR2(255),DTLPASSTHRUCHAR40 VARCHAR2(255), ' ||
  ' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM06 NUMBER(16,4),DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),'||
  ' DTLPASSTHRUNUM11 NUMBER(16,4),DTLPASSTHRUNUM12 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM13 NUMBER(16,4),DTLPASSTHRUNUM14 NUMBER(16,4),DTLPASSTHRUNUM15 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM16 NUMBER(16,4),DTLPASSTHRUNUM17 NUMBER(16,4),DTLPASSTHRUNUM18 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM19 NUMBER(16,4),DTLPASSTHRUNUM20 NUMBER(16,4),'||
  ' DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,' ||
  ' DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2),' ||
  ' QTYONHOLD NUMBER, QTYRCVD_INVSTATUS VARCHAR2(2),'||
  ' serialnumber varchar2(2000),useritem1 varchar2(20),useritem2 varchar2(20),useritem3 varchar2(20),'||
  ' orig_line_number number, unload_date date, condition varchar2(2), invclass varchar2(2), ' ||
  ' manufacturedate date, invstatus varchar2(2), link_lotnumber varchar2(30), ' ||
  ' lineseq number(3), subpart varchar2(20),CUBERCVDDMGD NUMBER, '||
  ' ITMPASSTHRUCHAR01 VARCHAR2(255), ITMPASSTHRUCHAR02 VARCHAR2(255), ITMPASSTHRUCHAR03 VARCHAR2(255), ' ||
  ' ITMPASSTHRUCHAR04 VARCHAR2(255), ITMPASSTHRUCHAR05 VARCHAR2(255), ITMPASSTHRUCHAR06 VARCHAR2(255), ' ||
  ' ITMPASSTHRUCHAR07 VARCHAR2(255), ITMPASSTHRUCHAR08 VARCHAR2(255), ITMPASSTHRUCHAR09 VARCHAR2(255), ' ||
  ' ITMPASSTHRUCHAR10 VARCHAR2(255), ITMPASSTHRUNUM01 NUMBER(16,4), ITMPASSTHRUNUM02 NUMBER(16,4),  ' ||
  ' ITMPASSTHRUNUM03 NUMBER(16,4), ITMPASSTHRUNUM04 NUMBER(16,4), ITMPASSTHRUNUM05 NUMBER(16,4), '||
  ' ITMPASSTHRUNUM06 NUMBER(16,4), ITMPASSTHRUNUM07 NUMBER(16,4), ITMPASSTHRUNUM08 NUMBER(16,4), '||
  ' ITMPASSTHRUNUM09 NUMBER(16,4), ITMPASSTHRUNUM10 NUMBER(16,4), GTIN VARCHAR2(14))';
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
end if;
debugmsg('create test');
if (nvl(rtrim(in_invclass_yn),'N')) = 'Y' then
  create_944_line_data_by_invcls(oh);
elsif (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') = 'Q') then
  create_944_line_data_returns(oh);
  if nvl(rtrim(in_invstatus_yn),'N') = 'Y' then
      cmdSql := 'delete  RCPT_NOTE_944_DTL_' || strSuffix || ' where orderid = ' || OH.orderid || ' and shipid = ' || oh.shipid;
      debugmsg(cmdSql);
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);
      create_944_line_data_by_is_rtn(oh);
  end if;
elsif (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') = 'R') then
  create_944_line_data_receipts(oh);
elsif Upper(nvl(in_summarize_manu_yn,'N')) = 'Y' then
  create_944_line_data_by_manu(oh);
elsif (nvl(rtrim(in_invstatus_yn),'N')) = 'Y' then
  create_944_line_data_by_invsts(oh);
elsif Upper(nvl(in_summarize_lots_yn,'N')) != 'Y' then
  create_944_line_data_by_lot(oh);
elsif (nvl(rtrim(in_dtlrcptlines_yn),'N')) = 'Y' then
   if oh.ordertype = 'R' then
      create_944_line_data_dtlrcptr(oh);
   elsif oh.ordertype = 'Q' then
      create_944_line_data_dtlrcptq(oh);
   end if;
else
  create_944_line_data_by_item(oh);
end if;

if nvl(in_create_944_cfs_data_yn,'N') = 'Y' then
  create_944_cfs_data(oh);
end if;

end;

procedure create_note_data(oh orderhdr%rowtype)
is
begin

if oh.comment1 is null then
  return;
end if;

l_seq := 0;
cmt := substr(oh.comment1,1,4000);
len := length(cmt);
tcur := 1;
while tcur < len loop
   l_seq := l_seq + 1;
   tpos := instr(cmt, chr(10), tcur);
   if tpos = 0 then
      tpos := len + 1; -- was +2
   end if;

   tcnt := tpos - tcur + 1;
   if tcnt > 0 then
    str := translate(substr(cmt,tcur, least(100,tcnt)),
        'A'||chr(13)||chr(10),'A');
   else
    str := ' ';
   end if;
   qpos := instr(str,'-');
   if qpos > 6 then
      qpos := 0;
   end if;
   if qpos > 1 then
    qual := substr(str, 1, least(4,qpos - 1));
    str := substr(str, qpos + 1);
   else
    qual := 'WHI';
   end if;
   tcur := tpos + 1;
   insert into rcptnote944noteex
   (
    sessionid,
    custid,
    orderid,
    shipid,
    sequence,
    qualifier,
    note
   )
   values
   (
    strsuffix,
    oh.custid,
    oh.orderid,
    oh.shipid,
    l_seq,
    qual,
    substr(str,1,80)
   );

end loop;

end;

procedure create_944_ide_over_short_data(od orderdtl%rowtype)
is
begin

l_qty := nvl(od.qtyrcvd,0) - nvl(od.qtyorder,0);
if l_qty is null then
  l_qty := 0;
end if;

insert into rcptnote944ideex
(
  sessionid,
  custid,
  orderid,
  shipid,
  item,
  lotnumber,
  qty,
  uom,
  condition,
  damagereason
)
values
(
  strsuffix,
  od.custid,
  od.orderid,
  od.shipid,
  od.item,
  od.lotnumber,
  decode(sign(l_qty), -1, -l_qty, l_qty),
  od.uom,
  decode(sign(l_qty), -1, '02','03'),
  null
);

end;

procedure create_944_ide_condition_data(oh orderhdr%rowtype, odr c_orddtlrcpt%rowtype)
is
begin

if (upper(nvl(in_exclude_ide_av_invstatus_yn,'N')) = 'Y') and
   (odr.invstatus = 'AV') then
  return;
end if;

insert into rcptnote944ideex
(
  sessionid,
  custid,
  orderid,
  shipid,
  item,
  lotnumber,
  qty,
  uom,
  condition,
  damagereason
)
values
(
  strsuffix,
  oh.custid,
  oh.orderid,
  oh.shipid,
  odr.item,
  rtrim(odr.lotnumber),
  nvl(odr.qtyrcvd,0),
  odr.uom,
  decode(odr.invstatus, 'DM', '01', '09'),
  nvl(odr.cond, 'NR')
);

end;

procedure insert_lip_data is
TYPE cur_type is REF CURSOR;
cr cur_type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_statusupdate date;
l_UPC varchar2(20);
l_lineseq number(3);
l_invstatus varchar2(32);
l_manufacturedate date;
l_expirationdate date;
cursor curOrderDtl(in_orderid number, in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderDtlRcpt(in_orderid number, in_shipid number, in_item varchar2, in_lotnumber varchar2) is
  select * from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)');

cursor curInventoryStatus(in_invstatus varchar2) is
   select descr
   from inventorystatus
   where code = in_invstatus;

cursor curItem(in_custid char, in_item char)
IS
 select *
   from custitemview
  where custid = in_custid
    and item = in_item;
itm curItem%rowtype;

cursor curManufactureDate(in_lpid varchar2)
IS
  select manufacturedate
    from plate
    where lpid = in_lpid
UNION
  select manufacturedate
    from deletedplate
    where lpid = in_lpid;

cursor curExpirationDate(in_lpid varchar2)
IS
  select expirationdate
    from plate
    where lpid = in_lpid
UNION
  select expirationdate
    from deletedplate
    where lpid = in_lpid;

begin
   debugmsg ('insert_lip_data ');
   cmdsql := 'select orderid, shipid from rcpt_note_944_hdr_' || strsuffix;
   debugmsg( cmdsql);
   open cr for cmdsql;

   loop
      fetch cr into l_orderid, l_shipid;
      exit when cr%notfound;
      debugmsg('order ' ||l_orderid);
      l_lineseq := 0;
      for OD in curOrderDtl(l_orderid,l_shipid)
      loop
         debugmsg('OD ' || OD.item || ' '|| OD.lotnumber);
         begin
            select upc into l_UPC
              from custitemupcview
              where custid = od.custid
                and item = od.item;
         exception when others then
            l_UPC := null;
         end;
         itm := null;
         open curItem(od.custid,od.item);
         fetch curItem into itm;
         close curItem;
         select statusupdate into l_statusupdate
            from orderhdr
            where orderid = l_orderid
              and shipid = l_shipid;
          for ODR in curOrderDtlRcpt(l_orderid,l_shipid,OD.item, OD.lotnumber) loop
             LineWeight := zci.item_weight(od.custid,od.item,od.uom) * ODR.qtyrcvd;
             LineCube := zci.item_cube(od.custid,od.item,od.uom) * ODR.qtyrcvd;
             LineWeightGood := zci.item_weight(od.custid,od.item,od.uom) * ODR.qtyrcvdgood;
             LineCubeGood := zci.item_cube(od.custid,od.item,od.uom) * ODR.qtyrcvdgood;
             LineWeightDmgd := zci.item_weight(od.custid,od.item,od.uom) * ODR.qtyrcvddmgd;
             LineCubeDmgd := zci.item_cube(od.custid,od.item,od.uom) * ODR.qtyrcvddmgd;
             LineWeightOnHold := 0;
             LineCubeOnHold := 0;
             l_invstatus := null;
             open curInventoryStatus(ODR.invstatus);
             fetch curInventoryStatus into l_invstatus;
             close curInventoryStatus;
             l_manufacturedate := null;
             open curManufactureDate(ODR.lpid);
             fetch curManufactureDate into l_manufacturedate;
             close curManufactureDate;
             l_expirationdate := null;
             open curExpirationDate(ODR.lpid);
             fetch curExpirationDate into l_expirationdate;
             close curExpirationDate;
             curFunc := dbms_sql.open_cursor;
             debugmsg('insert into rcpt_note_944_lip 1 ');
             l_lineseq := l_lineseq + 1;
             dbms_sql.parse(curFunc, 'insert into rcpt_note_944_lip_' || strSuffix ||
             ' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
             ':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
             ':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
             ':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
             ':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
             ':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
             ':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
             ':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
             ':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
             ':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
             ':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
             ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
             ':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
             ':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :LPID, :INVSTATUS, :LINESEQ, ' ||
             ':WEIGHT, :INVSTATUSDESC, :MANUFACTUREDATE, :LPIDLAST6, :EXPIRATIONDATE)',
                       dbms_sql.native);
             dbms_sql.bind_variable(curFunc, ':CUSTID', OD.CUSTID);
             dbms_sql.bind_variable(curFunc, ':ORDERID', OD.ORDERID);
             dbms_sql.bind_variable(curFunc, ':SHIPID', OD.SHIPID);
             dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', OD.DTLPASSTHRUNUM10);
             dbms_sql.bind_variable(curFunc, ':ITEM', OD.ITEM);
             dbms_sql.bind_variable(curFunc, ':UPC', l_UPC);
             dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
             dbms_sql.bind_variable(curFunc, ':LOTNUMBER', OD.LOTNUMBER);
             dbms_sql.bind_variable(curFunc, ':UOM', OD.UOM);
             dbms_sql.bind_variable(curFunc, ':QTYRCVD', ODR.qtyrcvd);
             dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
             dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', qtyLineGood);
             dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
             dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', qtyLineDmgd);
             dbms_sql.bind_variable(curFunc, ':QTYORDER', OD.QTYORDER);
             dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
             dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
             dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
             dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
             dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', OD.DTLPASSTHRUCHAR01);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', OD.DTLPASSTHRUCHAR02);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', OD.DTLPASSTHRUCHAR03);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', OD.DTLPASSTHRUCHAR04);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', OD.DTLPASSTHRUCHAR05);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', OD.DTLPASSTHRUCHAR06);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', OD.DTLPASSTHRUCHAR07);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', OD.DTLPASSTHRUCHAR08);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', OD.DTLPASSTHRUCHAR09);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', OD.DTLPASSTHRUCHAR10);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', OD.DTLPASSTHRUCHAR11);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', OD.DTLPASSTHRUCHAR12);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', OD.DTLPASSTHRUCHAR13);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', OD.DTLPASSTHRUCHAR14);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', OD.DTLPASSTHRUCHAR15);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', OD.DTLPASSTHRUCHAR16);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', OD.DTLPASSTHRUCHAR17);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', OD.DTLPASSTHRUCHAR18);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', OD.DTLPASSTHRUCHAR19);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', OD.DTLPASSTHRUCHAR20);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', OD.DTLPASSTHRUNUM01);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', OD.DTLPASSTHRUNUM02);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', OD.DTLPASSTHRUNUM03);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', OD.DTLPASSTHRUNUM04);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', OD.DTLPASSTHRUNUM05);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', OD.DTLPASSTHRUNUM06);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', OD.DTLPASSTHRUNUM07);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', OD.DTLPASSTHRUNUM08);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', OD.DTLPASSTHRUNUM09);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', OD.DTLPASSTHRUNUM10);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', OD.DTLPASSTHRUDATE01);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', OD.DTLPASSTHRUDATE02);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', OD.DTLPASSTHRUDATE03);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', OD.DTLPASSTHRUDATE04);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', OD.DTLPASSTHRUDOLL01);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', OD.DTLPASSTHRUDOLL02);
             dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', OD.DTLPASSTHRUDOLL02);
             dbms_sql.bind_variable(curFunc, ':QTYONHOLD', 0);
             dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', 0);
             dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', ODR.serialnumber);
             dbms_sql.bind_variable(curFunc, ':USERITEM1', ODR.useritem1);
             dbms_sql.bind_variable(curFunc, ':USERITEM2', ODR.useritem2);
             dbms_sql.bind_variable(curFunc, ':USERITEM3', ODR.useritem3);
             dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', '');
             dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', l_statusupdate);
             dbms_sql.bind_variable(curFunc, ':CONDITION', '');
             dbms_sql.bind_variable(curFunc, ':INVCLASS', ODR.inventoryclass);
             dbms_sql.bind_variable(curFunc, ':LPID', ODR.lpid);
             dbms_sql.bind_variable(curFunc, ':INVSTATUS', ODR.invstatus);
             dbms_sql.bind_variable(curFunc, ':LINESEQ', l_lineseq);
             dbms_sql.bind_variable(curFunc, ':WEIGHT', itm.WEIGHT * ODR.qtyrcvd);
             dbms_sql.bind_variable(curFunc, ':INVSTATUSDESC', l_invstatus);
             dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', l_manufacturedate);
             dbms_sql.bind_variable(curFunc, ':LPIDLAST6', zim7.lpid_last6(ODR.lpid));
             dbms_sql.bind_variable(curFunc, ':EXPIRATIONDATE', l_expirationdate);
             cntRows := dbms_sql.execute(curFunc);
             dbms_sql.close_cursor(curFunc);
          end loop; --for ODR
       end loop; -- for OD


   end loop; --fetch cr

   close cr;

end insert_lip_data;

PROCEDURE insert_lip_data_line IS
TYPE cur_type IS REF CURSOR;
cr cur_type;
l_orderid ORDERHDR.orderid%TYPE;
l_shipid ORDERHDR.shipid%TYPE;
l_statusupdate DATE;
l_UPC VARCHAR2(20);
l_linenumber orderdtlline.linenumber%type;
l_manufacturedate date;
l_qty orderdtlline.qty%type;
l_lineseq number(3);
type odl_rcd is record (
  item         orderdtlline.item%type,
  lotnumber    orderdtlline.lotnumber%type,
  linenumber   orderdtlline.linenumber%type,
  qty          orderdtl.qtyorder%type
);

type odl_tbl is table of odl_rcd
     index by binary_integer;

odl odl_tbl;
odlx integer;
odlfound boolean;


CURSOR curOrderDtl(in_orderid NUMBER, in_shipid NUMBER) IS
  SELECT *
    FROM ORDERDTL
   WHERE orderid = in_orderid
     AND shipid = in_shipid;

CURSOR curOrderDtlRcpt(in_orderid NUMBER, in_shipid NUMBER, in_item VARCHAR2) IS
  SELECT * FROM ORDERDTLRCPT
   WHERE orderid = in_orderid
     AND shipid = in_shipid
     AND item = in_item;

CURSOR curItem(in_custid CHAR, in_item CHAR)
IS
 SELECT *
   FROM custitemview
  WHERE custid = in_custid
    AND item = in_item;
itm curItem%ROWTYPE;

cursor C_ODL(in_orderid number, in_shipid number)
IS
select
      od.ITEM as item,
      od.LOTNUMBER as lotnumber,
      nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
      nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
 from orderdtlline ol, orderdtl od
where od.orderid = in_orderid
  and od.shipid = in_shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
order by 1,2,3;

procedure write_lip(OD orderdtl%rowtype, in_linenumber number, in_qty number,
                    in_qtyrcvdgood number, in_qtyrcvddmgd number, in_lpid varchar2)
is
CURSOR curodrInventoryclass(in_orderid NUMBER, in_shipid NUMBER, in_item VARCHAR2) IS
  SELECT inventoryclass FROM ORDERDTLRCPT
   WHERE orderid = in_orderid
     AND shipid = in_shipid
     AND item = in_item;
odrInventoryclass orderdtlrcpt.inventoryclass%type;

CURSOR curodrInvstatus(in_orderid NUMBER, in_shipid NUMBER, in_item VARCHAR2) IS
  SELECT invstatus FROM ORDERDTLRCPT
   WHERE orderid = in_orderid
     AND shipid = in_shipid
     AND item = in_item;
odrInvstatus orderdtlrcpt.invstatus%type;
cursor curManufactureDate(in_lpid varchar2)
IS
  select manufacturedate
    from plate
    where lpid = in_lpid
UNION
  select manufacturedate
    from deletedplate
    where lpid = in_lpid;

begin
   LineWeight := zci.item_weight(od.custid,od.item,od.uom) * in_qty;
   LineCube := zci.item_cube(od.custid,od.item,od.uom) * in_qty;
   LineWeightGood := zci.item_weight(od.custid,od.item,od.uom) * in_qtyrcvdgood;
   LineCubeGood := zci.item_cube(od.custid,od.item,od.uom) * in_qtyrcvdgood;
   LineWeightDmgd := zci.item_weight(od.custid,od.item,od.uom) * in_qtyrcvddmgd;
   LineCubeDmgd := zci.item_cube(od.custid,od.item,od.uom) * in_qtyrcvddmgd;
   LineWeightOnHold := 0;
   LineCubeOnHold := 0;
   odrInventoryclass := null;
   open curodrInventoryclass(OD.orderid,OD.shipid,OD.item);
   fetch curodrInventoryclass into odrInventoryclass;
   close curodrInventoryclass;
   odrInvstatus := null;
   open curodrInvstatus(OD.orderid,OD.shipid,OD.item);
   fetch curodrInvstatus into odrInvstatus;
   close curodrInvstatus;
   open curManufactureDate(ODR.lpid);
   fetch curManufactureDate into l_manufacturedate;
   close curManufactureDate;
   curFunc := dbms_sql.open_cursor;
   l_lineseq := l_lineseq + 1;
   debugmsg('insert into rcpt_note_944_lip');
   dbms_sql.parse(curFunc, 'insert into rcpt_note_944_lip_' || strSuffix ||
   ' values (:CUSTID,:ORDERID,:SHIPID,:LINE_NUMBER,:ITEM,:UPC,:DESCRIPTION,' ||
   ':LOTNUMBER,:UOM,:QTYRCVD,:CUBERCVD,:QTYRCVDGOOD,:CUBERCVDGOOD,:QTYRCVDDMGD,' ||
   ':QTYORDER,:WEIGHTITEM,:WEIGHTQUALIFIER,:WEIGHTUNITCODE,:VOLUME,:UOM_VOLUME,' ||
   ':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
   ':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
   ':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
   ':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
   ':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
   ':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
   ':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
   ':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
   ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,' ||
   ':QTYONHOLD,:QTYRCVD_INVSTATUS,:SERIALNUMBER,:USERITEM1,:USERITEM2,:USERITEM3,'||
   ':ORIG_LINE_NUMBER,:UNLOAD_DATE,:CONDITION, :INVCLASS, :LPID, :INVSTATUS, :LINESEQ, ' ||
   ':WEIGHT, :INVSTATUSDESC, :MANUFACTUREDATE, :LPIDLAST6)',
             dbms_sql.native);
   dbms_sql.bind_variable(curFunc, ':CUSTID', OD.CUSTID);
   dbms_sql.bind_variable(curFunc, ':ORDERID', OD.ORDERID);
   dbms_sql.bind_variable(curFunc, ':SHIPID', OD.SHIPID);
   dbms_sql.bind_variable(curFunc, ':LINE_NUMBER', in_linenumber);
   dbms_sql.bind_variable(curFunc, ':ITEM', OD.ITEM);
   dbms_sql.bind_variable(curFunc, ':UPC', l_UPC);
   dbms_sql.bind_variable(curFunc, ':DESCRIPTION', itm.descr);
   dbms_sql.bind_variable(curFunc, ':LOTNUMBER', OD.LOTNUMBER);
   dbms_sql.bind_variable(curFunc, ':UOM', OD.UOM);
   dbms_sql.bind_variable(curFunc, ':QTYRCVD', in_qty);
   dbms_sql.bind_variable(curFunc, ':CUBERCVD', LineCube);
   dbms_sql.bind_variable(curFunc, ':QTYRCVDGOOD', qtyLineGood);
   dbms_sql.bind_variable(curFunc, ':CUBERCVDGOOD', LineCubeGood);
   dbms_sql.bind_variable(curFunc, ':QTYRCVDDMGD', qtyLineDmgd);
   dbms_sql.bind_variable(curFunc, ':QTYORDER', OD.QTYORDER);
   dbms_sql.bind_variable(curFunc, ':WEIGHTITEM', itm.WEIGHT);
   dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', 'N');
   dbms_sql.bind_variable(curFunc, ':WEIGHTUNITCODE', 'L');
   dbms_sql.bind_variable(curFunc, ':VOLUME', LineCube/1728);
   dbms_sql.bind_variable(curFunc, ':UOM_VOLUME', 'CF');
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', OD.DTLPASSTHRUCHAR01);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', OD.DTLPASSTHRUCHAR02);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', OD.DTLPASSTHRUCHAR03);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', OD.DTLPASSTHRUCHAR04);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', OD.DTLPASSTHRUCHAR05);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', OD.DTLPASSTHRUCHAR06);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', OD.DTLPASSTHRUCHAR07);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', OD.DTLPASSTHRUCHAR08);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', OD.DTLPASSTHRUCHAR09);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', OD.DTLPASSTHRUCHAR10);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', OD.DTLPASSTHRUCHAR11);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', OD.DTLPASSTHRUCHAR12);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', OD.DTLPASSTHRUCHAR13);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', OD.DTLPASSTHRUCHAR14);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', OD.DTLPASSTHRUCHAR15);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', OD.DTLPASSTHRUCHAR16);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', OD.DTLPASSTHRUCHAR17);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', OD.DTLPASSTHRUCHAR18);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', OD.DTLPASSTHRUCHAR19);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', OD.DTLPASSTHRUCHAR20);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', OD.DTLPASSTHRUNUM01);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', OD.DTLPASSTHRUNUM02);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', OD.DTLPASSTHRUNUM03);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', OD.DTLPASSTHRUNUM04);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', OD.DTLPASSTHRUNUM05);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', OD.DTLPASSTHRUNUM06);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', OD.DTLPASSTHRUNUM07);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', OD.DTLPASSTHRUNUM08);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', OD.DTLPASSTHRUNUM09);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', in_linenumber);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', OD.DTLPASSTHRUDATE01);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', OD.DTLPASSTHRUDATE02);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', OD.DTLPASSTHRUDATE03);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', OD.DTLPASSTHRUDATE04);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', OD.DTLPASSTHRUDOLL01);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', OD.DTLPASSTHRUDOLL02);
   dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', OD.DTLPASSTHRUDOLL02);
   dbms_sql.bind_variable(curFunc, ':QTYONHOLD', 0);
   dbms_sql.bind_variable(curFunc, ':QTYRCVD_INVSTATUS', 0);
   dbms_sql.bind_variable(curFunc, ':SERIALNUMBER', '');
   dbms_sql.bind_variable(curFunc, ':USERITEM1', '');
   dbms_sql.bind_variable(curFunc, ':USERITEM2', '');
   dbms_sql.bind_variable(curFunc, ':USERITEM3', '');
   dbms_sql.bind_variable(curFunc, ':ORIG_LINE_NUMBER', '');
   dbms_sql.bind_variable(curFunc, ':UNLOAD_DATE', l_statusupdate);
   dbms_sql.bind_variable(curFunc, ':CONDITION', '');
   dbms_sql.bind_variable(curFunc, ':INVCLASS', odrInventoryclass);
   dbms_sql.bind_variable(curFunc, ':LPID', in_lpid);
   dbms_sql.bind_variable(curFunc, ':INVSTATUS', odrInvstatus);
   dbms_sql.bind_variable(curFunc, ':LINESEQ', l_lineseq);
   dbms_sql.bind_variable(curFunc, ':WEIGHT', itm.WEIGHT * ODR.qtyrcvd);
   dbms_sql.bind_variable(curFunc, ':INVSTATUSDESC', '');
   dbms_sql.bind_variable(curFunc, ':MANUFACTUREDATE', l_manufacturedate);
   dbms_sql.bind_variable(curFunc, ':LPIDLAST6', zim7.lpid_last6(ODR.lpid));

   cntRows := dbms_sql.EXECUTE(curFunc);
   dbms_sql.close_cursor(curFunc);

end write_lip;

procedure distribute_odl(in_custid varchar2, in_item varchar2, in_lot varchar2,
    in_uom varchar2, in_qty IN OUT number, OD orderdtl%rowtype,
    in_qtyrcvdgood number, in_qtyrcvddamaged number, in_lpid varchar2)
is
begin
    for odlx in 1..odl.count loop
        debugmsg('Check ODL:'||odl(odlx).item
            ||'/'||odl(odlx).lotnumber
            ||'/'||odl(odlx).linenumber
            ||'/'||odl(odlx).qty);
        if in_item = odl(odlx).item
         and nvl(in_lot,'(none)') = nvl(odl(odlx).lotnumber,'(none)')
         and odl(odlx).qty > 0 then
            if in_qty <= odl(odlx).qty then
                l_linenumber := odl(odlx).linenumber;
                l_qty := in_qty;
                odl(odlx).qty := odl(odlx).qty - in_qty;
                in_qty := 0;
                debugmsg('Adding < CNT for:'||l_qty);
                write_lip(OD,l_linenumber, l_qty, in_qtyrcvdgood, in_qtyrcvddamaged, in_lpid);
                exit;
            else
                l_linenumber := odl(odlx).linenumber;
                l_qty := odl(odlx).qty;
                in_qty := in_qty - odl(odlx).qty;
                odl(odlx).qty := 0;
                write_lip(OD,l_linenumber, l_qty, in_qtyrcvdgood, in_qtyrcvddamaged, in_lpid);
            end if;
        end if;
    end loop;
    if in_qty > 0 then
        l_linenumber := null;
        l_qty := in_qty;
        debugmsg('Adding no match CNT for:'||l_qty);
        write_lip(OD,l_linenumber, l_qty, in_qtyrcvdgood, in_qtyrcvddamaged, in_lpid);
    end if;
end distribute_odl;

BEGIN
   debugmsg ('insert_lip_data_line ');
   l_lineseq := 0;
   cmdsql := 'select orderid, shipid from rcpt_note_944_hdr_' || strsuffix;
   debugmsg( cmdsql);
   OPEN cr FOR cmdsql;

   LOOP
      FETCH cr INTO l_orderid, l_shipid;
      EXIT WHEN cr%NOTFOUND;
      debugmsg('order ' ||l_orderid);
      FOR OD IN curOrderDtl(l_orderid,l_shipid)
      LOOP
         BEGIN
            SELECT upc INTO l_UPC
              FROM custitemupcview
              WHERE custid = OD.custid
                AND item = OD.item;
         EXCEPTION WHEN OTHERS THEN
            l_UPC := NULL;
         END;
         itm := NULL;
         OPEN curItem(OD.custid,OD.item);
         FETCH curItem INTO itm;
         CLOSE curItem;
         SELECT statusupdate INTO l_statusupdate
            FROM ORDERHDR
            WHERE orderid = l_orderid
              AND shipid = l_shipid;

         BEGIN
           SELECT COUNT(1) INTO cntLines
              FROM ORDERDTLLINE ol
              WHERE ol.orderid = OD.orderid
                AND ol.shipid = OD.shipid
                AND ol.item = OD.item
                AND NVL(ol.lotnumber,'(none)') = NVL(OD.lotnumber,'(none)')
                AND NVL(ol.xdock,'N') = 'N';
         EXCEPTION WHEN OTHERS THEN
            cntLines := 1;
         END;
         IF cntLines = 0 THEN
            cntLines := 1;
         END IF;
         BEGIN
           SELECT COUNT(1)
             INTO cntApprovals
             FROM ORDERDTLLINE ol
             WHERE ol.orderid = od.orderid
               AND ol.shipid = od.shipid
               AND ol.item = od.item
               AND NVL(ol.lotnumber,'(none)') = NVL(od.lotnumber,'(none)')
               AND NVL(ol.qtyapproved,0) != 0
               AND NVL(ol.xdock,'N') = 'N';
         EXCEPTION WHEN OTHERS THEN
           cntApprovals := 0;
         END;
         cntLineSeq := 0;
         for crec in C_ODL(l_orderid, l_shipid) loop
            odlx := odl.count + 1;
            odl(odlx).item := crec.item;
            odl(odlx).lotnumber := crec.lotnumber;
            odl(odlx).linenumber := crec.linenumber;
            odl(odlx).qty := crec.qty;

            debugmsg('Add ODL:'||odl(odlx).item
              ||'/'||odl(odlx).lotnumber
              ||'/'||odl(odlx).linenumber
              ||'/'||odl(odlx).qty);

         end loop;
         FOR ODR IN curOrderDtlRcpt(l_orderid,l_shipid,OD.item) LOOP
           distribute_odl(OD.custid, OD.item, OD.lotnumber, OD.uom, ODR.qtyrcvd, OD,
                          ODR.qtyrcvdgood, ODR.qtyrcvddmgd, ODR.lpid);

          END LOOP; --for ODR
       END LOOP; -- for OD
   END LOOP; --fetch cr
   CLOSE cr;
END insert_lip_data_line;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'RCPT_NOTE_944_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('get customer');
cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Create HDR view

if nvl(in_orderid,0) != 0 then
   l_condition := ' and O.orderid = '||to_char(in_orderid)
               || ' and O.shipid = '||to_char(in_shipid)
               || ' ';
elsif nvl(in_loadno,0) != 0 then
   l_condition := ' and O.loadno = '||to_char(in_loadno)
               || ' ';
elsif in_begdatestr is not null then
   l_condition :=  ' and O.statusupdate >= to_date(''' || in_begdatestr
               || ''', ''yyyymmddhh24miss'')'
               ||  ' and O.statusupdate <  to_date(''' || in_enddatestr
               || ''', ''yyyymmddhh24miss'') ';
end if;
if in_exclude_source is not null then
   l_condition := l_condition || ' and O.source <> ''' || in_exclude_source || ''' ';
end if;

if l_condition is null then
   out_errorno := -2;
   out_msg := 'Invalid Selection Criteria ';
   return;
end if;

debugmsg('Condition is ' || l_condition);

debugmsg('create table RCPT_NOTE_944_HDR_' || strSuffix);
cmdSql := 'create table RCPT_NOTE_944_HDR_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,LOADNO NUMBER(7),ORDERID NUMBER(9) not null,' ||
' SHIPID NUMBER(2) not null,COMPANY CHAR(1),WAREHOUSE CHAR(1),CUST_ORDERID VARCHAR2(20),' ||
' CUST_SHIPID VARCHAR2(255),SHIPFROM VARCHAR2(255),SHIPFROMID VARCHAR2(255),' ||
' RECEIPT_DATE DATE,VENDOR VARCHAR2(10),VENDOR_DESC VARCHAR2(40),BILL_OF_LADING VARCHAR2(40),' ||
' CARRIER VARCHAR2(10),ROUTING VARCHAR2(255),PO VARCHAR2(20),ORDER_TYPE VARCHAR2(1) not null,' ||
' QTYORDER NUMBER(10),QTYRCVD NUMBER,QTYRCVDGOOD NUMBER,QTYRCVDDMGD NUMBER,' ||
' REPORTING_CODE VARCHAR2(255),SOME_DATE DATE,UNLOAD_DATE DATE,WHSE_RECEIPT_NUM VARCHAR2(81),' ||
' TRANSMETH_TYPE VARCHAR2(1),PACKER_NUMBER VARCHAR2(255),VENDOR_ORDER_NUM VARCHAR2(255),' ||
' WAREHOUSE_NAME VARCHAR2(40),WAREHOUSE_ID VARCHAR2(255),DEPOSITOR_NAME VARCHAR2(255),' ||
' DEPOSITOR_ID VARCHAR2(255),' ||
' HDRPASSTHRUCHAR01 VARCHAR2(255),HDRPASSTHRUCHAR02 VARCHAR2(255),HDRPASSTHRUCHAR03 VARCHAR2(255),HDRPASSTHRUCHAR04 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR05 VARCHAR2(255),HDRPASSTHRUCHAR06 VARCHAR2(255),HDRPASSTHRUCHAR07 VARCHAR2(255),HDRPASSTHRUCHAR08 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR09 VARCHAR2(255),HDRPASSTHRUCHAR10 VARCHAR2(255),HDRPASSTHRUCHAR11 VARCHAR2(255),HDRPASSTHRUCHAR12 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR13 VARCHAR2(255),HDRPASSTHRUCHAR14 VARCHAR2(255),HDRPASSTHRUCHAR15 VARCHAR2(255),HDRPASSTHRUCHAR16 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR17 VARCHAR2(255),HDRPASSTHRUCHAR18 VARCHAR2(255),HDRPASSTHRUCHAR19 VARCHAR2(255),HDRPASSTHRUCHAR20 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR21 VARCHAR2(255),HDRPASSTHRUCHAR22 VARCHAR2(255),HDRPASSTHRUCHAR23 VARCHAR2(255),HDRPASSTHRUCHAR24 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR25 VARCHAR2(255),HDRPASSTHRUCHAR26 VARCHAR2(255),HDRPASSTHRUCHAR27 VARCHAR2(255),HDRPASSTHRUCHAR28 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR29 VARCHAR2(255),HDRPASSTHRUCHAR30 VARCHAR2(255),HDRPASSTHRUCHAR31 VARCHAR2(255),HDRPASSTHRUCHAR32 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR33 VARCHAR2(255),HDRPASSTHRUCHAR34 VARCHAR2(255),HDRPASSTHRUCHAR35 VARCHAR2(255),HDRPASSTHRUCHAR36 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR37 VARCHAR2(255),HDRPASSTHRUCHAR38 VARCHAR2(255),HDRPASSTHRUCHAR39 VARCHAR2(255),HDRPASSTHRUCHAR40 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR41 VARCHAR2(255),HDRPASSTHRUCHAR42 VARCHAR2(255),HDRPASSTHRUCHAR43 VARCHAR2(255),HDRPASSTHRUCHAR44 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR45 VARCHAR2(255),HDRPASSTHRUCHAR46 VARCHAR2(255),HDRPASSTHRUCHAR47 VARCHAR2(255),HDRPASSTHRUCHAR48 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR49 VARCHAR2(255),HDRPASSTHRUCHAR50 VARCHAR2(255),HDRPASSTHRUCHAR51 VARCHAR2(255),HDRPASSTHRUCHAR52 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR53 VARCHAR2(255),HDRPASSTHRUCHAR54 VARCHAR2(255),HDRPASSTHRUCHAR55 VARCHAR2(255),HDRPASSTHRUCHAR56 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR57 VARCHAR2(255),HDRPASSTHRUCHAR58 VARCHAR2(255),HDRPASSTHRUCHAR59 VARCHAR2(255),HDRPASSTHRUCHAR60 VARCHAR2(255),' ||
' HDRPASSTHRUNUM01 NUMBER(16,4),HDRPASSTHRUNUM02 NUMBER(16,4),HDRPASSTHRUNUM03 NUMBER(16,4),' ||
' HDRPASSTHRUNUM04 NUMBER(16,4),HDRPASSTHRUNUM05 NUMBER(16,4),HDRPASSTHRUNUM06 NUMBER(16,4),' ||
' HDRPASSTHRUNUM07 NUMBER(16,4),HDRPASSTHRUNUM08 NUMBER(16,4),HDRPASSTHRUNUM09 NUMBER(16,4),' ||
' HDRPASSTHRUNUM10 NUMBER(16,4),HDRPASSTHRUDATE01 DATE,HDRPASSTHRUDATE02 DATE,' ||
' HDRPASSTHRUDATE03 DATE,HDRPASSTHRUDATE04 DATE,HDRPASSTHRUDOLL01 NUMBER(10,2),' ||
' HDRPASSTHRUDOLL02 NUMBER(10,2),PRONO VARCHAR2(20),TRAILER VARCHAR2(12),' ||
' SEAL VARCHAR2(15),PALLETCOUNT NUMBER,FACILITY VARCHAR2(3),SHIPPERNAME VARCHAR2(40),' ||
' SHIPPERCONTACT VARCHAR2(40),SHIPPERADDR1 VARCHAR2(40),SHIPPERADDR2 VARCHAR2(40),' ||
' SHIPPERCITY VARCHAR2(30),SHIPPERSTATE VARCHAR2(5),SHIPPERPOSTALCODE VARCHAR2(12),' ||
' SHIPPERCOUNTRYCODE VARCHAR2(3),SHIPPERPHONE VARCHAR2(25),SHIPPERFAX VARCHAR2(25),' ||
' SHIPPEREMAIL VARCHAR2(255),BILLTONAME VARCHAR2(40),BILLTOCONTACT VARCHAR2(40),' ||
' BILLTOADDR1 VARCHAR2(40),BILLTOADDR2 VARCHAR2(40),BILLTOCITY VARCHAR2(30),' ||
' BILLTOSTATE VARCHAR2(5),BILLTOPOSTALCODE VARCHAR2(12),BILLTOCOUNTRYCODE VARCHAR2(3),' ||
' BILLTOPHONE VARCHAR2(25),BILLTOFAX VARCHAR2(25),BILLTOEMAIL VARCHAR2(255),' ||
' RMA VARCHAR2(20),ORDERTYPE VARCHAR2(1) not null,RETURNTRACKINGNO VARCHAR2(30),' ||
' STATUSUSER VARCHAR2(12),INSTRUCTIONS VARCHAR2(512), CARRIERNAME VARCHAR2(40), '||
' REFERENCE VARCHAR2(20), SHIPPER VARCHAR2(10), SUPPLIER VARCHAR2(10), '||
' SCAC VARCHAR2(4), WEIGHTRCVD NUMBER(17,8), CUBERCVD NUMBER(10,4), WEIGHTRCVDGOOD NUMBER(17,8), '||
' CUBRCVDGOOD NUMBER(10,4), WEIGHTRCVDDMGD NUMBER(17,8), CUBERCVDDMGD NUMBER(10,4), '||
' SHIPTERMS VARCHAR2(3), DOORLOC VARCHAR2(10))';
debugmsg(cmdSql);
execute immediate cmdSql;

-- Create NTE extract
debugmsg('nte extract');
if nvl(in_orderid,0) != 0 then
   debugmsg('by orderid; recv_line_check_yn is ' || cu.recv_line_check_yn);
   debugmsg('rqn flag is ' || in_dtv_receipt_or_return_rqn);
   for crec in C_ORDS_BY_ORDERID(in_custid,in_orderid,in_shipid)
   loop
     debugmsg('order ' || crec.orderid || '-' || crec.shipid || ' status ' || crec.orderstatus || ' type ' || crec.ordertype);
     if upper(nvl(in_include_cancelled_orders_yn,'N')) <> 'Y' then
       if crec.orderstatus = 'X' then
         debugmsg('skipping cancelled order');
         goto continue_orderid_loop;
       end if;
     end if;
     if upper(nvl(cu.rcptnote_include_cross_cust_yn,'N')) <> 'Y' then
       if crec.ordertype = 'U' then
         debugmsg('skipping cross customer order');
         goto continue_orderid_loop;
       end if;
     end if;

     debugmsg('call create 944 hdr');
     create_944_hdr_data(crec);
     if (cu.recv_line_check_yn != 'N') or (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') != 'N')
     or (nvl(rtrim(in_invclass_yn),'N')) = 'Y'
     or (nvl(rtrim(in_invstatus_yn),'N')) = 'Y'
     or (nvl(rtrim(in_summarize_manu_yn),'N')) = 'Y'
     or (nvl(rtrim(in_dtlrcptlines_yn),'N')) = 'Y' then
       debugmsg('call create_944_line_data');
       create_944_line_data(crec);
     else
       for crec2 in C_ORDDTL(crec.orderid, crec.shipid)
       loop
         create_944_ide_over_short_data(crec2);
       end loop;
       if Upper(nvl(in_summarize_lots_yn,'N')) != 'Y' then
         for crec3 in C_ORDDTLRCPTLOT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       else
         for crec3 in C_ORDDTLRCPT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       end if;
     end if;
     create_note_data(crec);
     -- IDE for received short and received over
<< continue_orderid_loop >>
     null;
   end loop;
elsif nvl(in_loadno,0) != 0 then
   for crec in C_ORDS_BY_LOADNO(in_custid,in_loadno)
   loop
     if upper(nvl(in_include_cancelled_orders_yn,'N')) <> 'Y' then
       if crec.orderstatus = 'X' then
         goto continue_load_loop;
       end if;
     end if;
     if upper(nvl(cu.rcptnote_include_cross_cust_yn,'N')) <> 'Y' then
       if crec.ordertype = 'U' then
         debugmsg('skipping cross customer order');
         goto continue_load_loop;
       end if;
     end if;
     create_944_hdr_data(crec);
     if (cu.recv_line_check_yn != 'N') or (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') != 'N')
     or (nvl(rtrim(in_invclass_yn),'N')) = 'Y'
     or (nvl(rtrim(in_invstatus_yn),'N')) = 'Y'
     or (nvl(rtrim(in_summarize_manu_yn),'N')) = 'Y'
     or (nvl(rtrim(in_dtlrcptlines_yn),'N')) = 'Y' then
       create_944_line_data(crec);
     else
       for crec2 in C_ORDDTL(crec.orderid, crec.shipid)
       loop
         create_944_ide_over_short_data(crec2);
       end loop;
       if Upper(nvl(in_summarize_lots_yn,'N')) != 'Y' then
         for crec3 in C_ORDDTLRCPTLOT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       else
         for crec3 in C_ORDDTLRCPT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       end if;
     end if;
     create_note_data(crec);
<< continue_load_loop >>
     null;
   end loop;
else
   for crec in C_ORDS_BY_DATE(in_custid,
       to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
       to_date(in_enddatestr,'YYYYMMDDHH24MISS'))
   loop
     if upper(nvl(in_include_cancelled_orders_yn,'N')) <> 'Y' then
       if crec.orderstatus = 'X' then
         goto continue_date_loop;
       end if;
     end if;
     if upper(nvl(cu.rcptnote_include_cross_cust_yn,'N')) <> 'Y' then
       if crec.ordertype = 'U' then
         debugmsg('skipping cross customer order');
         goto continue_date_loop;
       end if;
     end if;
     create_944_hdr_data(crec);
     if (cu.recv_line_check_yn != 'N') or (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') != 'N')
     or (nvl(rtrim(in_invclass_yn),'N')) = 'Y'
     or (nvl(rtrim(in_invstatus_yn),'N')) = 'Y'
     or (nvl(rtrim(in_summarize_manu_yn),'N')) = 'Y'
     or (nvl(rtrim(in_dtlrcptlines_yn),'N')) = 'Y' then
       create_944_line_data(crec);
     else
       for crec2 in C_ORDDTL(crec.orderid, crec.shipid)
       loop
         create_944_ide_over_short_data(crec2);
       end loop;
       if Upper(nvl(in_summarize_lots_yn,'N')) != 'Y' then
         for crec3 in C_ORDDTLRCPTLOT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       else
         for crec3 in C_ORDDTLRCPT(crec.orderid, crec.shipid) loop
           create_944_ide_condition_data(crec,crec3);
         end loop;
       end if;
     end if;
     create_note_data(crec);
<< continue_date_loop >>
     null;
   end loop;
end if;

debugmsg('create nte view');
cmdSql := 'create view rcpt_note_944_nte_' || strSuffix ||
  ' (custid,orderid,shipid,sequence, qualifier, note) as ' ||
  ' select custid,orderid,shipid,sequence, qualifier, note ' ||
  '  from rcptnote944noteex ' ||
  ' where sessionid = ''' || strsuffix || '''';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
debugmsg('before ide ');
if (cu.recv_line_check_yn != 'N') or (nvl(rtrim(in_dtv_receipt_or_return_rqn),'N') != 'N')
or (nvl(rtrim(in_invclass_yn),'N')) = 'Y'
or (nvl(rtrim(in_invstatus_yn),'N')) = 'Y'
or (nvl(rtrim(in_summarize_manu_yn),'N')) = 'Y'
or (nvl(rtrim(in_dtlrcptlines_yn),'N')) = 'Y' then
  goto create_ide_view;
end if;
debugmsg('create 944_dtl');
-- Create DTL view
if Upper(nvl(in_summarize_lots_yn,'N')) != 'Y' then
  cmdSql := 'create view rcpt_note_944_dtl_' || strSuffix ||
    '(custid,orderid,shipid,line_number,item,upc,description,lotnumber,' ||
    ' uom,qtyrcvd,cubercvd,qtyrcvdgood,cubercvdgood,qtyrcvddmgd,qtyorder,' ||
    ' weightitem,weightqualifier,weightunitcode,volume,uom_volume, ' ||
' DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,' ||
' DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,' ||
' DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,' ||
' DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,' ||
' DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23,DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,' ||
' DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27,DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,' ||
' DTLPASSTHRUCHAR31,DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35,' ||
' DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39,DTLPASSTHRUCHAR40,' ||
' DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,' ||
' DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10,' ||
' DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13,DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,' ||
' DTLPASSTHRUNUM16,DTLPASSTHRUNUM17,DTLPASSTHRUNUM18,DTLPASSTHRUNUM19,DTLPASSTHRUNUM20,' ||
' DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,' ||
' DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,QTYONHOLD,QTYRCVD_INVSTATUS,'||
' serialnumber,useritem1,useritem2,useritem3,orig_line_number,unload_date, condition, invclass,' ||
' manufacturedate, invstatus, link_lotnumber, lineseq, ' ||
' itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04, '||
' itmpassthruchar05, itmpassthruchar06, itmpassthruchar07, itmpassthruchar08, '||
' itmpassthruchar09, itmpassthruchar10, itmpassthrunum01, itmpassthrunum02, '||
' itmpassthrunum03, itmpassthrunum04, itmpassthrunum05, itmpassthrunum06, '||
' itmpassthrunum07, itmpassthrunum08, itmpassthrunum09, itmpassthrunum10) ' ||
    'as select D.custid,D.orderid,D.shipid,nvl(D.dtlpassthruchar06,''000000''),'||
    ' D.item,nvl(D.dtlpassthruchar11,U.upc),I.descr,D.lotnumber,D.uom,'||
    ' nvl(D.qtyrcvd,0),nvl(D.cubercvd,0),' ||
    '  nvl(D.qtyrcvdgood,0),nvl(D.cubercvdgood,0),nvl(D.qtyrcvddmgd,0),' ||
    '  nvl(D.qtyorder,0),I.weight, '||
    ' ''N'',''L'',cube/1728,''CF'', ' ||
' D.DTLPASSTHRUCHAR01,D.DTLPASSTHRUCHAR02,' ||
' D.DTLPASSTHRUCHAR03,D.DTLPASSTHRUCHAR04,D.DTLPASSTHRUCHAR05,D.DTLPASSTHRUCHAR06,' ||
' D.DTLPASSTHRUCHAR07,D.DTLPASSTHRUCHAR08,D.DTLPASSTHRUCHAR09,D.DTLPASSTHRUCHAR10,' ||
' D.DTLPASSTHRUCHAR11,D.DTLPASSTHRUCHAR12,D.DTLPASSTHRUCHAR13,D.DTLPASSTHRUCHAR14,' ||
' D.DTLPASSTHRUCHAR15,D.DTLPASSTHRUCHAR16,D.DTLPASSTHRUCHAR17,D.DTLPASSTHRUCHAR18,' ||
' D.DTLPASSTHRUCHAR19,D.DTLPASSTHRUCHAR20, '||
' D.DTLPASSTHRUCHAR21,D.DTLPASSTHRUCHAR22,' ||
' D.DTLPASSTHRUCHAR23,D.DTLPASSTHRUCHAR24,D.DTLPASSTHRUCHAR25,D.DTLPASSTHRUCHAR26,' ||
' D.DTLPASSTHRUCHAR27,D.DTLPASSTHRUCHAR28,D.DTLPASSTHRUCHAR29,D.DTLPASSTHRUCHAR30,' ||
' D.DTLPASSTHRUCHAR31,D.DTLPASSTHRUCHAR32,D.DTLPASSTHRUCHAR33,D.DTLPASSTHRUCHAR34,' ||
' D.DTLPASSTHRUCHAR35,D.DTLPASSTHRUCHAR36,D.DTLPASSTHRUCHAR37,D.DTLPASSTHRUCHAR38,' ||
' D.DTLPASSTHRUCHAR39,D.DTLPASSTHRUCHAR40, '||
' D.DTLPASSTHRUNUM01,D.DTLPASSTHRUNUM02,' ||
' D.DTLPASSTHRUNUM03,D.DTLPASSTHRUNUM04,D.DTLPASSTHRUNUM05,D.DTLPASSTHRUNUM06,' ||
' D.DTLPASSTHRUNUM07,D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10,' ||
' D.DTLPASSTHRUNUM11,D.DTLPASSTHRUNUM12,' ||
' D.DTLPASSTHRUNUM13,D.DTLPASSTHRUNUM14,D.DTLPASSTHRUNUM15,D.DTLPASSTHRUNUM16,' ||
' D.DTLPASSTHRUNUM17,D.DTLPASSTHRUNUM18,D.DTLPASSTHRUNUM19,D.DTLPASSTHRUNUM20,' ||
' D.DTLPASSTHRUDATE01,D.DTLPASSTHRUDATE02,' ||
' D.DTLPASSTHRUDATE03,D.DTLPASSTHRUDATE04,D.DTLPASSTHRUDOLL01,D.DTLPASSTHRUDOLL02,' ||
' 0, '' '',';
if nvl(in_list_serialnumber_yn,'N') = 'Y' then
  cmdSql := cmdSql ||'(select '''||sn.snlist||''' from dual)';
else
  cmdSql := cmdSql ||'(select '''||rnide.serialnumber||''' from dual)';
end if;
 cmdSql := cmdSql || ','' '','' '','' '','' '',o.unload_date,'' '','' '','' '','' '', nvl(D.lotnumber,''(none)''), 0, ' ||
' I.itmpassthruchar01, I.itmpassthruchar02, I.itmpassthruchar03, I.itmpassthruchar04, '||
' I.itmpassthruchar05, I.itmpassthruchar06, I.itmpassthruchar07, I.itmpassthruchar08, '||
' I.itmpassthruchar09, I.itmpassthruchar10, I.itmpassthrunum01, I.itmpassthrunum02, '||
' I.itmpassthrunum03, I.itmpassthrunum04, I.itmpassthrunum05, I.itmpassthrunum06, '||
' I.itmpassthrunum07, I.itmpassthrunum08, I.itmpassthrunum09, I.itmpassthrunum10 ' ||
--' null, null, null, null, null, null, null, o.unload_date, null, null ' ||
    '  from custitemupcview U, custitem I, orderdtl D, ' ||
    ' rcpt_note_944_hdr_'|| strsuffix ||' O ' ||
    ' where D.orderid = O.orderid ' ||
    ' and D.shipid = O.shipid ' ||
    ' and D.custid = I.custid ' ||
    ' and D.item = I.item ' ||
    ' and D.custid = U.custid(+) '||
    ' and D.item = U.item(+) ';
  if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
    cmdSql := cmdSql || ' and nvl(D.qtyrcvd,0) <> 0 ';
  end if;
else
  cmdSql := 'create view rcpt_note_944_dtl_' || strSuffix ||
    ' (custid,orderid,shipid,line_number,item,upc,description,lotnumber,' ||
    ' uom,qtyrcvd,cubercvd,qtyrcvdgood,cubercvdgood,qtyrcvddmgd,qtyorder,' ||
    ' weightitem,weightqualifier,weightunitcode,volume,uom_volume, ' ||
' DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,' ||
' DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,' ||
' DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,' ||
' DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,' ||
' DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23,DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,' ||
' DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27,DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,' ||
' DTLPASSTHRUCHAR31,DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR23,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35,' ||
' DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR27,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39,DTLPASSTHRUCHAR40,' ||
' DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,' ||
' DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10,' ||
' DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13,DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,' ||
' DTLPASSTHRUNUM16,DTLPASSTHRUNUM17,DTLPASSTHRUNUM18,DTLPASSTHRUNUM19,DTLPASSTHRUNUM20,' ||
' dtlPASSTHRUDATE01,dtlPASSTHRUDATE02,' ||
' dtlPASSTHRUDATE03,dtlPASSTHRUDATE04,dtlPASSTHRUDOLL01,dtlPASSTHRUDOLL02, qtyonhold,qtyrcvd_invstatus,'||
' serialnumber,useritem1,useritem2,useritem3,orig_line_number,unload_date, condition, invclass,' ||
' manufacturedate, invstatus, link_lotnumber, lineseq, ' ||
' itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04, '||
' itmpassthruchar05, itmpassthruchar06, itmpassthruchar07, itmpassthruchar08, '||
' itmpassthruchar09, itmpassthruchar10, itmpassthrunum01, itmpassthrunum02, '||
' itmpassthrunum03, itmpassthrunum04, itmpassthrunum05, itmpassthrunum06, '||
' itmpassthrunum07, itmpassthrunum08, itmpassthrunum09, itmpassthrunum10) ' ||
    'as select D.custid,D.orderid,D.shipid,max(nvl(D.dtlpassthruchar06,''000000'')),'||
    ' D.item,max(nvl(D.dtlpassthruchar11,U.upc)),I.descr,''ALL'',max(D.uom),'||
    ' sum(nvl(D.qtyrcvd,0)),sum(nvl(D.cubercvd,0)),' ||
    ' sum(nvl(D.qtyrcvdgood,0)),sum(nvl(D.cubercvdgood,0)),sum(nvl(D.qtyrcvddmgd,0)),' ||
    ' sum(nvl(D.qtyorder,0)),I.weight, '||
    ' ''N'',''L'',cube/1728,''CF'', ' ||
' max(D.dtlPASSTHRUCHAR01),max(D.dtlPASSTHRUCHAR02),max(D.dtlPASSTHRUCHAR03),max(D.dtlPASSTHRUCHAR04),max(D.dtlPASSTHRUCHAR05),' ||
' max(D.dtlPASSTHRUCHAR06),max(D.dtlPASSTHRUCHAR07),max(D.dtlPASSTHRUCHAR08),max(D.dtlPASSTHRUCHAR09),' ||
' max(D.dtlPASSTHRUCHAR10),max(D.dtlPASSTHRUCHAR11),max(D.dtlPASSTHRUCHAR12),max(D.dtlPASSTHRUCHAR13),' ||
' max(D.dtlPASSTHRUCHAR14),max(D.dtlPASSTHRUCHAR15),max(D.dtlPASSTHRUCHAR16),max(D.dtlPASSTHRUCHAR17),' ||
' max(D.dtlPASSTHRUCHAR18),max(D.dtlPASSTHRUCHAR19),max(D.dtlPASSTHRUCHAR20), '||
' max(D.dtlPASSTHRUCHAR21),max(D.dtlPASSTHRUCHAR22),max(D.dtlPASSTHRUCHAR23),max(D.dtlPASSTHRUCHAR24),max(D.dtlPASSTHRUCHAR25),' ||
' max(D.dtlPASSTHRUCHAR26),max(D.dtlPASSTHRUCHAR27),max(D.dtlPASSTHRUCHAR28),max(D.dtlPASSTHRUCHAR29),' ||
' max(D.dtlPASSTHRUCHAR30),max(D.dtlPASSTHRUCHAR31),max(D.dtlPASSTHRUCHAR32),max(D.dtlPASSTHRUCHAR33),' ||
' max(D.dtlPASSTHRUCHAR34),max(D.dtlPASSTHRUCHAR35),max(D.dtlPASSTHRUCHAR36),max(D.dtlPASSTHRUCHAR37),' ||
' max(D.dtlPASSTHRUCHAR38),max(D.dtlPASSTHRUCHAR39),max(D.dtlPASSTHRUCHAR40), '||
' max(D.dtlPASSTHRUNUM01),max(D.dtlPASSTHRUNUM02),max(D.dtlPASSTHRUNUM03),max(D.dtlPASSTHRUNUM04),max(D.dtlPASSTHRUNUM05),' ||
' max(D.dtlPASSTHRUNUM06),max(D.dtlPASSTHRUNUM07),max(D.dtlPASSTHRUNUM08),max(D.dtlPASSTHRUNUM09),max(D.dtlPASSTHRUNUM10),' ||
' max(D.dtlPASSTHRUNUM11),max(D.dtlPASSTHRUNUM12),max(D.dtlPASSTHRUNUM13),max(D.dtlPASSTHRUNUM14),max(D.dtlPASSTHRUNUM15),' ||
' max(D.dtlPASSTHRUNUM16),max(D.dtlPASSTHRUNUM17),max(D.dtlPASSTHRUNUM18),max(D.dtlPASSTHRUNUM19),max(D.dtlPASSTHRUNUM20),' ||
' max(D.dtlPASSTHRUDATE01),max(D.dtlPASSTHRUDATE02),' ||
' max(D.dtlPASSTHRUDATE03),max(D.dtlPASSTHRUDATE04),max(D.dtlPASSTHRUDOLL01),max(D.dtlPASSTHRUDOLL02),'||
' 0, '' '',';
if nvl(in_list_serialnumber_yn,'N') = 'Y' then
  cmdSql := cmdSql ||'(select '''||sn.snlist||''' from dual)';
else
  cmdSql := cmdSql ||'(select '''||rnide.serialnumber||''' from dual)';
end if;
 cmdSql := cmdSql || ','' '','' '','' '','' '',o.unload_date,'' '','' '','' '','' '', nvl(D.lotnumber,''(none)''), 0 ,' ||
' I.itmpassthruchar01, I.itmpassthruchar02, I.itmpassthruchar03, I.itmpassthruchar04, '||
' I.itmpassthruchar05, I.itmpassthruchar06, I.itmpassthruchar07, I.itmpassthruchar08, '||
' I.itmpassthruchar09, I.itmpassthruchar10, I.itmpassthrunum01, I.itmpassthrunum02, '||
' I.itmpassthrunum03, I.itmpassthrunum04, I.itmpassthrunum05, I.itmpassthrunum06, '||
' I.itmpassthrunum07, I.itmpassthrunum08, I.itmpassthrunum09, I.itmpassthrunum10 ' ||
    '  from custitemupcview U, custitem I, orderdtl D, ' ||
    ' rcpt_note_944_hdr_'|| strsuffix ||' O ' ||
    ' where D.orderid = O.orderid ' ||
    ' and D.shipid = O.shipid ' ||
    ' and D.custid = I.custid ' ||
    ' and D.item = I.item ' ||
    ' and D.custid = U.custid(+) '||
    ' and D.item = U.item(+) ';
  if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
    cmdSql := cmdSql || ' and nvl(D.qtyrcvd,0) <> 0 ';
  end if;
  cmdSql := cmdSql ||
    ' group by D.custid,D.orderid,D.shipid,D.item,I.descr,''ALL'',I.weight, ' ||
    ' ''N'',''L'',(cube/1728),''CF'',o.unload_date ';
end if;
debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;

dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

if nvl(in_create_944_cfs_data_yn,'N') = 'Y' then
   cmdSql := 'select loadno from rcpt_note_944_hdr_'||strSuffix;
   open cl for cmdsql;
   fetch cl into hdr.loadno;
   if cl%found then
     create_944_cfs_data(hdr);
     close cl;
   end if;
end if;

<< create_ide_view >>

-- Create IDE extract and view
debugmsg('create ide view ' || strsuffix);
cmdSql := 'create view rcpt_note_944_ide_' || strSuffix ||
  ' (custid,orderid,shipid,item,lotnumber,qty,uom,condition,damagereason,' ||
  ' line_number, origtrackingno, serialnumber, useritem1, useritem2, useritem3, '||
  ' qtyrcvd_invstatus, orig_line_number, snweight, zeroqty ) as ' ||
  ' select custid,orderid,shipid,item, lotnumber, nvl(qty,0), ' ||
  ' uom, condition, damagereason, line_number, origtrackingno, serialnumber,'||
  ' useritem1, useritem2, useritem3, qtyrcvd_invstatus, orig_line_number, ' ||
  ' snweight, zeroqty' ||
  ' from rcptnote944ideex ' ||
  ' where sessionid = ''' || strsuffix || '''';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create ide 2 ' );
cmdSql := 'create view rcpt_note_944_ide2_' || strSuffix ||
  ' (custid,orderid,shipid,item,lotnumber,qty,uom,condition,damagereason,' ||
  ' line_number, origtrackingno, serialnumber, useritem1, useritem2, useritem3, qtyrcvd_invstatus, orig_line_number,'||
' qtyrcvdgood, qtyrcvddmgd, ' ||
' dtlPASSTHRUCHAR01,dtlPASSTHRUCHAR02,dtlPASSTHRUCHAR03,dtlPASSTHRUCHAR04,dtlPASSTHRUCHAR05,' ||
' dtlPASSTHRUCHAR06,dtlPASSTHRUCHAR07,dtlPASSTHRUCHAR08,dtlPASSTHRUCHAR09,' ||
' dtlPASSTHRUCHAR10,dtlPASSTHRUCHAR11,dtlPASSTHRUCHAR12,dtlPASSTHRUCHAR13,' ||
' dtlPASSTHRUCHAR14,dtlPASSTHRUCHAR15,dtlPASSTHRUCHAR16,dtlPASSTHRUCHAR17,' ||
' dtlPASSTHRUCHAR18,dtlPASSTHRUCHAR19,dtlPASSTHRUCHAR20,dtlPASSTHRUNUM01,' ||
' dtlPASSTHRUNUM02,dtlPASSTHRUNUM03,dtlPASSTHRUNUM04,dtlPASSTHRUNUM05,' ||
' dtlPASSTHRUNUM06,dtlPASSTHRUNUM07,dtlPASSTHRUNUM08,dtlPASSTHRUNUM09,' ||
' dtlPASSTHRUNUM10,dtlPASSTHRUDATE01,dtlPASSTHRUDATE02,' ||
' dtlPASSTHRUDATE03,dtlPASSTHRUDATE04,dtlPASSTHRUDOLL01,dtlPASSTHRUDOLL02, EXPIRATIONDATE ) as '||
' select R.custid,R.orderid,R.shipid,R.item, R.lotnumber, decode(R.zeroqty, ''Y'',0,nvl(R.qty,0)), ' ||
  ' R.uom, R.condition, R.damagereason, R.line_number, R.origtrackingno, ' ||
  ' R.serialnumber, R.useritem1, R.useritem2, R.useritem3, ' ||
  ' R.qtyrcvd_invstatus, R.orig_line_number, ' ||
  ' decode(R.zeroqty, ''Y'', 0, decode(R.qtyrcvd_invstatus, ''DM'', 0, nvl(R.qty,0))), ' ||
  ' decode(R.qtyrcvd_invstatus, ''DM'', nvl(R.qty,0), 0), ' ||
' dtlPASSTHRUCHAR01,dtlPASSTHRUCHAR02,dtlPASSTHRUCHAR03,dtlPASSTHRUCHAR04,dtlPASSTHRUCHAR05,' ||
' dtlPASSTHRUCHAR06,dtlPASSTHRUCHAR07,dtlPASSTHRUCHAR08,dtlPASSTHRUCHAR09,' ||
' dtlPASSTHRUCHAR10,dtlPASSTHRUCHAR11,dtlPASSTHRUCHAR12,dtlPASSTHRUCHAR13,' ||
' dtlPASSTHRUCHAR14,dtlPASSTHRUCHAR15,dtlPASSTHRUCHAR16,dtlPASSTHRUCHAR17,' ||
' dtlPASSTHRUCHAR18,dtlPASSTHRUCHAR19,dtlPASSTHRUCHAR20,dtlPASSTHRUNUM01,' ||
' dtlPASSTHRUNUM02,dtlPASSTHRUNUM03,dtlPASSTHRUNUM04,dtlPASSTHRUNUM05,' ||
' dtlPASSTHRUNUM06,dtlPASSTHRUNUM07,dtlPASSTHRUNUM08,dtlPASSTHRUNUM09,' ||
' dtlPASSTHRUNUM10,dtlPASSTHRUDATE01,dtlPASSTHRUDATE02,' ||
' dtlPASSTHRUDATE03,dtlPASSTHRUDATE04,dtlPASSTHRUDOLL01,dtlPASSTHRUDOLL02,' ||
' (select max(expirationdate)' ||
   ' from plate pl,orderdtlrcpt odr' ||
  ' where odr.orderid = D.orderid'||
    ' and odr.shipid = D.shipid'||
    ' and odr.item = D.item'||
    ' and nvl(odr.lotnumber,''(none)'') = nvl(D.lotnumber,''(none)'')' ||
    ' and pl.orderid = odr.orderid' ||
    ' and pl.shipid = odr.shipid' ||
    ' and pl.item = odr.item' ||
    ' and nvl(pl.lotnumber,''(none)'') = nvl(odr.lotnumber,''(none)'')' ||
    ' and pl.lpid = odr.lpid' ||
    ' and pl.expirationdate is not null)' ||
 ' from orderdtl D, rcptnote944ideex R ' ||
  ' where sessionid = ''' || strsuffix || '''' ||
  ' and D.orderid = R.orderid ' ||
  ' and D.shipid = R.shipid ' ||
  ' and D.item = R.item ' ||
  ' and nvl(D.lotnumber,''(none)'') = nvl(R.lotnumber,''(none)'') ';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




debugmsg('create lu1 view');

-- Create lot user 1 and view
cmdSql := 'create view rcpt_note_944_lu1_' || strSuffix ||
  ' (custid,orderid,shipid,item,lotnumber,uom,useritem1, qty) as' ||
  ' select  custid,orderid,shipid,item,lotnumber,uom,useritem1,' ||
  ' sum(nvl(qtyrcvdgood,0) + nvl(qtyrcvddmgd,0))' ||
  ' from orderdtlrcpt ' ||
  ' group by custid, orderid, shipid, item, lotnumber, uom, useritem1 ' ||
  ' having custid = ''' || in_custid || '''' ||
  '    and orderid in (select orderid from RCPT_NOTE_944_HDR_' || strSuffix || ')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create table RCPT_NOTE_944_LIP');
cmdSql := 'create table RCPT_NOTE_944_LIP_' || strSuffix ||
  ' (CUSTID VARCHAR2(10),ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,' ||
  ' LINE_NUMBER VARCHAR2(255),item varchar2(50) not null,UPC VARCHAR2(20),' ||
  ' DESCRIPTION VARCHAR2(255) not null,LOTNUMBER VARCHAR2(30),UOM VARCHAR2(4),' ||
  ' QTYRCVD NUMBER,CUBERCVD NUMBER,QTYRCVDGOOD NUMBER,CUBERCVDGOOD NUMBER,' ||
  ' QTYRCVDDMGD NUMBER,QTYORDER NUMBER,WEIGHTITEM NUMBER(17,8),WEIGHTQUALIFIER CHAR(1),' ||
  ' WEIGHTUNITCODE CHAR(1),VOLUME NUMBER,UOM_VOLUME CHAR(2),DTLPASSTHRUCHAR01 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR02 VARCHAR2(255),DTLPASSTHRUCHAR03 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR04 VARCHAR2(255),DTLPASSTHRUCHAR05 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR06 VARCHAR2(255),DTLPASSTHRUCHAR07 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR08 VARCHAR2(255),DTLPASSTHRUCHAR09 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR10 VARCHAR2(255),DTLPASSTHRUCHAR11 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR12 VARCHAR2(255),DTLPASSTHRUCHAR13 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR14 VARCHAR2(255),DTLPASSTHRUCHAR15 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR16 VARCHAR2(255),DTLPASSTHRUCHAR17 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR18 VARCHAR2(255),DTLPASSTHRUCHAR19 VARCHAR2(255),' ||
  ' DTLPASSTHRUCHAR20 VARCHAR2(255),DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM06 NUMBER(16,4),DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),' ||
  ' DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),DTLPASSTHRUDATE01 DATE,' ||
  ' DTLPASSTHRUDATE02 DATE,DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,' ||
  ' DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2),' ||
  ' QTYONHOLD NUMBER, QTYRCVD_INVSTATUS VARCHAR2(2),'||
  ' serialnumber varchar2(30),useritem1 varchar2(20),useritem2 varchar2(20),useritem3 varchar2(20),'||
  ' orig_line_number number, unload_date date, condition varchar2(2), invclass varchar2(2),'||
  ' lpid varchar2(15), invstatus varchar2(2), lineseq number(3),weight number(17,8),'||
  ' invstatusdesc varchar2(32), manufacturedate date, lpidlast6 varchar2(6), expirationdate date)';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

if nvl(in_lip_line_yn,'N') = 'Y' then
   insert_lip_data_line;
else
   insert_lip_data;
end if;
debugmsg(' check for trailer');

if nvl(in_loadno,0) != 0 then
   cmdSql := 'select loadno, custid from rcpt_note_944_hdr_'||strSuffix;
   open cl for cmdsql;
   fetch cl into l_loadno, l_custid;
   if cl%notfound then
      l_loadno := in_loadno;
      l_custid := in_custid;
   end if;

   close cl;
   -- create trailer view
   if l_loadno is null then
      cmdSql := 'create view rcpt_note_944_trl_' || strSuffix ||
      ' (orderid,shipid,custid,hdr_count,dtl_count,loadno) as '||
      ' select null,null, ''' || in_custid || ''','||
      ' 0,0,null from dual ';
   else
      cmdSql := 'create view rcpt_note_944_trl_' || strSuffix ||
      ' (orderid,shipid,custid,hdr_count,dtl_count,loadno) as '||
      ' select null,null, ''' || l_custid || ''','||
      ' (select count(1) from rcpt_note_944_hdr_'||strSuffix||'),'||
      ' (select count(1) from rcpt_note_944_dtl_'||strSuffix||'),'||
      l_loadno || ' from dual ';
   end if;
else
   -- create trailer view
   no_dtl := false; -- catch empty timed export when 944_dtl not created
   begin
      execute immediate
        'select count(1) from rcpt_note_944_dtl_' || strSuffix
        into cntRows;
   exception when others then
      no_dtl := true;
   end;
   if no_dtl then
   cmdSql := 'create view rcpt_note_944_trl_' || strSuffix ||
   ' (orderid,shipid,custid,hdr_count,dtl_count,loadno) as '||
   ' select orderid, shipid,custid,'||
   ' (select count(1) from rcpt_note_944_hdr_'||strSuffix||'),'||
      ' 0, null'||
      ' from rcpt_note_944_hdr_'||strSuffix;
   else
      cmdSql := 'create view rcpt_note_944_trl_' || strSuffix ||
      ' (orderid,shipid,custid,hdr_count,dtl_count,loadno) as '||
      ' select orderid, shipid,custid,'||
      ' (select count(1) from rcpt_note_944_hdr_'||strSuffix||'),'||
   ' (select count(1) from rcpt_note_944_dtl_'||strSuffix||'), null'||
   ' from rcpt_note_944_hdr_'||strSuffix;
   end if;
end if;
debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Create pal view

cmdSql := 'create view rcpt_note_944_pal_' ||strSuffix ||
  ' (custid,orderid,shipid,loadno,pallettype,inpallets,outpallets) as '||
  ' select  custid,orderid,shipid,loadno,pallettype,inpallets,outpallets ' ||
  ' from pallethistory ' ||
  ' where (orderid,shipid) in (select orderid, shipid from RCPT_NOTE_944_HDR_' || strSuffix || ')';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'CREATE VIEW rcpt_note_944_add_' || strSuffix ||
  ' (custid,orderid,shipid,item,lotnumber,qty,uom,condition,damagereason, '||
  ' line_number, origtrackingno, serialnumber, useritem1, useritem2, useritem3, qtyrcvd_invstatus, orig_line_number,'||
' qtyrcvdgood, qtyrcvddmgd,  '||
' dtlPASSTHRUCHAR01,dtlPASSTHRUCHAR02,dtlPASSTHRUCHAR03,dtlPASSTHRUCHAR04,dtlPASSTHRUCHAR05, '||
' dtlPASSTHRUCHAR06,dtlPASSTHRUCHAR07,dtlPASSTHRUCHAR08,dtlPASSTHRUCHAR09, '||
' dtlPASSTHRUCHAR10,dtlPASSTHRUCHAR11,dtlPASSTHRUCHAR12,dtlPASSTHRUCHAR13, '||
' dtlPASSTHRUCHAR14,dtlPASSTHRUCHAR15,dtlPASSTHRUCHAR16,dtlPASSTHRUCHAR17, '||
' dtlPASSTHRUCHAR18,dtlPASSTHRUCHAR19,dtlPASSTHRUCHAR20,dtlPASSTHRUNUM01, '||
' dtlPASSTHRUNUM02,dtlPASSTHRUNUM03,dtlPASSTHRUNUM04,dtlPASSTHRUNUM05, '||
' dtlPASSTHRUNUM06,dtlPASSTHRUNUM07,dtlPASSTHRUNUM08,dtlPASSTHRUNUM09, '||
' dtlPASSTHRUNUM10,dtlPASSTHRUDATE01,dtlPASSTHRUDATE02, '||
' dtlPASSTHRUDATE03,dtlPASSTHRUDATE04,dtlPASSTHRUDOLL01,dtlPASSTHRUDOLL02, EXPIRATIONDATE ) AS '||
' SELECT R.custid,R.orderid,R.shipid,R.item, R.lotnumber, DECODE(R.zeroqty, ''Y'',0,NVL(R.qty,0)),  '||
'   R.uom, R.condition, R.damagereason, R.line_number, R.origtrackingno,  '||
'   R.serialnumber, R.useritem1, R.useritem2, R.useritem3,  '||
'   R.qtyrcvd_invstatus, R.orig_line_number,  '||
'   DECODE(R.zeroqty, ''Y'', 0, DECODE(R.qtyrcvd_invstatus, ''DM'', 0, NVL(R.qty,0))),  '||
'   DECODE(R.qtyrcvd_invstatus, ''DM'', NVL(R.qty,0), 0),  '||
' NVL(DL.dtlPASSTHRUCHAR01,D.dtlPASSTHRUCHAR01),'||
' NVL(DL.dtlPASSTHRUCHAR02,D.dtlPASSTHRUCHAR02),'||
' NVL(DL.dtlPASSTHRUCHAR03,D.dtlPASSTHRUCHAR03),'||
' NVL(DL.dtlPASSTHRUCHAR04,D.dtlPASSTHRUCHAR04),'||
' NVL(DL.dtlPASSTHRUCHAR05,D.dtlPASSTHRUCHAR05),'||
' NVL(DL.dtlPASSTHRUCHAR06,D.dtlPASSTHRUCHAR06),'||
' NVL(DL.dtlPASSTHRUCHAR07,D.dtlPASSTHRUCHAR07),'||
' NVL(DL.dtlPASSTHRUCHAR08,D.dtlPASSTHRUCHAR08),'||
' NVL(DL.dtlPASSTHRUCHAR09,D.dtlPASSTHRUCHAR09),'||
' NVL(DL.dtlPASSTHRUCHAR10,D.dtlPASSTHRUCHAR10),'||
' NVL(DL.dtlPASSTHRUCHAR11,D.dtlPASSTHRUCHAR11),'||
' NVL(DL.dtlPASSTHRUCHAR12,D.dtlPASSTHRUCHAR12),'||
' NVL(DL.dtlPASSTHRUCHAR13,D.dtlPASSTHRUCHAR13),'||
' NVL(DL.dtlPASSTHRUCHAR14,D.dtlPASSTHRUCHAR14),'||
' NVL(DL.dtlPASSTHRUCHAR15,D.dtlPASSTHRUCHAR15),'||
' NVL(DL.dtlPASSTHRUCHAR16,D.dtlPASSTHRUCHAR16),'||
' NVL(DL.dtlPASSTHRUCHAR17,D.dtlPASSTHRUCHAR17),'||
' NVL(DL.dtlPASSTHRUCHAR18,D.dtlPASSTHRUCHAR18),'||
' NVL(DL.dtlPASSTHRUCHAR19,D.dtlPASSTHRUCHAR19),'||
' NVL(DL.dtlPASSTHRUCHAR20,D.dtlPASSTHRUCHAR20),'||
' NVL(DL.dtlPASSTHRUNUM01,D.dtlPASSTHRUNUM01), '||
' NVL(DL.dtlPASSTHRUNUM02,D.dtlPASSTHRUNUM02), '||
' NVL(DL.dtlPASSTHRUNUM03,D.dtlPASSTHRUNUM03), '||
' NVL(DL.dtlPASSTHRUNUM04,D.dtlPASSTHRUNUM04), '||
' NVL(DL.dtlPASSTHRUNUM05,D.dtlPASSTHRUNUM05), '||
' NVL(DL.dtlPASSTHRUNUM06,D.dtlPASSTHRUNUM06), '||
' NVL(DL.dtlPASSTHRUNUM07,D.dtlPASSTHRUNUM07), '||
' NVL(DL.dtlPASSTHRUNUM08,D.dtlPASSTHRUNUM08), '||
' NVL(DL.dtlPASSTHRUNUM09,D.dtlPASSTHRUNUM09), '||
' NVL(DL.dtlPASSTHRUNUM10,D.dtlPASSTHRUNUM10), '||
' NVL(DL.dtlPASSTHRUDATE01,D.dtlPASSTHRUDATE01),'||
' NVL(DL.dtlPASSTHRUDATE02,D.dtlPASSTHRUDATE02),'||
' NVL(DL.dtlPASSTHRUDATE03,D.dtlPASSTHRUDATE03),'||
' NVL(DL.dtlPASSTHRUDATE04,D.dtlPASSTHRUDATE04),'||
' NVL(DL.dtlPASSTHRUDOLL01,D.dtlPASSTHRUDOLL01),'||
' NVL(DL.dtlPASSTHRUDOLL02,D.dtlPASSTHRUDOLL02),'||
' (SELECT MAX(expirationdate) '||
   ' FROM PLATE pl,ORDERDTLRCPT odr '||
  ' WHERE odr.orderid = D.orderid'||
    ' AND odr.shipid = D.shipid'||
    ' AND odr.item = D.item'||
    ' AND NVL(odr.lotnumber,''(none)'') = NVL(D.lotnumber,''(none)'') '||
    ' AND pl.orderid = odr.orderid '||
    ' AND pl.shipid = odr.shipid '||
    ' AND pl.item = odr.item '||
    ' AND NVL(pl.lotnumber,''(none)'') = NVL(odr.lotnumber,''(none)'') '||
    ' AND pl.lpid = odr.lpid '||
    ' AND pl.expirationdate IS NOT NULL) '||
 ' FROM ORDERDTL D, ORDERDTLLINE DL, RCPTNOTE944IDEEX R  '||
  ' where sessionid = ''' || strsuffix || '''' ||
  ' AND D.orderid = R.orderid  '||
  ' AND D.shipid = R.shipid  '||
  ' AND D.item = R.item  '||
  ' AND NVL(D.lotnumber,''(none)'') = NVL(R.lotnumber,''(none)'') '||
  ' AND R.orderid = DL.orderid(+)'||
  ' AND R.shipid = DL.shipid(+)'||
  ' AND R.item = DL.item(+)'||
  ' AND R.line_number = DL.linenumber(+)';
--debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Create addln (idels with orderdetailine passthrus) view
cmdSql := 'create view rcpt_note_944_addln_' || strSuffix ||
  ' (custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,origtrackingno,'||
  ' serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,dtlpassthruchar01,'||
  ' dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,dtlpassthruchar06,'||
  ' dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,dtlpassthruchar11,'||
  ' dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,dtlpassthruchar16,'||
  ' dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,dtlpassthrunum01,'||
  ' dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,dtlpassthrunum06,'||
  ' dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,dtlpassthrudate01,'||
  ' dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,dtlpassthrudoll02,'||
  ' expirationdate,qty,qtyrcvdgood,qtyrcvddmgd, weight,tareweight,qtyexpected) '||
  ' as select '||
   ' custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,origtrackingno,'||
  ' serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,dtlpassthruchar01,'||
  ' dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,dtlpassthruchar06,'||
  ' dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,dtlpassthruchar11,'||
  ' dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,dtlpassthruchar16,'||
  ' dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,dtlpassthrunum01,'||
  ' dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,dtlpassthrunum06,'||
  ' dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,dtlpassthrudate01,'||
  ' dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,dtlpassthrudoll02,'||
  ' expirationdate,sum(qty),sum(qtyrcvdgood),sum(qtyrcvddmgd),sum(qty*zci.item_weight(custid,item,uom)),'||
  ' sum(qty*zci.item_tareweight(custid,item,uom)), '||
  ' max(zim7.line_qty_expected(orderid,shipid,item,lotnumber,line_number)) '||
  'from rcpt_note_944_add_' ||strSuffix||
  ' group by custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,'||
    ' origtrackingno,serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,'||
    ' dtlpassthruchar01,dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,'||
    ' dtlpassthruchar06,dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,'||
    ' dtlpassthruchar11,dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,'||
    ' dtlpassthruchar16,dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,'||
    ' dtlpassthrunum01,dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,'||
    ' dtlpassthrunum06,dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,'||
    ' dtlpassthrudate01,dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,'||
    ' dtlpassthrudoll02,expirationdate';
--debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create bdn');
cmdSql := 'create view rcpt_note_944_bdn_' || strSuffix || --detail breakdown
  '(custid,orderid,shipid,item,lotnumber, link_lotnumber,uom,invstatus, expirationdate, manufacturedate, qtyrcvd) '||
  'as select o.custid, o.orderid, o.shipid, o.item, o.lotnumber, nvl(o.lotnumber, ''(none)''),o.uom, o.invstatus, ' ||
     'nvl(p.EXPIRATIONDATE, dp.expirationdate), nvl(p.MANUFACTUREDATE,dp.manufacturedate), sum(o.qtyrcvd) '||
  ' from orderdtlrcpt o, plate p, deletedplate dp ' ||
  ' where (o.orderid,o.shipid ) in (select orderid, shipid from rcpt_note_944_hdr_' || strSuffix || ') '||
     'and o.lpid = p.lpid(+) '||
     'and o.lpid = dp.lpid(+) ' ||
  ' group by o.custid, o.orderid, o.shipid, o.item, o.lotnumber, o.uom, o.invstatus, '||
            'nvl(p.EXPIRATIONDATE, dp.expirationdate),nvl(p.MANUFACTUREDATE,dp.manufacturedate)';

debugmsg(cmdsql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Create idels (lot summary) view

debugmsg('create idels view');
cmdSql := 'create view rcpt_note_944_idels_' || strSuffix ||
  '(custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,origtrackingno,'||
  'serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,dtlpassthruchar01,'||
  'dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,dtlpassthruchar06,'||
  'dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,dtlpassthruchar11,'||
  'dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,dtlpassthruchar16,'||
  'dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,dtlpassthrunum01,'||
  'dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,dtlpassthrunum06,'||
  'dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,dtlpassthrudate01,'||
  'dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,dtlpassthrudoll02,'||
  'expirationdate,qty,qtyrcvdgood,qtyrcvddmgd, weight,tareweight,qtyexpected) '||
  'as select '||
   'custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,origtrackingno,'||
  'serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,dtlpassthruchar01,'||
  'dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,dtlpassthruchar06,'||
  'dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,dtlpassthruchar11,'||
  'dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,dtlpassthruchar16,'||
  'dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,dtlpassthrunum01,'||
  'dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,dtlpassthrunum06,'||
  'dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,dtlpassthrudate01,'||
  'dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,dtlpassthrudoll02,'||
  'expirationdate,sum(qty),sum(qtyrcvdgood),sum(qtyrcvddmgd),sum(qty*zci.item_weight(custid,item,uom)),'||
  'sum(qty*zci.item_tareweight(custid,item,uom)), '||
  'max(zim7.line_qty_expected(orderid,shipid,item,lotnumber,line_number)) '||
  'from rcpt_note_944_ide2_' || strSuffix ||
  ' group by custid,orderid,shipid,item,lotnumber,uom,condition,damagereason,line_number,'||
    'origtrackingno,serialnumber,useritem1,useritem2,useritem3,qtyrcvd_invstatus,orig_line_number,'||
    'dtlpassthruchar01,dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,dtlpassthruchar05,'||
    'dtlpassthruchar06,dtlpassthruchar07,dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10,'||
    'dtlpassthruchar11,dtlpassthruchar12,dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,'||
    'dtlpassthruchar16,dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,'||
    'dtlpassthrunum01,dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,dtlpassthrunum05,'||
    'dtlpassthrunum06,dtlpassthrunum07,dtlpassthrunum08,dtlpassthrunum09,dtlpassthrunum10,'||
    'dtlpassthrudate01,dtlpassthrudate02,dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,'||
    'dtlpassthrudoll02,expirationdate';
--debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'select facility from rcpt_note_944_hdr_'||strSuffix;
open cl for cmdsql;
fetch cl into l_facility;
if cl%notfound then
   l_facility := null;
end if;
close cl;


begin
   select code into strEdiPartner
      from EDI_PARTNER
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiPartner := null;
end;
begin
   select code into strEdiSender
      from EDI_SENDER
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiSender := null;
end;

begin
   select code into strEdiBatchref
      from EDI_BATCH_REF
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiBatchref := null;
end;

cmdSql := 'create view rcpt_note_944_ihr_'||strSuffix ||
          '(partneredicode,datetimecreated,custid,senderedicode,applicationsendercode, loadno, orderid, shipid) '||
          'as select ''' || strEdiPartner || ''', to_char(sysdate,''YYYYMMDDHHMI''), ''' ||
          in_custid || ''',''' || strEdiBatchRef || ''',''' || strEdiSender ||''', ' ||
          nvl(in_loadno,0) || ',' || nvl(in_orderid,0) || ',' || nvl(in_shipid,0)|| ' from dual ';

debugmsg(cmdsql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('lip trailer');
cmdSql := 'create or replace view rcpt_note_944_ltrl_' ||strSuffix ||
  ' (custid,orderid,shipid,lip_count, weight, qtyrcvd) as '||
  ' select  custid,orderid,shipid,count(1), sum(weight), sum(qtyrcvd) '||
  ' from RCPT_NOTE_944_LIP_' || strSuffix ||
  ' group by custid, orderid, shipid';

debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('facility');
cmdSql := 'create or replace view rcpt_note_944_fac_' || strSuffix ||
  ' (custid, facility) as ' ||
  ' select distinct custid, facility ' ||
  '  from rcpt_note_944_hdr_' || strSuffix ;
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('mbr');
cmdSql := 'create or replace view rcpt_note_944_mbr_' || strSuffix ||
   '(custid, facility, supplier, bill_of_lading, receipt_date, orderid, '||
    'lotnumber,lpid, item, weight, qtyrcvd, useritem1, useritem2, useritem3) as '||
    'select h.custid, h.facility,''"''|| rtrim(h.supplier) ||''"'', '||
           '''"'' || rtrim(h.bill_of_lading) || ''"'',' ||
           '''"'' || to_char(h.receipt_date, ''YYYY-MM-DD'') || ''"'', '||
           '''"'' || h.orderid || ''"'', '||
           '''"'' || rtrim(l.lotnumber) || ''"'', '||
           '''"'' || l.lpid || ''"'', '||
           '''"'' || rtrim(l.item) ||''"'', l.weight, l.qtyrcvd, '||
           '''"'' || rtrim(p.useritem1) ||''"'','||
           '''"'' || rtrim(p.useritem2) ||''"'','||
           '''"'' || rtrim(p.useritem3) ||''"'' '||
    'from rcpt_note_944_hdr_' || strSuffix || ' h, '||
         'rcpt_note_944_lip_' || strSuffix || ' l, ' ||
         'plate p ' ||
    'where l.orderid = h.orderid '||
      'and l.shipid = h.shipid ' ||
      'and l.lpid = p.lpid ' ||
    ' union ' ||
    'select h.custid, h.facility,''"''|| rtrim(h.supplier) ||''"'', '||
           '''"'' || rtrim(h.bill_of_lading) || ''"'',' ||
           '''"'' || to_char(h.receipt_date, ''YYYY-MM-DD'') || ''"'', '||
           '''"'' || h.orderid || ''"'', '||
           '''"'' || rtrim(l.lotnumber) || ''"'', '||
           '''"'' || l.lpid || ''"'', '||
           '''"'' || rtrim(l.item) ||''"'', l.weight, l.qtyrcvd, '||
           '''"'' || rtrim(p.useritem1) ||''"'','||
           '''"'' || rtrim(p.useritem2) ||''"'','||
           '''"'' || rtrim(p.useritem3) ||''"'' '||
    'from rcpt_note_944_hdr_' || strSuffix || ' h, '||
         'rcpt_note_944_lip_' || strSuffix || ' l, ' ||
         'deletedplate p ' ||
    'where l.orderid = h.orderid '||
      'and l.shipid = h.shipid ' ||
      'and l.lpid = p.lpid ';


debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('done');
out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbrn944 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_rcptnote944;

procedure end_rcptnote944
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

begin
  cmdSql := 'drop view rcpt_note_944_ide_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_ide2_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_idels_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_add_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_addln_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;
begin
  cmdSql := 'drop view rcpt_note_944_fac_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;
begin
  cmdSql := 'drop view rcpt_note_944_mbr_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;
begin
  cmdSql := 'drop view rcpt_note_944_trl_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;
begin
  cmdSql := 'drop view rcpt_note_944_ltrl_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop table rcpt_note_944_dtl_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_dtl_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
  cmdSql := 'drop view rcpt_note_944_bdn_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop VIEW rcpt_note_944_ihr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop VIEW rcpt_note_944_pal_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop VIEW rcpt_note_944_nte_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop VIEW rcpt_note_944_lu1_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop table rcpt_note_944_lip_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop table rcpt_note_944_cfs_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

begin
cmdSql := 'drop table rcpt_note_944_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
exception when others then
  dbms_sql.close_cursor(curFunc);
end;

delete from rcptnote944noteex where sessionid = strSuffix;

delete from rcptnote944ideex where sessionid = strSuffix;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimern944 ' || sqlerrm;
  out_errorno := sqlcode;
end end_rcptnote944;


procedure begin_shipnote945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_include_fromlpid_yn IN varchar2
,in_ltl_freight_passthru IN varchar2
,in_bol_tracking_yn IN varchar2
,in_round_freight_weight_up_yn IN varchar2
,in_invclass_yn IN varchar2
,in_carton_uom IN varchar2
,in_contents_by_po IN varchar2
,in_exclude_xdockorder_yn IN varchar2
,in_abc_revisions_yn IN varchar2
,in_abc_revisions_column IN varchar2
,in_fhd_sequence IN varchar2
,in_dtllot_yn IN varchar2
,in_include_zero_qty_lot_yn IN varchar2
,in_cnt_ignore_lot_yn IN varchar2
,in_810_yn IN varchar2
,in_transaction IN varchar2
,in_enforce_edi_trans_yn IN varchar2
,in_smallpackage_by_tn_yn IN varchar2
,in_shipment_column IN varchar2
,in_aux_shipment_column IN varchar2
,in_masterbol_column IN varchar2
,in_id_passthru_yn IN varchar2
,in_track_separator IN varchar2
,in_item_descr_dtlpassthru IN varchar2
,in_upc_dtlpassthru IN varchar2
,in_include_zero_qty_ctn_yn IN varchar2
,in_force_cnt_fromlpid_yn IN varchar2
,in_create_cnt_fs_yn IN varchar2
,in_cancel_productgroup IN varchar2
,in_force_estdelivery_yn IN varchar2
,in_estdelivery_validation_tbl in varchar2
,in_cnt_groupby_useritem IN varchar2
,in_include_zero_qty_shipped_yn IN varchar2
,in_ctn_rollup_lot_yn in varchar2
,in_create_cfs_yn IN varchar2
,in_lots_qtyorder_diff_yn IN varchar2
,in_freight_cost_once_yn IN varchar2
,in_810_seq_by_custid IN varchar2
,in_order_odl_by_qty_yn IN varchar2
,in_create_945_shipment_yn IN varchar2
,in_945_shipment_single_bol_yn IN varchar2
,in_shp_no_load_assigned_sp_yn in varchar2
,in_cost_by_trackingno_yn IN varchar2
,in_woodpalletcount_list IN varchar2
,in_lwh_in_ea_yn in varchar2
,in_allow_pick_status_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn,
    sipconsigneematchfield
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and loadno = in_loadno
   order by orderid,shipid;

cursor curPickOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('6','7','8','9','X')
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curPickOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('6','7','8','9','X')
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curPickOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('6','7','8','9','X')
     and loadno = in_loadno
   order by orderid,shipid;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15);
sp curShippingPlate%rowtype;



cursor curShippingPlateLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         lotnumber,
         max(fromlpid) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            lotnumber;
spl curShippingPlateLot%rowtype;

cursor curShippingPlateInvClass(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         lotnumber,
                        inventoryclass,
         max(fromlpid) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            lotnumber,inventoryclass;
spi curShippingPlateInvClass%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.LOTNUMBER as lotnumber,
         nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
         nvl(ol.DTLPASSTHRUchar01,od.DTLPASSTHRUchar01) as dtlpassthruchar01,
         nvl(ol.DTLPASSTHRUchar02,od.DTLPASSTHRUchar02) as dtlpassthruchar02,
         nvl(ol.DTLPASSTHRUchar03,od.DTLPASSTHRUchar03) as dtlpassthruchar03,
         nvl(ol.DTLPASSTHRUchar04,od.DTLPASSTHRUchar04) as dtlpassthruchar04,
         nvl(ol.DTLPASSTHRUchar05,od.DTLPASSTHRUchar05) as dtlpassthruchar05,
         nvl(ol.DTLPASSTHRUchar06,od.DTLPASSTHRUchar06) as dtlpassthruchar06,
         nvl(ol.DTLPASSTHRUchar07,od.DTLPASSTHRUchar07) as dtlpassthruchar07,
         nvl(ol.DTLPASSTHRUchar08,od.DTLPASSTHRUchar08) as dtlpassthruchar08,
         nvl(ol.DTLPASSTHRUchar09,od.DTLPASSTHRUchar09) as dtlpassthruchar09,
         nvl(ol.DTLPASSTHRUchar10,od.DTLPASSTHRUchar10) as dtlpassthruchar10,
         nvl(ol.DTLPASSTHRUchar11,od.DTLPASSTHRUchar11) as dtlpassthruchar11,
         nvl(ol.DTLPASSTHRUchar12,od.DTLPASSTHRUchar12) as dtlpassthruchar12,
         nvl(ol.DTLPASSTHRUchar13,od.DTLPASSTHRUchar13) as dtlpassthruchar13,
         nvl(ol.DTLPASSTHRUchar14,od.DTLPASSTHRUchar14) as dtlpassthruchar14,
         nvl(ol.DTLPASSTHRUchar15,od.DTLPASSTHRUchar15) as dtlpassthruchar15,
         nvl(ol.DTLPASSTHRUchar16,od.DTLPASSTHRUchar16) as dtlpassthruchar16,
         nvl(ol.DTLPASSTHRUchar17,od.DTLPASSTHRUchar17) as dtlpassthruchar17,
         nvl(ol.DTLPASSTHRUchar18,od.DTLPASSTHRUchar18) as dtlpassthruchar18,
         nvl(ol.DTLPASSTHRUchar19,od.DTLPASSTHRUchar19) as dtlpassthruchar19,
         nvl(ol.DTLPASSTHRUchar20,od.DTLPASSTHRUchar20) as dtlpassthruchar20,
         nvl(ol.DTLPASSTHRUchar21,od.DTLPASSTHRUchar21) as dtlpassthruchar21,
         nvl(ol.DTLPASSTHRUchar22,od.DTLPASSTHRUchar22) as dtlpassthruchar22,
         nvl(ol.DTLPASSTHRUchar23,od.DTLPASSTHRUchar23) as dtlpassthruchar23,
         nvl(ol.DTLPASSTHRUchar24,od.DTLPASSTHRUchar24) as dtlpassthruchar24,
         nvl(ol.DTLPASSTHRUchar25,od.DTLPASSTHRUchar25) as dtlpassthruchar25,
         nvl(ol.DTLPASSTHRUchar26,od.DTLPASSTHRUchar26) as dtlpassthruchar26,
         nvl(ol.DTLPASSTHRUchar27,od.DTLPASSTHRUchar27) as dtlpassthruchar27,
         nvl(ol.DTLPASSTHRUchar28,od.DTLPASSTHRUchar28) as dtlpassthruchar28,
         nvl(ol.DTLPASSTHRUchar29,od.DTLPASSTHRUchar29) as dtlpassthruchar29,
         nvl(ol.DTLPASSTHRUchar30,od.DTLPASSTHRUchar30) as dtlpassthruchar30,
         nvl(ol.DTLPASSTHRUchar31,od.DTLPASSTHRUchar31) as dtlpassthruchar31,
         nvl(ol.DTLPASSTHRUchar32,od.DTLPASSTHRUchar32) as dtlpassthruchar32,
         nvl(ol.DTLPASSTHRUchar33,od.DTLPASSTHRUchar33) as dtlpassthruchar33,
         nvl(ol.DTLPASSTHRUchar34,od.DTLPASSTHRUchar34) as dtlpassthruchar34,
         nvl(ol.DTLPASSTHRUchar35,od.DTLPASSTHRUchar35) as dtlpassthruchar35,
         nvl(ol.DTLPASSTHRUchar36,od.DTLPASSTHRUchar36) as dtlpassthruchar36,
         nvl(ol.DTLPASSTHRUchar37,od.DTLPASSTHRUchar37) as dtlpassthruchar37,
         nvl(ol.DTLPASSTHRUchar38,od.DTLPASSTHRUchar38) as dtlpassthruchar38,
         nvl(ol.DTLPASSTHRUchar39,od.DTLPASSTHRUchar39) as dtlpassthruchar39,
         nvl(ol.DTLPASSTHRUchar40,od.DTLPASSTHRUchar40) as dtlpassthruchar40,
         nvl(ol.DTLPASSTHRUNUM01,od.dtlpassthrunum01) as dtlpassthrunum01,
         nvl(ol.DTLPASSTHRUNUM02,od.dtlpassthrunum02) as dtlpassthrunum02,
         nvl(ol.DTLPASSTHRUNUM03,od.dtlpassthrunum03) as dtlpassthrunum03,
         nvl(ol.DTLPASSTHRUNUM04,od.dtlpassthrunum04) as dtlpassthrunum04,
         nvl(ol.DTLPASSTHRUNUM05,od.dtlpassthrunum05) as dtlpassthrunum05,
         nvl(ol.DTLPASSTHRUNUM06,od.dtlpassthrunum06) as dtlpassthrunum06,
         nvl(ol.DTLPASSTHRUNUM07,od.dtlpassthrunum07) as dtlpassthrunum07,
         nvl(ol.DTLPASSTHRUNUM08,od.dtlpassthrunum08) as dtlpassthrunum08,
         nvl(ol.DTLPASSTHRUNUM09,od.dtlpassthrunum09) as dtlpassthrunum09,
         nvl(ol.DTLPASSTHRUNUM10,od.dtlpassthrunum10) as dtlpassthrunum10,
         nvl(ol.DTLPASSTHRUNUM11,od.dtlpassthrunum11) as dtlpassthrunum11,
         nvl(ol.DTLPASSTHRUNUM12,od.dtlpassthrunum12) as dtlpassthrunum12,
         nvl(ol.DTLPASSTHRUNUM13,od.dtlpassthrunum13) as dtlpassthrunum13,
         nvl(ol.DTLPASSTHRUNUM14,od.dtlpassthrunum14) as dtlpassthrunum14,
         nvl(ol.DTLPASSTHRUNUM15,od.dtlpassthrunum15) as dtlpassthrunum15,
         nvl(ol.DTLPASSTHRUNUM16,od.dtlpassthrunum16) as dtlpassthrunum16,
         nvl(ol.DTLPASSTHRUNUM17,od.dtlpassthrunum17) as dtlpassthrunum17,
         nvl(ol.DTLPASSTHRUNUM18,od.dtlpassthrunum18) as dtlpassthrunum18,
         nvl(ol.DTLPASSTHRUNUM19,od.dtlpassthrunum19) as dtlpassthrunum19,
         nvl(ol.DTLPASSTHRUNUM20,od.dtlpassthrunum20) as dtlpassthrunum20,
         nvl(ol.LASTUSER,od.lastuser) as lastuser,
         nvl(ol.LASTUPDATE,od.lastupdate) as lastupdate,
         nvl(ol.DTLPASSTHRUDATE01,od.dtlpassthrudate01) as dtlpassthrudate01,
         nvl(ol.DTLPASSTHRUDATE02,od.dtlpassthrudate02) as dtlpassthrudate02,
         nvl(ol.DTLPASSTHRUDATE03,od.dtlpassthrudate03) as dtlpassthrudate03,
         nvl(ol.DTLPASSTHRUDATE04,od.dtlpassthrudate04) as dtlpassthrudate04,
         nvl(ol.DTLPASSTHRUDOLL01,od.dtlpassthrudoll01) as dtlpassthrudoll01,
         nvl(ol.DTLPASSTHRUDOLL02,od.dtlpassthrudoll02) as dtlpassthrudoll02,
         nvl(ol.QTYAPPROVED,0) as qtyapproved,
                        nvl(ol.uomentered, OD.uomentered) as uomentered
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curCarrier(in_carrier varchar2) is
  select *
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

cursor curCustItem(in_custid varchar2, in_item varchar2) is
  select descr
    from custitemview
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curLoads(in_loadno number) is
  select *
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

type lot_rcd is record (
  lotnumber    orderdtl.lotnumber%type,
  qtyapplied    orderdtl.qtyorder%type,
  qtyordered    orderdtl.qtyorder%type,
  qtydiff       orderdtl.qtyorder%type

);

type lot_tbl is table of lot_rcd
     index by binary_integer;

lots lot_tbl;
lotx pls_integer;
lotfoundx pls_integer;
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
cmdSqlShipDays varchar2(200);
strDebugYN char(1);
curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
strFromLpid varchar2(15);
InvClass varchar2(2);
dteTest date;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
qtyLineAccum shippingplate.quantity%type;
qtyShipped shippingplate.quantity%type;
qtyOrdered shippingplate.quantity%type;
strCaseUpc varchar2(255);
dteExpirationDate date;
weightshipped orderdtl.weightship%type;
dtl945 ship_note_945_dtl%rowtype;
strLotNumber shippingplate.lotnumber%type;
l_condition varchar2(2000);
l_carton_uom varchar2(4);
qtyOrd integer;
l_loadno orderhdr.loadno%type;
l_custid orderhdr.custid%type;
fileHdrSequence varchar2(20);
   d_orderid orderdtl.orderid%type;
   d_shipid orderdtl.shipid%type;
   d_custid orderhdr.custid%type;
TYPE cur_type is REF CURSOR;
cl cur_type;
l_facility orderhdr.tofacility%type;
strEdiPartner varchar2(25);
strEdiSender varchar2(25);
strEdiBatchRef varchar2(25);
add_zero_qty_shipped_yn char(1);
l_zero_shipped_cartonid945 varchar2(40);
strAssignedid orderdtlline.dtlpassthrunum10%type;
strWhiteType pallethistory.pallettype%type;
strChepType pallethistory.pallettype%type;
pType pallethistory.pallettype%type;

procedure debugmsg(in_text varchar2) is

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

procedure insert_945_lot(oh curOrderHdr%rowtype, od curOrderDtl%rowtype,
  ol curOrderDtlLine%rowtype, in_lotnumber varchar2, in_qty number,
  in_ord number, in_diff number) is
begin

debugmsg('begin insert_945_lot '  || od.orderid || '-' || od.shipid || ' ' ||
  od.item || ' ' || od.lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

strAssignedid := 0;
if ol.dtlpassthrunum10 is null then
  strAssignedid := 0;
else
  strAssignedid := ol.dtlpassthrunum10;
end if;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into ship_note_945_lot_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,' ||
':ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
':QTYSHIPPED,:QTYORDERED,:QTYDIFF,:WEIGHTSHIPPED,:LINK_ASSIGNEDID)',
  dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.CUSTID);
dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ol.dtlpassthrunum10);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', in_lotnumber);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', strLotNumber);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', in_qty);
dbms_sql.bind_variable(curFunc, ':QTYORDERED', in_ord);
dbms_sql.bind_variable(curFunc, ':QTYDIFF', in_diff);
dbms_sql.bind_variable(curFunc, ':WEIGHTSHIPPED', zci.item_weight(od.custid,od.item,od.uom) * in_qty);
dbms_sql.bind_variable(curFunc, ':LINK_ASSIGNEDID', strAssignedid);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end;

procedure insert_945_dtl(oh curOrderHdr%rowtype, od curOrderDtl%rowtype,
  ol curOrderDtlLine%rowtype, invcls varchar2) is
strReference orderhdr.reference%type;
nullStr varchar2(2) := null;
cursor od_gtin(in_custid varchar2, in_item varchar2) is
   select substr(itemalias,1,14) as itemalias
     from custitemalias
     where custid = in_custid
       and item = in_item
       and aliasdesc like 'GTIN%';
ODG od_gtin%rowtype;
begin

debugmsg('begin insert_945_dtl '  || od.orderid || '-' || od.shipid || ' ' ||
  od.item || ' ' || od.lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

qtyOrdered := ol.qty;

if upper(nvl(in_invclass_yn,'N')) = 'Y' then
  if qtyLineAccum = 0 then
    qtyOrdered := od.qtyorder;
  else
    qtyOrdered := qtyLineAccum;
  end if;
  qtyShipped := qtyLineAccum;
elsif upper(nvl(in_include_fromlpid_yn,'N')) = 'Y' and
      upper(nvl(in_summarize_lots_yn,'N')) = 'Y' then
  qtyShipped := qtyLineNumber;
else
  qtyShipped := ol.qty - qtyRemain;
end if;

begin
   select productgroup into dtl945.productgroup
     from custitemview
    where custid = oh.custid
      and item = od.item;
exception when no_data_found then
   dtl945.productgroup := null;
end;
if qtyShipped = 0 and
   nvl(in_cancel_productgroup,'NOPE') = nvl(dtl945.productgroup,'none') then
      qtyShipped := ol.qty;
end if;
debugmsg('get upc');
begin
  select upc
    into dtl945.Upc
    from custitemupcview
   where custid = cu.custid
     and item = od.item;
exception when others then
  dtl945.Upc := '';
end;
begin
   select hazardous into dtl945.hazardous
      from custitem
   where custid = cu.custid
     and item = od.item;
exception when others then
  dtl945.hazardous := '';
end;
weightshipped := zci.item_weight(cu.custid,od.item,od.uom) * qtyShipped;
dtl945.shipticket := substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15);

if nvl(rtrim(in_invclass_yn),'N') = 'N' then
  InvClass := '  ';
else
  InvClass := invcls;
end if;

if ca.multiship = 'Y' then
  dtl945.trackingno := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
else
  if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
    dtl945.trackingno :=
          nvl(oh.prono,nvl(ld.prono,nvl(oh.billoflading,nvl(ld.billoflading,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)))));
  else
    dtl945.trackingno :=
      nvl(oh.prono,nvl(ld.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)));
  end if;
end if;
if nvl(in_abc_revisions_yn, 'n') = 'Y' then
   strReference := zim7.abc_reference(oh.ORDERID, oh.SHIPID, in_abc_revisions_column);
else
   strReference := oh.REFERENCE;
end if;
dtl945.kgs := weightshipped / 2.2046;
dtl945.gms := weightshipped / .0022046;
dtl945.ozs := weightshipped * 16;
dtl945.smallpackagelbs := zim14.freight_weight(oh.orderid,oh.shipid,od.item,od.lotnumber,
  nvl(rtrim(in_round_freight_weight_up_yn),'N'));
dtl945.deliveryservice :=
 substr(zim14.delivery_service(oh.orderid,oh.shipid,od.item,od.lotnumber),1,10);
strAssignedid := 0;
if ol.dtlpassthrunum10 is null then
  strAssignedid := 0;
else
  strAssignedid := ol.dtlpassthrunum10;
end if;
ODG := null;
open od_gtin(oh.custid, od.item);
fetch od_gtin into ODG;
close od_gtin;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into ship_note_945_dtl_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,:SHIPTICKET,:TRACKINGNO,' ||
':SERVICECODE,:LBS,:KGS,:GMS,:OZS,:ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
':INVENTORYCLASS,' ||
':STATUSCODE,:REFERENCE,:LINENUMBER,:ORDERDATE,:PO,:QTYORDERED,:QTYSHIPPED,' ||
':QTYDIFF,:UOM,:PACKLISTSHIPDATE,:WEIGHT,:WEIGHTQUAIFIER,:WEIGHTUNIT,' ||
':DESCRIPTION,:UPC,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,' ||
':DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,' ||
':DTLPASSTHRUCHAR08,:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,' ||
':DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,' ||
':DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,' ||
':DTLPASSTHRUCHAR20,'||
':DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,:DTLPASSTHRUCHAR23,' ||
':DTLPASSTHRUCHAR24,:DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,:DTLPASSTHRUCHAR27,' ||
':DTLPASSTHRUCHAR28,:DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,:DTLPASSTHRUCHAR31,' ||
':DTLPASSTHRUCHAR32,:DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,:DTLPASSTHRUCHAR35,' ||
':DTLPASSTHRUCHAR36,:DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,:DTLPASSTHRUCHAR39,' ||
':DTLPASSTHRUCHAR40, '||
':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,' ||
':DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,' ||
':DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
':DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,:DTLPASSTHRUNUM13,' ||
':DTLPASSTHRUNUM14,:DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,:DTLPASSTHRUNUM17,' ||
':DTLPASSTHRUNUM18,:DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,:DTLPASSTHRUDATE01,' ||
':DTLPASSTHRUDATE02,:DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,' ||
':DTLPASSTHRUDOLL02, :FROMLPID, :SMALLPACKAGELBS, :DELIVERYSERVICE, ' ||
':ENTEREDUOM, :QTYSHIPPEDUOM, :HAZARDOUS, :PRODUCTGROUP, :LINK_ASSIGNEDID, ' ||
':CANCELREASON, :SHIPSHORTREASON,:CONSIGNEESKU,:GTIN)',
  dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.CUSTID);
dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ol.dtlpassthrunum10);
dbms_sql.bind_variable(curFunc, ':SHIPTICKET', dtl945.SHIPTICKET);
dbms_sql.bind_variable(curFunc, ':TRACKINGNO', dtl945.TRACKINGNO);
dbms_sql.bind_variable(curFunc, ':SERVICECODE', oh.deliveryservice);
dbms_sql.bind_variable(curFunc, ':LBS', weightshipped);
dbms_sql.bind_variable(curFunc, ':KGS', dtl945.kgs);
dbms_sql.bind_variable(curFunc, ':GMS', dtl945.gms);
dbms_sql.bind_variable(curFunc, ':OZS', dtl945.ozs);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.lotnumber);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', strLotNumber);
dbms_sql.bind_variable(curFunc, ':INVENTORYCLASS', InvClass);
dbms_sql.bind_variable(curFunc, ':STATUSCODE', od.linestatus);
dbms_sql.bind_variable(curFunc, ':REFERENCE', strReference);
dbms_sql.bind_variable(curFunc, ':LINENUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ORDERDATE', oh.ENTRYDATE);
dbms_sql.bind_variable(curFunc, ':PO', oh.PO);
dbms_sql.bind_variable(curFunc, ':QTYORDERED', qtyOrdered);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', qtySHIPPED);
dbms_sql.bind_variable(curFunc, ':QTYDIFF', ol.QTY - qtyShipped);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':PACKLISTSHIPDATE', oh.PACKLISTSHIPDATE);
dbms_sql.bind_variable(curFunc, ':WEIGHT', weightshipped);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUAIFIER', 'G');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNIT', 'L');
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', ci.descr);
dbms_sql.bind_variable(curFunc, ':UPC', dtl945.upc);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR21', ol.DTLPASSTHRUCHAR21);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR22', ol.DTLPASSTHRUCHAR22);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR23', ol.DTLPASSTHRUCHAR23);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR24', ol.DTLPASSTHRUCHAR24);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR25', ol.DTLPASSTHRUCHAR25);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR26', ol.DTLPASSTHRUCHAR26);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR27', ol.DTLPASSTHRUCHAR27);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR28', ol.DTLPASSTHRUCHAR28);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR29', ol.DTLPASSTHRUCHAR29);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR30', ol.DTLPASSTHRUCHAR30);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR31', ol.DTLPASSTHRUCHAR31);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR32', ol.DTLPASSTHRUCHAR32);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR33', ol.DTLPASSTHRUCHAR33);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR34', ol.DTLPASSTHRUCHAR34);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR35', ol.DTLPASSTHRUCHAR35);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR36', ol.DTLPASSTHRUCHAR36);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR37', ol.DTLPASSTHRUCHAR37);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR38', ol.DTLPASSTHRUCHAR38);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR39', ol.DTLPASSTHRUCHAR39);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR40', ol.DTLPASSTHRUCHAR40);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM11', ol.DTLPASSTHRUNUM11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM12', ol.DTLPASSTHRUNUM12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM13', ol.DTLPASSTHRUNUM13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM14', ol.DTLPASSTHRUNUM14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM15', ol.DTLPASSTHRUNUM15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM16', ol.DTLPASSTHRUNUM16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM17', ol.DTLPASSTHRUNUM17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM18', ol.DTLPASSTHRUNUM18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM19', ol.DTLPASSTHRUNUM19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM20', ol.DTLPASSTHRUNUM20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':FROMLPID', strFromLpid);
dbms_sql.bind_variable(curFunc, ':SMALLPACKAGELBS', dtl945.smallpackagelbs);
dbms_sql.bind_variable(curFunc, ':DELIVERYSERVICE', dtl945.DELIVERYSERVICE);
dbms_sql.bind_variable(curFunc, ':ENTEREDUOM', ol.uomentered);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPEDUOM',
    zcu.equiv_uom_qty(OH.custid,OD.item,OD.uom,qtyShipped,ol.uomentered));
dbms_sql.bind_variable(curFunc, ':HAZARDOUS', dtl945.HAZARDOUS);
dbms_sql.bind_variable(curFunc, ':PRODUCTGROUP', dtl945.productgroup);
dbms_sql.bind_variable(curFunc, ':LINK_ASSIGNEDID', strAssignedid);
dbms_sql.bind_variable(curFunc, ':CANCELREASON', od.cancelreason);
dbms_sql.bind_variable(curFunc, ':SHIPSHORTREASON', od.shipshortreason);
dbms_sql.bind_variable(curFunc, ':CONSIGNEESKU', od.consigneesku);
dbms_sql.bind_variable(curFunc, ':GTIN', ODG.itemalias);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end;



procedure add_945_dtl_rows_by_lot(oh curorderhdr%rowtype) is
ndxlot integer;
dsplymsg varchar2(255);
begin
  debugmsg('begin add_945_dtl_rows_by_lot');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    spl := null;
    open curShippingPlateLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateLot into spl;
    debugmsg('get lines');
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      qtyLineAccum := 0;
      lots.delete;
      qtyLineNumber := 0;
      qtyRemain := ol.qty;
      debugmsg('parentlpid ' || spl.parentlpid);
      if spl.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if spl.qty = 0 then
            debugmsg('get shippingplate');
            fetch curShippingPlateLot into spl;
            if curShippingPlateLot%notfound then
              spl := null;
              exit;
            end if;
          end if;
          if spl.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := spl.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          debugmsg('get expiration date');
          dteExpirationDate := zimsip.lip_expirationdate(spl.fromlpid);
          debugmsg('find lot');
          lotfoundx := 0;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spl.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfoundx := lotx;
              exit;
            end if;
          end loop;
          if lotfoundx != 0 then
            lotx := lotfoundx;
            dsplymsg := 'lot found ' || to_char(lotx, '99') || lots(lotx).lotnumber;
            debugmsg(spl.lotnumber);
          else
            lotx := lots.count + 1;
            dsplymsg := 'lot new ' || to_char(lotx, '99') || spl.lotnumber;
            if lotx = 1 then
               debugmsg(' lotx1');
            else
               debugmsg(' lotx not 1');
            end if;
            debugmsg(spl.lotnumber || '-' || spl.lotnumber);
            lots(lotx).lotnumber := spl.lotnumber;
            lots(lotx).qtyApplied := qtyLineNumber;
          end if;
          qtyRemain := qtyRemain - qtyLineNumber;
          spl.qty := spl.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      debugmsg('++qtyLineAccum '||qtyLineAccum);
      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          (upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' or
           sn945_include_canceled(in_cancel_productgroup, oh.custid, oh.orderid, oh.shipid, od.item) = true)) then
        insert_945_dtl(oh, od, ol, '  ');
        if  (qtyLineAccum = 0 and
             upper(nvl(in_include_zero_qty_lot_yn,'Y')) = 'Y') then
             insert_945_lot(oh,od,ol,null,0,od.qtyorder,od.qtyorder);
        else
           qtyOrd := od.qtyorder;
        for lotx in 1..lots.count
        loop
          if lotx = lots.count then
             lots(lotx).qtyordered := qtyOrd;
          else
             lots(lotx).qtyordered := lots(lotx).qtyapplied;
          end if;

          if (nvl(in_lots_qtyorder_diff_yn, 'N') = 'N') then
            lots(lotx).qtydiff := lots(lotx).qtyordered - lots(lotx).qtyapplied;
            qtyOrd := qtyOrd - lots(lotx).qtyapplied;
            insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,lots(lotx).qtyordered,lots(lotx).qtydiff);
          else
            lots(lotx).qtydiff := od.qtyorder - lots(lotx).qtyapplied;
            qtyOrd := qtyOrd - lots(lotx).qtyapplied;
            debugmsg('in_lots_qtyorder_diff_yn=Y >> ' || lots(lotx).qtyapplied||' - '||od.qtyorder || ' - ' ||lots(lotx).qtydiff);
            insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,od.qtyorder,lots(lotx).qtydiff);
          end if;

        end loop;
        end if;
      end if;
    end loop; -- orderdtlline
    close curShippingPlateLot;
  end loop; -- orderdtl
end;

procedure add_945_dtl_rows_by_invclass(oh curorderhdr%rowtype) is
sqlMsg varchar2(255);
begin
  debugmsg('begin add_945_dtl_rows_by_invclass');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('item ' || od.item || ' lot ' || od.lotnumber ||
            ' qtyorder ' || od.qtyorder || ' qtyship ' || od.qtyship);
    qtyRemain := od.qtyship;
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    spi := null;
    open curShippingPlateInvClass(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateInvClass into spi;
    debugmsg('get lines');
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      debugmsg('line ' || ol.linenumber);
      qtyLineAccum := 0;
      lots.delete;
      qtyLineNumber := 0;
      qtyRemain := ol.qty;
      if spi.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if spi.qty = 0 then
            debugmsg('get shippingplate');
            fetch curShippingPlateInvClass into spi;
            if curShippingPlateInvClass%notfound then
              spi := null;
              exit;
            end if;
          end if;
          if spi.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := spi.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          debugmsg('get expiration date');
          dteExpirationDate := zimsip.lip_expirationdate(spi.fromlpid);
          debugmsg('find lot');
          lotfoundx := 0;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spi.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfoundx := lotx;
              exit;
            end if;
          end loop;
          if lotfoundx != 0 then
            lotx := lotfoundx;
            debugmsg('lot found');
          else
            debugmsg('new lot' || to_char(lotx, '99') || '-' || spi.lotnumber);
            lotx := lots.count + 1;
            lots(lotx).lotnumber := spi.lotnumber;
            lots(lotx).qtyApplied := qtyLineNumber;
          end if;
          qtyRemain := qtyRemain - qtyLineNumber;
          spi.qty := spi.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      debugmsg(' qtyLineAccum ' || qtyLineAccum || ' qtyRemain ' || qtyRemain);
      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          (upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y' or
           sn945_include_canceled(in_cancel_productgroup, oh.custid, oh.orderid, oh.shipid, od.item) = true)) then
        qtyLineNumber := qtyLineAccum;
        insert_945_dtl(oh, od, ol, spi.inventoryclass);
        qtyOrd := od.qtyorder;
        for lotx in 1..lots.count
        loop
          if lotx = lots.count then
             lots(lotx).qtyordered := qtyOrd;
          else
             lots(lotx).qtyordered := lots(lotx).qtyapplied;
          end if;

          if (nvl(in_lots_qtyorder_diff_yn, 'N') = 'N') then
            lots(lotx).qtydiff := lots(lotx).qtyordered - lots(lotx).qtyapplied;
            qtyOrd := qtyOrd - lots(lotx).qtyapplied;
            insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,lots(lotx).qtyordered,lots(lotx).qtydiff);
          else
            lots(lotx).qtydiff := od.qtyorder - lots(lotx).qtyapplied;
            qtyOrd := qtyOrd - lots(lotx).qtyapplied;
            insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,od.qtyorder,lots(lotx).qtydiff);
          end if;

        end loop;
      end if;
    end loop; -- orderdtlline
    close curShippingPlateInvClass;
  end loop; -- orderdtl
end;

procedure add_945_dtl_rows_by_item(oh curorderhdr%rowtype) is
begin
  debugmsg('begin add_945_dtl_rows_by_item');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('order dtl loop');
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    sp := null;
    open curShippingPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlate into sp;
    debugmsg('sp  is ' || sp.parentlpid || '|' || sp.fromlpid || ' ' || sp.qty);
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      debugmsg('line ' || ol.linenumber);
      qtyLineAccum := 0;
      debugmsg('order line loop');
      qtyRemain := ol.qty;
      qtyLineNumber := 0;
      if sp.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if sp.qty = 0 then
            debugmsg('get next shipping plate');
            fetch curShippingPlate into sp;
            if curShippingPlate%notfound then
              debugmsg('no more shipping plate');
              sp := null;
              exit;
            end if;
          end if;
          if sp.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := sp.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          debugmsg(' qtyLineAccum ' || qtyLineAccum || ' qtyLineNumber ' || qtyLinenumber);
          dteExpirationDate := null;
          qtyRemain := qtyRemain - qtyLineNumber;
          sp.qty := sp.qty - qtyLineNumber;
          if upper(nvl(in_include_fromlpid_yn,'N')) = 'Y' then
            strFromLpid := sp.fromlpid;
            insert_945_dtl(oh,od,ol,'  ');
            strFromLpid := '';
          end if;
        end loop; -- shippingplate
      end if;
      if (qtyLineAccum <> 0 and
          upper(nvl(in_include_fromlpid_yn,'N')) != 'Y') or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
          insert_945_dtl(oh, od, ol,'  ');
      end if;
    end loop; -- orderdtlline
    close curShippingPlate;
  end loop; -- orderdtl
  debugmsg('end add_945_dtl_rows_by_item');
end;

procedure add_945_man_rows(oh curorderhdr%rowtype) is
TYPE cur_type is REF CURSOR;
cr cur_type;

man945 ship_note_945_man%rowtype;
qty number;

cmdsql varchar2(200);
cursor C_SP
IS
select *
  from shippingplate
 where orderid = oh.orderid
   and shipid = oh.shipid
   and item = man945.item
   and nvl(lotnumber,'(none)') = nvl(man945.lotnumber,'(none)')
   and serialnumber is not null;

SP shippingplate%rowtype;

begin
    debugmsg('begin add_945_man_rows ' || oh.orderid || '-' || oh.shipid);

    man945 := null;
    man945.orderid := oh.orderid;
    man945.shipid := oh.shipid;
    man945.custid := oh.custid;

    cmdsql := 'select item, lotnumber, assignedid, qtyshipped,'||
        ' dtlpassthruchar01 from ship_note_945_dtl_'||strSuffix||
        ' where orderid = ' || oh.orderid ||
          ' and shipid = '  || oh.shipid;

    debugmsg(cmdsql);

    SP := null;

    open cr for cmdsql;

    loop
        fetch cr into man945.item, man945.lotnumber, man945.assignedid, qty,
            man945.dtlpassthruchar01;
        exit when cr%notfound;

        debugmsg('MAN:'||man945.item||'/'||man945.lotnumber||' Id:'||
            man945.assignedid||' Qty:'||qty);

        man945.link_lotnumber := nvl(man945.lotnumber,'(none)');

        if nvl(SP.item,'aa') != man945.item
        or nvl(SP.lotnumber,'(none)') != nvl(man945.lotnumber,'(none)')
        then
            if C_SP%isopen then
                close C_SP;
            end if;
            open C_SP;
        end if;
        loop
          fetch C_SP into SP;
          exit when C_SP%notfound;
          if SP.item is not null then
            debugmsg('Have SN:'||SP.serialnumber);

            man945.serialnumber := SP.serialnumber;

            if SP.type <> 'F' then
               select shippingcost into SP.shippingcost
                  from shippingplate
                  where lpid = SP.parentlpid;
            end if;
            execute immediate 'insert into ship_note_945_man_'||strSuffix||
            ' values(:orderid,:shipid,:custid,:assignedid,:item,:lotnumber,'||
            ' :link_lotnumber,:serialnumber,:dtlpassthruchar01, :fromlpid, :lpid, ' ||
            ' :trackingno, :shippingcost, :weight, :quantity ) ' using
            man945.orderid, man945.shipid, man945.custid,man945.assignedid,
            man945.item, man945.lotnumber, man945.link_lotnumber,
            man945.serialnumber, man945.dtlpassthruchar01, SP.fromlpid,
            SP.lpid, SP.trackingno, SP.shippingcost, SP.weight, SP.quantity;
            qty := qty - SP.quantity;

          end if;
          exit when qty <= 0;

        end loop;


    end loop;

    close cr;
    if C_SP%isopen then
        close C_SP;
    end if;

end;

procedure add_945_dtl_rows(oh curorderhdr%rowtype) is
begin

debugmsg('begin add_945_dtl_rows ' || oh.orderid || '-' || oh.shipid);

if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  if oh.orderstatus = 'X' then
    return;
  end if;
end if;

ca := null;
open curCarrier(oh.carrier);
fetch curCarrier into ca;
close curCarrier;

ld := null;
open curLoads(oh.loadno);
fetch curLoads into ld;
close curLoads;

  if nvl(in_invclass_yn, 'N') = 'Y' then
     debugmsg('exec add_by_cls');
     add_945_dtl_rows_by_invclass(oh);
  else
     if nvl(in_summarize_lots_yn,'N') = 'Y'  then
        debugmsg('exec add_by_item');
        add_945_dtl_rows_by_item(oh);
     else
        debugmsg('exec add_by_lot');
        add_945_dtl_rows_by_lot(oh);
     end if;
  end if;

        add_945_man_rows(oh);

exception when others then
  debugmsg(sqlerrm);
end;

procedure extract_by_line_numbers is
begin

debugmsg('begin 945 extract by line numbers');
debugmsg('creating 945 dtl');
cmdSql := 'create table SHIP_NOTE_945_DTL_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4),SHIPTICKET VARCHAR2(15),TRACKINGNO VARCHAR2(81),' ||
' SERVICECODE VARCHAR2(4),LBS NUMBER(17,8),KGS NUMBER,GMS NUMBER,' ||
' OZS NUMBER,item varchar2(50) not null,LOTNUMBER VARCHAR2(30),' ||
' LINK_LOTNUMBER VARCHAR2(30),INVENTORYCLASS VARCHAR2(4),' ||
' STATUSCODE VARCHAR2(2),REFERENCE VARCHAR2(20),LINENUMBER VARCHAR2(255),' ||
' ORDERDATE DATE,PO VARCHAR2(20),QTYORDERED NUMBER(7),QTYSHIPPED NUMBER(7),' ||
' QTYDIFF NUMBER,UOM VARCHAR2(4),PACKLISTSHIPDATE DATE,WEIGHT NUMBER(17,8),' ||
' WEIGHTQUAIFIER CHAR(1),WEIGHTUNIT CHAR(1),DESCRIPTION VARCHAR2(255),' ||
' UPC VARCHAR2(20),DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR21 VARCHAR2(255),DTLPASSTHRUCHAR22 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR23 VARCHAR2(255),DTLPASSTHRUCHAR24 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR25 VARCHAR2(255),DTLPASSTHRUCHAR26 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR27 VARCHAR2(255),DTLPASSTHRUCHAR28 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR29 VARCHAR2(255),DTLPASSTHRUCHAR30 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR31 VARCHAR2(255),DTLPASSTHRUCHAR32 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR33 VARCHAR2(255),DTLPASSTHRUCHAR34 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR35 VARCHAR2(255),DTLPASSTHRUCHAR36 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR37 VARCHAR2(255),DTLPASSTHRUCHAR38 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR39 VARCHAR2(255),DTLPASSTHRUCHAR40 VARCHAR2(255),' ||
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),DTLPASSTHRUNUM03 NUMBER(16,4),' ||
' DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),DTLPASSTHRUNUM09 NUMBER(16,4),' ||
' DTLPASSTHRUNUM10 NUMBER(16,4),' ||
' DTLPASSTHRUNUM11 NUMBER(16,4),DTLPASSTHRUNUM12 NUMBER(16,4),DTLPASSTHRUNUM13 NUMBER(16,4),' ||
' DTLPASSTHRUNUM14 NUMBER(16,4),DTLPASSTHRUNUM15 NUMBER(16,4),DTLPASSTHRUNUM16 NUMBER(16,4),' ||
' DTLPASSTHRUNUM17 NUMBER(16,4),DTLPASSTHRUNUM18 NUMBER(16,4),DTLPASSTHRUNUM19 NUMBER(16,4),' ||
' DTLPASSTHRUNUM20 NUMBER(16,4),DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,DTLPASSTHRUDOLL01 NUMBER(10,2),' ||
' DTLPASSTHRUDOLL02 NUMBER(10,2), FROMLPID varchar2(15), smallpackagelbs number,'||
' deliveryservice varchar2(10), entereduom varchar2(4), qtyshippedEUOM number, '||
' hazardous char(1), productgroup varchar2(4), LINK_ASSIGNEDID NUMBER(16,4), '||
' CANCELREASON VARCHAR2(12), SHIPSHORTREASON VARCHAR2(12),  CONSIGNEESKU VARCHAR2(20), '||
' GTIN VARCHAR(14))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 lot');
cmdSql := 'create table SHIP_NOTE_945_lot_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4),item varchar2(50) not null,LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),' ||
' QTYSHIPPED NUMBER(7), QTYORDERED NUMBER(7), QTYDIFF NUMBER(7), WEIGHTSHIPPED NUMBER(17,8),LINK_ASSIGNEDID NUMBER(16,4))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 lxd');
cmdSql := 'create table SHIP_NOTE_945_LXD_' || strSuffix ||
        ' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 man');
cmdSql := 'create table SHIP_NOTE_945_MAN_' || strSuffix ||
' (ORDERID NUMBER(9),SHIPID NUMBER(2),CUSTID VARCHAR2(10),'||
' ASSIGNEDID NUMBER(16,4),item varchar2(50),' ||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),'||
' SERIALNUMBER VARCHAR2(30), DTLPASSTHRUCHAR01 VARCHAR2(255), ' ||
' FROMLPID VARCHAR2(15), LPID VARCHAR2(50), TRACKINGNO VARCHAR2(20), '||
' SHIPPINGCOST NUMBER(10,2), WEIGHT NUMBER(13,4), QUANTITY NUMBER(7) '||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 s18');
cmdSql := 'create table SHIP_NOTE_945_S18_' || strSuffix ||
' (ORDERID NUMBER,SHIPID NUMBER,CUSTID VARCHAR2(10),item varchar2(50),' ||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),SSCC18 VARCHAR2(20)' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
   if in_orderid != 0 then
     debugmsg('by pick order ' || in_orderid || '-' || in_shipid);
     for oh in curPickOrderHdr
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_dtl_rows(oh);
     end loop;
   elsif in_loadno != 0 then
     debugmsg('by pick loadno ' || in_loadno);
     for oh in curPickOrderHdrByLoad
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_dtl_rows(oh);
     end loop;
   elsif rtrim(in_begdatestr) is not null then
     debugmsg('by pick date ' || in_begdatestr || '-' || in_enddatestr);
     begin
       dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -1;
       out_msg := 'Invalid begin date string ' || in_begdatestr;
       return;
     end;
     begin
       dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -2;
       out_msg := 'Invalid end date string ' || in_enddatestr;
       return;
     end;
     for oh in curPickOrderHdrByShipDate
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_dtl_rows(oh);
     end loop;
   end if;

else
if in_orderid != 0 then
  debugmsg('by order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('by loadno ' || in_loadno);
  for oh in curOrderHdrByLoad
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('by date ' || in_begdatestr || '-' || in_enddatestr);
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
end if;
end if;

end;


----------------------------------------------------------------------
-- Extract by ID and contents
----------------------------------------------------------------------


procedure add_945_cnt_rows(oh curorderhdr%rowtype) is


cursor C_SP_old(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH'
     and parentlpid is null;

cursor C_SP(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status = 'SH'
     and (parentlpid is null or type in ('C'))
     and lpid in
    (select nvl(parentlpid,lpid)
       from shippingplate
       start with orderid = in_orderid and shipid = in_shipid
                  and type in ('F','P')
       connect by prior parentlpid = lpid);

cursor C_SPI(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status = 'SH'
     and (parentlpid is null or type in ('C'))
     and lpid in
    (select nvl(parentlpid,lpid)
       from shippingplate
       start with orderid = in_orderid and shipid = in_shipid
                  and type in ('F','P')
       connect by prior parentlpid = lpid)
    order by item, quantity;
csp C_SP%rowtype;

cursor C_SPS(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status in ('S', 'L', 'SH')
     and (parentlpid is null or type in ('C'))
     and lpid in
    (select nvl(parentlpid,lpid)
       from shippingplate
       start with orderid = in_orderid and shipid = in_shipid
                  and type in ('F','P')
       connect by prior parentlpid = lpid);

cursor C_LBL(in_orderid number, in_shipid number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and substr(barcode,1,3) = decode(in_labeltype,'P','001','000')
     and lpid = in_lpid
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'));

cursor C_LBLC(in_orderid number, in_shipid number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and substr(barcode,1,3) = decode(in_labeltype,'P','001','000')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBLCS(in_orderid number, in_shipid number,
    in_lpid varchar2, in_item varchar2, in_lot varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and labeltype in ('CS', 'IP')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and nvl(lotnumber,'(none)') = nvl(in_lot,nvl(lotnumber,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBLCS_NOLOT(in_orderid number, in_shipid number,
    in_lpid varchar2, in_item varchar2, in_lot varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and labeltype in ('CS', 'IP')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBL_CONS(in_orderid number, in_shipid number, in_wave number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where ((orderid = in_orderid and shipid = in_shipid) or
          (orderid = in_wave and shipid = 0))
     and ((length(barcode) > 14 and
            barcode like decode(in_labeltype,'P','001%','000%'))
        or
          (length(barcode) = 14 and
            barcode like decode(in_labeltype,'P','1%','0%')))
     and lpid = in_lpid
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'));

cursor C_LBLC_CONS(in_orderid number, in_shipid number, in_wave number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where ((orderid = in_orderid and shipid = in_shipid) or
          (orderid = in_wave and shipid = 0))
     and barcode like decode(in_labeltype,'P','001%','000%')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where (orderid = in_orderid and shipid = in_shipid) or
            (orderid = in_wave and shipid = 0)
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBLCS_CONS(in_orderid number, in_shipid number, in_wave number,
    in_lpid varchar2, in_item varchar2, in_lot varchar2)
is
  select *
    from caselabels
   where ((orderid = in_orderid and shipid = in_shipid) or
          (orderid = in_wave and shipid = 0))
     and labeltype in ('CS', 'IP')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and nvl(lotnumber,'(none)') = nvl(in_lot,nvl(lotnumber,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where (orderid = in_orderid and shipid = in_shipid) or
            (orderid = in_wave and shipid = 0)
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);


do_cases boolean;
do_cases_consolidated boolean;


LBL caselabels%rowtype;
LBLCS caselabels%rowtype;

SP shippingplate%rowtype;

cursor C_std_detail(in_orderid number, in_shipid number, in_lpid varchar2)
is
    select S.item, S.lotnumber, S.orderitem, S.orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    min(S.useritem1) useritem1,
                    min(S.useritem2) useritem2,
                    min(S.useritem3) useritem3,
                    min(S.serialnumber) serialnumber,
                    S.unitofmeasure, null as fromlpid, sum(S.quantity) quantity
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
                    and lpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    and parentlpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    start with S.parentlpid = in_lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                    S.unitofmeasure,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null);

cursor C_std_nolot_detail(in_orderid number, in_shipid number, in_lpid varchar2)
is
    select S.item, null as lotnumber, S.orderitem, null as orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    min(S.useritem1) useritem1,
                    min(S.useritem2) useritem2,
                    min(S.useritem3) useritem3,
                    min(S.serialnumber) serialnumber,
                    S.unitofmeasure, null as fromlpid, sum(S.quantity) quantity
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
          and lpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    and parentlpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    start with S.parentlpid = in_lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.orderitem,
                    S.unitofmeasure,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null);

cursor C_useritem_detail(in_orderid number, in_shipid number, in_lpid varchar2)
is
    select S.item, S.lotnumber, S.orderitem, S.orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    useritem1,
                    useritem2,
                    useritem3,
                    serialnumber,
                    S.unitofmeasure, null as fromlpid, sum(S.quantity) quantity
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
                    and lpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    and parentlpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    start with S.parentlpid = in_lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                    S.unitofmeasure,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null),
                    useritem1, useritem2, useritem3, serialnumber;
cursor C_std_detail_lpid(in_orderid number, in_shipid number, in_lpid varchar2)
is
    select S.item, S.lotnumber, S.orderitem, S.orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    min(S.useritem1) useritem1,
                    min(S.useritem2) useritem2,
                    min(S.useritem3) useritem3,
                    min(S.serialnumber) serialnumber,
                    S.unitofmeasure, S.fromlpid, sum(S.quantity) quantity
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
                    and lpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    and parentlpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    start with S.parentlpid = in_lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                    S.unitofmeasure, S.fromlpid,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null);
cursor C_useritem_detail_lpid(in_orderid number, in_shipid number, in_lpid varchar2)
is
    select S.item, S.lotnumber, S.orderitem, S.orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    useritem1,
                    useritem2,
                    useritem3,
                    serialnumber,
                    S.unitofmeasure, S.fromlpid, sum(S.quantity) quantity
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
                    and lpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    and parentlpid not in (select lpid from shippingplate where parentlpid = in_lpid and type = 'C')
                    start with S.parentlpid = in_lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                    S.unitofmeasure, S.fromlpid,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null),
                    useritem1, useritem2, useritem3, serialnumber;
cdtl C_std_detail%rowtype;

cursor C_OD(in_orderid number, in_shipid number, in_item varchar2,
    in_lotnumber varchar2)
IS
select *
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

OD orderdtl%rowtype;

cursor curManufactureDate(in_lpid varchar2, in_item varchar2, in_lotnumber varchar2)
IS
  select manufacturedate
    from plate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where parentlpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and type in ('F','P'))
UNION
  select manufacturedate
   from plate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where lpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and parentlpid is null
        and type in ('F'))
UNION
  select manufacturedate
    from deletedplate
    where lpid in
     ( select fromlpid
       from shippingplate
      where parentlpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and type in ('F','P'))
UNION
   select manufacturedate
    from deletedplate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where lpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and parentlpid is null
        and type in ('F'));

cursor curExpirationDate(in_lpid varchar2, in_item varchar2, in_lotnumber varchar2)
IS
  select expirationdate
    from plate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where parentlpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and type in ('F','P'))
UNION
  select expirationdate
   from plate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where lpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and parentlpid is null
        and type in ('F'))
UNION
  select expirationdate
    from deletedplate
    where lpid in
     ( select fromlpid
       from shippingplate
      where parentlpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and type in ('F','P'))
UNION
   select expirationdate
    from deletedplate
    where lpid in
     ( select fromlpid as lpid
       from shippingplate
      where lpid = in_lpid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
        and parentlpid is null
        and type in ('F'));

cursor C_ODLC(in_orderid number, in_shipid number, in_item varchar2,
    in_lotnumber varchar2, in_assignedid number)
IS
select
    D.custid,
    D.item,
    D.lotnumber,
    D.uom,
    D.itementered,
    nvl(L.dtlpassthruchar01,D.dtlpassthruchar01) dtlpassthruchar01,
    nvl(L.dtlpassthruchar02,D.dtlpassthruchar02) dtlpassthruchar02,
    nvl(L.dtlpassthruchar03,D.dtlpassthruchar03) dtlpassthruchar03,
    nvl(L.dtlpassthruchar04,D.dtlpassthruchar04) dtlpassthruchar04,
    nvl(L.dtlpassthruchar05,D.dtlpassthruchar05) dtlpassthruchar05,
    nvl(L.dtlpassthruchar06,D.dtlpassthruchar06) dtlpassthruchar06,
    nvl(L.dtlpassthruchar07,D.dtlpassthruchar07) dtlpassthruchar07,
    nvl(L.dtlpassthruchar08,D.dtlpassthruchar08) dtlpassthruchar08,
    nvl(L.dtlpassthruchar09,D.dtlpassthruchar09) dtlpassthruchar09,
    nvl(L.dtlpassthruchar10,D.dtlpassthruchar10) dtlpassthruchar10,
    nvl(L.dtlpassthruchar11,D.dtlpassthruchar11) dtlpassthruchar11,
    nvl(L.dtlpassthruchar12,D.dtlpassthruchar12) dtlpassthruchar12,
    nvl(L.dtlpassthruchar13,D.dtlpassthruchar13) dtlpassthruchar13,
    nvl(L.dtlpassthruchar14,D.dtlpassthruchar14) dtlpassthruchar14,
    nvl(L.dtlpassthruchar15,D.dtlpassthruchar15) dtlpassthruchar15,
    nvl(L.dtlpassthruchar16,D.dtlpassthruchar16) dtlpassthruchar16,
    nvl(L.dtlpassthruchar17,D.dtlpassthruchar17) dtlpassthruchar17,
    nvl(L.dtlpassthruchar18,D.dtlpassthruchar18) dtlpassthruchar18,
    nvl(L.dtlpassthruchar19,D.dtlpassthruchar19) dtlpassthruchar19,
    nvl(L.dtlpassthruchar20,D.dtlpassthruchar20) dtlpassthruchar20,
    nvl(L.dtlpassthruchar21,D.dtlpassthruchar21) dtlpassthruchar21,
    nvl(L.dtlpassthruchar22,D.dtlpassthruchar22) dtlpassthruchar22,
    nvl(L.dtlpassthruchar23,D.dtlpassthruchar23) dtlpassthruchar23,
    nvl(L.dtlpassthruchar24,D.dtlpassthruchar24) dtlpassthruchar24,
    nvl(L.dtlpassthruchar25,D.dtlpassthruchar25) dtlpassthruchar25,
    nvl(L.dtlpassthruchar26,D.dtlpassthruchar26) dtlpassthruchar26,
    nvl(L.dtlpassthruchar27,D.dtlpassthruchar27) dtlpassthruchar27,
    nvl(L.dtlpassthruchar28,D.dtlpassthruchar28) dtlpassthruchar28,
    nvl(L.dtlpassthruchar29,D.dtlpassthruchar29) dtlpassthruchar29,
    nvl(L.dtlpassthruchar30,D.dtlpassthruchar30) dtlpassthruchar30,
    nvl(L.dtlpassthruchar31,D.dtlpassthruchar31) dtlpassthruchar31,
    nvl(L.dtlpassthruchar32,D.dtlpassthruchar32) dtlpassthruchar32,
    nvl(L.dtlpassthruchar33,D.dtlpassthruchar33) dtlpassthruchar33,
    nvl(L.dtlpassthruchar34,D.dtlpassthruchar34) dtlpassthruchar34,
    nvl(L.dtlpassthruchar35,D.dtlpassthruchar35) dtlpassthruchar35,
    nvl(L.dtlpassthruchar36,D.dtlpassthruchar36) dtlpassthruchar36,
    nvl(L.dtlpassthruchar37,D.dtlpassthruchar37) dtlpassthruchar37,
    nvl(L.dtlpassthruchar38,D.dtlpassthruchar38) dtlpassthruchar38,
    nvl(L.dtlpassthruchar39,D.dtlpassthruchar39) dtlpassthruchar39,
    nvl(L.dtlpassthruchar40,D.dtlpassthruchar40) dtlpassthruchar40,
    nvl(L.dtlpassthrunum01,D.dtlpassthrunum01) dtlpassthrunum01,
    nvl(L.dtlpassthrunum02,D.dtlpassthrunum02) dtlpassthrunum02,
    nvl(L.dtlpassthrunum03,D.dtlpassthrunum03) dtlpassthrunum03,
    nvl(L.dtlpassthrunum04,D.dtlpassthrunum04) dtlpassthrunum04,
    nvl(L.dtlpassthrunum05,D.dtlpassthrunum05) dtlpassthrunum05,
    nvl(L.dtlpassthrunum06,D.dtlpassthrunum06) dtlpassthrunum06,
    nvl(L.dtlpassthrunum07,D.dtlpassthrunum07) dtlpassthrunum07,
    nvl(L.dtlpassthrunum08,D.dtlpassthrunum08) dtlpassthrunum08,
    nvl(L.dtlpassthrunum09,D.dtlpassthrunum09) dtlpassthrunum09,
    nvl(L.dtlpassthrunum10,D.dtlpassthrunum10) dtlpassthrunum10,
    nvl(L.dtlpassthrunum11,D.dtlpassthrunum11) dtlpassthrunum11,
    nvl(L.dtlpassthrunum12,D.dtlpassthrunum12) dtlpassthrunum12,
    nvl(L.dtlpassthrunum13,D.dtlpassthrunum13) dtlpassthrunum13,
    nvl(L.dtlpassthrunum14,D.dtlpassthrunum14) dtlpassthrunum14,
    nvl(L.dtlpassthrunum15,D.dtlpassthrunum15) dtlpassthrunum15,
    nvl(L.dtlpassthrunum16,D.dtlpassthrunum16) dtlpassthrunum16,
    nvl(L.dtlpassthrunum17,D.dtlpassthrunum17) dtlpassthrunum17,
    nvl(L.dtlpassthrunum18,D.dtlpassthrunum18) dtlpassthrunum18,
    nvl(L.dtlpassthrunum19,D.dtlpassthrunum19) dtlpassthrunum19,
    nvl(L.dtlpassthrunum20,D.dtlpassthrunum20) dtlpassthrunum20,
    nvl(L.dtlpassthrudate01,D.dtlpassthrudate01) dtlpassthrudate01,
    nvl(L.dtlpassthrudate02,D.dtlpassthrudate02) dtlpassthrudate02,
    nvl(L.dtlpassthrudate03,D.dtlpassthrudate03) dtlpassthrudate03,
    nvl(L.dtlpassthrudate04,D.dtlpassthrudate04) dtlpassthrudate04,
    nvl(L.dtlpassthrudoll01,D.dtlpassthrudoll01) dtlpassthrudoll01,
    nvl(L.dtlpassthrudoll02,D.dtlpassthrudoll02) dtlpassthrudoll02,
    D.childorderid,D.childshipid, D.qtyship,D.linestatus,D.cancelreason,
    D.weightship, D.cubeship, D.qtyorder
  from orderdtl D, orderdtlline L
 where D.orderid = in_orderid
   and D.shipid = in_shipid
   and D.item = in_item
   and nvl(D.lotnumber, '(none)') = nvl(in_lotnumber,'(none)')
   and D.orderid = L.orderid(+)
   and D.shipid = L.shipid(+)
   and D.item = L.item(+)
   and nvl(D.lotnumber,'(none)') = nvl(L.lotnumber(+),'(none)')
   and nvl(in_assignedid,-1) = nvl(L.dtlpassthrunum10(+),-1);

ODLC C_ODLC%rowtype;

cursor C_ODLZ(in_orderid number, in_shipid number, in_item varchar2,
    in_lotnumber varchar2)
IS
select
    D.custid,
    D.item,
    D.lotnumber,
    D.uom,
    D.itementered,
    nvl(L.dtlpassthruchar09,D.dtlpassthruchar09) dtlpassthruchar09,
    nvl(L.dtlpassthrunum10,D.dtlpassthrunum10) dtlpassthrunum10
  from orderdtl D, orderdtlline L
 where D.orderid = in_orderid
   and D.shipid = in_shipid
   and D.item = in_item
   and nvl(D.lotnumber, '(none)') = nvl(in_lotnumber,'(none)')
   and D.orderid = L.orderid(+)
   and D.shipid = L.shipid(+)
   and D.item = L.item(+)
   and nvl(D.lotnumber,'(none)') = nvl(L.lotnumber(+),'(none)');
ODLZ C_ODLZ%rowtype;

CNT ship_note_945_cnt%rowtype;



type odl_rcd is record (
  item         orderdtlline.item%type,
  lotnumber    orderdtlline.lotnumber%type,
  linenumber   orderdtlline.linenumber%type,
  qty          orderdtl.qtyorder%type,
  savelot      orderdtlline.lotnumber%type
);

type odl_tbl is table of odl_rcd
     index by binary_integer;

odl odl_tbl;
odlx integer;
odlfound boolean;



cursor C_ODL(in_orderid number, in_shipid number)
IS
select
      od.ITEM as item,
      od.LOTNUMBER as lotnumber,
      nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
      nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
 from orderdtlline ol, orderdtl od
where od.orderid = in_orderid
  and od.shipid = in_shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
order by 1,2,3;
cursor C_ODLI(in_orderid number, in_shipid number)
IS
select
      od.ITEM as item,
      od.LOTNUMBER as lotnumber,
      nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
      nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
 from orderdtlline ol, orderdtl od
where od.orderid = in_orderid
  and od.shipid = in_shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
order by 1,2,4;
l_seq integer;
l_max integer;


cursor C_CL(in_orderid number, in_shipid number)
IS
select labeltype
   from caselabels
   where orderid = oh.orderid
     and shipid = oh.shipid;
lLabelType caselabels.labeltype%type;


procedure write_contents(ODLC C_ODLC%rowtype)
is
nShippingCost number;
nShippingWeight number;
strShipType orderhdr.shiptype%type;
nHeight shippingplate.height%type;
nLength shippingplate.length%type;
nWidth shippingplate.width%type;
vRmaTrackingNo shippingplate.rmatrackingno%type;
cursor C_CI(in_custid varchar2, in_item varchar2)
IS
select descr, itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04,
       itmpassthruchar05, itmpassthruchar06, itmpassthruchar07, itmpassthruchar08,
       itmpassthruchar09, itmpassthruchar10, itmpassthrunum01, itmpassthrunum02,
       itmpassthrunum03, itmpassthrunum04, itmpassthrunum05, itmpassthrunum06,
       itmpassthrunum07, itmpassthrunum08, itmpassthrunum09, itmpassthrunum10,
       length, width, height, labeluom, baseuom
   from custitem
   where custid = in_custid
     and item = in_item;
CI C_CI%rowtype;
cursor C_CIU(in_custid varchar2, in_item varchar2, in_uom varchar2, in_labeluom varchar2)
IS
select length, width, height, qty
   from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_uom
     and touom = in_labeluom;
CIU C_CIU%rowtype;
cursor C_CT(in_fromlpid varchar2)
is
select cartontype
  from shippingplate sp
 where sp.fromlpid = in_fromlpid;
cursor C_MD(in_fromlpid varchar2)
is
select length, width, height
  from multishipdtl
 where cartonid = in_fromlpid;
inpk shippingplate.quantity%type;
begin
CI := null;
open C_CI(CNT.custid, CNT.item);
fetch C_CI into CI;
close C_CI;
select shiptype into strShipType
   from orderhdr
   where orderid = CNT.orderid
     and shipid = CNT.shipid;

if strShipType <> 'S' then
   nShippingCost := null;
   nShippingWeight := null;
else
  begin
     if nvl(in_cost_by_trackingno_yn, 'N') = 'Y' then
        nShippingcost := zim7.cost_by_trackingno(CNT.orderid,CNT.shipid, CNT.trackingno);
        select weight into nShippingWeight
           from shippingplate
           where lpid = CNT.lpid;
     else
   select shippingcost, weight, length, width, height, rmatrackingno
      into nShippingCost, nShippingWeight, nLength, nWidth, nHeight, vRmaTrackingNo
      from shippingplate
      where lpid = CNT.lpid;
     end if;
  exception when no_data_found then
   nShippingCost := null;
   nShippingWeight := null;
  end;
end if;
l_seq := 0;
if nvl(in_force_cnt_fromlpid_yn, 'N') = 'Y' then
   if nvl(OD.dtlpassthrunum10,0) != 0 then
      l_seq := OD.dtlpassthrunum10;
   else
      l_max := null;
      debugmsg('start max');
      select max(nvl(dtlpassthrunum10,0)) into l_max
        from orderdtl
        where orderid = OD.orderid
          and shipid = OD.shipid
          and item < OD.item;
      if l_max is null then
         l_max := 0;
      end if;
      debugmsg('max 10 ' || l_max);
      select count(1) into l_seq
        from orderdtl
        where orderid = OD.orderid
          and shipid = OD.shipid
          and item < OD.item
          and nvl(dtlpassthrunum10,0) = 0;
      debugmsg('max count' || l_seq);
l_seq := l_max + l_seq + 1;
      debugmsg('seq ' || l_seq);
   end if;
end if;

begin
   select hazardous, descr into CNT.hazardous, CNT.itemdescr
   from custitem
   where custid = OD.custid
     and item = OD.item;
exception when no_data_found then
   CNT.hazardous := null;
   CNT.itemdescr := null;
end;

open curManufactureDate(CNT.lpid, CNT.item, CNT.lotnumber);
fetch curManufactureDate into CNT.manufacturedate;
close curManufactureDate;

open curExpirationDate(CNT.lpid, CNT.item, CNT.lotnumber);
fetch curExpirationDate into CNT.expirationdate;
close curExpirationDate;

if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
   CNT.lotnumber := null;
   CNT.link_lotnumber := '(none)';
end if;
inpk := zlbl.uom_qty_conv(CNT.custid, CNT.item, 1, 'INPK', CNT.uom);
if inpk = 0 then
   inpk := 1;
end if;
CNT.innerpackqty := CNT.qty / inpk;
CNT.ea_to_cs := zlbl.uom_qty_conv(CNT.custid, CNT.item, 1, 'CA', 'EA');
if CNT.qty = 0 then
    CNT.shipmentstatuscode := 'CU';
else
    if CNT.odqtyorder <= CNT.qty then
        CNT.shipmentstatuscode := 'CC';
    else
        CNT.shipmentstatuscode := 'PR';
    end if;
end if;
open C_CT(CNT.fromlpid);
fetch C_CT into CNT.cartontype;
close C_CT;
open C_MD(CNT.fromlpid);
fetch C_MD into CNT.cslength, CNT.cswidth, CNT.csheight;
if  C_MD%notfound then
   close C_MD;
   CIU := null;
   if nvl(in_lwh_in_ea_yn,'N') = 'Y' then
      open C_CIU(CNT.custid, CNT.item, 'EA', CI.labeluom);
   else
      open C_CIU(CNT.custid, CNT.item, CI.baseuom, CI.labeluom);
   end if;
   fetch C_CIU into CIU;
   close C_CIU;
   if CIU.length is not null then
      CNT.cslength := CIU.length;
      CNT.cswidth := CIU.width;
      CNT.csheight := CIU.height;
   else
      if CI.width >= CI.length and CI.height >= CI.length then
         CNT.cslength := CI.length * NVL(CIU.qty,1);
      else
         CNT.cslength := CI.length;
      end if;
      if CI.length > CI.width and CI.height >= CI.width then
         CNT.cswidth := CI.width * NVL(CIU.qty,1);
      else
         CNT.cswidth := CI.width;
      end if;
      if  CI.width > CI.height and CI.length > ci.height then
         CNT.csheight := CI.height * NVL(CIU.qty,1);
      else
         CNT.csheight := CI.height;
      end if;
   end if;
else
   close C_MD;
end if;

debugmsg('CNT writing contents for LP:'||CNT.lpid);
if nvl(in_include_zero_qty_shipped_yn,'N') = 'Y'
    and CNT.qty = 0 then

    if ODLC.dtlpassthruchar09 is not null then
       l_zero_shipped_cartonid945 := ODLC.dtlpassthruchar09;
    else
       begin
         select cartonid945seq.nextval into l_zero_shipped_cartonid945 from dual;
       exception when others then
         l_zero_shipped_cartonid945 := '999999999999999';
       end;
    end if;

    execute immediate 'insert into SHIP_NOTE_945_CNT_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
    ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
    ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
    ' :ASSIGNEDID, :ITEM,:LOTNUMBER,:LINK_LOTNUMBER,'||
    ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
    ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
    ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
    ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
    ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
    ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
    ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
    ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
    ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
    ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
    ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
    ' :DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,' ||
    ' :DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
    ' :DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,' ||
    ' :DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
    ' :DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,' ||
    ' :DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
    ' :DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,' ||
    ' :DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
    ' :DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,' ||
    ' :DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
    ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
    ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
    ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
    ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
    ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
    ' :DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
    ' :DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,' ||
    ' :DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
    ' :DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,' ||
    ' :DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
    ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
    ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
    ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
    ' :PO, :WEIGHT, :VOLUME, :DESCR, :ODQTYORDER, :ODQTYSHIP, :LINESEQ, :HAZARDOUS, ' ||
    ' :FROMLPIDLAST6, :FROMLPIDLAST7, :ITEMDESCR, '||
    ':MANUFACTUREDATE, :SHIPPINGCOST, :SHIPPINGWEIGHT, '||
    ':SERIALNUMBER, :LABELTYPE, :ITMPASSTHRUCHAR01, :EXPIRATIONDATE, '||
    ':ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, :ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, '||
    ':ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, :ITMPASSTHRUCHAR09, '||
    ':ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
    ':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, ' ||
    ':ITMPASSTHRUNUM08, :ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :INNERPACKQTY, ' ||
    ':EA_TO_CS, :SHIPMENTSTATUSCODE, :QTYDIFFERENCE, :CARTONTYPE, ' ||
    ':CSLENGTH, :CSWIDTH, :CSHEIGHT, ' ||
    ':LENGTH, :WIDTH, :HEIGHT, :RMATRACKINGNO) '
    using
        CNT.orderid,
        CNT.shipid,
        CNT.custid,
        l_zero_shipped_cartonid945,
        l_zero_shipped_cartonid945,
        CNT.plt_sscc18,
        CNT.ctn_sscc18,
        CNT.trackingno,
        CNT.link_plt_sscc18,
        CNT.link_ctn_sscc18,
        CNT.link_trackingno,
        CNT.assignedid,
        CNT.item,
        CNT.lotnumber,
        CNT.link_lotnumber,
        CNT.useritem1,
        CNT.useritem2,
        CNT.useritem3,
        CNT.qty,
        CNT.uom,
        CNT.cartons,
        ODLC.dtlpassthruchar01,
        ODLC.dtlpassthruchar02,
        ODLC.dtlpassthruchar03,
        ODLC.dtlpassthruchar04,
        ODLC.dtlpassthruchar05,
        ODLC.dtlpassthruchar06,
        ODLC.dtlpassthruchar07,
        ODLC.dtlpassthruchar08,
        ODLC.dtlpassthruchar09,
        ODLC.dtlpassthruchar10,
        ODLC.dtlpassthruchar11,
        ODLC.dtlpassthruchar12,
        ODLC.dtlpassthruchar13,
        ODLC.dtlpassthruchar14,
        ODLC.dtlpassthruchar15,
        ODLC.dtlpassthruchar16,
        ODLC.dtlpassthruchar17,
        ODLC.dtlpassthruchar18,
        ODLC.dtlpassthruchar19,
        ODLC.dtlpassthruchar20,
        ODLC.dtlpassthruchar21,
        ODLC.dtlpassthruchar22,
        ODLC.dtlpassthruchar23,
        ODLC.dtlpassthruchar24,
        ODLC.dtlpassthruchar25,
        ODLC.dtlpassthruchar26,
        ODLC.dtlpassthruchar27,
        ODLC.dtlpassthruchar28,
        ODLC.dtlpassthruchar29,
        ODLC.dtlpassthruchar30,
        ODLC.dtlpassthruchar31,
        ODLC.dtlpassthruchar32,
        ODLC.dtlpassthruchar33,
        ODLC.dtlpassthruchar34,
        ODLC.dtlpassthruchar35,
        ODLC.dtlpassthruchar36,
        ODLC.dtlpassthruchar37,
        ODLC.dtlpassthruchar38,
        ODLC.dtlpassthruchar39,
        ODLC.dtlpassthruchar40,
        ODLC.dtlpassthrunum01,
        ODLC.dtlpassthrunum02,
        ODLC.dtlpassthrunum03,
        ODLC.dtlpassthrunum04,
        ODLC.dtlpassthrunum05,
        ODLC.dtlpassthrunum06,
        ODLC.dtlpassthrunum07,
        ODLC.dtlpassthrunum08,
        ODLC.dtlpassthrunum09,
        ODLC.dtlpassthrunum10,
        ODLC.dtlpassthrunum11,
        ODLC.dtlpassthrunum12,
        ODLC.dtlpassthrunum13,
        ODLC.dtlpassthrunum14,
        ODLC.dtlpassthrunum15,
        ODLC.dtlpassthrunum16,
        ODLC.dtlpassthrunum17,
        ODLC.dtlpassthrunum18,
        ODLC.dtlpassthrunum19,
        ODLC.dtlpassthrunum20,
        ODLC.dtlpassthrudate01,
        ODLC.dtlpassthrudate02,
        ODLC.dtlpassthrudate03,
        ODLC.dtlpassthrudate04,
        ODLC.dtlpassthrudoll01,
        ODLC.dtlpassthrudoll02,
        CNT.po,
        0, --ODLC.weightship * CNT.qty / ODLC.qtyship,
        0, --ODLC.cubeship * CNT.qty / ODLC.qtyship,
        CI.descr,
        ODLC.qtyorder,
        ODLC.qtyship,
        l_seq,
        CNT.hazardous,
        zim7.lpid_last6(CNT.FROMLPID),
        zim7.lpid_last7(CNT.FROMLPID),
        CNT.itemdescr,
        CNT.manufacturedate,
        nShippingCost,
        nShippingWeight,
        CNT.serialnumber,
        CNT.labeltype,
        CI.itmpassthruchar01,
        CNT.expirationdate,
        CI.itmpassthruchar02,
        CI.itmpassthruchar03,
        CI.itmpassthruchar04,
        CI.itmpassthruchar05,
        CI.itmpassthruchar06,
        CI.itmpassthruchar07,
        CI.itmpassthruchar08,
        CI.itmpassthruchar09,
        CI.itmpassthruchar10,
        CI.itmpassthrunum01,
        CI.itmpassthrunum02,
        CI.itmpassthrunum03,
        CI.itmpassthrunum04,
        CI.itmpassthrunum05,
        CI.itmpassthrunum06,
        CI.itmpassthrunum07,
        CI.itmpassthrunum08,
        CI.itmpassthrunum09,
        CI.itmpassthrunum10,
        CNT.innerpackqty,
        CNT.ea_to_cs,
        CNT.shipmentstatuscode,
        CNT.qtydifference,
        CNT.cartontype,
        CNT.cslength,
        CNT.cswidth,
        CNT.csheight,
        nLength,
        nWidth,
        nHeight,
        vRmaTrackingNo;



else
    execute immediate 'insert into SHIP_NOTE_945_CNT_' || strSuffix ||
    ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
    ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
    ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
    ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
    ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
    ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
    ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
    ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
    ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
    ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
    ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
    ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
    ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
    ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
    ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
    ' :DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,' ||
    ' :DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
    ' :DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,' ||
    ' :DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
    ' :DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,' ||
    ' :DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
    ' :DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,' ||
    ' :DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
    ' :DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,' ||
    ' :DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
    ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
    ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
    ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
    ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
    ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
    ' :DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
    ' :DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,' ||
    ' :DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
    ' :DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,' ||
    ' :DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
    ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
    ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
    ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
    ' :PO, :WEIGHT, :VOLUME, :DESCR, :ODQTYORDER, :ODQTYSHIP, :LINESEQ, :HAZARDOUS, ' ||
    ' :FROMLPIDLAST6, :FROMLPIDLAST7, :ITEMDESCR, '||
    ':MANUFACTUREDATE, :SHIPPINGCOST, :SHIPPINGWEIGHT, '||
    ':SERIALNUMBER, :LABELTYPE, :ITMPASSTHRUCHAR01, :EXPIRATIONDATE, ' ||
    ':ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, :ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, '||
    ':ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, :ITMPASSTHRUCHAR09, '||
    ':ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
    ':ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, ' ||
    ':ITMPASSTHRUNUM08, :ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :INNERPACKQTY, ' ||
    ':EA_TO_CS, :SHIPMENTSTATUSCODE, :QTYDIFFERENCE, :CARTONTYPE, ' ||
    ':CSLENGTH, :CSWIDTH, :CSHEIGHT, ' ||
    ':LENGTH, :WIDTH, :HEIGHT, :RMATRACKINGNO) '

    using
        CNT.orderid,
        CNT.shipid,
        CNT.custid,
        CNT.lpid,
        CNT.fromlpid,
        CNT.plt_sscc18,
        CNT.ctn_sscc18,
        CNT.trackingno,
        CNT.link_plt_sscc18,
        CNT.link_ctn_sscc18,
        CNT.link_trackingno,
        CNT.assignedid,
        CNT.item,
        CNT.lotnumber,
        CNT.link_lotnumber,
        CNT.useritem1,
        CNT.useritem2,
        CNT.useritem3,
        CNT.qty,
        CNT.uom,
        CNT.cartons,
        ODLC.dtlpassthruchar01,
        ODLC.dtlpassthruchar02,
        ODLC.dtlpassthruchar03,
        ODLC.dtlpassthruchar04,
        ODLC.dtlpassthruchar05,
        ODLC.dtlpassthruchar06,
        ODLC.dtlpassthruchar07,
        ODLC.dtlpassthruchar08,
        ODLC.dtlpassthruchar09,
        ODLC.dtlpassthruchar10,
        ODLC.dtlpassthruchar11,
        ODLC.dtlpassthruchar12,
        ODLC.dtlpassthruchar13,
        ODLC.dtlpassthruchar14,
        ODLC.dtlpassthruchar15,
        ODLC.dtlpassthruchar16,
        ODLC.dtlpassthruchar17,
        ODLC.dtlpassthruchar18,
        ODLC.dtlpassthruchar19,
        ODLC.dtlpassthruchar20,
        ODLC.dtlpassthruchar21,
        ODLC.dtlpassthruchar22,
        ODLC.dtlpassthruchar23,
        ODLC.dtlpassthruchar24,
        ODLC.dtlpassthruchar25,
        ODLC.dtlpassthruchar26,
        ODLC.dtlpassthruchar27,
        ODLC.dtlpassthruchar28,
        ODLC.dtlpassthruchar29,
        ODLC.dtlpassthruchar30,
        ODLC.dtlpassthruchar31,
        ODLC.dtlpassthruchar32,
        ODLC.dtlpassthruchar33,
        ODLC.dtlpassthruchar34,
        ODLC.dtlpassthruchar35,
        ODLC.dtlpassthruchar36,
        ODLC.dtlpassthruchar37,
        ODLC.dtlpassthruchar38,
        ODLC.dtlpassthruchar39,
        ODLC.dtlpassthruchar40,
        ODLC.dtlpassthrunum01,
        ODLC.dtlpassthrunum02,
        ODLC.dtlpassthrunum03,
        ODLC.dtlpassthrunum04,
        ODLC.dtlpassthrunum05,
        ODLC.dtlpassthrunum06,
        ODLC.dtlpassthrunum07,
        ODLC.dtlpassthrunum08,
        ODLC.dtlpassthrunum09,
        ODLC.dtlpassthrunum10,
        ODLC.dtlpassthrunum11,
        ODLC.dtlpassthrunum12,
        ODLC.dtlpassthrunum13,
        ODLC.dtlpassthrunum14,
        ODLC.dtlpassthrunum15,
        ODLC.dtlpassthrunum16,
        ODLC.dtlpassthrunum17,
        ODLC.dtlpassthrunum18,
        ODLC.dtlpassthrunum19,
        ODLC.dtlpassthrunum20,
        ODLC.dtlpassthrudate01,
        ODLC.dtlpassthrudate02,
        ODLC.dtlpassthrudate03,
        ODLC.dtlpassthrudate04,
        ODLC.dtlpassthrudoll01,
        ODLC.dtlpassthrudoll02,
        CNT.po,
        ODLC.weightship * CNT.qty / ODLC.qtyship,
        ODLC.cubeship * CNT.qty / ODLC.qtyship,
        CI.descr,
        ODLC.qtyorder,
        ODLC.qtyship,
        l_seq,
        CNT.hazardous,
        zim7.lpid_last6(CNT.FROMLPID),
        zim7.lpid_last7(CNT.FROMLPID),
        CNT.itemdescr,
        CNT.manufacturedate,
        nShippingCost,
        nShippingWeight,
        CNT.serialnumber,
        CNT.labeltype,
        CI.itmpassthruchar01,
        CNT.expirationdate,
        CI.itmpassthruchar02,
        CI.itmpassthruchar03,
        CI.itmpassthruchar04,
        CI.itmpassthruchar05,
        CI.itmpassthruchar06,
        CI.itmpassthruchar07,
        CI.itmpassthruchar08,
        CI.itmpassthruchar09,
        CI.itmpassthruchar10,
        CI.itmpassthrunum01,
        CI.itmpassthrunum02,
        CI.itmpassthrunum03,
        CI.itmpassthrunum04,
        CI.itmpassthrunum05,
        CI.itmpassthrunum06,
        CI.itmpassthrunum07,
        CI.itmpassthrunum08,
        CI.itmpassthrunum09,
        CI.itmpassthrunum10,
        CNT.innerpackqty,
        CNT.ea_to_cs,
        CNT.shipmentstatuscode,
        CNT.qtydifference,
        CNT.cartontype,
        CNT.cslength,
        CNT.cswidth,
        CNT.csheight,
        nLength,
        nWidth,
        nHeight,
        vRmaTrackingNo;



end if;

exception when others then
  debugmsg('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
  debugmsg(sqlerrm);

end;

procedure distribute_odl(in_custid varchar2, in_item varchar2, in_lot varchar2,
    in_orderitem varchar2, in_orderlot varchar2,
    in_uom varchar2, in_qty IN OUT number)
is
begin

    for odlx in 1..odl.count loop

        debugmsg('Check ODL:'||odl(odlx).item
            ||'/'||odl(odlx).lotnumber
            ||'/'||odl(odlx).linenumber
            ||'/'||odl(odlx).qty
            ||'/'||odl(odlx).savelot);

        if in_orderitem = odl(odlx).item
         and nvl(in_orderlot,'(none)')
                = nvl(odl(odlx).lotnumber,'(none)')
         and odl(odlx).qty > 0 then
           ODLC := null;
           if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
              debugmsg('&&&&& ' || OD.orderid || ', ' || OD.shipid || ', ' ||
                       odl(odlx).item || ', ' || odl(odlx).savelot || ', ' ||
                       odl(odlx).linenumber);
              OPEN C_ODLC(OH.orderid, OH.shipid, odl(odlx).item,
                  odl(odlx).savelot, odl(odlx).linenumber);
           else
              OPEN C_ODLC(OD.orderid, OD.shipid, odl(odlx).item,
                  odl(odlx).lotnumber, odl(odlx).linenumber);
           end if;
           FETCH C_ODLC into ODLC;
           CLOSE C_ODLC;
            if in_qty <= odl(odlx).qty then
                CNT.assignedid := odl(odlx).linenumber;
                if nvl(add_zero_qty_shipped_yn,'N') = 'Y' then
                    CNT.qty := 0;
                    CNT.cartons := 0;
                else
                    CNT.qty := in_qty; --csp.quantity;
                    CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                        in_uom, in_qty, l_carton_uom);
                end if;
                odl(odlx).qty := odl(odlx).qty - in_qty; --csp.quantity;
                -- csp.quantity := 0;
                in_qty := 0;
                debugmsg('Adding < CNT 945 for:'||CNT.qty);
                write_contents(ODLC);
                exit;
            else
                CNT.assignedid := odl(odlx).linenumber;
                if nvl(add_zero_qty_shipped_yn,'N') = 'Y' then
                    CNT.qty := 0;
                    CNT.cartons := 0;
                else
                    CNT.qty := odl(odlx).qty;
                    CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                       in_uom, CNT.qty, l_carton_uom);
                end if;
                in_qty := in_qty - odl(odlx).qty;
                odl(odlx).qty := 0;
                debugmsg('Adding > CNT for:'||CNT.qty);
                write_contents(ODLC);

            end if;

        end if;
    end loop;


--    if csp.quantity > 0 then
    if in_qty > 0 then
        CNT.assignedid := null;
--        CNT.qty := csp.quantity;
        CNT.qty := in_qty;
--        CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
--                 csp.unitofmeasure, csp.quantity, l_carton_uom);
        CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                 in_uom, in_qty, l_carton_uom);
        debugmsg('Adding no match CNT for:'||CNT.qty);
        ODLC := null;
        if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
           OPEN C_ODLC(OH.orderid, OH.shipid, odl(odlx).item,
               odl(odlx).savelot, odl(odlx).linenumber);
        else
           OPEN C_ODLC(OD.orderid, OD.shipid, odl(odlx).item,
               odl(odlx).lotnumber, odl(odlx).linenumber);
        end if;
        FETCH C_ODLC into ODLC;
        CLOSE C_ODLC;
        write_contents(ODLC);
    end if;




end distribute_odl;

procedure preprinted_labels is

cursor curCaseLabels(in_item varchar2, in_barcode varchar2) is
   select *
     from caselabels
    where orderid = oh.orderid
      and shipid = oh.shipid
      and item = in_item
      and barcode > in_barcode
    order by barcode;
CL curCaseLabels%rowtype;
last_item caselabels.item%type := '(none(';
cntSSCC caselabels.barcode%type := '(none(';
nQty integer;
lblcs_lot_cnt number;
lblcs_quantity number;
l_lotnumber orderdtl.lotnumber%type;

type odl_rcd is record (
  item         orderdtlline.item%type,
  qtydiff      number
);

type odl_tbl is table of odl_rcd
     index by binary_integer;

odl odl_tbl;
odlx integer;
notfound boolean;

begin
   debugmsg('Start preprinted labels');
   for csp in (select custid, item, serialnumber, lotnumber, nvl(parentlpid, lpid) as parentlpid, useritem1, useritem2,
                      useritem3, trackingno, unitofmeasure, sum(quantity) as quantity, orderitem, orderlot
                 from shippingplate
                 where orderid = oh.orderid
                   and shipid = oh.shipid
                   and type in ('F', 'P')
                   and status = 'SH'
               group by custid, item, serialnumber, lotnumber, nvl(parentlpid, lpid), useritem1, useritem2,
                        useritem3, trackingno, unitofmeasure, orderitem, orderlot
               order by item, quantity desc) loop
      debugmsg(csp.custid || ' ' || csp.item || '<>' || csp.serialnumber || '!!' || csp.lotnumber ||
               ' @@ ' || csp.parentlpid || ' ## ' || csp.unitofmeasure || ' $$ ' || csp.quantity||
               ' ** '|| csp.orderitem||' && '|| csp.orderlot);
      if csp.item <> last_item then
         if curCaseLabels%isopen then
            close curCaseLabels;
         end if;
         cmdSql := 'select nvl(max(ctn_sscc18), ''00000000000000000000'') from ship_note_945_cnt_' || strSuffix ||
                     ' where orderid = ' || oh.orderid ||
                       ' and shipid = ' || oh.shipid ||
                       ' and item = ''' || csp.item || '''';
         debugmsg('!!!!!!!!!!!!!!!! ' || cmdsql);
         begin
            execute immediate cmdSql into cntSSCC;
         exception when others then
            cntSSCC := '00000000000000000000';
         end;
         debugmsg('cntSSCC ' || cntSSCC);
         open curCaseLabels(csp.item, cntSSCC);
         last_item := csp.item;
      end if;
      OD := null;
      select count(1) into cntRows
         from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and item = csp.item
           and nvl(lotnumber,'(none)') = nvl(csp.lotnumber,'(none)');
      debugmsg('cnt lotnumber ' || cntRows || ' ' || csp.item || ' ' ||csp.lotnumber);
      if cntRows = 0 and
         csp.lotnumber is not null then
         l_lotnumber := null;
         debugmsg('   1');
         OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, null);
      else
         debugmsg('   2');
         l_lotnumber := csp.lotnumber;
         OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, csp.orderlot);
      end if;

      FETCH C_OD into OD;
      CLOSE C_OD;

      nQty := csp.quantity;
      debugmsg('starting nQty ' || nQty);
      CNT := null;
      CNT.orderid := oh.orderid;
      CNT.shipid := oh.shipid;
      CNT.custid := oh.custid;
      CNT.plt_sscc18 := null;
      CNT.trackingno := csp.trackingno;
      CNT.link_plt_sscc18 := '(none)';
      CNT.link_trackingno := nvl(csp.trackingno,'(none)');
      CNT.assignedid := OD.dtlpassthrunum10;
      CNT.item := csp.item;
      CNT.lotnumber := csp.lotnumber;
      CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
      CNT.useritem1 := csp.useritem1;
      CNT.useritem2 := csp.useritem2;
      CNT.useritem3 := csp.useritem3;
      -- CNT.qty := csp.quantity;
      CNT.uom := csp.unitofmeasure;
      CNT.po := oh.po;
      CNT.lpid := csp.parentlpid;
      begin
         select fromlpid into CNT.fromlpid
          from shippingplate
          where lpid = csp.parentlpid;
      exception when no_data_found then
         CNT.fromlpid := null;
      end;

      while nQty > 0 loop
         fetch curCaseLabels into CL;
         CNT.ctn_sscc18 := CL.barcode;
         CNT.link_ctn_sscc18 := nvl(CL.barcode,'(none)');

         if curCaseLabels%notfound then
            notfound := true;
            for odlx in 1..odl.count loop
              if odl(odlx).item = csp.item  and
                 abs(odl(odlx).qtydiff) = nQty then
                   debugmsg('Found Qtydiff: '||odl(odlx).item||'/'||odl(odlx).qtydiff);
                   notfound := false;
                exit;
              end if;
            end loop;

            if notfound then
            debugmsg('not found ' || nQty);
            distribute_odl(csp.custid, csp.item, csp.lotnumber, csp.orderitem, csp.orderlot,
                           csp.unitofmeasure, nQty);
            end if;
            nQty := 0;
         else
            if lblcs_lot_cnt > 1 then
             lblcs_quantity := csp.quantity;
            else
             lblcs_quantity := CL.quantity;
            end if;

            debugmsg('found >> ' || lblcs_quantity);
            nQty := nQty - lblcs_quantity;
            distribute_odl(csp.custid, csp.item, csp.lotnumber, csp.orderitem, csp.orderlot,
                          csp.unitofmeasure, lblcs_quantity);
         end if;
         debugmsg('ending nQty ' || nqty);
         if nQty < 0 then
           odlx := odl.count + 1;
           odl(odlx).item := csp.item;
           odl(odlx).qtydiff := nQty;
           debugmsg('Add Qtydiff:'||odl(odlx).item||'/'||odl(odlx).qtydiff);
         end if;
      end loop;


   end loop;
   if curCaseLabels%isopen then
      close curCaseLabels;
   end if;

end preprinted_labels;

procedure picked_labels
is
 lblcs_lot_cnt number;
 lblcs_lotnumber shippingplate.lotnumber%type;
 lblcs_quantity number;
 csp C_SP%rowtype;
begin
-- for every top level shipping plate for the order
if nvl(in_order_odl_by_qty_yn, 'N') = 'Y' then
    open C_SPI(oh.orderid, oh.shipid);
else
    open C_SP(oh.orderid, oh.shipid);
end if;
loop
    if nvl(in_order_odl_by_qty_yn, 'N') = 'Y' then
      fetch C_SPI into csp;
      exit when C_SPI%notfound;
    else
      fetch C_SP into csp;
      exit when C_SP%notfound;
    end if;
    debugmsg('CNT begin plate:'||csp.lpid || ' Type:'||csp.type);

    -- set up the contents row
    CNT := null;

    CNT.orderid := oh.orderid;
    CNT.shipid := oh.shipid;
    CNT.custid := oh.custid;
    CNT.lpid := csp.lpid;
    CNT.fromlpid := csp.fromlpid;

    -- locate the top level label (if any)
    LBL := null;
    OPEN C_LBL(oh.orderid, oh.shipid, 'P', csp.lpid, null);
    FETCH C_LBL into LBL;
    CLOSE C_LBL;

    CNT.plt_sscc18 := LBL.barcode;
    CNT.trackingno := csp.trackingno;
    CNT.labeltype := LBL.labeltype;
    CNT.link_plt_sscc18 := nvl(LBL.barcode,'(none)');
    CNT.link_trackingno := nvl(csp.trackingno,'(none)');

    do_cases := FALSE;
    do_cases_consolidated := FALSE;

    LBLCS := null;
    OPEN C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null);
    FETCH C_LBLCS into LBLCS;
    CLOSE C_LBLCS;
    if LBLCS.lpid is not null then
        do_cases := TRUE;
    else
        LBLCS := null;
        OPEN C_LBLCS_CONS(oh.orderid, oh.shipid, nvl(oh.original_wave_before_combine, oh.wave), csp.lpid, null, null);
        FETCH C_LBLCS_CONS into LBLCS;
        CLOSE C_LBLCS_CONS;
        if LBLCS.lpid is not null then
            do_cases_consolidated := TRUE;
        end if;
    end if;
   if do_cases then
      debugmsg('do cases ' || csp.lpid);
   else
      debugmsg('not do cases ' || csp.lpid);
   end if;
   debugmsg('Check if mixed lots on plate');
   begin
   lblcs_lot_cnt := 0;
    select count(*)
    into lblcs_lot_cnt
    from (
      select orderid, shipid, item, lotnumber
        from shippingplate
       where parentlpid = csp.lpid
         and item = csp.item
      group by orderid, shipid, item, lotnumber);
   exception when others then
     lblcs_lot_cnt := 0;
   end;
    debugmsg('csp.type:'||csp.type);


    if csp.type in ('F','P') then

        LBL := null;
        OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, csp.item);
        FETCH C_LBL into LBL;
        CLOSE C_LBL;

        CNT.ctn_sscc18 := LBL.barcode;
        CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');
        if CNT.link_ctn_sscc18 <> '(none)' then
           CNT.labeltype := LBL.labeltype;
        end if;
        OD := null;
        OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, csp.orderlot);
                --csp,item, csp.lotnumber);
        FETCH C_OD into OD;
        CLOSE C_OD;

        CNT.assignedid := OD.dtlpassthrunum10;
        CNT.item := csp.item;
        CNT.lotnumber := csp.lotnumber;
        CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
        CNT.useritem1 := csp.useritem1;
        CNT.useritem2 := csp.useritem2;
        CNT.useritem3 := csp.useritem3;
        CNT.serialnumber := csp.serialnumber;
        -- CNT.qty := csp.quantity;
        CNT.uom := csp.unitofmeasure;
        -- CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
        --                csp.unitofmeasure, csp.quantity, l_carton_uom);


        CNT.po := null;
        if csp.fromlpid is not null
        and nvl(in_contents_by_po,'N') = 'Y' then
          begin
            select po
              into CNT.po
              from allplateview
             where lpid = csp.fromlpid;
          exception when others then
            CNT.po := null;
          end;
        end if;

        if do_cases then

           if nvl(in_cnt_ignore_lot_yn,'N') = 'Y' then
              for cs in C_LBLCS_NOLOT(oh.orderid, oh.shipid, csp.lpid,
                  csp.item, csp.lotnumber)
              loop
                  odlfound := false;
                  debugmsg('Check for Item 1:'||cs.item
                      ||'/'||cs.lotnumber
                      ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                      ||'/'||cs.quantity);

                  CNT.ctn_sscc18 := cs.barcode;
                  CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                  if CNT.link_ctn_sscc18 <> '(none)' then
                     CNT.labeltype := cs.labeltype;
                  end if;

                  distribute_odl(cs.custid, cs.item, cs.lotnumber,
                      csp.orderitem, csp.orderlot,
                      csp.unitofmeasure, cs.quantity);

              end loop;

           else
            for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                csp.item, csp.lotnumber)
            loop
                odlfound := false;
                debugmsg('Check for Item 2:'||cs.item
                    ||'/'||cs.lotnumber
                    ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                    ||'/'||cs.quantity);

                CNT.ctn_sscc18 := cs.barcode;
                CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                if CNT.link_ctn_sscc18 <> '(none)' then
                   CNT.labeltype := cs.labeltype;
                end if;

                distribute_odl(cs.custid, cs.item, cs.lotnumber,
                    csp.orderitem, csp.orderlot,
                    csp.unitofmeasure, cs.quantity);

            end loop;

           end if;

        else

            if do_cases_consolidated then
               for cs in C_LBLCS_CONS(oh.orderid, oh.shipid, nvl(oh.original_wave_before_combine, oh.wave),
                                      csp.lpid, csp.item, csp.lotnumber)
               loop
                   odlfound := false;
                   debugmsg('Check for Item 3:'||cs.item
                       ||'/'||cs.lotnumber
                       ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                       ||'/'||cs.quantity);

                   CNT.ctn_sscc18 := cs.barcode;
                   CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                   if CNT.link_ctn_sscc18 <> '(none)' then
                      CNT.labeltype := cs.labeltype;
                   end if;

                   distribute_odl(cs.custid, cs.item, cs.lotnumber,
                       csp.orderitem, csp.orderlot,
                       csp.unitofmeasure, cs.quantity);

               end loop;

            else
               odlfound := false;
               debugmsg('Check for Item 4:'||csp.item
                  ||'/'||csp.lotnumber
                  ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                  ||'/'||csp.quantity);

               distribute_odl(csp.custid, csp.item, csp.lotnumber,
                  csp.orderitem, csp.orderlot,
                  csp.unitofmeasure, csp.quantity);
            end if;
         end if;
        goto lp_continue;

    end if;
    if nvl(in_force_cnt_fromlpid_yn,'N') = 'Y' then
     /*
       for cdtl in (select S.item, S.lotnumber, S.orderitem, S.orderlot,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                       min(S.useritem1) useritem1,
                       min(S.useritem2) useritem2,
                       min(S.useritem3) useritem3,
                       min(S.serialnumber) serialnumber,
                       S.unitofmeasure, S.fromlpid, sum(S.quantity) quantity
                      from shippingplate S
                     where S.orderid = oh.orderid
                       and S.shipid = oh.shipid
                       -- and parentlpid = csp.lpid
                       and S.type in ('F','P')
                       start with S.parentlpid = csp.lpid
                           connect by prior S.lpid = S.parentlpid
                      group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                       S.unitofmeasure, S.fromlpid,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null))
       */

       if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
          open C_useritem_detail_lpid(oh.orderid, oh.shipid, csp.lpid);
       else
          if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
             open C_std_nolot_detail(oh.orderid, oh.shipid, csp.lpid);
          else
             open C_std_detail(oh.orderid, oh.shipid, csp.lpid);
          end if;
       end if;

       loop
          if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
             fetch C_useritem_detail_lpid into cdtl;
             exit when C_useritem_detail_lpid%notfound;
          else
             if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
                fetch C_std_nolot_detail into cdtl;
                exit when C_std_nolot_detail%notfound;
             else
                fetch C_std_detail into cdtl;
                exit when C_std_detail%notfound;
             end if;
          end if;
           CNT.fromlpid := cdtl.fromlpid;
           debugmsg('cdtl ' || cdtl.item);
           LBL := null;
           OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
           FETCH C_LBL into LBL;
           CLOSE C_LBL;

           if LBL.orderid is null then
               OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
               FETCH C_LBLC into LBL;
               CLOSE C_LBLC;
           end if;


           CNT.ctn_sscc18 := LBL.barcode;
           CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');
           if CNT.link_ctn_sscc18 <> '(none)' then
                CNT.labeltype := LBL.labeltype;
           end if;

           OD := null;
           OPEN C_OD(oh.orderid, oh.shipid, cdtl.orderitem, cdtl.orderlot);
               -- cdtl.item, cdtl.lotnumber);
           FETCH C_OD into OD;
           CLOSE C_OD;

           CNT.assignedid := OD.dtlpassthrunum10;
           CNT.item := cdtl.item;
           CNT.lotnumber := cdtl.lotnumber;
           CNT.link_lotnumber := nvl(cdtl.lotnumber,'(none)');
           CNT.useritem1 := cdtl.useritem1;
           CNT.useritem2 := cdtl.useritem2;
           CNT.useritem3 := cdtl.useritem3;
           CNT.serialnumber := cdtl.serialnumber;
           -- CNT.qty := cdtl.quantity;
           CNT.uom := cdtl.unitofmeasure;
           CNT.po := cdtl.po;

           if do_cases then
               for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                   cdtl.item, cdtl.lotnumber)
               loop
                   odlfound := false;
                   debugmsg('Check for Item 3:'||cs.item
                       ||'/'||cs.lotnumber
                       ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                       ||'/'||cs.quantity);

                   CNT.ctn_sscc18 := cs.barcode;
                   CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                   if CNT.link_ctn_sscc18 <> '(none)' then
                      CNT.labeltype := cs.labeltype;
                   end if;

                   distribute_odl(cs.custid, cs.item, cs.lotnumber,
                       cdtl.orderitem, cdtl.orderlot,
                       cdtl.unitofmeasure, cs.quantity);
               end loop;
           else
              if csp.type = 'C' and
                 csp.item is null then
                  for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null)
                  loop
                      odlfound := false;
                      debugmsg('Check for Item C1:'||cs.item
                          ||'/'||cs.lotnumber
                          ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                          ||'/'||cs.quantity || '-' || cdtl.quantity);

                      CNT.ctn_sscc18 := cs.barcode;
                      CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                      if CNT.link_ctn_sscc18 <> '(none)' then
                         CNT.labeltype := cs.labeltype;
                      end if;
                      distribute_odl(cs.custid, cs.item, cs.lotnumber,
                          cdtl.orderitem, cdtl.orderlot,
                          cdtl.unitofmeasure, cdtl.quantity);
                  end loop;
              else
                  if csp.type = 'M' and
                     csp.item is null and
                     LBL.item is null then
                      for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null)
                      loop
                          odlfound := false;
                          debugmsg('Check for Item C2:'||cs.item
                              ||'/'||cs.lotnumber
                              ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                              ||'/'||cdtl.quantity);
                          CNT.ctn_sscc18 := cs.barcode;
                          CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                      distribute_odl(cs.custid, cs.item, cs.lotnumber,
                          cdtl.orderitem, cdtl.orderlot,
                          cdtl.unitofmeasure, cdtl.quantity);
                  end loop;
              else
                 odlfound := false;
                 debugmsg('Check for Item 4:'||cdtl.item
                     ||'/'||cdtl.lotnumber
                     ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                     ||'/'||cdtl.quantity);

                 distribute_odl(csp.custid, cdtl.item, cdtl.lotnumber,
                     cdtl.orderitem, cdtl.orderlot,
                     cdtl.unitofmeasure, cdtl.quantity);
              end if;
           end if;
         end if;
       end loop;

       if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
          close C_useritem_detail_lpid;
       else
          if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
             close C_std_nolot_detail;
          else
             close C_std_detail;
          end if;
       end if;

    end if;

    if nvl(in_force_cnt_fromlpid_yn,'N') = 'N' then
    -- in_force_cnt_fromlpid_yn mutually exclisive with in_ctn_rollup_lot_yn
    /*
       for cdtl in (select S.item, S.lotnumber, S.orderitem, S.orderlot,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                       min(S.useritem1) useritem1,
                       min(S.useritem2) useritem2,
                       min(S.useritem3) useritem3,
                        min(S.serialnumber) serialnumber,
                       S.unitofmeasure, sum(S.quantity) quantity
                      from shippingplate S
                     where S.orderid = oh.orderid
                       and S.shipid = oh.shipid
                       -- and parentlpid = csp.lpid
                       and S.type in ('F','P')
                       start with S.parentlpid = csp.lpid
                           connect by prior S.lpid = S.parentlpid
                      group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                       S.unitofmeasure,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null))
                       */
       if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
          open C_useritem_detail(oh.orderid, oh.shipid, csp.lpid);
       else
          if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
             open C_std_nolot_detail(oh.orderid, oh.shipid, csp.lpid);
       else
          open C_std_detail(oh.orderid, oh.shipid, csp.lpid);
       end if;
       end if;

       loop
          if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
             fetch C_useritem_detail into cdtl;
             exit when C_useritem_detail%notfound;
          else
             if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
                fetch C_std_nolot_detail into cdtl;
                exit when C_std_nolot_detail%notfound;
          else
             fetch C_std_detail into cdtl;
             exit when C_std_detail%notfound;
          end if;
          end if;
       debugmsg('cdtl 2 ' || cdtl.item || ' - ' || cdtl.lotnumber || ' - ' || cdtl.orderlot || ' - ' || cdtl.quantity);
        LBL := null;
        OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
        FETCH C_LBL into LBL;
        CLOSE C_LBL;

        if LBL.orderid is null then
            OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
            FETCH C_LBLC into LBL;
            CLOSE C_LBLC;
        end if;

        -- if caselabels is written with no item for multi-item cartons
        -- then just get the barcode via the csp.lpid.
        if LBL.orderid is null then
            OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, NULL);
            FETCH C_LBLC into LBL;
            CLOSE C_LBLC;
        end if;

        CNT.ctn_sscc18 := LBL.barcode;
        CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');
        if CNT.link_ctn_sscc18 <> '(none)' then
           CNT.labeltype := LBL.labeltype;
        end if;

        OD := null;
        OPEN C_OD(oh.orderid, oh.shipid, cdtl.orderitem, cdtl.orderlot);
            -- cdtl.item, cdtl.lotnumber);
        FETCH C_OD into OD;
        CLOSE C_OD;

        CNT.assignedid := OD.dtlpassthrunum10;
        CNT.item := cdtl.item;
        CNT.lotnumber := cdtl.lotnumber;
        CNT.link_lotnumber := nvl(cdtl.lotnumber,'(none)');
        CNT.useritem1 := cdtl.useritem1;
        CNT.useritem2 := cdtl.useritem2;
        CNT.useritem3 := cdtl.useritem3;
        -- CNT.qty := cdtl.quantity;
        CNT.uom := cdtl.unitofmeasure;
        CNT.po := cdtl.po;
        CNT.serialnumber := cdtl.serialnumber;




        if do_cases then
           if nvl(in_cnt_ignore_lot_yn,'N') = 'Y' then
              for cs in C_LBLCS_NOLOT(oh.orderid, oh.shipid, csp.lpid,
                  cdtl.item, cdtl.lotnumber)
              loop
                  odlfound := false;
                  debugmsg('Check for Item 5:'||cs.item
                      ||'/'||cs.lotnumber
                      ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                      ||'/'||cs.quantity);

                  CNT.ctn_sscc18 := cs.barcode;
                  CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                  if CNT.link_ctn_sscc18 <> '(none)' then
                     CNT.labeltype := cs.labeltype;
                  end if;

                  distribute_odl(cs.custid, cs.item, cs.lotnumber,
                      cdtl.orderitem, cdtl.orderlot,
                      cdtl.unitofmeasure, cs.quantity);

              end loop;

           else
               if csp.type = 'C' and
                      csp.item is null then
                    for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null)
            loop
                odlfound := false;
                debugmsg('Check for Item C2:'||cs.item
                    ||'/'||cs.lotnumber
                    ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                    ||'/'||cs.quantity || '-' || cdtl.quantity);

                CNT.ctn_sscc18 := cs.barcode;
                CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                if CNT.link_ctn_sscc18 <> '(none)' then
                   CNT.labeltype := cs.labeltype;
                end if;

                distribute_odl(cs.custid, cs.item, cs.lotnumber,
                    cdtl.orderitem, cdtl.orderlot,
                    cdtl.unitofmeasure, cdtl.quantity);
                    end loop;
               else
            for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                cdtl.item, cdtl.lotnumber)
            loop
                odlfound := false;
                debugmsg('Check for Item 6:'||cs.item
                    ||'/'||cs.lotnumber
                    ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                    ||'/'||cs.quantity);

                CNT.ctn_sscc18 := cs.barcode;
                CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                if CNT.link_ctn_sscc18 <> '(none)' then
                   CNT.labeltype := cs.labeltype;
                end if;

                distribute_odl(cs.custid, cs.item, cs.lotnumber,
                    cdtl.orderitem, cdtl.orderlot,
                    cdtl.unitofmeasure, cs.quantity);

            end loop;
           end if;
           end if;


        else

            if do_cases_consolidated then
               debugmsg('in do cases_cons ' || oh.orderid || ' ' || oh.shipid || ' ' ||
                         csp.lpid || ' ' || cdtl.item || ' ' || cdtl.lotnumber);
                if csp.type = 'C' then
                   for cs in C_LBLCS_CONS(oh.orderid, oh.shipid,
                                          nvl(oh.original_wave_before_combine, oh.wave),
                                          csp.lpid, LBL.item, LBL.lotnumber)
                    loop
                       odlfound := false;
                       debugmsg('Check for Item dc c1:'||cs.item
                           ||'/'||cs.lotnumber
                           ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                           ||'/'||cs.quantity);

                       CNT.ctn_sscc18 := cs.barcode;
                       CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                       if CNT.link_ctn_sscc18 <> '(none)' then
                          CNT.labeltype := cs.labeltype;
                       end if;
                       --debugmsg('!!!!!!!!!!!!!!!!!!!!!!assign ctn_sscc18 4 ' || CNT.ctn_sscc18);

                       distribute_odl(cs.custid, cs.item, cs.lotnumber,
                           cdtl.orderitem, cdtl.orderlot,
                           cdtl.unitofmeasure, cdtl.quantity);
                   end loop;
                else
                   for cs in C_LBLCS_CONS(oh.orderid, oh.shipid,
                                          nvl(oh.original_wave_before_combine, oh.wave),
                                          csp.lpid, cdtl.item, cdtl.lotnumber)
                   loop
                       odlfound := false;
                       debugmsg('Check for Item dc:'||cs.item
                           ||'/'||cs.lotnumber
                           ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                           ||'/'||cs.quantity);

                       CNT.ctn_sscc18 := cs.barcode;
                       CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                       if CNT.link_ctn_sscc18 <> '(none)' then
                          CNT.labeltype := cs.labeltype;
                       end if;

                       distribute_odl(cs.custid, cs.item, cs.lotnumber,
                           cdtl.orderitem, cdtl.orderlot,
                           cdtl.unitofmeasure, cs.quantity);

                   end loop;
                end if;
            else

               odlfound := false;
               debugmsg('Check for Item 7:'||cdtl.item
                   ||'/'||cdtl.lotnumber
                   ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                   ||'/'||cdtl.quantity);

               distribute_odl(csp.custid, cdtl.item, cdtl.lotnumber,
                   cdtl.orderitem, cdtl.orderlot,
                   cdtl.unitofmeasure, cdtl.quantity);
            end if;
        end if;
       end loop;
       if nvl(in_cnt_groupby_useritem,'N') = 'Y' then
          close C_useritem_detail;
       else
          if nvl(in_ctn_rollup_lot_yn,'N') = 'Y' then
             close C_std_nolot_detail;
       else
          close C_std_detail;
       end if;
       end if;

    end if;

<<lp_continue>>
    null;
end loop;

end picked_labels;

procedure ca_labels is

cursor curCaseLabels(in_item varchar2) is
   select *
     from caselabels
    where orderid = oh.orderid
      and shipid = oh.shipid
      and item = in_item
    order by barcode;
CL curCaseLabels%rowtype;
last_item caselabels.item%type := '(none(';
nQty integer;

cursor C_SP_CA(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status = 'SH'
     and (parentlpid is null or
          type = 'C')
     and lpid in
       (select lpid
          from caselabels
          where orderid = in_orderid
            and shipid = in_shipid
            and lpid is not null);


begin
   debugmsg('>>>> Start ca labels');
   for csp in (select custid, item, serialnumber, lotnumber, nvl(parentlpid, lpid) as parentlpid, useritem1, useritem2,
                      useritem3, trackingno, unitofmeasure, sum(quantity) as quantity
                 from shippingplate
                 where orderid = oh.orderid
                   and shipid = oh.shipid
                   and type in ('F', 'P')
                   and status = 'SH'
                   and parentlpid not in (select nvl(lpid,'(none)')
                                            from caselabels
                                           where orderid = oh.orderid and shipid = oh.shipid)
               group by custid, item, serialnumber, lotnumber, nvl(parentlpid, lpid), useritem1, useritem2,
                        useritem3, trackingno, unitofmeasure) loop
      debugmsg(csp.custid || ' ' || csp.item || '<>' || csp.serialnumber || '!!' || csp.lotnumber ||
               ' @@ ' || csp.parentlpid || ' ## ' || csp.unitofmeasure || ' $$ ' || csp.quantity);
      if csp.item <> last_item then
         if curCaseLabels%isopen then
            close curCaseLabels;
         end if;
         open curCaseLabels(csp.item);
         last_item := csp.item;
      end if;
      OD := null;
      select count(1) into cntRows
         from orderdtl
         where orderid = oh.orderid
           and shipid = oh.shipid
           and item = csp.item
           and nvl(lotnumber,'(none)') = nvl(csp.lotnumber,'(none)');
      if cntRows = 0 and
         csp.lotnumber is not null then
         OPEN C_OD(oh.orderid, oh.shipid, csp.item, null);
      else
         OPEN C_OD(oh.orderid, oh.shipid, csp.item, csp.lotnumber);
      end if;
      FETCH C_OD into OD;
      CLOSE C_OD;

      nQty := csp.quantity;
      debugmsg('starting nQty ' || nQty);
      CNT := null;
      CNT.orderid := oh.orderid;
      CNT.shipid := oh.shipid;
      CNT.custid := oh.custid;
      CNT.plt_sscc18 := null;
      CNT.trackingno := csp.trackingno;
      CNT.link_plt_sscc18 := '(none)';
      CNT.link_trackingno := nvl(csp.trackingno,'(none)');
      CNT.assignedid := OD.dtlpassthrunum10;
      CNT.item := csp.item;
      CNT.lotnumber := csp.lotnumber;
      CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
      CNT.useritem1 := csp.useritem1;
      CNT.useritem2 := csp.useritem2;
      CNT.useritem3 := csp.useritem3;
      -- CNT.qty := csp.quantity;
      CNT.uom := csp.unitofmeasure;
      CNT.po := oh.po;
      CNT.lpid := csp.parentlpid;
      begin
         select fromlpid into CNT.fromlpid
          from shippingplate
          where lpid = csp.parentlpid;
      exception when no_data_found then
         CNT.fromlpid := null;
      end;

      while nQty > 0 loop
         fetch curCaseLabels into CL;
         CNT.ctn_sscc18 := CL.barcode;
         CNT.link_ctn_sscc18 := nvl(CL.barcode,'(none)');

         if curCaseLabels%notfound then
            debugmsg('not found ' || nQty);
            distribute_odl(csp.custid, csp.item, csp.lotnumber, csp.item, csp.lotnumber,
                           csp.unitofmeasure, nQty);
            nQty := 0;
         else
            debugmsg('found ' || CL.quantity);
            nQty := nQty - CL.quantity;
            distribute_odl(csp.custid, csp.item, csp.lotnumber, csp.item, csp.lotnumber,
                          csp.unitofmeasure, CL.quantity);
         end if;
         debugmsg('ending nQty ' || nqty);
      end loop;


   end loop;
   if curCaseLabels%isopen then
      close curCaseLabels;
   end if;
-- now labels with a lpid
for csp in C_SP_CA(oh.orderid, oh.shipid) loop
    debugmsg('CNT begin plate:'||csp.lpid || ' Type:'||csp.type);

    -- set up the contents row
    CNT := null;

    CNT.orderid := oh.orderid;
    CNT.shipid := oh.shipid;
    CNT.custid := oh.custid;
    CNT.lpid := csp.lpid;
    CNT.fromlpid := csp.fromlpid;

    -- locate the top level label (if any)
    LBL := null;
    OPEN C_LBL(oh.orderid, oh.shipid, 'P', csp.lpid, null);
    FETCH C_LBL into LBL;
    CLOSE C_LBL;

    CNT.plt_sscc18 := LBL.barcode;
    CNT.trackingno := csp.trackingno;
    CNT.link_plt_sscc18 := nvl(LBL.barcode,'(none)');
    CNT.link_trackingno := nvl(csp.trackingno,'(none)');

    do_cases := FALSE;
    do_cases_consolidated := FALSE;

    LBLCS := null;
    OPEN C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null);
    FETCH C_LBLCS into LBLCS;
    CLOSE C_LBLCS;

    if LBLCS.lpid is not null then
        do_cases := TRUE;
    else
        LBLCS := null;
        OPEN C_LBLCS_CONS(oh.orderid, oh.shipid,
                          nvl(oh.original_wave_before_combine, oh.wave),
                          csp.lpid, null, null);
        FETCH C_LBLCS_CONS into LBLCS;
        CLOSE C_LBLCS_CONS;
        if LBLCS.lpid is not null then
            do_cases_consolidated := TRUE;
        end if;
    end if;


    if csp.type in ('F','P') then

        LBL := null;
        OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, csp.item);
        FETCH C_LBL into LBL;
        CLOSE C_LBL;

        CNT.ctn_sscc18 := LBL.barcode;
        CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

        --CNT.ctn_sscc18 := null;
        --CNT.link_ctn_sscc18 := '(none)';

        OD := null;
        OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, csp.orderlot);
                --csp,item, csp.lotnumber);
        FETCH C_OD into OD;
        CLOSE C_OD;

        CNT.assignedid := OD.dtlpassthrunum10;
        CNT.item := csp.item;
        CNT.lotnumber := csp.lotnumber;
        CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
        CNT.useritem1 := csp.useritem1;
        CNT.useritem2 := csp.useritem2;
        CNT.useritem3 := csp.useritem3;
        -- CNT.qty := csp.quantity;
        CNT.uom := csp.unitofmeasure;
        -- CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
        --                csp.unitofmeasure, csp.quantity, l_carton_uom);


        CNT.po := null;
        if csp.fromlpid is not null
        and nvl(in_contents_by_po,'N') = 'Y' then
          begin
            select po
              into CNT.po
              from allplateview
             where lpid = csp.fromlpid;
          exception when others then
            CNT.po := null;
          end;
        end if;

        if do_cases then
           if nvl(in_cnt_ignore_lot_yn,'N') = 'Y' then
              for cs in C_LBLCS_NOLOT(oh.orderid, oh.shipid, csp.lpid,
                  csp.item, csp.lotnumber)
              loop
                  odlfound := false;
                  debugmsg('Check for Item:'||cs.item
                      ||'/'||cs.lotnumber
                      ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                      ||'/'||cs.quantity);

                  CNT.ctn_sscc18 := cs.barcode;
                  CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                  distribute_odl(cs.custid, cs.item, cs.lotnumber,
                      csp.orderitem, csp.orderlot,
                      csp.unitofmeasure, cs.quantity);

              end loop;

           else
              for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                  csp.item, csp.lotnumber)
              loop
                  odlfound := false;
                  debugmsg('Check for Item:'||cs.item
                      ||'/'||cs.lotnumber
                      ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                      ||'/'||cs.quantity);

                  CNT.ctn_sscc18 := cs.barcode;
                  CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                  distribute_odl(cs.custid, cs.item, cs.lotnumber,
                      csp.orderitem, csp.orderlot,
                      csp.unitofmeasure, cs.quantity);

              end loop;
           end if;
        else
            if do_cases_consolidated then
               for cs in C_LBLCS_CONS(oh.orderid, oh.shipid,
                                      nvl(oh.original_wave_before_combine, oh.wave),
                                      csp.lpid, csp.item, csp.lotnumber)
               loop
                   odlfound := false;
                   debugmsg('Check for Item:'||cs.item
                       ||'/'||cs.lotnumber
                       ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                       ||'/'||cs.quantity);

                   CNT.ctn_sscc18 := cs.barcode;
                   CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                   distribute_odl(cs.custid, cs.item, cs.lotnumber,
                       csp.orderitem, csp.orderlot,
                       csp.unitofmeasure, cs.quantity);

               end loop;

            else
                odlfound := false;
                debugmsg('Check for Item:'||csp.item
                    ||'/'||csp.lotnumber
                    ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                    ||'/'||csp.quantity);

                distribute_odl(csp.custid, csp.item, csp.lotnumber,
                    csp.orderitem, csp.orderlot,
                    csp.unitofmeasure, csp.quantity);
            end if;
        end if;
        goto lp_continue;

    end if;

-- Need contents of the top level plate since it has no real contents
--    for cdtl in (select item, lotnumber, useritem1, useritem2, useritem3,
--                    unitofmeasure, sum(quantity) quantity
--                   from shippingplate
--                  where orderid = oh.orderid
--                    and shipid = oh.shipid
--                    and parentlpid = csp.lpid
--                    and type in ('F','P')
--                   group by item, lotnumber, useritem1, useritem2, useritem3,
--                        unitofmeasure)
    for cdtl in (select S.item, S.lotnumber, S.orderitem, S.orderlot,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                    min(S.useritem1) useritem1,
                    min(S.useritem2) useritem2,
                    min(S.useritem3) useritem3,
                    S.unitofmeasure, sum(S.quantity) quantity,
                    S.serialnumber
                   from shippingplate S
                  where S.orderid = oh.orderid
                    and S.shipid = oh.shipid
                    -- and parentlpid = csp.lpid
                    and S.type in ('F','P')
                    start with S.parentlpid = csp.lpid
                        connect by prior S.lpid = S.parentlpid
                   group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                    S.unitofmeasure,
                    decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null),S.serialnumber)
    loop

        LBL := null;
        OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
        FETCH C_LBL into LBL;
        CLOSE C_LBL;

        if LBL.orderid is null then
            OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
            FETCH C_LBLC into LBL;
            CLOSE C_LBLC;
        end if;

        -- if caselabels is written with no item for multi-item cartons
        -- then just get the barcode via the csp.lpid.
        if LBL.orderid is null then
            OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, NULL);
            FETCH C_LBLC into LBL;
            CLOSE C_LBLC;
        end if;

        CNT.ctn_sscc18 := LBL.barcode;
        CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

        OD := null;
        OPEN C_OD(oh.orderid, oh.shipid, cdtl.orderitem, cdtl.orderlot);
            -- cdtl.item, cdtl.lotnumber);
        FETCH C_OD into OD;
        CLOSE C_OD;

        CNT.assignedid := OD.dtlpassthrunum10;
        CNT.item := cdtl.item;
        CNT.lotnumber := cdtl.lotnumber;
        CNT.link_lotnumber := nvl(cdtl.lotnumber,'(none)');
        CNT.useritem1 := cdtl.useritem1;
        CNT.useritem2 := cdtl.useritem2;
        CNT.useritem3 := cdtl.useritem3;
        -- CNT.qty := cdtl.quantity;
        CNT.uom := cdtl.unitofmeasure;
        CNT.po := cdtl.po;
        CNT.serialnumber := cdtl.serialnumber;

        if do_cases then
           if nvl(in_cnt_ignore_lot_yn,'N') = 'Y' then
              for cs in C_LBLCS_NOLOT(oh.orderid, oh.shipid, csp.lpid,
                  cdtl.item, cdtl.lotnumber)
              loop
                  odlfound := false;
                  debugmsg('Check for Item:'||cs.item
                      ||'/'||cs.lotnumber
                      ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                      ||'/'||cs.quantity);

                  CNT.ctn_sscc18 := cs.barcode;
                  CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                  distribute_odl(cs.custid, cs.item, cs.lotnumber,
                      cdtl.orderitem, cdtl.orderlot,
                      cdtl.unitofmeasure, cs.quantity);

              end loop;

           else
              if csp.type = 'C' and
                 csp.item is null then
                  for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null)
                  loop
                      odlfound := false;
                      debugmsg('Check for Item C:'||cs.item
                          ||'/'||cs.lotnumber
                          ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                          ||'/'||cdtl.quantity);

                      CNT.ctn_sscc18 := cs.barcode;
                      CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                      distribute_odl(cs.custid, cs.item, cs.lotnumber,
                          cdtl.orderitem, cdtl.orderlot,
                          cdtl.unitofmeasure, cdtl.quantity);
                  end loop;
              else
                  for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                      cdtl.item, cdtl.lotnumber)
                  loop
                      odlfound := false;
                      debugmsg('Check for Item:'||cs.item
                          ||'/'||cs.lotnumber
                          ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                          ||'/'||cs.quantity);

                      CNT.ctn_sscc18 := cs.barcode;
                      CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                      distribute_odl(cs.custid, cs.item, cs.lotnumber,
                          cdtl.orderitem, cdtl.orderlot,
                          cdtl.unitofmeasure, cs.quantity);

                  end loop;
              end if;
           end if;
        else
            if do_cases_consolidated then
               debugmsg('in do cases_cons ' || oh.orderid || ' ' || oh.shipid || ' ' ||
                         csp.lpid || ' ' || cdtl.item || ' ' || cdtl.lotnumber);
                if csp.type = 'C' then
                   for cs in C_LBLCS_CONS(oh.orderid, oh.shipid, nvl(oh.original_wave_before_combine, oh.wave),
                                          csp.lpid, LBL.item, LBL.lotnumber)
                   loop
                       odlfound := false;
                       debugmsg('Check for Item dc c:'||cs.item
                           ||'/'||cs.lotnumber
                           ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                           ||'/'||cs.quantity);

                       CNT.ctn_sscc18 := cs.barcode;
                       CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                       --debugmsg('!!!!!!!!!!!!!!!!!!!!!!assign ctn_sscc18 4 ' || CNT.ctn_sscc18);

                       distribute_odl(cs.custid, cs.item, cs.lotnumber,
                           cdtl.orderitem, cdtl.orderlot,
                           cdtl.unitofmeasure, cdtl.quantity);
                   end loop;
                else
                   for cs in C_LBLCS_CONS(oh.orderid, oh.shipid,
                                          nvl(oh.original_wave_before_combine, oh.wave),
                                          csp.lpid, cdtl.item, cdtl.lotnumber)
                   loop
                       odlfound := false;
                       debugmsg('Check for Item dc:'||cs.item
                           ||'/'||cs.lotnumber
                           ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                           ||'/'||cs.quantity);

                       CNT.ctn_sscc18 := cs.barcode;
                       CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                       distribute_odl(cs.custid, cs.item, cs.lotnumber,
                           cdtl.orderitem, cdtl.orderlot,
                           cdtl.unitofmeasure, cs.quantity);

                   end loop;
                end if;
            else
                odlfound := false;
                debugmsg('Check for Item:'||cdtl.item
                    ||'/'||cdtl.lotnumber
                    ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                    ||'/'||cdtl.quantity);

                distribute_odl(csp.custid, cdtl.item, cdtl.lotnumber,
                    cdtl.orderitem, cdtl.orderlot,
                    cdtl.unitofmeasure, cdtl.quantity);
            end if;
        end if;
    end loop;

<<lp_continue>>
    null;
end loop;

end ca_labels;



begin

debugmsg('begin add_945_cnt_rows ' || oh.orderid || '-' || oh.shipid);
l_seq := 0;
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  if oh.orderstatus = 'X' then
    return;
  end if;
end if;

ca := null;
open curCarrier(oh.carrier);
fetch curCarrier into ca;
close curCarrier;

ld := null;
open curLoads(oh.loadno);
fetch curLoads into ld;
close curLoads;

-- First load the orderdtlline information
odl.delete;
odlx := 0;

if nvl(in_ctn_rollup_lot_yn,'N') <> 'Y' then
   for crec in C_ODL(oh.orderid, oh.shipid) loop
       odlx := odl.count + 1;
       odl(odlx).item := crec.item;
       odl(odlx).lotnumber := crec.lotnumber;
       odl(odlx).linenumber := crec.linenumber;
       odl(odlx).qty := crec.qty;

       debugmsg('Add ODL:'||odl(odlx).item
           ||'/'||odl(odlx).lotnumber
           ||'/'||odl(odlx).linenumber
           ||'/'||odl(odlx).qty);

   end loop;
elsif  nvl(in_order_odl_by_qty_yn, 'N') = 'Y' then
    for crec in C_ODLI(oh.orderid, oh.shipid) loop
        odlx := odl.count + 1;
        odl(odlx).item := crec.item;
        odl(odlx).lotnumber := crec.lotnumber;
        odl(odlx).linenumber := crec.linenumber;
        odl(odlx).qty := crec.qty;

        debugmsg('Add ODL:'||odl(odlx).item
            ||'/'||odl(odlx).lotnumber
            ||'/'||odl(odlx).linenumber
            ||'/'||odl(odlx).qty);

    end loop;
else
   for crec in C_ODL(oh.orderid, oh.shipid) loop
      debugmsg('item ' || crec.item || ' @ ' || crec.lotnumber || ' $ ' || crec.linenumber || ' # ' || crec.qty);
       odlx := odl.count + 1;
       odl(odlx).item := crec.item;
       odl(odlx).lotnumber := null;
       odl(odlx).linenumber := crec.linenumber;
       odl(odlx).qty := crec.qty;
       odl(odlx).savelot := crec.lotnumber;

       debugmsg('Add ODL nolot:'||odl(odlx).item
           ||'/'||odl(odlx).lotnumber
           ||'/'||odl(odlx).linenumber
           ||'/'||odl(odlx).qty
           ||'/'||odl(odlx).savelot);

   end loop;
end if;

open C_CL(oh.orderid, oh.shipid);
fetch C_CL into lLabelType;
if C_CL%notfound then
   lLabelType := 'zz';
end if;
close C_CL;
debugmsg('>>>> label type ' || lLabeltype);
if lLabeltype = 'PP' then
   preprinted_labels;
elsif lLabeltype = 'CA' then
   ca_labels;
else
   picked_labels;
end if;

-- Now if we are doing zero lines

  if ((upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'Y') or
     (upper(nvl(in_include_zero_qty_ctn_yn,'N')) = 'Y')) and
     (upper(nvl(in_include_zero_qty_shipped_yn,'N')) = 'N') then

    debugmsg('Starting zero for:'||oh.orderid||'/'||oh.shipid);

    for cod in (select od.ITEM as item, od.LOTNUMBER as lotnumber,
                       nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
                       nvl(OD.qtyorder,0) as qty,
                       od.uom as uom
                 from orderdtlline ol, orderdtl od
                where od.orderid = oh.orderid
                  and od.shipid = oh.shipid
                  and OD.orderid = OL.orderid(+)
                  and OD.shipid = OL.shipid(+)
                  and OD.item = OL.item(+)
                  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
                  and nvl(od.qtyship,0) = 0)    loop

        debugmsg('Have zero for:'||cod.item ||' '||cod.lotnumber||' '||cod.linenumber);

        CNT := null;

        CNT.orderid := oh.orderid;
        CNT.shipid := oh.shipid;
        CNT.custid := oh.custid;
        CNT.lpid := '999999999999999';
        CNT.fromlpid := '999999999999999';

        CNT.link_plt_sscc18 := '(none)';
        CNT.link_ctn_sscc18 := '(none)';
        CNT.link_trackingno := '(none)';

        CNT.assignedid := COD.linenumber;
        CNT.item := COD.item;
        CNT.lotnumber := COD.lotnumber;
        CNT.link_lotnumber := nvl(COD.lotnumber,'(none)');
        CNT.qty := 0;
        CNT.uom := COD.uom;
        CNT.cartons := 0;

        ODLC := null;
        OPEN C_ODLC(OD.orderid, OD.shipid, cod.item,
            cod.lotnumber, cod.linenumber);
        FETCH C_ODLC into ODLC;
        CLOSE C_ODLC;
        write_contents(ODLC);



    end loop;

end if;
if nvl(in_include_zero_qty_shipped_yn,'N') = 'Y' then
    debugmsg('Starting zero carton shipped for:'||oh.orderid||'/'||oh.shipid);
    for cod in (select d.custid, d.item, d.lotnumber, d.uom,
                       sum(nvl(d.qtyorder,0) - nvl(d.qtyship,0)) qtydiff
                  from orderdtl d
                  where d.orderid = oh.orderid
                    and d.shipid = oh.shipid
                    and ((nvl(d.qtyship,0) < nvl(d.qtyorder,0)) or
                         (nvl(d.qtyship,0) = 0))
                  group by  d.custid, d.item, d.lotnumber, d.uom)
    loop
        open C_ODLZ(oh.orderid, oh.shipid, cod.item, cod.lotnumber);
        fetch C_ODLZ into ODLZ;
        exit when C_ODLZ%notfound;

        add_zero_qty_shipped_yn := 'Y';
        CNT := null;
        CNT.orderid := oh.orderid;
        CNT.shipid := oh.shipid;
        CNT.custid := oh.custid;
        l_zero_shipped_cartonid945 := null;

        CNT.link_plt_sscc18 := '(none)';
        CNT.link_ctn_sscc18 := '(none)';
        CNT.link_trackingno := '(none)';
        CNT.item := COD.item;
        CNT.lotnumber := COD.lotnumber;
        CNT.link_lotnumber := nvl(COD.lotnumber,'(none)');
        CNT.qty := 0;
        CNT.uom := COD.uom;
        CNT.cartons := 0;
        debugmsg('distribute_odl:: '||cod.item||' '||cod.lotnumber||' '||cod.qtydiff);
        distribute_odl(cod.custid, cod.item, cod.lotnumber, cod.item, cod.lotnumber, cod.uom, cod.qtydiff);
        close C_ODLZ;
    end loop;
   add_zero_qty_shipped_yn := 'N';
end if;
<< continue_945_cnt >>
null;

exception when others then
  debugmsg(sqlerrm);
end;


procedure extract_by_id_contents is
sn9d cur_type;
SND ship_note_945_dtl%rowtype;
SNC ship_note_945_cnt%rowtype;
nullInt integer := null;
nullDate date := null;
nullVar varchar2(2) := null;
nullNum number(1,1) := null;
strItemDescr custitem.descr%type;
begin

l_carton_uom := nvl(substr(in_carton_uom,1,4),'CS');


debugmsg('begin 945 extract by id contents');
debugmsg('creating 945 cnt');
cmdSql := 'create table SHIP_NOTE_945_CNT_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' LPID VARCHAR2(15), FROMLPID VARCHAR2(15), PLT_SSCC18 VARCHAR2(20),'||
' CTN_SSCC18 VARCHAR2(20), ' ||
' TRACKINGNO VARCHAR2(30), ' ||
' LINK_PLT_SSCC18 VARCHAR2(20), LINK_CTN_SSCC18 VARCHAR2(20), ' ||
' LINK_TRACKINGNO VARCHAR2(30), ' ||
' ASSIGNEDID NUMBER(16,4), item varchar2(50) not null, '||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),' ||
' USERITEM1 VARCHAR2(20),USERITEM2 VARCHAR2(20),USERITEM3 VARCHAR2(20),'||
' QTY NUMBER, UOM VARCHAR2(4), CARTONS NUMBER, ' ||
' DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR21 VARCHAR2(255),DTLPASSTHRUCHAR22 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR23 VARCHAR2(255),DTLPASSTHRUCHAR24 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR25 VARCHAR2(255),DTLPASSTHRUCHAR26 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR27 VARCHAR2(255),DTLPASSTHRUCHAR28 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR29 VARCHAR2(255),DTLPASSTHRUCHAR30 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR31 VARCHAR2(255),DTLPASSTHRUCHAR32 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR33 VARCHAR2(255),DTLPASSTHRUCHAR34 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR35 VARCHAR2(255),DTLPASSTHRUCHAR36 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR37 VARCHAR2(255),DTLPASSTHRUCHAR38 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR39 VARCHAR2(255),DTLPASSTHRUCHAR40 VARCHAR2(255),' ||
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),' ||
' DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),' ||
' DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),' ||
' DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),' ||
' DTLPASSTHRUNUM11 NUMBER(16,4),DTLPASSTHRUNUM12 NUMBER(16,4),' ||
' DTLPASSTHRUNUM13 NUMBER(16,4),DTLPASSTHRUNUM14 NUMBER(16,4),' ||
' DTLPASSTHRUNUM15 NUMBER(16,4),DTLPASSTHRUNUM16 NUMBER(16,4),' ||
' DTLPASSTHRUNUM17 NUMBER(16,4),DTLPASSTHRUNUM18 NUMBER(16,4),' ||
' DTLPASSTHRUNUM19 NUMBER(16,4),DTLPASSTHRUNUM20 NUMBER(16,4),' ||
' DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,' ||
' DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2),'||
' PO VARCHAR2(20), WEIGHT NUMBER(13,4), VOLUME NUMBER(13,4), DESCR VARCHAR2(255), ODQTYORDER NUMBER(10), ODQTYSHIP NUMBER(10), ' ||
' LINESEQ INTEGER, HAZARDOUS CHAR(1), FROMLPIDLAST6 varchar2(6), '||
' FROMLPIDLAST7 VARCHAR2(7), ITEMDESCR VARCHAR2(60), MANUFACTUREDATE DATE, '||
' SHIPPINGCOST NUMBER(10,2), SHIPPINGWEIGHT NUMBER(17,8), SERIALNUMBER VARCHAR2(30), LABELTYPE VARCHAR2(2),' ||
' ITMPASSTHRUCHAR01 VARCHAR2(255), EXPIRATIONDATE DATE, ' ||
' ITMPASSTHRUCHAR02 VARCHAR2(255), ITMPASSTHRUCHAR03 VARCHAR2(255), ' ||
' ITMPASSTHRUCHAR04 VARCHAR2(255), ITMPASSTHRUCHAR05 VARCHAR2(255), ITMPASSTHRUCHAR06 VARCHAR2(255), ' ||
' ITMPASSTHRUCHAR07 VARCHAR2(255), ITMPASSTHRUCHAR08 VARCHAR2(255), ITMPASSTHRUCHAR09 VARCHAR2(255), ' ||
' ITMPASSTHRUCHAR10 VARCHAR2(255), ITMPASSTHRUNUM01 NUMBER(16,4), ITMPASSTHRUNUM02 NUMBER(16,4),  ' ||
' ITMPASSTHRUNUM03 NUMBER(16,4), ITMPASSTHRUNUM04 NUMBER(16,4), ITMPASSTHRUNUM05 NUMBER(16,4), '||
' ITMPASSTHRUNUM06 NUMBER(16,4), ITMPASSTHRUNUM07 NUMBER(16,4), ITMPASSTHRUNUM08 NUMBER(16,4), '||
' ITMPASSTHRUNUM09 NUMBER(16,4), ITMPASSTHRUNUM10 NUMBER(16,4), INNERPACKQTY NUMBER(7), ' ||
' EA_TO_CS NUMBER(7), SHIPMENTSTATUSCODE VARCHAR2(3), QTYDIFFERENCE NUMBER(7), CARTONTYPE VARCHAR2(8), ' ||
' CSLENGTH NUMBER(10,4), CSWIDTH NUMBER(10,4), CSHEIGHT NUMBER(10,4), ' ||
' LENGTH NUMBER(10,4), WIDTH NUMBER(10,4), HEIGHT NUMBER(10,4), RMATRACKINGNO VARCHAR2(30) )';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



debugmsg('creating 945 id');

if nvl(in_id_passthru_yn,'N') = 'Y' then
   cmdSql := 'create view SHIP_NOTE_945_ID_'|| strSuffix ||
   ' as select orderid,shipid,custid,lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
   ' trackingno,'||
   ' link_plt_sscc18,link_ctn_sscc18,link_trackingno, '||
   ' min(dtlpassthrunum01) as dtlpassthrunum01,' ||
   ' min(dtlpassthrunum02) as dtlpassthrunum02, '||
   ' shippingweight, shippingcost, '||
   ' sum(cartons) cartons, ' ||
   ' sum(nvl(weight,0)) totalweight, sum(nvl(volume,0)) totalvolume, ' ||
   ' length, width, height, rmatrackingno ' ||
   '  from ship_note_945_cnt_' || strSuffix ||
   '  group by orderid,shipid,custid,lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
   '  trackingno, '||
   '  link_plt_sscc18,link_ctn_sscc18,link_trackingno, dtlpassthrunum01, dtlpassthrunum02, '||
   '  dtlpassthrunum02,shippingweight,shippingcost,  ' ||
   '  length, width, height, rmatrackingno ';
else
   cmdSql := 'create view SHIP_NOTE_945_ID_'|| strSuffix ||
' as select orderid,shipid,custid,lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
' trackingno,'||
' link_plt_sscc18,link_ctn_sscc18,link_trackingno, '||
' shippingweight, shippingcost, '||
' sum(cartons) cartons, ' ||
' sum(nvl(weight,0)) totalweight, sum(nvl(volume,0)) totalvolume, ' ||
' length, width, height, rmatrackingno ' ||
'  from ship_note_945_cnt_' || strSuffix ||
'  group by orderid,shipid,custid,lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
'  trackingno, '||
'  link_plt_sscc18,link_ctn_sscc18,link_trackingno,shippingweight,shippingcost,  ' ||
'  length, width, height, rmatrackingno ';

end if;
debugmsg(' %%%%%%%%%%%%%%');
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


if nvl(in_allow_pick_status_yn,'N') = 'Y' then
   if in_orderid != 0 then
     debugmsg('by id pick order ' || in_orderid || '-' || in_shipid);
     for oh in curPickOrderHdr
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_cnt_rows(oh);
     end loop;
   elsif in_loadno != 0 then
     debugmsg('by id pick loadno ' || in_loadno);
     for oh in curPickOrderHdrByLoad
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_cnt_rows(oh);
     end loop;
   elsif rtrim(in_begdatestr) is not null then
     debugmsg('by id pick date ' || in_begdatestr || '-' || in_enddatestr);
     begin
       dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -1;
       out_msg := 'Invalid begin date string ' || in_begdatestr;
       return;
     end;
     begin
       dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -2;
       out_msg := 'Invalid end date string ' || in_enddatestr;
       return;
     end;
     for oh in curPickOrderHdrByShipDate
     loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       add_945_cnt_rows(oh);
     end loop;
   end if;
else
if in_orderid != 0 then
  debugmsg('by order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('by loadno ' || in_loadno);
  for oh in curOrderHdrByLoad
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('by date ' || in_begdatestr || '-' || in_enddatestr);
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
end if;
end if;


if in_cancel_productgroup is not null then
   cmdSql := 'select * from ship_note_945_dtl_'||strSuffix ||
             ' where productgroup = ''' || in_cancel_productgroup ||'''';
   debugmsg(cmdSql);
   open sn9d for cmdsql;
   loop
      fetch sn9d into SND;
      exit when sn9d%notfound;
      begin
         select po into SND.po
            from orderhdr
            where orderid = SND.orderid
              and shipid = SND.shipid;
      exception when no_data_found then
         SND.po := null;
      end;
      begin
         select descr into strItemDescr
            from custitem
            where custid = SNC.custid
              and item = SNC.item;
      exception when no_data_found then
         strItemdescr := null;
      end;
      SNC := null;
      SNC.lpid := '(none)';
      SNC.fromlpid := '(none)';
      SNC.link_plt_sscc18 := '(none)';
      SNC.link_ctn_sscc18 := '(none)';
      SNC.link_trackingno := '(none)';
      SNC.link_lotnumber := nvl(SNC.lotnumber, '(none)');
      SNC.cartons := 0;
      SNC.volume := 0;

      debugmsg('snd loop ' || SND.orderid || '-' || SND.shipid || ' ' || SND.item);

      execute immediate 'insert into SHIP_NOTE_945_CNT_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
      ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
      ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
      ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
      ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
      ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
      ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
      ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
      ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
      ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
      ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
      ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
      ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
      ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
      ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
      ' :DTLPASSTHRUCHAR21,:DTLPASSTHRUCHAR22,' ||
      ' :DTLPASSTHRUCHAR23,:DTLPASSTHRUCHAR24,' ||
      ' :DTLPASSTHRUCHAR25,:DTLPASSTHRUCHAR26,' ||
      ' :DTLPASSTHRUCHAR27,:DTLPASSTHRUCHAR28,' ||
      ' :DTLPASSTHRUCHAR29,:DTLPASSTHRUCHAR30,' ||
      ' :DTLPASSTHRUCHAR31,:DTLPASSTHRUCHAR32,' ||
      ' :DTLPASSTHRUCHAR33,:DTLPASSTHRUCHAR34,' ||
      ' :DTLPASSTHRUCHAR35,:DTLPASSTHRUCHAR36,' ||
      ' :DTLPASSTHRUCHAR37,:DTLPASSTHRUCHAR38,' ||
      ' :DTLPASSTHRUCHAR39,:DTLPASSTHRUCHAR40,' ||
      ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
      ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
      ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
      ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
      ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
      ' :DTLPASSTHRUNUM11,:DTLPASSTHRUNUM12,' ||
      ' :DTLPASSTHRUNUM13,:DTLPASSTHRUNUM14,' ||
      ' :DTLPASSTHRUNUM15,:DTLPASSTHRUNUM16,' ||
      ' :DTLPASSTHRUNUM17,:DTLPASSTHRUNUM18,' ||
      ' :DTLPASSTHRUNUM19,:DTLPASSTHRUNUM20,' ||
      ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
      ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
      ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
      ' :PO, :WEIGHT, :VOLUME, :DESCR, :ODQTYORDER, :ODQTYSHIP, '||
      ' :LINESEQ, :HAZARDOUS, :FROMLPIDLAST6, :FROMLPIDLAST7, '||
      ' :ITEMDESCR, :MANUFACTUREDATE, :SHIPPINGCOST, :SHIPPINGWEIGHT, '||
      ' :SERIALNUMBER, :LABELTYPE, :ITMPASSTHRUCHAR01, :EXPIRATIONDATE, '||
      ' :ITMPASSTHRUCHAR02, :ITMPASSTHRUCHAR03, :ITMPASSTHRUCHAR04, :ITMPASSTHRUCHAR05, '||
      ' :ITMPASSTHRUCHAR06, :ITMPASSTHRUCHAR07, :ITMPASSTHRUCHAR08, :ITMPASSTHRUCHAR09, '||
      ' :ITMPASSTHRUCHAR10, :ITMPASSTHRUNUM01, :ITMPASSTHRUNUM02, :ITMPASSTHRUNUM03, '||
      ' :ITMPASSTHRUNUM04, :ITMPASSTHRUNUM05, :ITMPASSTHRUNUM06, :ITMPASSTHRUNUM07, ' ||
      ' :ITMPASSTHRUNUM08, :ITMPASSTHRUNUM09, :ITMPASSTHRUNUM10, :INNERPACKQTY, ' ||
      ' :EA_TO_CS, :SHIPMENTSTATUSCODE, :QTYDIFFERENCE, :CARTONTYPE, ' ||
      ' :CSLENGTH, :CSWIDTH, :CSHEIGHT) '
      using
          SND.orderid,
          SND.shipid,
          SND.custid,
          SNC.lpid,
          SNC.fromlpid,
          SNC.plt_sscc18,
          SNC.ctn_sscc18,
          SNC.trackingno,
          SNC.link_plt_sscc18,
          SNC.link_ctn_sscc18,
          SNC.link_trackingno,
          SND.assignedid,
          SND.item,
          SND.lotnumber,
          SNC.link_lotnumber,
          SNC.useritem1,
          SNC.useritem2,
          SNC.useritem3,
          SND.qtyshipped,
          SND.uom,
          SNC.cartons,
          SND.dtlpassthruchar01,
          SND.dtlpassthruchar02,
          SND.dtlpassthruchar03,
          SND.dtlpassthruchar04,
          SND.dtlpassthruchar05,
          SND.dtlpassthruchar06,
          SND.dtlpassthruchar07,
          SND.dtlpassthruchar08,
          SND.dtlpassthruchar09,
          SND.dtlpassthruchar10,
          SND.dtlpassthruchar11,
          SND.dtlpassthruchar12,
          SND.dtlpassthruchar13,
          SND.dtlpassthruchar14,
          SND.dtlpassthruchar15,
          SND.dtlpassthruchar16,
          SND.dtlpassthruchar17,
          SND.dtlpassthruchar18,
          SND.dtlpassthruchar19,
          SND.dtlpassthruchar20,
          SND.dtlpassthruchar21,
          SND.dtlpassthruchar22,
          SND.dtlpassthruchar23,
          SND.dtlpassthruchar24,
          SND.dtlpassthruchar25,
          SND.dtlpassthruchar26,
          SND.dtlpassthruchar27,
          SND.dtlpassthruchar28,
          SND.dtlpassthruchar29,
          SND.dtlpassthruchar30,
          SND.dtlpassthruchar31,
          SND.dtlpassthruchar32,
          SND.dtlpassthruchar33,
          SND.dtlpassthruchar34,
          SND.dtlpassthruchar35,
          SND.dtlpassthruchar36,
          SND.dtlpassthruchar37,
          SND.dtlpassthruchar38,
          SND.dtlpassthruchar39,
          SND.dtlpassthruchar40,
          SND.dtlpassthrunum01,
          SND.dtlpassthrunum02,
          SND.dtlpassthrunum03,
          SND.dtlpassthrunum04,
          SND.dtlpassthrunum05,
          SND.dtlpassthrunum06,
          SND.dtlpassthrunum07,
          SND.dtlpassthrunum08,
          SND.dtlpassthrunum09,
          SND.dtlpassthrunum10,
          SND.dtlpassthrunum11,
          SND.dtlpassthrunum12,
          SND.dtlpassthrunum13,
          SND.dtlpassthrunum14,
          SND.dtlpassthrunum15,
          SND.dtlpassthrunum16,
          SND.dtlpassthrunum17,
          SND.dtlpassthrunum18,
          SND.dtlpassthrunum19,
          SND.dtlpassthrunum20,
          SND.dtlpassthrudate01,
          SND.dtlpassthrudate02,
          SND.dtlpassthrudate03,
          SND.dtlpassthrudate04,
          SND.dtlpassthrudoll01,
          SND.dtlpassthrudoll02,
          SND.po,
          SND.weight,
          SNC.volume,
          SND.description,
          SND.qtyordered,
          SND.qtyshipped,
          nullInt,
          SND.hazardous,
          nullVar,
          nullVar,
          strItemdescr,
          nullDate,
          nullNum,
          nullNum,
          nullVar,
          nullVar,
          nullVar,
          nullDate,
          nullVar, nullVar, nullvar, nullVar,
          nulLVar, nullVar, nullVar, nullVar,
          nullVar, nullNum, nullNum, nullNum,
          nullNum, nullNum, nullNum, nullNum,
          nullNum, nullNum, nullNum, nullNum,
          nullNum, nullVar, nullNum, nullVar,
          nullnum, nullNum, nullNum;
      end loop;
   close sn9d;
end if;

end; -- extract_by_id_contents;


procedure create_notes is
n_orderid orderdtl.orderid%type;
n_shipid orderdtl.shipid%type;
n_custid orderhdr.custid%type;
n_lineseq integer;
TYPE cur_typ is REF CURSOR;
croh cur_typ;
l_seq integer;
cmt varchar2(4001);
str varchar2(80);

len integer;
tpos integer;
tcur integer;
tcnt integer;

begin

debugmsg('creating 945 not');
cmdSql := 'create table SHIP_NOTE_945_not_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
 ' LINESEQ integer, COMMENT1 varchar2(57))';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdsql := 'select orderid, shipid, custid from ship_note_945_hdr_' || strSuffix;

if croh%isopen then
  close croh;
end if;
n_lineseq := 0;
open croh for cmdsql;
loop
   cmt := null;
   fetch croh into n_orderid, n_shipid, n_custid;
   exit when croh%notfound;
   select substr(comment1,1,4000) into cmt
      from orderhdr
      where orderid = n_orderid
        and shipid = n_shipid;
   debugmsg(cmt);
   select  instr(comment1, chr(12), 1) into tpos
      from orderhdr
      where orderid = n_orderid
        and shipid = n_shipid;
   debugmsg('[tpos ' || tpos);
   if cmt is not null then
      l_seq := 0;
      len := length(cmt);
      tcur := 1;
      while tcur < len loop
          l_seq := l_seq + 1;
          tpos := instr(cmt, chr(10), tcur);
          if tpos = 0 then
             tpos := len + 2;
          end if;
          tcnt := tpos - tcur - 1;
          --zut.prt(' tcur:'||tcur||' tpos:'||tpos||' tcnt:'||tcnt);
          if tcnt > 0 then
             str := substr(cmt,tcur, least(57,tcnt));
          else
             str := null;
          end if;
          tcur := tpos + 1;
          if  str is not null then
             n_lineseq := n_lineseq +1;
             execute immediate 'insert into ship_note_945_not_' || strSuffix || ' ' ||
                '(orderid, shipid, custid, lineseq, comment1) ' ||
                ' values (:ORDERID,:SHIPID,:CUSTID,:LINESEQ, :COMMENT1) '
                   using n_orderid, n_shipid,n_custid,n_lineseq,str;
          end if;
      end loop;
   end if;
end loop;


end create_notes;

procedure create_dtl_trackingno is
   d_orderid orderdtl.orderid%type;
   d_shipid orderdtl.shipid%type;
   d_custid orderhdr.custid%type;
   rowCnt number;

   d_weight orderdtl.weightship%type;
   d_qtyshipped orderdtl.qtyship%type;
   d_uom orderdtl.uom%type;
   d_item orderdtl.item%type;

   cursor C_MSP(in_orderid number, in_shipid number, in_item varchar2)
   IS
     select unitofmeasure, trackingno, sum(quantity) as quantity, sum(weight) as weight
    from shippingplate SP
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and type in ('F','P')
   group by unitofmeasure, trackingno;



   TYPE cur_typ is REF CURSOR;
   croh cur_typ;
   crod cur_typ;

 begin
    debugmsg('creating 945 dtlt');
    cmdSql := 'create table SHIP_NOTE_945_DTLT_' || strSuffix ||
    ' (ORDERID NUMBER(9) NOT NULL,SHIPID NUMBER(2) NOT NULL,'||
     ' CUSTID VARCHAR2(10), QTYSHIP NUMBER(13,4), UOM VARCHAR2(4),item varchar2(50) NOT NULL, '||
     ' WEIGHTSHIP NUMBER(17,8), TRACKINGNO VARCHAR2(30), FREIGHTCOST NUMBER(10,2))';
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);

    cmdsql := 'select orderid, shipid, custid from ship_note_945_hdr_' || strSuffix;

    if croh%isopen then
      close croh;
    end if;


    open croh for cmdsql;
    loop
       fetch croh into d_orderid, d_shipid, d_custid;
       exit when croh%notfound;
       select count(1) into rowCnt
          from shippingplate
          where orderid = d_orderid
            and shipid = d_shipid
            and trackingno is not null;
       debugmsg(d_orderid || ' - ' || d_shipid || ' - rc ' || rowCnt);
       cmdsql := 'select qtyshipped, uom, item, weight from ship_note_945_dtl_' || strSuffix ||
                 ' where orderid = ' || d_orderid ||' and shipid = ' || d_shipid;

       open crod for cmdsql;
       loop
          fetch crod into d_qtyshipped, d_uom, d_item, d_weight;
          exit when crod%notfound;
          if rowCnt = 0 then
             execute immediate 'insert into SHIP_NOTE_945_DTLT_' || strSuffix ||
                ' values (:ORDERID,:SHIPID,:CUSTID,:QTYSHIP,:UOM,:ITEM,:WEIGHTSHIP,:TRACKINGNO,:FREIGHTCOST) '
                using d_orderid, d_shipid,d_custid,d_qtyshipped,d_uom,d_item,d_weight,'',0;
          else
             for msp in C_MSP(d_orderid, d_shipid, d_item) loop
                --debugmsg('orderid ' || d_orderid);
                --debugmsg('shipid ' || d_shipid);
                --debugmsg('custid ' || d_custid);
                --debugmsg('qtyship ' || msp.quantity);
                --debugmsg('uom ' || msp.unitofmeasure);
                --debugmsg('item ' || d_item);
                --debugmsg('weight ' || msp.weight);
                --debugmsg('trackingno ' || msp.trackingno);
                --debugmsg('freightcost ' || zim14.freight_cost(d_orderid,d_shipid,d_item));
                if nvl(in_freight_cost_once_yn, 'N') = 'Y' then
                    execute immediate 'insert into SHIP_NOTE_945_DTLT_' || strSuffix ||
                       ' values (:ORDERID,:SHIPID,:CUSTID,:QTYSHIP,:UOM,:ITEM,:WEIGHTSHIP,:TRACKINGNO,:FREIGHTCOST) '
                       using d_orderid, d_shipid,d_custid,msp.quantity,msp.unitofmeasure,d_item,msp.weight,msp.trackingno,zim14.freight_cost_once(d_orderid,d_shipid);
                else
                execute immediate 'insert into SHIP_NOTE_945_DTLT_' || strSuffix ||
                   ' values (:ORDERID,:SHIPID,:CUSTID,:QTYSHIP,:UOM,:ITEM,:WEIGHTSHIP,:TRACKINGNO,:FREIGHTCOST) '
                   using d_orderid, d_shipid,d_custid,msp.quantity,msp.unitofmeasure,d_item,msp.weight,msp.trackingno,zim14.freight_cost(d_orderid,d_shipid,d_item);
                end if;
             end loop;
          end if;
       end loop;
    end loop;
    close croh;




end create_dtl_trackingno;

procedure create_cnt_fs is
   transDate varchar2(8);
   transTime varchar2(4);
begin
debugmsg('create_dtl_trackingno');
select to_char(sysdate, 'MMDDYYYY'), to_char(sysdate,'hh24mi')
   into transDate, transTime from dual;

cmdSql := 'create view SHIP_NOTE_945_FS_' || strSuffix ||
   '(custid, loadno, orderid, shipid, transaction_date, transaction_time, '||
    'item, itemdescr, reference, billoflading, ' ||
    'shipment_date, shipment_time, '||
    'arrivaldate, '||
    'carriername, '||
    'manufacturedate, assignedid, qty, uom, shiptoidcode, '||
    'shiptoname, shiptoaddr1, shiptoaddr2, shiptocity, shiptostate, ' ||
    'shiptopostalcode, shiptocountrycode, lpid, fromlpid, lotnumber, ' ||
    'total_lines, total_shipped, weight ) ' ||
    'as select o.custid, o.loadno, o.orderid, o.shipid, ''' || transDate || ''', ''' || transTime || ''',' ||
       'c.item, rtrim(c.itemdescr), o.reference, o.billoflading, '||
       'to_char(o.dateshipped,''MMDDYYYY''), to_char(o.dateshipped,''HH24MI''), '||
       'substr(o.deliverydate,7,2) || substr(o.deliverydate,5,2) || substr(o.deliverydate,1,4),'||
       'o.carrier_name, '||
       'to_char(c.manufacturedate, ''MMDDYYYY''), c.assignedid, c.qty, c.uom, o.shiptoidcode, '||
       'o.shiptoname, o.shiptoaddr1, o.shiptoaddr2, o.shiptocity, o.shiptostate, ' ||
       'o.shiptopostalcode, o.shiptocountrycode, c.lpid, c.fromlpid, c.lotnumber, ' ||
       '(select count(1) from SHIP_NOTE_945_CNT_' || strSuffix || ' where orderid = c.orderid and shipid = c.shipid),' ||
       '(select sum(qty) from SHIP_NOTE_945_CNT_' || strSuffix || ' where orderid = c.orderid and shipid = c.shipid),' ||
       'c.weight '||
    'from ship_note_945_cnt_' || strSuffix || ' c, ' ||
         'ship_note_945_hdr_' || strSuffix || ' o ' ||
    'where c.orderid = o.orderid '||
      'and c.shipid = o.shipid ';
debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


end create_cnt_fs;

procedure create_945_sn
is

l_cmd varchar2(4000);
dtlcur cur_type;
sncur cur_type;

type sn_rcd is record
(serialnumber shippingplate.serialnumber%type
,qtyremain shippingplate.quantity%type
);

type sn_tbl is table of sn_rcd
  index by binary_integer;
sns sn_tbl;
snx pls_integer;
snfoundx pls_integer;
dtl orderdtl%rowtype;
prev orderdtl%rowtype;
sndtl ship_note_945_sn%rowtype;

begin

  debugmsg('create_945_sn');
  prev.orderid := -1;
  prev.shipid := -1;
  l_cmd := 'select orderid,shipid,item,link_lotnumber,linenumber,qtyshipped from ' ||
            ' ship_note_945_dtl_' || strSuffix;
  open dtlcur for l_cmd;
  loop
    fetch dtlcur into dtl.orderid, dtl.shipid, dtl.item, dtl.lotnumber,dtl.dtlpassthrunum10,dtl.qtyship;
    exit when dtlcur%notfound;
    if dtl.orderid != prev.orderid or
       dtl.shipid != prev.shipid or
       dtl.item != prev.item or
       dtl.lotnumber != prev.lotnumber then
      sns.delete;
      prev.orderid := dtl.orderid;
      prev.shipid := dtl.shipid;
      prev.item := dtl.item;
      prev.lotnumber := dtl.lotnumber;
    end if;
    if dtl.qtyship = 0 then
      goto continue_dtlcur_loop;
    end if;
    l_cmd := 'select s.orderid, s.shipid, s.custid,';
    if nvl(in_abc_revisions_yn, 'n') = 'Y'  then
       l_cmd := l_cmd || 'zim7.abc_reference(oh.orderid, oh.shipid, ''' || in_abc_revisions_column ||'''),';
    else
       l_cmd := l_cmd || 'oh.reference,';
    end if;
    l_cmd := l_cmd || 'oh.po,s.item,'||
     ' s.lotnumber, s.quantity,s.unitofmeasure,s.weight, '||
     ' s.serialnumber, s.fromlpid, s.useritem1,s.useritem2,s.useritem3 '||
     'from shippingplate s, orderhdr oh';
    if nvl(in_allow_pick_status_yn,'N') = 'Y' then
        if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
          l_cmd := l_cmd || ' where oh.orderstatus in( ''6'',''7'',''8'',''9'') ';
        else
          l_cmd := l_cmd || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
        end if;
    else
      if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
        l_cmd := l_cmd || ' where oh.orderstatus = ''9'' ';
      else
        l_cmd := l_cmd || ' where oh.orderstatus in (''9'',''X'') ';
      end if;
   end if;
    if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
       l_cmd := l_cmd || ' and oh.xdockorderid is null ';
    end if;
    l_cmd := l_cmd ||
     ' and oh.orderid = s.orderid'||
     ' and oh.shipid = s.shipid'||
     ' and s.status = ''SH'''||
     ' and s.serialnumber is not null'||
     ' and s.orderid = ' || dtl.orderid ||
     ' and s.shipid = ' || dtl.shipid ||
     ' and s.item = ''' || dtl.item || '''';
    if dtl.lotnumber != '(none)' then
      l_cmd := l_cmd || ' and s.lotnumber = ''' || dtl.lotnumber || '''';
    end if;
    l_cmd := l_cmd || ' order by s.serialnumber';
    debugmsg('serial qry: ' || l_cmd);
    open sncur for l_cmd;
    loop
      fetch sncur into sndtl.ORDERID,sndtl.SHIPID,sndtl.CUSTID,sndtl.REFERENCE,sndtl.PO,sndtl.ITEM,sndtl.LOTNUMBER,sndtl.QUANTITY,
                       sndtl.UNITOFMEASURE,sndtl.LBS,sndtl.SERIALNUMBER,sndtl.FROMLPID,sndtl.USERITEM1,sndtl.USERITEM2,
                       sndtl.USERITEM3;
      exit when sncur%notfound;
      snfoundx := 0;
      for snx in 1 .. sns.count
      loop
        if sns(snx).serialnumber = sndtl.serialnumber then
          snfoundx := snx;
          exit;
        end if;
      end loop;
      if snfoundx = 0 then
        snfoundx := sns.count + 1;
        sns(snfoundx).serialnumber := sndtl.serialnumber;
        sns(snfoundx).qtyremain := sndtl.quantity;
      else
        if sns(snfoundx).qtyremain = 0 then
          goto continue_sncur_loop;
        end if;
      end if;
      if sns(snfoundx).qtyremain >= dtl.qtyship then
        sndtl.quantity := dtl.qtyship;
      else
        sndtl.quantity := sns(snfoundx).qtyremain;
      end if;
      execute immediate 'insert into ship_note_945_sn_' || strSuffix ||
        '  values ' ||
        ' (:ORDERID,:SHIPID,:CUSTID,:REFERENCE,:PO,:ITEM,:LOTNUMBER,:QUANTITY,' ||
        ' :UNITOFMEASURE,:LBS,:SERIALNUMBER,:FROMLPID,:USERITEM1,:USERITEM2,' ||
        ' :USERITEM3, :LINENUMBER, :DTLPASSTHRUNUM10)'
        using
        sndtl.ORDERID,sndtl.SHIPID,sndtl.CUSTID,sndtl.REFERENCE,sndtl.PO,sndtl.ITEM,sndtl.LOTNUMBER,
        sndtl.QUANTITY,sndtl.UNITOFMEASURE,sndtl.LBS,sndtl.SERIALNUMBER,sndtl.FROMLPID,sndtl.USERITEM1,
        sndtl.USERITEM2,sndtl.USERITEM3,dtl.DTLPASSTHRUNUM10,dtl.DTLPASSTHRUNUM10;
      sns(snfoundx).qtyremain := sns(snfoundx).qtyremain - sndtl.quantity;
      dtl.qtyship := dtl.qtyship - sndtl.quantity;
      if dtl.qtyship = 0 then
        exit;
      end if;
    <<continue_sncur_loop>>
      null;
    end loop;
    if sncur%isopen then
      close sncur;
    end if;
  <<continue_dtlcur_loop>>
    null;
  end loop;

  if dtlcur%isopen then
    close dtlcur;
  end if;

end create_945_sn;

procedure create_945_invoice
is
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_invoicenumber810 orderhdr.invoicenumber810%type;
l_invoicetotal810 orderhdr.invoiceamount810%type;
l_net orderhdr.invoiceamount810%type;
l_linetotal orderhdr.invoiceamount810%type;
l_item orderdtl.item%type;
l_lotnumber orderdtl.lotnumber%type;
l_qtyship orderdtl.qtyship%type;
l_unitcost orderdtl.dtlpassthrunum06%type;
l_sadtotal orderhdr.invoiceamount810%type;
l_sahtotal orderhdr.invoiceamount810%type;
l_inttotal integer;
l_comment1 clob;
l_reference orderhdr.reference%type;
l_custid orderhdr.custid%type;
l_po orderhdr.po%type;
l_seq integer;
cmt varchar2(4001);
str varchar2(255);
len integer;
tpos integer;
cpos integer;
tcur integer;
tcnt integer;

nullInt number;

cdSql varchar2(2000);
cl cur_type;
cd cur_type;
seqname varchar2(30);
cnt integer;

cursor curSAH (in_orderid number, in_shipid number) is
  select *
    from orderhdrsac
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curSAD (in_orderid number, in_shipid number,
               in_item in varchar2, in_lotnumber in varchar2) is
  select *
    from orderdtlsac
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

cursor curComment (in_orderid number, in_shipid number) is
   select comment1
     from orderhdr
    where orderid = in_orderid
      and shipid = in_shipid;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select item, lotnumber, qtyship, dtlpassthrudoll02, dtlpassthruchar01,
         dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,
         dtlpassthruchar05,dtlpassthruchar06,dtlpassthruchar07,
         dtlpassthruchar08,dtlpassthruchar09,dtlpassthruchar10, dtlpassthruchar11
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

PROCEDURE invoice945_update_orderhdr
   (in_orderid   in varchar2,
    in_shipid in varchar2,
    in_invoicenumber810 in number,
    in_invoicetotal810 in number)
is PRAGMA AUTONOMOUS_TRANSACTION;
begin
   update orderhdr
      set invoicenumber810 = in_invoicenumber810,
          invoiceamount810 = in_invoicetotal810
      where orderid = in_orderid
        and shipid = in_shipid;

   commit;

exception when others then
  rollback;
end invoice945_update_orderhdr;

begin
   debugmsg('create_945_invoice');
   nullInt := null;

   cmdSql := 'create table ship_note_945_ohi_' || strSuffix ||
      ' (custid varchar2(10), orderid number(9), shipid number(2), reference varchar2(20), '||
         ' po varchar2(20), seq number(16), comment1 varchar2(255))';
   debugmsg(cmdSql);
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);


   cmdSql := 'create table ship_note_945_sad_' || strSuffix ||
      ' (orderid number(9), shipid number(2), item varchar2(50), lotnumber varchar2(30), '||
       ' sac01 varchar2(255), sac02 varchar2(255), sac03 varchar2(255), sac04 varchar2(255), '||
       ' sac05 number(11,2), sac06 varchar2(255), sac07 varchar2(255), sac08 varchar2(255), '||
       ' sac09 varchar2(255), sac10 varchar2(255), sac11 varchar2(255), sac12 varchar2(255), '||
       ' sac13 varchar2(255), sac14 varchar2(255), sac15 varchar2(255), dtlpassthruchar01 varchar2(255),'||
       ' dtlpassthruchar02 varchar2(255), dtlpassthruchar03 varchar2(255), dtlpassthruchar04 varchar2(255),'||
       ' dtlpassthruchar05 varchar2(255), dtlpassthruchar06 varchar2(255), dtlpassthruchar07 varchar2(255),'||
       ' dtlpassthruchar08 varchar2(255), dtlpassthruchar09 varchar2(255), dtlpassthruchar10 varchar2(255),dtlpassthruchar11 varchar2(255))';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);

   cmdSql := 'create table ship_note_945_sah_' || strSuffix ||
      ' (orderid number(9), shipid number(2), '||
       ' sac01 varchar2(255), sac02 varchar2(255), sac03 varchar2(255), sac04 varchar2(255), '||
       ' sac05 number(11,2), sac06 varchar2(255), sac07 varchar2(255), sac08 varchar2(255), '||
       ' sac09 varchar2(255), sac10 varchar2(255), sac11 varchar2(255), sac12 varchar2(255), '||
       ' sac13 varchar2(255), sac14 varchar2(255), sac15 varchar2(255))';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);



   cmdSql := 'select orderid, shipid, invoicenumber810, reference, po, custid from ship_note_945_hdr_'||strSuffix;
   debugmsg(cmdSql);
   open cl for cmdsql;
   loop
      fetch cl into l_orderid, l_shipid, l_invoicenumber810, l_reference, l_po, l_custid;
      exit when cl%notfound;
      debugmsg('cl loop ' || l_orderid || '-' || l_shipid ||'i'||l_invoicenumber810);
      l_invoicetotal810 := 0;
      l_comment1 := null;
      open curComment(l_orderid, l_shipid);
      fetch curComment into l_comment1;
      close curComment;
      if l_comment1 is not null then
         l_seq := 0;
         cmt := substr(l_comment1,1,4000);
         len := length(cmt);
         tcur := 1;
         while tcur < len loop
             l_seq := l_seq + 1;
             tpos := instr(cmt, chr(10), tcur);
             if tpos = 0 then
                tpos := len + 2;
             end if;
             tcnt := tpos - tcur - 1;
             -- zut.prt(' tcur:'||tcur||' tpos:'||tpos||' tcnt:'||tcnt);

             if tcnt > 0 then
                str := substr(cmt,tcur, least(255,tcnt));
             else
                str := ' ';
             end if;
             tcur := tpos + 1;
             cpos := instr(str,'INV-');
             if cpos = 1  then
                execute immediate 'insert into ship_note_945_ohi_' || strSuffix ||
                   ' values (:custid, :orderid, :shipid, :reference, :po, :seq, :comment1) '
                   using l_custid, l_orderid, l_shipid, l_reference, l_po, l_seq, substr(str,5);
             end if;

         end loop;
      end if;


      debugmsg(l_invoicenumber810);
      for od in curOrderDtl(l_orderid, l_shipid) loop
         l_linetotal := nvl(od.qtyship,0) * nvl(od.dtlpassthrudoll02,0);
         debugmsg('cd '|| od.item || '>'|| od.lotnumber || '>'||od.qtyship || '>'||od.dtlpassthrudoll02 || '>'|| l_linetotal);

         for SAD in curSAD(l_orderid, l_shipid, od.item, od.lotnumber)  loop
            debugmsg('SAD ' || l_linetotal);
            if SAD.sac07 is not null then -- percent
               l_sadtotal := l_linetotal * to_number(SAD.sac07,'99999.99') / 100;
            else
               l_sadtotal := nvl(SAD.sac08,0); -- rate
            end if;
            debugmsg('sad total ' || l_sadtotal);
            if SAD.sac01 = 'C' then -- 'C' charge (+), 'A' allowance (-)
               l_linetotal := l_linetotal + l_sadtotal;
            else
               l_linetotal := l_linetotal - l_sadtotal;
            end if;
            l_inttotal := l_sadtotal * 100;
            debugmsg('int total ' || l_inttotal);
            execute immediate 'insert into SHIP_NOTE_945_SAD_' || strSuffix ||
               ' values (:orderid, :shipid, :item, :lotnumber, ' ||
                        ':sac01, :sac02, :sac03, :sac04, :sac05, ' ||
                        ':sac06, :sac07, :sac08, :sac94, :sac10, ' ||
                        ':sac11, :sac12, :sac13, :sac14, :sac15, :dtlpassthruchar01,'||
                        ':dltpassthruchar02, :dtlpassthruchar03, :dtlpassthruchar04,'||
                        ':dltpassthruchar05, :dtlpassthruchar06, :dtlpassthruchar07,'||
                        ':dltpassthruchar08, :dtlpassthruchar09, :dtlpassthruchar10, :dtlpassthruchar11) '
               using l_orderid, l_shipid, od.item, od.lotnumber,
                     SAD.sac01, SAD.sac02, nullInt, nullInt, l_sadtotal,
                     nullInt,nullInt,nullInt,nullInt,nullInt,
                     nullInt,nullInt,nullInt,nullInt,nullInt, od.dtlpassthruchar01,
                     od.dtlpassthruchar02,od.dtlpassthruchar03,od.dtlpassthruchar04,
                     od.dtlpassthruchar05,od.dtlpassthruchar06,od.dtlpassthruchar07,
                     od.dtlpassthruchar08,od.dtlpassthruchar09,od.dtlpassthruchar10, od.dtlpassthruchar11;
         end loop;
         l_invoicetotal810 := l_invoicetotal810 + l_linetotal;
      end loop; -- od

      debugmsg('invoice total after sad ' || l_invoicetotal810);
      l_net := l_invoicetotal810;
      for SAH in curSAH(l_orderid, l_shipid)  loop
         --debugmsg('SAH 01>' || SAH.sac01 || ' 02>' || SAH.sac02 || ' 03>' || SAH.sac03 || ' 04>' || SAH.sac04 || ' 05>' || SAH.sac05);
         --debugmsg('SAH 06>' || SAH.sac06 || ' 07>' || SAH.sac07 || ' 08>' || SAH.sac08 || ' 09>' || SAH.sac09 || ' 10>' || SAH.sac10);
         --debugmsg('SAH 11>' || SAH.sac11 || ' 12>' || SAH.sac12 || ' 13>' || SAH.sac13 || ' 14>' || SAH.sac14 || ' 01>' || SAH.sac15);
         if SAH.sac07 is not null then -- percent
            l_sahtotal := l_net * to_number(SAH.sac07,'99999.99') / 100;
         else
            l_sahtotal := nvl(SAH.sac08,0); -- rate
         end if;
         debugmsg('sah total ' || l_sahtotal);
         if SAH.sac01 = 'C' then -- 'C' charge (+), 'A' allowance (-)
            l_invoicetotal810 := l_invoicetotal810 + l_sahtotal;
         else
            l_invoicetotal810 := l_invoicetotal810 - l_sahtotal;
         end if;
         l_inttotal := l_sahtotal * 100;
         execute immediate 'insert into SHIP_NOTE_945_SAH_' || strSuffix ||
            ' values (:orderid, :shipid, ' ||
                     ':sac01, :sac02, :sac_03, :sac04, :sac05, ' ||
                     ':sac06, :sac07, :sac08, :sac94, :sac10, ' ||
                     ':sac11, :sac12, :sac13, :sac14, :sac15) '
            using l_orderid, l_shipid,
                  SAH.sac01, SAH.sac02, nullInt, nullInt, l_sahtotal,
                  nullInt,nullInt,nullInt,nullInt,nullInt,
                  nullInt,nullInt,nullInt,nullInt,nullInt;
         debugmsg('sah2');
      end loop;

      debugmsg('in_810_seq_by_custid: '|| in_810_seq_by_custid);
      if l_invoicenumber810 is null then
         if nvl(in_810_seq_by_custid, 'N') = 'Y' then
            seqname := 'INVOICE810_' || in_custid || '_SEQ';
            debugmsg('seqname: '|| seqname);
            select count(1)
              into cnt
              from user_sequences
              where sequence_name = seqname;
            if cnt = 0 then
              execute immediate 'create sequence ' || seqname
                    || ' increment by 1 start with 1 maxvalue 999999999 minvalue 1 nocache cycle';
            end if;
            execute immediate 'select '||seqname||'.nextval from dual'
              into l_invoicenumber810;
         else
         select invoice810seq.nextval into l_invoicenumber810 from dual;
         end if;
      end if;
      debugmsg('invoicenumber810: '|| l_invoicenumber810);
      invoice945_update_orderhdr(l_orderid, l_shipid, l_invoicenumber810, l_invoicetotal810);

   end loop; --for cl loop
   close cl;

end create_945_invoice;

procedure create_945_shipment is
co cur_type;
cor cur_type;
corSql varchar2(300);
l_shipment varchar2(255);
l_aux_shipment varchar2(255);
l_orderid number;
l_shipid number;
begin
   cmdSql := 'create table ship_note_945_shp_' || strSuffix ||
      ' (LINK_SHIPMENT VARCHAR2(255), LINK_AUX_SHIPMENT VARCHAR2(255), ORDERID NUMBER(9), SHIPID NUMBER(2)) ';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);

   cmdSql := 'select distinct link_shipment, link_aux_shipment from ship_note_945_hdr_' || strSuffix;
   open co for cmdSql;
   loop
      fetch co into l_shipment, l_aux_shipment;
      exit when co%notfound;
      corSql := 'select orderid, shipid from ship_note_945_hdr_' || strSuffix ||
                   ' where link_shipment = ''' || l_shipment || '''' ||
                   '   and link_aux_shipment = ''' || l_aux_shipment || '''' ||
                   ' order by orderid, shipid';
      open cor for corSql;
      fetch cor into l_orderid, l_shipid;
      close cor;
      execute immediate 'insert into SHIP_NOTE_945_shp_' || strSuffix ||
         ' values (:link_shipment, :link_aux_shipment, :orderid, :shipid)'
         using l_shipment, l_aux_shipment, l_orderid, l_shipid;
   end loop;
   close co;

   cmdSql := 'create view ship_note_945_bol_' || strSuffix ||
     ' (custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
     'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
     'width,length,shiptoidcode,'||
     'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
     'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
     'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
     'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
     'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
     'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
     'depositor_name,depositor_id,'||
     'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
     'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
     'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
     'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
     'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
     'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
     'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
     'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
     'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
     'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
     'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
     'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
     'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
     'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
     'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
     'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
     'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
     'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
     'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
     'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
     'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
     'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
     'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
     'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01 )'||
     ' as select ' ||
     'custid,company,warehouse,loadno,h.orderid,h.shipid,reference,trackingno,'||
     'dateshipped,commitdate,shipviacode, '||
     '(select sum(lbs) from ship_note_945_hdr_'|| strSuffix || ' where link_shipment = s.link_shipment),'||
     'kgs,gms,ozs,shipticket,height,'||
     'width,length,shiptoidcode,'||
     'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
     'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
     'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
     'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
     'splitshipno,invoicedate,effectivedate,'||
     '(select sum(totalunits) from ship_note_945_hdr_'|| strSuffix || ' where link_shipment = s.link_shipment),'||
     '(select sum(totalweight) from ship_note_945_hdr_'|| strSuffix || ' where link_shipment = s.link_shipment),'||
     'uomweight,'||
     '(select sum(totalvolume) from ship_note_945_hdr_'|| strSuffix || ' where link_shipment = s.link_shipment),'||
     'uomvolume,'||
     '(select sum(ladingqty) from ship_note_945_hdr_'|| strSuffix || ' where link_shipment = s.link_shipment),'||
     'uom,warehouse_name,warehouse_id,'||
     'depositor_name,depositor_id,'||
     'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
     'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
     'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
     'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
     'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
     'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
     'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
     'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
     'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
     'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
     'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
     'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
     'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
     'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
     'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
     'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
     'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
     'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
     'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
     'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
     'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
     'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
     'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
     'h.link_shipment, h.link_aux_shipment, h.CONSPASSTHRUCHAR01 '||
     ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
          ' ship_note_945_shp_' || strSuffix || ' s ' ||
          ' where h.orderid = s.orderid ' ||
             'and h.shipid = s.shipid';
   cntRows := 1;
   while (cntRows * 60) < (Length(cmdSql)+60)
   loop
     debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
     cntRows := cntRows + 1;
   end loop;

   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);

end create_945_shipment;
procedure create_945_shipment_by_tn --one asn per tracking number
is
   l_shiptype orderhdr.shiptype%type;
   procedure create_945_shipment_by_tn_load
   is
   begin
      cmdSql := 'create view ship_note_856_bol_' || strSuffix ||
        '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
        'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01)'||
        ' as select ' ||
        ' custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
        'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01'||
        ' from ship_note_945_bol_' || strSuffix;
      --cntRows := 1;
      --while (cntRows * 60) < (Length(cmdSql)+60)
      --loop
      --  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
      --  cntRows := cntRows + 1;
      --end loop;
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);
      cmdSql := 'create view ship_note_856_hdr_' || strSuffix ||
        '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
        'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01)'||
        ' as select ' ||
        'custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
        'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01'||
        ' from ship_note_945_hdr_' || strSuffix;
      --cntRows := 1;
      --while (cntRows * 60) < (Length(cmdSql)+60)
      --loop
      --  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
      --  cntRows := cntRows + 1;
      --end loop;
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);

      if nvl(in_id_passthru_yn,'N') = 'Y' then
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
                  '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
                  ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, dtlpassthrunum01, '||
                  ' dtlpassthrunum02, link_shipment, link_aux_shipment, ' ||
                  'length, width, height) ' ||
                  ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
                  ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.dtlpassthrunum01, i.dtlpsstrhunum02, '||
                  ' h.link_shipment, h.link_aux_shipment,' ||
                  ' i.length, i.width, i.height ' ||
           ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
                 'ship_note_945_id_' || strSuffix || ' i ' ||
                 ' where i.orderid = h.orderid and i.shipid = h.shipid ';
      else
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
                  '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
                  ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, link_shipment, link_aux_shipment,  ' ||
                  ' length, width, height, rmatrackingno )' ||
                  ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
                  ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, '||
                  ' h.link_shipment, h.link_aux_shipment, ' ||
                  ' i.length, i.width, i.height, i.rmatrackingno ' ||
           ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
                 'ship_note_945_id_' || strSuffix || ' i ' ||
                 ' where i.orderid = h.orderid and i.shipid = h.shipid ';
      end if;

      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);
   end create_945_shipment_by_tn_load;


   procedure create_945_shipment_by_tn_date
   is
   type cur_typ is ref cursor;
   crec cur_typ;
   oh ship_note_945_hdr%rowtype;

   begin
    debugmsg('create_945_shipment_by_tn_date');

    cmdSql := 'create view ship_note_856_hdr_' || strSuffix ||
        '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, link_shipment)'||
        ' as select ' ||
        'custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, link_shipment'||
        ' from ship_note_945_hdr_' || strSuffix ||
        ' where nvl(loadno,0) <> 0 or shiptype <> ''S'''||
        ' union ' ||
        ' select h.custid,h.company,h.warehouse,h.loadno,h.orderid,h.shipid,h.reference,';
    if nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
          cmdSql := cmdSql || ' i.trackingno, ';
    else
          cmdSql := cmdSql || ' h.trackingno, ';
    end if;
    cmdSql := cmdSql || 'h.dateshipped,h.commitdate,h.shipviacode,h.lbs,h.kgs,h.gms,h.ozs,h.shipticket,h.height,'||
        'h.width,h.length,h.shiptoidcode,'||
        'h.shiptoname,h.shiptocontact,h.shiptoaddr1,h.shiptoaddr2,'||
        'h.shiptocity,h.shiptostate,h.shiptopostalcode,h.shiptocountrycode,h.shiptophone,'||
        'h.carrier,h.carrier_name,h.packlistshipdate,h.routing,h.shiptype,h.shipterms,h.reportingcode,'||
        'h.depositororder,h.po,h.deliverydate,h.estdelivery,h.billoflading,h.prono,h.masterbol,'||
        'h.splitshipno,h.invoicedate,h.effectivedate,h.totalunits,h.totalweight,h.uomweight,'||
        'h.totalvolume,h.uomvolume,1,h.uom,h.warehouse_name,h.warehouse_id,'||
        'h.depositor_name,h.depositor_id,'||
        'h.HDRPASSTHRUCHAR01,h.HDRPASSTHRUCHAR02,h.HDRPASSTHRUCHAR03,h.HDRPASSTHRUCHAR04,'||
        'h.HDRPASSTHRUCHAR05,h.HDRPASSTHRUCHAR06,h.HDRPASSTHRUCHAR07,h.HDRPASSTHRUCHAR08,'||
        'h.HDRPASSTHRUCHAR09,h.HDRPASSTHRUCHAR10,h.HDRPASSTHRUCHAR11,h.HDRPASSTHRUCHAR12,'||
        'h.HDRPASSTHRUCHAR13,h.HDRPASSTHRUCHAR14,h.HDRPASSTHRUCHAR15,h.HDRPASSTHRUCHAR16,'||
        'h.HDRPASSTHRUCHAR17,h.HDRPASSTHRUCHAR18,h.HDRPASSTHRUCHAR19,h.HDRPASSTHRUCHAR20,'||
        'h.HDRPASSTHRUCHAR21,h.HDRPASSTHRUCHAR22,h.HDRPASSTHRUCHAR23,h.HDRPASSTHRUCHAR24,'||
        'h.HDRPASSTHRUCHAR25,h.HDRPASSTHRUCHAR26,h.HDRPASSTHRUCHAR27,h.HDRPASSTHRUCHAR28,'||
        'h.HDRPASSTHRUCHAR29,h.HDRPASSTHRUCHAR30,h.HDRPASSTHRUCHAR31,h.HDRPASSTHRUCHAR32,'||
        'h.HDRPASSTHRUCHAR33,h.HDRPASSTHRUCHAR34,h.HDRPASSTHRUCHAR35,h.HDRPASSTHRUCHAR36,'||
        'h.HDRPASSTHRUCHAR37,h.HDRPASSTHRUCHAR38,h.HDRPASSTHRUCHAR39,h.HDRPASSTHRUCHAR40,'||
        'h.HDRPASSTHRUCHAR41,h.HDRPASSTHRUCHAR42,h.HDRPASSTHRUCHAR43,h.HDRPASSTHRUCHAR44,'||
        'h.HDRPASSTHRUCHAR45,h.HDRPASSTHRUCHAR46,h.HDRPASSTHRUCHAR47,h.HDRPASSTHRUCHAR48,'||
        'h.HDRPASSTHRUCHAR49,h.HDRPASSTHRUCHAR50,h.HDRPASSTHRUCHAR51,h.HDRPASSTHRUCHAR52,'||
        'h.HDRPASSTHRUCHAR53,h.HDRPASSTHRUCHAR54,h.HDRPASSTHRUCHAR55,h.HDRPASSTHRUCHAR56,'||
        'h.HDRPASSTHRUCHAR57,h.HDRPASSTHRUCHAR58,h.HDRPASSTHRUCHAR59,h.HDRPASSTHRUCHAR60,'||
        'h.HDRPASSTHRUNUM01,h.HDRPASSTHRUNUM02,h.HDRPASSTHRUNUM03,h.HDRPASSTHRUNUM04,'||
        'h.HDRPASSTHRUNUM05,h.HDRPASSTHRUNUM06,h.HDRPASSTHRUNUM07,h.HDRPASSTHRUNUM08,'||
        'h.HDRPASSTHRUNUM09,h.HDRPASSTHRUNUM10,h.HDRPASSTHRUDATE01,h.HDRPASSTHRUDATE02,'||
        'h.HDRPASSTHRUDATE03,h.HDRPASSTHRUDATE04,h.HDRPASSTHRUDOLL01,h.HDRPASSTHRUDOLL02,'||
        'h.trailer,h.seal,h.palletcount,h.freightcost,h.lateshipreason,h.carrier_del_serv,' ||
        'h.shippingcost,h.prono_or_all_trackingnos,h.shipfrom_addr1,h.shipfrom_addr2,' ||
        'h.shipfrom_city,h.shipfrom_state,h.shipfrom_postalcode,h.invoicenumber810,'||
        'h.invoiceamount810,h.vicsbolnumber,h.scac,h.delivery_requested,h.authorizationnbr,';
    if nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
          cmdSql := cmdSql || ' i.trackingno '||
           ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
           '      ship_note_945_id_' || strSuffix || ' i '||
           ' where h.orderid = i.orderid and h.shipid = i.shipid ';
       if nvl(in_shp_no_load_assigned_sp_yn,'N') <> 'Y' then
          cmdSql := cmdSql ||
           ' and (nvl(h.loadno,0) = 0 or h.shiptype = ''S'')';
       else
          cmdSql := cmdSql ||
           ' and nvl(h.loadno,0) = 0';
       end if;
    else
       cmdSql := cmdSql || ' h.link_shipment ' ||
        ' from ship_note_945_hdr_' || strSuffix || ' h ';
       if nvl(in_shp_no_load_assigned_sp_yn,'N') <> 'Y' then
          cmdSql := cmdSql ||
          ' where (nvl(h.loadno,0) = 0 or h.shiptype = ''S'')';
       else
          cmdSql := cmdSql ||
          ' where nvl(h.loadno,0) = 0';
       end if;
    end if;
    cntRows := 1;
    while (cntRows * 60) < (Length(cmdSql)+60)
    loop
        debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
        cntRows := cntRows + 1;
    end loop;
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);

    cmdSql := 'create view ship_note_856_bol_' || strSuffix ||
        '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, link_shipment)'||
        ' as select ' ||
        ' custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
        'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
        'width,length,shiptoidcode,'||
        'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
        'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
        'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
        'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
        'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
        'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
        'depositor_name,depositor_id,'||
        'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
        'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
        'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
        'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
        'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
        'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
        'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
        'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
        'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
        'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
        'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
        'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
        'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
        'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
        'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
        'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
        'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
        'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
        'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
        'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
        'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
        'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
        'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, link_shipment'||
        ' from ship_note_945_bol_' || strSuffix ||
        ' where nvl(loadno,0) <> 0 and shiptype <> ''S''' ||
        ' union '||
        ' select ' ||
        'h.custid,h.company,h.warehouse,h.loadno,h.orderid,h.shipid,h.reference,h.trackingno,'||
        'h.dateshipped,h.commitdate,h.shipviacode,h.lbs,h.kgs,h.gms,h.ozs,h.shipticket,h.height,'||
        'h.width,h.length,h.shiptoidcode,'||
        'h.shiptoname,h.shiptocontact,h.shiptoaddr1,h.shiptoaddr2,'||
        'h.shiptocity,h.shiptostate,h.shiptopostalcode,h.shiptocountrycode,h.shiptophone,'||
        'h.carrier,h.carrier_name,h.packlistshipdate,h.routing,h.shiptype,h.shipterms,h.reportingcode,'||
        'h.depositororder,h.po,h.deliverydate,h.estdelivery,h.billoflading,h.prono,h.masterbol,'||
        'h.splitshipno,h.invoicedate,h.effectivedate,h.totalunits,h.totalweight,h.uomweight,'||
        'h.totalvolume,h.uomvolume,1,h.uom,h.warehouse_name,h.warehouse_id,'||
        'h.depositor_name,h.depositor_id,'||
        'h.HDRPASSTHRUCHAR01,h.HDRPASSTHRUCHAR02,h.HDRPASSTHRUCHAR03,h.HDRPASSTHRUCHAR04,'||
        'h.HDRPASSTHRUCHAR05,h.HDRPASSTHRUCHAR06,h.HDRPASSTHRUCHAR07,h.HDRPASSTHRUCHAR08,'||
        'h.HDRPASSTHRUCHAR09,h.HDRPASSTHRUCHAR10,h.HDRPASSTHRUCHAR11,h.HDRPASSTHRUCHAR12,'||
        'h.HDRPASSTHRUCHAR13,h.HDRPASSTHRUCHAR14,h.HDRPASSTHRUCHAR15,h.HDRPASSTHRUCHAR16,'||
        'h.HDRPASSTHRUCHAR17,h.HDRPASSTHRUCHAR18,h.HDRPASSTHRUCHAR19,h.HDRPASSTHRUCHAR20,'||
        'h.HDRPASSTHRUCHAR21,h.HDRPASSTHRUCHAR22,h.HDRPASSTHRUCHAR23,h.HDRPASSTHRUCHAR24,'||
        'h.HDRPASSTHRUCHAR25,h.HDRPASSTHRUCHAR26,h.HDRPASSTHRUCHAR27,h.HDRPASSTHRUCHAR28,'||
        'h.HDRPASSTHRUCHAR29,h.HDRPASSTHRUCHAR30,h.HDRPASSTHRUCHAR31,h.HDRPASSTHRUCHAR32,'||
        'h.HDRPASSTHRUCHAR33,h.HDRPASSTHRUCHAR34,h.HDRPASSTHRUCHAR35,h.HDRPASSTHRUCHAR36,'||
        'h.HDRPASSTHRUCHAR37,h.HDRPASSTHRUCHAR38,h.HDRPASSTHRUCHAR39,h.HDRPASSTHRUCHAR40,'||
        'h.HDRPASSTHRUCHAR41,h.HDRPASSTHRUCHAR42,h.HDRPASSTHRUCHAR43,h.HDRPASSTHRUCHAR44,'||
        'h.HDRPASSTHRUCHAR45,h.HDRPASSTHRUCHAR46,h.HDRPASSTHRUCHAR47,h.HDRPASSTHRUCHAR48,'||
        'h.HDRPASSTHRUCHAR49,h.HDRPASSTHRUCHAR50,h.HDRPASSTHRUCHAR51,h.HDRPASSTHRUCHAR52,'||
        'h.HDRPASSTHRUCHAR53,h.HDRPASSTHRUCHAR54,h.HDRPASSTHRUCHAR55,h.HDRPASSTHRUCHAR56,'||
        'h.HDRPASSTHRUCHAR57,h.HDRPASSTHRUCHAR58,h.HDRPASSTHRUCHAR59,h.HDRPASSTHRUCHAR60,'||
        'h.HDRPASSTHRUNUM01,h.HDRPASSTHRUNUM02,h.HDRPASSTHRUNUM03,h.HDRPASSTHRUNUM04,'||
        'h.HDRPASSTHRUNUM05,h.HDRPASSTHRUNUM06,h.HDRPASSTHRUNUM07,h.HDRPASSTHRUNUM08,'||
        'h.HDRPASSTHRUNUM09,h.HDRPASSTHRUNUM10,h.HDRPASSTHRUDATE01,h.HDRPASSTHRUDATE02,'||
        'h.HDRPASSTHRUDATE03,h.HDRPASSTHRUDATE04,h.HDRPASSTHRUDOLL01,h.HDRPASSTHRUDOLL02,'||
        'h.trailer,h.seal,h.palletcount,h.freightcost,h.lateshipreason,h.carrier_del_serv,' ||
        'h.shippingcost,h.prono_or_all_trackingnos,h.shipfrom_addr1,h.shipfrom_addr2,' ||
        'h.shipfrom_city,h.shipfrom_state,h.shipfrom_postalcode,h.invoicenumber810,'||
        'h.invoiceamount810, h.vicsbolnumber, h.scac, h.delivery_requested,h.authorizationnbr, h.link_shipment '||
        ' from ship_note_856_hdr_' || strSuffix || ' h '||
        ' where nvl(h.loadno,0) = 0 or h.shiptype = ''S''';
      cntRows := 1;
      while (cntRows * 60) < (Length(cmdSql)+60)
      loop
        debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
        cntRows := cntRows + 1;
      end loop;
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);

      if nvl(in_id_passthru_yn,'N') = 'Y' then
        if nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
            '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
            ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, dtlpassthrunum01, dtlpassthrunum02, link_shipment, ' ||
            ' length, width, height, rmatrackingno) ' ||
            ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
            ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.dtlpassthrunum01, i.dtlpsstrhunum02, i.link_trackingno, ' ||
            ' i.length, i.width, i.height, i.rmatrackingno '||
            ' from ship_note_945_id_' || strSuffix || ' i '||
            ' where exists (select (1) from ship_note_945_hdr_' || strSuffix ||' h '||
            '         where i.orderid = h.orderid and i.shipid = h.shipid'||
            '          and (nvl(h.loadno,0) = 0 or h.shiptype = ''S''))'||
            ' union '||
            ' select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
            ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.dtlpassthrunum01, i.dtlpsstrhunum02, h.link_shipment,' ||
            ' i.length, i.width, i.height, i.rmatrackingno ' ||
            ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
            ' ship_note_945_id_' || strSuffix || ' i ' ||
            ' where i.orderid = h.orderid and i.shipid = h.shipid '||
            ' and (nvl(h.loadno,0) <> 0 or h.shiptype <> ''S'')';
        else
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
                  '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
                  ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, dtlpassthrunum01, dtlpassthrunum02, link_shipment,  ' ||
                  ' length, width, height, rmatrackingno) ' ||
                  ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
                  ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.dtlpassthrunum01, i.dtlpsstrhunum02, h.link_shipment, ' ||
                  ' i.length, i.width, i.height, i.rmatrackingno ' ||
           ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
                 'ship_note_945_id_' || strSuffix || ' i ' ||
                 ' where i.orderid = h.orderid and i.shipid = h.shipid ';
        end if;
      else
        if nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
                  '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
                  ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, link_shipment,  ' ||
                  ' length, width, height, rmatrackingno) ' ||
                  ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
                  ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.link_trackingno, ' ||
                  ' i.length, i.width, i.height, i.rmatrackingno ' ||
            ' from ship_note_945_id_' || strSuffix || ' i '||
            ' where exists (select (1) from ship_note_945_hdr_' || strSuffix ||' h '||
            '         where i.orderid = h.orderid and i.shipid = h.shipid'||
            '          and (nvl(h.loadno,0) = 0 or h.shiptype = ''S''))'||
            ' union '||
            ' select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
            ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, h.link_shipment, ' ||
            ' i.length, i.width, i.height, i.rmatrackingno ' ||
            ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
            ' ship_note_945_id_' || strSuffix || ' i ' ||
            ' where i.orderid = h.orderid and i.shipid = h.shipid '||
            ' and (nvl(h.loadno,0) <> 0 or h.shiptype <> ''S'')';
        else
         cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
                  '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
                  ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, link_shipment ) ' ||
                  ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
                  ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, h.link_shipment, ' ||
                  ' i.length, i.width, i.height, i.rmatrackingno ' ||
           ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
                 'ship_note_945_id_' || strSuffix || ' i ' ||
                 ' where i.orderid = h.orderid and i.shipid = h.shipid ';
        end if;
      end if;
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curFunc);
      dbms_sql.close_cursor(curFunc);
      debugmsg(cmdSql);
   end create_945_shipment_by_tn_date;


begin

  if rtrim(in_begdatestr) is not null and
     nvl(in_create_945_shipment_yn,'N') = 'Y' then
       create_945_shipment_by_tn_date;
       goto finish_945_shipment_by_tn;
       return;
  elsif nvl(in_loadno,0) <> 0 then
      create_945_shipment_by_tn_load;
      if nvl(in_create_945_shipment_yn,'N') = 'Y' then
        goto finish_945_shipment_by_tn;
      end if;
      return;
  end if;

  begin
    select shiptype
      into l_shiptype
      from orderhdr
    where orderid = in_orderid
      and shipid = in_shipid;
  exception when others then
    l_shiptype := null;
  end;

  cmdSql := 'create view ship_note_856_hdr_' || strSuffix ||
    '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
    'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
    'width,length,shiptoidcode,'||
    'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
    'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
    'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
    'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
    'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
    'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
    'depositor_name,depositor_id,'||
    'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
    'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
    'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
    'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
    'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
    'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
    'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
    'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
    'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
    'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
    'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
    'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
    'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
    'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
    'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
    'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
    'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
    'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
    'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
    'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
    'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
    'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
    'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
    'link_shipment, link_aux_shipment, CONSPASSTHRUCHAR01)'||
    ' as select ' ||
    'h.custid,h.company,h.warehouse,h.loadno,h.orderid,h.shipid,h.reference,';

    if in_shipment_column is null and
       nvl(in_create_945_shipment_yn,'N') = 'Y' and
       nvl(l_shiptype,'none') = 'S' and
       nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
          cmdSql := cmdSql || ' i.trackingno, ';
    else
          cmdSql := cmdSql || ' h.trackingno, ';
    end if;

    cmdSql := cmdSql ||
    'h.dateshipped,h.commitdate,h.shipviacode,h.lbs,h.kgs,h.gms,h.ozs,h.shipticket,h.height,'||
    'h.width,h.length,h.shiptoidcode,'||
    'h.shiptoname,h.shiptocontact,h.shiptoaddr1,h.shiptoaddr2,'||
    'h.shiptocity,h.shiptostate,h.shiptopostalcode,h.shiptocountrycode,h.shiptophone,'||
    'h.carrier,h.carrier_name,h.packlistshipdate,h.routing,h.shiptype,h.shipterms,h.reportingcode,'||
    'h.depositororder,h.po,h.deliverydate,h.estdelivery,h.billoflading,h.prono,h.masterbol,'||
    'h.splitshipno,h.invoicedate,h.effectivedate,h.totalunits,h.totalweight,h.uomweight,'||
    'h.totalvolume,h.uomvolume,1,h.uom,h.warehouse_name,h.warehouse_id,'||
    'h.depositor_name,h.depositor_id,'||
    'h.HDRPASSTHRUCHAR01,h.HDRPASSTHRUCHAR02,h.HDRPASSTHRUCHAR03,h.HDRPASSTHRUCHAR04,'||
    'h.HDRPASSTHRUCHAR05,h.HDRPASSTHRUCHAR06,h.HDRPASSTHRUCHAR07,h.HDRPASSTHRUCHAR08,'||
    'h.HDRPASSTHRUCHAR09,h.HDRPASSTHRUCHAR10,h.HDRPASSTHRUCHAR11,h.HDRPASSTHRUCHAR12,'||
    'h.HDRPASSTHRUCHAR13,h.HDRPASSTHRUCHAR14,h.HDRPASSTHRUCHAR15,h.HDRPASSTHRUCHAR16,'||
    'h.HDRPASSTHRUCHAR17,h.HDRPASSTHRUCHAR18,h.HDRPASSTHRUCHAR19,h.HDRPASSTHRUCHAR20,'||
    'h.HDRPASSTHRUCHAR21,h.HDRPASSTHRUCHAR22,h.HDRPASSTHRUCHAR23,h.HDRPASSTHRUCHAR24,'||
    'h.HDRPASSTHRUCHAR25,h.HDRPASSTHRUCHAR26,h.HDRPASSTHRUCHAR27,h.HDRPASSTHRUCHAR28,'||
    'h.HDRPASSTHRUCHAR29,h.HDRPASSTHRUCHAR30,h.HDRPASSTHRUCHAR31,h.HDRPASSTHRUCHAR32,'||
    'h.HDRPASSTHRUCHAR33,h.HDRPASSTHRUCHAR34,h.HDRPASSTHRUCHAR35,h.HDRPASSTHRUCHAR36,'||
    'h.HDRPASSTHRUCHAR37,h.HDRPASSTHRUCHAR38,h.HDRPASSTHRUCHAR39,h.HDRPASSTHRUCHAR40,'||
    'h.HDRPASSTHRUCHAR41,h.HDRPASSTHRUCHAR42,h.HDRPASSTHRUCHAR43,h.HDRPASSTHRUCHAR44,'||
    'h.HDRPASSTHRUCHAR45,h.HDRPASSTHRUCHAR46,h.HDRPASSTHRUCHAR47,h.HDRPASSTHRUCHAR48,'||
    'h.HDRPASSTHRUCHAR49,h.HDRPASSTHRUCHAR50,h.HDRPASSTHRUCHAR51,h.HDRPASSTHRUCHAR52,'||
    'h.HDRPASSTHRUCHAR53,h.HDRPASSTHRUCHAR54,h.HDRPASSTHRUCHAR55,h.HDRPASSTHRUCHAR56,'||
    'h.HDRPASSTHRUCHAR57,h.HDRPASSTHRUCHAR58,h.HDRPASSTHRUCHAR59,h.HDRPASSTHRUCHAR60,'||
    'h.HDRPASSTHRUNUM01,h.HDRPASSTHRUNUM02,h.HDRPASSTHRUNUM03,h.HDRPASSTHRUNUM04,'||
    'h.HDRPASSTHRUNUM05,h.HDRPASSTHRUNUM06,h.HDRPASSTHRUNUM07,h.HDRPASSTHRUNUM08,'||
    'h.HDRPASSTHRUNUM09,h.HDRPASSTHRUNUM10,h.HDRPASSTHRUDATE01,h.HDRPASSTHRUDATE02,'||
    'h.HDRPASSTHRUDATE03,h.HDRPASSTHRUDATE04,h.HDRPASSTHRUDOLL01,h.HDRPASSTHRUDOLL02,'||
    'h.trailer,h.seal,h.palletcount,h.freightcost,h.lateshipreason,h.carrier_del_serv,' ||
    'h.shippingcost,h.prono_or_all_trackingnos,h.shipfrom_addr1,h.shipfrom_addr2,' ||
    'h.shipfrom_city,h.shipfrom_state,h.shipfrom_postalcode,h.invoicenumber810,'||
    'h.invoiceamount810,h.vicsbolnumber,h.scac,h.delivery_requested,h.authorizationnbr ';
  if in_shipment_column is null and
     nvl(in_create_945_shipment_yn,'N') = 'Y' and
     nvl(l_shiptype,'none') = 'S' and
     nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
        cmdSql := cmdSql || ' i.trackingno, link_aux_shipment, h.CONSPASSTHRUCHAR01 '||
         ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
         '      ship_note_945_id_' || strSuffix || ' i ';
  else
        cmdSql := cmdSql || ', h.link_shipment, link_aux_shipment, h.CONSPASSTHRUCHAR01 ' ||
         ' from ship_note_945_hdr_' || strSuffix || ' h ';
  end if;

  cntRows := 1;
  while (cntRows * 60) < (Length(cmdSql)+60)
  loop
    debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
    cntRows := cntRows + 1;
  end loop;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
  cmdSql := 'create view ship_note_856_bol_' || strSuffix ||
    '(custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
    'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
    'width,length,shiptoidcode,'||
    'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
    'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
    'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
    'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
    'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
    'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
    'depositor_name,depositor_id,'||
    'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
    'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
    'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
    'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
    'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
    'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
    'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
    'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
    'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
    'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
    'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
    'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
    'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
    'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
    'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
    'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
    'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
    'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
    'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
    'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
    'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
    'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
    'invoiceamount810, vicsbolnumber, scac, delivery_requested,authorizationnbr, '||
    'link_shipment,link_aux_shipment, CONSPASSTHRUCHAR01)'||
    ' as select ' ||
    'h.custid,h.company,h.warehouse,h.loadno,h.orderid,h.shipid,h.reference,h.trackingno,'||
    'h.dateshipped,h.commitdate,h.shipviacode,h.lbs,h.kgs,h.gms,h.ozs,h.shipticket,h.height,'||
    'h.width,h.length,h.shiptoidcode,'||
    'h.shiptoname,h.shiptocontact,h.shiptoaddr1,h.shiptoaddr2,'||
    'h.shiptocity,h.shiptostate,h.shiptopostalcode,h.shiptocountrycode,h.shiptophone,'||
    'h.carrier,h.carrier_name,h.packlistshipdate,h.routing,h.shiptype,h.shipterms,h.reportingcode,'||
    'h.depositororder,h.po,h.deliverydate,h.estdelivery,h.billoflading,h.prono,h.masterbol,'||
    'h.splitshipno,h.invoicedate,h.effectivedate,h.totalunits,h.totalweight,h.uomweight,'||
    'h.totalvolume,h.uomvolume,1,h.uom,h.warehouse_name,h.warehouse_id,'||
    'h.depositor_name,h.depositor_id,'||
    'h.HDRPASSTHRUCHAR01,h.HDRPASSTHRUCHAR02,h.HDRPASSTHRUCHAR03,h.HDRPASSTHRUCHAR04,'||
    'h.HDRPASSTHRUCHAR05,h.HDRPASSTHRUCHAR06,h.HDRPASSTHRUCHAR07,h.HDRPASSTHRUCHAR08,'||
    'h.HDRPASSTHRUCHAR09,h.HDRPASSTHRUCHAR10,h.HDRPASSTHRUCHAR11,h.HDRPASSTHRUCHAR12,'||
    'h.HDRPASSTHRUCHAR13,h.HDRPASSTHRUCHAR14,h.HDRPASSTHRUCHAR15,h.HDRPASSTHRUCHAR16,'||
    'h.HDRPASSTHRUCHAR17,h.HDRPASSTHRUCHAR18,h.HDRPASSTHRUCHAR19,h.HDRPASSTHRUCHAR20,'||
    'h.HDRPASSTHRUCHAR21,h.HDRPASSTHRUCHAR22,h.HDRPASSTHRUCHAR23,h.HDRPASSTHRUCHAR24,'||
    'h.HDRPASSTHRUCHAR25,h.HDRPASSTHRUCHAR26,h.HDRPASSTHRUCHAR27,h.HDRPASSTHRUCHAR28,'||
    'h.HDRPASSTHRUCHAR29,h.HDRPASSTHRUCHAR30,h.HDRPASSTHRUCHAR31,h.HDRPASSTHRUCHAR32,'||
    'h.HDRPASSTHRUCHAR33,h.HDRPASSTHRUCHAR34,h.HDRPASSTHRUCHAR35,h.HDRPASSTHRUCHAR36,'||
    'h.HDRPASSTHRUCHAR37,h.HDRPASSTHRUCHAR38,h.HDRPASSTHRUCHAR39,h.HDRPASSTHRUCHAR40,'||
    'h.HDRPASSTHRUCHAR41,h.HDRPASSTHRUCHAR42,h.HDRPASSTHRUCHAR43,h.HDRPASSTHRUCHAR44,'||
    'h.HDRPASSTHRUCHAR45,h.HDRPASSTHRUCHAR46,h.HDRPASSTHRUCHAR47,h.HDRPASSTHRUCHAR48,'||
    'h.HDRPASSTHRUCHAR49,h.HDRPASSTHRUCHAR50,h.HDRPASSTHRUCHAR51,h.HDRPASSTHRUCHAR52,'||
    'h.HDRPASSTHRUCHAR53,h.HDRPASSTHRUCHAR54,h.HDRPASSTHRUCHAR55,h.HDRPASSTHRUCHAR56,'||
    'h.HDRPASSTHRUCHAR57,h.HDRPASSTHRUCHAR58,h.HDRPASSTHRUCHAR59,h.HDRPASSTHRUCHAR60,'||
    'h.HDRPASSTHRUNUM01,h.HDRPASSTHRUNUM02,h.HDRPASSTHRUNUM03,h.HDRPASSTHRUNUM04,'||
    'h.HDRPASSTHRUNUM05,h.HDRPASSTHRUNUM06,h.HDRPASSTHRUNUM07,h.HDRPASSTHRUNUM08,'||
    'h.HDRPASSTHRUNUM09,h.HDRPASSTHRUNUM10,h.HDRPASSTHRUDATE01,h.HDRPASSTHRUDATE02,'||
    'h.HDRPASSTHRUDATE03,h.HDRPASSTHRUDATE04,h.HDRPASSTHRUDOLL01,h.HDRPASSTHRUDOLL02,'||
    'h.trailer,h.seal,h.palletcount,h.freightcost,h.lateshipreason,h.carrier_del_serv,' ||
    'h.shippingcost,h.prono_or_all_trackingnos,h.shipfrom_addr1,h.shipfrom_addr2,' ||
    'h.shipfrom_city,h.shipfrom_state,h.shipfrom_postalcode,h.invoicenumber810,'||
    'h.invoiceamount810, h.vicsbolnumber, h.scac, h.delivery_requested,h.authorizationnbr, '||
    'h.link_shipment, h.link_aux_shipment, CONSPASSTHRUCHAR01 '||
    ' from ship_note_856_hdr_' || strSuffix || ' h ';

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
  cntRows := 1;
  while (cntRows * 60) < (Length(cmdSql)+60)
  loop
    debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
    cntRows := cntRows + 1;
  end loop;
  if in_shipment_column is null and
     nvl(in_create_945_shipment_yn,'N') = 'Y' and
     nvl(l_shiptype,'none') != 'S' and
     nvl(in_945_shipment_single_bol_yn, 'N') = 'N' then
     cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
             '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
             ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, link_shipment, link_aux_shipment ) ' ||
             ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
             ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, i.link_trackingno, i.link_trackingno' ||
             ' from ship_note_945_id_' || strSuffix || ' i ';
  else
     cmdSql := 'create view SHIP_NOTE_856_ID_'|| strSuffix ||
              '(orderid, shipid, custid, lpid, fromlpid, plt_sscc18, ctn_sscc18, trackingno, '||
              ' link_plt_sscc18, link_ctn_sscc18, link_trackingno, cartons, link_shipment, link_aux_shipment ) ' ||
              ' as select i.orderid, i.shipid, i.custid, i.lpid, i.fromlpid, i.plt_sscc18, i.ctn_sscc18, i.trackingno, '||
              ' i.link_plt_sscc18, i.link_ctn_sscc18, i.link_trackingno, i.cartons, h.link_shipment, h.link_shipment' ||
              ' from ship_note_945_hdr_' || strSuffix || ' h, ' ||
              '      ship_note_945_id_' || strSuffix || ' i ' ||
              ' where i.orderid = h.orderid and i.shipid = h.shipid ';
  end if;

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);

<< finish_945_shipment_by_tn >>

  if nvl(in_create_945_shipment_yn,'N') = 'Y' then
    debugmsg('creating 856 cnt');
    cmdSql := 'create view ship_note_856_cnt_' || strSuffix ||
        ' (orderid,shipid, custid, lpid , fromlpid , plt_sscc18, '||
        ' ctn_sscc18 , trackingno, link_plt_sscc18 , link_ctn_sscc18, ' ||
        ' link_trackingno, assignedid , item, lotnumber ,link_lotnumber ,' ||
        ' useritem1 ,useritem2 ,useritem3 , qty , uom , cartons, ' ||
        ' DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,' ||
        ' DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,' ||
        ' DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,' ||
        ' DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,' ||
        ' DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,' ||
        ' DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23,DTLPASSTHRUCHAR24,' ||
        ' DTLPASSTHRUCHAR25,DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27,DTLPASSTHRUCHAR28,' ||
        ' DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,DTLPASSTHRUCHAR31,DTLPASSTHRUCHAR32,' ||
        ' DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35,DTLPASSTHRUCHAR36,' ||
        ' DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39,DTLPASSTHRUCHAR40,' ||
        ' DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,' ||
        ' DTLPASSTHRUNUM05,DTLPASSTHRUNUM06, DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,' ||
        ' DTLPASSTHRUNUM09,DTLPASSTHRUNUM10,DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,' ||
        ' DTLPASSTHRUNUM13,DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,DTLPASSTHRUNUM16,' ||
        ' DTLPASSTHRUNUM17,DTLPASSTHRUNUM18,DTLPASSTHRUNUM19,DTLPASSTHRUNUM20, DTLPASSTHRUDATE01, '||
        ' DTLPASSTHRUDATE02, DTLPASSTHRUDATE03 ,DTLPASSTHRUDATE04 ,DTLPASSTHRUDOLL01, DTLPASSTHRUDOLL02, '||
        ' po, weight, volume, descr, odqtyorder, odqtyship, serialnumber, '||
        ' link_shipment) '||
        ' as select ' ||
        ' c.orderid, c.shipid, c.custid, c.lpid, c.fromlpid, c.plt_sscc18, c.ctn_sscc18, c.trackingno, '||
        ' c.link_plt_sscc18, c.link_ctn_sscc18, c.link_trackingno, c.assignedid, c.item, c.lotnumber, '||
        ' c.link_lotnumber, c.useritem1, c.useritem2, c.useritem3, c.qty, c.uom, c.cartons, '||
        ' c.DTLPASSTHRUCHAR01, c.DTLPASSTHRUCHAR02, c.DTLPASSTHRUCHAR03, c.DTLPASSTHRUCHAR04, '||
        ' c.DTLPASSTHRUCHAR05, c.DTLPASSTHRUCHAR06, c.DTLPASSTHRUCHAR07, c.DTLPASSTHRUCHAR08, '||
        ' c.DTLPASSTHRUCHAR09, c.DTLPASSTHRUCHAR10, c.DTLPASSTHRUCHAR11, c.DTLPASSTHRUCHAR12, '||
        ' c.DTLPASSTHRUCHAR13, c.DTLPASSTHRUCHAR14, c.DTLPASSTHRUCHAR15, c.DTLPASSTHRUCHAR16, '||
        ' c.DTLPASSTHRUCHAR17, c.DTLPASSTHRUCHAR18, c.DTLPASSTHRUCHAR19, c.DTLPASSTHRUCHAR20, '||
        ' c.DTLPASSTHRUCHAR21, c.DTLPASSTHRUCHAR22, c.DTLPASSTHRUCHAR23, c.DTLPASSTHRUCHAR24, '||
        ' c.DTLPASSTHRUCHAR25, c.DTLPASSTHRUCHAR26, c.DTLPASSTHRUCHAR27, c.DTLPASSTHRUCHAR28, '||
        ' c.DTLPASSTHRUCHAR29, c.DTLPASSTHRUCHAR30, c.DTLPASSTHRUCHAR31, c.DTLPASSTHRUCHAR32, '||
        ' c.DTLPASSTHRUCHAR33, c.DTLPASSTHRUCHAR34, c.DTLPASSTHRUCHAR35, c.DTLPASSTHRUCHAR36, '||
        ' c.DTLPASSTHRUCHAR37, c.DTLPASSTHRUCHAR38, c.DTLPASSTHRUCHAR39, c.DTLPASSTHRUCHAR40, '||
        ' c.DTLPASSTHRUNUM01, c.DTLPASSTHRUNUM02, c.DTLPASSTHRUNUM03, c.DTLPASSTHRUNUM04, '||
        ' c.DTLPASSTHRUNUM05, c.DTLPASSTHRUNUM06, c.DTLPASSTHRUNUM07, c.DTLPASSTHRUNUM08, '||
        ' c.DTLPASSTHRUNUM09, c.DTLPASSTHRUNUM10, c.DTLPASSTHRUNUM11, c.DTLPASSTHRUNUM12, '||
        ' c.DTLPASSTHRUNUM13, c.DTLPASSTHRUNUM14, c.DTLPASSTHRUNUM15, c.DTLPASSTHRUNUM16, '||
        ' c.DTLPASSTHRUNUM17, c.DTLPASSTHRUNUM18, c.DTLPASSTHRUNUM19, c.DTLPASSTHRUNUM20, '||
        ' c.DTLPASSTHRUDATE01, c.DTLPASSTHRUDATE02, c.DTLPASSTHRUDATE03, c.DTLPASSTHRUDATE04, '||
        ' c.DTLPASSTHRUDOLL01, c.DTLPASSTHRUDOLL02, '||
        ' c.po, c.weight, c.volume, c.descr, c.odqtyorder, c.odqtyship, c.serialnumber, '||
        ' h.link_shipment '||
        ' from ship_note_856_hdr_' || strSuffix || ' h, ' ||
        '      ship_note_945_cnt_' || strSuffix || ' c ' ||
        ' where c.orderid = h.orderid and c.shipid = h.shipid ';
    debugmsg(cmdSql);
    curFunc := dbms_sql.open_cursor;
    dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
    cntRows := dbms_sql.execute(curFunc);
    dbms_sql.close_cursor(curFunc);

  end if;

end create_945_shipment_by_tn;


procedure create_dtllot is
DTL cur_type;
cmdSqlDTL varchar2(255);
ODL SHIP_NOTE_945_DTL%rowtype;
LOT cur_type;
cmdSqlLOT varchar2(255);
ODLOT SHIP_NOTE_945_LOT%rowtype;
begin
   debugmsg('begin create_dtllot');
   cmdSql := 'create table SHIP_NOTE_945_DLL_' || strSuffix ||
   ' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
   ' ASSIGNEDID NUMBER(16,4),SHIPTICKET VARCHAR2(15),TRACKINGNO VARCHAR2(81),' ||
   ' SERVICECODE VARCHAR2(4),LBS NUMBER(17,8),KGS NUMBER,GMS NUMBER,' ||
   ' OZS NUMBER,item varchar2(50) not null,LOTNUMBER VARCHAR2(30),' ||
   ' LINK_LOTNUMBER VARCHAR2(30),INVENTORYCLASS VARCHAR2(4),' ||
   ' STATUSCODE VARCHAR2(2),REFERENCE VARCHAR2(20),LINENUMBER VARCHAR2(255),' ||
   ' ORDERDATE DATE,PO VARCHAR2(20),QTYORDERED NUMBER(7),QTYSHIPPED NUMBER(7),' ||
   ' QTYDIFF NUMBER,UOM VARCHAR2(4),PACKLISTSHIPDATE DATE,WEIGHT NUMBER(17,8),' ||
   ' WEIGHTQUALIFIER CHAR(1),WEIGHTUNIT CHAR(1),DESCRIPTION VARCHAR2(255),' ||
   ' UPC VARCHAR2(20),DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
   ' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
   ' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),DTLPASSTHRUNUM03 NUMBER(16,4),' ||
   ' DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
   ' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),DTLPASSTHRUNUM09 NUMBER(16,4),' ||
   ' DTLPASSTHRUNUM10 NUMBER(16,4),DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
   ' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,DTLPASSTHRUDOLL01 NUMBER(10,2),' ||
   ' DTLPASSTHRUDOLL02 NUMBER(10,2), FROMLPID varchar2(15), smallpackagelbs number,'||
   ' deliveryservice varchar2(10), entereduom varchar2(4), qtyshippedEUOM number )';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);

   cmdSqlDTL := 'select * from ship_note_945_dtl_' || strSuffix;

   open DTL for cmdSqlDTL;
   loop
      fetch DTL into ODL;
      exit when DTL%notfound;
      debugmsg('ITM ' || ODL.orderid || ' ' || ODL.item || ' ' || ODL.qtyshipped || ' ' || ODL.linenumber);
      cmdSqlLOT := 'select * from ship_note_945_lot_' || strSuffix ||
                   ' where orderid = ' || ODL.orderid ||
                     ' and shipid = '  || ODL.shipid ||
                     ' and item = ''' || ODL.item || '''';
      if ODL.assignedid is not null then
         cmdSqlLOT := cmdSqlLOT || ' and assignedid = ' || ODL.assignedid;
      end if;
      --debugmsg(cmdSqlLOT);
      OPEN LOT for cmdSQLLOT;
      loop
         fetch LOT into ODLOT;
         exit when LOT%notfound;
         debugmsg('LOT ' || ODLOT.orderid || ' ' || ODLOT.shipid || ' ' || ODLOT.custid || ' ' ||
                  ODLOT.assignedid || ' ' || ODLOT.item || ' ' || ODLOT.lotnumber || ' ' ||
                  ODLOT.link_lotnumber || ' ' ||  ODLOT.qtyshipped || ' ' || ODLOT.qtyordered ||
                  ' ' || ODLOT.qtydiff || ' ' ||ODLOT.weightshipped);
         ODL.kgs := ODLOT.weightshipped / 2.2046;
         ODL.gms := ODLOT.weightshipped / .0022046;
         ODL.ozs := ODLOT.weightshipped * 16;

         curFunc := dbms_sql.open_cursor;
         dbms_sql.parse(curFunc, 'insert into ship_note_945_dll_' || strSuffix ||
         ' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,:SHIPTICKET,:TRACKINGNO,' ||
         ':SERVICECODE,:LBS,:KGS,:GMS,:OZS,:ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
         ':INVENTORYCLASS,' ||
         ':STATUSCODE,:REFERENCE,:LINENUMBER,:ORDERDATE,:PO,:QTYORDERED,:QTYSHIPPED,' ||
         ':QTYDIFF,:UOM,:PACKLISTSHIPDATE,:WEIGHT,:WEIGHTQUALIFIER,:WEIGHTUNIT,' ||
         ':DESCRIPTION,:UPC,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,' ||
         ':DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,' ||
         ':DTLPASSTHRUCHAR08,:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,' ||
         ':DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,' ||
         ':DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,' ||
         ':DTLPASSTHRUCHAR20,:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,' ||
         ':DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,' ||
         ':DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,' ||
         ':DTLPASSTHRUDATE02,:DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,' ||
         ':DTLPASSTHRUDOLL02, :FROMLPID, :SMALLPACKAGELBS, :DELIVERYSERVICE, ' ||
         ':ENTEREDUOM, :QTYSHIPPEDUOM)',
           dbms_sql.native);
         dbms_sql.bind_variable(curFunc, ':ORDERID', ODL.ORDERID);
         dbms_sql.bind_variable(curFunc, ':SHIPID', ODL.SHIPID);
         dbms_sql.bind_variable(curFunc, ':CUSTID', ODL.CUSTID);
         dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ODL.dtlpassthrunum10);
         dbms_sql.bind_variable(curFunc, ':SHIPTICKET', ODL.SHIPTICKET);
         dbms_sql.bind_variable(curFunc, ':TRACKINGNO', ODL.TRACKINGNO);
         dbms_sql.bind_variable(curFunc, ':SERVICECODE', ODL.deliveryservice);
         dbms_sql.bind_variable(curFunc, ':LBS', ODLOT.weightshipped);
         dbms_sql.bind_variable(curFunc, ':KGS', ODL.kgs);
         dbms_sql.bind_variable(curFunc, ':GMS', ODL.gms);
         dbms_sql.bind_variable(curFunc, ':OZS', ODL.ozs);
         dbms_sql.bind_variable(curFunc, ':ITEM', ODL.ITEM);
         dbms_sql.bind_variable(curFunc, ':LOTNUMBER', ODLOT.lotnumber);
         dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', ODLOT.lotnumber);
         dbms_sql.bind_variable(curFunc, ':INVENTORYCLASS', ODL.inventoryclass);
         dbms_sql.bind_variable(curFunc, ':STATUSCODE', ODL.statuscode);
         dbms_sql.bind_variable(curFunc, ':REFERENCE', ODL.reference);
         dbms_sql.bind_variable(curFunc, ':LINENUMBER', ODL.linenumber);
         dbms_sql.bind_variable(curFunc, ':ORDERDATE', ODL.orderdate);
         dbms_sql.bind_variable(curFunc, ':PO', ODL.po);
         dbms_sql.bind_variable(curFunc, ':QTYORDERED', ODLOT.qtyordered);
         dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', ODLOT.qtyshipped);
         dbms_sql.bind_variable(curFunc, ':QTYDIFF', ODLOT.qtydiff);
         dbms_sql.bind_variable(curFunc, ':UOM', ODL.UOM);
         dbms_sql.bind_variable(curFunc, ':PACKLISTSHIPDATE', ODL.packlistshipdate);
         dbms_sql.bind_variable(curFunc, ':WEIGHT', ODLOT.weightshipped);
         dbms_sql.bind_variable(curFunc, ':WEIGHTQUALIFIER', ODL.weightquaifier);
         dbms_sql.bind_variable(curFunc, ':WEIGHTUNIT', ODL.weightunit);
         dbms_sql.bind_variable(curFunc, ':DESCRIPTION', ODL.description);
         dbms_sql.bind_variable(curFunc, ':UPC', ODL.upc);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ODL.dtlpassthruchar01);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ODL.dtlpassthruchar02);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ODL.dtlpassthruchar03);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ODL.dtlpassthruchar04);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ODL.dtlpassthruchar05);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ODL.dtlpassthruchar06);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ODL.dtlpassthruchar07);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ODL.dtlpassthruchar08);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ODL.dtlpassthruchar09);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ODL.dtlpassthruchar10);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ODL.dtlpassthruchar11);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ODL.dtlpassthruchar12);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ODL.dtlpassthruchar13);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ODL.dtlpassthruchar14);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ODL.dtlpassthruchar15);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ODL.dtlpassthruchar16);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ODL.dtlpassthruchar17);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ODL.dtlpassthruchar18);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ODL.dtlpassthruchar19);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ODL.dtlpassthruchar20);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ODL.dtlpassthrunum01);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ODL.dtlpassthrunum02);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ODL.dtlpassthrunum03);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ODL.dtlpassthrunum04);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ODL.dtlpassthrunum05);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ODL.dtlpassthrunum06);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ODL.dtlpassthrunum07);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ODL.dtlpassthrunum08);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ODL.dtlpassthrunum09);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ODL.dtlpassthrunum10);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ODL.dtlpassthrudate01);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ODL.dtlpassthrudate02);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ODL.dtlpassthrudate03);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ODL.dtlpassthrudate04);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ODL.dtlpassthrudoll01);
         dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ODL.dtlpassthrudoll02);
         dbms_sql.bind_variable(curFunc, ':FROMLPID', ODL.fromlpid);
         dbms_sql.bind_variable(curFunc, ':SMALLPACKAGELBS', ODL.smallpackagelbs);
         dbms_sql.bind_variable(curFunc, ':DELIVERYSERVICE', ODL.deliveryservice);
         dbms_sql.bind_variable(curFunc, ':ENTEREDUOM', ODL.entereduom);
         dbms_sql.bind_variable(curFunc, ':QTYSHIPPEDUOM',
            zcu.equiv_uom_qty(ODL.custid,ODL.item,ODL.uom,ODL.qtyShipped,ODL.entereduom));
         cntRows := dbms_sql.execute(curFunc);
         dbms_sql.close_cursor(curFunc);

      end loop;
      close LOT;
   end loop;
   close DTL;
end create_dtllot;

procedure  create_cfs is
begin
debugmsg('create cfs');
cmdSql := 'create or replace view ship_note_945_cfsh_' || strSuffix ||
    '(facility, custid, loadno, carrier, authorizationnbr, dateshipped) '||
    ' as '||
    ' select warehouse_id, custid, loadno, '||
    '        carrier, authorizationnbr, dateshipped '||
    '  from ship_note_945_hdr_' || strSuffix ||
    ' group by warehouse_id, custid, loadno, carrier, authorizationnbr, dateshipped';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create or replace view ship_note_945_cfsd_' || strSuffix ||
   '( loadno, orderid, shipid, custid, reference, lotnumber, qtyshipped) '||
    ' as '||
    ' select h.loadno, h.orderid, h.shipid, h.custid, h.reference,'||
    '       nvl(d.lotnumber,''none'') as lotnumber, '||
    '       sum(d.qtyshipped) as qtyshipped '||
    '  from ship_note_945_hdr_' || strSuffix || ' h, '||
    '       ship_note_945_dtl_' || strSuffix || ' d ' ||
    ' where h.orderid = d.orderid '||
    '   and d.shipid = d.shipid' ||
    ' group by h.loadno, h.orderid, h.shipid, h.custid, h.reference, nvl(d.lotnumber,''none'')';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end create_cfs;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIP_NOTE_945_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' and oh.orderid = '||to_char(in_orderid)
                 || ' and oh.shipid = '||to_char(in_shipid)
                 || ' ';
  elsif in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';

  debugmsg('enforce edi ' || in_enforce_edi_trans_yn || ' <> ' || cu.sipconsigneematchfield ||
           ' <> ' || in_transaction || ' <> ' || nvl(in_orderid,0));
  if nvl(in_enforce_edi_trans_yn,'N') = 'Y' and
     cu.sipconsigneematchfield is not null and
     nvl(in_transaction,'000') in ('810','856','945') and
     nvl(in_orderid,0) = 0 then  -- if small package we already know to produce the export or we wouldn't have got this far
      l_condition := l_condition || ' and zim7.check_edi(oh.orderid, oh.shipid, oh.custid, ''' || in_transaction || ''',' ||
                                                    '''' ||cu.sipconsigneematchfield||''') = ''Y''';
  end if;

  debugmsg('Condition = '||l_condition);

  -- Create header view
cmdSql := 'create view ship_note_945_hdr_' || strSuffix ||
  ' (custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
  'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
  'width,length,shiptoidcode,'||
  'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
  'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
  'billtoidcode,billtoname,billtocontact,billtoaddr1,billtoaddr2,billtocity,billtostate,'||
  'billtopostalcode,billtocountrycode,billtophone,billtofax,billtoemail,'||
  'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
  'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
  'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
  'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
  'depositor_name,depositor_id,'||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
  'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
  'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
  'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
  'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
  'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
  'shippingcost, prono_or_all_trackingnos, ship_plate_count, shipfrom_addr1, shipfrom_addr2,' ||
  'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
  'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, '||
  'link_shipment, link_aux_shipment,'||
  'sscccount,shipment, ' ||
  'amtcod, consignee, custaddr1, custaddr2, custcity, custstate, custpostalcode, entrydate, '||
  'CONSPASSTHRUCHAR01, ldpassthruchar01,ldpassthruchar02,ldpassthruchar03,ldpassthruchar04,'||
  'ldpassthruchar05,ldpassthruchar06,ldpassthruchar07,ldpassthruchar08,'||
  'ldpassthruchar09,ldpassthruchar10,ldpassthruchar11,ldpassthruchar12,'||
  'ldpassthruchar13,ldpassthruchar14,ldpassthruchar15,ldpassthruchar16,'||
  'ldpassthruchar17,ldpassthruchar18,ldpassthruchar19,ldpassthruchar20,'||
  'ldpassthruchar21,ldpassthruchar22,ldpassthruchar23,ldpassthruchar24,'||
  'ldpassthruchar25,ldpassthruchar26,ldpassthruchar27,ldpassthruchar28,'||
  'ldpassthruchar29,ldpassthruchar30,ldpassthruchar31,ldpassthruchar32,'||
  'ldpassthruchar33,ldpassthruchar34,ldpassthruchar35,ldpassthruchar36,'||
  'ldpassthruchar37,ldpassthruchar38,ldpassthruchar39,ldpassthruchar40,'||
  'ldpassthrunum01,ldpassthrunum02,ldpassthrunum03,ldpassthrunum04,ldpassthrunum05,'||
  'ldpassthrunum06,ldpassthrunum07,ldpassthrunum08,ldpassthrunum09,ldpassthrunum10,'||
  'ldpassthrudate01,ldpassthrudate02,ldpassthrudate03,ldpassthrudate04, doorloc, cheppallets, '||
  'lsshipto,shipfromcountrycode,customername,customercountrycode,vicssubbol,vicsminbol, '||
  'totqtyshipped,totqtyordered,qtydifference,cancelafter,requestedship,shipnotbefore, ' ||
  'shipnolater,cancelifnotdelivdby,donotdeliverafter,donotdeliverbefore,cancelleddate, '||
  'woodpallets,conspassthruchar02,conspassthruchar03, ' ||
  'conspassthruchar04,conspassthruchar05,conspassthruchar06,conspassthruchar07, ' ||
  'conspassthruchar08,conspassthruchar09,conspassthruchar10, interlinecarrier) '||
  'as select ' ||
  'oh.custid,'' '','' '',oh.loadno,oh.orderid,oh.shipid,';

if nvl(in_abc_revisions_yn, 'n') = 'Y'  then
   cmdSql := cmdSql || 'zim7.abc_reference(oh.orderid, oh.shipid, ''' || in_abc_revisions_column ||'''),';
else
   cmdSql := cmdSql || 'oh.reference,';
end if;
if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid)))))),';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid)))),';
end if;
cmdSql := cmdSql ||
  'oh.statusupdate,oh.shipdate,nvl(deliveryservice,''OTHR''),'||
  'zim7.sum_shipping_weight(orderid,shipid),'||
  'zim7.sum_shipping_weight(orderid,shipid) / 2.2046,'||
  'zim7.sum_shipping_weight(orderid,shipid) / .0022046,'||
  'zim7.sum_shipping_weight(orderid,shipid) * 16,'||
  'substr(zoe.max_shipping_container(orderid,shipid),1,15),'||
  'zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),'||
  'oh.shipto,'||
  'decode(CN.consignee,null,shiptoname,CN.name),'||
  'decode(CN.consignee,null,shiptocontact,CN.contact),'||
  'decode(CN.consignee,null,shiptoaddr1,CN.addr1),'||
  'decode(CN.consignee,null,shiptoaddr2,CN.addr2),'||
  'decode(CN.consignee,null,shiptocity,CN.city),'||
  'decode(CN.consignee,null,shiptostate,CN.state),'||
  'decode(CN.consignee,null,shiptopostalcode,CN.postalcode),'||
  'decode(CN.consignee,null,shiptocountrycode,CN.countrycode),'||
  'decode(CN.consignee,null,shiptophone,CN.phone),'||
  'oh.consignee,'||
  'decode(BCN.consignee,null,billtoname,BCN.name),'||
  'decode(BCN.consignee,null,billtocontact,BCN.contact),'||
  'decode(BCN.consignee,null,billtoaddr1,BCN.addr1),'||
  'decode(BCN.consignee,null,billtoaddr2,BCN.addr2),'||
  'decode(BCN.consignee,null,billtocity,BCN.city),'||
  'decode(BCN.consignee,null,billtostate,BCN.state),'||
  'decode(BCN.consignee,null,billtopostalcode,BCN.postalcode),'||
  'decode(BCN.consignee,null,billtocountrycode,BCN.countrycode),'||
  'decode(BCN.consignee,null,billtophone,BCN.phone),'||
  'decode(BCN.consignee,null,billtofax,BCN.fax),'||
  'decode(BCN.consignee,null,billtoemail,BCN.email),'||
  'oh.carrier,ca.name,'||
  '''  '',oh.hdrpassthruchar06,oh.shiptype,oh.shipterms,''A'',';
if nvl(in_abc_revisions_yn, 'n') = 'Y'  then
   cmdSql := cmdSql || 'zim7.abc_reference(oh.orderid, oh.shipid, ''' || in_abc_revisions_column ||'''),';
else
   cmdSql := cmdSql || 'oh.reference,';
end if;

cmdSql := cmdSql || ' oh.po,oh.hdrpassthruchar07,';

if nvl(in_estdelivery_validation_tbl,'(none)') != '(none)' then
   cmdSql := cmdSql || 'zim7.facility_arrival_date(oh.dateshipped,oh.hdrpassthruchar12,''' || in_estdelivery_validation_tbl || '''),';
else
   if nvl(in_force_estdelivery_yn,'N') = 'Y' then
      cmdSql := cmdSql || 'trunc(oh.dateshipped + 5),';
   else
      cmdSql := cmdSql || 'oh.arrivaldate,';
   end if;
end if;
cmdSql := cmdSql ||  'decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),'||
  'nvl(oh.billoflading,nvl(L.billoflading,to_char(oh.orderid)||''-''||to_char(oh.shipid)))),'||
  'nvl(oh.prono,L.prono),';
  if nvl(in_masterbol_column,'(none)') <> '(none)' then
     cmdSql := cmdSql || 'nvl(' || in_masterbol_column ||', decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null)),';
  else
     cmdSql := cmdSql || 'decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null),'; --masterbol
  end if;
  cmdSql := cmdSql || 'decode(zim7.split_shipment(oh.custid, oh.reference),''Y'',oh.reference,null),'|| --splitshipno
  'oh.dateshipped,oh.dateshipped,oh.qtyship,'|| --invoicedate, effectivedate, totalunits
  'zim7.sum_shipping_weight(orderid,shipid),''LB'',oh.cubeship,''CF'',ordercheckview_cartons(oh.orderid, oh.shipid),''CT'','||--totalweight, uomweight, totalvolume,uomvolume,ladingqty, uom
  'F.name,F.facility,C.name,'' '','|| --warehousename, warehouseid, depositorname, depositorid
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
  'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
  'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
  'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
  'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,'||
  'HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,' ||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,' ||
  'L.trailer,L.seal,'||
  'zim7.pallet_count(oh.loadno,oh.custid,oh.fromfacility,oh.orderid,oh.shipid), ';
if rtrim(in_ltl_freight_passthru) is not null then
  if nvl(in_freight_cost_once_yn, 'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
     'zim14.freight_cost_once(oh.orderid,oh.shipid),oh.'||
     in_ltl_freight_passthru || ') ';
  else
     cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'zim14.freight_total(oh.orderid,oh.shipid,null,null),oh.'||
  in_ltl_freight_passthru || ') ';
  end if;
else
  if nvl(in_freight_cost_once_yn, 'N') = 'Y' then
     cmdSql := cmdSql || 'zim14.freight_cost_once(oh.orderid,oh.shipid) ';
  else
  cmdSql := cmdSql || 'zim14.freight_total(oh.orderid,oh.shipid,null,null) ';
  end if;
end if;

cmdSql := cmdSql || ', L.lateshipreason, OH.carrier||OH.deliveryservice,'
 ||'OH.shippingcost, ';

if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid, ''' || in_track_separator || '''),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid))))))';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid, ''' || in_track_separator || '''),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid))))';
end if;


if in_track_separator is not null then
   cmdSql := cmdSql || ' || ''' || in_track_separator || '''';
end if;

cmdSQL := cmdSQL || ', zim7.ship_plate_count(oh.orderid, oh.shipid),F.addr1,F.addr2,F.city,F.state,F.postalcode, oh.invoicenumber810, '||
                    'oh.invoiceamount810,zim7.VICSbolNumber(oh.loadno,oh.orderid,oh.shipid,oh.custid),' ||
                    'ca.scac, oh.delivery_requested, L.ldpassthruchar01, ';

if in_shipment_column is null and
  nvl(in_create_945_shipment_yn,'N') = 'N' then
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdsql || '''' ||  to_char(in_orderid) || to_char(in_shipid)|| ''' ';
   else
      cmdSql := cmdsql || '''' ||  to_char(in_loadno) || ''' ';
   end if;
elsif in_shipment_column is null and
  nvl(in_create_945_shipment_yn,'N') = 'Y' then
   if rtrim(in_begdatestr) is not null then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              ' decode(nvl(oh.loadno,0), 0, '||
                              ' to_char(oh.orderid) || to_char(oh.shipid),'||
                              ' to_char(oh.loadno))) ';
   else
     if nvl(in_loadno,0) = 0 then
        cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              '''' || to_char(in_orderid) || to_char(in_shipid)|| ''') ';
     else
        cmdSql := cmdSql || '''' ||to_char(in_loadno)|| '''';
     end if;
   end if;
else
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              'nvl(oh.' || in_shipment_column ||',''' || to_char(in_orderid) || to_char(in_shipid)|| ''' )) ';
   else
      cmdSql := cmdSql || 'nvl(oh.' || in_shipment_column ||
                          ',''' ||  to_char(in_loadno)|| ''' )';
   end if;
end if;
cmdSql := cmdSql || ',';
if in_aux_shipment_column is null and
  nvl(in_create_945_shipment_yn,'N') = 'N' then
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdsql || '''' ||  to_char(in_orderid) || to_char(in_shipid)|| ''' ';
   else
      cmdSql := cmdsql || '''' ||  to_char(in_loadno) || ''' ';
   end if;
elsif in_aux_shipment_column is null and
  nvl(in_create_945_shipment_yn,'N') = 'Y' then
   if rtrim(in_begdatestr) is not null then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              ' decode(nvl(oh.loadno,0), 0, '||
                              ' to_char(oh.orderid) || to_char(oh.shipid),'||
                              ' to_char(oh.loadno))) ';
   else
     if nvl(in_loadno,0) = 0 then
        cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              '''' || to_char(in_orderid) || to_char(in_shipid)|| ''') ';
     else
        cmdSql := cmdSql || '''' ||to_char(in_loadno)|| '''';
     end if;
   end if;
else
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30), ' ||
                              'nvl(oh.' || in_aux_shipment_column ||',''' || to_char(in_orderid) || to_char(in_shipid)|| ''' )) ';
   else
      cmdSql := cmdSql || 'nvl(oh.' || in_aux_shipment_column ||
                          ',''' ||  to_char(in_loadno)|| ''' )';
   end if;
end if;

cmdSql := cmdSql || ',zim7.sscc_count(oh.orderid, oh.shipid), ' ||
                    'decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),to_char(oh.loadno)), ';
cmdSQL := cmdSQL || ' oh.amtcod, oh.consignee, C.addr1, C.addr2, C.city,C.state, C.postalcode, oh.entrydate, '||
                    'cn.CONSPASSTHRUCHAR01, ' ||
                    'L.ldpassthruchar01,L.ldpassthruchar02,L.ldpassthruchar03,L.ldpassthruchar04,'||
                    'L.ldpassthruchar05,L.ldpassthruchar06,L.ldpassthruchar07,L.ldpassthruchar08,'||
                    'L.ldpassthruchar09,L.ldpassthruchar10,L.ldpassthruchar11,L.ldpassthruchar12,'||
                    'L.ldpassthruchar13,L.ldpassthruchar14,L.ldpassthruchar15,L.ldpassthruchar16,'||
                    'L.ldpassthruchar17,L.ldpassthruchar18,L.ldpassthruchar19,L.ldpassthruchar20,'||
                    'L.ldpassthruchar21,L.ldpassthruchar22,L.ldpassthruchar23,L.ldpassthruchar24,'||
                    'L.ldpassthruchar25,L.ldpassthruchar26,L.ldpassthruchar27,L.ldpassthruchar28,'||
                    'L.ldpassthruchar29,L.ldpassthruchar30,L.ldpassthruchar31,L.ldpassthruchar32,'||
                    'L.ldpassthruchar33,L.ldpassthruchar34,L.ldpassthruchar35,L.ldpassthruchar36,'||
                    'L.ldpassthruchar37,L.ldpassthruchar38,L.ldpassthruchar39,L.ldpassthruchar40,'||
                    'L.ldpassthrunum01,L.ldpassthrunum02,L.ldpassthrunum03,L.ldpassthrunum04,L.ldpassthrunum05,'||
                    'L.ldpassthrunum06,L.ldpassthrunum07,L.ldpassthrunum08,L.ldpassthrunum09,L.ldpassthrunum10,'||
                    'L.ldpassthrudate01,L.ldpassthrudate02,L.ldpassthrudate03,L.ldpassthrudate04, L.doorloc, ';
strChepType := trim(substr(zci.default_value('PALLETTYPECHEP'),1,12));
if strChepType is null then
   cmdSql := cmdsql || 'zim7.order_pallet_count_by_type(oh.custid,oh.fromfacility, ' ||
                                                       'oh.orderid, oh.shipid, ''CHEP'') + '||
                       'zim7.order_pallet_count_by_type(oh.custid,oh.fromfacility, ' ||
                                                        'oh.orderid, oh.shipid, ''SWITCHCHEP'') ';
else
   cmdSql := cmdsql || 'zim7.order_pallet_count_by_type(oh.custid,oh.fromfacility, oh.orderid, oh.shipid, ' ||
                                                        '''' || strChepType || ''') ';
end if;
cmdSql := cmdSql || ', LS.shipto,F.countrycode,C.name,C.countrycode, ' ||
                    'zim7.VICSsubbolNumber(oh.orderid, oh.shipid, oh.custid), ' ||
                    'zim7.VICSMinbolNumber(nvl(oh.loadno,0), oh.custid, oh.orderid, oh.shipid, oh.shipto),  ' ||
                    'OH.qtyship, OH.qtyorder, OH.qtyorder - OH.qtyship, OH.cancel_after, OH.requested_ship, '||
                    'OH.ship_not_before,OH.ship_no_later,OH.cancel_if_not_delivered_by,'||
                    ' OH.do_not_deliver_after,OH.do_not_deliver_before,OH.cancelled_date, ';
if in_woodpalletcount_list is null then
   cmdSql := cmdSql || ' 0,';
else
   cmdSql := cmdSql || 'zim7.order_pallet_count_by_list(oh.custid,oh.fromfacility, ' ||
                                                        'oh.orderid, oh.shipid, ''' || in_woodpalletcount_list || '''), ';
end if;
cmdSql := cmdsql || 'cn.conspassthruchar02,cn.conspassthruchar03,cn.conspassthruchar04, '||
                    'cn.conspassthruchar05,cn.conspassthruchar06,cn.conspassthruchar07, ' ||
                    'cn.conspassthruchar08,cn.conspassthruchar09,cn.conspassthruchar10, cail.scac ';
cmdSql := cmdSql ||
  ' from consignee CN, consignee BCN, customer C, facility F, loads L, carrier ca, carrier cail, orderhdr oh, loadstop LS ';
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus in ( ''6'',''7'',''8'',''9'') ';
    else
      cmdSql := cmdSql || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
    end if;
else
  if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
    cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
  else
    cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
  end if;
end if;
if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := cmdSql || ' and oh.xdockorderid is null ';
end if;

cmdSql := cmdSql ||
  ' and oh.carrier = ca.carrier(+) '||
  ' and oh.loadno = L.loadno(+) ' ||
  ' and oh.fromfacility = F.facility(+) '||
  ' and oh.custid = C.custid(+) ' ||
  ' and oh.shipto = CN.consignee(+) ' ||
  ' and oh.consignee = BCN.consignee(+) ' ||
  ' and oh.loadno = LS.loadno(+) '||
  ' and oh.stopno = LS.stopno(+) '||
  ' and oh.interlinecarrier = cail.carrier(+) ' ||
  l_condition;

cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

if in_shipment_column is not null then
   create_945_shipment;
end if;

if cu.linenumbersyn = 'Y' then
  debugmsg('perform extract by line numbers');
  extract_by_line_numbers;
  goto finish_shipnote945;
end if;

-- Create LXD View
cmdSql := 'create view ship_note_945_lxd_' || strSuffix ||
 '(orderid,shipid,custid,assignedid) '||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10 '||
 ' from orderdtl d, orderhdr oh ';
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus in ( ''6'',''7'',''8'',''9'') ';
    else
      cmdSql := cmdSql || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
    end if;
else
  if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
    cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
  else
    cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
  end if;
end if;
if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := cmdSql || ' and oh.xdockorderid is null ';
end if;
cmdSql := cmdSql ||
 '  and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid ';
if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
  cmdSql := cmdSql || ' and nvl(d.qtyship,0) <> 0 ';
end if;
cmdSql := cmdSql || l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create dtl');


-- Create Detail View
cmdSql := 'create view ship_note_945_dtl_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,shipticket,trackingno,servicecode,'||
 'lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,inventoryclass,'||
 'statuscode,reference,linenumber,orderdate,po,qtyordered,qtyshipped,'||
 'qtydiff,uom,packlistshipdate,weight,weightquaifier,weightunit,' ||
 'description,upc'||
 ',DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03' ||
 ',DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07' ||
 ',DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11' ||
 ',DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15' ||
 ',DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19' ||
 ',DTLPASSTHRUCHAR20'||
 ',DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23' ||
 ',DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27' ||
 ',DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,DTLPASSTHRUCHAR31' ||
 ',DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35' ||
 ',DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39' ||
 ',DTLPASSTHRUCHAR40'||
 ',DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03' ||
 ',DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07' ||
 ',DTLPASSTHRUNUM08,DTLPASSTHRUNUM09, DTLPASSTHRUNUM10, ' ||
 'DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13' ||
 ',DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,DTLPASSTHRUNUM16,DTLPASSTHRUNUM17' ||
 ',DTLPASSTHRUNUM18,DTLPASSTHRUNUM19, DTLPASSTHRUNUM20, ' ||
'DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,' ||
' DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02, FROMLPID, smallpackagelbs ,' ||
' deliveryservice, entereduom, qtyshippedeuom, hazardous, link_assignedid, ' ||
' cancelreason, shipshortreason, consigneesku, gtin)' ||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10,'||
 'substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),'||
 'decode(nvl(ca.multiship,''N''),''Y'','||
 '  substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
 ' nvl(oh.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid))),'||
 'nvl(oh.deliveryservice,''OTHR''),nvl(d.weightship,0)'||
 ',nvl(d.weightship,0) / 2.2046,nvl(d.weightship,0) / .0022046,' ||
 'nvl(d.weightship,0) * 16,'||
 'd.item,d.lotnumber,nvl(d.lotnumber,''(none)''),d.inventoryclass,'||
 'decode(D.linestatus, ''X'',''CU'','||
 'decode(nvl(d.qtyship,0), 0,''DS'','||
        'decode(zim7.split_item(oh.custid,oh.reference,d.item),'||
                '''Y'',''SS'','||
         'decode(zim7.changed_qty(oh.orderid,oh.shipid,'||
                                  'd.item,d.lotnumber),'||
            '''Y'',''PR'',''CC'')))),';
if nvl(in_abc_revisions_yn, 'n') = 'Y'  then
   cmdSql := cmdSql || 'zim7.abc_reference(oh.orderid, oh.shipid, ''' || in_abc_revisions_column ||'''),';
else
   cmdSql := cmdSql || 'oh.reference,';
end if;
cmdSql := cmdSql || 'nvl(d.dtlpassthrunum10,''000000''),oh.entrydate,oh.po,d.qtyentered,'||
 'nvl(d.qtyship,0),'||
 'nvl(d.qtyship,0) - d.qtyentered,d.uom,oh.packlistshipdate,'||
 'nvl(d.weightship,0),''G'','||
 '''L'',';
if rtrim(in_item_descr_dtlpassthru) is not null then
  cmdSql := cmdSql || 'nvl(d.' || rtrim(in_item_descr_dtlpassthru) || ',i.descr),';
else
  cmdSql := cmdSql || 'i.descr,';
end if;
if rtrim(in_upc_dtlpassthru) is not null then
  cmdSql := cmdSql || 'nvl(d.' || rtrim(in_upc_dtlpassthru) || ',U.upc)';
else
  cmdSql := cmdSql || 'u.upc';
end if;
cmdSql := cmdSql ||
 ',D.DTLPASSTHRUCHAR01,D.DTLPASSTHRUCHAR02,D.DTLPASSTHRUCHAR03' ||
 ',D.DTLPASSTHRUCHAR04,D.DTLPASSTHRUCHAR05,D.DTLPASSTHRUCHAR06,D.DTLPASSTHRUCHAR07' ||
 ',D.DTLPASSTHRUCHAR08,D.DTLPASSTHRUCHAR09,D.DTLPASSTHRUCHAR10,D.DTLPASSTHRUCHAR11' ||
 ',D.DTLPASSTHRUCHAR12,D.DTLPASSTHRUCHAR13,D.DTLPASSTHRUCHAR14,D.DTLPASSTHRUCHAR15' ||
 ',D.DTLPASSTHRUCHAR16,D.DTLPASSTHRUCHAR17,D.DTLPASSTHRUCHAR18,D.DTLPASSTHRUCHAR19' ||
 ',D.DTLPASSTHRUCHAR20'||
 ',D.DTLPASSTHRUCHAR21,D.DTLPASSTHRUCHAR22,D.DTLPASSTHRUCHAR23' ||
 ',D.DTLPASSTHRUCHAR24,D.DTLPASSTHRUCHAR25,D.DTLPASSTHRUCHAR26,D.DTLPASSTHRUCHAR27' ||
 ',D.DTLPASSTHRUCHAR28,D.DTLPASSTHRUCHAR29,D.DTLPASSTHRUCHAR30,D.DTLPASSTHRUCHAR31' ||
 ',D.DTLPASSTHRUCHAR32,D.DTLPASSTHRUCHAR33,D.DTLPASSTHRUCHAR34,D.DTLPASSTHRUCHAR35' ||
 ',D.DTLPASSTHRUCHAR36,D.DTLPASSTHRUCHAR37,D.DTLPASSTHRUCHAR38,D.DTLPASSTHRUCHAR39' ||
 ',D.DTLPASSTHRUCHAR40'||
 ',D.DTLPASSTHRUNUM01,D.DTLPASSTHRUNUM02,D.DTLPASSTHRUNUM03' ||
 ',D.DTLPASSTHRUNUM04,D.DTLPASSTHRUNUM05,D.DTLPASSTHRUNUM06,D.DTLPASSTHRUNUM07' ||
 ',D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10'||
 ',D.DTLPASSTHRUNUM11,D.DTLPASSTHRUNUM12,D.DTLPASSTHRUNUM13' ||
 ',D.DTLPASSTHRUNUM14,D.DTLPASSTHRUNUM15,D.DTLPASSTHRUNUM16,D.DTLPASSTHRUNUM17' ||
 ',D.DTLPASSTHRUNUM18,D.DTLPASSTHRUNUM19,D.DTLPASSTHRUNUM20, '||
 ' D.DTLPASSTHRUDATE01,D.DTLPASSTHRUDATE02,D.DTLPASSTHRUDATE03,D.DTLPASSTHRUDATE04,' ||
 ' D.DTLPASSTHRUDOLL01,D.DTLPASSTHRUDOLL02, ''000000000000000'',0,oh.deliveryservice, ' ||
 ' D.uomentered, zcu.equiv_uom_qty (D.custid,D.item,D.uom,D.qtyship,D.uomentered), i.hazardous, nvl(d.dtlpassthrunum10,0),  ' ||
 ' D.cancelreason, D.shipshortreason, D.consigneesku, null ' ||
 ' from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh ';
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus in ( ''6'',''7'',''8'',''9'') ';
    else
      cmdSql := cmdSql || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
    end if;
else
  if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
    cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
  else
    cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
  end if;
end if;
if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := cmdSql || ' and oh.xdockorderid is null ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid '||
 ' and oh.carrier = ca.carrier(+) '||
 ' and d.custid = i.custid(+) '||
 ' and d.item = i.item(+) '||
 ' and d.custid = U.custid(+) '||
 ' and d.item = U.item(+) ';
if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
  cmdSql := cmdSql || ' and nvl(d.qtyship,0) <> 0 ';
end if;
cmdSql := cmdSql || l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


  -- Create man (sscc18 view)
cmdSql := 'create view ship_note_945_s18_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,sscc18) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.barcode '||
 'from caselabels s, orderhdr oh ';
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus in ( ''6'',''7'',''8'',''9'') ';
    else
      cmdSql := cmdSql || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
    end if;
else
  if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
    cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
  else
    cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
  end if;
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.barcode is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create man (serial number view)
cmdSql := 'create view ship_note_945_man_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,item,lotnumber,link_lotnumber,' ||
 ' serialnumber,dtlpassthruchar01,fromlpid,lpid,trackingno, ' ||
 ' shippingcost,weight,quantity) '||
 ' as select s.orderid,s.shipid,s.custid,d.dtlpassthrunum10,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.serialnumber, ' ||
 ' d.dtlpassthruchar01, s.fromlpid, s.lpid, s.trackingno, ' ||
 ' decode(s.type, ''F'', s.shippingcost, (select shippingcost from shippingplate where lpid = s.parentlpid)), '||
 's.weight, s.quantity ' ||
 'from shippingplate s, orderhdr oh, orderdtl d ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := cmdSql || ' and oh.xdockorderid is null ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and d.orderid = s.orderid' ||
 ' and d.shipid = s.shipid' ||
 ' and d.item = s.item' ||
 ' and nvl(d.lotnumber,''(none)'') = nvl(s.lotnumber,''(none)'')'||
 ' and s.status||'''' = ''SH'''||
 ' and s.serialnumber is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create lot view
debugmsg('create plot view');
cmdSql := 'create view ship_note_945_plot_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,qtyshipped,qtyordered,qtydiff,assignedid, uom, iskit) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.orderlot,''(none)''),sum(s.quantity),sum(s.quantity),0,null, s.unitofmeasure, ci.iskit '||
 'from shippingplate s, orderhdr oh, custitem ci ';
if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus in ( ''6'',''7'',''8'',''9'') ';
    else
      cmdSql := cmdSql || ' where oh.orderstatus in (''6'',''7'',''8'',''9'',''X'') ';
    end if;
else
  if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
    cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
  else
    cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
  end if;
end if;
if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := cmdSql || ' and oh.xdockorderid is null ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.status||'''' = ''SH'''||
 ' and s.type in (''F'',''P'') '||
 ' and oh.custid = ci.custid ' ||
 ' and s.item = ci.item ' ||
 l_condition  ||
' group by s.orderid,s.shipid,s.custid,s.item,'||
' s.lotnumber, nvl(s.orderlot,''(none)''), s.unitofmeasure, ci.iskit ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

debugmsg('create lot view');
cmdSql := 'create view ship_note_945_lot_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,item,lotnumber,link_lotnumber,qtyshipped,'||
 ' qtyordered,qtydiff,weightshipped,childorderid,childshipid,iskit,link_assignedid) '||
 ' as select orderid,shipid,custid,assignedid,item,lotnumber,link_lotnumber,qtyshipped,'||
 ' qtyordered,qtydiff,weightshipped,childorderid,childshipid,iskit,link_assignedid '||
 ' from ('||
 ' select s.orderid,s.shipid,s.custid,s.assignedid,s.item,s.lotnumber, ';

 if (nvl(in_lots_qtyorder_diff_yn, 'N') = 'N') then
 cmdSql := cmdSql ||
 '    s.link_lotnumber,s.qtyshipped,s.qtyordered,s.qtydiff,'||
 '    zci.item_weight(s.custid,s.item,s.uom) * s.qtyshipped as weightshipped, ';
 else
 cmdSql := cmdSql ||
 '    s.link_lotnumber,s.qtyshipped,o.qtyorder as qtyordered,o.qtyorder - s.qtyshipped as qtydiff,'||
 '    zci.item_weight(s.custid,s.item,s.uom) * s.qtyshipped as weightshipped, ';
 end if;

 cmdSql := cmdSql ||
 '    o.childorderid,o.childshipid,(select nvl(iskit,''N'') from custitem where custid = s.custid and item = s.item) as iskit , '||
 '    nvl(s.assignedid, 0) as link_assignedid' ||
 ' from ship_note_945_plot_' || strsuffix || ' s, ' ||
      ' orderdtl o ' ||
 ' where o.orderid = s.orderid and '||
        'o.shipid = s.shipid and ' ||
        'o.item = s.item ';
if nvl(in_include_zero_qty_lot_yn,'N') = 'Y' then
   cmdSql := cmdSql ||
      'union ' ||
      ' select oh.orderid,oh.shipid,oh.custid,0,od.item, null, ''(none)'', 0, '||
      ' od.qtyorder, null, 0, 0, 0, ''N'', 0'||
      ' from orderhdr oh, orderdtl od ';
   if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
      cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
   else
      cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
   end if;
   if nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
      cmdSql := cmdSql || ' and oh.xdockorderid is null ';
   end if;
   cmdSql := cmdSql ||
     'and oh.orderid = od.orderid '||
     'and oh.shipid = od.shipid ' ||
     'and nvl(od.qtyship,0) = 0 ' ||
     l_condition;
end if;
cmdSql := cmdSql ||
 ')'||
 ' group by orderid,shipid,custid,assignedid,item,lotnumber,link_lotnumber,qtyshipped,'||
 ' qtyordered,qtydiff,weightshipped,childorderid,childshipid,iskit,link_assignedid';

debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


<< finish_shipnote945 >>

extract_by_id_contents;

debugmsg('create ship hd view');
cmdSql := 'create view ship_note_945_hd_' || strSuffix ||
' (custid,company,warehouse,loadno,orderid,shipid,reference,hdr_trackingno,dateshipped'
||' ,commitdate,shipviacode,hdr_lbs,hdr_kgs,hdr_gms,hdr_ozs,hdr_shipticket,height'
||' ,width,length,shiptoidcode,shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,shiptocity'
||' ,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,carrier,carrier_name'
||' ,packlistshipdate,routing,shiptype,shipterms,reportingcode,depositororder,po'
||' ,deliverydate,estdelivery,billoflading,prono,masterbol,splitshipno,invoicedate'
||' ,effectivedate,totalunits,totalweight,uomweight,totalvolume,uomvolume,ladingqty'
||' ,hdr_uom,warehouse_name,warehouse_id,depositor_name,depositor_id'
||' ,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05'
||' ,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10'
||' ,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15'
||' ,HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20'
||' ,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,HDRPASSTHRUNUM05'
||' ,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10'
||' ,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01'
||' ,HDRPASSTHRUDOLL02,trailer,seal,palletcount,freightcost,assignedid,shipticket,trackingno'
||' ,servicecode,lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,statuscode,linenumber'
||' ,orderdate,qtyordered,qtyshipped,qtydiff,uom,weight,weightquaifier,weightunit'
||' ,description,upc,DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04'
||' ,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09'
||' ,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14'
||' ,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19'
||' ,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04'
||' ,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09'
||' ,DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,DTLPASSTHRUDATE04'
||' ,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,fromlpid,smallpackagelbs,deliveryservice)'
||' as select hdr.custid,company,warehouse,loadno,hdr.orderid,hdr.shipid,hdr.reference'
|| ' ,hdr.trackingno,dateshipped,commitdate,shipviacode,hdr.lbs,hdr.kgs,hdr.gms,hdr.ozs'
||' ,hdr.shipticket,height,width,length,shiptoidcode,shiptoname,shiptocontact,shiptoaddr1'
||' ,shiptoaddr2,shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone'
||' ,carrier,carrier_name,hdr.packlistshipdate,routing,shiptype,shipterms,reportingcode'
||' ,depositororder,hdr.po,deliverydate,estdelivery,billoflading,prono,masterbol'
||' ,splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,totalvolume'
||' ,uomvolume,ladingqty,hdr.uom,warehouse_name,warehouse_id,depositor_name,depositor_id'
||' ,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05'
||' ,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10'
||' ,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15'
||' ,HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20'
||' ,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,HDRPASSTHRUNUM05'
||' ,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10'
||' ,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01'
||' ,HDRPASSTHRUDOLL02,trailer,seal,palletcount,freightcost,assignedid,dtl.shipticket'
||' ,dtl.trackingno,servicecode,dtl.lbs,dtl.kgs,dtl.gms,dtl.ozs,item,lotnumber,link_lotnumber'
||' ,statuscode,linenumber,orderdate,qtyordered,qtyshipped,qtydiff,dtl.uom,weight'
||' ,weightquaifier,weightunit,description,upc,DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02'
||' ,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07'
||' ,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12'
||' ,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17'
||' ,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02'
||' ,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07'
||' ,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02'
||' ,DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,fromlpid'
||' ,smallpackagelbs,deliveryservice from ship_note_945_dtl_' || strSuffix
||' dtl, ship_note_945_hdr_' || strSuffix || ' hdr'
||' where hdr.orderid = dtl.orderid  and hdr.shipid = dtl.shipid ';
--debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

create_dtl_trackingno;

debugmsg('create fhd');
if in_fhd_sequence is not null then
   cmdSql := 'create table ship_note_945_fhd_' || strSuffix ||
      ' (ORDERID NUMBER(9), SHIPID NUMBER(2), CUSTID VARCHAR2(10),' ||
      ' LOADNO number, file_sequence varchar2(20))';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
end if;


cmdSql := 'select count(1) custid from ship_note_945_hdr_'||strSuffix;
open cl for cmdsql;
fetch cl into cntRows;
close cl;

if cntRows = 0 and
   nvl(rtrim(in_exclude_xdockorder_yn),'N') = 'Y' then
   cmdSql := 'create table ship_note_945_trl_' || strSuffix ||
      ' (ORDERID NUMBER(9), SHIPID NUMBER(2), CUSTID VARCHAR2(10),' ||
      ' HDR_COUNT number, DTL_COUNT number, LOT_COUNT number, LXD_COUNT number, '||
      ' S18_COUNT number, LOADNO number)';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
else


   if nvl(in_loadno,0) != 0 then
      cmdSql := 'select loadno, custid from ship_note_945_hdr_'||strSuffix;
      open cl for cmdsql;
      fetch cl into l_loadno, l_custid;
      if cl%notfound then
         l_loadno := in_loadno;
         l_custid := in_custid;
      end if;
      close cl;
      if in_fhd_sequence is not null and
         cntRows > 0 then
         cmdSql := 'select to_char(' || rtrim(in_fhd_sequence) || '.nextval,''FM09999999'') from dual';
         debugmsg(cmdsql);
         execute immediate cmdSql into fileHdrSequence;
         debugmsg('fhd insert');
         execute immediate 'insert into SHIP_NOTE_945_FHD_' || strSuffix ||
            ' values (:orderid, :shipid, :custid, :loadno, :file_sequence)'
            using in_orderid, in_shipid, l_custid, l_loadno, fileHdrSequence;
   --      ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
      end if;
      cmdSql := 'create view ship_note_945_trl_' || strSuffix ||
      ' (orderid,shipid,custid,hdr_count,dtl_count,lot_count,lxd_count,man_count,s18_count, loadno) as '||
      ' select null, null, ''' || l_custid|| ''','||
      ' (select count(1) from ship_note_945_hdr_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_dtl_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_lot_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_lxd_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_man_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_s18_'||strSuffix||'),'||
      l_loadno || ' from dual ';
   else
      if in_fhd_sequence is not null and
         cntRows > 0 then
         l_loadno := null;
         l_custid := in_custid;
         cmdSql := 'select to_char(' || rtrim(in_fhd_sequence) || '.nextval,''FM09999999'') from dual';
         debugmsg(cmdsql);
         execute immediate cmdSql into fileHdrSequence;
         debugmsg('fhd insert');
         execute immediate 'insert into SHIP_NOTE_945_FHD_' || strSuffix ||
            ' values (:orderid, :shipid, :custid, :loadno, :file_sequence)'
            using in_orderid, in_shipid, l_custid, l_loadno, fileHdrSequence;
   --      ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||

      end if;
      cmdSql := 'create view ship_note_945_trl_' || strSuffix ||
      ' (orderid,shipid,custid,hdr_count,dtl_count,lot_count,lxd_count,man_count,s18_count, loadno) as '||
      ' select orderid, shipid,custid,'||
      ' (select count(1) from ship_note_945_hdr_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_dtl_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_lot_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_lxd_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_man_'||strSuffix||'),'||
      ' (select count(1) from ship_note_945_s18_'||strSuffix||'), null '||
      ' from ship_note_945_hdr_'||strSuffix;
   end if;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

   cntRows := 1;
   while (cntRows * 60) < (Length(cmdSql)+60)
   loop
     debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
     cntRows := cntRows + 1;
   end loop;

   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);

end if;

  -- Create sn (alternate serial number view)
  -- Create sn (alternate serial number view)
cmdSql := 'create table ship_note_945_sn_' || strSuffix ||
  ' as select * from ship_note_945_sn where 1 = 0';
debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
create_945_sn;

if nvl(in_810_yn,'N') = 'Y' then
   create_945_invoice;
end if;

if nvl(in_smallpackage_by_tn_yn,'N') = 'Y' and
nvl(in_transaction,'000') = '856' then
   create_945_shipment_by_tn;
end if;

if nvl(in_dtllot_yn ,'N') = 'Y' then
  create_dtllot;
end if;
cmdSql := 'create view ship_note_945_pal_' || strSuffix ||
  ' (custid,orderid,shipid,loadno,pallettype,inpallets,outpallets) as '||
  ' select  custid,orderid,shipid,loadno,pallettype,inpallets,outpallets ' ||
  ' from pallethistory ' ||
  ' where (orderid,shipid) in (select orderid, shipid from SHIP_NOTE_945_HDR_' || strSuffix || ')';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'select warehouse_id from ship_note_945_hdr_'||strSuffix;
open cl for cmdsql;
fetch cl into l_facility;
if cl%notfound then
   l_facility := null;
end if;
close cl;


begin
   select code into strEdiPartner
      from EDI_PARTNER
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiPartner := null;
end;
begin
   select code into strEdiSender
      from EDI_SENDER
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiSender := null;
end;

begin
   select code into strEdiBatchref
      from EDI_BATCH_REF
      where descr = rtrim(in_custid) || rtrim(l_facility);
exception when others then
  strEdiBatchref := null;
end;

cmdSql := 'create view ship_note_945_ihr_'||strSuffix ||
          '(partneredicode,datetimecreated,custid,senderedicode,applicationsendercode, loadno, orderid, shipid) '||
          'as select ''' || strEdiPartner || ''', to_char(sysdate,''YYYYMMDDHHMI''), ''' ||
          in_custid || ''',''' || strEdiBatchRef || ''',''' || strEdiSender ||''', ' ||
          nvl(in_loadno,0) || ',' || nvl(in_orderid,0) || ',' || nvl(in_shipid,0)|| ' from dual ';

debugmsg(cmdsql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

create_notes;


debugmsg('cnt trailer');
cmdSql := 'create or replace view ship_note_945_ctr_' ||strSuffix ||
  ' (custid,orderid,shipid,cnt_count, weight, qty) as '||
  ' select  custid,orderid,shipid,count(1), sum(weight), sum(qty) '||
  ' from SHIP_NOTE_945_CNT_' || strSuffix ||
  ' group by custid, orderid, shipid';

debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


if nvl(in_create_cnt_fs_yn,'N') = 'Y' then
   create_cnt_fs;
end if;


debugmsg('facility');
cmdSql := 'create or replace view ship_note_945_fac_' || strSuffix ||
  ' (custid, facility) as ' ||
  ' select distinct custid, warehouse_id ' ||
  '  from ship_note_945_hdr_' || strSuffix ;
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('mbr');
cmdSql := 'create or replace view ship_note_945_mbr_' || strSuffix ||
   '(custid, facility, po, dateshipped, orderid, '||
    'lotnumber,lpid, item, weight, qty) as '||
    'select h.custid, h.warehouse_id,''"''|| rtrim(h.po) ||''"'', '||
           '''"'' || to_char(h.dateshipped, ''YYYY-MM-DD'') || ''"'', '||
           '''"'' || h.orderid || ''"'', '||
           '''"'' || rtrim(c.lotnumber) || ''"'', '||
           '''"'' || c.fromlpid || ''"'', '||
           '''"'' || rtrim(c.item) ||''"'', c.weight, c.qty '||
    'from ship_note_945_hdr_' || strSuffix || ' h, '||
         'ship_note_945_cnt_' || strSuffix || ' c ' ||
    'where c.orderid = h.orderid '||
      'and c.shipid = h.shipid';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 spk');
cmdSql := 'create table ship_note_945_spk_' || strSuffix ||
' (custid varchar2(50), orderid varchar2(50), shipid varchar2(50), '||
' orderdate varchar2(50), dateshipped varchar2(50), reference varchar2(50), '||
' shiptoname varchar2(50), lineitemscnt varchar2(50), trackingno varchar2(50), prono varchar2(50), '||
' freightcost varchar2(50), weight varchar2(50), carrier varchar2(50), qtyshipcnt varchar2(50), loadno varchar2(50), '||
' created varchar2(80) )';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'insert into ship_note_945_spk_' || strSuffix ||
    ' values(''Cust Id'',''Order Id'',''Ship Id'',''Order Date'',''Ship Date'',''Order #'',''Ship Name'', ''#Line Itms'', '||
    ' ''Tracking #'', ''Pro #'', ''Freight'',''Weight'',''Carrier'',''#Pkgs'', ''Loadno'', '||
    ' ''Created'' '||
    ')';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'insert into ship_note_945_spk_' || strSuffix ||
    ' select h.custid, h.orderid, h.shipid ,'||
           ' to_char(h.entrydate, ''YYYY-MM-DD'') ,'||
           ' to_char(h.dateshipped, ''YYYY-MM-DD'') ,'||
           ' rtrim(h.reference) ,'||
           ' rtrim(h.shiptoname) ,'||
           ' zim14.cnt_lineitems(h.orderid, h.shipid) ,'||
           ' decode(h.shiptype, ''S'', rtrim(h.trackingno), null) ,'||
           ' decode(h.shiptype, ''L'', rtrim(h.prono), null) ,'||
           ' decode(zim14.freight_cost_all_items(h.orderid, h.shipid, h.shiptype), 0 , null, zim14.freight_cost_all_items(h.orderid, h.shipid, h.shiptype)) ,'||
           ' zim14.sum_weightship(h.orderid, h.shipid, h.shiptype) ,'||
           ' decode(h.shiptype, ''S'', zim14.get_carrier_name(h.carrier, h.shipviacode), zim14.get_carrier_name(h.carrier, h.hdrpassthruchar20)) ,'||
           ' zim14.cnt_qtyship(h.orderid, h.shipid, h.shiptype), '||
           ' h.loadno, '||
           ' (select systimestamp from dual) ' ||
    'from ship_note_945_hdr_' || strSuffix || ' h';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn945 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_shipnote945;


procedure end_shipnote945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strObject varchar2(32);
strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

for obj in (select object_name, object_type
              from user_objects
             where object_name like 'SHIP_NOTE_856_%_' || strSuffix )
loop

  cmdSql := 'drop ' || obj.object_type || ' ' || obj.object_name;

  execute immediate cmdSql;

end loop;

for obj in (select object_name, object_type
              from user_objects
             where object_name like 'SHIP_NOTE_945_%_' || strSuffix
               and object_name != 'SHIP_NOTE_945_HDR_' || strSuffix )
loop

  cmdSql := 'drop ' || obj.object_type || ' ' || obj.object_name;

  execute immediate cmdSql;

end loop;

cmdsql := 'drop view SHIP_NOTE_945_HDR_' || strSuffix;
execute immediate cmdSql;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn945 ' || sqlerrm;
  out_errorno := sqlcode;
end end_shipnote945;



----------------------------------------------------------------------
-- begin_invadj947
----------------------------------------------------------------------
procedure begin_invadj947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_exclude_zero_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;


cursor C_INVADJACTIVITY is
  select IA.rowid,IA.*, U.upc
    from custitemupcview U, invadjactivity IA
   where IA.custid = in_custid
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and IA.custid = U.custid(+)
     and IA.item = U.item(+)
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

cursor C_LPID(in_lpid varchar2) is
  select DR.descr, P.holdreason
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code(+);

dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
cntChar integer;
strHoldReason varchar2(2);

begin

mark := 'Start';

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'INVADJ947HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;

-- Loopthru the invadj for the customer
  for adj in C_INVADJACTIVITY loop
      zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,
            strRegWhse,strRetWhse);
      if strWhse is not null then
         if nvl(in_exclude_zero_yn,'N') = 'Y' then
            intErrorNo := 0;
         else
         zedi.validate_interface(adj.rowid,strMovementCode,intErrorNo,strMsg);
         end if;
         if intErrorNo = 0 then
            if adj.newinvstatus = 'DM' and adj.invstatus != 'DM' then
               OPEN C_LPID(adj.lpid);
               FETCH C_LPID into strRefDesc, strHoldReason;
               CLOSE C_LPID;
            else
               strRefDesc := null;
               strHoldReason := null;
            end if;
            if ((adj.inventoryclass !=
                  nvl(adj.newinventoryclass,adj.inventoryclass)) or
                (adj.invstatus !=
                  nvl(adj.newinvstatus,adj.invstatus)) ) then
               qtyAdjust := adj.adjqty * -1;
            else
               qtyAdjust := adj.adjqty;
            end if;
            insert into invadj947dtlex
               (
                   sessionid,
                   whenoccurred,
                   lpid,
                   facility,
                   custid,
                   rsncode,
                   quantity,
                   uom,
                   upc,
                   item,
                   lotno,
                   dmgdesc
               )
            values
               (
                   strSuffix,
                   adj.whenoccurred,
                   adj.lpid,
                   adj.facility,
                   adj.custid,
                   strMovementCode,
                   qtyAdjust,
                   adj.uom,
                   adj.upc,
                   adj.item,
                   adj.lpid,
                   strRefDesc
               );
         end if;
      end if;
  end loop;

-- create hdr view
cmdSql := 'create view INVADJ947HDR_' || strSuffix ||
 ' (custid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
 '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
 '  facility_addr1,facility_addr2,facility_city,facility_state,'||
 '  facility_postalcode,custreference,reference,po,status) '||
 'as select distinct I.custid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
 '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
 '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode, '||
 ' max(I.custreference), ' ||
 ' max(case when (select max(adjreason) from invadjactivity where lpid=I.lpid and whenoccurred=I.whenoccurred and item=I.item)<>''PI'' '||
      'then (select reference from orderhdr where rownum=1 and orderid=nvl((select orderid from plate where lpid=i.lpid),(select orderid from deletedplate where lpid=i.lpid))) end) ' ||
 ' ,'''' po, '''' status ' ||
 ' from facility F, customer C, invadj947dtlex I ' ||
 ' where sessionid = '''||strSuffix||''''||
 '  and I.custid = C.custid(+)'||
 '  and I.facility = F.facility(+)';
if nvl(in_exclude_zero_yn,'N') = 'Y' then
   cmdSql := cmdSql || ' and I.quantity <> 0 ';
end if;
cmdSql := cmdSql || ' group by I.custid,I.whenoccurred,C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode';
cntChar := 1;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create dtl view
cmdSql := 'create view invadj947dtl_' || strSuffix ||
 ' (custid,facility,adjno,lpid,reason,quantity,uom,upc,item,lot, '||
   'oldtaxstat,newtaxstat,sapmove,newlot,newitem,custreference, ' ||
   'stdinvstatus,oldinvstatus,newinvstatus,manufacturedate,expirationdate, '||
   'lotnumber,holdreason,adjreason,reference) ' ||
 'as select I.custid,I.facility,to_char(whenoccurred,''YYYYMMDDHH24MISS''),'||
 ' I.lpid,I.rsncode,I.quantity,I.uom,I.upc,I.item,I.lotno, '||
  'I.oldtaxcode,I.newtaxcode,I.sapmovecode,I.newlotno,I.newitemno,I.custreference, ' ||
  'I.oldinvstatus,I.oldinvstatus,I.newinvstatus, ';
if nvl(in_exclude_zero_yn,'N') = 'Y' then
cmdSql := cmdSql ||
     'decode(P.manufacturedate, null, decode(DP.manufacturedate, null, null, to_char(DP.manufacturedate, ''YYYYMMDD'')), to_char(P.manufacturedate, ''YYYYMMDD'')), ' ||
     'decode(P.expirationdate, null, decode(DP.expirationdate, null, to_char(DP.expirationdate, ''YYYYMMDD'')), to_char(P.expirationdate, ''YYYYMMDD'')), ';
else
cmdSql := cmdSql ||
     'decode(P.manufacturedate, null, DP.manufacturedate, P.manufacturedate), ' ||
     'decode(P.expirationdate, null, DP.expirationdate, P.expirationdate), ';
end if;
cmdSql := cmdSql ||
  'I.lotnumber,I.holdreason, ' ||
  ' (select max(adjreason) from invadjactivity ia ' ||
     'where lpid=I.lpid and whenoccurred=I.whenoccurred and item=I.item) adjreason, ' ||
  ' (case when (select max(adjreason) from invadjactivity where lpid=I.lpid and whenoccurred=I.whenoccurred and item=I.item)<>''PI'' '||
          'then (select reference from orderhdr where rownum=1 and orderid=nvl((select orderid from plate where lpid=I.lpid),(select orderid from deletedplate where lpid=I.lpid))) end) ' ||
 ' from invadj947dtlex I, plate P, deletedplate DP'||
 ' where sessionid = '''||strSuffix||''''  ||
   ' and I.lpid = P.lpid(+) ' ||
   ' and I.lpid = DP.lpid(+) ';
if nvl(in_exclude_zero_yn,'N') = 'Y' then
 cmdSql := cmdSql || ' and I.quantity <> 0 ';
end if;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create ref view
cmdSql := 'create view invadj947ref_' || strSuffix ||
 ' (custid,facility,adjno,lpid,refdesc) ' ||
 ' as select custid,facility,to_char(whenoccurred,''YYYYMMDDHH24MISS''),'||
 ' lpid,dmgdesc ' ||
 ' from invadj947dtlex ' ||
 ' where sessionid = '''||strSuffix||'''' ||
 ' and dmgdesc is not null ';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_invadj947;

----------------------------------------------------------------------
-- end_invadj947
----------------------------------------------------------------------
procedure end_invadj947
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from invadj947dtlex where sessionid = strSuffix;

cmdSql := 'drop VIEW invadj947dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW invadj947ref_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW invadj947hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'ze947 ' || sqlerrm;
  out_errorno := sqlcode;
end end_invadj947;


----------------------------------------------------------------------
-- begin_invadjgt947
----------------------------------------------------------------------
procedure begin_invadjgt947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_partner_edi_code IN varchar2
,in_sender_edi_code IN varchar2
,in_app_sender_code IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

strName varchar2(40);

cursor C_INVADJACTIVITY is
  select IA.rowid,IA.*, U.upc
    from custitemupcview U, invadjactivity IA
   where IA.custid = in_custid
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and IA.custid = U.custid(+)
     and IA.item = U.item(+)
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

cursor C_LPID(in_lpid varchar2) is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
strNewRsnCode invadjactivity.adjreason%TYPE;
qtyAdjNew  invadjactivity.adjqty%TYPE;
strDebugYN char(1);
strDate varchar2(8);
strTime varchar2(8);
strBatch varchar2(12);
dCnt integer;
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;
procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || ' '  || ': ' || out_msg;
  zms.log_autonomous_msg('JEFF', in_facility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), 'JEFF', strMsg);
end;



begin
if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

--out_msg := in_begdatestr || ' ' || in_enddatestr;
--order_msg('I');


out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'GT947_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
begin
  dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -1;
  out_msg := 'Invalid begin date string ' || in_begdatestr;
  return;
end;
begin
  dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -2;
  out_msg := 'Invalid end date string ' || in_enddatestr;
  return;
end;

-- Loopthru the invadj for the customer
for adj in C_INVADJACTIVITY loop
   if adj.facility = nvl(in_facility,adj.facility) then
      strNewRsnCode := null;
      if adj.invstatus is not null then
         debugmsg(to_char(adj.whenoccurred,'MM/DD/YYYY HH:MI:SS') || ' ' ||
                  adj.lpid || ' ' || adj.item || ' ' ||
                  adj.adjqty || ' :' || adj.oldinvstatus || '-' ||
                  adj.newinvstatus);

         if adj.invstatus = 'AV' then
            if adj.adjqty < 0 then
               if  nvl(adj.newinvstatus,'AV') != 'AV' then
                    strNewRsnCode := '05';
               end if;
            else
               if  nvl(adj.oldinvstatus,'AV') != 'AV' then
                    strNewRsnCode := '55';
               end if;
            end if;
         else
            if adj.adjqty < 0 then
               if  nvl(adj.newinvstatus,'xx') = 'AV' then
                    strNewRsnCode := '55';
               end if;
            else
               if  nvl(adj.oldinvstatus,'xx') = 'AV' then
                    strNewRsnCode := '05';
               end if;
            end if;

         end if;
      end if;
      debugmsg( '-- ' || strNewRsnCode);
      debugmsg('');
      if strNewRsnCode is not null then
         insert into invadj947dtlex (sessionid, whenoccurred, lpid, facility, custid,
            rsncode,quantity,uom,upc,item,lotno,
            dmgdesc,oldinvstatus, document, serialnumber)
          values(strSuffix,adj.whenoccurred,adj.lpid,adj.facility,adj.custid,
                 strNewRsnCode,adj.adjqty,adj.uom,adj.upc,adj.item,adj.lotnumber,
                 strRefDesc,adj.invstatus, zim7.gt947_document(adj.lpid), adj.serialnumber);
      end if;
   end if;
end loop;

select to_char(sysdate,'YYYYMMDD') into strDate from dual;
select to_char(sysdate,'HHMMSS')||'00' into strTime from dual;
strBatch := strDate || substr(strTime,1,4);


begin
  select name into strName
     from customer
     where custid = in_custid;
exception when others then
   strName := null;
end;

/*
cmdsql := 'create table gt947_hdr_' || strsuffix  ||
'(custid varchar2(10) not null, record_type varchar2(1), transaction_set varchar2(3), ' ||
' partner_edi_code varchar2(15), date_created varchar2(8), time_created varchar2(8), '||
' depositor_code varchar2(12), batch_reference varchar2(35), other_reference varchar2(35), '||
' sender_edi_code varchar2(15), app_sender_code varchar2(12), app_recvr_code varchar2(12))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('insert hdr');
cmdSql := 'insert into gt947_hdr_' || strSuffix ||
'(custid, record_type, transaction_set, partner_edi_code, date_created, time_created, '||
' depositor_code, batch_reference, other_reference, sender_edi_code, app_sender_code, '||
' app_recvr_code) ' ||
' values ( ''' || in_custid || ''', ''I'', ''947'', '''|| in_partner_edi_code || ''', ''' ||
          strDate || ''', ''' || strTime ||''', null, '''|| strBatch ||''', ' ||
         'null, ''' || in_sender_edi_code || ''' , ''' || in_app_sender_code || ''', null)';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
*/


cmdSql := 'create view gt947_rpt_' || strSuffix ||
'(document, custid, record_type, date_created, name) '||
' as select distinct document, ''' || in_custid || ''', ''H'', ''' || strDate || ''', '||
            '''' || strName ||'''' ||
 ' from invadj947dtlex  ' ||
 ' where sessionid = '''||strSuffix||'''';



debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


cmdSql := 'create view gt947_hdr_' || strSuffix ||
'(document, custid, record_type, transaction_set, partner_edi_code, date_created, time_created, '||
' depositor_code, batch_reference, other_reference, sender_edi_code, app_sender_code, '||
' app_recvr_code) ' ||
' as select distinct document,  ''' || in_custid || ''', ''I'', ''947'', '''|| in_partner_edi_code || ''', ''' ||
          strDate || ''', ''' || strTime ||''', null, '''|| strBatch ||''', ' ||
         'null, ''' || in_sender_edi_code || ''' , ''' || in_app_sender_code || ''', null ' ||
 ' from invadj947dtlex  ' ||
 ' where sessionid = '''||strSuffix||'''';
debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdsql := 'create table gt947_dtl_' || strsuffix  ||
'(record_type char(1), custid varchar2(10) not null, '||
' item varchar2(50), lotnumber varchar2(30), serialnumber varchar2(30), '||
' facility varchar2(3), location varchar2(10), quantity varchar2(11), unitofmeasure varchar2(4), '||
' detialstatus char(1), document varchar2(6), adjreference varchar2(30), '||
' adjreason varchar2(2), reasoncode varchar2(10), originalreasoncode varchar2(10),'||
' itemsub1 varchar2(10), weight varchar2(10), pallets varchar2(10), lpid varchar2(15),'||
' lpidlast6 varchar2(6),lpidlast7 varchar2(7))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'insert into gt947_dtl_' || strSuffix ||
' select ''D'', i.custid, i.item, i.lotno, i.serialnumber, i.facility, ' ||
 'nvl(p.location,dp.location), ' ||
 'to_char(abs(i.quantity), ''FM0999999V99'') || decode(sign(i.quantity), -1, ''-'', ''+''), '||
 'i.uom, null, i.document, '||
 ' to_char(i.whenoccurred,''YYYYMMDDHH24MISS'') || i.lpid, i.rsncode, ' ||
 ' decode(nvl(i.oldinvstatus,''z''),''AV'', null, (select abbrev from inventorystatus where code = I.oldinvstatus)),'||
 ' decode(nvl(i.oldinvstatus,''z''),''AV'', null, (select abbrev from inventorystatus where code = I.oldinvstatus)),'||
 ' substr(i.lotno, length(i.lotno) -3), '||
 ' to_char(abs(i.quantity) * ci.weight,''FM0999999V99'') || decode(sign(i.quantity), -1, ''-'', ''+''), '||
 ' ''000000100''  || decode(sign(i.quantity), -1, ''-'', ''+''), i.lpid, zim7.lpid_last6(i.lpid), zim7.lpid_last6(i.lpid) '||
 ' from invadj947dtlex i, ' ||
      ' plate p, '||
      ' deletedplate dp, ' ||
      ' custitem ci '||
 ' where sessionid = '''||strSuffix||'''' ||
   ' and i.lpid = p.lpid(+) ' ||
   ' and i.lpid = dp.lpid(+) ' ||
   ' and i.custid = ci.custid(+) ' ||
   ' and i.item = ci.item(+) ';

debugmsg(cmdsql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'delete from gt947_dtl_' || strSuffix ||
           ' where reasoncode is null ';
out_errorno := viewcount;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

/*
execute immediate
  'select count(1) from gt947_dtl_' || strSuffix
  into dCnt;

if dCnt = 0 then
  cmdSql := 'delete from gt947_hdr_' || strSuffix;
  out_errorno := viewcount;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
end if;

out_msg := 'OKAY';
*/


exception when others then
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_invadjgt947;


----------------------------------------------------------------------
-- end_invadjgt947
----------------------------------------------------------------------
procedure end_invadjgt947
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from invadj947dtlex where sessionid = strSuffix;

cmdSql := 'drop TABLE gt947_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW gt947_rpt_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view gt947_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'ze947 ' || sqlerrm;
  out_errorno := sqlcode;
end end_invadjgt947;


----------------------------------------------------------------------
-- begin_prodactv852
----------------------------------------------------------------------
procedure begin_prodactv852
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

cursor C_FACILITIES(in_custid varchar2, in_beg date, in_end date) is
  select distinct facility
    from custitemtot
   where custid = in_custid
     and facility is not null
 union
  select distinct nvl(fromfacility, tofacility) facility
    from orderhdr
   where custid = in_custid
     and statusupdate >= in_beg
     and statusupdate < in_end
     and (fromfacility is not null
       or tofacility is not null)
 union
  select distinct facility
    from invadjactivity IA
   where IA.custid = in_custid
     and IA.facility is not null
     and IA.whenoccurred >= in_beg
     and IA.whenoccurred <  in_end
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

CURSOR C_FACILITY(in_facility varchar2)
IS
  select *
    from facility
   where facility = in_facility;

FAC facility%rowtype;

CURSOR C_ITEMS(in_custid varchar2, in_facility varchar2)
IS
 select decode(nvl(I.iskit,'N'),'N',I.item,'C',I.item,W.component) item,
        I.baseuom,
        decode(nvl(T.invstatus,'AV'),'AV','33','20') qual,
        sum(nvl(decode(nvl(I.iskit,'N'),'N',T.qty,'C',T.qty,T.qty*W.qty),0)) qty
   from workordercomponents W, custitemtot T, custitem I
  where I.custid = in_custid
    and in_facility = T.facility(+)
    and I.custid = T.custid(+)
    and I.item = T.item(+)
    and I.item not in ('UNKNOWN','RETURNS','x')
    and T.status(+) not in ('D','P','U','CM')
    and I.custid = W.custid(+)
    and I.item = W.item(+)
   group by
        decode(nvl(I.iskit,'N'),'N',I.item,'C',I.item,W.component),
        I.baseuom,
        decode(nvl(T.invstatus,'AV'),'AV','33','20')
union
 select I.item,
        I.baseuom,
        '33',
        0
   from custitem I
  where I.custid = in_custid
    and nvl(I.iskit,'N') != 'N';

CURSOR C_ITEMS_OLD(in_custid varchar2, in_facility varchar2)
IS
 select I.item,
        I.baseuom,
        decode(nvl(T.invstatus,'AV'),'AV','33','20') qual,
        sum(nvl(T.qty,0)) qty
   from custitemtot T, custitem I
  where I.custid = in_custid
    and in_facility = T.facility(+)
    and I.custid = T.custid(+)
    and I.item = T.item(+)
    and I.item not in ('UNKNOWN','RETURNS','x')
    and T.status(+) not in ('D','P','U','CM')
   group by
        I.item,
        I.baseuom,
        decode(nvl(T.invstatus,'AV'),'AV','33','20');


cursor C_RCPT_ORDS(in_facility char, in_custid char,
                   in_begin date, in_end date)
IS
select custid, orderid, shipid, reference, po, statusupdate
  from orderhdr
 where custid = in_custid
   and tofacility = in_facility
   and orderstatus = 'R'
   and statusupdate >= in_begin
   and statusupdate <= in_end;

cursor C_ORDDTLRCPT(in_orderid number, in_shipid number)
is
select R.item, R.lotnumber, R.uom, R.qtyrcvd, R.invstatus,
       D.dtlpassthruchar06 SAPLineNumber,
       decode(R.invstatus,'AV','33','20') qual
 from orderdtl D, orderdtlrcpt R
where R.orderid = in_orderid
  and R.shipid = in_shipid
  and R.orderid = D.orderid
  and R.shipid = D.shipid
  and R.orderitem = D.item
  and nvl(R.orderlot,'(null)') = nvl(D.lotnumber,'(null)');


cursor C_SHIP_ORDS(in_facility char, in_custid char,
                   in_begin date, in_end date)
IS
select custid, orderid, shipid, reference, po, statusupdate
  from orderhdr
 where custid = in_custid
   and fromfacility = in_facility
   and orderstatus = '9'
   and statusupdate >= in_begin
   and statusupdate <= in_end;

cursor C_ORDDTLSHIP(in_orderid number, in_shipid number)
is
select SP.item, SP.unitofmeasure, SP.invstatus, sum(SP.quantity) qty,
       D.dtlpassthruchar13 SAPLineNumber,
       decode(SP.invstatus,'AV','33','20') qual
 from orderdtl D, shippingplate SP
where SP.orderid = in_orderid
  and SP.shipid = in_shipid
  and SP.type in ('F','P')
  and SP.orderid = D.orderid
  and SP.shipid = D.shipid
  and SP.orderitem = D.item
  and nvl(SP.orderlot,'(null)') = nvl(SP.lotnumber,'(null)')
 group by SP.item, SP.unitofmeasure, SP.invstatus, D.dtlpassthruchar13,
       decode(SP.invstatus,'AV','33','20');


cursor C_INVADJACTIVITY(in_custid char, in_facility char) is
  select IA.rowid,IA.*
    from invadjactivity IA
   where IA.custid = in_custid
     and IA.facility = in_facility
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

cursor C_LPID(in_lpid varchar2) is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dteTest date;

seq number;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);


procedure insert_852dtl
(
    in_activity char,
    in_sequence number,
    in_item char,
    in_qty number,
    in_uom char,
    in_refq char,
    in_ref char,
    in_qual char,
    in_line char,
    in_actvdate date
 )
is
begin
   insert into prodactivity852dtlex
   (
       sessionid,
       custid,
       warehouse_id,
       item,
       activity_code,
       sequence,
       quantity,
       uom,
       ref_id_qualifier,
       ref_id,
       qty_qualifier,
       assigned_number,
       dt_qualifier,
       activity_date,
       activity_time
    )
    values
    (
       strSuffix,
       in_custid,
       FAC.facility,
       in_item,
       in_activity,
       in_sequence,
       in_qty,
       in_uom,
       in_refq,
       in_ref,
       in_qual,
       in_line,
       decode(in_activity,'QE','','945'),
       decode(in_activity,'QE','',to_char(in_actvdate,'YYYYMMDD')),
       decode(in_activity,'QE','',to_char(in_actvdate,'HH24:MI:SS'))
    );

end insert_852dtl;

begin

mark := 'Start';

out_errorno := 0;
out_msg := '';
seq := 0;

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'PRODACTV852HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;

-- Determine the facilities where there is activity
  -- zut.prt('About to start loop');
  for cf in C_FACILITIES(in_custid,
                         to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
                         to_date(in_enddatestr,'YYYYMMDDHH24MISS')) loop
     FAC := null;
     OPEN C_FACILITY(cf.facility);
     FETCH C_FACILITY into FAC;
     CLOSE C_FACILITY;


     insert into prodactivity852hdrex
        (
            sessionid,
            custid,
            start_date,
            end_date,
            warehouse_name,
            warehouse_id
        )
     values
        (
            strSuffix,
            in_custid,
            to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
            to_date(in_enddatestr,'YYYYMMDDHH24MISS'),
            FAC.name,
            cf.facility -- FAC.facility
        );

  -- For all items in the universe create the ending balance records
     -- zut.prt('  item loop for:'||cf.facility);

     for CI in C_ITEMS(in_custid, FAC.facility) loop
        seq := seq + 1;
        insert_852dtl('QE',seq,CI.item,CI.qty,CI.baseuom,
               '  ','  ',
               CI.qual,
               '',to_date(in_enddatestr,'YYYYMMDDHH24MISS'));

     end loop;
  -- For this facility find all closed orders that need to have stuff
  -- reported
     -- zut.prt('  rcpt loop for:'||cf.facility);
     for cord in C_RCPT_ORDS(FAC.facility,in_custid,
         to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
         to_date(in_enddatestr,'YYYYMMDDHH24MISS'))
     loop
       for crcpt in C_ORDDTLRCPT(cord.orderid, cord.shipid) loop
         seq := seq + 1;
         insert_852dtl('QR',seq,crcpt.item,crcpt.qtyrcvd,crcpt.uom,
               'PO',cord.po,
               crcpt.qual,
               crcpt.SAPLineNumber, cord.statusupdate);
       end loop; -- C_ORDDTLRCPT
     end loop; -- C_RCPT_ORDERS

     -- zut.prt('  ship loop for:'||cf.facility);
     for cord in C_SHIP_ORDS(FAC.facility,in_custid,
         to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
         to_date(in_enddatestr,'YYYYMMDDHH24MISS'))
     loop
       for cship in C_ORDDTLSHIP(cord.orderid, cord.shipid) loop

         seq := seq + 1;
         insert_852dtl('QS',seq,cship.item,cship.qty,cship.unitofmeasure,
               'CR',cord.reference,
               cship.qual,
               cship.SAPLineNumber,cord.statusupdate);
       end loop; -- C_ORDDTLSHIP
     end loop; -- C_SHIP_ORDERS
-- Loopthru the invadj for the customer
     for adj in C_INVADJACTIVITY(in_custid, FAC.facility) loop
       zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,
            strRegWhse,strRetWhse);
       if strWhse is not null then
         zedi.validate_interface(adj.rowid,strMovementCode,intErrorNo,strMsg);
         if intErrorNo = 0 then
            if ((adj.inventoryclass !=
                  nvl(adj.newinventoryclass,adj.inventoryclass)) or
                (adj.invstatus !=
                  nvl(adj.newinvstatus,adj.invstatus)) ) then
               qtyAdjust := adj.adjqty * -1;
            else
               qtyAdjust := adj.adjqty;
            end if;
            if instr(strMovementCode,'+33') > 0 then
               seq := seq + 1;
               insert_852dtl('QT',seq,adj.item,qtyAdjust,adj.uom,
                    'BP',to_char(adj.whenoccurred,'YYYYMMDDHH24MISS'),
                    '33','',adj.whenoccurred);
            end if;
            if instr(strMovementCode,'-33') > 0 then
               seq := seq + 1;
               insert_852dtl('QT',seq,adj.item,-qtyAdjust,adj.uom,
                    'BP',to_char(adj.whenoccurred,'YYYYMMDDHH24MISS'),
                    '33','',adj.whenoccurred);
            end if;
            if instr(strMovementCode,'+20') > 0 then
               seq := seq + 1;
               insert_852dtl('QT',seq,adj.item,qtyAdjust,adj.uom,
                    'BP',to_char(adj.whenoccurred,'YYYYMMDDHH24MISS'),
                    '20','',adj.whenoccurred);
            end if;
            if instr(strMovementCode,'-20') > 0 then
               seq := seq + 1;
               insert_852dtl('QT',seq,adj.item,-qtyAdjust,adj.uom,
                    'BP',to_char(adj.whenoccurred,'YYYYMMDDHH24MISS'),
                    '20','',adj.whenoccurred);
            end if;

         end if;
       end if;
     end loop; -- C_INVADJACTIVITY




  end loop;



-- create hdr view

cmdSql := 'create view prodactv852hdr_' || strSuffix ||
 '(custid,start_date,end_date,warehouse_name,warehouse_id) as '||
 ' select custid,start_date,end_date,warehouse_name,warehouse_id '||
 '  from prodactivity852hdrex '||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create dtl view

cmdSql := 'create view prodactv852dtl_' || strSuffix ||
 '(custid,warehouse_id,item) as '||
 ' select distinct custid,warehouse_id,item '||
 '  from prodactivity852dtlex '||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create par view

cmdSql := 'create view prodactv852par_' || strSuffix ||
 '(custid,warehouse_id,item,activity_code,sequence,quantity,uom,'||
 'ref_id_qualifier,ref_id,qty_qualifier) as ' ||
 ' select custid,warehouse_id,item,activity_code,sequence,quantity,uom, '||
 '  ref_id_qualifier,ref_id,qty_qualifier '||
 ' from prodactivity852dtlex '||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create prq view

cmdSql := 'create view prodactv852prq_' || strSuffix ||
 '(custid,warehouse_id,item,activity_code,sequence,assigned_number,'||
 'dt_qualifier,activity_date,activity_time) as '||
 ' select custid,warehouse_id,item,activity_code,sequence,assigned_number,'||
 'dt_qualifier,activity_date,activity_time '||
 ' from prodactivity852dtlex '||
 ' where sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zb852 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_prodactv852;

----------------------------------------------------------------------
-- end_prodactv852
----------------------------------------------------------------------
procedure end_prodactv852
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from prodactivity852hdrex where sessionid = strSuffix;
delete from prodactivity852dtlex where sessionid = strSuffix;

cmdSql := 'drop VIEW prodactv852dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW prodactv852par_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW prodactv852prq_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW prodactv852hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'ze852 ' || sqlerrm;
  out_errorno := sqlcode;
end end_prodactv852;



----------------------------------------------------------------------
-- begin_shipnote856
----------------------------------------------------------------------
procedure begin_shipnote856
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_allow_pick_status_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

CURSOR C_CUST(in_custid char)
RETURN customer%rowtype
IS
  SELECT *
    FROM customer
   WHERE custid = in_custid;

CURSOR C_LOAD(in_loadno number)
RETURN loads%rowtype
IS
  SELECT *
    FROM loads
   WHERE loadno = in_loadno;

CURSOR C_ORD(in_loadno number, in_stopno number,
             in_shipno number, in_consignee char)
RETURN orderhdr%rowtype
IS
  SELECT *
    FROM orderhdr
   WHERE loadno = in_loadno
     AND stopno = in_stopno
     AND shipno = in_shipno
     AND nvl(shipto, nvl(consignee,'o'||orderid||'-'||shipid)) = in_consignee;



cursor C_SHIPMENTS
IS
  select distinct loadno, stopno, shipno, custid,
         nvl(shipto, nvl(consignee,'o'||orderid||'-'||shipid)) consignee
    from orderhdr
   where orderstatus = '9'
     and custid = in_custid
     and loadno = decode(nvl(in_loadno,0), 0, loadno, in_loadno)
     and statusupdate >= nvl(to_date(in_begdatestr,'yyyymmddhh24miss'),
                           statusupdate)
     and statusupdate < nvl(to_date(in_enddatestr,'yyyymmddhh24miss'),
                           statusupdate+1);


cursor C_PICKSHIPMENTS
IS
  select distinct loadno, stopno, shipno, custid,
         nvl(shipto, nvl(consignee,'o'||orderid||'-'||shipid)) consignee
    from orderhdr
   where orderstatus = '9'
     and custid = in_custid
     and loadno = decode(nvl(in_loadno,0), 0, loadno, in_loadno)
     and statusupdate >= nvl(to_date(in_begdatestr,'yyyymmddhh24miss'),
                           statusupdate)
     and statusupdate < nvl(to_date(in_enddatestr,'yyyymmddhh24miss'),
                           statusupdate+1);

cursor C_SP(in_orderid number, in_shipid number)
IS
  select lpid
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and parentlpid is null;
     -- and type = 'M';    ????? Ask Brian about when an M is required

cursor C_ITM(in_lpid char)
IS
 select SP.item, SP.orderitem, SP.orderlot,
        SP.unitofmeasure, SP.uomentered, I.descr,
        sum(SP.weight) weight, sum(SP.quantity) quantity
   from custitem I, shippingplate SP
  where SP.type in ('F','P')
    and SP.custid = I.custid
    and SP.item = I.item
    and SP.lpid in
   (select lpid
      from shippingplate
      start with lpid = in_lpid
    connect by prior lpid = parentlpid)
   group by SP.item, SP.orderitem, SP.orderlot,
            SP.unitofmeasure, SP.uomentered, I.descr;


cursor C_ORDTL(in_orderid number, in_shipid number, in_orderitem char,
              in_orderlot char)
IS
 select *
   from orderdtl
  where orderid = in_orderid
    and shipid = in_shipid
    and item = in_orderitem
    and nvl(lotnumber,'<null>') = nvl(in_orderlot, '<null>');

cursor C_UPC(in_custid char, in_item char)
return custitemupcview%rowtype
IS
 select *
   from custitemupcview
  where custid = in_custid
    and item = in_item;


CUST customer%rowtype;
LOAD loads%rowtype;
ORD  orderhdr%rowtype;
ORDTL orderdtl%rowtype;
UPC custitemupcview%rowtype;
cship C_SHIPMENTS%rowtype;


curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);
l_structure varchar2(4);
l_asnnumber varchar2(30);
l_shipunits number(8);
l_weight number(8);

l_orders integer;
l_orderid number(9);
l_shipid number(2);
l_bol varchar2(15);
l_qty number(8);

ucc128 varchar2(20);

cnt integer;
errmsg varchar2(100);
strDebugYN char(1);

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin


out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIPNOTE856HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


  l_condition := null;

  if in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';


-- Get the customer information
  CUST := NULL;
  OPEN C_CUST(in_custid);
  FETCH C_CUST into CUST;
  CLOSE C_CUST;
  debugmsg('in_allow_pick_status_yn: '||in_allow_pick_status_yn);

-- Determine the distinct shipments in the period
    if nvl(in_allow_pick_status_yn,'N') = 'Y' then
        open C_PICKSHIPMENTS;
    else
        open C_SHIPMENTS;
    end if;

    loop
      if nvl(in_allow_pick_status_yn,'N') = 'Y' then
          fetch C_PICKSHIPMENTS into cship;
          exit when C_PICKSHIPMENTS%notfound;
      else
          fetch C_SHIPMENTS into cship;
          exit when C_SHIPMENTS%notfound;
      end if;

      l_structure := '0001';  -- only case for now
      l_asnnumber := cship.consignee||'-'||cship.loadno||'-'
                   ||cship.stopno||'-'||cship.shipno;

      if substr(cship.consignee,1,1) = 'o' then
         l_orderid := substr(cship.consignee,2,instr(cship.consignee,'-',2) - 2);
         l_shipid := substr(cship.consignee,instr(cship.consignee,'-',2)+1);
      else
        l_orderid := null;
        l_shipid := null;
      end if;

      l_orders := 0;
      if nvl(in_allow_pick_status_yn,'N') = 'Y' then
          select count(1)
            into l_orders
            from orderhdr
           where loadno = cship.loadno
             and orderstatus in ('6','7','8','9');
      else
      select count(1)
        into l_orders
        from orderhdr
       where loadno = cship.loadno
         and orderstatus = '9';
      end if;
      debugmsg('order count: '||l_orders);

      LOAD := NULL;
      OPEN C_LOAD(cship.loadno);
      FETCH C_LOAD into LOAD;
      CLOSE C_LOAD;

      ORD := NULL;
      OPEN C_ORD(cship.loadno, cship.stopno, cship.shipno, cship.consignee);
      FETCH C_ORD into ORD;
      CLOSE C_ORD;

      if l_orders = 1 then
         l_bol := ORD.orderid || '-'||ORD.shipid;
      else
         l_bol := cship.loadno;
      end if;

      select sum(1), sum(weight)
        into l_shipunits, l_weight
        from shippingplate
       where parentlpid is null
         -- and type = 'M'
         and (orderid, shipid) in
         (
            SELECT orderid, shipid
              FROM orderhdr
             WHERE loadno = cship.loadno
               AND stopno = cship.stopno
               AND shipno = cship.shipno
               AND nvl(shipto, nvl(consignee,'o'||orderid||'-'||shipid))
                   = cship.consignee
         );

      cnt := 0;
      SELECT sum(nvl(qtyorder,0)) - sum(nvl(qtyship,0))
        INTO cnt
        FROM orderhdr
       WHERE loadno = cship.loadno
         AND stopno = cship.stopno
         AND shipno = cship.shipno
         AND nvl(shipto, nvl(consignee,'o'||orderid||'-'||shipid))
                         = cship.consignee;

      insert into shipnote856hdrex
      (
        sessionid,
        asnnumber,
        structure,
        status,
        bol,
        custid,
        facility,
        loadno,
        consignee,
        shiptype,
        appointment,
        shipunits,
        weight,
        orderid,
        shipid
      )
      values
      (
        strSuffix,
        l_asnnumber,
        l_structure,
        decode(sign(cnt), 1, 'BO','CC'),
        l_bol,
        cship.custid,
        LOAD.facility,
        LOAD.loadno,
        cship.consignee,
        ORD.shiptype,
        to_char(ORD.arrivaldate,'YYYYMMDD'),
        l_shipunits,
        l_weight,
        l_orderid,
        l_shipid
      );

  -- now we need the order level
     for cord in C_ORD(cship.loadno, cship.stopno, cship.shipno,
                       cship.consignee) loop
         cnt := 0;
         select sum(1)
           into cnt
           from shippingplate
          where orderid = cord.orderid
            and shipid = cord.shipid
            and parentlpid is null;
            -- and type = 'M';
         insert into shipnote856ordex
         (
            sessionid,
            asnnumber,
            loadno,
            orderid,
            shipid,
            custid,
            shipunits
         )
         values
         (
            strsuffix,
            l_asnnumber,
            LOAD.loadno,
            cord.orderid,
            cord.shipid,
            cord.custid,
            cnt
         );
         for csp in C_SP(cord.orderid, cord.shipid) loop

            -- zut.prt('Got SP:'||csp.lpid);

            ucc128 := zedi.get_sscc18_code(cord.custid, '1', csp.lpid);

            insert into shipnote856tarex
            (
                sessionid,
                asnnumber,
                loadno,
                orderid,
                shipid,
                ucc128
            )
            values
            (
                strsuffix,
                l_asnnumber,
                LOAD.loadno,
                cord.orderid,
                cord.shipid,
                ucc128
            );

            for citm in C_ITM(csp.lpid) loop
                -- zut.prt('   Item:'||citm.item);

                ORDTL := null;
                OPEN C_ORDTL(cord.orderid, cord.shipid,
                            citm.orderitem, citm.orderlot);
                FETCH C_ORDTL into ORDTL;
                CLOSE C_ORDTL;

                UPC := null;
                OPEN C_UPC(cord.custid, citm.item);
                FETCH C_UPC into UPC;
                CLOSE C_UPC;

                l_qty := 0;
                if ORDTL.uomentered != citm.unitofmeasure then
                   zbut.translate_uom(cord.custid,
                        citm.item,
                        citm.quantity,
                        citm.unitofmeasure,
                        ORDTL.uomentered,
                        l_qty,
                        errmsg);
                else
                    l_qty := citm.quantity;
                end if;

                insert into shipnote856itmex
                (
                    sessionid,
                    asnnumber,
                    loadno,
                    orderid,
                    shipid,
                    custid,
                    ucc128,
                    item,
                    venditem,
                    upc,
                    shipped,
                    shipuom,
                    ordered,
                    orderuom,
                    orderlot
                )
                values
                (
                    strsuffix,
                    l_asnnumber,
                    LOAD.loadno,
                    cord.orderid,
                    cord.shipid,
                    cord.custid,
                    ucc128,
                    citm.item,
                    ORDTL.consigneesku,
                    UPC.upc,
                    l_qty,
                    citm.unitofmeasure,
                    ORDTL.qtyentered,
                    ORDTL.UOMentered,
                    citm.orderlot
                );
            end loop; -- citm C_ITM


         end loop; -- csp C_SP

     end loop; -- cord C_ORD


  end loop; -- cship C_SHIPMENTS

  if nvl(in_allow_pick_status_yn,'N') = 'Y' then
    close C_PICKSHIPMENTS;
  else
    close C_SHIPMENTS;
  end if;
-- Now create default views for these guys

-- Header view

cmdSql := 'create view shipnote856hdr_' || strSuffix ||
 '(custid,loadno,asnnumber,structure,shipdate,shiptime,shipstatus,' ||
 ' pronumber,shipunits,weight,uomweight,appointment,carrier,trailer,bol,'||
 ' transportation,carriername,customer_name,customer_addr1,customer_addr2,'||
 ' customer_city,customer_state,customer_postalcode,'||
 ' shipto_id,shipto_name,shipto_addr1,shipto_addr2,'||
 ' shipto_city,shipto_state,shipto_postalcode,'||
 ' facility_id,facility_name,facility_addr1,facility_addr2,'||
 ' facility_city,facility_state,facility_postalcode)'||
 'as select S.custid,S.loadno,S.asnnumber,S.structure,'||
 ' to_char(L.statusupdate,''YYYYMMDD''),'||
 ' to_char(L.statusupdate,''HH24MISS''),'||
 ' S.status,nvl(oh.prono,L.prono),S.shipunits,S.weight,''LB'',S.appointment,CA.carrier,'||
 ' L.trailer,S.bol,S.shiptype,CA.name,C.name,C.addr1,C.addr2,'||
 ' C.city,C.state,C.postalcode,'||
 ' decode(substr(S.consignee,1,1),''o'','''',CN.consignee),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptoname,CN.name),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptoaddr1,CN.addr1),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptoaddr2,CN.addr2),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptocity,CN.city),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptostate,CN.state),'||
 ' decode(substr(S.consignee,1,1),''o'',OH.shiptopostalcode,CN.postalcode),'||
 'F.facility,F.name,F.addr1,F.addr2,'||
 ' F.city,F.state,F.postalcode '||
 ' from orderhdr OH, carrier CA, facility F, customer C, consignee CN, '||
 ' loads L, shipnote856hdrex S '||
 ' where S.loadno = L.loadno'||
 '  and S.custid = C.custid'||
 '  and S.consignee = CN.consignee(+)'||
 '  and S.facility = F.facility'||
 '  and L.carrier = CA.carrier'||
 '  and S.orderid = OH.orderid(+)'||
 '  and S.shipid = OH.shipid(+)'||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Do order
cmdSql := 'create view shipnote856ord_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,po,reference,'||
 '  shipunits,paymentcode) '||
 ' as '||
 ' select S.custid,S.asnnumber,S.loadno,S.orderid,S.shipid,O.po,O.reference,'||
 'S.shipunits,'||
 '  decode(O.shipterms,''COL'',''CC'',''PPD'',''PP'',''??'') '||
 ' from orderhdr O, shipnote856ordex S ' ||
 ' where S.orderid = O.orderid '||
 '  and S.shipid = O.shipid '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



-- Do tare
cmdSql := 'create view shipnote856tar_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,ucc128) '||
 ' as '||
 ' select O.custid,S.asnnumber,S.loadno, S.orderid,S.shipid,S.ucc128 '||
 ' from orderhdr O, shipnote856tarex S '||
 ' where S.orderid = O.orderid '||
 '  and S.shipid = O.shipid '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Do item
cmdSql := 'create view shipnote856itm_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,ucc128,upc,item,venditem,shipped,' ||
 ' shipuom,orderer,orderuom,description) '||
 ' as ' ||
 ' select S.custid,S.asnnumber,S.loadno,S.orderid,S.shipid,S.ucc128,S.upc,S.item,'||
 ' S.venditem,S.shipped,S.shipuom,S.ordered,S.orderuom,I.descr '||
 ' from custitem I, shipnote856itmex S ' ||
 ' where S.custid = I.custid '||
 '  and S.item = I.item '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn856 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_shipnote856;



----------------------------------------------------------------------
-- end_shipnote856
----------------------------------------------------------------------
procedure end_shipnote856
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from shipnote856hdrex where sessionid = strSuffix;

delete from shipnote856ordex where sessionid = strSuffix;

delete from shipnote856tarex where sessionid = strSuffix;

delete from shipnote856itmex where sessionid = strSuffix;

cmdSql := 'drop view shipnote856itm_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856tar_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856ord_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn856 ' || sqlerrm;
  out_errorno := sqlcode;
end end_shipnote856;



----------------------------------------------------------------------
-- begin_shipnote856oldworld
----------------------------------------------------------------------
procedure begin_shipnote856oldworld
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

CURSOR C_CUST(in_custid char)
RETURN customer%rowtype
IS
  SELECT *
    FROM customer
   WHERE custid = in_custid;

CURSOR C_LOAD(in_loadno number)
RETURN loads%rowtype
IS
  SELECT *
    FROM loads
   WHERE loadno = in_loadno;

CURSOR C_ORD(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
  SELECT *
    FROM orderhdr
   WHERE orderid = in_orderid
     AND shipid = in_shipid;


cursor C_SHIPMENTS
IS
  select distinct loadno, stopno, shipno, custid,
         orderid, shipid, nvl(shipto, consignee) consignee
    from orderhdr
   where orderstatus = '9'
     and custid = in_custid
     and loadno = decode(nvl(in_loadno,0), 0, loadno, in_loadno)
     and statusupdate >= nvl(to_date(in_begdatestr,'yyyymmddhh24miss'),
                           statusupdate)
     and statusupdate < nvl(to_date(in_enddatestr,'yyyymmddhh24miss'),
                           statusupdate+1);


cursor C_SP(in_orderid number, in_shipid number)
IS
  select lpid
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and parentlpid is null;
     -- and type = 'M';    ????? Ask Brian about when an M is required

cursor C_ITM(in_lpid char)
IS
 select SP.item, SP.orderitem, SP.orderlot,
        SP.unitofmeasure, SP.uomentered, I.descr,
        sum(SP.weight) weight, sum(SP.quantity) quantity
   from custitem I, shippingplate SP
  where SP.type in ('F','P')
    and SP.custid = I.custid
    and SP.item = I.item
    and SP.lpid in
   (select lpid
      from shippingplate
      start with lpid = in_lpid
    connect by prior lpid = parentlpid)
   group by SP.item, SP.orderitem, SP.orderlot,
            SP.unitofmeasure, SP.uomentered, I.descr;


cursor C_ORDTL(in_orderid number, in_shipid number, in_orderitem char,
              in_orderlot char)
IS
 select *
   from orderdtl
  where orderid = in_orderid
    and shipid = in_shipid
    and item = in_orderitem
    and nvl(lotnumber,'<null>') = nvl(in_orderlot, '<null>');

cursor C_UPC(in_custid char, in_item char)
return custitemupcview%rowtype
IS
 select *
   from custitemupcview
  where custid = in_custid
    and item = in_item;


CUST customer%rowtype;
LOAD loads%rowtype;
ORD  orderhdr%rowtype;
ORDTL orderdtl%rowtype;
UPC custitemupcview%rowtype;


curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);
l_structure varchar2(4);
l_asnnumber varchar2(30);
l_shipunits number(8);
l_weight number(8);

l_orders integer;
l_orderid number(9);
l_shipid number(2);
l_bol varchar2(15);
l_qty number(8);

ucc128 varchar2(20);

cnt integer;
errmsg varchar2(100);

begin


out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIPNOTE856HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


  l_condition := null;

  if in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';


-- Get the customer information
  CUST := NULL;
  OPEN C_CUST(in_custid);
  FETCH C_CUST into CUST;
  CLOSE C_CUST;

-- Determine the distinct shipments in the period
  for cship in C_SHIPMENTS loop

      l_structure := '0001';  -- only case for now
      l_asnnumber := cship.orderid||'-'||cship.shipid;

      l_orders := 0;

      LOAD := NULL;
      OPEN C_LOAD(cship.loadno);
      FETCH C_LOAD into LOAD;
      CLOSE C_LOAD;

      ORD := NULL;
      OPEN C_ORD(cship.orderid, cship.shipid);
      FETCH C_ORD into ORD;
      CLOSE C_ORD;

      l_bol := ORD.orderid || '-'||ORD.shipid;

      select sum(1), sum(weight)
        into l_shipunits, l_weight
        from shippingplate
       where parentlpid is null
         -- and type = 'M'
         and orderid = cship.orderid
         and shipid = cship.shipid;


      cnt := 0;
      SELECT sum(nvl(qtyorder,0)) - sum(nvl(qtyship,0))
        INTO cnt
        FROM orderhdr
       WHERE orderid = cship.orderid
         AND shipid = cship.shipid;

      insert into shipnote856hdrex
      (
        sessionid,
        asnnumber,
        structure,
        status,
        bol,
        custid,
        facility,
        loadno,
        consignee,
        shiptype,
        appointment,
        shipunits,
        weight,
        orderid,
        shipid
      )
      values
      (
        strSuffix,
        l_asnnumber,
        l_structure,
        decode(sign(cnt), 1, 'BO','CC'),
        l_bol,
        cship.custid,
        LOAD.facility,
        LOAD.loadno,
        cship.consignee,
        ORD.shiptype,
        to_char(ORD.arrivaldate,'YYYYMMDD'),
        l_shipunits,
        l_weight,
        cship.orderid,
        cship.shipid
      );

  -- now we need the order level
     for cord in C_ORD(cship.orderid, cship.shipid) loop
         cnt := 0;
         select sum(1)
           into cnt
           from shippingplate
          where orderid = cord.orderid
            and shipid = cord.shipid
            and parentlpid is null;
            -- and type = 'M';
         insert into shipnote856ordex
         (
            sessionid,
            asnnumber,
            loadno,
            orderid,
            shipid,
            custid,
            shipunits
         )
         values
         (
            strsuffix,
            l_asnnumber,
            LOAD.loadno,
            cord.orderid,
            cord.shipid,
            cord.custid,
            cnt
         );
         for csp in C_SP(cord.orderid, cord.shipid) loop

            -- zut.prt('Got SP:'||csp.lpid);

            ucc128 := zedi.get_sscc18_code(cord.custid, '1', csp.lpid);

            insert into shipnote856tarex
            (
                sessionid,
                asnnumber,
                loadno,
                orderid,
                shipid,
                ucc128
            )
            values
            (
                strsuffix,
                l_asnnumber,
                LOAD.loadno,
                cord.orderid,
                cord.shipid,
                ucc128
            );

            for citm in C_ITM(csp.lpid) loop
                -- zut.prt('   Item:'||citm.item);

                ORDTL := null;
                OPEN C_ORDTL(cord.orderid, cord.shipid,
                            citm.orderitem, citm.orderlot);
                FETCH C_ORDTL into ORDTL;
                CLOSE C_ORDTL;

                UPC := null;
                OPEN C_UPC(cord.custid, citm.item);
                FETCH C_UPC into UPC;
                CLOSE C_UPC;

                l_qty := 0;
                if ORDTL.uomentered != citm.unitofmeasure then
                   zbut.translate_uom(cord.custid,
                        citm.item,
                        citm.quantity,
                        citm.unitofmeasure,
                        ORDTL.uomentered,
                        l_qty,
                        errmsg);
                else
                    l_qty := citm.quantity;
                end if;

                -- old world specific
                if ORDTL.dtlpassthruchar09 is not null then
                   UPC.upc := substr(ORDTL.dtlpassthruchar09,1,20);
                end if;

                insert into shipnote856itmex
                (
                    sessionid,
                    asnnumber,
                    loadno,
                    orderid,
                    shipid,
                    custid,
                    ucc128,
                    item,
                    venditem,
                    upc,
                    shipped,
                    shipuom,
                    ordered,
                    orderuom,
                    orderlot
                )
                values
                (
                    strsuffix,
                    l_asnnumber,
                    LOAD.loadno,
                    cord.orderid,
                    cord.shipid,
                    cord.custid,
                    ucc128,
                    citm.item,
                    ORDTL.consigneesku,
                    UPC.upc,
                    l_qty,
                    citm.unitofmeasure,
                    ORDTL.qtyentered,
                    ORDTL.UOMentered,
                    citm.orderlot
                );
            end loop; -- citm C_ITM


         end loop; -- csp C_SP

     end loop; -- cord C_ORD


  end loop; -- cship C_SHIPMENTS

-- Now create default views for these guys

-- Header view

cmdSql := 'create view shipnote856hdr_' || strSuffix ||
 '(custid,loadno,asnnumber,structure,shipdate,shiptime,shipstatus,' ||
 ' pronumber,shipunits,weight,uomweight,appointment,carrier,trailer,bol,'||
 ' transportation,carriername,customer_name,customer_addr1,customer_addr2,'||
 ' customer_city,customer_state,customer_postalcode,'||
 ' shipto_id,shipto_name,shipto_addr1,shipto_addr2,'||
 ' shipto_city,shipto_state,shipto_postalcode,'||
 ' facility_id,facility_name,facility_addr1,facility_addr2,'||
 ' facility_city,facility_state,facility_postalcode)'||
 'as select S.custid,S.loadno,S.asnnumber,S.structure,'||
 ' to_char(L.statusupdate,''YYYYMMDD''),'||
 ' to_char(L.statusupdate,''HH24MISS''),'||
 ' S.status,nvl(oh.prono,L.prono),S.shipunits,S.weight,''LB'',S.appointment,CA.carrier,'||
 ' L.trailer,S.bol,S.shiptype,CA.name,C.name,C.addr1,C.addr2,'||
 ' C.city,C.state,C.postalcode,'||
 ' decode(S.consignee,null,'''',CN.consignee),'||
 ' decode(S.consignee,null,OH.shiptoname,CN.name),'||
 ' decode(S.consignee,null,OH.shiptoaddr1,CN.addr1),'||
 ' decode(S.consignee,null,OH.shiptoaddr2,CN.addr2),'||
 ' decode(S.consignee,null,OH.shiptocity,CN.city),'||
 ' decode(S.consignee,null,OH.shiptostate,CN.state),'||
 ' decode(S.consignee,null,OH.shiptopostalcode,CN.postalcode),'||
 'F.facility,F.name,F.addr1,F.addr2,'||
 ' F.city,F.state,F.postalcode '||
 ' from orderhdr OH, carrier CA, facility F, customer C, consignee CN, '||
 ' loads L, shipnote856hdrex S '||
 ' where S.loadno = L.loadno'||
 '  and S.custid = C.custid'||
 '  and S.consignee = CN.consignee(+)'||
 '  and S.facility = F.facility'||
 '  and L.carrier = CA.carrier'||
 '  and S.orderid = OH.orderid(+)'||
 '  and S.shipid = OH.shipid(+)'||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Do order
cmdSql := 'create view shipnote856ord_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,po,reference,'||
 '  shipunits,paymentcode) '||
 ' as '||
 ' select S.custid,S.asnnumber,S.loadno,S.orderid,S.shipid,O.po,O.reference,'||
 'S.shipunits,'||
 '  decode(O.shipterms,''COL'',''CC'',''PPD'',''PP'',''??'') '||
 ' from orderhdr O, shipnote856ordex S ' ||
 ' where S.orderid = O.orderid '||
 '  and S.shipid = O.shipid '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



-- Do tare
cmdSql := 'create view shipnote856tar_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,ucc128) '||
 ' as '||
 ' select O.custid,S.asnnumber,S.loadno,S.orderid,S.shipid,S.ucc128 '||
 ' from orderhdr O, shipnote856tarex S '||
 ' where S.orderid = O.orderid '||
 '  and S.shipid = O.shipid '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Do item
cmdSql := 'create view shipnote856itm_' || strSuffix ||
 ' (custid,asnnumber,loadno,orderid,shipid,ucc128,upc,item,venditem,shipped,' ||
 ' shipuom,orderer,orderuom,description) '||
 ' as ' ||
 ' select S.custid,S.asnnumber,S.loadno,S.orderid,S.shipid,S.ucc128,S.upc,S.item,'||
 ' S.venditem,S.shipped,S.shipuom,S.ordered,S.orderuom,I.descr '||
 ' from custitem I, shipnote856itmex S ' ||
 ' where S.custid = I.custid '||
 '  and S.item = I.item '||
 '  and sessionid = '''||strSuffix||'''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn856 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_shipnote856oldworld;



----------------------------------------------------------------------
-- end_shipnote856oldworld
----------------------------------------------------------------------
procedure end_shipnote856oldworld
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

delete from shipnote856hdrex where sessionid = strSuffix;

delete from shipnote856ordex where sessionid = strSuffix;

delete from shipnote856tarex where sessionid = strSuffix;

delete from shipnote856itmex where sessionid = strSuffix;

cmdSql := 'drop view shipnote856itm_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856tar_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856ord_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipnote856hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn856 ' || sqlerrm;
  out_errorno := sqlcode;
end end_shipnote856oldworld;




----------------------------------------------------------------------
-- load_orders
----------------------------------------------------------------------
FUNCTION load_orders
(
    in_loadno   IN      number
)
RETURN varchar2
IS
  stat varchar2(2);
  cnt integer;
BEGIN
  stat := 'N';

  cnt := 0;

  select count(1)
    into cnt
    from orderhdr
   where loadno = in_loadno;

 if cnt > 1 then
    stat := 'Y';
 end if;

 return stat;

EXCEPTION WHEN OTHERS THEN
  return stat;
END load_orders;

FUNCTION split_shipment
(
    in_custid    IN      varchar2,
    in_reference IN      varchar2
)
RETURN varchar2
IS
  stat varchar2(2);
  cnt integer;
BEGIN
  stat := 'N';

  cnt := 0;

  select count(1)
    into cnt
    from orderhdr H
   where H.custid = in_custid
     and H.reference = in_reference
     and H.orderstatus != 'X';

 if cnt > 1 then
    stat := 'Y';
 end if;

 return stat;

EXCEPTION WHEN OTHERS THEN
  return stat;
END split_shipment;

FUNCTION split_item
(
    in_custid    IN      varchar2,
    in_reference IN      varchar2,
    in_item      IN      varchar2
)
RETURN varchar2
IS
  stat varchar2(2);
  cnt integer;
BEGIN
  stat := 'N';

  cnt := 0;

  select count(1)
    into cnt
    from orderdtl D, orderhdr H
   where H.custid = in_custid
     and H.reference = in_reference
     and H.orderstatus != 'X'
     and H.orderid = D.orderid
     and H.shipid = D.shipid
     and D.item = in_item;

 if cnt > 1 then
    stat := 'Y';
 end if;

 return stat;

EXCEPTION WHEN OTHERS THEN
  return stat;
END split_item;

FUNCTION sum_shipping_weight
(in_orderid IN number
,in_shipid  IN number
) return number is

out_weight shippingplate.weight%type;

begin

out_weight := 0;

select sum(nvl(weight,0))
  into out_weight
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and type in ('F','P');

return out_weight;

exception when others then
  return out_weight;
end sum_shipping_weight;

FUNCTION sscc_count
(in_orderid IN number
,in_shipid  IN number
) return number is

out_count number;

begin
out_count := 0;
select count(1)
  into out_count
  from caselabels
 where orderid = in_orderid
   and shipid = in_shipid;

return out_count;

exception when others then
  return out_count;
end sscc_count;

FUNCTION changed_qty
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
    in_lotnumber IN      varchar2
)
RETURN varchar2
IS
  stat varchar2(2);
  cnt integer;
BEGIN
  stat := 'N';

  cnt := 0;
    SELECT count(1)
      INTO cnt
      FROM oldorderdtl O, neworderdtl N
     WHERE O.orderid = in_orderid
       AND O.shipid = in_shipid
       AND O.item = in_item
       AND nvl(O.lotnumber,'<none>') = nvl(in_lotnumber,'<none>')
       AND O.chgdate = N.chgdate
       AND O.chguser = N.chguser
       AND O.chgrowid = N.chgrowid
       AND O.qtyorder > N.qtyorder
       AND O.chguser != 'IMPORDER';

 if cnt >= 1 then
    stat := 'Y';
 end if;

 return stat;

EXCEPTION WHEN OTHERS THEN
  return stat;
END changed_qty;

procedure begin_olson945
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
l_condition varchar2(200);

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'olson_945_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' and oh.orderid = '||to_char(in_orderid)
                 || ' and oh.shipid = '||to_char(in_shipid)
                 || ' ';
  elsif in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';

  --zut.prt('Condition = '||l_condition);

  -- Create header view
cmdSql := 'create view olson_945_hdr_' || strSuffix ||
  ' (custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
  'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
  'width,length,shiptoidcode,'||
  'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
  'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
  'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,'||
  'reportingcode,'||
  'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
  'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
  'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
  'depositor_name,depositor_id,'||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,seal,trailer,requested_ship'||
  ') '||
  'as select ' ||
  'oh.custid,'' '','' '',oh.loadno,oh.orderid,oh.shipid,oh.reference,'||
  'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid)))),'||
  'oh.statusupdate,oh.shipdate,nvl(deliveryservice,''OTHR''),'||
  'zim7.sum_shipping_weight(orderid,shipid),'||
  'zim7.sum_shipping_weight(orderid,shipid) / 2.2046,'||
  'zim7.sum_shipping_weight(orderid,shipid) / .0022046,'||
  'zim7.sum_shipping_weight(orderid,shipid) * 16,'||
  'substr(zoe.max_shipping_container(orderid,shipid),1,15),'||
  'zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),'||
  'oh.shipto,'||
  'decode(CN.consignee,null,shiptoname,CN.name),'||
  'decode(CN.consignee,null,shiptocontact,CN.contact),'||
  'decode(CN.consignee,null,shiptoaddr1,CN.addr1),'||
  'decode(CN.consignee,null,shiptoaddr2,CN.addr2),'||
  'decode(CN.consignee,null,shiptocity,CN.city),'||
  'decode(CN.consignee,null,shiptostate,CN.state),'||
  'decode(CN.consignee,null,shiptopostalcode,CN.postalcode),'||
  'decode(CN.consignee,null,shiptocountrycode,CN.countrycode),'||
  'decode(CN.consignee,null,shiptophone,CN.phone),'||
  'oh.carrier,ca.name,'||
  '''  '',oh.hdrpassthruchar06,oh.shiptype,oh.shipterms,''A'','||
  'oh.reference,oh.po,oh.hdrpassthruchar07,'||
  'to_char(oh.arrivaldate,''YYYYMMDD''),'||
  'to_char(oh.orderid)||''-''||to_char(oh.shipid),nvl(oh.prono,L.prono),'||
  'decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null),'||
  'decode(zim7.split_shipment(oh.custid, oh.reference),''Y'',oh.reference,null),'||
  'to_char(oh.dateshipped,''YYYYMMDD''),'||
  'to_char(oh.dateshipped,''HHMISS''),oh.qtyship,'||
  'zim7.sum_shipping_weight(orderid,shipid),''LB'',oh.cubeship,''CF'',0,''CT'','||
  'F.name,F.facility,C.name,'' '','||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,l.seal,l.trailer,oh.requested_ship'||
  ' from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh '||
  ' where orderstatus = ''9'' '||
  ' and oh.carrier = ca.carrier(+) '||
  ' and oh.loadno = L.loadno(+) ' ||
  ' and oh.fromfacility = F.facility(+) '||
  ' and oh.custid = C.custid(+) ' ||
  ' and oh.shipto = CN.consignee(+) ' ||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- Create LXD View
cmdSql := 'create view olson_945_lxd_' || strSuffix ||
 '(orderid,shipid,custid,assignedid) '||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10 '||
 ' from orderdtl d, orderhdr oh'||
 ' where orderstatus = ''9'' '||
 '  and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid '||
 ' and d.linestatus != ''X'''||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- Create Detail View
cmdSql := 'create view olson_945_dtl_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,shipticket,trackingno,servicecode,'||
 'lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,'||
 'statuscode,reference,linenumber,orderdate,po,qtyordered,qtyshipped,'||
 'qtydiff,uom,packlistshipdate,weight,weightquaifier,weightunit,' ||
 'description,upc'||
 ',DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03' ||
 ',DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07' ||
 ',DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11' ||
 ',DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15' ||
 ',DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19' ||
 ',DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03' ||
 ',DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07' ||
 ',DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10) '||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10,'||
 'substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),'||
 'decode(nvl(ca.multiship,''N''),''Y'','||
 '  substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
 ' nvl(oh.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid))),'||
 'nvl(oh.deliveryservice,''OTHR''),nvl(d.weightship,0)'||
 ',nvl(d.weightship,0) / 2.2046,nvl(d.weightship,0) / .0022046,' ||
 'nvl(d.weightship,0) * 16,'||
 'd.item,d.lotnumber,nvl(d.lotnumber,''(none)''),'||
 'decode(D.linestatus, ''X'',''CU'','||
 'decode(nvl(d.qtyship,0), 0,''DS'','||
        'decode(zim7.split_item(oh.custid,oh.reference,d.item),'||
                '''Y'',''SS'','||
         'decode(zim7.changed_qty(oh.orderid,oh.shipid,'||
                                  'd.item,d.lotnumber),'||
            '''Y'',''PR'',''CC'')))),'||
 'oh.reference,'||
 'nvl(d.dtlpassthrunum10,''000000''),oh.entrydate,oh.po,d.qtyentered,'||
 'nvl(d.qtyship,0),'||
 'nvl(d.qtyship,0) - d.qtyentered,d.uom,oh.packlistshipdate,'||
 'nvl(d.weightship,0),''G'','||
 '''L'', nvl(d.dtlpassthruchar10,i.descr), nvl(D.dtlpassthruchar09,U.upc) ' ||
 ',D.DTLPASSTHRUCHAR01,D.DTLPASSTHRUCHAR02,D.DTLPASSTHRUCHAR03' ||
 ',D.DTLPASSTHRUCHAR04,D.DTLPASSTHRUCHAR05,D.DTLPASSTHRUCHAR06,D.DTLPASSTHRUCHAR07' ||
 ',D.DTLPASSTHRUCHAR08,D.DTLPASSTHRUCHAR09,D.DTLPASSTHRUCHAR10,D.DTLPASSTHRUCHAR11' ||
 ',D.DTLPASSTHRUCHAR12,D.DTLPASSTHRUCHAR13,D.DTLPASSTHRUCHAR14,D.DTLPASSTHRUCHAR15' ||
 ',D.DTLPASSTHRUCHAR16,D.DTLPASSTHRUCHAR17,D.DTLPASSTHRUCHAR18,D.DTLPASSTHRUCHAR19' ||
 ',D.DTLPASSTHRUCHAR20,D.DTLPASSTHRUNUM01,D.DTLPASSTHRUNUM02,D.DTLPASSTHRUNUM03' ||
 ',D.DTLPASSTHRUNUM04,D.DTLPASSTHRUNUM05,D.DTLPASSTHRUNUM06,D.DTLPASSTHRUNUM07' ||
 ',D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10 '||
 ' from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh'||
 ' where orderstatus = ''9'' '||
 '  and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid '||
 ' and oh.carrier = ca.carrier(+) '||
 ' and d.custid = i.custid(+) '||
 ' and d.item = i.item(+) '||
 ' and d.custid = U.custid(+) '||
 ' and d.item = U.item(+) '||
 ' and d.linestatus != ''X'''||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


  -- Create man (sscc18 view)
cmdSql := 'create view olson_945_s18_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,sscc18,qtypercase,caseweight) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.barcode, '||
 ' zci.item_touom_qty(s.custid,s.item,''CS''),'||
 ' zci.item_weight(s.custid,s.item,''CS'') ' ||
 'from caselabels s, orderhdr oh '||
 'where oh.orderstatus = ''9'' '||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.barcode is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

  -- Create man (serial number view)
cmdSql := 'create view olson_945_man_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,serialnumber) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.serialnumber '||
 'from shippingplate s, orderhdr oh '||
 'where oh.orderstatus = ''9'' '||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.status||'''' = ''SH'''||
 ' and s.serialnumber is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn945 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_olson945;

procedure end_olson945
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop VIEW olson_945_s18_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW olson_945_man_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW olson_945_lxd_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW olson_945_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW olson_945_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn945 ' || sqlerrm;
  out_errorno := sqlcode;
end end_olson945;

procedure begin_ship_notify
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_zero_shipped_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

curFunc integer;
cmdSql varchar2(20000);
cmdAnd varchar2(1000);
strDebugYN char(1);
strSuffix varchar2(32);
viewcount integer;
cntRows integer;

procedure debugmsg(in_text varchar2) is

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

procedure append_oh_clause
is
begin
if upper(rtrim(in_include_cancelled_orders_yn)) = 'Y' then
  cmdSql := cmdSql || ' and oh.orderstatus in (''9'',''X'') ';
else
  cmdSql := cmdSql || ' and oh.orderstatus = ''9'' ';
end if;

if nvl(in_loadno,0) != 0 then
  cmdSql := cmdSql || ' and oh.loadno = ' || in_loadno || ' ';
elsif nvl(in_orderid,0) != 0 then
  cmdSql := cmdSql || ' and oh.orderid = ' || in_orderid || ' ';
  cmdSql := cmdSql || ' and oh.shipid = ' || in_shipid || ' ';
else
  cmdSql := cmdSql || ' and oh.statusupdate >= to_date(''' || in_begdatestr
        || ''', ''yyyymmddhh24miss'')'
        ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
        || ''', ''yyyymmddhh24miss'') ';
end if;

cmdSql := cmdSql || ' and oh.custid = ''' || in_custid || ''' ';

end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIP_NOTIFY_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('create hdr view');
cmdSql :=
 ' CREATE VIEW ship_notify_hdr_' || strSuffix || ' ' ||
 ' (custid,company,warehouse,orderid,shipid,reference,trackingno,dateshipped' ||
 ' ,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,width,length,shiptoname' ||
 ',shiptocontact,shiptoaddr1,shiptoaddr2,shiptocity,shiptostate,shiptopostalcode'||
 ',shiptocountrycode,shiptophone,carrier,carrierused,cost,packlistshipdate,pronumber'||
 ',outpallets,po,hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,'||
 'hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,hdrpassthruchar09,'||
 'hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,hdrpassthruchar13,hdrpassthruchar14,'||
 'hdrpassthruchar15,hdrpassthruchar16,hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,'||
 'hdrpassthruchar20,hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,'||
 'hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,hdrpassthrunum09,'||
 'hdrpassthrunum10,shipterms,loadno,order_count,order_seq,billoflading,'||
 'saturdaydelivery,shiptype,prono_or_trackingno)'||
 ' as select custid, hdrpassthruchar05, hdrpassthruchar06, orderid, shipid,reference,'||
 'decode(nvl(ca.multiship,''N''),''Y'',substr(zoe.max_trackingno(orderid,shipid),1,30),'||
 ' to_char(orderid) || ''-'' || to_char(shipid)),oh.statusupdate,shipdate,nvl(deliveryservice,''OTHR''),'||
 'zoe.sum_shipping_weight(orderid,shipid),'||
 'zoe.sum_shipping_weight(orderid,shipid) / 2.2046,'||
 'zoe.sum_shipping_weight(orderid,shipid) / .0022046,'||
 'zoe.sum_shipping_weight(orderid,shipid) * 16,'||
 'substr(zoe.max_shipping_container(orderid,shipid),1,15),'||
 'zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),'||
 'zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),'||
 'zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),'||
 'decode(CN.consignee,null,shiptoname,CN.name),'||
 'decode(CN.consignee,null,shiptocontact,CN.contact),'||
 'decode(CN.consignee,null,shiptoaddr1,CN.addr1),'||
 'decode(CN.consignee,null,shiptoaddr2,CN.addr2),'||
 'decode(CN.consignee,null,shiptocity,CN.city),'||
 'decode(CN.consignee,null,shiptostate,CN.state),'||
 'decode(CN.consignee,null,shiptopostalcode,CN.postalcode),'||
 'decode(CN.consignee,null,shiptocountrycode,CN.countrycode),'||
 'decode(CN.consignee,null,shiptophone,CN.phone),'||
 'oh.carrier,'||
 'substr(zoe.max_carrierused(orderid,shipid),1,10),'||
 'zoe.sum_shipping_cost(orderid,shipid),packlistshipdate,nvl(oh.prono,lo.prono),'||
 'zpt.sum_outpallets(oh.loadno,oh.orderid,oh.shipid),po,hdrpassthruchar01,'||
 'hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,hdrpassthruchar05,'||
 'hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,hdrpassthruchar09,'||
 'hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,hdrpassthruchar13,'||
 'hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,hdrpassthruchar17,'||
 'hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,hdrpassthrunum01,'||
 'hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,hdrpassthrunum05,'||
 'hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,hdrpassthrunum09,'||
 'hdrpassthrunum10,nvl(lo.shipterms,oh.shipterms),oh.loadno,'||
 'zimsb.order_count_on_load(oh.loadno),'||
 'zimsb.order_seq_on_load(oh.loadno,oh.orderid,oh.shipid),'||
 'nvl(nvl(lo.billoflading,oh.billoflading),to_char(orderid)||''-''||to_char(shipid)),'||
 'oh.saturdaydelivery,nvl(lo.shiptype,oh.shiptype),'||
 'nvl(substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),nvl(oh.prono,lo.prono))'||
 ' from consignee cn, carrier ca, loads lo, orderhdr oh '||
 ' where oh.carrier = ca.carrier(+) and oh.loadno = lo.loadno(+) ' ||
 ' and oh.shipto = CN.consignee(+) ';

debugmsg('append_oh_clause');
append_oh_clause;
debugmsg('execute hdr');
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
begin
  execute immediate cmdSql;
exception when others then
  out_msg := 'zimbsnhdr ' || sqlerrm;
  out_errorno := sqlcode;
  return;
end;

debugmsg('create container');
cmdSql :=
'create view ship_notify_container_' || strSuffix || ' ' ||
'(orderid,shipid,custid,shipticket,ucc128,trackingno,carrier,dateshipped'||
',servicecode,lbs,kgs,gms,ozs,carrierused,reason,cost,packlistshipdate,qty)'||
' as select oh.orderid, oh.shipid, oh.custid, d.parentlpid,'||
'zedi.get_sscc18_code(d.custid, ''1'', d.parentlpid),'||
'decode(nvl(c.multiship,''N''),''Y'',substr(zmp.shipplate_trackingno(d.parentlpid),1,30),'||
' to_char(oh.orderid) || ''-'' || to_char(oh.shipid)),'||
'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),'||
'sum(d.weight),sum(d.weight / 2.2046),sum(d.weight / .0022046),sum(d.weight * 16),'||
'substr(zsp.carrierused(d.orderid,d.shipid,d.parentlpid),1,10),'||
'substr(zsp.reason(d.orderid,d.shipid,d.parentlpid),1,100),'||
'zsp.cost(d.orderid,d.shipid,d.parentlpid),oh.packlistshipdate,sum(d.quantity)'||
' from carrier c, shippingplate d, orderhdr oh '||
' where oh.orderid = d.orderid and oh.shipid = d.shipid and d.parentlpid is not null'||
' and d.status = ''SH'' and oh.carrier = c.carrier(+) ';
append_oh_clause;
cmdSql := cmdSql ||
' group by oh.orderid,oh.shipid,oh.custid,d.parentlpid,'||
' zedi.get_sscc18_code(d.custid, ''1'', d.parentlpid),'||
'decode(nvl(c.multiship,''N''),''Y'',substr(zmp.shipplate_trackingno(d.parentlpid),1,30),'||
'to_char(oh.orderid) || ''-'' || to_char(oh.shipid)),'||
'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),'||
'substr(zsp.carrierused(d.orderid,d.shipid,d.parentlpid),1,10),'||
'substr(zsp.reason(d.orderid,d.shipid,d.parentlpid),1,100),'||
'zsp.cost(d.orderid,d.shipid,d.parentlpid),oh.packlistshipdate';

debugmsg('append_oh_clause');
if upper(rtrim(in_include_zero_shipped_yn)) = 'Y' then
   cmdSql := cmdSql ||
  ' union ' ||
  ' select oh.orderid,oh.shipid,oh.custid,''NONE'',null,null,'||
  'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),'||
  '0,0,0,0,null,null,0,oh.packlistshipdate,0'||
  ' from orderhdr oh '||
  ' where exists (select * from orderdtl od where oh.orderid = od.orderid and ' ||
  ' oh.shipid = od.shipid and nvl(od.qtyship,0) = 0) ';
  append_oh_clause;
end if;
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
debugmsg('execute container');

begin
  execute immediate cmdSql;
exception when others then
  out_msg := 'zimbsncontainer ' || sqlerrm;
  out_errorno := sqlcode;
  return;
end;

debugmsg('create contents');
cmdSql :=
'create view ship_notify_contents_' || strSuffix || ' ' ||
'(orderid,shipid,custid,shipticket,trackingno,carrier,dateshipped,servicecode,'||
'lbs,kgs,gms,ozs,item,itemdescr,reference,linenumber,orderdate,po,qty,uom,lotnumber,'||
'serialnumber,linenumberstr,packlistshipdate,useritem1,useritem2,useritem3,qtyorder)'||
'as select oh.orderid,oh.shipid,oh.custid,nvl(d.parentlpid,lpid),'||
'decode(nvl(c.multiship,''N''),''Y'','||
'  substr(zmp.shipplate_trackingno(nvl(d.parentlpid,lpid)),1,30),'||
'  to_char(oh.orderid) || ''-'' || to_char(oh.shipid)),'||
'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),d.weight,d.weight / 2.2046,'||
'd.weight / .0022046,d.weight * 16,d.item,substr(zit.item_descr(d.custid,d.item),1,255),'||
'oh.reference,zoe.line_number(d.orderid,d.shipid,d.orderitem,d.orderlot),oh.entrydate,'||
'oh.po,d.quantity,d.unitofmeasure,d.lotnumber,d.serialnumber,'||
'substr(zoe.line_number_str(d.orderid,d.shipid,d.orderitem,d.orderlot),3,4),'||
'oh.packlistshipdate,d.useritem1,d.useritem2,d.useritem3,'||
'zoe.line_qtyorder(d.orderid,d.shipid,d.orderitem,d.orderlot)'||
' from carrier c, shippingplate d, orderhdr oh '||
'where oh.orderid = d.orderid and oh.shipid = d.shipid and d.type in (''F'',''P'')'||
'  and d.status = ''SH'' and oh.carrier = c.carrier(+)';

debugmsg('append_oh_clause');
append_oh_clause;
debugmsg('execute contents');

begin
  execute immediate cmdSql;
exception when others then
  out_msg := 'zimbsncontents ' || sqlerrm;
  out_errorno := sqlcode;
  return;
end;

debugmsg('create items');
cmdSql :=
'create view ship_notify_items_' || strSuffix || ' ' ||
'(orderid,shipid,custid,shipticket,trackingno,carrier,dateshipped,servicecode'||
',lbs,kgs,gms,ozs,item,itemdescr,reference,linenumber,orderdate,po,qty,uom'||
',lotnumber,serialnumber,linenumberstr,packlistshipdate,useritem1,useritem2'||
',useritem3,qtyorder,qtyentered,uomentered,DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02'||
',DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06'||
',DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10'||
',DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14'||
',DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18'||
',DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02'||
',DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06'||
',DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10'||
',DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,DTLPASSTHRUDATE04'||
',DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,prono_or_trackingno)'||
' as select oh.orderid,oh.shipid,oh.custid,nvl(d.parentlpid,lpid),'||
'decode(nvl(c.multiship,''N''),''Y'','||
'  substr(zmp.shipplate_trackingno(nvl(d.parentlpid,lpid)),1,30),'||
'  to_char(oh.orderid) || ''-'' || to_char(oh.shipid)),'||
'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),'||
'd.weight,d.weight / 2.2046,d.weight / .0022046,d.weight * 16,'||
'nvl(d.item,od.item),substr(zit.item_descr(oh.custid,nvl(d.item,od.item)),1,255),'||
'oh.reference,zoe.line_number(od.orderid,od.shipid,od.item,od.lotnumber),'||
'oh.entrydate,oh.po,d.quantity,nvl(d.unitofmeasure,od.uom),nvl(d.lotnumber,od.lotnumber),d.serialnumber,'||
'substr(zoe.line_number_str(od.orderid,od.shipid,od.item,nvl(d.orderlot,od.lotnumber)),3,4),'||
'oh.packlistshipdate,d.useritem1,d.useritem2,d.useritem3,'||
'zoe.line_qtyorder(od.orderid,od.shipid,od.item,od.lotnumber),'||
'decode(mod(zcu.equiv_uom_qty(oh.custid,nvl(d.item,od.item),nvl(d.unitofmeasure,od.uom),d.quantity,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,nvl(d.orderitem,od.item),nvl(d.orderlot,od.lotnumber)),1,4)),1),'||
'0,zcu.equiv_uom_qty(oh.custid,nvl(d.item,od.item),nvl(d.unitofmeasure,od.uom),d.quantity,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,nvl(d.orderitem,od.item),nvl(d.orderlot,od.lotnumber)),1,4)),'||
'd.quantity),decode(mod(zcu.equiv_uom_qty(oh.custid,nvl(d.item,od.item),nvl(d.unitofmeasure,od.uom),d.quantity,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,nvl(d.orderitem,od.item),nvl(d.orderlot,od.lotnumber)),1,4)),1),'||
'0,substr(zim14.line_uomentered(od.orderid,od.shipid,nvl(d.orderitem,od.item),nvl(d.orderlot,od.lotnumber)),1,4),'||
'nvl(d.unitofmeasure,od.uom)),od.DTLPASSTHRUCHAR01,od.DTLPASSTHRUCHAR02,od.DTLPASSTHRUCHAR03'||
',od.DTLPASSTHRUCHAR04,od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,od.DTLPASSTHRUCHAR07'||
',od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,od.DTLPASSTHRUCHAR10,od.DTLPASSTHRUCHAR11'||
',od.DTLPASSTHRUCHAR12,od.DTLPASSTHRUCHAR13,od.DTLPASSTHRUCHAR14,od.DTLPASSTHRUCHAR15'||
',od.DTLPASSTHRUCHAR16,od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,od.DTLPASSTHRUCHAR19'||
',od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,od.DTLPASSTHRUNUM03'||
',od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,od.DTLPASSTHRUNUM07'||
',od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,od.DTLPASSTHRUDATE01'||
',od.DTLPASSTHRUDATE02,od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01'||
',od.DTLPASSTHRUDOLL02'||
',nvl(substr(zoe.max_trackingno(od.orderid,od.shipid,od.item,od.lotnumber),1,30),nvl(oh.prono,lo.prono))'||
' from loads lo, carrier c, shippingplate d, orderdtl od, orderhdr oh ';
cmdSql := cmdSql ||
' where oh.orderid = d.orderid and oh.shipid = d.shipid and d.type in (''F'',''P'')'||
'  and d.status = ''SH''  and oh.carrier = c.carrier(+)'||
'  and d.orderid = od.orderid and d.shipid = od.shipid and oh.loadno = lo.loadno(+) '||
'  and d.orderitem = od.item and nvl(d.orderlot,''(none)'') = nvl(od.lotnumber,''(none)'')';

debugmsg('append_oh_clause');
append_oh_clause;
if upper(rtrim(in_include_zero_shipped_yn)) = 'Y' then
  cmdSql := cmdSql ||
' union all ' ||
' select oh.orderid,oh.shipid,oh.custid,''NONE'','||
'decode(nvl(c.multiship,''N''),''Y'','||
'  substr(zmp.shipplate_trackingno(''x''),1,30),'||
'  to_char(oh.orderid) || ''-'' || to_char(oh.shipid)),'||
'oh.carrier,oh.statusupdate,nvl(oh.deliveryservice,''OTHR''),'||
'0,0 / 2.2046,0 / .0022046,0 * 16,'||
'nvl(od.item,od.item),substr(zit.item_descr(oh.custid,nvl(od.item,od.item)),1,255),'||
'oh.reference,zoe.line_number(od.orderid,od.shipid,od.item,od.lotnumber),'||
'oh.entrydate,oh.po,0,nvl(od.uom,od.uom),od.lotnumber,null,'||
'substr(zoe.line_number_str(od.orderid,od.shipid,od.item,od.lotnumber),3,4),'||
'oh.packlistshipdate,null,null,null,'||
'zoe.line_qtyorder(od.orderid,od.shipid,od.item,od.lotnumber),'||
'decode(mod(zcu.equiv_uom_qty(oh.custid,nvl(od.item,od.item),nvl(od.uom,od.uom),0,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,od.item,od.lotnumber),1,4)),1),'||
'0,zcu.equiv_uom_qty(oh.custid,nvl(od.item,od.item),nvl(od.uom,od.uom),0,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,od.item,od.lotnumber),1,4)),'||
'0),decode(mod(zcu.equiv_uom_qty(oh.custid,nvl(od.item,od.item),nvl(od.uom,od.uom),0,'||
'substr(zim14.line_uomentered(od.orderid,od.shipid,od.item,od.lotnumber),1,4)),1),'||
'0,substr(zim14.line_uomentered(od.orderid,od.shipid,od.item,od.lotnumber),1,4),'||
'nvl(od.uom,od.uom)),od.DTLPASSTHRUCHAR01,od.DTLPASSTHRUCHAR02,od.DTLPASSTHRUCHAR03'||
',od.DTLPASSTHRUCHAR04,od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,od.DTLPASSTHRUCHAR07'||
',od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,od.DTLPASSTHRUCHAR10,od.DTLPASSTHRUCHAR11'||
',od.DTLPASSTHRUCHAR12,od.DTLPASSTHRUCHAR13,od.DTLPASSTHRUCHAR14,od.DTLPASSTHRUCHAR15'||
',od.DTLPASSTHRUCHAR16,od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,od.DTLPASSTHRUCHAR19'||
',od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,od.DTLPASSTHRUNUM03'||
',od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,od.DTLPASSTHRUNUM07'||
',od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,od.DTLPASSTHRUDATE01'||
',od.DTLPASSTHRUDATE02,od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01'||
',od.DTLPASSTHRUDOLL02'||
',nvl(substr(zoe.max_trackingno(od.orderid,od.shipid,null,null),1,30),nvl(oh.prono,lo.prono))'||
' from loads lo, carrier c, orderdtl od, orderhdr oh ';
cmdSql := cmdSql ||
' where oh.carrier = c.carrier(+)'||
'  and oh.orderid = od.orderid and oh.shipid = od.shipid'||
'  and nvl(od.qtyship,0) = 0 ' ||
'  and oh.loadno = lo.loadno(+) ';
debugmsg('append_oh_clause');
append_oh_clause;
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
end if;
debugmsg('execute items');

begin
  execute immediate cmdSql;
exception when others then
  out_msg := 'zimbsnitems ' || sqlerrm;
  out_errorno := sqlcode;
  return;
end;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_ship_notify;

procedure end_ship_notify
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

execute immediate
  'drop view ship_notify_container_' || strSuffix;
execute immediate
  'drop view ship_notify_contents_' || strSuffix;
execute immediate
  'drop view ship_notify_items_' || strSuffix;
execute immediate
  'drop view ship_notify_hdr_' || strSuffix;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn ' || sqlerrm;
  out_errorno := sqlcode;
end end_ship_notify;

procedure begin_stock_status_nsd
(in_facility IN varchar2
,in_custid IN varchar2
,in_active_items_only_yn IN varchar2
,in_exclude_zero_balance_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'STOCK_STATUS_NSD_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


cmdSql := 'create view stock_status_nsd_' || strSuffix ||
' (facility,custid,item,nsd_status,qty) as ' ||
' select facility,custid,item,''N'',sum(nvl(qty,0) * zci.custitem_sign(status)) from custitemtot ' ||
' where item not in (''UNKNOWN'',''RETURNS'',''x'') and invstatus != ''SU'' ' ||
'  and ( ((invstatus = ''AV'') and (status in (''CM'',''I'',''PN''))) or ' ||
'        ((invstatus not in (''AV'',''DM'')) and (status in (''A'',''M'',''PN''))) ) ';
if nvl(rtrim(in_active_items_only_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' and exists (select * from custitem where custitemtot.custid = ' ||
  'custitem.custid and custitemtot.item = custitem.item and custitem.status = ''ACTV'') ';
end if;
if nvl(rtrim(in_facility),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and facility = ''' || in_facility || '''';
end if;
if nvl(rtrim(in_custid),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and custid = ''' || in_custid || '''';
end if;
cmdSql := cmdSql || ' group by facility,custid,item,''N'' ';
if nvl(rtrim(in_exclude_zero_balance_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' having sum(nvl(qty,0) * zci.custitem_sign(status)) > 0 ';
end if;
cmdSql := cmdSql ||
' union select facility, custid, item, ''S'', sum(nvl(qty,0) * zci.custitem_sign(status)) ' ||
' from custitemtot where item not in (''UNKNOWN'',''RETURNS'',''x'') and invstatus = ''AV'' ' ||
' and status in (''A'',''M'',''CM'',''PN'') ';
if nvl(rtrim(in_active_items_only_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' and exists (select * from custitem where custitemtot.custid = ' ||
  'custitem.custid and custitemtot.item = custitem.item and custitem.status = ''ACTV'') ';
end if;
if nvl(rtrim(in_facility),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and facility = ''' || in_facility || '''';
end if;
if nvl(rtrim(in_custid),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and custid = ''' || in_custid || '''';
end if;
cmdSql := cmdSql || ' group by facility,custid,item,''S'' ';
if nvl(rtrim(in_exclude_zero_balance_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' having sum(nvl(qty,0) * zci.custitem_sign(status)) > 0 ';
end if;
cmdSql := cmdSql ||
' union select facility, custid, item, ''D'', sum(nvl(qty,0)) ' ||
' from custitemtot where item not in (''UNKNOWN'',''RETURNS'',''x'') and invstatus != ''SU'' ' ||
'  and invstatus = ''DM'' and status in (''A'',''M'',''PN'') ';
if nvl(rtrim(in_active_items_only_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' and exists (select * from custitem where custitemtot.custid = ' ||
  'custitem.custid and custitemtot.item = custitem.item and custitem.status = ''ACTV'') ';
end if;
if nvl(rtrim(in_facility),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and facility = ''' || in_facility || '''';
end if;
if nvl(rtrim(in_custid),'ALL') != 'ALL' then
  cmdSql := cmdSql || ' and custid = ''' || in_custid || '''';
end if;
cmdSql := cmdSql || ' group by facility,custid,item,''D'' ';
if nvl(rtrim(in_exclude_zero_balance_yn),'N') = 'Y' then
  cmdSql := cmdSql || ' having sum(nvl(qty,0) * zci.custitem_sign(status)) > 0 ';
end if;

if strDebugYN = 'Y' then
  cntRows := 1;
  while (cntRows * 60) < (Length(cmdSql)+60)
  loop
    zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
    cntRows := cntRows + 1;
  end loop;
end if;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss: ' || sqlerrm;
  out_errorno := sqlcode;
end begin_stock_status_nsd;

procedure end_stock_status_nsd
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'drop VIEW stock_status_nsd_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimessn ' || sqlerrm;
  out_errorno := sqlcode;
end end_stock_status_nsd;

FUNCTION find_po
(in_lpid IN varchar2
) return varchar2
IS
l_po plate.po%type;

BEGIN

    l_po := null;

    select po
      into l_po
      from allplateview
     where lpid = in_lpid;

    return l_po;

EXCEPTION WHEN OTHERS THEN
    return null;
END find_po;

FUNCTION abc_reference
(in_orderid IN number
,in_shipid IN number
,in_abc_revisions_column IN varchar2
) return varchar2
IS
strReference orderhdr.reference%type;
strPassthru orderhdr.hdrpassthruchar01%type;
pos integer;
cmdSql varchar2(2000);
BEGIN
   strReference := null;

   if in_abc_revisions_column is null  then
      select reference into strReference
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
      return strReference;
   end if;

   cmdsql := 'select reference, '|| in_abc_revisions_column || ' '||
             'from orderhdr ' ||
             'where orderid = ' || in_orderid  ||
             'and shipid = ' || in_shipid ;


   execute immediate cmdsql into strReference, strPassthru;
   select instr(strReference, nvl(strPassthru, '^'), 1, 1) into pos from dual;
   if pos = 0 then
      return strReference;
   end if;
   select substr(strReference, 1, pos - 1) into strReference from dual;
   return strReference;


EXCEPTION WHEN OTHERS THEN
    return strReference;
END abc_reference;


----------------------------------------------------------------------
-- begin_stdinvadj947
----------------------------------------------------------------------
procedure begin_stdinvadj947
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_947_by_transaction_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;


cursor C_INVADJACTIVITY is
  select IA.rowid,IA.*, U.upc
    from custitemupcview U, invadjactivity IA
   where IA.custid = in_custid
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and IA.custid = U.custid(+)
     and IA.item = U.item(+)
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

cursor C_LPID(in_lpid varchar2) is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
strNewRsnCode invadjactivity.adjreason%TYPE;
qtyAdjNew  invadjactivity.adjqty%TYPE;
strDebugYN char(1);

procedure debugmsg(in_text varchar2) is
cntChar integer;
begin
   if strDebugYN <> 'Y' then
     return;
   end if;
   cntChar := 1;
   while (cntChar * 60) < (Length(in_text)+60)
   loop
     zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
     cntChar := cntChar + 1;
   end loop;
exception when others then
  null;
end;

begin

mark := 'Start';

if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'INVADJ947HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;

-- Loopthru the invadj for the customer
  for adj in C_INVADJACTIVITY loop
/*    if ((adj.inventoryclass !=
          nvl(adj.newinventoryclass,adj.inventoryclass)) or
        (adj.invstatus !=
          nvl(adj.newinvstatus,adj.invstatus)) ) then
       qtyAdjust := adj.adjqty * -1;
    else
       qtyAdjust := adj.adjqty;
    end if;
*/

       insert into invadj947dtlex
          (
              sessionid,
              whenoccurred,
              lpid,
              facility,
              custid,
              rsncode,
              quantity,
              uom,
              upc,
              item,
              lotno,
              dmgdesc,
              oldinvstatus,
              manufacturedate,
              oldmanufacturedate,
              newmanufacturedate,
              expirationdate,
              oldexpirationdate,
              newexpirationdate
          )
       values
          (
              strSuffix,
              adj.whenoccurred,
              adj.lpid,
              adj.facility,
              adj.custid,
              adj.adjreason,
              adj.adjqty,
              adj.uom,
              adj.upc,
              adj.item,
              adj.lotnumber,
              strRefDesc,
              adj.invstatus,
              adj.manufacturedate,
              adj.oldmanufacturedate,
              adj.newmanufacturedate,
              adj.expirationdate,
              adj.oldexpirationdate,
              adj.newexpirationdate
          );

  end loop;

-- create hdr view
if nvl(in_947_by_transaction_yn, 'N') = 'Y' then
   cmdSql := 'create view invadj947hdr_' || strSuffix ||
    ' (custid,lpid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
    '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
    '  facility_addr1,facility_addr2,facility_city,facility_state,'||
    '  facility_postalcode) '||
    'as select distinct I.custid,I.lpid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
    '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
    '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
    '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode '||
    ' from facility F, customer C, invadj947dtlex I ' ||
    ' where sessionid = '''||strSuffix||''''||
    '  and I.custid = C.custid(+)'||
    '  and I.facility = F.facility(+)';
   debugmsg(cmdSql);
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
else
   cmdSql := 'create view invadj947hdr_' || strSuffix ||
    ' (custid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
    '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
    '  facility_addr1,facility_addr2,facility_city,facility_state,'||
    '  facility_postalcode) '||
    'as select distinct I.custid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
    '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
    '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
    '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode '||
    ' from facility F, customer C, invadj947dtlex I ' ||
    ' where sessionid = '''||strSuffix||''''||
    '  and I.custid = C.custid(+)'||
    '  and I.facility = F.facility(+)';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
end if;

-- create dtl view
cmdSql := 'create or replace view invadj947dtl_' || strSuffix ||
 ' (custid,facility,adjno,lpid,reason,quantity,uom,upc,item,lot, stdinvstatus, manufacturedate, expirationdate,'||
 '  itmpassthruchar01,itmpassthruchar02,itmpassthruchar03,itmpassthruchar04,itmpassthruchar05,itmpassthruchar06,'||
 '  itmpassthruchar07,itmpassthruchar08,itmpassthruchar09,itmpassthruchar10,itmpassthrunum01,itmpassthrunum02,'||
 '  itmpassthrunum03,itmpassthrunum04,itmpassthrunum05,itmpassthrunum06,itmpassthrunum07,itmpassthrunum08,'||
 '  itmpassthrunum09,itmpassthrunum10,oldmanufacturedate,newmanufacturedate,oldexpirationdate,newexpirationdate)'||
 'as select I.custid,I.facility,to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
 '   I.lpid,I.rsncode,I.quantity,I.uom,I.upc,I.item,I.lotno,I.oldinvstatus,'||
   ' decode(I.manufacturedate, null, decode(P.manufacturedate, null, DP.manufacturedate, P.manufacturedate), I.manufacturedate),'||
   ' decode(I.expirationdate, null, decode(P.expirationdate, null, DP.expirationdate, P.expirationdate), I.expirationdate),'||
   ' IT.itmpassthruchar01,IT.itmpassthruchar02,IT.itmpassthruchar03,IT.itmpassthruchar04,IT.itmpassthruchar05,IT.itmpassthruchar06,'||
   ' IT.itmpassthruchar07,IT.itmpassthruchar08,IT.itmpassthruchar09,IT.itmpassthruchar10,IT.itmpassthrunum01,IT.itmpassthrunum02,'||
   ' IT.itmpassthrunum03,IT.itmpassthrunum04,IT.itmpassthrunum05,IT.itmpassthrunum06,IT.itmpassthrunum07,IT.itmpassthrunum08,'||
   ' IT.itmpassthrunum09,IT.itmpassthrunum10,I.oldmanufacturedate,I.newmanufacturedate,I.oldexpirationdate,I.newexpirationdate'||
 ' from invadj947dtlex I, plate P, deletedplate DP, custitem IT'||
 ' where sessionid = '''||strSuffix||'''' ||
   ' and I.lpid = P.lpid(+)'||
   ' and I.lpid = DP.lpid(+)'||
   ' and I.custid = IT.custid(+)'||
   ' and I.item = IT.item(+)';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create ref view
cmdSql := 'create view invadj947ref_' || strSuffix ||
 ' (custid,facility,adjno,lpid,refdesc) ' ||
 ' as select custid,facility,to_char(whenoccurred,''YYYYMMDDHH24MISS''),'||
 '   lpid,dmgdesc ' ||
 ' from invadj947dtlex ' ||
 ' where sessionid = '''||strSuffix||'''' ||
 ' and dmgdesc is not null ';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_stdinvadj947;

FUNCTION ship_plate_count
(in_orderid IN number
,in_shipid IN number
) return integer
IS
cnt integer;
BEGIN
    cnt := 0;
    select count(distinct lpid)
      into cnt
      from shippingplateview
     where orderid = in_orderid
       and shipid = in_shipid
       and parentlpid is null
       and type in ('M','F');

    return nvl(cnt, 0);

EXCEPTION WHEN OTHERS THEN
    return 0;
END ship_plate_count;

FUNCTION line_qty_expected
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_line_number IN number
) return number
IS
l_qty number;
BEGIN
    l_qty := 0;
    select qty
      into l_qty
      from orderdtlline
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_item
       and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
       and linenumber = in_line_number;

    return nvl(l_qty,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END line_qty_expected;

function VICSbolNumber(in_loadno number, in_orderid number, in_shipid number, in_custid varchar2)
   return varchar2 is
OutData varchar2(17);
VarData varchar2 (16);
VarNumber number;
vics_number varchar2(16);
VarManufacturerucc customer.manufacturerucc%type;
out_msg varchar2(255);
procedure vics_msg(in_msgtype varchar2, in_orderid varchar2, in_shipid varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'VICS ' || rtrim(in_custid) || ' ' || in_orderid || ' ' || in_shipid || ' ' || out_msg;
  zms.log_autonomous_msg('945', '945', rtrim(in_custid), out_msg, 'E', '945', strMsg);
end;

begin
if nvl(in_loadno,0) = 0 then
   OutData := null;
   return OutData;
end if;
begin
   select nvl(manufacturerucc,'0000000') into VarManufacturerucc
      from customer
      where custid = in_custid;
exception when others then
   VarManufacturerucc := '0000000';
end;
if length(VarManufacturerucc) <= 7 then
   vics_number := lpad(nvl(VarManufacturerucc,'0000000'),7,'0')||trim(to_char(nvl(in_loadno,0),'000000000'));
elsif length(VarManufacturerucc) = 8 then
   vics_number := lpad(nvl(VarManufacturerucc,'00000000'),8,'0')||trim(to_char(nvl(in_loadno,0),'00000000'));
elsif length(VarManufacturerucc) = 9 then
   vics_number := lpad(nvl(VarManufacturerucc,'000000000'),9,'0')||trim(to_char(nvl(in_loadno,0),'0000000'));
end if;
if length(vics_number) <> 16 then
   out_msg := '945 vics invalid field length ' || length(vics_number);
   OutData := '99999999999999999';
   return OutData;
end if;

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := to_number(substr(vics_number,1,7));

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := to_number(substr(vics_number,8,9));

VarNumber := 10 - MOD(to_number(substr(trim(vics_number),1,1)) +
                      to_number(substr(trim(vics_number),2,1)) * 3 +
                      to_number(substr(trim(vics_number),3,1)) +
                      to_number(substr(trim(vics_number),4,1)) * 3 +
                      to_number(substr(trim(vics_number),5,1)) +
                      to_number(substr(trim(vics_number),6,1)) * 3 +
                      to_number(substr(trim(vics_number),7,1)) +
                      to_number(substr(trim(vics_number),8,1)) * 3 +
                      to_number(substr(trim(vics_number),9,1)) +
                      to_number(substr(trim(vics_number),10,1)) * 3 +
                      to_number(substr(trim(vics_number),11,1)) +
                      to_number(substr(trim(vics_number),12,1)) * 3 +
                      to_number(substr(trim(vics_number),13,1)) +
                      to_number(substr(trim(vics_number),14,1)) * 3 +
                      to_number(substr(trim(vics_number),15,1)) +
                      to_number(substr(trim(vics_number),16,1)) * 3,10);

if VarNumber = 10 then
   VarNumber := 0;
end if;

OutData := vics_number || to_char(VarNumber);

return OutData;

exception when others then
   return '99999999999999999';
end VICSbolNumber;

function VICSSubBolNumber(in_orderid number, in_shipid number, in_custid varchar2)
   return varchar2 is
OutData varchar2(17);
VarData varchar2 (16);
VarNumber number;
vics_number varchar2(16);
VarManufacturerucc customer.manufacturerucc%type;
OrderidShipid varchar2(10);
out_msg varchar2(255);
procedure vics_msg(in_msgtype varchar2, in_orderid varchar2, in_shipid varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'VICS ' || rtrim(in_custid) || ' ' || in_orderid || ' ' || in_shipid || ' ' || out_msg;
  zms.log_autonomous_msg('945', '945', rtrim(in_custid), out_msg, 'E', '945', strMsg);
end;
begin
begin
   select nvl(manufacturerucc,'0000000') into VarManufacturerucc
      from customer
      where custid = in_custid;
exception when others then
   VarManufacturerucc := '0000000';
end;
OrderidShipid := to_char(in_orderid * 10 + in_shipid);
if length(VarManufacturerucc) <= 7 then
   if length(OrderidShipid) < 9 then
      OrderidShipid := lpad(OrderidShipid, 9, 0);
   elsif  length(OrderidShipid) > 9 then
      OrderidShipid := substr(OrderidShipid, length(OrderidShipid) - 8);
   end if;
   vics_number := lpad(nvl(VarManufacturerucc,'0000000'),7,'0')||OrderidShipid;
elsif length(VarManufacturerucc) = 8 then
   if length(OrderidShipid) < 8 then
      OrderidShipid := lpad(OrderidShipid, 8, 0);
   elsif  length(OrderidShipid) > 8 then
      OrderidShipid := substr(OrderidShipid, length(OrderidShipid) - 7);
   end if;
   vics_number := lpad(nvl(VarManufacturerucc,'00000000'),8,'0')||OrderidShipid;
elsif length(VarManufacturerucc) = 9 then
   if length(OrderidShipid) < 7 then
      OrderidShipid := lpad(OrderidShipid, 7, 0);
   elsif  length(OrderidShipid) > 7 then
      OrderidShipid := substr(OrderidShipid, length(OrderidShipid) - 6);
   end if;
   vics_number := lpad(nvl(VarManufacturerucc,'000000000'),9,'0')||OrderidShipid;
end if;
if length(vics_number) <> 16 then
   out_msg := '945 vics invalid field length ' || length(vics_number);
   OutData := '99999999999999999';
   return OutData;
end if;
VarNumber := to_number(substr(vics_number,1,7));
VarNumber := to_number(substr(vics_number,8,9));
VarNumber := 10 - MOD(to_number(substr(trim(vics_number),1,1)) +
                      to_number(substr(trim(vics_number),2,1)) * 3 +
                      to_number(substr(trim(vics_number),3,1)) +
                      to_number(substr(trim(vics_number),4,1)) * 3 +
                      to_number(substr(trim(vics_number),5,1)) +
                      to_number(substr(trim(vics_number),6,1)) * 3 +
                      to_number(substr(trim(vics_number),7,1)) +
                      to_number(substr(trim(vics_number),8,1)) * 3 +
                      to_number(substr(trim(vics_number),9,1)) +
                      to_number(substr(trim(vics_number),10,1)) * 3 +
                      to_number(substr(trim(vics_number),11,1)) +
                      to_number(substr(trim(vics_number),12,1)) * 3 +
                      to_number(substr(trim(vics_number),13,1)) +
                      to_number(substr(trim(vics_number),14,1)) * 3 +
                      to_number(substr(trim(vics_number),15,1)) +
                      to_number(substr(trim(vics_number),16,1)) * 3,10);
if VarNumber = 10 then
   VarNumber := 0;
end if;
OutData := vics_number || to_char(VarNumber);
return OutData;
exception when others then
   return '99999999999999999';
end VICSSubBolNumber;
function VICSMinBolNumber
(in_loadno in number
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_shipto varchar2
) return varchar2 is
cursor cur_oh is
   select orderid, shipid
     from orderhdr
    where loadno = in_loadno
      and nvl(shipto,'Y') = nvl(in_shipto,'Z')
      and qtyship > 0
    order by orderid, shipid;
OH cur_oh%rowtype;
begin
   if nvl(in_loadno,0) = 0 then
      return VICSSubBolNumber(in_orderid, in_shipid, in_custid);
   end if;
   open cur_oh;
   fetch cur_oh into OH;
   if cur_oh%notfound then
      close cur_oh;
      return '99999999999999999';
   end if;
   close cur_oh;
   return VICSSubBolNumber(OH.orderid, OH.shipid, in_custid);
end VICSMinBolNumber;
function check_edi
(in_orderid in number
,in_shipid in number
,in_custid varchar2
,in_transaction varchar2
,in_sipconsigneematchfield varchar2
) return varchar2 is
l_Consignee custconsignee.consignee%type;
l_generate_ship_notice char(1);
l_generate_945 char(1);
l_generate_810 char(1);
res char(1);
cmdSql varchar2(255);
begin
res := 'N';
cmdSql := 'select consignee '||
           ' from custconsigneesipname '||
          ' where custid = ''' || in_custid || '''' ||
            ' and rtrim(sipname) = (select nvl(rtrim(' || in_sipconsigneematchfield ||'),''(none)'') '||
                            ' from orderhdr where orderid = ' || in_orderid  ||
                             ' and shipid = '|| in_shipid || ')';
execute immediate cmdSql into l_Consignee;
--zut.prt('cons ' || l_Consignee);
cmdSql := 'select generate_ship_notice, generate_945, generate_810 ' ||
           ' from custconsignee ' ||
          ' where custid = ''' || in_custid || ''' '||
            ' and consignee = ''' || l_Consignee || '''';
execute immediate cmdSql into l_generate_ship_notice, l_generate_945, l_generate_810;
if in_transaction = '856' then
   res := nvl(l_generate_ship_notice, 'N');
elsif in_transaction = '945' then
   res := nvl(l_generate_945, 'N');
elsif in_transaction = '810' then
   res := nvl(l_generate_810, 'N');
end if;
return res;
exception when others then
   return 'N';
end check_edi;

procedure begin_wave_notify
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_movement IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
l_condition varchar2(200);
strDebugYN char(1);
strSuffix varchar2(32);
viewcount integer;
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin
if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';


viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'WAVE_NOTIFY_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

l_condition := null;

if in_orderid != 0 then
   l_condition := ' oh.orderid = '||to_char(in_orderid)
               || ' and oh.shipid = '||to_char(in_shipid)
               || ' ';
elsif in_loadno != 0 then
   l_condition := ' oh.loadno = '||to_char(in_loadno)
               || ' ';
elsif in_begdatestr is not null then
   l_condition :=  ' oh.statusupdate >= to_date(''' || in_begdatestr
               || ''', ''yyyymmddhh24miss'')'
               ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
               || ''', ''yyyymmddhh24miss'') ';
end if;

cmdSql := 'create view wave_notify_' || strSuffix ||
  ' (custid,orderid,shipid,reference,po,movement) as '||
  ' select  custid,orderid,shipid,reference,po,''' || in_movement || '''' ||
  ' from orderhdr oh where ' ||
  l_condition;
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimwn: ' || sqlerrm;
  out_errorno := sqlcode;
end begin_wave_notify;

procedure end_wave_notify
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop VIEW wave_notify_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimewn ' || sqlerrm;
  out_errorno := sqlcode;
end end_wave_notify;


FUNCTION gt947_document
(in_lpid IN varchar2
) return varchar2
is
retdoc varchar2(6);
begin
   begin
      select to_char(nvl(orderid,0), 'FM099999') into retdoc
         from plate
         where lpid = in_lpid;
   exception when no_data_found then
      begin
         select to_char(nvl(orderid,0), 'FM099999') into retdoc
            from deletedplate
            where lpid = in_lpid;
      exception when no_data_found then
         retdoc := '000000';
      end;
   end;
   return retdoc;
end gt947_document;

FUNCTION lpid_last6
(in_lpid IN varchar2
) return varchar2
is
retLpidLast6 varchar2(6);
begin
   begin
      select trim(leading '0' from substr(in_lpid,10)) into retLpidLast6 from dual;
   exception when others then
      retLpidLast6 := '0';
   end;
   return retLpidLast6;
end lpid_last6;

FUNCTION lpid_last7
(in_lpid IN varchar2
) return varchar2
is
retLpidLast7 varchar2(7);
begin
   begin
      select trim(leading '0' from substr(in_lpid,9)) into retLpidLast7 from dual;
      exception when others then
         retLpidLast7 := '0';
      end;
   return retLpidLast7;
end lpid_last7;

function sn945_include_canceled
(in_cancel_productgroup in varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
) return boolean is
l_cnt integer;
l_ProductGroup custitem.productgroup%type;

begin
if in_cancel_productgroup is null then
   return false;
end if;
select count(1) into l_cnt
   from orderdtl
where orderid = in_orderid
  and shipid = in_shipid
  and item = in_item
  and linestatus = 'X';

if l_cnt = 0 then
   return false;
end if;

select nvl(productgroup,'zzzz') into l_ProductGroup
       from custitemview
          where custid = rtrim(in_custid)
            and item = in_item;
if l_ProductGroup = in_cancel_productgroup then
   return true;
end if;
return false;

exception when others then
   return false;
end sn945_include_canceled;

FUNCTION facility_arrival_date
(in_dateshipped IN date
,in_fromfacility IN varchar2
,in_validation_table IN varchar2
) return date
IS
cmdSql varchar2(2000);
strDays varchar2(5);
retDate date;
BEGIN
   select trunc(in_dateshipped + 5) into retDate
      from dual;
   cmdSql := 'select abbrev from ' || in_validation_table ||
             ' where code = ''' || in_fromfacility || '''';

   execute immediate cmdSql into strDays;

   if strDays is not null then
      select trunc(in_dateshipped + to_number(strDays)) into retDate
         from dual;
   end if;

   return retDate;


EXCEPTION WHEN OTHERS THEN
    return retDate;
END facility_arrival_date;

FUNCTION getdmgreason
(in_lpid varchar2
) return varchar2
IS

cursor C_LPID is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dmgreason plate.condition%type;

BEGIN
 dmgreason := null;

 open C_LPID;
 fetch C_LPID into dmgreason;
 close C_LPID;

 return dmgreason;

EXCEPTION WHEN OTHERS THEN
  return null;
END getdmgreason;
function cost_by_trackingno
(in_orderid IN number
,in_shipid IN number
,in_trackingno IN varchar2
) return number
is
outCost shippingplate.shippingcost%type;
begin
   select sum(shippingcost) into outCost
      from shippingplate
     where orderid = in_orderid
       and shipid = in_shipid
       and trackingno = in_trackingno;
   return outCost;
EXCEPTION WHEN OTHERS THEN
  return 0;
END cost_by_trackingno;
end zimportproc7;
/
show error package body zimportproc7;
exit;
