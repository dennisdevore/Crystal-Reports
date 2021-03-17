CREATE OR REPLACE package body zucclabels as
--
-- $Id: zuccbody.sql 815 2007-04-20 15:43:49Z ed $
--


-- Types


type auxdata is record(
   lpid ucc_standard_labels.lpid%type,
   picktolp ucc_standard_labels.picktolp%type,
   item ucc_standard_labels.item%type,
   quantity ucc_standard_labels.quantity%type,
   weight ucc_standard_labels.weight%type,
   seq ucc_standard_labels.seq%type,
   seqof ucc_standard_labels.seqof%type,
   lotnumber ucc_standard_labels.lotnumber%type,
   shippingtype ucc_standard_labels.shippingtype%type,
   fromfacility ucc_standard_labels.fromfacility%type,
   fromaddr1 ucc_standard_labels.fromaddr1%type,
   fromaddr2 ucc_standard_labels.fromaddr2%type,
   fromcity ucc_standard_labels.fromcity%type,
   fromstate ucc_standard_labels.fromstate%type,
   fromzip ucc_standard_labels.fromzip%type,
   shipfromcountrycode ucc_standard_labels.shipfromcountrycode%type,
   bol ucc_standard_labels.bol%type,
   carriername ucc_standard_labels.carriername%type,
   scac ucc_standard_labels.scac%type,
   sscctype varchar2(2),
   changeproc caselabels.changeproc%type,
   consignee_name consignee.name%type,
   consignee_contact consignee.contact%type,
   consignee_addr1 consignee.addr1%type,
   consignee_addr2 consignee.addr2%type,
   consignee_city consignee.city%type,
   consignee_state consignee.state%type,
   consignee_postalcode consignee.postalcode%type,
   consignee_countrycode consignee.countrycode%type,
   shipto orderhdr.shipto%type,
   color ucc_standard_labels.color%type,
   customeritem ucc_standard_labels.customeritem%type,
   department ucc_standard_labels.department%type,
   division ucc_standard_labels.division%type,
   itemsize ucc_standard_labels.itemsize%type,
   makrforstate ucc_standard_labels.makrforstate%type,
   markforaddr1 ucc_standard_labels.markforaddr1%type,
   markforaddr2 ucc_standard_labels.markforaddr2%type,
   markforcity ucc_standard_labels.markforcity%type,
   markforcountrycode ucc_standard_labels.markforcountrycode%type,
   markforname ucc_standard_labels.markforname%type,
   markforstate ucc_standard_labels.markforstate%type,
   markforzip ucc_standard_labels.markforzip%type,
   pptype shippingplate.type%type,
   storebarcode ucc_standard_labels.storebarcode%type,
   storehuman ucc_standard_labels.storehuman%type,
   storenum ucc_standard_labels.storenum%type,
   style ucc_standard_labels.style%type,
   vendorbar ucc_standard_labels.vendorbar%type,
   vendorhuman ucc_standard_labels.vendorhuman%type,
   vendoritem ucc_standard_labels.vendoritem%type);

type dtlpassthru is record(
   dtlpassthruchar01 orderdtl.dtlpassthruchar01%type,
   dtlpassthruchar02 orderdtl.dtlpassthruchar02%type,
   dtlpassthruchar03 orderdtl.dtlpassthruchar03%type,
   dtlpassthruchar04 orderdtl.dtlpassthruchar04%type,
   dtlpassthruchar05 orderdtl.dtlpassthruchar05%type,
   dtlpassthruchar06 orderdtl.dtlpassthruchar06%type,
   dtlpassthruchar07 orderdtl.dtlpassthruchar07%type,
   dtlpassthruchar08 orderdtl.dtlpassthruchar08%type,
   dtlpassthruchar09 orderdtl.dtlpassthruchar09%type,
   dtlpassthruchar10 orderdtl.dtlpassthruchar10%type,
   dtlpassthruchar11 orderdtl.dtlpassthruchar11%type,
   dtlpassthruchar12 orderdtl.dtlpassthruchar12%type,
   dtlpassthruchar13 orderdtl.dtlpassthruchar13%type,
   dtlpassthruchar14 orderdtl.dtlpassthruchar14%type,
   dtlpassthruchar15 orderdtl.dtlpassthruchar15%type,
   dtlpassthruchar16 orderdtl.dtlpassthruchar16%type,
   dtlpassthruchar17 orderdtl.dtlpassthruchar17%type,
   dtlpassthruchar18 orderdtl.dtlpassthruchar18%type,
   dtlpassthruchar19 orderdtl.dtlpassthruchar19%type,
   dtlpassthruchar20 orderdtl.dtlpassthruchar20%type,
   dtlpassthruchar21 orderdtl.dtlpassthruchar21%type,
   dtlpassthruchar22 orderdtl.dtlpassthruchar22%type,
   dtlpassthruchar23 orderdtl.dtlpassthruchar23%type,
   dtlpassthruchar24 orderdtl.dtlpassthruchar24%type,
   dtlpassthruchar25 orderdtl.dtlpassthruchar25%type,
   dtlpassthruchar26 orderdtl.dtlpassthruchar26%type,
   dtlpassthruchar27 orderdtl.dtlpassthruchar27%type,
   dtlpassthruchar28 orderdtl.dtlpassthruchar28%type,
   dtlpassthruchar29 orderdtl.dtlpassthruchar29%type,
   dtlpassthruchar30 orderdtl.dtlpassthruchar30%type,
   dtlpassthruchar31 orderdtl.dtlpassthruchar31%type,
   dtlpassthruchar32 orderdtl.dtlpassthruchar32%type,
   dtlpassthruchar33 orderdtl.dtlpassthruchar33%type,
   dtlpassthruchar34 orderdtl.dtlpassthruchar34%type,
   dtlpassthruchar35 orderdtl.dtlpassthruchar35%type,
   dtlpassthruchar36 orderdtl.dtlpassthruchar36%type,
   dtlpassthruchar37 orderdtl.dtlpassthruchar37%type,
   dtlpassthruchar38 orderdtl.dtlpassthruchar38%type,
   dtlpassthruchar39 orderdtl.dtlpassthruchar39%type,
   dtlpassthruchar40 orderdtl.dtlpassthruchar40%type,
   dtlpassthrunum01 orderdtl.dtlpassthrunum01%type,
   dtlpassthrunum02 orderdtl.dtlpassthrunum02%type,
   dtlpassthrunum03 orderdtl.dtlpassthrunum03%type,
   dtlpassthrunum04 orderdtl.dtlpassthrunum04%type,
   dtlpassthrunum05 orderdtl.dtlpassthrunum05%type,
   dtlpassthrunum06 orderdtl.dtlpassthrunum06%type,
   dtlpassthrunum07 orderdtl.dtlpassthrunum07%type,
   dtlpassthrunum08 orderdtl.dtlpassthrunum08%type,
   dtlpassthrunum09 orderdtl.dtlpassthrunum09%type,
   dtlpassthrunum10 orderdtl.dtlpassthrunum10%type,
   dtlpassthrunum11 orderdtl.dtlpassthrunum01%type,
   dtlpassthrunum12 orderdtl.dtlpassthrunum02%type,
   dtlpassthrunum13 orderdtl.dtlpassthrunum03%type,
   dtlpassthrunum14 orderdtl.dtlpassthrunum04%type,
   dtlpassthrunum15 orderdtl.dtlpassthrunum05%type,
   dtlpassthrunum16 orderdtl.dtlpassthrunum06%type,
   dtlpassthrunum17 orderdtl.dtlpassthrunum07%type,
   dtlpassthrunum18 orderdtl.dtlpassthrunum08%type,
   dtlpassthrunum19 orderdtl.dtlpassthrunum09%type,
   dtlpassthrunum20 orderdtl.dtlpassthrunum10%type,
   dtlpassthrudate01 orderdtl.dtlpassthrudate01%type,
   dtlpassthrudate02 orderdtl.dtlpassthrudate02%type,
   dtlpassthrudate03 orderdtl.dtlpassthrudate03%type,
   dtlpassthrudate04 orderdtl.dtlpassthrudate04%type,
   dtlpassthrudoll01 orderdtl.dtlpassthrudoll01%type,
   dtlpassthrudoll02 orderdtl.dtlpassthrudoll02%type,
   consigneesku orderdtl.consigneesku%type,
   upc custitemalias.itemalias%type);

type key_table is record (
   fieldname user_tab_columns.column_name%type,
   fieldvalue orderhdr.hdrpassthruchar01%type );

type key_val is table of key_table index by pls_integer;
key_values key_val;

hardcoded_manucc varchar2(10) := null;
l_cartonsuom varchar2(3) := 'CTN';
globalConsorderid number(9);

type contents_rectype is record (
   dptchar01 ucc_standard_labels.dptchar01_01%type,
   dptchar02 ucc_standard_labels.dptchar02_01%type,
   dptchar03 ucc_standard_labels.dptchar03_01%type,
   itemqty ucc_standard_labels.itemqty_01%type);
type contents_tbltype is table of contents_rectype index by binary_integer;
cntnts contents_tbltype;
cntntsx integer;

type ordrectype is record (
   orderid orderhdr.orderid%type,
   shipid orderhdr.shipid%type,
   picked boolean,
   usebatch boolean);
type ordtbltype is table of ordrectype index by binary_integer;
ord_tbl ordtbltype;

-- Private


function duplicate_cnt
   (in_oh in orderhdr%rowtype)
return number
is
begin
-- 2 copies for kmart and walgreens non small package orders
   if (nvl(in_oh.hdrpassthruchar05, '(none)') in ('141627', '10485'))
   and (in_oh.shiptype != 'S') then
      return 2;
   end if;

   return 1;
end duplicate_cnt;


procedure load_key_values is

begin

-- Load the vaules for the field and value for each 'shipto' customer.
   key_values(1).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(1).fieldvalue := '0097642';  -- Walmart
   key_values(2).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(2).fieldvalue := '0088990';  -- Target
   key_values(3).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(3).fieldvalue := '0005000';  -- Shopko
   key_values(4).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(4).fieldvalue := '0023684';  -- Burlington Coat Factory
   key_values(5).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(5).fieldvalue := '0077891';  -- Sears and SLS
   key_values(6).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(6).fieldvalue := '5084033';  -- KMART
   key_values(7).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(7).fieldvalue := null;  -- Stage Stores
   key_values(8).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(8).fieldvalue := '78407';  -- Macys
   key_values(9).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(9).fieldvalue := '78407';  -- Ross
   key_values(10).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(10).fieldvalue := '0019265'; -- Boscovs
   key_values(11).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(11).fieldvalue := '0005895'; -- Kohls
   key_values(12).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(12).fieldvalue := '0020008'; -- AAFES
   key_values(13).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(13).fieldvalue := '0030000'; -- Mervyns
   key_values(14).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(14).fieldvalue := '0040000'; -- Bed Bath and Beyond
   key_values(15).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(15).fieldvalue := '0010000'; -- J.C. Penney
   key_values(16).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(16).fieldvalue := null; -- Cato
   key_values(17).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(17).fieldvalue := null; -- Value City
   key_values(18).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(18).fieldvalue := null; -- Bonton and Saks
   key_values(19).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(19).fieldvalue := null; -- Belk
   key_values(20).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(20).fieldvalue := '0071994'; -- Pamida
   key_values(21).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(21).fieldvalue := null; -- Stien Mart
   key_values(22).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(22).fieldvalue := null;  -- Stage Stores
   key_values(23).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(23).fieldvalue := null;  -- Nieman Marcus
   key_values(24).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(24).fieldvalue := null; --  Alloy
   key_values(25).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(25).fieldvalue := '0006076'; -- Amazon.com
   key_values(26).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(26).fieldvalue := null; -- Anthropologie Direct
   key_values(27).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(27).fieldvalue := null;  -- Charming Shops
   key_values(28).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(28).fieldvalue := null; -- Citi Trends
   key_values(29).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(29).fieldvalue := null; -- Filines Basement
   key_values(30).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(30).fieldvalue := null;  -- Bob's Stores
   key_values(31).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(31).fieldvalue := null;  -- Forever21
   key_values(32).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(32).fieldvalue := null; -- Glicks
   key_values(33).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(33).fieldvalue := null; -- Gordmans
   key_values(34).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(34).fieldvalue := null; -- International Mail
   key_values(35).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(35).fieldvalue := null; -- Maurices
   key_values(36).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(36).fieldvalue := null; -- Number 7
   key_values(37).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(37).fieldvalue := '0005422'; -- Gabrial Brothers
   key_values(38).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(38).fieldvalue := '7807329';  -- Rainbow
   key_values(39).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(39).fieldvalue := null; -- Hamricks
   key_values(40).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(40).fieldvalue := null; -- Olympia
   key_values(41).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(41).fieldvalue := null; -- Dunhams
   key_values(42).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(42).fieldvalue := null; -- Gottshalks
   key_values(43).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(43).fieldvalue := null; -- Modells
   key_values(44).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(44).fieldvalue := null; -- Nordstorms
   key_values(45).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(45).fieldvalue := null; -- Lane Bryant
   key_values(46).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(46).fieldvalue := null; -- Dawahares
   key_values(47).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(47).fieldvalue := '0005521'; -- Winners
   key_values(48).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(48).fieldvalue := '0051365'; -- Kaybee
   key_values(49).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(49).fieldvalue := '4183943'; -- Froman Mills
   key_values(50).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(50).fieldvalue := '0077284'; -- Fred Miller
   key_values(51).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(51).fieldvalue := null; -- Rue 21
   key_values(52).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(52).fieldvalue := '0060202'; -- TJ Maxx
   key_values(53).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(53).fieldvalue := '0060202'; -- Marshalls
   key_values(54).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(54).fieldvalue := '0096282'; -- Toys R Us
   key_values(55).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(55).fieldvalue := '9174217'; -- Toys R Us Canada
   key_values(56).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(56).fieldvalue := null; -- Von Maur
   key_values(57).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(57).fieldvalue := '0701425'; -- Bealls
   key_values(58).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(58).fieldvalue := '2381611'; -- Buy Buy Baby
   key_values(59).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(59).fieldvalue := 'LABELPRINT'; -- generic
   key_values(60).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(60).fieldvalue := 'LWAMZ.GEN'; -- amazon
   key_values(61).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(61).fieldvalue := 'LWKMART'; -- lifeworks kmart/sears
   key_values(62).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(62).fieldvalue := 'LWAAFES'; -- lifeworks aafes
   key_values(63).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(63).fieldvalue := 'LWFNGHT'; -- lifeworks aafes
   key_values(64).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(64).fieldvalue := 'LWDT2ST'; -- lifeworks sears
   key_values(65).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(65).fieldvalue := '039019'; -- sgfootware bbb
   key_values(66).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(66).fieldvalue := '003436'; -- sgfootware harmon
   key_values(67).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(67).fieldvalue := '000014'; -- sgfootware jockey
   key_values(68).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(68).fieldvalue := '33642'; -- sgfootware bonton
   key_values(69).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(69).fieldvalue := '7013'; -- sgfootware boscovs
   key_values(70).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(70).fieldvalue := '7132'; -- sgfootware k and g
   key_values(71).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(71).fieldvalue := 'LWOFFDEP'; -- lifeworks office depot
   key_values(72).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(72).fieldvalue := 'LWBSTBY'; -- lifeworks bestbuy
   key_values(73).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(73).fieldvalue := '66133'; -- SG Footware Belk
   key_values(74).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(74).fieldvalue := 'LWSTPL'; -- lifeworks staples
   key_values(75).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(75).fieldvalue := '214428'; -- basspro
   key_values(76).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(76).fieldvalue := 'LWMST.GEN'; -- lifeworks pack
   key_values(77).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(77).fieldvalue := '0005086'; -- blustem
   key_values(78).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(78).fieldvalue := 'LWMICR'; -- micro
   key_values(79).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(79).fieldvalue := 'LWBBBD2S'; -- lwbuybuybaby
   key_values(80).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(80).fieldvalue := '0097645';  -- Walmartcom
   key_values(81).fieldname := 'HDRPASSTHRUCHAR13';
   key_values(81).fieldvalue := '0040002';  -- lazybonezz

return;
end load_key_values;


function find_key_value_idx (value varchar2) return number
is
   i pls_integer;
begin
   -- find the value in the key_values data to get the index.
   for i in 1..key_values.last loop
      if( nvl(key_values(i).fieldvalue,'x') = nvl(value,'x')) then
         return i;
      end if;
   end loop;
   return 0;
end find_key_value_idx;


function adjust_column
   (in_column  in varchar2,
    in_value   in varchar2,
    in_aux     in auxdata,
    in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru)
return varchar2
is
   l_customer varchar2(255);
