CREATE OR REPLACE PACKAGE  BODY zimportproctms
as
--
-- $Id$
--

procedure begin_tmsexport
(in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

in_carrier varchar2(10);
i integer;
rowcnt integer;
dteTest date;

cmt varchar2(4000);
cmt1 varchar2(4000);
cmt2 varchar2(4000);
cmt3 varchar2(4000);

commentsize constant integer := 4000;
breakatch10 char(1);

str varchar2(4000);
len integer;
tcur integer;
tpos integer;
tcnt integer;
l_seq integer;
startline integer;
bolcnt integer;

carrierexists integer;

currentbol varchar2(10);
currenbolhazflag char(1);

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);
viewcount integer;

cursor bol_header( in_beg date, in_end date) is
select  BOL,custid, hazflag,orderid,shipid,consignee
from tmsexportview
where rtrim(scac) in (select rtrim(code) from tmscarriers)
and orderdate between in_beg and in_end
and shipid = 1
order by BOL;

cursor bol_nohazdetail(in_bol varchar2) is
select to_char(od.orderid) || '-' || to_char(od.shipid) as BOL,
'I' as linetype,
sum(od.qtyship) as qtyship,
sum(od.weightship) as weightship,
ci.hazardous,
nc.class,
nc.descr as description
from orderdtl od,
    custitem ci,
    nmfclasscodes nc
where od.item = ci.item (+)
 and  ci.nmfc = nc.nmfc (+)
 and  (ci.hazardous is null or ci.hazardous = 'N')
 and to_char(od.orderid) || '-' || to_char(od.shipid) = in_bol
group by to_char(od.orderid) || '-' || to_char(od.shipid),
      ci.hazardous,nc.class,nc.descr;

cursor bol_hazdetail(in_bol varchar2) is
select to_char(od.orderid) || '-' || to_char(od.shipid) as BOL,
'I' as linetype,
od.item,
od.qtyship,
od.weightship,
ci.hazardous,
nc.class,
decode(ci.hazardous,'Y',
   od.uomentered||', '||rtrim(cc.dotbolcomment)||'  |  '||rtrim(ci.descr)||', I#'||rtrim(od.item)||', CHEM#'||ci.primarychemcode,
      od.uomentered||', '||rtrim(ci.descr)||', I#'||rtrim(od.item)) as description
from orderdtl od,
    custitem ci,
    nmfclasscodes nc,
    chemicalcodes cc
where ci.primarychemcode = cc.chemcode (+)
 and  od.item = ci.item (+)
 and  ci.nmfc = nc.nmfc (+)
 --and ci.hazardous = 'Y'
 and  to_char(od.orderid) || '-' || to_char(od.shipid) = in_bol;


 cursor odbolcomments(in_bol varchar2,in_item varchar2) is
 select bolcomment
  from orderdtlbolcomments
  where in_bol = to_char(orderid) || '-' || to_char(shipid) and
   item = in_item  and
   1 = 2;

 --cursor cibolcomments(in_custid varchar2,in_bol varchar2,in_item varchar2) is
 cursor cibolcomments(in_custid varchar2,in_bol varchar2,in_consingee varchar2) is
 select comment1
  from custitembolcomments
  where (
      (
        (item = 'default' or item is null) and
        custid = in_custid         and
        (
         consignee = in_consingee or
         consignee = 'default'
         )
      )
        or
      (
        (item = 'default' or item is null) and
        custid = 'default'            and
        (
         consignee = in_consingee or
         consignee = 'default'
         )
      )
   );

cursor ohbolcomments(in_bol varchar2) is
 select bolcomment
  from orderhdrbolcomments
  where in_bol = to_char(orderid) || '-' || to_char(shipid);



cursor chemcomments(in_custid varchar2,in_item varchar2) is
select rtrim(b.dotbolcomment) as chemcom1,
rtrim(b.iatabolcomment) as chemcom2,
rtrim(b.imobolcomment) as chemcom3
from  custitem a,
     chemicalcodes b
