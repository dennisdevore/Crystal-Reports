create or replace package body zimportproc7pd as

IMP_USERID constant varchar2(8) := 'IMPORDER';
last_orderid    orderhdr.orderid%type;
strDebugYN      char(1);


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

begin

if strDebugYN <> 'Y' then
   return;
end if;

cntChar := 1;
while (cntChar * 60) < (length(in_text)+60)
  loop
      zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
    cntChar := cntChar + 1;
  end loop;

exception when others then
   null;
end;

----------------------------------------------------------------------
-- begin_diageo947
----------------------------------------------------------------------
procedure begin_diageo947
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
  select IA.whenoccurred, IA.lpid, IA.facility, IA.custid, IA.item,
         IA.lotnumber,IA.inventoryclass, IA.invstatus, IA.uom, IA.adjqty,
      IA.adjreason, IA.tasktype, IA.adjuser, IA.lastuser, IA.lastupdate,
      IA.serialnumber,
      IA.oldcustid, IA.olditem, IA.oldlotnumber,IA.oldinventoryclass,
      IA.oldinvstatus, IA.custreference,
         IB.newcustid, IB.newitem, IB.newlotnumber,IB.newinventoryclass,
         IB.newinvstatus, OH.reference, DH.reference as ALTREF
    from  invadjactivity IA, invadjactivity IB, plate LP, orderhdr OH,
          deletedplate DP, orderhdr DH
   where IA.custid = in_custid
     and IA.whenoccurred(+) = IB.whenoccurred
     and IA.lpid = IB.lpid
     and IB.lpid = LP.lpid(+)
     and LP.orderid = OH.orderid(+)
     and LP.shipid = OH.shipid(+)
     and IB.lpid = DP.lpid(+)
     and DP.orderid = DH.orderid(+)
     and DP.shipid = DH.shipid(+)
     and IA.olditem is not null
     and IB.olditem is null
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and nvl(IA.suppress_edi_yn,'N') != 'Y'
     and nvl(IB.suppress_edi_yn,'N') != 'Y'
  union select  IA.whenoccurred, IA.lpid, IA.facility, IA.custid, IA.item,
         IA.lotnumber,IA.inventoryclass, IA.invstatus, IA.uom, IA.adjqty,
      IA.adjreason, IA.tasktype, IA.adjuser, IA.lastuser, IA.lastupdate,
      IA.serialnumber,
      IA.oldcustid, IA.olditem, IA.oldlotnumber,IA.oldinventoryclass,
      IA.oldinvstatus, IA.custreference,
         IB.newcustid, IB.newitem, IB.newlotnumber,IB.newinventoryclass,
         IB.newinvstatus, OH.reference, DH.reference as ALTREF
    from  invadjactivity IA, invadjactivity IB, plate LP, orderhdr OH,
          deletedplate DP, orderhdr DH
   where IA.custid = in_custid
     and trunc(IA.whenoccurred,'MI') = trunc(IB.whenoccurred,'MI')
     and IA.item = IB.item
     and nvl(IA.lotnumber,'(none)') = nvl(IB.lotnumber, '(none)')
     and IA.adjqty = (IB.adjqty * -1)
     and IA.tasktype = 'DM'
     and IB.tasktype = 'DM'
     and IB.lpid = LP.lpid(+)
     and LP.orderid = OH.orderid(+)
     and LP.shipid = OH.shipid(+)
     and IB.lpid = DP.lpid(+)
     and DP.orderid = DH.orderid(+)
     and DP.shipid = DH.shipid(+)
     and IA.olditem is not null
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and nvl(IA.suppress_edi_yn,'N') != 'Y'
     and nvl(IB.suppress_edi_yn,'N') != 'Y';

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
sapMVV varchar2(3);
sapOLD varchar2(2);
sapNEW varchar2(2);
qtyAdjust number(7);
tmpOld varchar2(2);
tmpNew varchar2(2);
strRefDesc varchar2(45);
ia_max varchar2(20);
ib_max varchar2(20);

begin

mark := 'Start';
debugmsg(mark);

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
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
               viewcount;
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
/*
trace_msg('0', strSuffix);
*/
debugmsg('first trace');
select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
/*
trace_msg('X', in_custid);
*/
  out_errorno := -1;
  out_msg := 'Invalid Customer Code-' || in_custid;
  return;
end if;

debugmsg('cust edited');
-- Verify the dates
/*
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
*/
--
--  Process Database Updates for DM commands

DELETE from invadj947dtlex where sessionid =  strSuffix;

