drop table pklrequest_detail;

create table pklrequest_detail
(pklsessionid       number(7)
,linenumber         number(12)
,pklsequence        number(7)
,pklrecordtype      varchar2(4)
,ORDERID NUMBER(9)
,SHIPID NUMBER(2)
,item varchar2(50)
,CUSTID VARCHAR2(10)
,FROMFACILITY VARCHAR2(3)
,UOM VARCHAR2(4)
,LINESTATUS VARCHAR2(1)
,COMMITSTATUS VARCHAR2(1)
,QTYENTERED NUMBER(7)
,ITEMENTERED VARCHAR2(50)
,UOMENTERED VARCHAR2(4)
,QTYORDER NUMBER(7)
,WEIGHTORDER NUMBER(17,8)
,CUBEORDER NUMBER(10,4)
,AMTORDER NUMBER(10,2)
,QTYCOMMIT NUMBER(7)
,WEIGHTCOMMIT NUMBER(17,8)
,CUBECOMMIT NUMBER(10,4)
,AMTCOMMIT NUMBER(10,2)
,QTYSHIP NUMBER(7)
,WEIGHTSHIP NUMBER(17,8)
,CUBESHIP NUMBER(10,4)
,AMTSHIP NUMBER(10,2)
,QTYTOTCOMMIT NUMBER(7)
,WEIGHTTOTCOMMIT NUMBER(17,8)
,CUBETOTCOMMIT NUMBER(10,4)
,AMTTOTCOMMIT NUMBER(10,2)
,QTYRCVD NUMBER(7)
,WEIGHTRCVD NUMBER(17,8)
,CUBERCVD NUMBER(10,4)
,AMTRCVD NUMBER(10,2)
,QTYRCVDGOOD NUMBER(7)
,WEIGHTRCVDGOOD NUMBER(17,8)
,CUBERCVDGOOD NUMBER(10,4)
,AMTRCVDGOOD NUMBER(10,2)
,QTYRCVDDMGD NUMBER(7)
,WEIGHTRCVDDMGD NUMBER(17,8)
,CUBERCVDDMGD NUMBER(10,4)
,AMTRCVDDMGD NUMBER(10,2)
,COMMENT1 CLOB
,STATUSUSER VARCHAR2(12)
,STATUSUPDATE DATE
,LASTUSER VARCHAR2(12)
,LASTUPDATE DATE
,PRIORITY VARCHAR2(1)
,LOTNUMBER VARCHAR2(30)
,BACKORDER VARCHAR2(2)
,ALLOWSUB VARCHAR2(1)
,QTYTYPE VARCHAR2(1)
,INVSTATUSIND VARCHAR2(1)
,INVSTATUS VARCHAR2(255)
,INVCLASSIND VARCHAR2(1)
,INVENTORYCLASS VARCHAR2(255)
,QTYPICK NUMBER(7)
,WEIGHTPICK NUMBER(17,8)
,CUBEPICK NUMBER(10,4)
,AMTPICK NUMBER(10,2)
,CONSIGNEESKU VARCHAR2(20)
,CHILDORDERID NUMBER(9)
,CHILDSHIPID NUMBER(2)
,STAFFHRS NUMBER(10,4)
,QTY2SORT NUMBER(7)
,WEIGHT2SORT NUMBER(17,8)
,CUBE2SORT NUMBER(10,4)
,AMT2SORT NUMBER(10,2)
,QTY2PACK NUMBER(7)
,WEIGHT2PACK NUMBER(17,8)
,CUBE2PACK NUMBER(10,4)
,AMT2PACK NUMBER(10,2)
,QTY2CHECK NUMBER(7)
,WEIGHT2CHECK NUMBER(17,8)
,CUBE2CHECK NUMBER(10,4)
,AMT2CHECK NUMBER(10,2)
,DTLPASSTHRUCHAR01 VARCHAR2(255)
,DTLPASSTHRUCHAR02 VARCHAR2(255)
,DTLPASSTHRUCHAR03 VARCHAR2(255)
,DTLPASSTHRUCHAR04 VARCHAR2(255)
,DTLPASSTHRUCHAR05 VARCHAR2(255)
,DTLPASSTHRUCHAR06 VARCHAR2(255)
,DTLPASSTHRUCHAR07 VARCHAR2(255)
,DTLPASSTHRUCHAR08 VARCHAR2(255)
,DTLPASSTHRUCHAR09 VARCHAR2(255)
,DTLPASSTHRUCHAR10 VARCHAR2(255)
,DTLPASSTHRUCHAR11 VARCHAR2(255)
,DTLPASSTHRUCHAR12 VARCHAR2(255)
,DTLPASSTHRUCHAR13 VARCHAR2(255)
,DTLPASSTHRUCHAR14 VARCHAR2(255)
,DTLPASSTHRUCHAR15 VARCHAR2(255)
,DTLPASSTHRUCHAR16 VARCHAR2(255)
,DTLPASSTHRUCHAR17 VARCHAR2(255)
,DTLPASSTHRUCHAR18 VARCHAR2(255)
,DTLPASSTHRUCHAR19 VARCHAR2(255)
,DTLPASSTHRUCHAR20 VARCHAR2(255)
,DTLPASSTHRUNUM01 NUMBER(16,4)
,DTLPASSTHRUNUM02 NUMBER(16,4)
,DTLPASSTHRUNUM03 NUMBER(16,4)
,DTLPASSTHRUNUM04 NUMBER(16,4)
,DTLPASSTHRUNUM05 NUMBER(16,4)
,DTLPASSTHRUNUM06 NUMBER(16,4)
,DTLPASSTHRUNUM07 NUMBER(16,4)
,DTLPASSTHRUNUM08 NUMBER(16,4)
,DTLPASSTHRUNUM09 NUMBER(16,4)
,DTLPASSTHRUNUM10 NUMBER(16,4)
,ASNVARIANCE CHAR(1)
,CANCELREASON VARCHAR2(12)
,RFAUTODISPLAY VARCHAR2(1)
,XDOCKORDERID NUMBER(9)
,XDOCKSHIPID NUMBER(2)
,XDOCKLOCID VARCHAR2(10)
,baseuom    varchar2(4)
,baseuomabbrev varchar2(12)
,baseuomshipped number(7)
,uom1       varchar2(4)
,uom1abbrev varchar2(12)
,uom1shipped number(7)
,itemdescr varchar2(255)
,itemalias varchar2(255)
,trackingnos varchar2(255)
,itemqtydescr varchar2(255)
);