where a.primarychemcode = b.chemcode
and a.custid = in_custid and a.item = in_item
and (b.dotbolcomment is not null
or b.iatabolcomment is not null
or b.imobolcomment is not null)
union
select rtrim(b.dotbolcomment) as chemcom1,
rtrim(b.iatabolcomment) as chemcom2,
rtrim(b.imobolcomment) as chemcom3
from  custitem a,
     chemicalcodes b
where a.secondarychemcode = b.chemcode
and a.custid = in_custid and a.item = in_item
and (b.dotbolcomment is not null
or b.iatabolcomment is not null
or b.imobolcomment is not null)
union
select rtrim(b.dotbolcomment) as chemcom1,
rtrim(b.iatabolcomment) as chemcom2,
rtrim(b.imobolcomment) as chemcom3
from  custitem a,
     chemicalcodes b
where a.tertiarychemcode = b.chemcode
and a.custid = in_custid and a.item = in_item
and (b.dotbolcomment is not null
or b.iatabolcomment is not null
or b.imobolcomment is not null)
union
select rtrim(b.dotbolcomment) as chemcom1,
rtrim(b.iatabolcomment) as chemcom2,
rtrim(b.imobolcomment) as chemcom3
from  custitem a,
     chemicalcodes b
where a.quaternarychemcode = b.chemcode
and a.custid = in_custid and a.item = in_item
and (b.dotbolcomment is not null
or b.iatabolcomment is not null
or b.imobolcomment is not null);


cursor carrierlistexists is
   select count(*) from user_tables
      where table_name = 'TMSCARRIERS';

begin




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

 -- Check for TMSCarriers table

open carrierlistexists;
fetch carrierlistexists into carrierexists;
close carrierlistexists;

if carrierexists = 0 then

    out_errorno := -3;
    out_msg := 'TMSCARRIERS Table Missing';
    zms.log_msg('BGNTMSEXPORT', null, null,
         out_msg, 'E', 'BGNTMSEXPORT', out_msg);
    return;

end if;


 -- Put data w/ chr(10) on separate lines?

 breakatch10 := 'N';

 -- Calculate view suffix