begin
   l_customer := lower(substr(in_aux.changeproc, instr(in_aux.changeproc, '.')+1));

   if in_column = 'bol' then
      if l_customer in ('amazongen', 'burlingtoncoat', 'mervyns') then
         return in_oh.orderid||'-'||in_oh.shipid;
      elsif l_customer in ('bbbsgfoo','jockeysgfoo','boscovssgfoo', 'bontonsgfoo', 'kgsgfoo') then
         return null;
      end if;
      return in_value;
   end if;

   if in_column = 'color' then
      if l_customer in ('burlingtoncoat', 'mervyns', 'shopko', 'targetstores','lwbestbuy') then
         return in_od.dtlpassthruchar03;
      elsif l_customer in ('bontonsgfoo','boscovssgfoo','kgsgfoo') then
         return in_od.dtlpassthruchar08;
      end if;
      return in_od.dtlpassthruchar04;
   end if;

   if in_column = 'customeritem' then
      if l_customer in ('buybuybaby', 'lazybonezz', 'kaybee', 'toysrus','lwbestbuy','bluestem') then
         return in_od.dtlpassthruchar02;
      end if;
      return in_od.dtlpassthruchar01;
   end if;

   if in_column = 'department' then
      if l_customer in ('boscovs', 'bedbathandbeyond', 'buybuybaby', 'lazybonezz', 'kaybee', 'toysrus',
            'kmart', 'searsroebuck') then
         return in_oh.hdrpassthruchar09;
      elsif l_customer in ('bontonsgfoo','boscovssgfoo','kgsgfoo') then
         return in_oh.hdrpassthruchar10;
      end if;
      return in_oh.hdrpassthruchar08;
   end if;

   if in_column = 'division' then
      if l_customer in ('jcpenney') then
         return in_oh.hdrpassthruchar09;
      end if;
      return in_oh.hdrpassthruchar10;
   end if;

   if in_column = 'itemsize' then
      if l_customer in ('bedbathandbeyond') then
         return in_od.dtlpassthruchar01;
      end if;
      return in_od.dtlpassthruchar03;
   end if;

   if in_column = 'makrforstate' then
      if l_customer in ('jcpenney') then
         return in_oh.hdrpassthruchar05;
      end if;
      return in_oh.hdrpassthruchar06;
   end if;

   if in_column = 'markforaddr1' then
      if l_customer in ('burlingtoncoat', 'jcpenney') then
         return in_oh.hdrpassthruchar02;
      end if;
      return in_oh.hdrpassthruchar03;
   end if;

   if in_column = 'markforaddr2' then
      if l_customer in ('jcpenney') then
         return in_oh.hdrpassthruchar03;
      end if;
      return in_oh.hdrpassthruchar04;
   end if;

   if in_column = 'markforcity' then
      if l_customer in ('burlingtoncoat', 'jcpenney') then
         return in_oh.hdrpassthruchar04;
      end if;
      return in_oh.hdrpassthruchar05;
   end if;

   if in_column = 'markforcountrycode' then
      if l_customer in ('jcpenney') then
         return in_oh.hdrpassthruchar07;
      end if;
      return in_oh.hdrpassthruchar08;
   end if;

   if in_column = 'markforname' then
      if l_customer in ('burlingtoncoat') then
         return in_oh.hdrpassthruchar16;
      end if;
      return in_oh.hdrpassthruchar01;
   end if;

   if in_column = 'markforstate' then
      if l_customer in ('burlingtoncoat') then
         return in_oh.hdrpassthruchar05;
      end if;
      return in_oh.hdrpassthruchar06;
   end if;

   if in_column = 'markforzip' then
      if l_customer in ('burlingtoncoat', 'jcpenney') then
         return in_oh.hdrpassthruchar06;
      end if;
      return in_oh.hdrpassthruchar07;
   end if;

   if in_column = 'storebarcode' then
      if l_customer in ('burlingtoncoat', 'jcpenney', 'lwfingerhut', 'shopko',
                        'lwbestbuy','lwaafes') then
         return '91'||in_oh.hdrpassthruchar01;
      elsif l_customer in ('belksgfoo','basspro') then
         return '91'||in_oh.hdrpassthruchar02;
      elsif l_customer in ('amazongen') then
         return '91'||in_oh.hdrpassthruchar20;
      elsif l_customer in ('walmart','walmartcom') then
         return '91'||in_oh.hdrpassthruchar04;
      elsif l_customer in ('mervyns') then
         return null;
      end if;
      if length(rtrim(in_oh.hdrpassthruchar05)) > 18 then
         return '91'||substr(in_oh.hdrpassthruchar05,1,18);
      else
         return '91'||in_oh.hdrpassthruchar05;
      end if;
   end if;

   if in_column = 'storehuman' then
      if l_customer in ('burlingtoncoat', 'jcpenney', 'lwfingerhut', 'shopko',
                        'lwbestbuy','lwaffes') then
         return '(91)'||in_oh.hdrpassthruchar01;
      elsif l_customer in ('belksgfoo','basspro') then
         return '(91)'||in_oh.hdrpassthruchar02;
      elsif l_customer in ('amazongen') then
         return '(91)'||in_oh.hdrpassthruchar20;
      elsif l_customer in ('walmart','walmartcom') then
         return '(91)'||in_oh.hdrpassthruchar04;
      elsif l_customer in ('mervyns') then
         return null;
      end if;
      if length(rtrim(in_oh.hdrpassthruchar05)) > 15 then
         return '(91)'||substr(in_oh.hdrpassthruchar05,1,15);
      else
         return '(91)'||in_oh.hdrpassthruchar05;
      end if;
   end if;

   if in_column = 'storenum' then
      if l_customer in ('amazongen', 'lwkmart') then
         return in_oh.hdrpassthruchar20;
      elsif l_customer in ('burlingtoncoat', 'mervyns') then
         return in_oh.fromfacility;
      elsif l_customer in ('searsroebuck', 'bbbsgfoo','boscovssgfoo', 'jockeysgfoo',
                           'kgsgfoo','bontonsgfoo','belksgfoo','basspro') then
         return in_oh.hdrpassthruchar02;
      end if;
      return in_oh.hdrpassthruchar01;
   end if;

   if in_column = 'style' then
      if l_customer in ('boscovs', 'bedbathandbeyond', 'buybuybaby', 'kaybee', 'lazybonezz', 'toysrus') then
         return in_od.dtlpassthruchar04;
      elsif l_customer in ('amazongen', 'searsroebuck') then
         return in_od.dtlpassthruchar05;
      end if;
      return in_aux.item;
   end if;

   if in_column = 'upc' then
      if l_customer in ('amazongen', 'burlingtoncoat', 'lwfingerhut', 'mervyns',
            'shopko', 'targetstores', 'lwofficedepot', 'lwbestbuy', 'lwstaples',
            'lwbuybuybaby') then
         return in_od.dtlpassthruchar01;
      end if;
      return in_value;
   end if;

   if in_column = 'vendorbar' then
      if l_customer in ('walmart','walmartcom') then
         return '90'||in_oh.hdrpassthruchar07;
      elsif l_customer in ('burlingtoncoat', 'lwfingerhut', 'lwkmart') then
         return null;
      elsif l_customer in ('bbbsgfoo','jockeysgfoo','boscovssgfoo', 'bontonsgfoo', 'kgsgfoo') then
         return in_oh.hdrpassthruchar13;
      end if;
      if length(rtrim(in_oh.hdrpassthruchar01)) > 16 then
         return '90'||substr(in_oh.hdrpassthruchar01,1,18);
      else
         return '90'||in_oh.hdrpassthruchar01;
      end if;
   end if;

   if in_column = 'vendorhuman' then
      if l_customer in ('walmart','walmartcom') then
         return '(90)'||in_oh.hdrpassthruchar07;
      elsif l_customer in ('burlingtoncoat', 'lwfingerhut', 'lwkmart') then
         return null;
      elsif l_customer in ('bbbsgfoo','jockeysgfoo','boscovssgfoo', 'bontonsgfoo', 'kgsgfoo') then
         return in_oh.hdrpassthruchar13;
      end if;
      if length(rtrim(in_oh.hdrpassthruchar01)) > 16 then
         return '(90)'||substr(in_oh.hdrpassthruchar05,1,16);
      else
         return '(90)'||in_oh.hdrpassthruchar01;
      end if;
   end if;

   if in_column = 'vendoritem' then
      if l_customer in ('walmart', 'lwstaples','walmartcom') then
         return in_od.dtlpassthruchar02;
      elsif l_customer in ('boscovs') then
         return null;
      end if;
      return in_od.consigneesku;
   end if;

end adjust_column;

procedure check_order
   (in_orderid  in number,
    in_shipid   in number,
    in_customer in varchar2,
    in_idx      in pls_integer)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.orderstatus, nvl(WV.picktype,'ORDR') as picktype
         from orderhdr OH, waves WV
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and WV.wave (+) = OH.wave;
   oh c_oh%rowtype := null;
   i binary_integer;
   l_sql varchar2(1024);
   l_cnt pls_integer := 0;
   l_taskcnt pls_integer := 0;
   l_val varchar2(255);
   l_picked boolean := false;
   l_usebatch boolean := false;
begin
   if in_customer != '*' then
      if key_values(in_idx).fieldname is null then
         null;    -- no check
      elsif key_values(in_idx).fieldvalue = '(NOTNULL)' then
         l_sql := 'select count(1) from orderhdr'
               || ' where orderid = ' || in_orderid
               || ' and shipid = ' || in_shipid
               || ' and ' || key_values(in_idx).fieldname || ' is not null';
         execute immediate l_sql into l_cnt;
         if l_cnt = 0 then
            return;
         end if;
      else
         l_sql := 'select ' || key_values(in_idx).fieldname || ' from orderhdr'
               || ' where orderid = ' || in_orderid
               || ' and shipid = ' || in_shipid;
         begin
            execute immediate l_sql into l_val;
         exception when others then
            return;
         end;

         if sql%rowcount = 0 THEN
            return;
         end if;

         -- check the value.
         if nvl(l_val,'(none)') != nvl(in_customer,'(none)') then
            return;
         end if;
      end if;
   end if;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   if oh.orderstatus = '4' then
      l_picked := false;
      if oh.picktype = 'BAT' then
         select count(1) into l_taskcnt
            from batchtasks
            where orderid = in_orderid
              and shipid = in_shipid;
         select count(1) into l_cnt
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid;
         if l_taskcnt = 0 and l_cnt != 0 then
            l_usebatch := false;
         elsif l_taskcnt != 0 and l_cnt = 0 then
            l_usebatch := true;
         else
            return;
         end if;
      end if;
   elsif oh.orderstatus in ('6','7','8','9') then
      l_picked := true;
   else
      return;
   end if;

   i := ord_tbl.count+1;
   ord_tbl(i).orderid := in_orderid;
   ord_tbl(i).shipid := in_shipid;
   ord_tbl(i).picked := l_picked;
   ord_tbl(i).usebatch := l_usebatch;
end check_order;