create index pklrequest_dtl_sessionid_idx
 on pklrequest_detail(pklsessionid);

create index pklrequest_dtl_lastupdate_idx
 on pklrequest_detail(lastupdate);

create or replace package pkldetailpkg
as type pklrequest_detail_type is ref cursor return pklrequest_detail%rowtype;
end pkldetailpkg;
/
create or replace procedure pkldetailproc
(pklrequest_detail_cursor IN OUT pkldetailpkg.pklrequest_detail_type
,in_pklsessionid number
,in_orderid number
,in_shipid number
,in_debug_yn IN varchar2)
as
--
-- $Id$
--

cursor curOrderdtl is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';
od curOrderdtl%rowtype;

cntRows integer;
wrk pklrequest_detail%rowtype;

cursor curOrderDtlLine(in_orderitem varchar2, in_orderlot varchar2) is
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
ol curOrderDtlLine%rowtype;

cursor curCustItem(in_custid varchar2,in_item varchar2) is
  select descr
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curCustItemAlias(in_custid varchar2,in_item varchar2) is
  select itemalias
    from custitemalias
   where custid = in_custid
     and item = in_item
   order by itemalias;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status in ('P','S','L','SH')
   group by item,
            substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30);
sp curShippingPlate%rowtype;

qtyRemain integer;
qtyLineNumber integer;
prevLineNumber integer;

type trackingnotype is record (
  trackingno shippingplate.trackingno%type
);

type trackingnotbltype is table of trackingnotype
     index by binary_integer;

trackingno_tbl trackingnotbltype;
tx integer;
cntTrackingNo integer;
trackingnofound boolean;

begin

delete from pklrequest_detail
where pklsessionid = in_pklsessionid;
commit;

delete from pklrequest_detail
where lastupdate < trunc(sysdate);
commit;

wrk := null;
wrk.pklsessionid := in_pklsessionid;
wrk.pklsequence := 0;

if in_debug_yn = 'Y' then
  zut.prt('start orderdtl loop');
end if;