viewcount := 1;
while(1=1)
loop

  strSuffix := 'ALL'|| viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'TMS_HDRVIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;


  rowcnt := 0;
  bolcnt := 0;



  for bolh in bol_header(to_date(in_begdatestr,'YYYYMMDDHH24MISS'),
                         to_date(in_enddatestr,'YYYYMMDDHH24MISS')) loop





       i := 1;
       bolcnt := bolcnt + 1;


       currentbol := bolh.bol;



       currenbolhazflag := bolh.hazflag;



       if  bolh.hazflag = 'N' then

       zut.prt('hi jim N:' || bolh.bol);

            for nhd in bol_nohazdetail(bolh.bol) loop

               zut.prt('bol :' || nhd.bol);


               begin

               insert into tmsexport values(nhd.bol,lpad(to_char(i),2,'0'),
                  nhd.linetype,
                  nhd.qtyship,round(nhd.weightship,0),nhd.hazardous,
                  nhd.class,nhd.description,strSuffix,bolh.orderid,bolh.shipid);


            exception when others then
               zut.prt('error1a ' || out_errorno);
            end;



            i := i + 1;
            rowcnt := rowcnt + 1;


            end loop;
       else



            for hd in bol_hazdetail(bolh.bol) loop


               begin



               insert into tmsexport values(hd.bol,lpad(to_char(i),2,'0'),
                  hd.linetype,
                  hd.qtyship,round(hd.weightship,0),hd.hazardous,
                  hd.class,hd.description,strSuffix,bolh.orderid,bolh.shipid);


            exception when others then
                  zut.prt('error1b ' || out_errorno);
            end;

            i := i + 1;

            rowcnt := rowcnt + 1;


            commit;

      -- Add order detail BOL comments

            open odbolcomments(bolh.bol,hd.item);
            fetch odbolcomments into cmt;
            close odbolcomments;

            if breakatch10 = 'N' then
               cmt := replace(cmt,chr(10),'  ');
            end if;

            len := length(cmt);
                  tcur := 1;


                  while tcur < len loop

                      l_seq := l_seq + 1;
                           tpos := instr(cmt, chr(10), tcur);


                        if  tpos = 0 then
                              tpos := len;

                              tcnt := tpos - tcur + 1 ;

                           else
                              tcnt := tpos - tcur;

                           end if;

                           if tcnt > commentsize then
                              tcnt := commentsize;
                              tpos := tcur + commentsize - 1;

                           end if;



                        if tcnt > 0 then
                              str := substr(cmt,tcur, tcnt);
                           else
                              str := ' ';
                           end if;


                           tcur := tpos + 1;

                           if str <> ' ' then
                              insert into tmsexport values(hd.bol,lpad(to_char(i),2,'0'),
                     'T',
                     null,null,null,
                     null,str,strSuffix,bolh.orderid,bolh.shipid);

                              commit;

                              i := i + 1;
                              rowcnt := rowcnt + 1;

                           end if;
                  end loop;

 -- Add cust item BOL comments

       for cib in cibolcomments(bolh.custid,bolh.bol,bolh.consignee) loop
               cmt := cib.comment1;

            --open cibolcomments(bolh.custid,bolh.bol,hd.item);
            --fetch cibolcomments into cmt;
            --close cibolcomments;

            if breakatch10 = 'N' then
               cmt := replace(cmt,chr(10),'  ');
            end if;

            len := length(cmt);
                  tcur := 1;


                  while tcur < len loop

                        l_seq := l_seq + 1;
                           tpos := instr(cmt, chr(10), tcur);


                        if  tpos = 0 then
                              tpos := len;
                              tcnt := tpos - tcur + 1 ;
                           else
                              tcnt := tpos - tcur;
                           end if;


                           if tcnt > commentsize then
                              tcnt := commentsize;
                              tpos := tcur + commentsize - 1;
                           end if;



                        if tcnt > 0 then
                              str := substr(cmt,tcur, tcnt);
                           else
                              str := ' ';
                           end if;

                           tcur := tpos + 1;

                           if str <> ' ' then
                              insert into tmsexport values(hd.bol,lpad(to_char(i),2,'0'),
                     'T',
                     null,null,null,
                     null,str,strSuffix,bolh.orderid,bolh.shipid);

                              commit;

                              i := i + 1;
                              rowcnt := rowcnt + 1;
                           end if;
                  end loop;
                 end loop;



       -- Add order header BOL comments
             If currenbolhazflag = 'Y'  then
            cmt := ' ';
         open ohbolcomments(bolh.bol);
         fetch ohbolcomments into cmt;
         close ohbolcomments;

         if breakatch10 = 'N' then
            cmt := replace(cmt,chr(10),'  ');
         end if;

          len := length(cmt);
                 tcur := 1;


                 while tcur < len loop

                  l_seq := l_seq + 1;
                        tpos := instr(cmt, chr(10), tcur);


                      if  tpos = 0 then
                           tpos := len;
                           tcnt := tpos - tcur + 1 ;
                         else
                           tcnt := tpos - tcur;
                         end if;

                        if tcnt > commentsize then
                              tcnt := commentsize;
                              tpos := tcur + commentsize - 1;
                        end if;



                      if tcnt > 0 then
                           str := substr(cmt,tcur, tcnt);
                        else
                           str := ' ';
                        end if;

                        tcur := tpos + 1;

                        if str <> ' ' then
                           insert into tmsexport values(currentbol,lpad(to_char(i),2,'0'),
                  'T',
                  null,null,null,
                  null,str,strSuffix,bolh.orderid,bolh.shipid);

                           commit;

                           i := i + 1;
                           rowcnt := rowcnt + 1;
                        end if;
                 end loop;
               end if;
         end loop;
      end if;

  end loop;

 commit;

-- Create Header View