procedure verify_order
   (in_lpid          in varchar2,
    in_func          in varchar2,
    in_action        in varchar2,
    in_customer      in varchar2,
    in_auxdata       in varchar2,
    out_oh           out orderhdr%rowtype,
    out_msg          out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct orderid, shipid
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   oh c_oh%rowtype := null;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;

   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
   l_pos number;
   l_order varchar2(255);
   l_orderid orderhdr.orderid%type := null;
   l_shipid orderhdr.shipid%type := null;
   i binary_integer;
   l_consolidated char(1);
   l_wave orderhdr.wave%type := null;
   l_auxdata varchar2(255);
begin
   out_msg := null;
   globalConsorderid := 0;
-- Verify function
   if in_func not in ('Q','X') then
      out_msg := 'Unsupported Function';
      return;
   end if;

-- Load the translation table.
   load_key_values;
--
   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;
   l_auxdata := nvl(rtrim(in_auxdata), '(none)');
   if l_auxdata = '(none)' then
   -- try to determine order from lpid (could be plate or shippingplate)
      if substr(l_lpid, -1, 1) != 'S' then
         open c_lp(l_lpid);
         fetch c_lp into lp;
         if c_lp%found then            -- direct hit on XP
            l_lpid := lp.parentlpid;
         else
            open c_inf(l_lpid);
            fetch c_inf into inp;
            if c_inf%found then        -- try picked from lp
               l_cnt := 1;
               fetch c_inf into inp;
               if c_inf%found then     -- orderid/shipid not unique
                  l_cnt := 2;
               end if;
            end if;
            close c_inf;
         end if;
         close c_lp;
      end if;

      if substr(l_lpid, -1, 1) = 'S' then
         open c_inp(l_lpid);
         fetch c_inp into inp;
         if c_inp%found then
            l_cnt := 1;
         end if;
         close c_inp;
      end if;
      if inp.shipid = 0 then
         l_auxdata := 'ORDER|'||inp.orderid || '|0';
      else
         if l_cnt != 1 then
            if in_func = 'Q' then
               if l_cnt = 0 then
                  out_msg := 'Order not found';
               else
                  out_msg := 'Order not unique';
               end if;
            end if;
            return;
         end if;

      -- insure order is for correct customer
         open c_oh(inp.orderid, inp.shipid);
         fetch c_oh into out_oh;
         close c_oh;

         if in_customer != '*' then
         -- get the field to look at.
         idx := find_key_value_idx(in_customer);
         if idx = 0 then
            if in_func = 'Q' then
               out_msg := 'Table error on shipto';
            end if;
            return;
         end if;
         -- get the field value from orderhdr
         sql_stmt := 'select ' || key_values(idx).fieldname ||' from orderhdr
                       where orderid = '|| inp.orderid ||
                       ' and shipid = '|| inp.shipid;
         begin
            execute immediate sql_stmt into order_key_val;
         exception when others then
      --      dbms_output.put_line('sql_stmt: ' || sql_stmt);
            out_msg := 'Error getting Order';
            return;
         end;
         if sql%rowcount = 0 THEN
            if in_func = 'Q' then
               out_msg := '1 Nothing for order';
            end if;
            out_msg := 'Nothing in Index';
            return;
         end if;

         -- check the value.
         --dbms_output.put_line('order_key_val '|| order_key_val);
         if nvl(order_key_val, '(none)') != nvl(in_customer,'(none)') then
            if in_func = 'Q' then
               out_msg := '2 Nothing for order';
            end if;
            return;
         end if;
      --   EXCEPTION
      --      WHEN others THEN
      --          out_msg := 'Error finding key';
      --           return;
      --   end;

      --   if nvl(out_oh.hdrpassthruchar05, '(none)') != in_customer then
      --      if in_func = 'Q' then
      --          out_msg := 'Nothing for order';
      --      end if;
      --      return;
      --   end if;

         end if;
      -- insure everything picked
         select count(1) into l_cnt
            from shippingplate
            where orderid = inp.orderid
              and shipid = inp.shipid
              and status in ('U','P');

         if l_cnt != 0 then
            if in_func = 'Q' then
               out_msg := 'Order has picks';
            end if;
            return;
         end if;
         l_orderid := inp.orderid;
         l_shipid := inp.shipid;
      end if;
   end if;

   if l_auxdata != '(none)' then
        --aux data has data check to see if consolidated order or regular order
        -- Parse out orderid/shipid from auxdata
------------------------------------------------------------------------------------------------
      l_pos := instr(l_auxdata, '|');
      if l_pos != 0 then
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'ORDER' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
            end if;
         end if;
         if upper(substr(l_auxdata, 1, l_pos-1)) = 'WAVE' then
            l_order := substr(l_auxdata, l_pos+1);
            l_pos := instr(l_order, '|');
            if l_pos != 0 then
               l_orderid := to_number(substr(l_order, 1, l_pos-1));
               l_shipid := to_number(substr(l_order, l_pos+1));
            end if;
            begin
               select nvl(consolidated,'X') into l_consolidated
                  from waves
                  where wave = l_order;
            exception when no_data_found then
               l_consolidated := 'X';
            end;
            if l_consolidated <> 'Y' then
               if in_func = 'Q' then
                  out_msg := 'Wv not consolidated';
              end if;
              return;
            end if;
         end if;
      end if;
      if l_orderid is null then
         if in_func = 'Q' then
            out_msg := 'Order not found';
         end if;
         return;
      end if;

--    Load the translation table.
      if in_customer != '*' then
         load_key_values;
--    get the field to look at.
         idx := find_key_value_idx(in_customer);
         if idx = 0 then
            if in_func = 'Q' then
               out_msg := 'Table error on shipto';
            end if;
            return;
         end if;
      end if;

      ord_tbl.delete;

      if l_shipid != 0 then
         begin
            select nvl(consolidated,'X'), wave into l_consolidated, l_wave
               from waves
               where wave = (select wave from orderhdr
                               where orderid = l_orderid and shipid =  l_shipid);
         exception when no_data_found then
            l_consolidated := 'X';
         end;
         if l_consolidated = 'Y' then
            l_orderid := l_wave;
            for oh in (select orderid, shipid from orderhdr
                        where wave = l_orderid) loop
               check_order(oh.orderid, oh.shipid, in_customer, idx);
            end loop;
            globalConsorderid := l_orderid;
         else
            check_order(l_orderid, l_shipid, in_customer, idx);
         end if;
      else
         for oh in (select orderid, shipid from orderhdr
                     where wave = l_orderid) loop
            check_order(oh.orderid, oh.shipid, in_customer, idx);
         end loop;
         globalConsorderid := l_orderid;
      end if;
      if ord_tbl.count = 0 then
         if in_func = 'Q' then
            out_msg := '3 Nothing for order';
         end if;
         return;
      end if;

      l_cnt := 0;
      for i in 1..ord_tbl.count loop
         if ord_tbl(i).picked then
            l_cnt := l_cnt + 1;
         end if;
      end loop;

      if l_cnt != ord_tbl.count then
         if in_func = 'Q' then
            out_msg := 'Order has picks';
         end if;
         return;
      end if;
      if nvl(globalConsorderid,0) = 0 then
         open c_oh(l_orderid, l_shipid);
         fetch c_oh into out_oh;
         close c_oh;
      end if;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         if nvl(globalConsorderid,0) <> 0 then
            select count(1) into l_cnt
               from ucc_standard_labels
               where wave = globalConsorderid;
         else
--            app_msg('non cons reprint');
            select count(1) into l_cnt
               from ucc_standard_labels
               where orderid = l_orderid
                 and shipid = l_shipid;
         end if;
--         app_msg('l_cnt ' || l_cnt);
        if l_cnt = 0 then
            out_msg := '4 Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         if nvl(globalConsorderid,0) <> 0 then
            open c_wav(globalConsorderid);
            fetch c_wav into oh;
            close c_wav;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_zucclabels_view L , zseq Z'
                  || ' where L.wave = ' || globalConsorderid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         else
            open c_oh(l_orderid, l_shipid);
            fetch c_oh into oh;
            close c_oh;
            out_msg := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_zucclabels_view L , zseq Z'
                  || ' where L.orderid = ' || l_orderid
                  || ' and L.shipid = ' || l_shipid
                  || ' and Z.seq <= ' || duplicate_cnt(oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
         end if;
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_order;


procedure verify_order_cntnts
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_customer  in varchar2,
    out_oh       out orderhdr%rowtype,
    out_msg      out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct orderid, shipid
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
begin
   out_msg := null;

-- Load the translation table.
   load_key_values;
--
   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;

-- try to determine order from lpid (could be plate or shippingplate)
   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then            -- direct hit on XP
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then        -- try picked from lp
            l_cnt := 1;
            fetch c_inf into inp;
            if c_inf%found then     -- orderid/shipid not unique
               l_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         l_cnt := 1;
      end if;
      close c_inp;
   end if;

   if l_cnt != 1 then
      if in_func = 'Q' then
         if l_cnt = 0 then
            out_msg := 'Order not found';
         else
            out_msg := 'Order not unique';
         end if;
      end if;
      return;
   end if;

-- insure order is for correct customer
   open c_oh(inp.orderid, inp.shipid);
   fetch c_oh into out_oh;
   close c_oh;
-- insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where orderid = inp.orderid
        and shipid = inp.shipid
        and status in ('U','P');

   if l_cnt != 0 then
      if in_func = 'Q' then
         out_msg := 'Order has picks';
      end if;
      return;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where orderid = inp.orderid
              and shipid = inp.shipid;
         if l_cnt = 0 then
            out_msg := '5 Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         out_msg := 'select L.*'
               || ' from lbl_zucccntnts_view L, zseq Z'
               || ' where L.orderid = ' || inp.orderid
               || ' and L.shipid = ' || inp.shipid
               || ' and Z.seq <= ' || duplicate_cnt(out_oh)
               || ' order by L.item, L.seq';
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_order_cntnts;

procedure verify_order --overload
   (in_lpid      in varchar2,
    in_func      in varchar2,
    in_action    in varchar2,
    in_customer  in varchar2,
    in_customer2 in varchar2,
    in_auxdata   in varchar2,
    out_oh       out orderhdr%rowtype,
    out_msg      out varchar2)
is
   cursor c_lp(p_lpid varchar2) is
      select parentlpid
         from plate
         where lpid = p_lpid
           and type = 'XP';
   lp c_lp%rowtype;
   cursor c_inp(p_lpid varchar2) is
      select orderid, shipid
         from shippingplate
         where lpid = p_lpid;
   cursor c_inf(p_lpid varchar2) is
      select distinct orderid, shipid
         from shippingplate
         where fromlpid = p_lpid;
   inp c_inp%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
      select *
         from  orderhdr oh
         where oh.orderid = p_orderid
           and oh.shipid = p_shipid;
   l_lpid shippingplate.lpid%type := in_lpid;
   l_cnt pls_integer := 0;
   idx   pls_integer := 0;
   idx2  pls_integer := 0;
   order_key_val varchar2(255);
   sql_stmt varchar2(1024);
begin
   out_msg := null;
   globalConsorderid := 0;
-- Load the translation table.
   load_key_values;
--
   if in_action not in ('A','C','P') then
      if in_func = 'Q' then
         out_msg := 'Unsupported Action';
      end if;
      return;
   end if;

-- try to determine order from lpid (could be plate or shippingplate)
   if substr(l_lpid, -1, 1) != 'S' then
      open c_lp(l_lpid);
      fetch c_lp into lp;
      if c_lp%found then            -- direct hit on XP
         l_lpid := lp.parentlpid;
      else
         open c_inf(l_lpid);
         fetch c_inf into inp;
         if c_inf%found then        -- try picked from lp
            l_cnt := 1;
            fetch c_inf into inp;
            if c_inf%found then     -- orderid/shipid not unique
               l_cnt := 2;
            end if;
         end if;
         close c_inf;
      end if;
      close c_lp;
   end if;

   if substr(l_lpid, -1, 1) = 'S' then
      open c_inp(l_lpid);
      fetch c_inp into inp;
      if c_inp%found then
         l_cnt := 1;
      end if;
      close c_inp;
   end if;

   if l_cnt != 1 then
      if in_func = 'Q' then
         if l_cnt = 0 then
            out_msg := 'Order not found';
         else
            out_msg := 'Order not unique';
         end if;
      end if;
      return;
   end if;

-- insure order is for correct customer
   open c_oh(inp.orderid, inp.shipid);
   fetch c_oh into out_oh;
   close c_oh;

   -- get the field to look at.
   idx := find_key_value_idx(in_customer);
   if idx = 0 then
      if in_func = 'Q' then
         out_msg := 'Table error on shipto';
      end if;
      return;
   end if;
   -- get the field value from orderhdr
   sql_stmt := 'select ' || key_values(idx).fieldname ||' from orderhdr
                 where orderid = '|| inp.orderid ||
                 ' and shipid = '|| inp.shipid;
   begin
      execute immediate sql_stmt into order_key_val;
   exception when others then
--      dbms_output.put_line('sql_stmt: ' || sql_stmt);
      out_msg := 'Error getting Order';
      return;
   end;
   if sql%rowcount = 0 THEN
      if in_func = 'Q' then
         out_msg := '6 Nothing for order';
      end if;
      out_msg := 'Nothing in Index';
      return;
   end if;

   -- check the value.
-- dbms_output.put_line('order_key_val '|| order_key_val);
   if nvl(order_key_val, '(none)') != nvl(in_customer,'(none)') and
      nvl(order_key_val, '(none)') != nvl(in_customer2,'(none)') then
      if in_func = 'Q' then
         out_msg := '7 Nothing for order';
      end if;
      return;
   end if;
--   EXCEPTION
--      WHEN others THEN
--          out_msg := 'Error finding key';
--           return;
--   end;

--   if nvl(out_oh.hdrpassthruchar05, '(none)') != in_customer then
--      if in_func = 'Q' then
--          out_msg := 'Nothing for order';
--      end if;
--      return;
--   end if;

-- insure everything picked
   select count(1) into l_cnt
      from shippingplate
      where orderid = inp.orderid
        and shipid = inp.shipid
        and status in ('U','P');

   if l_cnt != 0 then
      if in_func = 'Q' then
         out_msg := 'Order has picks';
      end if;
      return;
   end if;

-- process reprint
   if in_action = 'P' then
      if in_func = 'Q' then
         select count(1) into l_cnt
            from ucc_standard_labels
            where orderid = inp.orderid
              and shipid = inp.shipid;
         if l_cnt = 0 then
            out_msg := '7 Nothing for order';
         else
            out_msg := 'OKAY';
         end if;
      else
         out_msg := 'select L.*'
               || ' from lbl_zucclabels_view L, zseq Z'
               || ' where L.orderid = ' || inp.orderid
               || ' and L.shipid = ' || inp.shipid
               || ' and Z.seq <= ' || duplicate_cnt(out_oh)
               || ' order by L.item, L.seq';
      end if;
      return;
   end if;

-- process generate all and change
   if (in_action = 'A') and (in_func = 'Q') then
      out_msg := 'OKAY';
   else
      out_msg := 'Continue';
   end if;

end verify_order;


procedure init_lblgroup
   (in_orderid  in number,
    in_shipid   in number,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_action   in varchar2,
    in_group    in varchar2,
    out_aux     out auxdata)
is
   cursor c_ord(p_orderid number, p_shipid number) is
      select FA.name as faname,
             FA.addr1,
             FA.addr2,
             FA.city,
             FA.state,
             FA.postalcode,
             FA.countrycode,
             CA.name as caname,
             CA.scac
         from orderhdr OH, facility FA, carrier CA
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and FA.facility = OH.fromfacility
           and CA.carrier (+) = OH.carrier;
   ord c_ord%rowtype;

  cursor c_consignee(p_orderid number, p_shipid number) is
     select nvl(oh.shiptoname, c.name) name,
            nvl(oh.shiptocontact, c.contact) contact,
            nvl(oh.shiptoaddr1, c.addr1) addr1,
            nvl(oh.shiptoaddr2, c.addr2) addr2,
            nvl(oh.shiptocity, c.city) city,
            nvl(oh.shiptostate, c.state) state,
            nvl(oh.shiptopostalcode, c.postalcode) postalcode,
            nvl(oh.shiptocountrycode, c.countrycode) countrycode,
            oh.shipto shipto
       from orderhdr oh, consignee c
      where oh.orderid = p_orderid
        and oh.shipid = p_shipid
        and c.consignee (+) = oh.shipto;
  consignee_rec c_consignee%rowtype;
  l_consolidated char(1);
begin
   begin
      select upper(nvl(defaultvalue,'CTN')) into l_cartonsuom
         from systemdefaults
         where defaultid = 'CARTONSUOM';
   exception when no_data_found then
         l_cartonsuom := 'CTN';
   end;

   out_aux := null;
   out_aux.quantity := 0;
   out_aux.weight := 0;
   out_aux.seq := 0;

   out_aux.seqof := 0;
   select nvl(consolidated,'N') into l_consolidated
      from waves
      where wave = (select wave
                       from orderhdr
                       where orderid = in_orderid
                         and shipid = in_shipid);
   if l_consolidated = 'Y' then
      for pp in (select lpid, type, fromlpid, quantity, weight, item
                  from shippingplate
                  where lpid in (select distinct parentlpid
                                  from shippingplate
                                  where orderid = in_orderid
                                    and shipid = in_shipid)) loop
         if (pp.type = 'C') or (in_group = 'ccp') then
            out_aux.seqof := out_aux.seqof + 1;
         else
            for cp in (select custid, item, unitofmeasure, lotnumber,
                              sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                          and orderid = in_orderid
                          and shipid = in_shipid
                        start with lpid = pp.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber) loop
               out_aux.seqof := out_aux.seqof
                     + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
            end loop;
         end if;
      end loop;
   else
      for pp in (select lpid, type, quantity from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and parentlpid is null) loop
         if (pp.type = 'C') or (in_group = 'ccp') then
            out_aux.seqof := out_aux.seqof + 1;
         else
            for cp in (select custid, item, unitofmeasure, lotnumber,
                              sum(quantity) as quantity
                        from shippingplate
                        where type in ('F','P')
                        start with lpid = pp.lpid
                        connect by prior lpid = parentlpid
                        group by custid, item, unitofmeasure, lotnumber) loop
               out_aux.seqof := out_aux.seqof
                     + zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure, l_cartonsuom);
            end loop;
         end if;
      end loop;
   end if;

   open c_ord(in_orderid, in_shipid);
   fetch c_ord into ord;
   close c_ord;
   out_aux.fromfacility := ord.faname;
   out_aux.fromaddr1 := ord.addr1;
   out_aux.fromaddr2 := ord.addr2;
   out_aux.fromcity := ord.city;
   out_aux.fromstate := ord.state;
   out_aux.fromzip := ord.postalcode;
   out_aux.shipfromcountrycode := ord.countrycode;
   out_aux.bol := zedi.get_custom_bol(in_orderid, in_shipid);
   out_aux.carriername := ord.caname;
   out_aux.scac := ord.scac;

   open c_consignee(in_orderid, in_shipid);
   fetch c_consignee into consignee_rec;
   close c_consignee;
   out_aux.consignee_name := consignee_rec.name;
   out_aux.consignee_addr1 := consignee_rec.addr1;
   out_aux.consignee_addr2 := consignee_rec.addr2;
   out_aux.consignee_city := consignee_rec.city;
   out_aux.consignee_state := consignee_rec.state;
   out_aux.consignee_postalcode := consignee_rec.postalcode;
   out_aux.consignee_countrycode := consignee_rec.countrycode;
   out_aux.shipto := consignee_rec.shipto;

   out_aux.sscctype := in_sscctype;
   out_aux.changeproc := 'zucclabels.'||upper(in_procname);

   if in_action = 'A' then
      delete from ucc_standard_labels
         where orderid = in_orderid
           and shipid = in_shipid;
      delete from caselabels
         where orderid = in_orderid
           and shipid = in_shipid;
      commit;
   end if;

   delete caselabels_temp;
   delete ucc_standard_labels_temp;

end init_lblgroup;


function sscc14_barcode
   (in_custid in varchar2,
    in_type   in varchar2,
    in_oh     in orderhdr%rowtype)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc, manufacturerucc_passthrufield
         from customer
         where custid = in_custid;
   manucc customer.manufacturerucc%type := null;
   barcode varchar2(14);
   manucc2 customer.manufacturerucc%type := null;
   manuccpass customer.manufacturerucc_passthrufield%type := null;
   seqname varchar2(30);
   seqval varchar2(5);
   ix integer;
   cc integer;
   cnt integer;
   cmdSql varchar2(200);
begin
   open c_cust;
   fetch c_cust into manucc,manuccpass;
   close c_cust;
   if manuccpass is not null then
      begin
         cmdSql := 'select substr(' || manuccpass || ',''1'',''7'') ' ||
                   ' from orderhdr ' ||
                   ' where orderid = ' || in_oh.orderid ||
                   '   and shipid = ' || in_oh.shipid;
         execute immediate cmdSql into manucc2;
      exception when no_data_found then
         manucc2 := null;
      end;
   end if;

   if manucc2 is not null then
      manucc := manucc2;
   end if;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   seqname := 'SSCC14_' || manucc || '_SEQ';
   select count(1)
      into cnt
      from user_sequences
      where sequence_name = seqname;

   if cnt = 0 then
      execute immediate 'create sequence ' || seqname
            || ' increment by 1 start with 1 maxvalue 99999 minvalue 1 nocache cycle';
   end if;

   execute immediate 'select lpad(' || seqname || '.nextval, 5, ''0'') from dual'
      into seqval;

   barcode := lpad(substr(in_type, 1, 1), 1, '1') || manucc || seqval;

   cc := 0;
   for cnt in 1..13 loop
      ix := substr(barcode, cnt, 1);

      if mod(cnt, 2) = 0 then
         cc := cc + ix;
      else
         cc := cc + (3 * ix);
      end if;
   end loop;

   cc := mod(10 - mod(cc, 10), 10);
   barcode := barcode || to_char(cc);
   commit;
   return barcode;

exception
  when others then
      rollback;
      return '00000000000000';
end sscc14_barcode;

function dwsscc14_barcode
   (in_oh      in orderhdr%rowtype,
    in_aux     in out auxdata)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc, manufacturerucc_passthrufield
         from customer
         where custid = in_oh.custid;
   manucc customer.manufacturerucc%type := null;
   manucc2 customer.manufacturerucc%type := null;
   manuccpass customer.manufacturerucc_passthrufield%type := null;
   barcode varchar2(14);
   max_barcode varchar2(20);
   seqname varchar2(30);
   seqval varchar2(5);
   in_type varchar2(1);
   ix integer;
   cc integer;
   cnt integer;
   cmdSql varchar2(200);
   cursor c_odl (in_value varchar2) is
      select dtlpassthruchar08
        from orderdtlline
        where orderid = in_oh.orderid
          and shipid = in_oh.shipid
          and item = in_aux.item
          and dtlpassthruchar08 is not null
          and dtlpassthruchar08 > nvl(in_value, ' ' );
begin
   open c_cust;
   fetch c_cust into manucc,manuccpass;
   close c_cust;
   if manuccpass is not null then
      begin
         cmdSql := 'select substr(' || manuccpass || ',''1'',''7'') ' ||
                   ' from orderhdr ' ||
                   ' where orderid = ' || in_oh.orderid  ||
                   '   and shipid = ' || in_oh.shipid;
         execute immediate cmdSql into manucc2;
      exception when no_data_found then
         manucc2 := null;
      end;
   end if;
   if manucc2 is not null then
      manucc := manucc2;
   end if;
   begin
      select max(sscc) into max_barcode from ucc_standard_labels
         where orderid = in_oh.orderid
           and shipid = in_oh.shipid
           and item = in_aux.item;
   exception when no_data_found then
      max_barcode := null;
   end;
   open c_odl(max_barcode);
   fetch c_odl into barcode;
   if c_odl%notfound then
      barcode := null;
   end if;
   close c_odl;
   if barcode is null then
      in_type := 0;
      if manucc is null then
         manucc := '0000000';
      elsif length(manucc) < 7 then
         manucc := lpad(manucc, 7, '0');
      end if;

      seqname := 'SSCC14_' || manucc || '_SEQ';
      select count(1)
         into cnt
         from user_sequences
         where sequence_name = seqname;

      if cnt = 0 then
         execute immediate 'create sequence ' || seqname
               || ' increment by 1 start with 1 maxvalue 99999 minvalue 1 nocache cycle';
      end if;

      execute immediate 'select lpad(' || seqname || '.nextval, 5, ''0'') from dual'
         into seqval;

      barcode := lpad(substr(in_type, 1, 1), 1, '1') || manucc || seqval;

      cc := 0;
      for cnt in 1..13 loop
         ix := substr(barcode, cnt, 1);

         if mod(cnt, 2) = 0 then
            cc := cc + ix;
         else
            cc := cc + (3 * ix);
         end if;
      end loop;

      cc := mod(10 - mod(cc, 10), 10);
      barcode := barcode || to_char(cc);
   end if;
   commit;
   return barcode;

exception
  when others then
      rollback;
      return '00000000000000';
end dwsscc14_barcode;


function dwsscc_barcode
   (in_oh      in orderhdr%rowtype,
    in_aux     in out auxdata)
return varchar2
is
   pragma autonomous_transaction;
   cursor c_cust is
      select manufacturerucc, manufacturerucc_passthrufield
         from customer
         where custid = in_oh.custid;

   cursor c_odl (in_value varchar2) is
      select dtlpassthruchar08
        from orderdtlline
        where orderid = in_oh.orderid
          and shipid = in_oh.shipid
          and item = in_aux.item
          and dtlpassthruchar08 is not null
          and dtlpassthruchar08 > nvl(in_value, ' ' );

   manucc customer.manufacturerucc%type := null;
   manucc2 customer.manufacturerucc%type := null;
   manuccpass customer.manufacturerucc_passthrufield%type := null;
   barcode varchar2(20);
   max_barcode varchar2(20);
   seqname varchar2(30);
   seqval varchar2(9);
   ix integer;
   cc integer;
   cnt integer;
   m_length integer;
   m_max_value varchar2(9);
   cmdSql varchar2(200);
begin

   open c_cust;
   fetch c_cust into manucc,manuccpass;
   close c_cust;
   if manuccpass is not null then
      begin
         cmdSql := 'select substr(' || manuccpass || ',''1'',''7'') ' ||
                   ' from orderhdr ' ||
                   ' where orderid = ' || in_oh.orderid ||
                   '   and shipid = ' || in_oh.shipid;
         execute immediate cmdSql into manucc2;
      exception when no_data_found then
         manucc2 := null;
      end;
   end if;
   if manucc2 is not null then
      manucc := manucc2;
   end if;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   begin
      select max(sscc) into max_barcode from ucc_standard_labels
         where orderid = in_oh.orderid
           and shipid = in_oh.shipid
           and item = in_aux.item;
   exception when no_data_found then
      max_barcode := null;
   end;
   --zut.prt('max ' || nvl(max_barcode, '(null)') || ' ' ||
   --        in_oh.orderid || ' ' || in_oh.shipid || ' ' || in_aux.item );
   open c_odl(max_barcode);
   fetch c_odl into barcode;
   if c_odl%notfound then
      barcode := null;
   end if;
   close c_odl;
   --zut.prt('bc  ' || nvl(barcode, '(null)'));

   if barcode is null then
      seqname := 'CSLBL_' || manucc || '_SEQ';
      select count(1)
         into cnt
         from user_sequences
         where sequence_name = seqname;

      m_length := length(manucc);
      ix := 16 - m_length;
      if cnt = 0 then
         m_max_value := substr('999999999', 1,ix);
         cmdsql := 'create sequence ' || seqname
               || ' increment by 1 start with 1 maxvalue ' || m_max_value
               ||  ' minvalue 1 nocache cycle';
         execute immediate cmdSql;
      end if;

      cmdSql := 'select lpad(' || seqname ||
                        '.nextval, ' || ix || ', ''0'') from dual';
      execute immediate cmdSql into seqval;

      barcode := '00'|| lpad(substr('0', 1, 1), 1, '1') || manucc || seqval;

      cc := 0;
      for cnt in 1..19 loop
         ix := substr(barcode, cnt, 1);

         if mod(cnt, 2) = 0 then
            cc := cc + ix;
         else
            cc := cc + (3 * ix);
         end if;
      end loop;

      cc := mod(10 - mod(cc, 10), 10);
      barcode := barcode || to_char(cc);
   end if;
   commit;
   return barcode;
exception
  when others then
      rollback;
      return '00000000000000000000';

end dwsscc_barcode;

procedure fill_cntnts
   (in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru,
    io_aux     in out auxdata)
is
   cursor c_od(in_orderid number, in_shipid number, in_item varchar2) is
      select dtlpassthruchar01,dtlpassthruchar02,dtlpassthruchar03
        from orderdtl
       where orderid = in_orderid
         and shipid = in_shipid
         and item = in_item;

begin
   cntntsx := 0;
   for sp in (select item, sum(quantity) as quantity
      from shippingplate
     where orderid = in_oh.orderid
       and shipid = in_oh.shipid
       and type in ('F','P')
     start with lpid = io_aux.lpid
        connect by prior lpid = parentlpid
          group by item
          order by item)
   loop
      cntntsx := cntntsx + 1;
      cntnts(cntntsx).itemqty := sp.quantity;
      open c_od(in_oh.orderid, in_oh.shipid, sp.item);
      fetch c_od into cntnts(cntntsx).dptchar01,
                      cntnts(cntntsx).dptchar02,
                      cntnts(cntntsx).dptchar03;
      close c_od;
   end loop;


end fill_cntnts;


procedure add_label
   (in_oh      in orderhdr%rowtype,
    in_od      in dtlpassthru,
    in_action  in varchar2,
    in_lbltype in varchar2,
    in_part    in varchar2,
    io_aux     in out auxdata)
is
   cursor c_itm(p_custid varchar2, p_item varchar2) is
      select item, descr,
             itmpassthruchar01, itmpassthruchar02, itmpassthruchar03, itmpassthruchar04,
             itmpassthrunum01, itmpassthrunum02, itmpassthrunum03, itmpassthrunum04
         from custitem
         where custid = p_custid
           and item = p_item;
   itm c_itm%rowtype;
   l_sscc varchar2(20);
   l_ssccfmt varchar2(40);
   l_barcodetype varchar2(1);
   l_rowid varchar2(20);
   l_labeltype caselabels.labeltype%type;
   l_lbltypedesc ucc_standard_labels.lbltypedesc%type;
   l_upc ucc_standard_labels.upc%type;
   l_manupass customer.manufacturerucc_passthrufield%type := null;
   l_cnt integer;
   cmdSql varchar2(200);
begin
   if in_lbltype = 'S' then
      l_labeltype := 'PL';
      if in_oh.shiptype = 'S' or
         io_aux.shippingtype = 'C' then
         l_labeltype := 'CS';
         l_barcodetype := '0';
         l_lbltypedesc := 'carton';
      else
         l_barcodetype := '1';
         l_lbltypedesc := 'pallet';
      end if;
   else
      l_labeltype := 'CS';
      l_barcodetype := '0';
      l_lbltypedesc := 'carton';
   end if;

   if io_aux.item is null then
      itm := null;
      itm.item := 'Mixed';
      itm.descr := 'Mixed';
   else
      open c_itm(in_oh.custid, io_aux.item);
      fetch c_itm into itm;
      close c_itm;
   end if;

   io_aux.seq := io_aux.seq + 1;
   io_aux.bol := adjust_column('bol', io_aux.bol, io_aux, in_oh, in_od);
   io_aux.color := adjust_column('color', null, io_aux, in_oh, in_od);
   io_aux.customeritem := adjust_column('customeritem', null, io_aux, in_oh, in_od);
   io_aux.department := adjust_column('department', null, io_aux, in_oh, in_od);
   io_aux.division := adjust_column('division', null, io_aux, in_oh, in_od);
   io_aux.itemsize := adjust_column('itemsize', null, io_aux, in_oh, in_od);
   io_aux.makrforstate := adjust_column('makrforstate', null, io_aux, in_oh, in_od);
   io_aux.markforaddr1 := adjust_column('markforaddr1', null, io_aux, in_oh, in_od);
   io_aux.markforaddr2 := adjust_column('markforaddr2', null, io_aux, in_oh, in_od);
   io_aux.markforcity := adjust_column('markforcity', null, io_aux, in_oh, in_od);
   io_aux.markforcountrycode := adjust_column('markforcountrycode', null, io_aux, in_oh, in_od);
   io_aux.markforname := adjust_column('markforname', null, io_aux, in_oh, in_od);
   io_aux.markforstate := adjust_column('markforstate', null, io_aux, in_oh, in_od);
   io_aux.markforzip := adjust_column('markforzip', null, io_aux, in_oh, in_od);
   io_aux.storebarcode := adjust_column('storebarcode', null, io_aux, in_oh, in_od);
   io_aux.storehuman := adjust_column('storehuman', null, io_aux, in_oh, in_od);
   io_aux.storenum := adjust_column('storenum', null, io_aux, in_oh, in_od);
   io_aux.style := adjust_column('style', null, io_aux, in_oh, in_od);
   l_upc := adjust_column('upc', in_od.upc, io_aux, in_oh, in_od);
   io_aux.vendorbar := adjust_column('vendorbar', null, io_aux, in_oh, in_od);
   io_aux.vendorhuman := adjust_column('vendorhuman', null, io_aux, in_oh, in_od);
   io_aux.vendoritem := adjust_column('vendoritem', null, io_aux, in_oh, in_od);
   cntnts.delete;
   for cntntsx in 1..14 loop
      cntnts(cntntsx) := null;
   end loop;
   if io_aux.pptype = 'X' then
      cntnts(1).dptchar01 := in_od.dtlpassthruchar01;
      cntnts(1).dptchar02 := in_od.dtlpassthruchar02;
      cntnts(1).dptchar03 := in_od.dtlpassthruchar03;
      cntnts(1).itemqty := io_aux.quantity;
   else
      fill_cntnts(in_oh, in_od, io_aux);
   end if;

   if in_action = 'A' then
      if io_aux.sscctype = '18' then
         if hardcoded_manucc is not null then
            l_sscc := zlbl.caselabel_barcode_var_manucc(in_oh.custid, l_barcodetype, hardcoded_manucc);
            -- zut.prt('zzcc 1 ' || l_sscc ||' <> ' || in_oh.custid || ' <> ' || l_barcodetype || ' <> ' || hardcoded_manucc);
            if length(hardcoded_manucc) = 9 then
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ????????? ??????? ?');
            elsif length(hardcoded_manucc) = 8  then
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
             else
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
            end if;
         else
            select manufacturerucc_passthrufield into l_manupass
               from customer
               where custid = in_oh.custid;
            if l_manupass is not null then
               if instr(l_manupass,'NUM') > 0 then
                  cmdSql := 'select  to_char(' || l_manupass || ', ''FM0999999'') ' ||
                             ' from orderhdr where orderid = ' || in_oh.orderid || ' and shipid = ' || in_oh.shipid;
         else
                  cmdSql := 'select  ' || l_manupass ||
                             ' from orderhdr where orderid = ' || in_oh.orderid || ' and shipid = ' || in_oh.shipid;
               end if;
               begin
                  execute immediate cmdSql into hardcoded_manucc;
               exception when no_data_found then
                  hardcoded_manucc := null;
               end;
            end if;
            if hardcoded_manucc is null then
               l_sscc := zlbl.caselabel_barcode(in_oh.custid, l_barcodetype);
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
            else
               l_sscc := zlbl.caselabel_barcode_var_manucc(in_oh.custid, l_barcodetype, hardcoded_manucc);
               -- zut.prt('zzcc 1 ' || l_sscc ||' <> ' || in_oh.custid || ' <> ' || l_barcodetype || ' <> ' || hardcoded_manucc);
               if length(hardcoded_manucc) = 9 then
                  l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ????????? ??????? ?');
               elsif length(hardcoded_manucc) = 8  then
                  l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
                else
                  l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
               end if;
            end if;
            -- zut.prt('zzcc 2 ' || l_sscc ||' <> ' || in_oh.custid || ' <> ' || l_barcodetype);
         end if;
      elsif io_aux.sscctype = 'DW' then
         l_sscc := dwsscc_barcode(in_oh, io_aux);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      elsif io_aux.sscctype = 'D1' then
         l_sscc := dwsscc14_barcode(in_oh, io_aux);
         l_ssccfmt := zlbl.format_string(l_sscc, '? ?? ????? ????? ?');
      else
         l_sscc := sscc14_barcode(in_oh.custid, l_barcodetype, in_oh);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;

--      if lower(substr(io_aux.changeproc, instr(io_aux.changeproc, '.')+1))
--         in ('shopko', 'walmart') then
--            l_sscc := '10'||in_od.dtlpassthruchar01;
--            l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
--      end if;

      insert into ucc_standard_labels
         (sscc,
          ssccfmt,
          lpid,
          picktolp,
          orderid,
          shipid,
          loadno,
          wave,
          item,
          itemdescr,
          quantity,
          weight,
          seq,
          seqof,
          lbltype,
          created,
          shiptoname,
          shiptocontact,
          shiptoaddr1,
          shiptoaddr2,
          shiptocity,
          shiptostate,
          shiptozip,
          shiptocountrycode,
          fromfacility,
          fromaddr1,
          fromaddr2,
          fromcity,
          fromstate,
          fromzip,
          shipfromcountrycode,
          pro,
          bol,
          po,
          reference,
          carriername,
          scac,
          lotnumber,
          shippingtype,
          custid,
          facility,
          hdrpasschar01,
          hdrpasschar02,
          hdrpasschar03,
          hdrpasschar04,
          hdrpasschar05,
          hdrpasschar06,
          hdrpasschar07,
          hdrpasschar08,
          hdrpasschar09,
          hdrpasschar10,
          hdrpasschar11,
          hdrpasschar12,
          hdrpasschar13,
          hdrpasschar14,
          hdrpasschar15,
          hdrpasschar16,
          hdrpasschar17,
          hdrpasschar18,
          hdrpasschar19,
          hdrpasschar20,
          hdrpasschar21,
          hdrpasschar22,
          hdrpasschar23,
          hdrpasschar24,
          hdrpasschar25,
          hdrpasschar26,
          hdrpasschar27,
          hdrpasschar28,
          hdrpasschar29,
          hdrpasschar30,
          hdrpasschar31,
          hdrpasschar32,
          hdrpasschar33,
          hdrpasschar34,
          hdrpasschar35,
          hdrpasschar36,
          hdrpasschar37,
          hdrpasschar38,
          hdrpasschar39,
          hdrpasschar40,
          hdrpasschar41,
          hdrpasschar42,
          hdrpasschar43,
          hdrpasschar44,
          hdrpasschar45,
          hdrpasschar46,
          hdrpasschar47,
          hdrpasschar48,
          hdrpasschar49,
          hdrpasschar50,
          hdrpasschar51,
          hdrpasschar52,
          hdrpasschar53,
          hdrpasschar54,
          hdrpasschar55,
          hdrpasschar56,
          hdrpasschar57,
          hdrpasschar58,
          hdrpasschar59,
          hdrpasschar60,
          hdrpassnum01,
          hdrpassnum02,
          hdrpassnum03,
          hdrpassnum04,
          hdrpassnum05,
          hdrpassnum06,
          hdrpassnum07,
          hdrpassnum08,
          hdrpassnum09,
          hdrpassnum10,
          hdrpassdate01,
          hdrpassdate02,
          hdrpassdate03,
          hdrpassdate04,
          hdrpassdoll01,
          hdrpassdoll02,
          dtlpasschar01,
          dtlpasschar02,
          dtlpasschar03,
          dtlpasschar04,
          dtlpasschar05,
          dtlpasschar06,
          dtlpasschar07,
          dtlpasschar08,
          dtlpasschar09,
          dtlpasschar10,
          dtlpasschar11,
          dtlpasschar12,
          dtlpasschar13,
          dtlpasschar14,
          dtlpasschar15,
          dtlpasschar16,
          dtlpasschar17,
          dtlpasschar18,
          dtlpasschar19,
          dtlpasschar20,
          dtlpasschar21,
          dtlpasschar22,
          dtlpasschar23,
          dtlpasschar24,
          dtlpasschar25,
          dtlpasschar26,
          dtlpasschar27,
          dtlpasschar28,
          dtlpasschar29,
          dtlpasschar30,
          dtlpasschar31,
          dtlpasschar32,
          dtlpasschar33,
          dtlpasschar34,
          dtlpasschar35,
          dtlpasschar36,
          dtlpasschar37,
          dtlpasschar38,
          dtlpasschar39,
          dtlpasschar40,
          dtlpassnum01,
          dtlpassnum02,
          dtlpassnum03,
          dtlpassnum04,
          dtlpassnum05,
          dtlpassnum06,
          dtlpassnum07,
          dtlpassnum08,
          dtlpassnum09,
          dtlpassnum10,
          dtlpassnum11,
          dtlpassnum12,
          dtlpassnum13,
          dtlpassnum14,
          dtlpassnum15,
          dtlpassnum16,
          dtlpassnum17,
          dtlpassnum18,
          dtlpassnum19,
          dtlpassnum20,
          dtlpassdate01,
          dtlpassdate02,
          dtlpassdate03,
          dtlpassdate04,
          dtlpassdoll01,
          dtlpassdoll02,
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          color,
          customeritem,
          department,
          division,
          itemsize,
          makrforstate,
          markforaddr1,
          markforaddr2,
          markforcity,
          markforcountrycode,
          markforname,
          markforstate,
          markforzip,
          storenum,
          style,
          vendoritem,
          dptchar01_01,
          dptchar02_01,
          dptchar03_01,
          itemqty_01,
          dptchar01_02,
          dptchar02_02,
          dptchar03_02,
          itemqty_02,
          dptchar01_03,
          dptchar02_03,
          dptchar03_03,
          itemqty_03,
          dptchar01_04,
          dptchar02_04,
          dptchar03_04,
          itemqty_04,
          dptchar01_05,
          dptchar02_05,
          dptchar03_05,
          itemqty_05,
          dptchar01_06,
          dptchar02_06,
          dptchar03_06,
          itemqty_06,
          dptchar01_07,
          dptchar02_07,
          dptchar03_07,
          itemqty_07,
          dptchar01_08,
          dptchar02_08,
          dptchar03_08,
          itemqty_08,
          dptchar01_09,
          dptchar02_09,
          dptchar03_09,
          itemqty_09,
          dptchar01_10,
          dptchar02_10,
          dptchar03_10,
          itemqty_10,
          dptchar01_11,
          dptchar02_11,
          dptchar03_11,
          itemqty_11,
          dptchar01_12,
          dptchar02_12,
          dptchar03_12,
          itemqty_12,
          dptchar01_13,
          dptchar02_13,
          dptchar03_13,
          itemqty_13,
          dptchar01_14,
          dptchar02_14,
          dptchar03_14,
          itemqty_14,
          shipto_master)
      values
         (l_sscc,
          l_ssccfmt,
          io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          in_oh.wave,
          itm.item,
          itm.descr,
          io_aux.quantity,
          io_aux.weight,
          io_aux.seq,
          io_aux.seqof,
          in_lbltype,
          sysdate,
          nvl(in_oh.shiptoname, io_aux.consignee_name),
          nvl(in_oh.shiptocontact, io_aux.consignee_contact),
          nvl(in_oh.shiptoaddr1, io_aux.consignee_addr1),
          nvl(in_oh.shiptoaddr2, io_aux.consignee_addr2),
          nvl(in_oh.shiptocity, io_aux.consignee_city),
          nvl(in_oh.shiptostate, io_aux.consignee_state),
          nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          nvl(in_oh.shiptocountrycode, io_aux.consignee_countrycode),
          io_aux.fromfacility,
          io_aux.fromaddr1,
          io_aux.fromaddr2,
          io_aux.fromcity,
          io_aux.fromstate,
          io_aux.fromzip,
          io_aux.shipfromcountrycode,
          in_oh.prono,
          io_aux.bol,
          in_oh.po,
          in_oh.reference,
          io_aux.carriername,
          io_aux.scac,
          io_aux.lotnumber,
          io_aux.shippingtype,
          in_oh.custid,
          in_oh.fromfacility,
          in_oh.hdrpassthruchar01,
          in_oh.hdrpassthruchar02,
          in_oh.hdrpassthruchar03,
          in_oh.hdrpassthruchar04,
          in_oh.hdrpassthruchar05,
          in_oh.hdrpassthruchar06,
          in_oh.hdrpassthruchar07,
          in_oh.hdrpassthruchar08,
          in_oh.hdrpassthruchar09,
          in_oh.hdrpassthruchar10,
          in_oh.hdrpassthruchar11,
          in_oh.hdrpassthruchar12,
          in_oh.hdrpassthruchar13,
          in_oh.hdrpassthruchar14,
          in_oh.hdrpassthruchar15,
          in_oh.hdrpassthruchar16,
          in_oh.hdrpassthruchar17,
          in_oh.hdrpassthruchar18,
          in_oh.hdrpassthruchar19,
          in_oh.hdrpassthruchar20,
          in_oh.hdrpassthruchar21,
          in_oh.hdrpassthruchar22,
          in_oh.hdrpassthruchar23,
          in_oh.hdrpassthruchar24,
          in_oh.hdrpassthruchar25,
          in_oh.hdrpassthruchar26,
          in_oh.hdrpassthruchar27,
          in_oh.hdrpassthruchar28,
          in_oh.hdrpassthruchar29,
          in_oh.hdrpassthruchar30,
          in_oh.hdrpassthruchar31,
          in_oh.hdrpassthruchar32,
          in_oh.hdrpassthruchar33,
          in_oh.hdrpassthruchar34,
          in_oh.hdrpassthruchar35,
          in_oh.hdrpassthruchar36,
          in_oh.hdrpassthruchar37,
          in_oh.hdrpassthruchar38,
          in_oh.hdrpassthruchar39,
          in_oh.hdrpassthruchar40,
          in_oh.hdrpassthruchar41,
          in_oh.hdrpassthruchar42,
          in_oh.hdrpassthruchar43,
          in_oh.hdrpassthruchar44,
          in_oh.hdrpassthruchar45,
          in_oh.hdrpassthruchar46,
          in_oh.hdrpassthruchar47,
          in_oh.hdrpassthruchar48,
          in_oh.hdrpassthruchar49,
          in_oh.hdrpassthruchar50,
          in_oh.hdrpassthruchar51,
          in_oh.hdrpassthruchar52,
          in_oh.hdrpassthruchar53,
          in_oh.hdrpassthruchar54,
          in_oh.hdrpassthruchar55,
          in_oh.hdrpassthruchar56,
          in_oh.hdrpassthruchar57,
          in_oh.hdrpassthruchar58,
          in_oh.hdrpassthruchar59,
          in_oh.hdrpassthruchar60,
          in_oh.hdrpassthrunum01,
          in_oh.hdrpassthrunum02,
          in_oh.hdrpassthrunum03,
          in_oh.hdrpassthrunum04,
          in_oh.hdrpassthrunum05,
          in_oh.hdrpassthrunum06,
          in_oh.hdrpassthrunum07,
          in_oh.hdrpassthrunum08,
          in_oh.hdrpassthrunum09,
          in_oh.hdrpassthrunum10,
          in_oh.hdrpassthrudate01,
          in_oh.hdrpassthrudate02,
          in_oh.hdrpassthrudate03,
          in_oh.hdrpassthrudate04,
          in_oh.hdrpassthrudoll01,
          in_oh.hdrpassthrudoll02,
          in_od.dtlpassthruchar01,
          decode(io_aux.item, null, 'Mixed', in_od.dtlpassthruchar02),
          in_od.dtlpassthruchar03,
          in_od.dtlpassthruchar04,
          in_od.dtlpassthruchar05,
          in_od.dtlpassthruchar06,
          in_od.dtlpassthruchar07,
          in_od.dtlpassthruchar08,
          in_od.dtlpassthruchar09,
          in_od.dtlpassthruchar10,
          in_od.dtlpassthruchar11,
          in_od.dtlpassthruchar12,
          in_od.dtlpassthruchar13,
          in_od.dtlpassthruchar14,
          in_od.dtlpassthruchar15,
          in_od.dtlpassthruchar16,
          in_od.dtlpassthruchar17,
          in_od.dtlpassthruchar18,
          in_od.dtlpassthruchar19,
          in_od.dtlpassthruchar20,
          in_od.dtlpassthruchar21,
          in_od.dtlpassthruchar22,
          in_od.dtlpassthruchar23,
          in_od.dtlpassthruchar24,
          in_od.dtlpassthruchar25,
          in_od.dtlpassthruchar26,
          in_od.dtlpassthruchar27,
          in_od.dtlpassthruchar28,
          in_od.dtlpassthruchar29,
          in_od.dtlpassthruchar30,
          in_od.dtlpassthruchar31,
          in_od.dtlpassthruchar32,
          in_od.dtlpassthruchar33,
          in_od.dtlpassthruchar34,
          in_od.dtlpassthruchar35,
          in_od.dtlpassthruchar36,
          in_od.dtlpassthruchar37,
          in_od.dtlpassthruchar38,
          in_od.dtlpassthruchar39,
          in_od.dtlpassthruchar40,
          in_od.dtlpassthrunum01,
          in_od.dtlpassthrunum02,
          in_od.dtlpassthrunum03,
          in_od.dtlpassthrunum04,
          in_od.dtlpassthrunum05,
          in_od.dtlpassthrunum06,
          in_od.dtlpassthrunum07,
          in_od.dtlpassthrunum08,
          in_od.dtlpassthrunum09,
          in_od.dtlpassthrunum10,
          in_od.dtlpassthrunum11,
          in_od.dtlpassthrunum12,
          in_od.dtlpassthrunum13,
          in_od.dtlpassthrunum14,
          in_od.dtlpassthrunum15,
          in_od.dtlpassthrunum16,
          in_od.dtlpassthrunum17,
          in_od.dtlpassthrunum18,
          in_od.dtlpassthrunum19,
          in_od.dtlpassthrunum20,
          in_od.dtlpassthrudate01,
          in_od.dtlpassthrudate02,
          in_od.dtlpassthrudate03,
          in_od.dtlpassthrudate04,
          in_od.dtlpassthrudoll01,
          in_od.dtlpassthrudoll02,
          itm.itmpassthruchar01,
          itm.itmpassthruchar02,
          itm.itmpassthruchar03,
          itm.itmpassthruchar04,
          itm.itmpassthrunum01,
          itm.itmpassthrunum02,
          itm.itmpassthrunum03,
          itm.itmpassthrunum04,
          in_od.consigneesku,
          l_upc,
          '420'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          '(420)'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          io_aux.storebarcode,
          io_aux.storehuman,
          io_aux.vendorbar,
          io_aux.vendorhuman,
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          io_aux.color,
          io_aux.customeritem,
          io_aux.department,
          io_aux.division,
          io_aux.itemsize,
          io_aux.makrforstate,
          io_aux.markforaddr1,
          io_aux.markforaddr2,
          io_aux.markforcity,
          io_aux.markforcountrycode,
          io_aux.markforname,
          io_aux.markforstate,
          io_aux.markforzip,
          io_aux.storenum,
          io_aux.style,
          io_aux.vendoritem,
          cntnts(1).dptchar01,
          cntnts(1).dptchar02,
          cntnts(1).dptchar03,
          cntnts(1).itemqty,
          cntnts(2).dptchar01,
          cntnts(2).dptchar02,
          cntnts(2).dptchar03,
          cntnts(2).itemqty,
          cntnts(3).dptchar01,
          cntnts(3).dptchar02,
          cntnts(3).dptchar03,
          cntnts(3).itemqty,
          cntnts(4).dptchar01,
          cntnts(4).dptchar02,
          cntnts(4).dptchar03,
          cntnts(4).itemqty,
          cntnts(5).dptchar01,
          cntnts(5).dptchar02,
          cntnts(5).dptchar03,
          cntnts(5).itemqty,
          cntnts(6).dptchar01,
          cntnts(6).dptchar02,
          cntnts(6).dptchar03,
          cntnts(6).itemqty,
          cntnts(7).dptchar01,
          cntnts(7).dptchar02,
          cntnts(7).dptchar03,
          cntnts(7).itemqty,
          cntnts(8).dptchar01,
          cntnts(8).dptchar02,
          cntnts(8).dptchar03,
          cntnts(8).itemqty,
          cntnts(9).dptchar01,
          cntnts(9).dptchar02,
          cntnts(9).dptchar03,
          cntnts(9).itemqty,
          cntnts(10).dptchar01,
          cntnts(10).dptchar02,
          cntnts(10).dptchar03,
          cntnts(10).itemqty,
          cntnts(11).dptchar01,
          cntnts(11).dptchar02,
          cntnts(11).dptchar03,
          cntnts(11).itemqty,
          cntnts(12).dptchar01,
          cntnts(12).dptchar02,
          cntnts(12).dptchar03,
          cntnts(12).itemqty,
          cntnts(13).dptchar01,
          cntnts(13).dptchar02,
          cntnts(13).dptchar03,
          cntnts(13).itemqty,
          cntnts(14).dptchar01,
          cntnts(14).dptchar02,
          cntnts(14).dptchar03,
          cntnts(14).itemqty,
          in_oh.shipto_master
          );
      if io_aux.sscctype = '14' or
         io_aux.sscctype = 'D1' then
         select count(1) into l_cnt
            from caselabels
            where barcode = l_sscc;
         if l_cnt > 0 then
            delete from caselabels where barcode = l_sscc;
         end if;
      end if;

      insert into caselabels
         (orderid,
          shipid,
          custid,
          item,
          lotnumber,
          lpid,
          barcode,
          seq,
          seqof,
          created,
          auxtable,
          auxkey,
          quantity,
          labeltype,
          changeproc)
      values
         (in_oh.orderid,
          in_oh.shipid,
          in_oh.custid,
          io_aux.item,
          io_aux.lotnumber,
          io_aux.lpid,
          l_sscc,
          io_aux.seq,
          io_aux.seqof,
          sysdate,
          'ucc_standard_labels',
          'sscc',
          io_aux.quantity,
          l_labeltype,
          io_aux.changeproc);
   else
      insert into ucc_standard_labels_temp
         (lpid,
          picktolp,
          orderid,
          shipid,
          loadno,
          wave,
          item,
          itemdescr,
          quantity,
          weight,
          seq,
          seqof,
          lbltype,
          shiptoname,
          shiptocontact,
          shiptoaddr1,
          shiptoaddr2,
          shiptocity,
          shiptostate,
          shiptozip,
          shiptocountrycode,
          fromfacility,
          fromaddr1,
          fromaddr2,
          fromcity,
          fromstate,
          fromzip,
          shipfromcountrycode,
          pro,
          bol,
          po,
          reference,
          carriername,
          scac,
          lotnumber,
          shippingtype,
          custid,
          facility,
          hdrpasschar01,
          hdrpasschar02,
          hdrpasschar03,
          hdrpasschar04,
          hdrpasschar05,
          hdrpasschar06,
          hdrpasschar07,
          hdrpasschar08,
          hdrpasschar09,
          hdrpasschar10,
          hdrpasschar11,
          hdrpasschar12,
          hdrpasschar13,
          hdrpasschar14,
          hdrpasschar15,
          hdrpasschar16,
          hdrpasschar17,
          hdrpasschar18,
          hdrpasschar19,
          hdrpasschar20,
          hdrpasschar21,
          hdrpasschar22,
          hdrpasschar23,
          hdrpasschar24,
          hdrpasschar25,
          hdrpasschar26,
          hdrpasschar27,
          hdrpasschar28,
          hdrpasschar29,
          hdrpasschar30,
          hdrpasschar31,
          hdrpasschar32,
          hdrpasschar33,
          hdrpasschar34,
          hdrpasschar35,
          hdrpasschar36,
          hdrpasschar37,
          hdrpasschar38,
          hdrpasschar39,
          hdrpasschar40,
          hdrpasschar41,
          hdrpasschar42,
          hdrpasschar43,
          hdrpasschar44,
          hdrpasschar45,
          hdrpasschar46,
          hdrpasschar47,
          hdrpasschar48,
          hdrpasschar49,
          hdrpasschar50,
          hdrpasschar51,
          hdrpasschar52,
          hdrpasschar53,
          hdrpasschar54,
          hdrpasschar55,
          hdrpasschar56,
          hdrpasschar57,
          hdrpasschar58,
          hdrpasschar59,
          hdrpasschar60,
          hdrpassnum01,
          hdrpassnum02,
          hdrpassnum03,
          hdrpassnum04,
          hdrpassnum05,
          hdrpassnum06,
          hdrpassnum07,
          hdrpassnum08,
          hdrpassnum09,
          hdrpassnum10,
          hdrpassdate01,
          hdrpassdate02,
          hdrpassdate03,
          hdrpassdate04,
          hdrpassdoll01,
          hdrpassdoll02,
          dtlpasschar01,
          dtlpasschar02,
          dtlpasschar03,
          dtlpasschar04,
          dtlpasschar05,
          dtlpasschar06,
          dtlpasschar07,
          dtlpasschar08,
          dtlpasschar09,
          dtlpasschar10,
          dtlpasschar11,
          dtlpasschar12,
          dtlpasschar13,
          dtlpasschar14,
          dtlpasschar15,
          dtlpasschar16,
          dtlpasschar17,
          dtlpasschar18,
          dtlpasschar19,
          dtlpasschar20,
          dtlpasschar21,
          dtlpasschar22,
          dtlpasschar23,
          dtlpasschar24,
          dtlpasschar25,
          dtlpasschar26,
          dtlpasschar27,
          dtlpasschar28,
          dtlpasschar29,
          dtlpasschar30,
          dtlpasschar31,
          dtlpasschar32,
          dtlpasschar33,
          dtlpasschar34,
          dtlpasschar35,
          dtlpasschar36,
          dtlpasschar37,
          dtlpasschar38,
          dtlpasschar39,
          dtlpasschar40,
          dtlpassnum01,
          dtlpassnum02,
          dtlpassnum03,
          dtlpassnum04,
          dtlpassnum05,
          dtlpassnum06,
          dtlpassnum07,
          dtlpassnum08,
          dtlpassnum09,
          dtlpassnum10,
          dtlpassnum11,
          dtlpassnum12,
          dtlpassnum13,
          dtlpassnum14,
          dtlpassnum15,
          dtlpassnum16,
          dtlpassnum17,
          dtlpassnum18,
          dtlpassnum19,
          dtlpassnum20,
          dtlpassdate01,
          dtlpassdate02,
          dtlpassdate03,
          dtlpassdate04,
          dtlpassdoll01,
          dtlpassdoll02,
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          lbltypedesc,
          part,
          shipto,
          color,
          customeritem,
          department,
          division,
          itemsize,
          makrforstate,
          markforaddr1,
          markforaddr2,
          markforcity,
          markforcountrycode,
          markforname,
          markforstate,
          markforzip,
          storenum,
          style,
          vendoritem,
          dptchar01_01,
          dptchar02_01,
          dptchar03_01,
          itemqty_01,
          dptchar01_02,
          dptchar02_02,
          dptchar03_02,
          itemqty_02,
          dptchar01_03,
          dptchar02_03,
          dptchar03_03,
          itemqty_03,
          dptchar01_04,
          dptchar02_04,
          dptchar03_04,
          itemqty_04,
          dptchar01_05,
          dptchar02_05,
          dptchar03_05,
          itemqty_05,
          dptchar01_06,
          dptchar02_06,
          dptchar03_06,
          itemqty_06,
          dptchar01_07,
          dptchar02_07,
          dptchar03_07,
          itemqty_07,
          dptchar01_08,
          dptchar02_08,
          dptchar03_08,
          itemqty_08,
          dptchar01_09,
          dptchar02_09,
          dptchar03_09,
          itemqty_09,
          dptchar01_10,
          dptchar02_10,
          dptchar03_10,
          itemqty_10,
          dptchar01_11,
          dptchar02_11,
          dptchar03_11,
          itemqty_11,
          dptchar01_12,
          dptchar02_12,
          dptchar03_12,
          itemqty_12,
          dptchar01_13,
          dptchar02_13,
          dptchar03_13,
          itemqty_13,
          dptchar01_14,
          dptchar02_14,
          dptchar03_14,
          itemqty_14,
          shipto_master)
      values
         (io_aux.lpid,
          io_aux.picktolp,
          in_oh.orderid,
          in_oh.shipid,
          in_oh.loadno,
          in_oh.wave,
          itm.item,
          itm.descr,
          io_aux.quantity,
          io_aux.weight,
          io_aux.seq,
          io_aux.seqof,
          in_lbltype,
          nvl(in_oh.shiptoname, io_aux.consignee_name),
          nvl(in_oh.shiptocontact, io_aux.consignee_contact),
          nvl(in_oh.shiptoaddr1, io_aux.consignee_addr1),
          nvl(in_oh.shiptoaddr2, io_aux.consignee_addr2),
          nvl(in_oh.shiptocity, io_aux.consignee_city),
          nvl(in_oh.shiptostate, io_aux.consignee_state),
          nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          nvl(in_oh.shiptocountrycode, io_aux.consignee_countrycode),
          io_aux.fromfacility,
          io_aux.fromaddr1,
          io_aux.fromaddr2,
          io_aux.fromcity,
          io_aux.fromstate,
          io_aux.fromzip,
          io_aux.shipfromcountrycode,
          in_oh.prono,
          io_aux.bol,
          in_oh.po,
          in_oh.reference,
          io_aux.carriername,
          io_aux.scac,
          io_aux.lotnumber,
          io_aux.shippingtype,
          in_oh.custid,
          in_oh.fromfacility,
          in_oh.hdrpassthruchar01,
          in_oh.hdrpassthruchar02,
          in_oh.hdrpassthruchar03,
          in_oh.hdrpassthruchar04,
          in_oh.hdrpassthruchar05,
          in_oh.hdrpassthruchar06,
          in_oh.hdrpassthruchar07,
          in_oh.hdrpassthruchar08,
          in_oh.hdrpassthruchar09,
          in_oh.hdrpassthruchar10,
          in_oh.hdrpassthruchar11,
          in_oh.hdrpassthruchar12,
          in_oh.hdrpassthruchar13,
          in_oh.hdrpassthruchar14,
          in_oh.hdrpassthruchar15,
          in_oh.hdrpassthruchar16,
          in_oh.hdrpassthruchar17,
          in_oh.hdrpassthruchar18,
          in_oh.hdrpassthruchar19,
          in_oh.hdrpassthruchar20,
          in_oh.hdrpassthruchar21,
          in_oh.hdrpassthruchar22,
          in_oh.hdrpassthruchar23,
          in_oh.hdrpassthruchar24,
          in_oh.hdrpassthruchar25,
          in_oh.hdrpassthruchar26,
          in_oh.hdrpassthruchar27,
          in_oh.hdrpassthruchar28,
          in_oh.hdrpassthruchar29,
          in_oh.hdrpassthruchar30,
          in_oh.hdrpassthruchar31,
          in_oh.hdrpassthruchar32,
          in_oh.hdrpassthruchar33,
          in_oh.hdrpassthruchar34,
          in_oh.hdrpassthruchar35,
          in_oh.hdrpassthruchar36,
          in_oh.hdrpassthruchar37,
          in_oh.hdrpassthruchar38,
          in_oh.hdrpassthruchar39,
          in_oh.hdrpassthruchar40,
          in_oh.hdrpassthruchar41,
          in_oh.hdrpassthruchar42,
          in_oh.hdrpassthruchar43,
          in_oh.hdrpassthruchar44,
          in_oh.hdrpassthruchar45,
          in_oh.hdrpassthruchar46,
          in_oh.hdrpassthruchar47,
          in_oh.hdrpassthruchar48,
          in_oh.hdrpassthruchar49,
          in_oh.hdrpassthruchar50,
          in_oh.hdrpassthruchar51,
          in_oh.hdrpassthruchar52,
          in_oh.hdrpassthruchar53,
          in_oh.hdrpassthruchar54,
          in_oh.hdrpassthruchar55,
          in_oh.hdrpassthruchar56,
          in_oh.hdrpassthruchar57,
          in_oh.hdrpassthruchar58,
          in_oh.hdrpassthruchar59,
          in_oh.hdrpassthruchar60,
          in_oh.hdrpassthrunum01,
          in_oh.hdrpassthrunum02,
          in_oh.hdrpassthrunum03,
          in_oh.hdrpassthrunum04,
          in_oh.hdrpassthrunum05,
          in_oh.hdrpassthrunum06,
          in_oh.hdrpassthrunum07,
          in_oh.hdrpassthrunum08,
          in_oh.hdrpassthrunum09,
          in_oh.hdrpassthrunum10,
          in_oh.hdrpassthrudate01,
          in_oh.hdrpassthrudate02,
          in_oh.hdrpassthrudate03,
          in_oh.hdrpassthrudate04,
          in_oh.hdrpassthrudoll01,
          in_oh.hdrpassthrudoll02,
          in_od.dtlpassthruchar01,
          decode(io_aux.item, null, 'Mixed', in_od.dtlpassthruchar02),
          in_od.dtlpassthruchar03,
          in_od.dtlpassthruchar04,
          in_od.dtlpassthruchar05,
          in_od.dtlpassthruchar06,
          in_od.dtlpassthruchar07,
          in_od.dtlpassthruchar08,
          in_od.dtlpassthruchar09,
          in_od.dtlpassthruchar10,
          in_od.dtlpassthruchar11,
          in_od.dtlpassthruchar12,
          in_od.dtlpassthruchar13,
          in_od.dtlpassthruchar14,
          in_od.dtlpassthruchar15,
          in_od.dtlpassthruchar16,
          in_od.dtlpassthruchar17,
          in_od.dtlpassthruchar18,
          in_od.dtlpassthruchar19,
          in_od.dtlpassthruchar20,
          in_od.dtlpassthruchar21,
          in_od.dtlpassthruchar22,
          in_od.dtlpassthruchar23,
          in_od.dtlpassthruchar24,
          in_od.dtlpassthruchar25,
          in_od.dtlpassthruchar26,
          in_od.dtlpassthruchar27,
          in_od.dtlpassthruchar28,
          in_od.dtlpassthruchar29,
          in_od.dtlpassthruchar30,
          in_od.dtlpassthruchar31,
          in_od.dtlpassthruchar32,
          in_od.dtlpassthruchar33,
          in_od.dtlpassthruchar34,
          in_od.dtlpassthruchar35,
          in_od.dtlpassthruchar36,
          in_od.dtlpassthruchar37,
          in_od.dtlpassthruchar38,
          in_od.dtlpassthruchar39,
          in_od.dtlpassthruchar40,
          in_od.dtlpassthrunum01,
          in_od.dtlpassthrunum02,
          in_od.dtlpassthrunum03,
          in_od.dtlpassthrunum04,
          in_od.dtlpassthrunum05,
          in_od.dtlpassthrunum06,
          in_od.dtlpassthrunum07,
          in_od.dtlpassthrunum08,
          in_od.dtlpassthrunum09,
          in_od.dtlpassthrunum10,
          in_od.dtlpassthrunum11,
          in_od.dtlpassthrunum12,
          in_od.dtlpassthrunum13,
          in_od.dtlpassthrunum14,
          in_od.dtlpassthrunum15,
          in_od.dtlpassthrunum16,
          in_od.dtlpassthrunum17,
          in_od.dtlpassthrunum18,
          in_od.dtlpassthrunum19,
          in_od.dtlpassthrunum20,
          in_od.dtlpassthrudate01,
          in_od.dtlpassthrudate02,
          in_od.dtlpassthrudate03,
          in_od.dtlpassthrudate04,
          in_od.dtlpassthrudoll01,
          in_od.dtlpassthrudoll02,
          itm.itmpassthruchar01,
          itm.itmpassthruchar02,
          itm.itmpassthruchar03,
          itm.itmpassthruchar04,
          itm.itmpassthrunum01,
          itm.itmpassthrunum02,
          itm.itmpassthrunum03,
          itm.itmpassthrunum04,
          in_od.consigneesku,
          l_upc,
          '420'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          '(420)'||substr(nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),1,5),
          io_aux.storebarcode,
          io_aux.storehuman,
          io_aux.vendorbar,
          io_aux.vendorhuman,
          nvl(in_oh.shiptocity, io_aux.consignee_city)||', '
            ||nvl(in_oh.shiptostate, io_aux.consignee_state) ||' '
            ||nvl(in_oh.shiptopostalcode, io_aux.consignee_postalcode),
          io_aux.fromcity||', '||io_aux.fromstate||' '||io_aux.fromzip,
          l_lbltypedesc,
          in_part,
          io_aux.shipto,
          io_aux.color,
          io_aux.customeritem,
          io_aux.department,
          io_aux.division,
          io_aux.itemsize,
          io_aux.makrforstate,
          io_aux.markforaddr1,
          io_aux.markforaddr2,
          io_aux.markforcity,
          io_aux.markforcountrycode,
          io_aux.markforname,
          io_aux.markforstate,
          io_aux.markforzip,
          io_aux.storenum,
          io_aux.style,
          io_aux.vendoritem,
          cntnts(1).dptchar01,
          cntnts(1).dptchar02,
          cntnts(1).dptchar03,
          cntnts(1).itemqty,
          cntnts(2).dptchar01,
          cntnts(2).dptchar02,
          cntnts(2).dptchar03,
          cntnts(2).itemqty,
          cntnts(3).dptchar01,
          cntnts(3).dptchar02,
          cntnts(3).dptchar03,
          cntnts(3).itemqty,
          cntnts(4).dptchar01,
          cntnts(4).dptchar02,
          cntnts(4).dptchar03,
          cntnts(4).itemqty,
          cntnts(5).dptchar01,
          cntnts(5).dptchar02,
          cntnts(5).dptchar03,
          cntnts(5).itemqty,
          cntnts(6).dptchar01,
          cntnts(6).dptchar02,
          cntnts(6).dptchar03,
          cntnts(6).itemqty,
          cntnts(7).dptchar01,
          cntnts(7).dptchar02,
          cntnts(7).dptchar03,
          cntnts(7).itemqty,
          cntnts(8).dptchar01,
          cntnts(8).dptchar02,
          cntnts(8).dptchar03,
          cntnts(8).itemqty,
          cntnts(9).dptchar01,
          cntnts(9).dptchar02,
          cntnts(9).dptchar03,
          cntnts(9).itemqty,
          cntnts(10).dptchar01,
          cntnts(10).dptchar02,
          cntnts(10).dptchar03,
          cntnts(10).itemqty,
          cntnts(11).dptchar01,
          cntnts(11).dptchar02,
          cntnts(11).dptchar03,
          cntnts(11).itemqty,
          cntnts(12).dptchar01,
          cntnts(12).dptchar02,
          cntnts(12).dptchar03,
          cntnts(12).itemqty,
          cntnts(13).dptchar01,
          cntnts(13).dptchar02,
          cntnts(13).dptchar03,
          cntnts(13).itemqty,
          cntnts(14).dptchar01,
          cntnts(14).dptchar02,
          cntnts(14).dptchar03,
          cntnts(14).itemqty,
          in_oh.shipto_master)
      returning rowid into l_rowid;

      insert into caselabels_temp
         (orderid,
          shipid,
          custid,
          item,
          lotnumber,
          lpid,
          seq,
          seqof,
          quantity,
          labeltype,
          barcodetype,
          auxrowid,
          matched)
      values
         (in_oh.orderid,
          in_oh.shipid,
          in_oh.custid,
          io_aux.item,
          io_aux.lotnumber,
          io_aux.lpid,
          io_aux.seq,
          io_aux.seqof,
          io_aux.quantity,
          l_labeltype,
          l_barcodetype,
          l_rowid,
          'N');
   end if;