/* PRN 7655 - I/E locking freezing. The following code was taking much too long to execute
UPDATE  invadjactivity IA
   set IA.olditem = IA.item,
       IA.oldcustid = IA.custid,
      IA.oldlotnumber = IA.lotnumber,
      IA.oldinventoryclass = IA.inventoryclass,
      IA.oldinvstatus = (SELECT MAX(IB.invstatus) FROM invadjactivity IB
     WHERE trunc(IB.whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
       and  IB.item = IA.item
        and  IB.custid = in_custid
      and  IB.lotnumber = IA.lotnumber
      and  IB.tasktype = 'DM'
      and  IB.adjqty = (-1 * IA.adjqty) )
  WHERE EXISTS (SELECT IB.invstatus FROM invadjactivity IB
         WHERE trunc(IB.whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
             and IB.item = IA.item
            and IB.adjqty = (-1 * IA.adjqty)
           and IB.tasktype = 'DM'
            and IB.custid = in_custid
           and IB.adjqty < 0)
          and IA.olditem is null
       and IA.custid = in_custid;


UPDATE  invadjactivity IA
   set IA.newitem = IA.item,
       IA.newcustid = IA.custid,
      IA.newlotnumber = IA.lotnumber,
      IA.newinventoryclass = IA.inventoryclass,
      IA.newinvstatus = (SELECT MAX(IB.invstatus) FROM invadjactivity IB
      WHERE trunc(IB.whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
             and  IB.item = IA.item
                and  IB.lotnumber = IA.lotnumber
           and  IB.tasktype = 'DM'
            and  IB.custid = in_custid
            and  IB.adjqty = (-1 * IA.adjqty) )
  WHERE EXISTS (SELECT IB.invstatus FROM invadjactivity IB
           WHERE trunc(IB.whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
             and  IB.item = IA.item
           and  IB.custid = in_custid
                and  IB.lotnumber = IA.lotnumber
            and  IB.adjqty = (-1 * IA.adjqty)
           and IB.tasktype = 'DM'
           and IB.adjqty > 0)
       and IA.newitem is null
     and IA.custid = in_custid;
*/
for IA in (  select *  from  invadjactivity
              where whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
                and whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
                and custid = in_custid
                and tasktype = 'DM'
                and nvl(suppress_edi_yn,'N') != 'Y'
                and adjqty < 0
                and newitem is null) loop
  debugmsg('IA ' || to_char(IA.whenoccurred,'mm/dd/yy hh24:mi') || ' ' || IA.custid || ' ' ||
           IA.invstatus || ' ' || IA.item || ' ' || IA.adjqty);
  select max(I.invstatus) into ia_max from invadjactivity I
     where trunc(I.whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
       and  I.item = IA.item
       and  I.custid = in_custid
       and  nvl(I.lotnumber,'(none)') = nvl(IA.lotnumber,'(none)')
       and  I.tasktype = 'DM'
       and nvl(I.suppress_edi_yn,'N') != 'Y'
       and  I.adjqty = (-1 * IA.adjqty);
  for IB in ( select *  from  invadjactivity
              where trunc(whenoccurred,'MI') = trunc(IA.whenoccurred,'MI')
              and item = IA.item
              and adjqty = (-1 * IA.adjqty)
              and tasktype = 'DM'
              and nvl(suppress_edi_yn,'N') != 'Y'
              and custid = in_custid) loop
     select max(I.invstatus) into ib_max from invadjactivity I
        where trunc(I.whenoccurred,'MI') = trunc(IB.whenoccurred,'MI')
          and I.item = IB.item
          and I.custid = in_custid
          and nvl(I.lotnumber,'(none)') = nvl(IB.lotnumber,'(none)')
          and I.tasktype = 'DM'
          and nvl(I.suppress_edi_yn,'N') != 'Y'
          and I.adjqty = (-1 * IB.adjqty);
     debugmsg('IB ' || to_char(IB.whenoccurred,'mm/dd/yy hh24:mi') || ' ' || IB.custid || ' ' ||
              IB.invstatus || ' ' || IB.item || ' ' || IB.adjqty);
     if IB.olditem is null then
        update invadjactivity
           set olditem = IA.item,
               oldcustid = IA.custid,
               oldlotnumber = IA.lotnumber,
               oldinventoryclass = IA.inventoryclass,
               oldinvstatus = ia_max
           where whenoccurred = IB.whenoccurred
             and facility = IB.facility
             and custid = IB.custid
             and item = IB.item
             and invstatus = IB.invstatus
             and inventoryclass = IB.inventoryclass
             and nvl(lotnumber,'(none)') = nvl(IB.lotnumber, '(none)')
             and adjqty = IB.adjqty;
     end if;
     if IA.newitem is null then
        update invadjactivity
           set newitem = IB.item,
               newcustid = IB.custid,
               newlotnumber = IB.lotnumber,
               newinventoryclass = IB.inventoryclass,
               newinvstatus = ib_max
           where whenoccurred = IA.whenoccurred
             and facility = IA.facility
             and custid = IA.custid
             and item = IA.item
             and invstatus = IA.invstatus
             and inventoryclass = IA.inventoryclass
             and nvl(lotnumber,'(none)') = nvl(IA.lotnumber, '(none)')
             and adjqty = IA.adjqty;
     end if;

  end loop;
end loop;


COMMIT;


-- Loopthru the invadj for the customer
debugmsg ('lets loop');
  for adj in C_INVADJACTIVITY loop
      debugmsg('cursor loop');
  /*
      zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,
            strRegWhse,strRetWhse);
      if strWhse is not null then
         zedi.validate_interface(adj.rowid,strMovementCode,intErrorNo,strMsg);
         if intErrorNo = 0 then
            strRefDesc := null;
            if adj.newinvstatus = 'DM' and adj.invstatus != 'DM' then
               OPEN C_LPID(adj.lpid);
               FETCH C_LPID into strRefDesc;
               CLOSE C_LPID;

            end if;
            trace_msg('0x', strSuffix);
  */
            if ((adj.inventoryclass !=
                  nvl(adj.newinventoryclass,adj.inventoryclass)) or
                (adj.invstatus !=
                  nvl(adj.newinvstatus,adj.invstatus)) ) then
               qtyAdjust := adj.adjqty * -1;
            else
               qtyAdjust := adj.adjqty;
            end if;

        if adj.oldinvstatus = 'AV' or adj.oldinvstatus = 'SP' then
           tmpOld := 'UR';
        end if;

        if adj.oldinvstatus = 'SU' or adj.oldinvstatus = 'DM' then
           tmpOld := 'BL';
        end if;

        if adj.oldinvstatus = 'EX' or adj.oldinvstatus = 'FD'  or
           adj.oldinvstatus = 'IN' or adj.oldinvstatus = 'QA' or
           adj.oldinvstatus = 'CH' or adj.oldinvstatus = 'CR' or
           adj.oldinvstatus = 'OH' or adj.oldinvstatus = 'RE' or
           adj.oldinvstatus = 'UN' or adj.oldinvstatus = 'US' or
               adj.oldinvstatus = 'QC' then
          tmpOld := 'QI';
        end if;

        if adj.newinvstatus = 'AV' or adj.newinvstatus = 'SP' then
           tmpNew := 'UR';
        end if;

        if adj.newinvstatus = 'SU' or adj.newinvstatus = 'DM' then
           tmpNew := 'BL';
        end if;


        if adj.newinvstatus = 'EX' or adj.newinvstatus = 'FD'  or
           adj.newinvstatus = 'IN' or adj.newinvstatus = 'QA' or
           adj.newinvstatus = 'CH' or adj.newinvstatus = 'CR' or
           adj.newinvstatus = 'OH' or adj.newinvstatus = 'RE' or
           adj.newinvstatus = 'UN' or adj.newinvstatus = 'US' or
               adj.newinvstatus = 'QC' then
          tmpNew := 'QI';
        end if;

        if tmpOld = 'UR' then
           sapMVV :='URX';
           if tmpNew = 'BL' then
             sapMVV := '344';
          end if;
           if tmpNew = 'QI' then
             sapMVV := '322';
          end if;
        end if;

        if tmpOld = 'BL' then
           sapMVV :='BLX';
           if tmpNew = 'UR' then
              sapMVV := '343';
          end if;
           if tmpNew = 'QI' then
             sapMVV := '349';
          end if;
        end if;

        if tmpOld = 'QI' then
           sapMVV :='QIX';
           if tmpNew = 'UR' then
             sapMVV := '321';
          end if;
           if tmpNew = 'BL' then
             sapMVV := '350';
          end if;
        end if;


            sapOLD := 'XX';
        sapNEW := 'XX';

            if adj.oldinvstatus = 'SU' then
           if adj.oldinventoryclass = 'IB' then
             sapOLD := 'LI';
          end if;
           if adj.oldinventoryclass = 'RG' then
             sapOLD := 'LT';
          end if;
           if adj.oldinventoryclass = 'FT' then
             sapOLD := 'LC';
          end if;
        else
           if adj.oldinventoryclass = 'IB' then
             sapOLD := 'IB';
          end if;
           if adj.oldinventoryclass = 'RG' then
             sapOLD := 'TP';
          end if;
           if adj.oldinventoryclass = 'FT' then
             sapOLD := 'CB';
          end if;
        end if;

            if adj.newinvstatus = 'SU' then
           if adj.newinventoryclass = 'IB' then
             sapNEW := 'LI';
          end if;
           if adj.newinventoryclass = 'RG' then
             sapNEW := 'LT';
          end if;
           if adj.newinventoryclass = 'FT' then
             sapNEW := 'LC';
          end if;
        else
           if adj.newinventoryclass = 'IB' then
             sapNEW := 'IB';
          end if;
           if adj.newinventoryclass = 'RG' then
             sapNEW := 'TP';
          end if;
           if adj.newinventoryclass = 'FT' then
             sapNEW := 'CB';
          end if;
        end if;
        debugmsg('old: ' || adj.olditem || ' .new: ' || adj.newitem);

        if tmpOld = 'UR' then
           if nvl(adj.oldlotnumber,'0') <> '0'  then
               if adj.lotnumber <> nvl(adj.oldlotnumber,adj.lotnumber) then
                  sapMVV :='311';
             end if;
          end if;
        end if;

        if tmpOld = 'QI' then
           if nvl(adj.oldlotnumber,'0') <> '0'  then
               if adj.lotnumber <> nvl(adj.oldlotnumber,adj.lotnumber) then
                  sapMVV :='323';
             end if;
          end if;
        end if;

        if tmpOld <> tmpNew or tmpOld = 'BL' then
           if nvl(adj.oldlotnumber,'0') <> '0'  then
               if adj.lotnumber <> nvl(adj.oldlotnumber,adj.lotnumber) then
                  sapMVV :='325';
             end if;
          end if;
        end if;

        if tmpOld = 'UR' then
           if adj.oldinventoryclass = 'RG' or
             adj.oldinventoryclass = 'IB' or
              adj.oldinventoryclass = 'FT' then
             if adj.newinventoryclass = 'DM' then
                sapMVV := '551';
            end if;
          end if;
        end if;

        if tmpOld = 'QI' then
           if adj.oldinventoryclass = 'RG' or
             adj.oldinventoryclass = 'IB' or
              adj.oldinventoryclass = 'FT' then
             if adj.newinventoryclass = 'DM' then
                sapMVV := '553';
            end if;
          end if;
        end if;

        if tmpOld = 'BL' then
           if adj.oldinventoryclass = 'RG' or
             adj.oldinventoryclass = 'IB' or
              adj.oldinventoryclass = 'FT' then
             if adj.newinventoryclass = 'DM' then
                sapMVV := '555';
            end if;
          end if;
        end if;

        if nvl(adj.newitem,'0') <> '0'  then
            if adj.olditem <> nvl(adj.newitem,adj.item) then
               sapMVV :='999';
          end if;
        end if;

        if sapOLD = 'IB' and sapNEW = 'TP' then
           sapMVV := '975';
        end if;

        if sapOLD = 'CB' and sapNEW = 'TP' then
           sapMVV := '975';
        end if;

        if sapOLD = 'TP' and sapNEW = 'IB' then
           sapMVV := '976';
        end if;

        if sapOLD = 'TP' and sapNEW = 'CB' then
           sapMVV := '976';
        end if;
/*
            trace_msg('1',  qtyAdjust || sapMVV || sapOLD || sapNEW);
          trace_msg('2', 'suff:' || length(strSuffix));
          trace_msg('2', 'when:' || length(adj.whenoccurred) || adj.whenoccurred);
          trace_msg('2', 'lpid:' || length(adj.lpid));
          trace_msg('2', 'facl:' || length(adj.facility));
          trace_msg('2', 'cust:' || length(adj.custid));
          trace_msg('2', 'move:' || length(strMovementCode));
          trace_msg('2', 'uomf:' || length(adj.uom));
          trace_msg('2', 'item:' || length(adj.item));
          trace_msg('2', 'lotd:' || length(adj.lotnumber));
          trace_msg('2', 'desc:' || length(strRefDesc));
          trace_msg('2', 'newl:' || length(adj.newlotnumber));
          trace_msg('2', 'OI  :' || length(adj.oldinvstatus));
          trace_msg('2', 'OC  :' || length(adj.oldinventoryclass));
          trace_msg('2', 'NI  :' || length(adj.newinvstatus));
          trace_msg('2', 'NC  :' || length(adj.newinventoryclass));
          trace_msg('2', 'sold:' || length(sapOLD));
          trace_msg('2', 'snew:' || length(sapNEW));
          trace_msg('2', 'smvv:' || length(sapMVV));
          trace_msg('2', 'cref:' || length(adj.custreference));
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
                   item,
                   lotno,
                   dmgdesc,
             newlotno,
             oldinvstatus,
             oldinventoryclass,
             oldtaxcode,
             newtaxcode,
             newinventoryclass,
             newinvstatus,
             sapmovecode,
             custreference,
             newitemno
               )
            values
               (
                   strSuffix,
                   adj.whenoccurred,
                   adj.lpid,
                   adj.facility,
                   adj.custid,
                   adj.adjreason,
                   qtyAdjust,
                   adj.uom,
                   adj.olditem,
                   adj.oldlotnumber,
                   strRefDesc,
             adj.lotnumber,
             adj.oldinvstatus,
             adj.oldinventoryclass,
             sapOLD,
             sapNEW,
             adj.newinventoryclass,
             adj.newinvstatus,
             sapMVV,
              nvl(adj.reference,adj.altref),
             adj.newitem
               );
     --    end if;
     --  end if;
  end loop;

-- create hdr view
cmdSql := 'create view invadj947hdr_' || strSuffix ||
 ' (custid,lpid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
 '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
 '  facility_addr1,facility_addr2,facility_city,facility_state,'||
 '  facility_postalcode,custreference,whenoccurred) '||
 'as select distinct I.custid,I.lpid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
 '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
 '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode,' ||
 '  I.custreference,I.whenoccurred '||
 ' from facility F, customer C, invadj947dtlex I ' ||
 ' where sessionid = '''||strSuffix||''''||
 '  and I.custid = C.custid(+)'||
 '  and I.facility = F.facility(+)';
 /*
 trace_msg('3',cmdSql);
*/
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create dtl view
cmdSql := 'create view invadj947dtl_' || strSuffix ||
 ' (custid,facility,adjno,lpid,reason,quantity,uom,upc,item,lot,' ||
 '  oldtaxstat,newtaxstat,sapmove,newlot,newitem,custreference) '||
 'as select custid,facility,to_char(whenoccurred,''YYYYMMDDHH24MISS''),'||
 '   lpid,rsncode,quantity,uom,upc,item,lotno,oldtaxcode,newtaxcode,' ||
 '   sapmovecode,newlotno,newitemno,custreference '||
 ' from invadj947dtlex '||
 ' where sessionid = '''||strSuffix||'''';

/*
trace_msg('4', cmdSql);
*/
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);





out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  debugmsg (out_msg);
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_diageo947;

----------------------------------------------------------------------
-- end_diageo947
----------------------------------------------------------------------
procedure end_diageo947
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

  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
               in_viewsuffix;

delete from invadj947dtlex where sessionid = strSuffix;
begin
   cmdSql := 'drop VIEW invadj947dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop VIEW invadj947ref_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop VIEW invadj947hdr_' || strSuffix;
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
  out_msg := 'ze947 ' || sqlerrm;
  out_errorno := sqlcode;
end end_diageo947;






----------------------------------------------------------------------
-- begin_pacam210
----------------------------------------------------------------------
procedure begin_pacam210
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_codelist IN varchar2
,in_custlist IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
curSql integer;
cmdOrd varchar2(20000);
strMsg varchar2(255);
curOrd integer;
intI integer;
curCompany integer;
intCustLen integer;
intCustCurr integer;
intCodeLen integer;
intCodeCurr integer;
intTotLen integer;
intTotCurr integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
strCodeCmd varchar2(255);
strCustCmd varchar2(255);
strTotCmd varchar2(255);
viewcount integer;
cntShipped integer;
h210 get_210_hdr_view%rowtype;
h210rcpt orderhdr%rowtype;
h210othr orderhdr%rowtype;
h210invh invoicehdr%rowtype;
cntReceipt integer;
dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
sapMVV varchar2(3);
sapOLD varchar2(2);
sapNEW varchar2(2);
qtyAdjust number(7);
tmpOld varchar2(2);
tmpNew varchar2(2);
strRefDesc varchar2(45);
cntInvoice integer;

procedure extract_invoice (in_masterinvoice varchar2) is

oh orderhdr%rowtype; -- receipt order info
ah orderhdr%rowtype; -- outbound order info
lo loads%rowtype;
ph posthdr%rowtype;
id invoicedtl%rowtype;
cntShipped integer;

begin

debugmsg('extracting invoice ' || in_masterinvoice);

ph := null;
begin
  select custid, invoice, invdate, postdate
    into ph.custid, ph.invoice, ph.invdate, ph.postdate
    from posthdr
   where invoice = in_masterinvoice;
exception when no_data_found then
  strMsg := 'Post Hdr not found: ' || in_masterinvoice;
  debugmsg(strMsg);
  return;
end;

for ih in (select facility,loadno,invoice,orderid
               from invoicehdr
              where masterinvoice = in_masterinvoice
                and loadno is not null)
loop

  strMsg := 'extracting order ' || to_char(ih.orderid);
  debugmsg(strMsg);

-- get receipt order info
  debugmsg('get receipt info');
  oh := null;
  begin
    select orderid,shipid,prono,shipterms,hdrpassthruchar03,hdrpassthruchar01,
           hdrpassthruchar06,reference,statusupdate,qtyrcvd,hdrpassthruchar05
      into oh.orderid,oh.shipid,oh.prono,oh.shipterms,oh.hdrpassthruchar03,
           oh.hdrpassthruchar01,oh.hdrpassthruchar06,oh.reference,
           oh.statusupdate,oh.qtyrcvd,oh.hdrpassthruchar05
      from orderhdr
     where orderid = ih.orderid
       and shipid = 1;
  exception when no_data_found then
    strMsg := 'Receipt Order not found ' || to_char(ih.orderid);
    debugmsg(strMsg);
    return;
  end;

-- get outbound order info
  ah := null;
  cntShipped := 0;
  debugmsg('get shipment info ' || oh.reference);
  begin
   select orderid,shipid,billoflading,loadno
    into ah.orderid,ah.shipid,ah.billoflading,ah.loadno
    from orderhdr
   where substr(reference,1,10) = substr(oh.reference,1,10)
     and custid = in_custid
     and ordertype = 'V'
     and orderstatus = '9'
     and rtrim(hdrpassthruchar05) = rtrim(oh.hdrpassthruchar05)
     and qtyship = oh.qtyrcvd;
   cntShipped := 1;
  exception when others then
    cntShipped := 0;
  end;
  if cntShipped = 0 then
    for h210ship in
      (select orderid,shipid,billoflading,loadno
        from orderhdr
       where substr(reference,1,10) = substr(oh.reference,1,10)
         and custid = in_custid
         and ordertype = 'V'
         and orderstatus = '9'
         and rtrim(hdrpassthruchar05) = rtrim(oh.hdrpassthruchar05)
         and statusupdate > oh.statusupdate
       order by statusupdate)
    loop
      ah.orderid := h210ship.orderid;
      ah.shipid := h210ship.shipid;
      ah.billoflading := h210ship.billoflading;
      ah.loadno := h210ship.loadno;
      cntShipped := 1;
      exit;
    end loop;
  end if;
  if cntShipped = 0 then
    for h210ship in
      (select orderid,shipid,billoflading,loadno
        from orderhdr
       where substr(reference,1,10) = substr(oh.reference,1,10)
         and custid = in_custid
         and ordertype = 'V'
         and orderstatus = '9'
         and rtrim(hdrpassthruchar05) = rtrim(oh.hdrpassthruchar05)
         and statusupdate <= oh.statusupdate
       order by statusupdate)
    loop
      ah.orderid := h210ship.orderid;
      ah.shipid := h210ship.shipid;
      ah.billoflading := h210ship.billoflading;
      ah.loadno := h210ship.loadno;
      cntShipped := 1;
      exit;
    end loop;
  end if;
  if cntShipped = 0 then
    strMsg := 'skip--Outbound order not found ' || oh.reference;
    debugmsg(strMsg);
    return;
  end if;

-- get outbound load info
  lo := null;
  debugmsg('get load info');
  begin
    select billoflading,trailer
      into lo.billoflading,lo.trailer
      from loads
     where loadno = ah.loadno;
  exception when no_data_found then
    strMsg := 'Outbound load not found ' || to_char(ah.loadno);
    debugmsg(strMsg);
  end;

  id := null;
  cmdSql := 'select nvl(sum(billedamt),0) as billedamt from invoicedtl where invoice = ' ||
             ih.invoice || ' and activity ' || strTotCmd;
  debugmsg(cmdSql);
  execute immediate cmdSql into id.billedamt;

  debugmsg('set column values');
  h210 := null;
  h210.facility := ih.facility;
  h210.loadno := ih.loadno;
  h210.custid := ph.custid;
  h210.orderid := oh.orderid;
  h210.shipid := oh.shipid;
  h210.prono := oh.prono;
  debugmsg('ah billoflading is >' || ah.billoflading || '<');
  debugmsg('lo billoflading is >' || lo.billoflading || '<');
  debugmsg('ah orderid is >' || to_char(ah.orderid) || '<');
  debugmsg('ah shipid is >' || to_char(ah.shipid) || '<');
  h210.bolnumber := ah.billoflading;
  if nvl(rtrim(h210.bolnumber),'x') = 'x' then
    h210.bolnumber := lo.billoflading;
  end if;
  if nvl(rtrim(h210.bolnumber),'x') = 'x' then
    debugmsg('use order id and ship id');
    h210.bolnumber := to_char(ah.orderid) || '-' || to_char(ah.shipid);
  end if;
  debugmsg('210 billoflading is >' || h210.bolnumber || '<');
  h210.shipterms := oh.shipterms;
  h210.invoice := ph.invoice;
  h210.altinv := ih.invoice;
  h210.invdate := ph.invdate;
  h210.postdate := ph.postdate;
  h210.trailerid := lo.trailer;
  h210.containerid := rtrim(oh.hdrpassthruchar03);
  h210.hdrpassthruchar01 := oh.hdrpassthruchar01;
  h210.ifsd := oh.hdrpassthruchar06;
  h210.totamtdue := to_char(nvl(id.billedamt,0),'99999999.99');
  h210.masterbol := ah.loadno;
  debugmsg('insert 210 hdr info');
  execute immediate 'insert into get_210_hdr_view_' || strSuffix ||
  ' values (:facility,:loadno,:custid,:orderid,:shipid,:prono,:bolnumber, ' ||
  ' :shipterms,:invoice,:altinv,:invdate,:postdate,:trailerid,:containerid, ' ||
  ' :hdrpassthruchar01,:ifsd,:totamtdue,:masterbol)'
  using h210.facility,h210.loadno,h210.custid,h210.orderid,h210.shipid,
        h210.prono,h210.bolnumber,h210.shipterms,h210.invoice,h210.altinv,
        h210.invdate,h210.postdate,h210.trailerid,h210.containerid,
        h210.hdrpassthruchar01,h210.ifsd,h210.totamtdue,h210.masterbol;

end loop;

exception when others then
  debugmsg('extract_invoice: ' || sqlerrm);
end;

begin

mark := 'Start';
debugmsg(mark);

if out_errorno = -12345 then
   strDebugYN := 'Y';
else
   strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

intTotCurr :=0;
intCustCurr :=0;
intCustLen :=length(in_custlist);
strCustCmd :='in (''';
    for intI in 1..intCustLen
      LOOP
        if substr (in_custlist,intI,1) <> ',' then
           strCustCmd := strCustCmd || substr (in_custlist, intI,1);
        else
           strCustCmd := strCustCmd || ''',''';
        end if;
    END LOOP;
strCustCmd := strCustCmd || '''' || ')';

--    Assemble into a total list of codes

strTotCmd :='in (''';
    for intI in 1..intCustLen
      LOOP
        if substr (in_custlist,intI,1) <> ',' then
           strTotCmd := strTotCmd || substr (in_custlist, intI,1);
        else
           strTotCmd := strTotCmd || ''',''';
        end if;
    END LOOP;
strTotCmd := strTotCmd || ''',''';


intCodeCurr :=0;
intCodeLen :=length(in_codelist);
strCodeCmd :='in (''';
    for intI in 1..intCodeLen
      LOOP
        if substr (in_codelist,intI,1) <> ',' then
           strCodeCmd := strCodeCmd || substr (in_codelist, intI,1);
        else
           strCodeCmd := strCodeCmd || ''',''';
        end if;
    END LOOP;
strCodeCmd := strCodeCmd || '''' || ')';

--    assemble onto the Total List of activity codes

    for intI in 1..intCodeLen
      LOOP
        if substr (in_codelist,intI,1) <> ',' then
           strTotCmd := strTotCmd || substr (in_codelist, intI,1);
        else
           strTotCmd := strTotCmd || ''',''';
        end if;
    END LOOP;
strTotCmd := strTotCmd || '''' || ')';


viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
               viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'GET_210_HDR_VIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;
/*
trace_msg('0', strSuffix);
*/
debugmsg('first trace');
select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
/*
trace_msg('X', in_custid);
*/
  out_errorno := -3;
  out_msg := 'Invalid Customer Code-' || in_custid;
  return;
end if;

debugmsg('cust edited');
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


  debugmsg (strCodeCmd);

cmdSql := 'create table get_210_hdr_view_' || strSuffix ||
  ' ( FACILITY varchar2(3), LOADNO number(7), CUSTID varchar2(10), ' ||
  '   ORDERID number(7), SHIPID number(7), PRONO varchar2(20), ' ||
  ' BOLNUMBER varchar2(40), SHIPTERMS varchar2(3), INVOICE number(8), ' ||
  ' ALTINV number(8), INVDATE date, ' ||
  ' POSTDATE date, TRAILERID varchar2(12), CONTAINERID varchar2(12), ' ||
  ' HDRPASSTHRUCHAR01 varchar2(255), ' ||
  ' IFSD varchar2(255), TOTAMTDUE number, MASTERBOL number(7) ) ';

--debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create hdr data
for h210ship in (select orderid,shipid,reference,hdrpassthruchar03,statusupdate,
                        qtyship,hdrpassthruchar05
                   from orderhdr
                  where custid = in_custid
                    and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
                    and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss')
                    and orderstatus = '9'
                    and ordertype = 'V')
