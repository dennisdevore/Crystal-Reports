drop table zbrugreenlabelrpt;

create table zbrugreenlabelrpt (
   sessionid        number,
   orderid          number(9),
   shipid           number(2),
   seq              number(7),
   blanketpo1       varchar2(255),
   blanketpo2       varchar2(255),
   blanketpo3       varchar2(255),
   blanketpo4       varchar2(255),
   storenumber1     varchar2(255),
   storenumber2     varchar2(255),
   storenumber3     varchar2(255),
   storenumber4     varchar2(255),
   customername1    varchar2(255),
   customername2    varchar2(255),
   customername3    varchar2(255),
   customername4    varchar2(255),
   skn1             varchar2(255),
   skn2             varchar2(255),
   skn3             varchar2(255),
   skn4             varchar2(255),
   po1              varchar2(255),
   po2              varchar2(255),
   po3              varchar2(255),
   po4              varchar2(255),
   lastupdate       date
);


create index zbrugreenrpt_sessionid_idx
   on zbrugreenlabelrpt(sessionid);

create index zbrugreenrpt_lastupdate_idx
   on zbrugreenlabelrpt(lastupdate);


create or replace package zbrugreenlabelrptpkg
   as type rsr_type is ref cursor return zbrugreenlabelrpt%rowtype;
end zbrugreenlabelrptpkg;
/


create or replace procedure zbrugreenlabelrptproc
   (rsr_cursor in out zbrugreenlabelrptpkg.rsr_type,
    in_orderid in number,
    in_shipid in number,
    in_item in varchar2)
is
--
-- $Id: zbrugreenlabelrptobjects.sql 284 2005-10-28 17:35:10Z ed $
--
   l_sessionid number;
   l_lastupdate date := trunc(sysdate);

   l_lbl_cnt pls_integer;
   l_cnt pls_integer;
   l_seq pls_integer;

   len integer;
   tpos integer;
   tcur integer;
   tcnt integer;

   cmdSql varchar2(2000);
   TYPE cur_typ is REF CURSOR;
   cr cur_typ;
   OD orderdtl%rowtype;

   type lbldata is record(
      orderid zbrugreenlabelrpt.orderid%type,
      shipid zbrugreenlabelrpt.shipid%type,
      blanketpo1 zbrugreenlabelrpt.blanketpo1%type,
      blanketpo2 zbrugreenlabelrpt.blanketpo2%type,
      blanketpo3 zbrugreenlabelrpt.blanketpo3%type,
      blanketpo4 zbrugreenlabelrpt.blanketpo4%type,
      storenumber1 zbrugreenlabelrpt.storenumber1%type,
      storenumber2 zbrugreenlabelrpt.storenumber2%type,
      storenumber3 zbrugreenlabelrpt.storenumber3%type,
      storenumber4 zbrugreenlabelrpt.storenumber4%type,
      customername1 zbrugreenlabelrpt.customername1%type,
      customername2 zbrugreenlabelrpt.customername2%type,
      customername3 zbrugreenlabelrpt.customername3%type,
      customername4 zbrugreenlabelrpt.customername4%type,
      skn1 zbrugreenlabelrpt.skn1%type,
      skn2 zbrugreenlabelrpt.skn2%type,
      skn3 zbrugreenlabelrpt.skn3%type,
      skn4 zbrugreenlabelrpt.skn4%type,
      poID1 zbrugreenlabelrpt.po1%type,
      poID2 zbrugreenlabelrpt.po2%type,
      poID3 zbrugreenlabelrpt.po3%type,
      poID4 zbrugreenlabelrpt.po4%type);
   l_data lbldata;

   cursor c_oh(p_orderid number, p_shipid number) is
      select orderid, shipid, custid, ordertype, oh.shiptype, shipdate, po,
             reference, loadno, stopno, oh.shipno, oh.shipto, prono,
             billoflading, carrier, fromfacility,
             hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03,
             hdrpassthruchar04, hdrpassthruchar05, hdrpassthruchar06,
             hdrpassthruchar07, hdrpassthruchar08,
             hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11,
             hdrpassthruchar12, hdrpassthruchar13, hdrpassthruchar14,
             hdrpassthruchar15, hdrpassthruchar16, hdrpassthruchar17,
             hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
             hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03,
             hdrpassthrunum04, hdrpassthrunum05, hdrpassthrunum06,
             hdrpassthrunum07, hdrpassthrunum08, hdrpassthrunum09,
             hdrpassthrunum10, hdrpassthrudate01, hdrpassthrudate02,
             hdrpassthrudate03, hdrpassthrudate04, hdrpassthrudoll01,
             hdrpassthrudoll02,
             decode(cn.consignee,null,oh.shiptoname, cn.name) as shiptoname
         from orderhdr oh, consignee cn
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid
           and oh.shipto = cn.consignee(+);
OH c_oh%rowtype;

procedure insert_label
(in_oh c_oh%rowtype,
 io_seq in out integer)
is
begin
   io_seq := io_seq + 1;
   insert into zbrugreenlabelrpt
      (sessionid,
       orderid,
       shipid,
       seq,
       blanketpo1,
       blanketpo2,
       blanketpo3,
       blanketpo4,
       storenumber1,
       storenumber2,
       storenumber3,
       storenumber4,
       customername1,
       customername2,
       customername3,
       customername4,
       skn1,
       skn2,
       skn3,
       skn4,
       po1,
       po2,
       po3,
       po4,
       lastupdate)
   values
      (l_sessionid,
       l_data.orderid,
       l_data.shipid,
       io_seq,
       l_data.blanketpo1,
       l_data.blanketpo2,
       l_data.blanketpo3,
       l_data.blanketpo4,
       l_data.storenumber1,
       l_data.storenumber2,
       l_data.storenumber3,
       l_data.storenumber4,
       l_data.customername1,
       l_data.customername2,
       l_data.customername3,
       l_data.customername4,
       l_data.skn1,
       l_data.skn2,
       l_data.skn3,
       l_data.skn4,
       l_data.poID1,
       l_data.poID2,
       l_data.poID3,
       l_data.poID4,
       l_lastupdate);