exception when others then
  zut.prt(sqlcode|| ' '|| sqlerrm);

end add_label;


procedure match_labels
   (in_orderid in number,
    in_shipid  in number,
    out_stmt   out varchar2)
is
   l_match varchar2(1);
   l_cnt pls_integer;
   cntCombined pls_integer;
begin
   out_stmt := null;

   select count(1) into cntCombined
      from caselabels
      where orderid = in_orderid
        and shipid = in_shipid
        and labeltype = 'CS'
        and nvl(combined,'N') = 'Y';

-- match caselabels with temp ignoring barcode
   for lbl in (select * from caselabels
                  where orderid = in_orderid
                    and shipid = in_shipid) loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop
         if cntCombined = 0 then
            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
            and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
            and nvl(tmp.seq,0) = nvl(lbl.seq,0)
            and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
            and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
            and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then

               l_match := 'Y';
               update caselabels_temp
                  set matched = l_match
                  where rowid = tmp.rowid;
               exit;
            end if;
         else
            if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
            and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
            and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
            and nvl(tmp.item,'?') = nvl(lbl.item,'?')
            and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
            and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
            and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
            and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then
               l_match := 'Y';
               update caselabels_temp
                  set matched = l_match
                  where rowid = tmp.rowid;
               exit;
            end if;
         end if;
      end loop;

      if l_match = 'N' then
         out_stmt := 'OKAY';
         exit;
      end if;
   end loop;