loop
  strMsg := 'outbound order ' || to_char(h210ship.orderid) || '-' ||
    to_char(h210ship.shipid) || ' ref: ' || h210ship.reference ||
    ' shipped: ' || to_char(h210ship.statusupdate, 'mm/dd/yy');
  debugmsg(strMsg);
  cntReceipt := 0;
  begin
    select orderid,shipid,prono,shipterms,hdrpassthruchar03,hdrpassthruchar01,
           hdrpassthruchar06,loadno
      into h210rcpt.orderid,h210rcpt.shipid,h210rcpt.prono,h210rcpt.shipterms,
           h210rcpt.hdrpassthruchar03,h210rcpt.hdrpassthruchar01,
           h210rcpt.hdrpassthruchar06,h210rcpt.loadno
      from orderhdr
     where substr(reference,1,10) = substr(h210ship.reference,1,10)
       and custid = in_custid
       and ordertype = 'R'
       and orderstatus = 'R'
       and rtrim(hdrpassthruchar05) = rtrim(h210ship.hdrpassthruchar05)
       and qtyrcvd = h210ship.qtyship;
    cntReceipt := 1;
  exception when others then
    cntReceipt := 0;
  end;
  if cntReceipt = 0 then
    for rcpt in
     (select orderid,shipid,prono,shipterms,hdrpassthruchar03,hdrpassthruchar01,
             hdrpassthruchar06,loadno
        from orderhdr
       where substr(reference,1,10) = substr(h210ship.reference,1,10)
         and custid = in_custid
         and ordertype = 'R'
         and orderstatus = 'R'
         and rtrim(hdrpassthruchar05) = rtrim(h210ship.hdrpassthruchar05)
         and statusupdate < h210ship.statusupdate
       order by statusupdate desc)
    loop
      h210rcpt.orderid := rcpt.orderid;
      h210rcpt.shipid := rcpt.shipid;
      h210rcpt.prono := rcpt.prono;
      h210rcpt.shipterms := rcpt.shipterms;
      h210rcpt.hdrpassthruchar03 := rcpt.hdrpassthruchar03;
      h210rcpt.hdrpassthruchar01 := rcpt.hdrpassthruchar01;
      h210rcpt.hdrpassthruchar06 := rcpt.hdrpassthruchar06;
      h210rcpt.loadno := rcpt.loadno;
      cntReceipt := 1;
      exit;
    end loop;
  end if;
  if cntReceipt = 0 then
    for rcpt in
     (select orderid,shipid,prono,shipterms,hdrpassthruchar03,hdrpassthruchar01,
             hdrpassthruchar06,loadno
        from orderhdr
       where substr(reference,1,10) = substr(h210ship.reference,1,10)
         and custid = in_custid
         and ordertype = 'R'
         and orderstatus = 'R'
         and rtrim(hdrpassthruchar05) = rtrim(h210ship.hdrpassthruchar05)
         and qtyrcvd >= h210ship.qtyship
       order by statusupdate)
    loop
      h210rcpt.orderid := rcpt.orderid;
      h210rcpt.shipid := rcpt.shipid;
      h210rcpt.prono := rcpt.prono;
      h210rcpt.shipterms := rcpt.shipterms;
      h210rcpt.hdrpassthruchar03 := rcpt.hdrpassthruchar03;
      h210rcpt.hdrpassthruchar01 := rcpt.hdrpassthruchar01;
      h210rcpt.hdrpassthruchar06 := rcpt.hdrpassthruchar06;
      h210rcpt.loadno := rcpt.loadno;
      cntReceipt := 1;
      exit;
    end loop;
  end if;
  if cntReceipt = 0 then
    debugmsg('skip--no associated receipt order');
    goto continue_extract_loop;
  end if;
  strMsg := 'invoicehdr data for ' || to_char(h210rcpt.orderid);
  debugmsg(strMsg);
  begin
    select facility,masterinvoice,invoice,loadno
      into h210invh.facility,h210invh.masterinvoice,h210invh.invoice,
           h210invh.loadno
      from invoicehdr
     where orderid = h210rcpt.orderid
       and loadno is not null
       and masterinvoice is not null;
  exception when no_data_found then
    debugmsg('skip--no associated invoicehdr');
    goto continue_extract_loop;
  end;
