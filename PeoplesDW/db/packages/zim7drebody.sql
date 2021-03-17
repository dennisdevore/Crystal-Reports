create or replace package body alps.zimportproc7DRE as
--
-- $Id$
--
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

----------------------------------------------------------------------
-- begin_invadj947DRE
----------------------------------------------------------------------
procedure begin_invadj947DRE
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
/*    if ((adj.inventoryclass !=
          nvl(adj.newinventoryclass,adj.inventoryclass)) or
        (adj.invstatus !=
          nvl(adj.newinvstatus,adj.invstatus)) ) then
       qtyAdjust := adj.adjqty * -1;
    else
       qtyAdjust := adj.adjqty;
    end if;
*/

  case adj.adjreason
      when 'CC' then
        if adj.adjqty < 0 then
           strNewRsnCode := '01';
        else
           strNewRsnCode := '51';
        end if;
      when 'CA' then
         if adj.adjqty < 0 then
            strNewRsnCode := '04';
         else
            strNewRsnCode := '54';
         end if;
      when 'WD' then
          strNewRsnCode := '02';
      when 'ID' then
          if adj.adjqty > 0 then
             strNewRsnCode := '95';
          end if;
      when 'OD' then
         if adj.adjqty > 0 then
            strNewRsnCode := '97';
         end if;
      when 'FD' then
         strNewRsnCode := '07';
      when 'DD' then
         strNewRsnCode := 'Z4';
      when 'X1' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X1';
         end if;
      when 'X2' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X2';
         end if;
      when 'X3' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X3';
         end if;
      when 'X4' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X4';
         end if;
      when 'X5' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X5';
         end if;
      when 'X6' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X6';
         end if;
      when 'X7' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X7';
         end if;
      when 'X8' then
         if adj.adjqty > 0 then
            strNewRsnCode := 'X8';
         end if;
      else
         ------ default value
         if adj.adjqty < 0 then
            strNewRsnCode := '01';
         else
            strNewRsnCode := '51';
         end if;
  end case;

/*

     if adj.adjreason = 'CC' then
        if adj.adjqty < 0 then
           strNewRsnCode := '01';
        else
           strNewRsnCode := '51';
        end if;
     else
        if adj.adjreason = 'CA' then
           if adj.adjqty < 0 then
              strNewRsnCode := '04';
           else
              strNewRsnCode := '54';
           end if;
        else
           if adj.adjreason = 'WD' then
              strNewRsnCode := '02';
           else
              if adj.adjreason = 'ID' then
                 if adj.adjqty > 0 then
                    strNewRsnCode := '95';
                 end if;
              else
                 if adj.adjreason = 'OD' then
                    if adj.adjqty > 0 then
                       strNewRsnCode := '97';
                    end if;
                 else
                    if adj.adjreason = 'FD' then
                       strNewRsnCode := '07';
                    else
                       if adj.adjreason = 'DD' then
                          strNewRsnCode := 'Z4';
                       else
                          ------ default value
                          if adj.adjqty < 0 then
                             strNewRsnCode := '01';
                          else
                             strNewRsnCode := '51';
                          end if;
                       end if;
                    end if;
                 end if;
              end if;
           end if;
        end if;
     end if;
*/
     if not strNewRsnCode = '  ' then
       if adj.adjqty < 0 then
          qtyAdjNew := adj.adjqty * -1;
       else
          qtyAdjNew := adj.adjqty;
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
              strNewRsnCode,
              qtyAdjNew,
              adj.uom,
              adj.upc,
              adj.item,
              adj.lpid,
              strRefDesc
          );
     end if;
  end loop;

-- create hdr view
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