-- each caselabel is also in temp, check for extras in temp
   if out_stmt is null then
      select count(1) into l_cnt
         from caselabels_temp
         where matched = 'N';
      if l_cnt > 0 then
         out_stmt := 'OKAY';
      end if;
   end if;

   if out_stmt is null then
      out_stmt := '9 Nothing for order';
   end if;

end match_labels;


procedure merge_labels
   (in_oh    in orderhdr%rowtype,
    in_aux   in auxdata,
    out_stmt out varchar2)
is
   cursor c_alt(p_rowid varchar2) is
      select *
         from ucc_standard_labels_temp
         where rowid = chartorowid(p_rowid);
   alt c_alt%rowtype;
   l_match varchar2(1);
   l_sscc varchar2(20);
   l_ssccfmt varchar2(40);
   l_cnt integer;
begin
-- mark matches between caselabel and temp
   for lbl in (select rowid, caselabels.* from caselabels
                  where orderid = in_oh.orderid
                    and shipid = in_oh.shipid) loop

      l_match := 'N';
      for tmp in (select rowid, caselabels_temp.* from caselabels_temp
                     where matched = 'N') loop

         if nvl(tmp.orderid,0) = nvl(lbl.orderid,0)
         and nvl(tmp.shipid,0) = nvl(lbl.shipid,0)
         and nvl(tmp.custid,'?') = nvl(lbl.custid,'?')
         and nvl(tmp.item,'?') = nvl(lbl.item,'?')
         and nvl(tmp.lotnumber,'?') = nvl(lbl.lotnumber,'?')
         and nvl(tmp.lpid,'?') = nvl(lbl.lpid,'?')
         and nvl(tmp.seq,0) = nvl(lbl.seq,0)
         and nvl(tmp.seqof,0) = nvl(lbl.seqof,0)
         and nvl(tmp.quantity,0) = nvl(lbl.quantity,0)
         and nvl(tmp.labeltype,'?') = nvl(lbl.labeltype,'?') then

            l_match := 'Y';
            update caselabels_temp
               set matched = l_match
               where rowid = tmp.rowid;
            exit;
         end if;
      end loop;

      update caselabels
         set matched = l_match
         where rowid = lbl.rowid;
   end loop;