-- check for any unprocessed shipments associated with the invoice
  strMsg := 'checking invoice ' || h210invh.masterinvoice || ' order ' ||
             to_char(h210rcpt.orderid);
  debugmsg(strMsg);
  for othr in (select orderid
                from invoicehdr
               where masterinvoice = h210invh.masterinvoice
                 and loadno is not null
                 and orderid != h210rcpt.orderid)
  loop
     strMsg := 'checking order ' || to_char(othr.orderid);
     debugmsg(strMsg);
     begin
       select reference,hdrpassthruchar03,qtyrcvd,hdrpassthruchar05
         into h210othr.reference,h210othr.hdrpassthruchar03,
              h210othr.qtyrcvd,h210othr.hdrpassthruchar05
         from orderhdr
        where orderid = othr.orderid
          and shipid = 1;
     exception when no_data_found then
       debugmsg('order reference not found');
       goto continue_extract_loop;
     end;
     strMsg := '  ref: ' || h210othr.reference || ' rcpt: ' ||
               h210othr.hdrpassthruchar05;
     debugmsg(strMsg);
     cntShipped := 0;
     select count(1)
       into cntShipped
       from orderhdr
      where reference = substr(h210othr.reference,1,10)
        and custid = in_custid
        and ordertype = 'V'
        and orderstatus = '9'
        and rtrim(hdrpassthruchar05) = rtrim(h210othr.hdrpassthruchar05)
        and qtyship = h210othr.qtyrcvd;
     if cntShipped = 0 then
       select count(1)
         into cntShipped
         from orderhdr
        where reference = substr(h210othr.reference,1,10)
          and custid = in_custid
          and ordertype = 'V'
          and orderstatus = '9'
          and rtrim(hdrpassthruchar05) = rtrim(h210othr.hdrpassthruchar05)
          and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');
     end if;
     if cntShipped = 0 then
       debugmsg('  skip invoice--shipped order not found--orders on file:');
       for othorders in (select orderid,shipid,qtyrcvd,hdrpassthruchar05,reference
                        from orderhdr
                       where reference = substr(h210othr.reference,1,10)
                         and custid = in_custid
                         and ordertype = 'V')
       loop
         strMsg := '  ' ||
                   to_char(othorders.orderid) || '-' ||
                   to_char(othorders.shipid) || ' rcvd: ' ||
                   to_char(othorders.qtyrcvd) || ' ref: ' ||
                   othorders.reference || ' rcpt: ' ||
                   othorders.hdrpassthruchar05;
         debugmsg(strMsg);
       end loop;
       goto continue_extract_loop;
     end if;
  end loop;
  cmdSql := 'select count(1) from get_210_hdr_view_' || strSuffix ||
  ' where invoice = ' || h210invh.masterinvoice;
--  debugmsg(cmdSql);
  execute immediate cmdSql into cntInvoice;
  if cntInvoice = 0 then
    extract_invoice(h210invh.masterinvoice);
  end if;
<< continue_extract_loop >>
  null;
end loop;

cmdSql := 'create view get_210_hdrhdr_view_' || strSuffix ||
  ' (FACILITY, LOADNO, CUSTID, ORDERID, SHIPID, PRONO, ' ||
  '  BOLNUMBER,  SHIPTERMS, INVOICE, ALTINV, INVDATE, POSTDATE, ' ||
  '  TRAILERID, CONTAINERID, HDRPASSTHRUCHAR01, IFSD, TOTAMTDUE, MASTERBOL) as ' ||
  '  select facility, loadno, custid, ' ||
  '  orderid, shipid, prono, max(bolnumber), shipterms, invoice, ' ||
  '  altinv, invdate, postdate, max(trailerid), containerid, ' ||
  '  hdrpassthruchar01, ifsd, totamtdue, masterbol ' ||
  '  from get_210_hdr_view_' || strSuffix ||
  '  group by facility, loadno, custid, orderid, shipid, prono, ' ||
  '    shipterms, invoice, altinv, invdate, postdate, containerid, ' ||
  '    hdrpassthruchar01, ifsd, totamtdue, masterbol';