for od in curOrderDtl
loop
  if in_debug_yn = 'Y' then
    zut.prt('in orderdtl loop');
  end if;
  sp := null;
  ci := null;
  if in_debug_yn = 'Y' then
    zut.prt('fetch custitem');
  end if;
  open curCustItem(od.custid,od.item);
  fetch curCustItem into ci;
  close curCustItem;
  if in_debug_yn = 'Y' then
    zut.prt('fetch shippingplate');
  end if;
  open curShippingPlate(od.orderid,od.shipid,od.item,od.lotnumber);
  fetch curShippingPlate into sp;
  if in_debug_yn = 'Y' then
    zut.prt('fetch custitemalias');
  end if;
  open curCustItemAlias(od.custid,od.item);
  fetch curCustItemAlias into wrk.itemalias;
  close curCustItemAlias;
  trackingno_tbl.delete;
  prevLineNumber := -1;
  for ol in curOrderDtlLine(od.item,od.lotnumber)
  loop
    if prevLineNumber <> -1 then
      wrk.trackingnos := null;
      for tx in 1..trackingno_tbl.count
      loop
        if wrk.trackingnos is null then
          wrk.trackingNos := 'Tracking Numbers: ';
        elsif (length(wrk.trackingnos) > 55) then
          wrk.pklsequence := wrk.pklsequence + 1;
          insert into pklrequest_detail
          (pklsessionid,linenumber,pklsequence,pklrecordtype,trackingnos,
           item,lotnumber)
          values (wrk.pklsessionid,prevlinenumber,wrk.pklsequence,'TRAK',
            wrk.trackingnos,od.item,od.lotnumber);
          commit;
          wrk.trackingnos := null;
        else
          wrk.trackingNos := wrk.TrackingNos || ', ';
        end if;
        if wrk.trackingnos is null then
          wrk.trackingnos := trackingno_tbl(tx).trackingno;
        else
          wrk.trackingNos := wrk.TrackingNos || trackingno_tbl(tx).trackingno;
        end if;
      end loop;
      if wrk.trackingnos is not null then
        wrk.pklsequence := wrk.pklsequence + 1;
        insert into pklrequest_detail
        (pklsessionid,linenumber,pklsequence,pklrecordtype,trackingnos,
         item,lotnumber)
        values (wrk.pklsessionid,prevlinenumber,wrk.pklsequence,'TRAK',
          wrk.trackingnos,od.item,od.lotnumber);
        commit;
        wrk.trackingnos := null;
      end if;
      trackingno_tbl.delete;
    end if;
    prevLineNumber := ol.linenumber;
    qtyRemain := ol.qty;
    qtyLineNumber := 0;
    while (qtyRemain > 0)
    loop
      if sp.qty = 0 then
        fetch curShippingPlate into sp;
        if curShippingPlate%notfound then
          sp := null;
        end if;
      end if;
      if sp.item is null then
        if qtyLineNumber <> 0 then
          goto insert_detail_row;
        else
          exit;
        end if;
      end if;
      if (trim(sp.trackingno)) is not null then
        trackingnofound := False;
        for tx in 1..trackingno_tbl.count
        loop
          if sp.trackingno = trackingno_tbl(tx).trackingno then
            trackingnofound := True;
            exit;
          end if;
        end loop;
        if trackingnofound = False then
          tx := trackingno_tbl.count + 1;
          trackingno_tbl(tx).trackingno := sp.trackingno;
        end if;
      end if;
      if sp.qty >= qtyRemain then
        qtyLineNumber := qtyLineNumber + qtyRemain;
        qtyRemain := 0;
        sp.qty := sp.qty - qtyRemain;
      else
        qtyLineNumber := qtyLineNumber + sp.qty;
        qtyRemain := qtyRemain - sp.qty;
        sp.qty := 0;
      end if;
      if qtyRemain > 0 then
        goto continue_shippingplate_loop;
      end if;
<< insert_detail_row >>
      wrk.pklsequence := wrk.pklsequence + 1;
      if wrk.pklsequence > 10000 then
        exit;
      end if;
      wrk.baseuom := od.uom;
      wrk.baseuomabbrev := substr(zit.uom_abbrev(wrk.baseuom),1,12);
      wrk.baseuomshipped := qtyLineNumber;
      wrk.uom1 := substr(zcu.next_uom(od.custid,sp.item,wrk.baseuom,1),1,4);
      wrk.uom1abbrev := substr(zit.uom_abbrev(wrk.uom1),1,12);
      if (wrk.baseuom is not null) and
         (wrk.uom1 is not null) then
        wrk.uom1shipped :=
          zcu.equiv_uom_qty(od.custid,sp.item,wrk.baseuom,
               qtyLineNumber,wrk.uom1);
      end if;
      zci.item_qty_descr(od.custid,od.item,wrk.baseuom,wrk.baseuomshipped,
        wrk.itemqtydescr);
      insert into pklrequest_detail