-- delete unmatched old data
   delete ucc_standard_labels
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid
        and sscc in (select barcode from caselabels
                     where orderid = in_oh.orderid
                       and shipid = in_oh.shipid
                       and matched = 'N');
   delete caselabels
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid
        and matched = 'N';

-- add new data
   update ucc_standard_labels
      set changed = 'N'
      where orderid = in_oh.orderid
        and shipid = in_oh.shipid;

   for tmp in (select * from caselabels_temp
                  where matched = 'N') loop

      open c_alt(tmp.auxrowid);
      fetch c_alt into alt;
      close c_alt;

      if in_aux.sscctype = '18' then
         if hardcoded_manucc is not null then
            l_sscc := zlbl.caselabel_barcode_var_manucc(tmp.custid, tmp.barcodetype, hardcoded_manucc);
            if length(hardcoded_manucc) = 9 then
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ????????? ??????? ?');
            else
               l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
            end if;
         else
            l_sscc := zlbl.caselabel_barcode(tmp.custid, tmp.barcodetype);
            l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
         end if;
      else
         l_sscc := sscc14_barcode(tmp.custid, tmp.barcodetype, in_oh);
         l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ??????? ????????? ?');
      end if;

      if lower(substr(in_aux.changeproc, instr(in_aux.changeproc, '.')+1))
         in ('shopko', 'walmart') then
            l_sscc := '10'||alt.dtlpasschar01;
            l_ssccfmt := zlbl.format_string(l_sscc, '(??) ? ???????? ???????? ?');
      end if;
      if in_aux.sscctype = '14' or
         in_aux.sscctype = 'D1' then
         select count(1) into l_cnt
            from caselabels
            where barcode = l_sscc;
         if l_cnt > 0 then
            delete from caselabels where barcode = l_sscc;
         end if;
      end if;


      insert into caselabels
         (orderid,
          shipid,
          custid,
          item,
          lotnumber,
          lpid,
          barcode,
          seq,
          seqof,
          created,
          auxtable,
          auxkey,
          quantity,
          labeltype,
          changeproc)
      values
         (tmp.orderid,
          tmp.shipid,
          tmp.custid,
          tmp.item,
          tmp.lotnumber,
          tmp.lpid,
          l_sscc,
          tmp.seq,
          tmp.seqof,
          sysdate,
          'ucc_standard_labels',
          'sscc',
          tmp.quantity,
          tmp.labeltype,
          in_aux.changeproc);

      insert into ucc_standard_labels
         (sscc,
          ssccfmt,
          lpid,
          picktolp,
          orderid,
          shipid,
          loadno,
          wave,
          item,
          itemdescr,
          quantity,
          weight,
          seq,
          seqof,
          lbltype,
          created,
          shiptoname,
          shiptocontact,
          shiptoaddr1,
          shiptoaddr2,
          shiptocity,
          shiptostate,
          shiptozip,
          shiptocountrycode,
          fromfacility,
          fromaddr1,
          fromaddr2,
          fromcity,
          fromstate,
          fromzip,
          shipfromcountrycode,
          pro,
          bol,
          po,
          reference,
          carriername,
          scac,
          lotnumber,
          shippingtype,
          custid,
          facility,
          hdrpasschar01,
          hdrpasschar02,
          hdrpasschar03,
          hdrpasschar04,
          hdrpasschar05,
          hdrpasschar06,
          hdrpasschar07,
          hdrpasschar08,
          hdrpasschar09,
          hdrpasschar10,
          hdrpasschar11,
          hdrpasschar12,
          hdrpasschar13,
          hdrpasschar14,
          hdrpasschar15,
          hdrpasschar16,
          hdrpasschar17,
          hdrpasschar18,
          hdrpasschar19,
          hdrpasschar20,
          hdrpasschar21,
          hdrpasschar22,
          hdrpasschar23,
          hdrpasschar24,
          hdrpasschar25,
          hdrpasschar26,
          hdrpasschar27,
          hdrpasschar28,
          hdrpasschar29,
          hdrpasschar30,
          hdrpasschar31,
          hdrpasschar32,
          hdrpasschar33,
          hdrpasschar34,
          hdrpasschar35,
          hdrpasschar36,
          hdrpasschar37,
          hdrpasschar38,
          hdrpasschar39,
          hdrpasschar40,
          hdrpasschar41,
          hdrpasschar42,
          hdrpasschar43,
          hdrpasschar44,
          hdrpasschar45,
          hdrpasschar46,
          hdrpasschar47,
          hdrpasschar48,
          hdrpasschar49,
          hdrpasschar50,
          hdrpasschar51,
          hdrpasschar52,
          hdrpasschar53,
          hdrpasschar54,
          hdrpasschar55,
          hdrpasschar56,
          hdrpasschar57,
          hdrpasschar58,
          hdrpasschar59,
          hdrpasschar60,
          hdrpassnum01,
          hdrpassnum02,
          hdrpassnum03,
          hdrpassnum04,
          hdrpassnum05,
          hdrpassnum06,
          hdrpassnum07,
          hdrpassnum08,
          hdrpassnum09,
          hdrpassnum10,
          hdrpassdate01,
          hdrpassdate02,
          hdrpassdate03,
          hdrpassdate04,
          hdrpassdoll01,
          hdrpassdoll02,
          dtlpasschar01,
          dtlpasschar02,
          dtlpasschar03,
          dtlpasschar04,
          dtlpasschar05,
          dtlpasschar06,
          dtlpasschar07,
          dtlpasschar08,
          dtlpasschar09,
          dtlpasschar10,
          dtlpasschar11,
          dtlpasschar12,
          dtlpasschar13,
          dtlpasschar14,
          dtlpasschar15,
          dtlpasschar16,
          dtlpasschar17,
          dtlpasschar18,
          dtlpasschar19,
          dtlpasschar20,
          dtlpasschar21,
          dtlpasschar22,
          dtlpasschar23,
          dtlpasschar24,
          dtlpasschar25,
          dtlpasschar26,
          dtlpasschar27,
          dtlpasschar28,
          dtlpasschar29,
          dtlpasschar30,
          dtlpasschar31,
          dtlpasschar32,
          dtlpasschar33,
          dtlpasschar34,
          dtlpasschar35,
          dtlpasschar36,
          dtlpasschar37,
          dtlpasschar38,
          dtlpasschar39,
          dtlpasschar40,
          dtlpassnum01,
          dtlpassnum02,
          dtlpassnum03,
          dtlpassnum04,
          dtlpassnum05,
          dtlpassnum06,
          dtlpassnum07,
          dtlpassnum08,
          dtlpassnum09,
          dtlpassnum10,
          dtlpassnum11,
          dtlpassnum12,
          dtlpassnum13,
          dtlpassnum14,
          dtlpassnum15,
          dtlpassnum16,
          dtlpassnum17,
          dtlpassnum18,
          dtlpassnum19,
          dtlpassnum20,
          dtlpassdate01,
          dtlpassdate02,
          dtlpassdate03,
          dtlpassdate04,
          dtlpassdoll01,
          dtlpassdoll02,
          itmpasschar01,
          itmpasschar02,
          itmpasschar03,
          itmpasschar04,
          itmpassnum01,
          itmpassnum02,
          itmpassnum03,
          itmpassnum04,
          consigneesku,
          upc,
          zipcodebar,
          zipcodehuman,
          storebarcode,
          storehuman,
          vendorbar,
          vendorhuman,
          shiptocsz,
          shipfromcsz,
          changed,
          lbltypedesc,
          part,
          shipto,
          color,
          customeritem,
          department,
          division,
          itemsize,
          makrforstate,
          markforaddr1,
          markforaddr2,
          markforcity,
          markforcountrycode,
          markforname,
          markforstate,
          markforzip,
          storenum,
          style,
          vendoritem,
          dptchar01_01,
          dptchar02_01,
          dptchar03_01,
          itemqty_01,
          dptchar01_02,
          dptchar02_02,
          dptchar03_02,
          itemqty_02,
          dptchar01_03,
          dptchar02_03,
          dptchar03_03,
          itemqty_03,
          dptchar01_04,
          dptchar02_04,
          dptchar03_04,
          itemqty_04,
          dptchar01_05,
          dptchar02_05,
          dptchar03_05,
          itemqty_05,
          dptchar01_06,
          dptchar02_06,
          dptchar03_06,
          itemqty_06,
          dptchar01_07,
          dptchar02_07,
          dptchar03_07,
          itemqty_07,
          dptchar01_08,
          dptchar02_08,
          dptchar03_08,
          itemqty_08,
          dptchar01_09,
          dptchar02_09,
          dptchar03_09,
          itemqty_09,
          dptchar01_10,
          dptchar02_10,
          dptchar03_10,
          itemqty_10,
          dptchar01_11,
          dptchar02_11,
          dptchar03_11,
          itemqty_11,
          dptchar01_12,
          dptchar02_12,
          dptchar03_12,
          itemqty_12,
          dptchar01_13,
          dptchar02_13,
          dptchar03_13,
          itemqty_13,
          dptchar01_14,
          dptchar02_14,
          dptchar03_14,
          itemqty_14,
          shipto_master)
      values
         (l_sscc,
          l_ssccfmt,
          alt.lpid,
          alt.picktolp,
          alt.orderid,
          alt.shipid,
          alt.loadno,
          alt.wave,
          alt.item,
          alt.itemdescr,
          alt.quantity,
          alt.weight,
          alt.seq,
          alt.seqof,
          alt.lbltype,
          sysdate,
          alt.shiptoname,
          alt.shiptocontact,
          alt.shiptoaddr1,
          alt.shiptoaddr2,
          alt.shiptocity,
          alt.shiptostate,
          alt.shiptozip,
          alt.shiptocountrycode,
          alt.fromfacility,
          alt.fromaddr1,
          alt.fromaddr2,
          alt.fromcity,
          alt.fromstate,
          alt.fromzip,
          alt.shipfromcountrycode,
          alt.pro,
          alt.bol,
          alt.po,
          alt.reference,
          alt.carriername,
          alt.scac,
          alt.lotnumber,
          alt.shippingtype,
          alt.custid,
          alt.facility,
          alt.hdrpasschar01,
          alt.hdrpasschar02,
          alt.hdrpasschar03,
          alt.hdrpasschar04,
          alt.hdrpasschar05,
          alt.hdrpasschar06,
          alt.hdrpasschar07,
          alt.hdrpasschar08,
          alt.hdrpasschar09,
          alt.hdrpasschar10,
          alt.hdrpasschar11,
          alt.hdrpasschar12,
          alt.hdrpasschar13,
          alt.hdrpasschar14,
          alt.hdrpasschar15,
          alt.hdrpasschar16,
          alt.hdrpasschar17,
          alt.hdrpasschar18,
          alt.hdrpasschar19,
          alt.hdrpasschar20,
          alt.hdrpasschar21,
          alt.hdrpasschar22,
          alt.hdrpasschar23,
          alt.hdrpasschar24,
          alt.hdrpasschar25,
          alt.hdrpasschar26,
          alt.hdrpasschar27,
          alt.hdrpasschar28,
          alt.hdrpasschar29,
          alt.hdrpasschar30,
          alt.hdrpasschar31,
          alt.hdrpasschar32,
          alt.hdrpasschar33,
          alt.hdrpasschar34,
          alt.hdrpasschar35,
          alt.hdrpasschar36,
          alt.hdrpasschar37,
          alt.hdrpasschar38,
          alt.hdrpasschar39,
          alt.hdrpasschar40,
          alt.hdrpasschar41,
          alt.hdrpasschar42,
          alt.hdrpasschar43,
          alt.hdrpasschar44,
          alt.hdrpasschar45,
          alt.hdrpasschar46,
          alt.hdrpasschar47,
          alt.hdrpasschar48,
          alt.hdrpasschar49,
          alt.hdrpasschar50,
          alt.hdrpasschar51,
          alt.hdrpasschar52,
          alt.hdrpasschar53,
          alt.hdrpasschar54,
          alt.hdrpasschar55,
          alt.hdrpasschar56,
          alt.hdrpasschar57,
          alt.hdrpasschar58,
          alt.hdrpasschar59,
          alt.hdrpasschar60,
          alt.hdrpassnum01,
          alt.hdrpassnum02,
          alt.hdrpassnum03,
          alt.hdrpassnum04,
          alt.hdrpassnum05,
          alt.hdrpassnum06,
          alt.hdrpassnum07,
          alt.hdrpassnum08,
          alt.hdrpassnum09,
          alt.hdrpassnum10,
          alt.hdrpassdate01,
          alt.hdrpassdate02,
          alt.hdrpassdate03,
          alt.hdrpassdate04,
          alt.hdrpassdoll01,
          alt.hdrpassdoll02,
          alt.dtlpasschar01,
          alt.dtlpasschar02,
          alt.dtlpasschar03,
          alt.dtlpasschar04,
          alt.dtlpasschar05,
          alt.dtlpasschar06,
          alt.dtlpasschar07,
          alt.dtlpasschar08,
          alt.dtlpasschar09,
          alt.dtlpasschar10,
          alt.dtlpasschar11,
          alt.dtlpasschar12,
          alt.dtlpasschar13,
          alt.dtlpasschar14,
          alt.dtlpasschar15,
          alt.dtlpasschar16,
          alt.dtlpasschar17,
          alt.dtlpasschar18,
          alt.dtlpasschar19,
          alt.dtlpasschar20,
          alt.dtlpasschar21,
          alt.dtlpasschar22,
          alt.dtlpasschar23,
          alt.dtlpasschar24,
          alt.dtlpasschar25,
          alt.dtlpasschar26,
          alt.dtlpasschar27,
          alt.dtlpasschar28,
          alt.dtlpasschar29,
          alt.dtlpasschar30,
          alt.dtlpasschar31,
          alt.dtlpasschar32,
          alt.dtlpasschar33,
          alt.dtlpasschar34,
          alt.dtlpasschar35,
          alt.dtlpasschar36,
          alt.dtlpasschar37,
          alt.dtlpasschar38,
          alt.dtlpasschar39,
          alt.dtlpasschar40,
          alt.dtlpassnum01,
          alt.dtlpassnum02,
          alt.dtlpassnum03,
          alt.dtlpassnum04,
          alt.dtlpassnum05,
          alt.dtlpassnum06,
          alt.dtlpassnum07,
          alt.dtlpassnum08,
          alt.dtlpassnum09,
          alt.dtlpassnum10,
          alt.dtlpassnum11,
          alt.dtlpassnum12,
          alt.dtlpassnum13,
          alt.dtlpassnum14,
          alt.dtlpassnum15,
          alt.dtlpassnum16,
          alt.dtlpassnum17,
          alt.dtlpassnum18,
          alt.dtlpassnum19,
          alt.dtlpassnum20,
          alt.dtlpassdate01,
          alt.dtlpassdate02,
          alt.dtlpassdate03,
          alt.dtlpassdate04,
          alt.dtlpassdoll01,
          alt.dtlpassdoll02,
          alt.itmpasschar01,
          alt.itmpasschar02,
          alt.itmpasschar03,
          alt.itmpasschar04,
          alt.itmpassnum01,
          alt.itmpassnum02,
          alt.itmpassnum03,
          alt.itmpassnum04,
          alt.consigneesku,
          alt.upc,
          alt.zipcodebar,
          alt.zipcodehuman,
          alt.storebarcode,
          alt.storehuman,
          alt.vendorbar,
          alt.vendorhuman,
          alt.shiptocsz,
          alt.shipfromcsz,
          'Y',
          alt.lbltypedesc,
          alt.part,
          alt.shipto,
          alt.color,
          alt.customeritem,
          alt.department,
          alt.division,
          alt.itemsize,
          alt.makrforstate,
          alt.markforaddr1,
          alt.markforaddr2,
          alt.markforcity,
          alt.markforcountrycode,
          alt.markforname,
          alt.markforstate,
          alt.markforzip,
          alt.storenum,
          alt.style,
          alt.vendoritem,
          alt.dptchar01_01,
          alt.dptchar02_01,
          alt.dptchar03_01,
          alt.itemqty_01,
          alt.dptchar01_02,
          alt.dptchar02_02,
          alt.dptchar03_02,
          alt.itemqty_02,
          alt.dptchar01_03,
          alt.dptchar02_03,
          alt.dptchar03_03,
          alt.itemqty_03,
          alt.dptchar01_04,
          alt.dptchar02_04,
          alt.dptchar03_04,
          alt.itemqty_04,
          alt.dptchar01_05,
          alt.dptchar02_05,
          alt.dptchar03_05,
          alt.itemqty_05,
          alt.dptchar01_06,
          alt.dptchar02_06,
          alt.dptchar03_06,
          alt.itemqty_06,
          alt.dptchar01_07,
          alt.dptchar02_07,
          alt.dptchar03_07,
          alt.itemqty_07,
          alt.dptchar01_08,
          alt.dptchar02_08,
          alt.dptchar03_08,
          alt.itemqty_08,
          alt.dptchar01_09,
          alt.dptchar02_09,
          alt.dptchar03_09,
          alt.itemqty_09,
          alt.dptchar01_10,
          alt.dptchar02_10,
          alt.dptchar03_10,
          alt.itemqty_10,
          alt.dptchar01_11,
          alt.dptchar02_11,
          alt.dptchar03_11,
          alt.itemqty_11,
          alt.dptchar01_12,
          alt.dptchar02_12,
          alt.dptchar03_12,
          alt.itemqty_12,
          alt.dptchar01_13,
          alt.dptchar02_13,
          alt.dptchar03_13,
          alt.itemqty_13,
          alt.dptchar01_14,
          alt.dptchar02_14,
          alt.dptchar03_14,
          alt.itemqty_14,
          in_oh.shipto_master);

   end loop;

   out_stmt := 'select L.*'
         || ' from lbl_zucclabels_view L, zseq Z'
         || ' where L.orderid = ' || in_oh.orderid
         || ' and L.shipid = ' || in_oh.shipid
         || ' and L.changed = ''Y'''
         || ' and Z.seq <= ' || duplicate_cnt(in_oh)
         || ' order by L.item, L.seq';