/*
 trace_msg('3b',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create order view

cmdSql := 'create view get_210_order_view_' || strSuffix ||
  ' (LOADNO, CUSTID, ORDERID, PRONO, ' ||
  '  BOLNUMBER,  TRAILERID, REFERENCE ) AS select distinct ' ||
  '  gh.loadno, gh.custid, oh.orderid, oh.prono, ' ||
  '  oh.hdrpassthruchar05, oh.hdrpassthruchar03, oh.reference from ' ||
  '  get_210_hdr_view_' || strSuffix || ' gh, orderhdr oh ' ||
  '      where gh.orderid = oh.orderid and ' ||
  '            gh.shipid = oh.shipid';
 /*
 trace_msg('3b',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- create invoicedtl view

cmdSql := 'create view get_210_invdtl_view_' || strSuffix ||
  ' (LOADNO, CUSTID, INVOICE, INVDATE, ACTIVITY, CHARGES) ' ||
  ' as SELECT distinct gh.loadno, gh.custid, gh.invoice, gh.invdate, ' ||
  '    id.activity, to_char(decode(id.invtype,''C'', 0-id.billedamt, ' ||
  '    id.billedamt), ''99999999.99'') from ' ||
  ' get_210_hdr_view_' || strSuffix || ' gh, invoicedtl id ' ||
  ' where  (gh.altinv = id.invoice) and ' ||
  '     id.billedamt <> 0 and id.billstatus <> 4 and ' ||
  '     id.billmethod = ''FLAT'' and ' ||
  '     id.activity ' || strCustCmd;
 /*
 trace_msg('3c',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



-- create plate view

cmdSql := 'create view get_210_plate_view_' || strSuffix ||
  ' (LOADNO, CUSTID, ITEM, LOTNUMBER, USERITEM1, USERITEM2, USERITEM3)' ||
  ' as SELECT gh.loadno, gh.custid, p.item, p.lotnumber, ' ||
  '    sum(p.useritem1), sum(p.useritem2), sum(p.useritem3) from ' ||
  ' get_210_hdr_view_' || strSuffix || ' gh, rctplates p ' ||
  ' where gh.orderid = p.orderid and ' ||
  '     p.CUSTID = ''' || in_custid ||
  ''' and gh.shipid = p.shipid' ||
  ' group by gh.loadno, gh.custid, p.item, p.lotnumber';

 /*
 trace_msg('3d',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- create platesummary view

cmdSql := 'create view get_210_platesum_view_' || strSuffix ||
  ' (LOADNO, CUSTID, ITEM, USERITEM1, USERITEM2, USERITEM3)' ||
  ' as SELECT gh.loadno, gh.custid, p.item,  ' ||
  '    sum(p.useritem1), sum(p.useritem2), sum(p.useritem3) from ' ||
  ' get_210_hdr_view_' || strSuffix || ' gh, rctplates p ' ||
  ' where gh.orderid = p.orderid and ' ||
  '     p.CUSTID = ''' || in_custid ||
  ''' and gh.shipid = p.shipid' ||
  ' group by gh.loadno, gh.custid, p.item';

 /*
 trace_msg('3d',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



-- create chgdtl view

cmdSql := 'create view get_210_chgdtl_view_' || strSuffix ||
  ' (LOADNO, CUSTID,  ITEM, ACTIVITY, CHARGES) ' ||
  ' as SELECT gh.loadno, gh.custid, id.item, ' ||
  '    id.activity, sum(id.billedamt) from ' ||
  ' get_210_hdr_view_' || strSuffix || ' gh, invoicedtl id ' ||
  ' where  id.custid = ''' || in_custid ||
  ''' and gh.altinv = id.invoice' ||
  '   and id.activity '  || strCodeCmd  ||
  '   and id.billedamt <> 0  and id.billstatus <> 4' ||
  ' group by gh.loadno, gh.custid, id.item, id.activity';
 /*
 trace_msg('3c',cmdSql);
 */

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);





out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  debugmsg (out_msg);
  out_msg := 'zb210 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_pacam210;

----------------------------------------------------------------------
-- end_pacam210
----------------------------------------------------------------------
procedure end_pacam210
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

  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
               in_viewsuffix;

cmdSql := 'drop VIEW get_210_hdrhdr_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW get_210_order_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW get_210_invdtl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW get_210_chgdtl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


cmdSql := 'drop VIEW get_210_plate_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW get_210_platesum_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop TABLE get_210_hdr_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'ze210 ' || sqlerrm;
  out_errorno := sqlcode;
end end_pacam210;

-------------------------------------------------------------
--  PD SHIPNOTE 945
-------------------------------------------------------------

procedure begin_pd_shipnote945
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
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
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

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20) as trackingno,
         substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20),
            substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15);
sp curShippingPlate%rowtype;



cursor curShippingPlateLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20) as trackingno,
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
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20),
            lotnumber;
spl curShippingPlateLot%rowtype;

cursor curShippingPlateInvClass(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20) as trackingno,
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
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,20),
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
  qtyapplied    orderdtl.qtyorder%type
);

type lot_tbl is table of lot_rcd
     index by binary_integer;

lots lot_tbl;
lotx integer;
lotfound boolean;
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
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
strCaseUpc varchar2(255);
dteExpirationDate date;
weightshipped orderdtl.weightship%type;
dtl945 ship_note_945_dtl%rowtype;
strLotNumber shippingplate.lotnumber%type;
l_condition varchar2(255);

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
  ol curOrderDtlLine%rowtype, in_lotnumber varchar2, in_qty number) is
begin

debugmsg('begin insert_945_lot '  || od.orderid || '-' || od.shipid || ' ' ||
  ol.item || ' ' || in_lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into ship_note_945_lot_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,' ||
':ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
':QTYSHIPPED)',
  dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.CUSTID);
dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ol.dtlpassthrunum10);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', in_lotnumber);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', strLotNumber);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', in_qty);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end;

procedure insert_945_dtl(oh curOrderHdr%rowtype, od curOrderDtl%rowtype,
  ol curOrderDtlLine%rowtype, invcls varchar2) is
begin

debugmsg('begin insert_945_dtl '  || od.orderid || '-' || od.shipid || ' ' ||
  od.item || ' ' || od.lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

if upper(nvl(in_include_fromlpid_yn,'N')) = 'Y' and
   upper(nvl(in_summarize_lots_yn,'Y')) = 'Y' then
  qtyShipped := qtyLineNumber;
else
  qtyShipped := qtyLineAccum;
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
weightshipped := zci.item_weight(cu.custid,od.item,od.uom) * qtyShipped;
dtl945.shipticket := substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15);

if nvl(rtrim(in_invclass_yn),'N') = 'N' then
  InvClass := '  ';
else
  InvClass := invcls;
end if;

if ca.multiship = 'Y' then
  dtl945.trackingno := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,20);
else
  if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
    dtl945.trackingno :=
          nvl(oh.prono,nvl(ld.prono,nvl(oh.billoflading,nvl(ld.billoflading,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)))));
  else
    dtl945.trackingno :=
      nvl(oh.prono,nvl(ld.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)));
  end if;
end if;
dtl945.kgs := weightshipped / 2.2046;
dtl945.gms := weightshipped / .0022046;
dtl945.ozs := weightshipped * 16;
dtl945.smallpackagelbs := zim14.freight_weight(oh.orderid,oh.shipid,od.item,od.lotnumber,
  nvl(rtrim(in_round_freight_weight_up_yn),'N'));
dtl945.deliveryservice :=
 substr(zim14.delivery_service(oh.orderid,oh.shipid,od.item,od.lotnumber),1,10);
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
':DTLPASSTHRUCHAR20,:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,' ||
':DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,' ||
':DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,' ||
':DTLPASSTHRUDATE02,:DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,' ||
':DTLPASSTHRUDOLL02, :FROMLPID, :SMALLPACKAGELBS, :DELIVERYSERVICE)',
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
dbms_sql.bind_variable(curFunc, ':REFERENCE', oh.REFERENCE);
dbms_sql.bind_variable(curFunc, ':LINENUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ORDERDATE', oh.ENTRYDATE);
dbms_sql.bind_variable(curFunc, ':PO', oh.PO);
dbms_sql.bind_variable(curFunc, ':QTYORDERED', ol.QTY);
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
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':FROMLPID', strFromLpid);
dbms_sql.bind_variable(curFunc, ':SMALLPACKAGELBS', dtl945.smallpackagelbs);
dbms_sql.bind_variable(curFunc, ':DELIVERYSERVICE', dtl945.DELIVERYSERVICE);
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
          lotfound := false;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spl.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfound := true;
              exit;
            end if;
          end loop;
          if lotfound then
            dsplymsg := 'lot found ' || to_char(lotx, '99') || lots(lotx).lotnumber;
            debugmsg(spl.lotnumber);
          else
            lotx := lots.count + 1;
            dsplymsg := 'lot new ' || to_char(lotx, '99') || lots(lotx).lotnumber;
            if lotx = 1 then
               debugmsg(' lotx1');
            else
               debugmsg(' lotx not 1');
            end if;
            debugmsg(spl.lotnumber || '-' || lots(lotx).lotnumber);
            lots(lotx).lotnumber := spl.lotnumber;
            lots(lotx).qtyApplied := qtyLineNumber;
          end if;
          qtyRemain := qtyRemain - qtyLineNumber;
          spl.qty := spl.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
        insert_945_dtl(oh, od, ol, '  ');
        for lotx in 1..lots.count
        loop
          insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied);
        end loop;
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
      qtyLineAccum := 0;
      lots.delete;
      qtyLineNumber := 0;