end insert_label;

procedure add_label
(in_oh in c_oh%rowtype,
 in_item1 in varchar2,
 in_item2 in varchar2,
 in_item3 in varchar2,
 io_cnt in out integer,
 io_seq in out integer)
is
begin
   l_data.orderid := in_oh.orderid;
   l_data.shipid := in_oh.shipid;
   l_data.blanketpo1 := in_oh.po;
   l_data.blanketpo2 := in_oh.po;
   l_data.blanketpo3 := in_oh.po;
   l_data.blanketpo4 := in_oh.po;
   l_data.storenumber1 := in_oh.hdrpassthruchar01;
   l_data.storenumber2 := in_oh.hdrpassthruchar01;
   l_data.storenumber3 := in_oh.hdrpassthruchar01;
   l_data.storenumber4 := in_oh.hdrpassthruchar01;
   l_data.customername1 := in_oh.hdrpassthruchar14;
   l_data.customername2 := in_oh.hdrpassthruchar14;
   l_data.customername3 := in_oh.hdrpassthruchar14;
   l_data.customername4 := in_oh.hdrpassthruchar14;
   l_data.skn1 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
   l_data.skn2 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
   l_data.skn3 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
   l_data.skn4 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
   l_data.poID1 := in_oh.hdrpassthruchar18;
   l_data.poID2 := in_oh.hdrpassthruchar18;
   l_data.poID3 := in_oh.hdrpassthruchar18;
   l_data.poID4 := in_oh.hdrpassthruchar18;
   insert_label(in_oh, io_seq);
/*
   io_cnt := io_cnt + 1;
   if io_cnt = 1 then
      l_data.orderid := in_oh.orderid;
      l_data.shipid := in_oh.shipid;
      l_data.blanketpo1 := in_oh.po;
      l_data.blanketpo2 := null;
      l_data.storenumber1 := in_oh.hdrpassthruchar01;
      l_data.storenumber2 := null;
      l_data.customername1 := in_oh.shiptoname;
      l_data.customername2 := null;
      l_data.skn1 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
      l_data.skn2 := null;
      l_data.poID1 := in_oh.hdrpassthruchar19;
      l_data.poID2 := null;

   end if;
   if io_cnt = 2 then
      l_data.blanketpo2 := in_oh.po;
      l_data.storenumber2 := in_oh.hdrpassthruchar01;
      l_data.customername2 := in_oh.shiptoname;
      l_data.skn2 := rtrim(in_item1) || ' ' || rtrim(in_item2) || ' ' || rtrim(in_item3);
      l_data.poID2 := in_oh.hdrpassthruchar19;
      insert_label(in_oh, io_seq);
      io_cnt := 0;
   end if;
*/
end add_label;
begin

   select sys_context('USERENV','SESSIONID')
      into l_sessionid
      from dual;

   delete from zbrugreenlabelrpt
      where sessionid = l_sessionid;
   commit;

   delete from zbrugreenlabelrpt
      where lastupdate < l_lastupdate;
   commit;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into OH;
   close c_oh;

   l_cnt := 0;
   l_seq := 0;

   cmdSql := 'select * from orderdtl ' ||
             ' where orderid = ' || in_orderid ||
               ' and shipid = '|| in_shipid ||
               '  and linestatus != ''X''';
   if upper(nvl(in_item,'ALL')) != 'ALL' then
      cmdSql := cmdSql || ' and item in (''';
      tcur := 1;
      l_seq := 1;
      tpos := instr(in_Item, ',', 1, l_seq);
      if tpos = 0 then
         cmdSql := cmdSql || in_item || ''')';
      else
         cmdSql := cmdSql || substr(in_item, tcur, tpos - tcur) || '''';
         tcur := tpos + 1;
         l_seq := l_seq + 1;

         while instr(in_Item, ',', 1, l_seq) != 0 loop
            tpos := instr(in_Item, ',', 1, l_seq);
            cmdSql := cmdSql || ',''' || substr(in_item, tcur, tpos - tcur) || '''';
            tcur := tpos + 1;
            l_seq := l_seq + 1;
         end loop;
         cmdSql := cmdSql || ',''' || substr(in_item, tcur) || ''')';
      end if;
   end if;

   open cr for cmdsql;
   loop
      fetch cr into OD;
      exit when cr%notfound;
      l_lbl_cnt := zlbl.uom_qty_conv(OH.custid, od.item, od.qtyorder, od.uom, 'CTN');

      for i in 1..l_lbl_cnt loop
         add_label(OH, od.dtlpassthruchar02, OD.item, OD.dtlpassthruchar03, l_cnt, l_seq);
      end loop;
   end loop;
   close cr;
--   if l_cnt = 1 then
--      insert_label(OH, l_seq);
--   end if;


   commit;

   open rsr_cursor for
      select *
         from zbrugreenlabelrpt
         where sessionid = l_sessionid
         order by seq;

end zbrugreenlabelrptproc;
/

show errors package zbrugreenlabelrptpkg;
show errors procedure zbrugreenlabelrptproc;
exit;