cmdSql := 'create view TMS_HDRVIEW_' || strSuffix ||
 ' as select ''L''||lpad(orderid,6,''0'') as bol,custid,seq,orderstatus,shipper,consignee,billto,shipdate,arrivaldate, ' ||
   'TO_CHAR(orderdate,''MM/DD/YYYY'') as orderdate,shipterms,scac,po,reference,prono,apptdate,amtcod,revenucode,hazflag,qtyship, ' ||
   ' weightship,terminalcode,orderid,shipid,facility,confname,inerlinecarrier,companycheckok,servicedays,pallets ' ||
 ' from tmsexportview ' ||
 ' where rtrim(scac) in (select rtrim(code) from tmscarriers) ' ||
 ' and orderdate between  to_date('||in_begdatestr||',''YYYYMMDDHH24MISS'') and ' ||
 'to_date('||in_enddatestr||',''YYYYMMDDHH24MISS'')';



curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- Create Detail View


cmdSql := 'create view TMS_DETAILVIEW_' || strSuffix ||
 ' as select ''L''||lpad(orderid,6,''0'') as DETAILBOL,SEQ,LINETYPE,PIECES,WEIGHT,HAZFLAG,LTLCLASS,DESCRIPTION, ' ||
 '  orderid,  shipid ' ||
 ' from tmsexport ' ||
 ' where suffix = '''||strSuffix||'''';


curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



  out_errorno := viewcount;
  out_msg := 'OKAY';
  return;



  exception when others then
   out_msg := sqlerrm;
   return;

end begin_tmsexport;


-------------------
-- end_tmsexport --
-------------------

procedure end_tmsexport
(in_viewsuffix IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2)
 is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
begin


 strSuffix := 'ALL' || in_viewsuffix;

  cmdSql := 'drop VIEW tms_detailview_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);


  delete from tmsexport where suffix = strSuffix;


  cmdSql := 'drop VIEW tms_hdrview_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);


  out_errorno := 0;
  out_msg := 'OKAY';
  return;

  exception when others then
   out_msg := sqlerrm;
   return;


end end_tmsexport;


-----------------------
-- begin tmscustexport --
-----------------------

procedure begin_tmscustexport
(in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is


curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);
viewcount integer;

dteTest date;

carrierexists integer;

cursor carrierlistexists is
   select count(*) from user_tables
      where table_name = 'TMSCARRIERS';

begin


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

 -- Check for TMSCarriers table

open carrierlistexists;
fetch carrierlistexists into carrierexists;
close carrierlistexists;

if carrierexists = 0 then

    out_errorno := -3;
    out_msg := 'TMSCARRIERS Table Missing';
    zms.log_msg('TMSCSTEXPORT', null, null,
         out_msg, 'E', 'TMSCSTEXPORT', out_msg);
    return;

end if;


 -- Calculate view suffix

viewcount := 1;
while(1=1)
loop

  strSuffix := 'ALL'|| viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'TMSCUSTVIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;


-- Create customer/consingee view



 cmdSql := 'create view TMSCUSTVIEW_' || strSuffix || ' as  ' ||
   ' select * from tmscustconsnview  where id in ( ' ||
   'select distinct billto from tmsexportview ' ||
   ' where scac in (select code from tmscarriers) ' ||
 ' and orderdate between  to_date('||in_begdatestr||',''YYYYMMDDHH24MISS'') and ' ||
 'to_date('||in_enddatestr||',''YYYYMMDDHH24MISS'') ' ||
 ' union ' ||
' select distinct consignee from tmsexportview ' ||
   ' where scac in (select code from tmscarriers) ' ||
 ' and orderdate between  to_date('||in_begdatestr||',''YYYYMMDDHH24MISS'') and ' ||
 'to_date('||in_enddatestr||',''YYYYMMDDHH24MISS''))';




curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);




  out_errorno := viewcount;
  out_msg := 'OKAY';
  return;



  exception when others then
   out_msg := sqlerrm;
   return;


end begin_tmscustexport;

-----------------------
-- end tmscustexport --
-----------------------


procedure end_tmscustexport
(in_viewsuffix IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2)
 is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
dteTest date;
begin
strSuffix := 'ALL' || in_viewsuffix;


  cmdSql := 'drop VIEW tmscustview_' || strSuffix;
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);


  out_errorno := 0;
  out_msg := 'OKAY';
  return;

  exception when others then
   out_msg := sqlerrm;
   return;


end end_tmscustexport;


end zimportproctms;
/
exit;