--      qtyRemain := ol.qty;
/*
      -- If the Detail Line qty is zero, default it to the ship qty
         for the Order Detail.  WARNING!!! multiple zero quantity lines
         will cause a malfunction (maybe)...
*/
/*      if qtyRemain = 0 then
         qtyRemain := od.qtyship;
      end if;
*/
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
          lotfound := false;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spi.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfound := true;
              exit;
            end if;
          end loop;
          if lotfound then
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

      qtyLineAccum := od.qtyship;
      if qtyLineAccum > ol.qty then
         qtyLineAccum := ol.qty;
      end if;

      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
        insert_945_dtl(oh, od, ol, spi.inventoryclass);
        for lotx in 1..lots.count
        loop
          insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied);
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
        add_945_dtl_rows_by_invclass(oh);
     end if;
  end if;

exception when others then
  debugmsg(sqlerrm);
end;

procedure extract_by_line_numbers is
begin

debugmsg('begin 945 extract by line numbers');
debugmsg('creating 945 dtl');
cmdSql := 'create table SHIP_NOTE_945_DTL_' || strSuffix ||
' (ORDERID NUMBER(7) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
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
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),DTLPASSTHRUNUM03 NUMBER(16,4),' ||
' DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),DTLPASSTHRUNUM09 NUMBER(16,4),' ||
' DTLPASSTHRUNUM10 NUMBER(16,4),DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,DTLPASSTHRUDOLL01 NUMBER(10,2),' ||
' DTLPASSTHRUDOLL02 NUMBER(10,2), FROMLPID varchar2(15), smallpackagelbs number,'||
' deliveryservice varchar2(10) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('creating 945 lot');
cmdSql := 'create table SHIP_NOTE_945_lot_' || strSuffix ||
' (ORDERID NUMBER(7) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4),item varchar2(50) not null,LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),' ||
' QTYSHIPPED NUMBER(7) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 lxd');
cmdSql := 'create table SHIP_NOTE_945_LXD_' || strSuffix ||
        ' (ORDERID NUMBER(7) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 man');
cmdSql := 'create table SHIP_NOTE_945_MAN_' || strSuffix ||
' (ORDERID NUMBER(7),SHIPID NUMBER(2),CUSTID VARCHAR2(10),item varchar2(50),' ||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),SERIALNUMBER VARCHAR2(30)' ||
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

  debugmsg('Condition = '||l_condition);

  -- Create header view
cmdSql := 'create view ship_note_945_hdr_' || strSuffix ||
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
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
  'trailer,seal,palletcount,freightcost,lateshipreason )'||
  'as select ' ||
  'oh.custid,'' '','' '',oh.loadno,oh.orderid,oh.shipid,oh.reference,';
if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,20),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid)))))),';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,20),'||
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
  'oh.carrier,ca.name,'||
  '''  '',oh.hdrpassthruchar06,oh.shiptype,oh.shipterms,''A'','||
  'oh.reference,oh.po,oh.hdrpassthruchar07,'||
  'to_char(oh.arrivaldate,''YYYYMMDD''),'||
  'decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),'||
  'nvl(oh.billoflading,nvl(L.billoflading,to_char(oh.orderid)||''-''||to_char(oh.shipid)))),'||
  'nvl(oh.prono,L.prono),'||
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
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,'||
  'HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,' ||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,' ||
  'L.trailer,L.seal,'||
  'zim7.pallet_count(oh.loadno,oh.custid,oh.fromfacility,oh.orderid,oh.shipid), ';
if rtrim(in_ltl_freight_passthru) is not null then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'zim14.freight_total(oh.orderid,oh.shipid,null,null),oh.'||
  in_ltl_freight_passthru || ') ';
else
  cmdSql := cmdSql || 'zim14.freight_total(oh.orderid,oh.shipid,null,null) ';
end if;
cmdSql := cmdSql || ', L.lateshipreason ';
cmdSql := cmdSql ||
  ' from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
  ' and oh.carrier = ca.carrier(+) '||
  ' and oh.loadno = L.loadno(+) ' ||
  ' and oh.fromfacility = F.facility(+) '||
  ' and oh.custid = C.custid(+) ' ||
  ' and oh.shipto = CN.consignee(+) ' ||
  l_condition;

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
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
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
 ',DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03' ||
 ',DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07' ||
 ',DTLPASSTHRUNUM08,DTLPASSTHRUNUM09, '||
' DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,' ||
' DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02, FROMLPID, smallpackagelbs ,' ||
' deliveryservice)' ||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10,'||
 'substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),'||
 'decode(nvl(ca.multiship,''N''),''Y'','||
 '  substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,20),'||
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
            '''Y'',''PR'',''CC'')))),'||
 'oh.reference,'||
 'nvl(d.dtlpassthruchar13,''000000''),oh.entrydate,oh.po,d.qtyentered,'||
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
 ',D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10, '||
 ' D.DTLPASSTHRUDATE01,D.DTLPASSTHRUDATE02,D.DTLPASSTHRUDATE03,D.DTLPASSTHRUDATE04,' ||
 ' D.DTLPASSTHRUDOLL01,D.DTLPASSTHRUDOLL02, ''000000000000000'',0,oh.deliveryservice ' ||
 ' from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
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
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.barcode is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create man (serial number view)
cmdSql := 'create view ship_note_945_rtv_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber, ' ||
 ' lp_scanout, lp_scanin, useritem1, useritem2, useritem3, ' ||
 ' link_lotnumber,serialnumber,reference) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, s.lastupdate, dp.creationdate, dp.useritem1, dp.useritem2, ' ||
 ' dp.useritem3, nvl(s.lotnumber,''(none)''),s.serialnumber,oh.reference '||
 'from shippingplate s, orderhdr oh, orderdtl d, deletedplate dp ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.fromlpid = dp.lpid' ||
 ' and d.orderid = oh.orderid' ||
 ' and d.shipid = oh.shipid' ||
 ' and d.item = s.item' ||
 ' and s.status||'''' = ''SH'''||
 ' and s.serialnumber is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create lot view
debugmsg('create lot view');
cmdSql := 'create view ship_note_945_lot_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,qtyshipped) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.orderlot,''(none)''),sum(s.quantity) '||
 'from shippingplate s, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.status||'''' = ''SH'''||
 ' and s.type in (''F'',''P'') '||
 l_condition  ||
' group by s.orderid,s.shipid,s.custid,s.item,'||
' s.lotnumber, nvl(s.orderlot,''(none)'') ';

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


<< finish_shipnote945 >>

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
||' ,hdr.trackingno,dateshipped,commitdate,shipviacode,hdr.lbs,hdr.kgs,hdr.gms,hdr.ozs'
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
end begin_pd_shipnote945;


procedure end_pd_shipnote945
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

if out_errorno = -12345 then
    strDebugYN := 'Y';
else
    strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

if cu.linenumbersyn = 'Y' then
  strObject := ' table ';
else
  strObject := ' view ';
end if;


cmdSql := 'drop ' || strObject || ' ship_note_945_man_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