end merge_labels;


procedure shipunit_label
   (in_oh       in orderhdr%rowtype,
    in_action   in varchar2,
    in_lblcount in number,
    io_aux      in out auxdata)
is
   cursor c_od(p_lpid varchar2) is
      select distinct OD.dtlpassthruchar01,
             OD.dtlpassthruchar02,
             OD.dtlpassthruchar03,
             OD.dtlpassthruchar04,
             OD.dtlpassthruchar05,
             OD.dtlpassthruchar06,
             OD.dtlpassthruchar07,
             OD.dtlpassthruchar08,
             OD.dtlpassthruchar09,
             OD.dtlpassthruchar10,
             OD.dtlpassthruchar11,
             OD.dtlpassthruchar12,
             OD.dtlpassthruchar13,
             OD.dtlpassthruchar14,
             OD.dtlpassthruchar15,
             OD.dtlpassthruchar16,
             OD.dtlpassthruchar17,
             OD.dtlpassthruchar18,
             OD.dtlpassthruchar19,
             OD.dtlpassthruchar20,
             OD.dtlpassthruchar21,
             OD.dtlpassthruchar22,
             OD.dtlpassthruchar23,
             OD.dtlpassthruchar24,
             OD.dtlpassthruchar25,
             OD.dtlpassthruchar26,
             OD.dtlpassthruchar27,
             OD.dtlpassthruchar28,
             OD.dtlpassthruchar29,
             OD.dtlpassthruchar30,
             OD.dtlpassthruchar31,
             OD.dtlpassthruchar32,
             OD.dtlpassthruchar33,
             OD.dtlpassthruchar34,
             OD.dtlpassthruchar35,
             OD.dtlpassthruchar36,
             OD.dtlpassthruchar37,
             OD.dtlpassthruchar38,
             OD.dtlpassthruchar39,
             OD.dtlpassthruchar40,
             OD.dtlpassthrunum01,
             OD.dtlpassthrunum02,
             OD.dtlpassthrunum03,
             OD.dtlpassthrunum04,
             OD.dtlpassthrunum05,
             OD.dtlpassthrunum06,
             OD.dtlpassthrunum07,
             OD.dtlpassthrunum08,
             OD.dtlpassthrunum09,
             OD.dtlpassthrunum10,
             OD.dtlpassthrunum11,
             OD.dtlpassthrunum12,
             OD.dtlpassthrunum13,
             OD.dtlpassthrunum14,
             OD.dtlpassthrunum15,
             OD.dtlpassthrunum16,
             OD.dtlpassthrunum17,
             OD.dtlpassthrunum18,
             OD.dtlpassthrunum19,
             OD.dtlpassthrunum20,
             OD.dtlpassthrudate01,
             OD.dtlpassthrudate02,
             OD.dtlpassthrudate03,
             OD.dtlpassthrudate04,
             OD.dtlpassthrudoll01,
             OD.dtlpassthrudoll02,
             OD.consigneesku,
             CIA.itemalias upc
         from custitemalias CIA, orderdtl OD, shippingplate SP
         where OD.orderid = SP.orderid
           and OD.shipid = SP.shipid
           and OD.item = SP.orderitem
           and nvl(OD.lotnumber, '(none)') = nvl(SP.orderlot, '(none)')
           and CIA.item(+) = od.item
           and CIA.custid(+) = in_oh.custid
           and CIA.aliasdesc(+) like 'UPC%'
           and SP.lpid in (select lpid from shippingplate
                              where type in ('F','P')
                              start with lpid = p_lpid
                              connect by prior lpid = parentlpid);

   cursor c_sp(p_lpid varchar2) is
      select distinct item, lotnumber
         from shippingplate
         where type in ('F','P')
         start with lpid = p_lpid
         connect by prior lpid = parentlpid
         order by item;

   l_od dtlpassthru := null;
   l_cnt pls_integer := 0;
   l_lblcount pls_integer := in_lblcount;
   l_quantity ucc_standard_labels.quantity%type := io_aux.quantity;
   l_weight ucc_standard_labels.weight%type := io_aux.weight;
   l_plqty shippingplate.quantity%type := io_aux.quantity / in_lblcount;
   l_plwt shippingplate.weight%type := io_aux.weight / in_lblcount;
begin

   for od in c_od(io_aux.lpid) loop -- determine whether multiple orderdtl rows
      l_od := od;
      l_cnt := l_cnt + 1;
      exit when l_cnt > 1;
   end loop;

   if l_cnt > 1 then
      l_od := null;
   else
      for sp in c_sp(io_aux.lpid) loop -- determine if multiple lotnumbers
         if c_sp%rowcount = 1 then
            io_aux.item := sp.item;
            io_aux.lotnumber := sp.lotnumber;
         else
            io_aux.lotnumber := null;
            exit;
         end if;
      end loop;
   end if;

   while (l_lblcount > 0) loop
      io_aux.quantity := least(l_quantity, l_plqty);
      io_aux.weight := least(l_weight, l_plwt);

      add_label(in_oh, l_od, in_action, 'S', null, io_aux);

      l_quantity := l_quantity - io_aux.quantity;
      l_weight := l_weight - io_aux.weight;
      l_lblcount := l_lblcount - 1;
   end loop;

end shipunit_label;


procedure case_label
   (in_oh     in orderhdr%rowtype,
    in_action in varchar2,
    io_aux    in out auxdata)
is
   cursor c_od(p_orderid number, p_shipid number, p_orderitem varchar2,
               p_orderlot varchar2, p_custid varchar2) is
      select dtlpassthruchar01,
             dtlpassthruchar02,
             dtlpassthruchar03,
             dtlpassthruchar04,
             dtlpassthruchar05,
             dtlpassthruchar06,
             dtlpassthruchar07,
             dtlpassthruchar08,
             dtlpassthruchar09,
             dtlpassthruchar10,
             dtlpassthruchar11,
             dtlpassthruchar12,
             dtlpassthruchar13,
             dtlpassthruchar14,
             dtlpassthruchar15,
             dtlpassthruchar16,
             dtlpassthruchar17,
             dtlpassthruchar18,
             dtlpassthruchar19,
             dtlpassthruchar20,
             dtlpassthruchar21,
             dtlpassthruchar22,
             dtlpassthruchar23,
             dtlpassthruchar24,
             dtlpassthruchar25,
             dtlpassthruchar26,
             dtlpassthruchar27,
             dtlpassthruchar28,
             dtlpassthruchar29,
             dtlpassthruchar30,
             dtlpassthruchar31,
             dtlpassthruchar32,
             dtlpassthruchar33,
             dtlpassthruchar34,
             dtlpassthruchar35,
             dtlpassthruchar36,
             dtlpassthruchar37,
             dtlpassthruchar38,
             dtlpassthruchar39,
             dtlpassthruchar40,
             dtlpassthrunum01,
             dtlpassthrunum02,
             dtlpassthrunum03,
             dtlpassthrunum04,
             dtlpassthrunum05,
             dtlpassthrunum06,
             dtlpassthrunum07,
             dtlpassthrunum08,
             dtlpassthrunum09,
             dtlpassthrunum10,
             dtlpassthrunum11,
             dtlpassthrunum12,
             dtlpassthrunum13,
             dtlpassthrunum14,
             dtlpassthrunum15,
             dtlpassthrunum16,
             dtlpassthrunum17,
             dtlpassthrunum18,
             dtlpassthrunum19,
             dtlpassthrunum20,
             dtlpassthrudate01,
             dtlpassthrudate02,
             dtlpassthrudate03,
             dtlpassthrudate04,
             dtlpassthrudoll01,
             dtlpassthrudoll02,
             consigneesku,
             itemalias
         from orderdtl od, custitemalias cia
         where od.orderid = p_orderid
           and od.shipid = p_shipid
           and od.item = p_orderitem
           and nvl(lotnumber, '(none)') = nvl(p_orderlot, '(none)')
           and cia.item(+) = od.item
           and cia.custid(+) = p_custid
           and cia.aliasdesc(+) like 'UPC%';

   od dtlpassthru;
   l_csqty shippingplate.quantity%type;
   l_cswt shippingplate.weight%type;
   l_cnt pls_integer;
   l_part varchar2(4);
begin

   for sp in (select custid, item, unitofmeasure, lotnumber, orderitem, orderlot,
                  sum(quantity) as quantity, sum(nvl(weight,0)) as weight
                  from shippingplate
                  where type in ('F','P')
                    and orderid = in_oh.orderid
                    and shipid = in_oh.shipid
                  start with lpid = io_aux.lpid
                  connect by prior lpid = parentlpid
                  group by custid, item, unitofmeasure, lotnumber, orderitem, orderlot
                  order by item, lotnumber, orderitem, orderlot) loop
      --zut.prt(sp.custid || ' 1 ' ||sp.item || ' 2 ' ||sp.unitofmeasure || ' 3 ' ||sp.lotnumber ||
      --        ' 4 ' || sp.orderitem || ' 5 ' || sp.orderlot || ' 6 ' || sp.quantity || ' 7 ' || sp.weight);
      l_csqty := zlbl.uom_qty_conv(sp.custid, sp.item, 1, l_cartonsuom, sp.unitofmeasure);

      --zut.prt('case qty ' || l_csqty || ' ' || l_cartonsuom);
      l_cswt := l_csqty * sp.weight / sp.quantity;
      l_cnt := zlbl.uom_qty_conv(sp.custid, sp.item, sp.quantity, sp.unitofmeasure, l_cartonsuom);

      io_aux.item := sp.item;
      io_aux.lotnumber := sp.lotnumber;
      while (l_cnt > 0) loop
         open c_od(in_oh.orderid, in_oh.shipid, sp.orderitem, sp.orderlot,
              in_oh.custid);
         fetch c_od into od;
         close c_od;

         io_aux.quantity := least(sp.quantity, l_csqty);
         io_aux.weight := least(sp.weight, l_cswt);
         if io_aux.quantity = l_csqty then
            l_part := null;
         else
            l_part := 'PART';
         end if;
         add_label(in_oh, od, in_action, 'C', l_part, io_aux);

         sp.quantity := sp.quantity - io_aux.quantity;
         sp.weight := sp.weight - io_aux.weight;
         l_cnt := l_cnt - 1;
      end loop;
   end loop;

end case_label;


procedure ctn_group
   (in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    in out varchar2)
is
   l_aux auxdata;
   l_consolidated char(1);
begin

   if out_stmt is not null and
      out_stmt != 'Continue' then
      hardcoded_manucc := out_stmt;
   else
      if  in_procname in ('bbbsgfoo', 'jockeysgfoo','boscovssgfoo', 'bontonsgfoo', 'kgsgfoo','basspro') then
         if in_oh.hdrpassthruchar16 is not null then     -- sgfootware bbb label manufacturer number
            hardcoded_manucc := in_oh.hdrpassthruchar16; -- is on an order by order basis. Stored in
         else                                            -- hdrpassthruchar16
            hardcoded_manucc := '000090464';
         end if;
      else
         hardcoded_manucc := null;
      end if;
   end if;
   init_lblgroup(in_oh.orderid, in_oh.shipid, in_sscctype, in_procname, in_action, 'ctn', l_aux);
   select nvl(consolidated,'N') into l_consolidated
      from waves
      where wave = (select wave
                       from orderhdr
                       where orderid = in_oh.orderid
                         and shipid = in_oh.shipid);
   if l_consolidated = 'Y' then
      for pp in (select lpid, type, fromlpid, quantity, weight, item
                  from shippingplate
                  where lpid in (select distinct parentlpid
                                  from shippingplate
                                  where orderid = in_oh.orderid
                                    and shipid = in_oh.shipid)) loop
         l_aux.lpid := pp.lpid;
         l_aux.picktolp := pp.fromlpid;
         l_aux.shippingtype := pp.type;
         if pp.type = 'C' then
            l_aux.quantity := pp.quantity;
            l_aux.weight := pp.weight;
            l_aux.item := pp.item;
            l_aux.pptype := 'C';
            shipunit_label(in_oh, in_action, 1, l_aux);
         else
            l_aux.pptype := 'X';
            case_label(in_oh, in_action, l_aux);
         end if;
      end loop;
   else
      for pp in (select lpid, type, fromlpid, quantity, weight, item
                  from shippingplate
                  where orderid = in_oh.orderid
                    and shipid = in_oh.shipid
                    and parentlpid is null
                  order by lpid) loop
         --zut.prt(pp.lpid || ' ' || pp.type || ' ' || pp.fromlpid || ' ' || pp.quantity || ' ' || pp.weight || ' ' || pp.item);
         l_aux.lpid := pp.lpid;
         l_aux.picktolp := pp.fromlpid;
         l_aux.shippingtype := pp.type;
         if pp.type = 'C' then
            l_aux.quantity := pp.quantity;
            l_aux.weight := pp.weight;
            l_aux.item := pp.item;
            l_aux.pptype := 'C';
            shipunit_label(in_oh, in_action, 1, l_aux);
         else
            l_aux.pptype := 'X';
            case_label(in_oh, in_action, l_aux);
         end if;
      end loop;
   end if;

   if in_action = 'A' then
      if in_procname = 'filtersscccntnt' then
         out_stmt := 'select L.*'
               || ' from lbl_zucccntnts_view L, zseq Z'
               || ' where L.orderid = ' || in_oh.orderid
               || ' and L.shipid = ' || in_oh.shipid
               || ' and Z.seq <= ' || duplicate_cnt(in_oh)
               || ' order by L.item, L.seq';
      else
         out_stmt := 'select L.*'
            || ' from lbl_zucclabels_view L, zseq Z'
            || ' where L.orderid = ' || in_oh.orderid
            || ' and L.shipid = ' || in_oh.shipid
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
      end if;
   elsif in_func = 'Q' then
      match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ctn_group;

procedure ccp_group
   (in_oh       in orderhdr%rowtype,
    in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    out varchar2)
is
   l_aux auxdata;
begin

   hardcoded_manucc := null;

   init_lblgroup(in_oh.orderid, in_oh.shipid, in_sscctype, in_procname, in_action, 'ccp', l_aux);

   for pp in (select lpid, type, item, fromlpid, quantity, weight
               from shippingplate
               where orderid = in_oh.orderid
                 and shipid = in_oh.shipid
                 and parentlpid is null
               order by lpid) loop
      l_aux.lpid := pp.lpid;
      l_aux.picktolp := pp.fromlpid;
      l_aux.shippingtype := pp.type;
      l_aux.quantity := pp.quantity;
      l_aux.weight := pp.weight;
      l_aux.item := pp.item;
      l_aux.pptype := 'X';
      shipunit_label(in_oh, in_action, 1, l_aux);
   end loop;

   if in_action = 'A' then
      out_stmt := 'select L.*'
            || ' from lbl_zucclabels_view L, zseq Z'
            || ' where L.orderid = ' || in_oh.orderid
            || ' and L.shipid = ' || in_oh.shipid
            || ' and Z.seq <= ' || duplicate_cnt(in_oh)
            || ' order by L.item, L.seq';
   elsif in_func = 'Q' then
      match_labels(in_oh.orderid, in_oh.shipid, out_stmt);
   else
      merge_labels(in_oh, l_aux, out_stmt);
   end if;
   commit;