values (wrk.pklsessionid,ol.linenumber,wrk.pklsequence,'LINE',
od.ORDERID,od.SHIPID,od.ITEM,od.CUSTID,od.FROMFACILITY,od.UOM,od.LINESTATUS,
od.COMMITSTATUS,od.QTYENTERED,od.ITEMENTERED,od.UOMENTERED,od.QTYORDER,od.WEIGHTORDER,
od.CUBEORDER,od.AMTORDER,od.QTYCOMMIT,od.WEIGHTCOMMIT,od.CUBECOMMIT,od.AMTCOMMIT,
od.QTYSHIP,od.WEIGHTSHIP,od.CUBESHIP,od.AMTSHIP,od.QTYTOTCOMMIT,od.WEIGHTTOTCOMMIT,
od.CUBETOTCOMMIT,od.AMTTOTCOMMIT,od.QTYRCVD,od.WEIGHTRCVD,od.CUBERCVD,od.AMTRCVD,
od.QTYRCVDGOOD,od.WEIGHTRCVDGOOD,od.CUBERCVDGOOD,od.AMTRCVDGOOD,od.QTYRCVDDMGD,
od.WEIGHTRCVDDMGD,od.CUBERCVDDMGD,od.AMTRCVDDMGD,od.COMMENT1,od.STATUSUSER,
od.STATUSUPDATE,od.LASTUSER,od.LASTUPDATE,od.PRIORITY,od.LOTNUMBER,od.BACKORDER,
od.ALLOWSUB,od.QTYTYPE,od.INVSTATUSIND,od.INVSTATUS,od.INVCLASSIND,od.INVENTORYCLASS,
od.QTYPICK,od.WEIGHTPICK,od.CUBEPICK,od.AMTPICK,od.CONSIGNEESKU,od.CHILDORDERID,
od.CHILDSHIPID,od.STAFFHRS,od.QTY2SORT,od.WEIGHT2SORT,od.CUBE2SORT,od.AMT2SORT,
od.QTY2PACK,od.WEIGHT2PACK,od.CUBE2PACK,od.AMT2PACK,od.QTY2CHECK,od.WEIGHT2CHECK,
od.CUBE2CHECK,od.AMT2CHECK,od.DTLPASSTHRUCHAR01,od.DTLPASSTHRUCHAR02,od.DTLPASSTHRUCHAR03,
od.DTLPASSTHRUCHAR04,od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,od.DTLPASSTHRUCHAR07,
od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,od.DTLPASSTHRUCHAR10,od.DTLPASSTHRUCHAR11,
od.DTLPASSTHRUCHAR12,od.DTLPASSTHRUCHAR13,od.DTLPASSTHRUCHAR14,od.DTLPASSTHRUCHAR15,
od.DTLPASSTHRUCHAR16,od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,od.DTLPASSTHRUCHAR19,
od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,od.DTLPASSTHRUNUM03,
od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,od.DTLPASSTHRUNUM07,
od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,od.ASNVARIANCE,
od.CANCELREASON,od.RFAUTODISPLAY,od.XDOCKORDERID,od.XDOCKSHIPID,od.XDOCKLOCID,
wrk.baseuom,wrk.baseuomabbrev,wrk.baseuomshipped,wrk.uom1,wrk.uom1abbrev,wrk.uom1shipped,
ci.descr,wrk.itemalias,null,wrk.itemqtydescr);
      commit;
      if sp.item is null then
        exit;
      end if;
<< continue_shippingplate_loop >>
      null;
    end loop; -- shippingplate
  end loop; -- orderdtlline
  close curShippingPlate;
  if prevLineNumber <> -1 then
    wrk.trackingnos := null;
    for tx in 1..trackingno_tbl.count
    loop
      if wrk.trackingnos is null then
        wrk.trackingNos := 'Tracking Numbers: ';
      elsif (length(wrk.trackingnos) > 55) then
        wrk.pklsequence := wrk.pklsequence + 1;
        insert into pklrequest_detail
        (pklsessionid,linenumber,pklsequence,pklrecordtype,trackingnos)
        values (wrk.pklsessionid,prevlinenumber,wrk.pklsequence,'TRAK',
          wrk.trackingnos);
        commit;
        wrk.trackingnos := null;
      else
        wrk.trackingNos := wrk.TrackingNos || ', ';
      end if;
      if wrk.trackingnos is null then
        wrk.trackingnos := trackingno_tbl(tx).trackingno;
      else
        wrk.trackingNos := wrk.TrackingNos || trackingno_tbl(tx).trackingno;
      end if;
    end loop;
    if wrk.trackingnos is not null then
      wrk.pklsequence := wrk.pklsequence + 1;
      insert into pklrequest_detail
      (pklsessionid,linenumber,pklsequence,pklrecordtype,trackingnos,
       item,lotnumber)
      values (wrk.pklsessionid,prevlinenumber,wrk.pklsequence,'TRAK',
        wrk.trackingnos,od.item,od.lotnumber);
      commit;
      wrk.trackingnos := null;
    end if;
  end if;
end loop; -- orderdtl

<<return_pkls_rows>>

commit;

open pklrequest_detail_cursor for
 select *
   from pklrequest_detail
  where pklsessionid = in_pklsessionid
  order by linenumber,pklsequence;

end pkldetailproc;
/
show errors package pkldetailpkg;
show errors procedure pkldetailproc;
exit;