cmdSql := 'drop ' || strObject || ' ship_note_945_lxd_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop ' || strObject || ' ship_note_945_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop ' || strObject || ' ship_note_945_lot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW ship_note_945_hd_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop ' || strObject || ' ship_note_945_s18_' || strSuffix;
debugmsg (cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW ship_note_945_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn945 ' || sqlerrm;
  out_errorno := sqlcode;
end end_pd_shipnote945;

----------------------------------------------------------------------
-- begin_pacam856
----------------------------------------------------------------------
procedure begin_pacam856
(in_custid IN varchar2
,in_loadno IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

cursor C_LOADS
IS
  select distinct loadno
    from orderhdr
   where orderstatus = '9'
     and custid = in_custid
     and loadno = decode(nvl(in_loadno,0), 0, loadno, in_loadno)
     and statusupdate >= nvl(to_date(in_begdatestr,'yyyymmddhh24miss'),
                           statusupdate)
     and statusupdate < nvl(to_date(in_enddatestr,'yyyymmddhh24miss'),
                           statusupdate+1);

CURSOR C_LOAD(in_loadno number)
RETURN loads%rowtype
IS
  SELECT *
    FROM loads
   WHERE loadno = in_loadno;
ld loads%rowtype;

cursor C_SHIPTO(in_loadno number)
is
  select shipto, shiptype, hdrpassthruchar02 from orderhdr
  where loadno = in_loadno;

CURSOR C_ORD(in_custid varchar2, in_po varchar2)
IS
  SELECT *
    FROM orderhdr
   WHERE custid = in_custid
     AND po = in_po;

CURSOR C_ORDPO(in_loadno number)
IS
  SELECT distinct custid, po
    FROM orderhdr
   WHERE loadno = in_loadno;

cursor C_DTL(in_orderid number, in_shipid number)
IS
 select *
   from orderdtl
  where orderid = in_orderid
    and shipid = in_shipid;


viewcount integer;
strSuffix varchar2(32);

l_condition varchar2(200);
l_loadno number(9);
l_shiptype varchar2(2);
l_bol varchar2(20);
l_shipto varchar2(20);
l_carrierauth varchar2(40);
l_ladingqty number(10);
l_qtyship number(10);
l_qty number(10);
l_ca_qty number(10);
ix number(10);
l_sscc varchar2(20);
l_upc varchar2(20);
l_sku varchar2(20);
l_shipmentid varchar2(20);
l_hdrpassthruchar02 varchar2(40);
rowCnt integer;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);


begin


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
   where table_name = 'PACAM856HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;



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

  debugmsg(l_condition);

  cmdSql := 'create table pacam856hdr_' || strSuffix ||
    ' (CUSTID VARCHAR2(10),LOADNO NUMBER(9),SHIPMENTID VARCHAR2(27),UOM VARCHAR2(4),'||
     ' LADINGQTY NUMBER(10),WEIGHT NUMBER(17,8),'||
     ' CARRIER VARCHAR2(4),SHIPTYPE VARCHAR2(1),CARRIERAUTH VARCHAR2(40),'||
     ' CARRIERAUTH2 VARCHAR2(40),CARRIERAUTH3 VARCHAR2(40),'||
     ' BILLOFLADING VARCHAR2(40),PRONO VARCHAR2(20),SHIPDATE VARCHAR2(10),'||
     ' SHIPTIME VARCHAR2(10), SHIPTO VARCHAR2(10),FACILITY VARCHAR2(3))';

  --debugmsg(cmdSql);

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);

  cmdSql := 'create table pacam856ord_' || strSuffix ||
    ' (CUSTID VARCHAR2(10), LOADNO NUMBER(9),SHIPMENTID VARCHAR2(27),'||
     ' ORDERID NUMBER(9), SHIPID NUMBER(2),'||
     ' PO VARCHAR2(20), QTYSHIP NUMBER(10), UOM VARCHAR2(4))';

  --debugmsg(cmdSql);

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);

  cmdSql := 'create table pacam856pckg_' || strSuffix ||
    ' (CUSTID VARCHAR2(10), LOADNO NUMBER(9),SHIPMENTID VARCHAR2(27),'||
     ' ORDERID NUMBER(9), SHIPID NUMBER(2),'||
     ' BARCODE VARCHAR2(20))';

  --debugmsg(cmdSql);

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);

  cmdSql := 'create table pacam856dtl_' || strSuffix ||
    ' (CUSTID VARCHAR2(10), LOADNO NUMBER(9),SHIPMENTID VARCHAR2(27),'||
     ' ORDERID NUMBER(9), SHIPID NUMBER(2),BARCODE VARCHAR2(20),'||
     ' UPC VARCHAR2(20), SKU VARCHAR2(20), item varchar2(50), '||
     ' QTYSHIP NUMBER(10),UOM VARCHAR2(4))';

  --debugmsg(cmdSql);

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);

  if in_loadno != 0 then
     l_loadno := in_loadno;
  else
     open C_LOADS;
  end if;
  while(1=1)
  loop
    if in_loadno = 0 then
       fetch C_LOADS into l_loadno;
       exit when C_LOADS%notfound;
    end if;
    debugmsg('loadno ' || l_loadno);
    ld := null;
    OPEN C_LOAD(l_loadno);
    FETCH C_LOAD into ld;
    CLOSE C_LOAD;

    OPEN C_SHIPTO(l_loadno);
    FETCH C_SHIPTO into l_shipto, l_shiptype, l_hdrpassthruchar02;
    CLOSE C_SHIPTO;

    l_carrierauth := null;
    l_ladingqty := 0;
    if ld.billoflading is not null then
       l_bol := ld.billoflading;
    else
       select count(1) into rowCnt from orderhdr
          where loadno = l_loadno;

       if rowCnt = 1 then
          select orderid || '-'|| shipid into l_bol
             from orderhdr
             where loadno = l_loadno;
       else
          l_bol := l_loadno;
       end if;
    end if;
    for ohpo in C_ORDPO(l_loadno) loop
       l_shipmentid := to_char(l_loadno, 'FM0999999') || ohpo.po;
       for oh in C_ORD(ohpo.custid, ohpo.po) loop
          l_qtyship := 0;
          for od in C_DTL(oh.orderid, oh.shipid) loop
             l_qty := zlbl.uom_qty_conv(od.custid, od.item, od.qtyship, od.uom, 'CS');
             l_qtyship := l_qtyship + l_qty;
             l_ladingqty := l_ladingqty + l_qty;
             l_ca_qty := zlbl.uom_qty_conv(od.custid, od.item, 1, 'CS', od.uom);
             ix := 0;
             while ix < l_qty loop
                ix := ix + 1;
                l_sscc := zlbl.caselabel_barcode(oh.custid, '0');
                l_upc := null;
                begin
                   select itemalias into l_upc from custitemalias
                      where custid = od.custid
                        and item = od.item
                        and aliasdesc = 'UPC';
                  exception when others then
                     null;
                end;
                l_sku := null;
                begin
                  select itemalias into l_sku from custitemalias
                     where custid = od.custid
                       and item = od.item
                       and aliasdesc = 'SKU';
                  exception when others then
                     null;
                end;
                if l_sku is null then
                   l_sku := '(NONE)';
                end if;
                execute immediate 'insert into pacam856pckg_' || strSuffix ||
                  ' values (:CUSTID,:LOADNO,:SHIPMENTID,:ORDERID,:SHIPID,:BARCODE)'
                   using oh.custid,oh.loadno,l_shipmentid,oh.orderid,oh.shipid,l_sscc;
                execute immediate 'insert into pacam856dtl_' || strSuffix ||
                  ' values (:CUSTID,:LOADNO,:SHIPMENTID,:ORDERID,:SHIPID,:BARCODE,:UPC,'||
                      ':SKU,:ITEM,:QTYSHIP,:UOM)'
                   using oh.custid,oh.loadno,l_shipmentid,oh.orderid,oh.shipid,l_sscc,l_upc,
                         l_sku,od.item,l_ca_qty,od.uom;
             end loop;


          end loop;
          debugmsg(oh.orderid || ' ' || oh.shipid);
          execute immediate 'insert into pacam856ord_' || strSuffix ||
            ' values (:CUSTID,:LOADNO,:SHIPMENTID,:ORDERID,:SHIPID,:PO,:QTYSHIP,:UOM)'
             using oh.custid,oh.loadno,l_shipmentid,oh.orderid,oh.shipid,oh.po,l_qtyship,'CS';

       end loop;

       execute immediate 'insert into pacam856hdr_' || strSuffix ||
       ' values (:CUSTID,:LOADNO,:SHIPMENTID,:UOM,:LADINGQTY,:WEIGHT,:CARRIER,:SHIPTYPE,'||
          ':CARRIERAUTH,:CARRIERAUTH2,:CARRIERAUTH3,:BILLOFLADING,:PRONO,:SHIPDATE,:SHIPTIME,:SHIPTO,:FACILITY)'
       using in_custid,l_loadno,l_shipmentid,'CS',l_ladingqty,ld.weightship,ld.carrier,l_shiptype,
             ld.seal,l_hdrpassthruchar02,ld.trailer,l_bol,ld.prono,to_char(ld.statusupdate,'YYYYMMDD'),
             to_char(ld.statusupdate,'HH24MISS'), l_shipto, ld.facility;
--
    end loop;

    if in_loadno != 0 then
       exit;
    end if;
  end loop;

  if in_loadno = 0 then
     close C_LOADS;
  end if;


out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn856 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_pacam856;



----------------------------------------------------------------------
-- end_pacam856
----------------------------------------------------------------------
procedure end_pacam856
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

cmdSql := 'drop table pacam856dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table pacam856pckg_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table pacam856ord_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table pacam856hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn856 ' || sqlerrm;
  out_errorno := sqlcode;
end end_pacam856;




end zimportproc7pd;
/
show errors package body zimportproc7pd;

exit;