-- create dtl view
cmdSql := 'create view invadj947dtl_' || strSuffix ||
 ' (custid,facility,adjno,lpid,reason,quantity,uom,upc,item,lot) '||
 'as select custid,facility,to_char(whenoccurred,''YYYYMMDDHH24MISS''),'||
 '   lpid,rsncode,quantity,uom,upc,item,lotno '||
 ' from invadj947dtlex '||
 ' where sessionid = '''||strSuffix||'''';

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
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_invadj947DRE;

/*-----------------------------------------------------------------------------
  import order lines for Birds Eye and CW (BIREYH and CALWAH)
  ---------------------------------------------------------------------------*/
procedure import_order_line_dre_be
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_rfautodisplay varchar2
,in_comment  long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustItemAlias is
     select *
       from custitemalias
      where custid = rtrim(in_custid) and
            itemalias = rtrim(in_dtlpassthruchar01) and
            nvl(partial_match_yn,'N') = 'N';
cia curCustItemAlias%rowtype;

cntRows integer;
sItem varchar(20);
pItem varchar(20);

procedure iold_trace_msg(in_pos varchar2, in_msg varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg('iold', in_pos, ' ', substr(in_msg,1,254),
    'T','iold', strMsg);
  if length(in_msg) > 254 then
     zms.log_msg('iold', in_pos || 'A', ' ', substr(in_msg,255,254),
       'T','iold', strMsg);
  end if;
  if length(in_msg) > 508 then
     zms.log_msg('iold', in_pos || 'B', ' ', substr(in_msg,509,254),
       'T','iold', strMsg);
  end if;
  if length(in_msg) > 764 then
     zms.log_msg('iold', in_pos || 'C', ' ', substr(in_msg,763,254),
       'T','iold', strMsg);
  end if;
end;

begin
   /* Birds Eye / C W product code is in_dtlpassthruchar01,
                      UPC is in_dtlpassthruchar02
      if product code exists in cust item
         item entered = product code
      else if an alias exists for UPC in custitemalias
         item entered = UPC alias item
      else
         item entered = UPC

   */
   sItem := in_dtlpassthruchar02;
   select count(1)
     into cntRows
     from custitem
     where custid = in_custid and
           item = sItem;

   if cntRows = 0 then
      open curCustItemAlias;
      fetch curCustItemAlias into cia;
      if curCustItemAlias%FOUND then
         pItem := cia.item;
      else
         pItem := in_dtlpassthruchar01;
      end if;
      close curCustItemAlias;
   else
      pItem := sItem;
   end if;

/*    iold_trace_msg('E', 'PItem ' || pitem || ' sItem ' || sItem);
   iold_trace_msg('E', 'qty ' || to_char(in_qtyentered,'9999') || ' uom ' || in_uomentered || ' UPC ' || in_dtlpassthruchar01 ||
                       ' Item ' || in_dtlpassthruchar02 || ' PI ' || in_dtlpassthruchar03);
   iold_trace_msg('E', 'desc ' || in_dtlpassthruchar04 || ' line ' || to_char(in_dtlpassthrunum01,'99'));
*/
   zimp.import_order_line(in_func,in_custid,in_reference,in_po,
       pItem,in_lotnumber,
       in_uomentered,in_qtyentered,
       in_backorder,in_allowsub,in_qtytype,
       in_invstatusind,in_invstatus,in_invclassind,in_inventoryclass,
       in_consigneesku,
       in_dtlpassthruchar01,in_dtlpassthruchar02,
       in_dtlpassthruchar03,in_dtlpassthruchar04,
       in_dtlpassthruchar05,in_dtlpassthruchar06,
       in_dtlpassthruchar07,in_dtlpassthruchar08,
       in_dtlpassthruchar09,in_dtlpassthruchar10,
       in_dtlpassthruchar11,in_dtlpassthruchar12,
       in_dtlpassthruchar13,in_dtlpassthruchar14,
       in_dtlpassthruchar15,in_dtlpassthruchar16,
       in_dtlpassthruchar17,in_dtlpassthruchar18,
       in_dtlpassthruchar19,in_dtlpassthruchar20,
       null,null,null,null,null,null,null,null,null,null,
       null,null,null,null,null,null,null,null,null,null,
       in_dtlpassthrunum01,in_dtlpassthrunum02,
       in_dtlpassthrunum03,in_dtlpassthrunum04,
       in_dtlpassthrunum05,in_dtlpassthrunum06,
       in_dtlpassthrunum07,in_dtlpassthrunum08,
       in_dtlpassthrunum09,in_dtlpassthrunum10,
       null,null,null,null,null,null,null,null,null,null,
       in_dtlpassthrudate01,in_dtlpassthrudate02,
       in_dtlpassthrudate03,in_dtlpassthrudate04,
       in_dtlpassthrudoll01,in_dtlpassthrudoll02,
       in_rfautodisplay,in_comment,in_weight_entered_lbs,in_weight_entered_kgs, null, null, null, null, null, null,
       null, null, null, null, null, null, null, null, null, null, null,null,null,null,
       out_orderid,out_shipid,out_errorno,out_msg);


out_msg := 'OKAY';

exception when others then
  out_msg := 'zi7dreol ' || sqlerrm;
  out_errorno := sqlcode;

end import_order_line_dre_be;

end zimportproc7DRE;
/
show error package body zimportproc7DRE;
exit;