end ccp_group;

procedure cons_ctn_check
   (in_sscctype in varchar2,
    in_procname in varchar2,
    in_func     in varchar2,
    in_action   in varchar2,
    out_stmt    in out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   l_oh orderhdr%rowtype;
begin
   for i in 1..ord_tbl.count loop
      open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
      fetch c_oh into l_oh;
      close c_oh;
      ctn_group(l_oh, in_sscctype, in_procname, in_func, in_action, out_stmt);
      if out_stmt = 'OKAY' then
         exit;
      end if;
      out_stmt := 'Continue';
   end loop;
end cons_ctn_check;


-- Public


procedure targetstores
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0088990', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'targetstores', in_func, in_action, out_stmt);
      else
        ctn_group(l_oh, '18', 'targetstores', in_func, in_action, out_stmt);
     end if;
   end if;

end targetstores;


procedure shopko
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0005000', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'shopko', in_func, in_action, out_stmt);
      else
        ctn_group(l_oh, '18', 'shopko', in_func, in_action, out_stmt);
      end if;
   end if;

end shopko;


procedure burlingtoncoat
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0023684', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'burlingtoncoat', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'burlingtoncoat', in_func, in_action, out_stmt);
      end if;
   end if;

end burlingtoncoat;

procedure buybuybaby
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '2381611', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'buybuybaby', in_func, in_action, out_stmt);
      else
        ctn_group(l_oh, '18', 'buybuybaby', in_func, in_action, out_stmt);
      end if;

end if;

end buybuybaby;

procedure lwbuybuybaby
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWBBBD2S', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwbuybuybaby', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwbuybuybaby', in_func, in_action, out_stmt);
      end if;

   end if;

end lwbuybuybaby;


procedure targetcom
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0088990', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'targetcom', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'targetcom', in_func, in_action, out_stmt);
      end if;
   end if;

end targetcom;


procedure kohls
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0005895', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'kohls', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'kohls', in_func, in_action, out_stmt);
      end if;
   end if;

end kohls;


procedure macys
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'macys', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'macys', in_func, in_action, out_stmt);
      end if;
   end if;

end macys;


procedure walgreens
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '10485', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'walgreens', in_func, in_action, out_stmt);
   end if;

end walgreens;


procedure walmart
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0097642', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid,0) <> 0 then
         cons_ctn_check('14', 'walmart', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '14', 'walmart', in_func, in_action, out_stmt);
      end if;
   end if;

end walmart;


procedure stagestores
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'stagestores', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'stagestores', in_func, in_action, out_stmt);
      end if;
   end if;

end stagestores;


procedure kmart
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '5084033', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'kmart', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'kmart', in_func, in_action, out_stmt);
      end if;
   end if;

end kmart;


procedure rossstores
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'rossstores', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'rossstores', in_func, in_action, out_stmt);
      end if;
   end if;

end rossstores;


procedure searsroebuck
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0077891', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'searsroebuck', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'searsroebuck', in_func, in_action, out_stmt);
      end if;
   end if;

end searsroebuck;


procedure aafes
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '10579', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'aafes', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'aafes', in_func, in_action, out_stmt);
      end if;
   end if;

end aafes;


procedure mervyns
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0030000', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'mervyns', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'mervyns', in_func, in_action, out_stmt);
      end if;
   end if;

end mervyns;


procedure amazoncom
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0006076', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'amazoncom', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'amazoncom', in_func, in_action, out_stmt);
      end if;
   end if;

end amazoncom;


procedure boscovs
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0019265', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'boscovs', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'boscovs', in_func, in_action, out_stmt);
      end if;
   end if;

end boscovs;


procedure bedbathandbeyond
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0040000', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bedbathandbeyond', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bedbathandbeyond', in_func, in_action, out_stmt);
      end if;
   end if;

end bedbathandbeyond;

procedure jcpenney
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0010000', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'jcpenney', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'jcpenney', in_func, in_action, out_stmt);
      end if;
   end if;

end jcpenney;


procedure cato
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'cato', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'cato', in_func, in_action, out_stmt);
      end if;
   end if;

end cato;


procedure valuecity
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'valuecity', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'valuecity', in_func, in_action, out_stmt);
      end if;
   end if;

end valuecity;


procedure bontonsaks
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bontonsaks', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bontonsaks', in_func, in_action, out_stmt);
      end if;
   end if;

end bontonsaks;

procedure belk
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'belk', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'belk', in_func, in_action, out_stmt);
      end if;
   end if;

end belk;

procedure pamida
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0071994', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'pamida', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'pamida', in_func, in_action, out_stmt);
      end if;
   end if;

end pamida;

procedure stienmart
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'stienmart', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'stienmart', in_func, in_action, out_stmt);
      end if;
   end if;

end stienmart;

procedure peebles
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'peebles', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'peebles', in_func, in_action, out_stmt);
   end if;

end if;

end peebles;

procedure niemanmarcus
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'niemanmarcus', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'niemanmarcus', in_func, in_action, out_stmt);
      end if;
   end if;

end niemanmarcus;

procedure alloy
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'alloy', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'alloy', in_func, in_action, out_stmt);
      end if;
   end if;

end alloy;


procedure anthropologie
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'anthropologie', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'anthropologie', in_func, in_action, out_stmt);
      end if;
   end if;

end anthropologie;

procedure charmingshops
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'charmingshops', in_func, in_action, out_stmt);
      else
        ctn_group(l_oh, '18', 'charmingshops', in_func, in_action, out_stmt);
      end if;
   end if;

end charmingshops;

procedure cititrends
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'cititrends', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'cititrends', in_func, in_action, out_stmt);
      end if;
   end if;

end cititrends;

procedure filinesbasement
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'filinesbasement', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'filinesbasement', in_func, in_action, out_stmt);
      end if;
   end if;

end filinesbasement;

procedure bobsstores
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bobsstores', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bobsstores', in_func, in_action, out_stmt);
      end if;
   end if;

end bobsstores;

procedure forever21
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'forrever21', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'forrever21', in_func, in_action, out_stmt);
      end if;
   end if;

end forever21;

procedure glicks
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'glicks', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'glicks', in_func, in_action, out_stmt);
      end if;
   end if;

end glicks;

procedure gordmans
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'gordmans', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'gordmans', in_func, in_action, out_stmt);
      end if;
   end if;

end gordmans;

procedure internationalmail
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'internationalmail', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'internationalmail', in_func, in_action, out_stmt);
      end if;
   end if;

end internationalmail;

procedure maurices
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'maurices', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'maurices', in_func, in_action, out_stmt);
      end if;
   end if;

end maurices;

procedure number7
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'number7', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'number7', in_func, in_action, out_stmt);
      end if;
   end if;

end number7;

procedure gabrialbrothers
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0005422', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'gabrialbrothers', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'gabrialbrothers', in_func, in_action, out_stmt);
      end if;
   end if;

end gabrialbrothers;

procedure rainbow
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '7807329', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'rainbow', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'rainbow', in_func, in_action, out_stmt);
      end if;
   end if;

end rainbow;

procedure hamricks
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'hamricks', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'hamricks', in_func, in_action, out_stmt);
      end if;
   end if;

end hamricks;

procedure olympia
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'olympia', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'olympia', in_func, in_action, out_stmt);
      end if;
   end if;

end olympia;

procedure dunhams
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'dunhams', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'dunhams', in_func, in_action, out_stmt);
      end if;
   end if;

end dunhams;

procedure gottshalks
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'gottshalks', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'gottshalks', in_func, in_action, out_stmt);
      end if;
   end if;

end gottshalks;

procedure modells
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'modells', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'modells', in_func, in_action, out_stmt);
      end if;
   end if;

end modells;

procedure nordstroms
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'nordstroms', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'nordstroms', in_func, in_action, out_stmt);
      end if;
   end if;

end nordstroms;

procedure lanebryant
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lanebryant', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lanebryant', in_func, in_action, out_stmt);
      end if;
   end if;

end lanebryant;

procedure dawahares
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'dawahares', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'dawahares', in_func, in_action, out_stmt);
      end if;
   end if;

end dawahares;

procedure winners
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0005521', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'winners', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'winners', in_func, in_action, out_stmt);
      end if;
   end if;

end winners;

procedure kaybee
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0051365', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'kaybee', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'kaybee', in_func, in_action, out_stmt);
      end if;
   end if;

end kaybee;

procedure formanmills
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '4183943', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'formanmills', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'formanmills', in_func, in_action, out_stmt);
      end if;
   end if;

end formanmills;

procedure fredmeyer
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0077284', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'fredmeyer', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'fredmeyer', in_func, in_action, out_stmt);
      end if;
   end if;

end fredmeyer;

procedure rue21
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'rue21', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'rue21', in_func, in_action, out_stmt);
      end if;
   end if;

end rue21;

procedure tjmaxx
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0060202', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'tjmaxx', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'tjmaxx', in_func, in_action, out_stmt);
      end if;
   end if;

end tjmaxx;

procedure marshalls
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0060202', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'marshalls', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'marshalls', in_func, in_action, out_stmt);
      end if;
   end if;

end marshalls;

procedure toysrus
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0096282', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'toysrus', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'toysrus', in_func, in_action, out_stmt);
      end if;
   end if;

end toysrus;

procedure toysruscanada
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '9174217', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'toysruscanada', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'toysruscanada', in_func, in_action, out_stmt);
      end if;
   end if;

end toysruscanada;

procedure vonmaur
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, null, null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'vonmaur', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'vonmaur', in_func, in_action, out_stmt);
      end if;
   end if;

end vonmaur;

procedure bealls
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0701425', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bealls', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bealls', in_func, in_action, out_stmt);
      end if;
   end if;

end bealls;

procedure genericucc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LABELPRINT', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'genericucc', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'genericucc', in_func, in_action, out_stmt);
      end if;
   end if;

end genericucc;

procedure amazongen
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWAMZ.GEN', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'amazongen', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'amazongen', in_func, in_action, out_stmt);
      end if;
   end if;

end amazongen;

procedure lwkmart
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWKMART', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwkmart', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwkmart', in_func, in_action, out_stmt);
      end if;
   end if;

end lwkmart;

procedure lwaafes
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWAAFES', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwaafes', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwaafes', in_func, in_action, out_stmt);
      end if;
   end if;

end lwaafes;

procedure lwbestbuy
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWBSTBY', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwbestbuy', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwbestbuy', in_func, in_action, out_stmt);
      end if;
   end if;

end lwbestbuy;

procedure lwfingerhut
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWFNGHT', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwfingerhut', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwfingerhut', in_func, in_action, out_stmt);
      end if;
   end if;

end lwfingerhut;

procedure lwsears
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWDT2ST', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '081235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwsears', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwsears', in_func, in_action, out_stmt);
      end if;
   end if;

end lwsears;

procedure lwstaples
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWSTPL', null, l_oh, out_stmt);
   if out_stmt = 'Continue' then
      out_stmt := '081235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwstaples', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwstaples', in_func, in_action, out_stmt);
      end if;
   end if;

end lwstaples;

procedure lwofficedepot
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWOFFDEP', null, l_oh, out_stmt);
   if out_stmt = 'Continue' then
      out_stmt := '081235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lwofficedepot', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lwofficedepot', in_func, in_action, out_stmt);
      end if;
   end if;

end lwofficedepot;

procedure bbbsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '039019', '003436', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bbbsgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bbbsgfoo', in_func, in_action, out_stmt);
      end if;
   end if;

end bbbsgfoo;

procedure jockeysgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '000014', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'jockeysgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'jockeysgfoo', in_func, in_action, out_stmt);
      end if;
   end if;

end jockeysgfoo;

procedure kgsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '7132', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'kgsgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'kgsgfoo', in_func, in_action, out_stmt);
      end if;
   end if;
   
end kgsgfoo;

procedure belksgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '66133', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'belksgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'belksgfoo', in_func, in_action, out_stmt);
      end if;
   end if;
end belksgfoo;

procedure bontonsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '33642', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bontonsgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bontonsgfoo', in_func, in_action, out_stmt);
      end if;
   end if;
end bontonsgfoo;

procedure boscovssgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '7013', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'boscovssgfoo', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'boscovssgfoo', in_func, in_action, out_stmt);
      end if;
   end if;
   
end boscovssgfoo;

procedure basspro
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '214428', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'basspro', in_func, in_action, out_stmt);
   end if;
end basspro;

procedure lwpack
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWMST.GEN', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if l_oh.shiptype = 'S' then
         ccp_group(l_oh, '18', 'lwpack', in_func, in_action, out_stmt);
      else
         if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
            cons_ctn_check('18', 'lwpack', in_func, in_action, out_stmt);
         else
            ctn_group(l_oh, '18', 'lwpack', in_func, in_action, out_stmt);
         end if;
      end if;
   end if;
   
end lwpack;

procedure bluestem
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0005086', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'bluestem', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'bluestem', in_func, in_action, out_stmt);
      end if;
   end if;
end bluestem;

procedure micro
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, 'LWMICR', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      out_stmt := '81235001'; -- 8 digit mfg ucc number
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'micro', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'micro', in_func, in_action, out_stmt);
      end if;
   end if;
end micro;

procedure lazybonezz
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0040002', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'lazybonezz', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'lazybonezz', in_func, in_action, out_stmt);
      end if;
   end if;

end lazybonezz;

procedure walmartcom
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '0097645', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'walmartcom', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'walmartcom', in_func, in_action, out_stmt);
      end if;
   end if;

end walmartcom;

procedure filtersscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'filtersscc', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'filtersscc', in_func, in_action, out_stmt);
      end if;
   end if;

end filtersscc;

procedure filtersscccntnt
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order_cntnts(in_lpid, in_func, in_action, '*', l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('18', 'filtersscccntnt', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '18', 'filtersscccntnt', in_func, in_action, out_stmt);
      end if;
   end if;

end filtersscccntnt;

procedure filtersscc14
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      if in_action = 'C' and in_func = 'Q' and nvl(globalConsorderid, 0) <> 0 then
         cons_ctn_check('14', 'filtersscc14', in_func, in_action, out_stmt);
      else
         ctn_group(l_oh, '14', 'filtersscc14', in_func, in_action, out_stmt);
      end if;
   end if;

end filtersscc14;

procedure dwffiltersscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ctn_group(l_oh, 'DW', 'dwffiltersscc', in_func, in_action, out_stmt);
   end if;

end dwffiltersscc;

procedure dwcfiltersscc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ctn_group(l_oh, '18', 'dwcfiltersscc', in_func, in_action, out_stmt);
   end if;

end dwcfiltersscc;

procedure dwfiltersscc14
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ctn_group(l_oh, 'D1', 'dwfiltersscc14', in_func, in_action, out_stmt);
   end if;

end dwfiltersscc14;

procedure filterpallet
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    out_stmt  out varchar2)
is
   l_oh orderhdr%rowtype;
   l_auxmsg varchar2(255);
begin
   out_stmt := null;

   verify_order(in_lpid, in_func, in_action, '*', null, l_oh, out_stmt);

   if out_stmt = 'Continue' then
      ccp_group(l_oh, '18', 'filterpallet', in_func, in_action, out_stmt);
   end if;

end filterpallet;

procedure filtersscccons
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2)
is
   l_auxmsg varchar2(255);
   i pls_integer;
   cursor c_wav(p_wave number) is
      select * from orderhdr
         where wave = p_wave;
   cursor c_oh(p_orderid number, p_shipid number) is
      select * from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   l_oh orderhdr%rowtype;

begin
   out_stmt := null;
   verify_order(in_lpid, in_func, in_action, '*', in_auxdata, l_oh, out_stmt);
   if out_stmt = 'Continue' then
      if globalConsorderid = 0 then
         ctn_group(l_oh, '18', 'filtersscccons', in_func, in_action, out_stmt);
      else
         for i in 1..ord_tbl.count loop
            open c_oh(ord_tbl(i).orderid, ord_tbl(i).shipid);
            fetch c_oh into l_oh;
            close c_oh;
            ctn_group(l_oh, '18', 'filtersscccons', in_func, in_action, out_stmt);
            if in_action = 'C' and in_func = 'Q' and out_stmt = 'OKAY' then
               exit;
            end if;
            out_stmt := 'Continue';
         end loop;

         if in_action = 'A' then
            if nvl(globalConsorderid,0) <> 0 then
               open c_wav(globalConsorderid);
               fetch c_wav into l_oh;
               close c_wav;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_zucclabels_view L, zseq Z'
                  || ' where L.wave = ' || globalConsorderid
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            else
               open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
               fetch c_oh into l_oh;
               close c_oh;
               out_stmt := 'select L.*, Z.seq as zseq_seq from '
                  || ' lbl_zucclabels_view L, zseq Z'
                  || ' where L.orderid = ' || ord_tbl(1).orderid
                  || ' and L.shipid = ' || ord_tbl(1).shipid
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            end if;
         elsif in_func = 'X' then
            if nvL(globalConsorderid,0) <> 0 then
               open c_wav(globalConsorderid);
               fetch c_wav into l_oh;
               close c_wav;
               out_stmt := 'select L.*, Z.seq as zseq_seq from lbl_zucclabels_view L, zseq Z'
                  || ' where L.wave = ' || globalConsorderid
                  || ' and L.changed = ''Y'''
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';
            else
               open c_oh(ord_tbl(1).orderid, ord_tbl(1).shipid);
               fetch c_oh into l_oh;
               close c_oh;
               out_stmt := 'select L.*, Z.seq as zseq_seq from lbl_zucclabels_view L, zseq Z'
                  || ' where L.orderid = ' || ord_tbl(1).orderid
                  || ' and L.shipid = ' || ord_tbl(1).shipid
                  || ' and L.changed = ''Y'''
                  || ' and Z.seq <= ' || duplicate_cnt(l_oh)
                  || ' order by L.item, L.orderid, L.shipid, L.seq';

            end if;
         elsif out_stmt = 'Continue' then
            out_stmt := 'A Nothing for order';
         else
            rollback;      -- mismatch, undo any lpid updates
         end if;
         commit;

      end if;
   end if;

end filtersscccons;

function casepack
(in_custid custitem.custid%type,
 in_item custitem.item%type
 )
return integer
is
retVal integer;
strFromUOM custitemuom.fromuom%type;
strToUOM custitemuom.touom%type;
procedure test_msg(in_msg varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_autonomous_msg('sscc', 'sscc', rtrim(in_custid), in_msg, 'I', 'sscc', strMsg);
end;

begin
   retVal := 0;
   if in_item is null then
      return retVal;
   end if;
   select sscccasepackfromuom, sscccasepacktouom into strFromUOM, strToUOM
      from custitem
      where custid = in_custid
        and item = in_item;
   if strFromUOM is null and
      strToUOM is null then
      select nvl(sscccasepackfromuom, 'PCS'), nvl(sscccasepacktouom,'CTN') into strFromUOM, strToUOM
         from customer
         where custid = in_custid;
   end if;
   begin
      select qty into retVal
         from custitemuom
         where custid = in_custid
           and item = in_item
           and fromuom = strFromUOM
           and touom = strToUOM;
   exception when no_data_found then
      return 0;
   end;
   return retVal;
exception when others then
   return retVal;
end casepack;
end zucclabels;
/
show error package body zucclabels;
exit;
