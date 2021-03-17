-- import-export routines for starbucks

create or replace package body alps.zimportprocsb as
--
-- $Id$
--

procedure import_832_item
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN OUT varchar2
,in_baseuom IN varchar2
,in_cube IN number
,in_weight IN number
,in_tareweight IN number
,in_hazardous IN varchar2
,in_to_uom1 IN varchar2
,in_to_uom1_qty IN number
,in_to_uom1_weight IN number
,in_to_uom1_cube IN number
,in_to_uom1_length IN number
,in_to_uom1_width IN number
,in_to_uom1_height IN number
,in_velocity1 IN varchar2
,in_picktotype1 IN varchar2
,in_cartontype1 IN varchar2
,in_to_uom2 IN varchar2
,in_to_uom2_qty IN number
,in_to_uom2_weight IN number
,in_to_uom2_cube IN number
,in_to_uom2_length IN number
,in_to_uom2_width IN number
,in_to_uom2_height IN number
,in_velocity2 IN varchar2
,in_picktotype2 IN varchar2
,in_cartontype2 IN varchar2
,in_to_uom3 IN varchar2
,in_to_uom3_qty IN number
,in_to_uom3_weight IN number
,in_to_uom3_cube IN number
,in_to_uom3_length IN number
,in_to_uom3_width IN number
,in_to_uom3_height IN number
,in_velocity3 IN varchar2
,in_picktotype3 IN varchar2
,in_cartontype3 IN varchar2
,in_to_uom4 IN varchar2
,in_to_uom4_qty IN number
,in_to_uom4_weight IN number
,in_to_uom4_cube IN number
,in_to_uom4_length IN number
,in_to_uom4_width IN number
,in_to_uom4_height IN number
,in_velocity4 IN varchar2
,in_picktotype4 IN varchar2
,in_cartontype4 IN varchar2
,in_to_uom5 IN varchar2
,in_to_uom5_qty IN number
,in_to_uom5_weight IN number
,in_to_uom5_cube IN number
,in_to_uom5_length IN number
,in_to_uom5_width IN number
,in_to_uom5_height IN number
,in_velocity5 IN varchar2
,in_picktotype5 IN varchar2
,in_cartontype5 IN varchar2
,in_to_uom6 IN varchar2
,in_to_uom6_qty IN number
,in_to_uom6_weight IN number
,in_to_uom6_cube IN number
,in_to_uom6_length IN number
,in_to_uom6_width IN number
,in_to_uom6_height IN number
,in_velocity6 IN varchar2
,in_picktotype6 IN varchar2
,in_cartontype6 IN varchar2
,in_to_uom7 IN varchar2
,in_to_uom7_qty IN number
,in_to_uom7_weight IN number
,in_to_uom7_cube IN number
,in_to_uom7_length IN number
,in_to_uom7_width IN number
,in_to_uom7_height IN number
,in_velocity7 IN varchar2
,in_picktotype7 IN varchar2
,in_cartontype7 IN varchar2
,in_to_uom8 IN varchar2
,in_to_uom8_qty IN number
,in_to_uom8_weight IN number
,in_to_uom8_cube IN number
,in_to_uom8_length IN number
,in_to_uom8_width IN number
,in_to_uom8_height IN number
,in_velocity8 IN varchar2
,in_picktotype8 IN varchar2
,in_cartontype8 IN varchar2
,in_to_uom9 IN varchar2
,in_to_uom9_qty IN number
,in_to_uom9_weight IN number
,in_to_uom9_cube IN number
,in_to_uom9_length IN number
,in_to_uom9_width IN number
,in_to_uom9_height IN number
,in_velocity9 IN varchar2
,in_picktotype9 IN varchar2
,in_cartontype9 IN varchar2
,in_to_uom10 IN varchar2
,in_to_uom10_qty IN number
,in_to_uom10_weight IN number
,in_to_uom10_cube IN number
,in_to_uom10_length IN number
,in_to_uom10_width IN number
,in_to_uom10_height IN number
,in_velocity10 IN varchar2
,in_picktotype10 IN varchar2
,in_cartontype10 IN varchar2
,in_shelflife IN number
,in_countryof IN varchar2
,in_bolcomment IN varchar2
,in_alias IN varchar2
,in_aliasdesc IN varchar2
,in_alias_partial_match_yn IN varchar2
,in_alias2 IN varchar2
,in_alias2desc IN varchar2
,in_alias2_partial_match_yn IN varchar2
,in_alias3 IN varchar2
,in_alias3desc IN varchar2
,in_alias3_partial_match_yn IN varchar2
,in_alias4 IN varchar2
,in_alias4desc IN varchar2
,in_alias4_partial_match_yn IN varchar2
,in_alias5 IN varchar2
,in_alias5desc IN varchar2
,in_alias5_partial_match_yn IN varchar2
,in_alias6 IN varchar2
,in_alias6desc IN varchar2
,in_alias6_partial_match_yn IN varchar2
,in_alias7 IN varchar2
,in_alias7desc IN varchar2
,in_alias7_partial_match_yn IN varchar2
,in_alias8 IN varchar2
,in_alias8desc IN varchar2
,in_alias8_partial_match_yn IN varchar2
,in_add_status IN varchar2
,in_delete_status IN varchar2
,in_add_review_yn IN varchar2
,in_update_review_yn IN varchar2
,in_delete_review_yn IN varchar2
,in_length IN number
,in_width IN number
,in_height IN number
,in_tms_commodity_code IN varchar2
,in_nmfc IN varchar2
,in_nmfc_article IN varchar2
,in_useramt1 IN number
,in_useramt2 IN number
,in_uom_update IN varchar2
,in_passthrunum01  IN  number
,in_passthrunum02  IN  number
,in_passthrunum03  IN  number
,in_passthrunum04  IN  number
,in_passthrunum05  IN  number
,in_passthrunum06  IN  number
,in_passthrunum07  IN  number
,in_passthrunum08  IN  number
,in_passthrunum09  IN  number
,in_passthrunum10  IN  number
,in_passthruchar01  IN varchar2
,in_passthruchar02  IN varchar2
,in_passthruchar03  IN varchar2
,in_passthruchar04  IN varchar2
,in_passthruchar05  IN varchar2
,in_passthruchar06  IN varchar2
,in_passthruchar07  IN varchar2
,in_passthruchar08  IN varchar2
,in_passthruchar09  IN varchar2
,in_passthruchar10  IN varchar2
,in_productgroup    IN varchar2
,in_recvinvstatus   IN varchar2
,in_lotrequired IN varchar2
,in_serialrequired IN varchar2
,in_user1required IN varchar2
,in_user2required IN varchar2
,in_user3required IN varchar2
,in_mfgdaterequired IN varchar2
,in_expdaterequired IN varchar2
,in_countryrequired IN varchar2
,in_allowsub IN varchar2
,in_backorder IN varchar2
,in_invstatusind IN varchar2
,in_invclassind IN varchar2
,in_qtytype IN varchar2
,in_weightcheckrequired IN varchar2
,in_ordercheckrequired IN varchar2
,in_fifowindowdays IN number
,in_putawayconfirmation IN varchar2
,in_velocity IN varchar2
,in_nodamaged IN varchar2
,in_iskit IN varchar2
,in_picktotype IN varchar2
,in_cartontype      IN varchar2
,in_subslprsnrequired      IN varchar2
,in_lotsumreceipt      IN varchar2
,in_lotsumrenewal      IN varchar2
,in_lotsumbol      IN varchar2
,in_lotsumaccess      IN varchar2
,in_lotfmtaction      IN varchar2
,in_serialfmtaction      IN varchar2
,in_user1fmtaction      IN varchar2
,in_user2fmtaction      IN varchar2
,in_user3fmtaction      IN varchar2
,in_maxqtyof1      IN varchar2
,in_rategroup      IN varchar2
,in_serialasncapture      IN varchar2
,in_user1asncapture      IN varchar2
,in_user2asncapture      IN varchar2
,in_user3asncapture      IN varchar2
,in_style_color_size_columns IN varchar2
,in_table_changes IN varchar2
,in_importfileid IN varchar2
,in_ignore_to_uom in varchar2
,in_labelqty IN number
,in_labeluom IN varchar2
,in_allow_uom_chgs IN varchar2
,in_use_zero_as_null IN varchar2
,in_lotfmtruleid IN varchar2
,in_serialfmtruleid IN varchar2
,in_user1fmtruleid IN varchar2
,in_user2fmtruleid IN varchar2
,in_user3fmtruleid IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_use_fifo IN varchar2
,in_parseruleid IN varchar2
,in_parseentryfield IN varchar2
,in_parseruleaction IN varchar2
,in_update_existing_item_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select name, duplicate_aliases_allowed
    from customer_aux ca, customer cu
   where cu.custid = upper(rtrim(in_custid))
     and cu.custid = ca.custid(+);
cs curCustomer%rowtype;

cursor curCustItem(in_item varchar2) is
  select descr,status
    from custitem
   where custid = upper(rtrim(in_custid))
     and item = upper(rtrim(in_item));
ci curCustItem%rowtype;

cursor curCustProdGroup(in_custid varchar2, in_pg varchar2) is
  select custid, productgroup
    from custproductgroup
   where custid = upper(rtrim(in_custid))
     and productgroup = upper(rtrim(in_pg));

pg curCustProdGroup%rowtype;

cursor curCustRategroup(in_custid varchar2, in_rategroup varchar2) is
  select custid, rategroup
  from custrategroup
  where custid = upper(rtrim(in_custid))
    and rategroup = upper(rtrim(in_rategroup));

rg curCustRategroup%rowtype;

uom_sequence custitemuom.sequence%type;
wrk custitem%rowtype;
l_item custitem.item%type;
l_msg varchar2(256);
cnt integer;

procedure log_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin

  if in_msgtype != 'E' then
    return;
  end if;

  out_msg := ' Item: ' || rtrim(l_item) || ': ' || out_msg;
  zms.log_msg('IMPEXP', null, rtrim(in_custid),
    out_msg, nvl(rtrim(in_msgtype),'E'), 'IMPITEM', strMsg);

end;

procedure update_uom(in_seq number, in_qty number,
    in_from_uom varchar2, in_to_uom varchar2,
    in_weight number, in_cube number, in_length number,
    in_width number, in_height number,
    in_velocity varchar2, in_picktotype varchar2,
    in_cartontype varchar2)
IS
begin
    begin
     if nvl(in_use_zero_as_null, 'N') = 'Y' then
        insert into custitemuom
        (custid,item,
         sequence,qty,
         fromuom,
         touom,
         weight,
         cube,
         length,
         width,
         height,
         lastuser,lastupdate,
         velocity,
         picktotype,
         cartontype)
        values
        (upper(rtrim(in_custid)),upper(rtrim(l_item)),
        in_seq,in_qty,
        in_from_uom,
        in_to_uom,
        decode(in_weight,0,null, in_weight),
        decode(in_cube,0,null, in_cube),
        decode(in_length,0,null, in_length),
        decode(in_width,0,null, in_width),
        decode(in_height,0,null, in_height),
        'IMPITEM',sysdate,
        upper(rtrim(in_velocity)),
        upper(rtrim(in_picktotype)),
        upper(rtrim(in_cartontype)));
     else
        insert into custitemuom
        (custid,item,
         sequence,qty,
         fromuom,
         touom,
         weight,
         cube,
         length,
         width,
         height,
         lastuser,lastupdate,
         velocity,
         picktotype,
         cartontype)
        values
        (upper(rtrim(in_custid)),upper(rtrim(l_item)),
        in_seq,in_qty,
        in_from_uom,
        in_to_uom,
        in_weight,
        in_cube,
        in_length,
        in_width,
        in_height,
        'IMPITEM',sysdate,
        upper(rtrim(in_velocity)),
        upper(rtrim(in_picktotype)),
        upper(rtrim(in_cartontype)));
     end if;

    exception when DUP_VAL_ON_INDEX then
        if nvl(in_use_zero_as_null, 'N') = 'Y' then
            update custitemuom
               set fromuom = in_from_uom,
                   touom = in_to_uom,
                   qty = in_qty,
                   weight = decode(rtrim(in_weight), null,weight, 0,weight, rtrim(in_weight)),
                   cube = decode(rtrim(in_cube), null,cube, 0,cube, rtrim(in_cube)),
                   length = decode(rtrim(in_length), null,length, 0,length, rtrim(in_length)),
                   width = decode(rtrim(in_width), null,width, 0,width, rtrim(in_width)),
                   height = decode(rtrim(in_height), null,height, 0,height, rtrim(in_height)),
                   velocity = nvl(upper(rtrim(in_velocity)), velocity),
                   picktotype = nvl(upper(rtrim(in_picktotype)), picktotype),
                   cartontype = nvl(upper(rtrim(in_cartontype)), cartontype)
            where custid = upper(rtrim(in_custid))
              and item = upper(rtrim(l_item))
              and sequence = in_seq;
        else
        update custitemuom
           set fromuom = in_from_uom,
               touom = in_to_uom,
               qty = in_qty,
               weight = nvl(in_weight,weight),
               cube = nvl(in_cube,cube),
               length = nvl(in_length,length),
               width = nvl(in_width,width),
               height = nvl(in_height,height),
               velocity = nvl(upper(rtrim(in_velocity)), velocity),
               picktotype = nvl(upper(rtrim(in_picktotype)), picktotype),
               cartontype = nvl(upper(rtrim(in_cartontype)), cartontype)
        where custid = upper(rtrim(in_custid))
          and item = upper(rtrim(l_item))
          and sequence = in_seq;
        end if;
    end;

end;

procedure add_alias(in_alias varchar2, in_descr varchar2, in_partial_match varchar2, in_duplicates_allowed varchar2) is
rowCnt integer;
l_alias_count integer;
begin
  select count(1) into rowCnt from custitemalias
  where custid = upper(rtrim(in_custid))
    and item = upper(rtrim(in_item))
    and itemalias = upper(rtrim(in_alias));
  out_msg := upper(rtrim(in_custid)) || ' ' || upper(rtrim(in_item)) || ' ' || upper(rtrim(in_alias)) || ' ' || rowCnt;
  log_msg('I');

  if rowCnt > 0 then
     update custitemalias
        set aliasdesc = in_descr,
            partial_match_yn = in_partial_match,
            lastuser = 'IMPITEM',
            lastupdate = sysdate
      where custid = upper(rtrim(in_custid))
        and item = upper(rtrim(l_item))
        and itemalias = upper(rtrim(in_alias));
   else
      begin

         select count(1)
         into l_alias_count
         from custitemalias
         where custid = upper(rtrim(in_custid))
           and itemalias = upper(rtrim(in_alias));

         if (l_alias_count > 0 and in_duplicates_allowed = 'N') then
           out_errorno := 104;
           out_msg := 'Duplicate aliases are not allowed';
           log_msg('E');
           return;
         end if;

         insert into custitemalias
            (custid,item,itemalias,aliasdesc,partial_match_yn,lastuser,lastupdate)
         values
            (upper(rtrim(in_custid)),upper(rtrim(l_item)),upper(rtrim(in_alias)),
            nvl(rtrim(in_descr),in_alias),upper(rtrim(in_partial_match)),'IMPITEM',sysdate);
         exception when dup_val_on_index then
            update custitemalias
            set aliasdesc = nvl(rtrim(in_descr),in_alias),
                partial_match_yn = nvl(in_partial_match,partial_match_yn),
                lastuser = 'IMPITEM',
                lastupdate = sysdate
            where custid = upper(rtrim(in_custid))
              and item = upper(rtrim(in_item))
              and itemalias = upper(rtrim(in_alias));
            if sql%rowcount = 0 then
               out_errorno := 105;
               out_msg := 'Alias value of ' || rtrim(in_alias) || ' is already in use';
               log_msg('E');
               return;
            end if;
      end;
    end if;

end;

procedure check_832_changes
is
   cursor cust_item is
      select * from custitem
      where custid = in_custid
        and item = in_item;
   CI cust_item%rowtype;

   type uom_rcd is record (
      sequence custitemuom.sequence%type,
      qty custitemuom.qty%type,
      fromuom custitemuom.fromuom%type,
      touom custitemuom.fromuom%type,
      weight custitemuom.weight%type,
      cube custitemuom.cube%type,
      length custitemuom.length%type,
      width custitemuom.width%type,
      height custitemuom.height%type);

   type uoms_tbl is table of uom_rcd
        index by binary_integer;
   uoms uoms_tbl;
   in_uoms uoms_tbl;
   i pls_integer;
   j pls_integer;
   k pls_integer;
   aliasDesc custitemalias.aliasdesc%type;
   cib_comment1 varchar(32767);
   changed pls_integer;

   procedure write_custitem_import_changes(in_column varchar2, in_new_value varchar2,
                                                               in_orig_value varchar2)
   is
   begin
      insert into custitem_import_changes
         (lastupdate, custid, item, msgtext, importfileid)
      values
         (systimestamp, in_custid, in_item,
          in_column || ' NEW: ' || in_new_value || ' ORIG: ' || in_orig_value,
          in_importfileid);
   end write_custitem_import_changes;

begin
   out_msg := 'OKAY';
   
   delete from custitem_import_changes where lastupdate < sysdate - 30;
   commit;
   
   open cust_item;
   fetch cust_item into CI;
   if cust_item%notfound  then
      close cust_item;
      out_msg := 'Cust Item not found';
      return;
   end if;
   close cust_item;

   if nvl(in_descr,'z') != nvl(CI.descr,'z') then
      write_custitem_import_changes('DESCR', in_descr, CI.descr);
   end if;
   if nvl(in_abbrev,'z') != nvl(CI.abbrev,'z') then
      write_custitem_import_changes('ABBREV', in_abbrev, CI.abbrev);
   end if;
   if nvl(in_baseuom,'EA') != nvl(CI.baseuom,'z') then
      write_custitem_import_changes('BASEUOM', in_baseuom, CI.baseuom);
   end if;
   if nvl(in_cube,0) != nvl(CI.cube,0) then
      write_custitem_import_changes('CUBE', in_cube, CI.cube);
   end if;
   if nvl(in_weight,0) != nvl(CI.weight,0) then
      write_custitem_import_changes('WEIGHT', in_weight, CI.weight);
   end if;
   if nvl(in_tareweight,0) != nvl(CI.tareweight,0) then
      write_custitem_import_changes('TAREWEIGHT', in_tareweight, CI.tareweight);
   end if;
   if nvl(in_hazardous,'N') != nvl(CI.hazardous,'z') then
      write_custitem_import_changes('HAZARDOUS', in_hazardous, CI.hazardous);
   end if;
   if nvl(in_shelflife,0) != nvl(CI.shelflife,0) then
      write_custitem_import_changes('SHELFLIFE', in_shelflife, CI.shelflife);
   end if;
   if nvl(in_countryof,'z') != nvl(CI.countryof,'z') then
      write_custitem_import_changes('COUNTRYOF', in_countryof, CI.countryof);
   end if;
   if nvl(in_length,0) != nvl(CI.length,0) then
      write_custitem_import_changes('LENGTH', in_length, CI.length);
   end if;
   if nvl(in_width,0) != nvl(CI.width,0) then
      write_custitem_import_changes('WIDTH', in_width, CI.width);
   end if;
   if nvl(in_height,0) != nvl(CI.height,0) then
      write_custitem_import_changes('HEIGHT', in_height, CI.height);
   end if;
   if nvl(in_tms_commodity_code,'z') != nvl(CI.tms_commodity_code,'z') then
      write_custitem_import_changes('TMS_COMMODITY_CODE', in_tms_commodity_code, CI.tms_commodity_code);
   end if;
   if nvl(in_nmfc,'z') != nvl(CI.nmfc,'z') then
      write_custitem_import_changes('NMFC', in_nmfc, CI.nmfc);
   end if;
   if nvl(in_nmfc_article,'z') != nvl(CI.nmfc_article,'z') then
      write_custitem_import_changes('NMFC_ARTICLE', in_nmfc_article, CI.nmfc_article);
   end if;
   if nvl(in_useramt1,0) != nvl(CI.useramt1,0) then
      write_custitem_import_changes('USERAMT1', in_useramt1, CI.useramt1);
   end if;
   if nvl(in_useramt2,0) != nvl(CI.useramt2,0) then
      write_custitem_import_changes('USERAMT2', in_useramt2, CI.useramt2);
   end if;
   if nvl(in_passthrunum01,0) != nvl(CI.itmpassthrunum01,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM01', in_passthrunum01, CI.itmpassthrunum01);
   end if;
   if nvl(in_passthrunum02,0) != nvl(CI.itmpassthrunum02,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM02', in_passthrunum02, CI.itmpassthrunum02);
   end if;
   if nvl(in_passthrunum03,0) != nvl(CI.itmpassthrunum03,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM03', in_passthrunum03, CI.itmpassthrunum03);
   end if;
   if nvl(in_passthrunum04,0) != nvl(CI.itmpassthrunum04,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM04', in_passthrunum04, CI.itmpassthrunum04);
   end if;
   if nvl(in_passthrunum05,0) != nvl(CI.itmpassthrunum05,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM05', in_passthrunum05, CI.itmpassthrunum05);
   end if;
   if nvl(in_passthrunum06,0) != nvl(CI.itmpassthrunum06,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM06', in_passthrunum06, CI.itmpassthrunum06);
   end if;
   if nvl(in_passthrunum07,0) != nvl(CI.itmpassthrunum07,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM07', in_passthrunum07, CI.itmpassthrunum07);
   end if;
   if nvl(in_passthrunum08,0) != nvl(CI.itmpassthrunum08,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM08', in_passthrunum08, CI.itmpassthrunum08);
   end if;
   if nvl(in_passthrunum09,0) != nvl(CI.itmpassthrunum09,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM09', in_passthrunum09, CI.itmpassthrunum09);
   end if;
   if nvl(in_passthrunum10,0) != nvl(CI.itmpassthrunum10,0) then
      write_custitem_import_changes('ITMPASSTHRUNUM10', in_passthrunum10, CI.itmpassthrunum10);
   end if;
   if nvl(in_passthruchar01,'z') != nvl(CI.itmpassthruchar01,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR01', in_passthruchar01, CI.itmpassthruchar01);
   end if;
   if nvl(in_passthruchar02,'z') != nvl(CI.itmpassthruchar02,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR02', in_passthruchar02, CI.itmpassthruchar02);
   end if;
   if nvl(in_passthruchar03,'z') != nvl(CI.itmpassthruchar03,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR03', in_passthruchar03, CI.itmpassthruchar03);
   end if;
   if nvl(in_passthruchar04,'z') != nvl(CI.itmpassthruchar04,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR04', in_passthruchar04, CI.itmpassthruchar04);
   end if;
   if nvl(in_passthruchar05,'z') != nvl(CI.itmpassthruchar05,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR05', in_passthruchar05, CI.itmpassthruchar05);
   end if;
   if nvl(in_passthruchar06,'z') != nvl(CI.itmpassthruchar06,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR06', in_passthruchar06, CI.itmpassthruchar06);
   end if;
   if nvl(in_passthruchar07,'z') != nvl(CI.itmpassthruchar07,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR07', in_passthruchar07, CI.itmpassthruchar07);
   end if;
   if nvl(in_passthruchar08,'z') != nvl(CI.itmpassthruchar08,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR08', in_passthruchar08, CI.itmpassthruchar08);
   end if;
   if nvl(in_passthruchar09,'z') != nvl(CI.itmpassthruchar09,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR09', in_passthruchar09, CI.itmpassthruchar09);
   end if;
   if nvl(in_passthruchar10,'z') != nvl(CI.itmpassthruchar10,'z') then
      write_custitem_import_changes('ITMPASSTHRUCHAR10', in_passthruchar10, CI.itmpassthruchar10);
   end if;
   if nvl(in_productgroup,'z') != nvl(CI.productgroup,'z') then
      write_custitem_import_changes('PRODUCTGROUP', in_productgroup, CI.productgroup);
   end if;
   if nvl(in_recvinvstatus,'AV') != nvl(CI.recvinvstatus,'z') then
      write_custitem_import_changes('RECVINVSTATUS', in_recvinvstatus, CI.recvinvstatus);
   end if;
   if nvl(in_serialrequired,'C') != nvl(CI.serialrequired,'z') then
      write_custitem_import_changes('SERIALREQUIRED', in_serialrequired, CI.serialrequired);
   end if;
   if nvl(in_fifowindowdays,0) != nvl(CI.fifowindowdays,0) then
      write_custitem_import_changes('FIFOWINDOWDAYS', in_fifowindowdays, CI.fifowindowdays);
   end if;
   if nvl(in_velocity,'C') != nvl(CI.velocity,'z') then
      write_custitem_import_changes('VELOCITY', in_velocity, CI.velocity);
   end if;
   if nvl(in_iskit,'z') != nvl(CI.iskit,'z') then
      write_custitem_import_changes('ISKIT', in_iskit, CI.iskit);
   end if;
   if nvl(in_picktotype,'PAL') != nvl(CI.picktotype,'z') then
      write_custitem_import_changes('PICKTOTYPE', in_picktotype, CI.picktotype);
   end if;
   if nvl(in_cartontype,'PAL') != nvl(CI.cartontype,'z') then
      write_custitem_import_changes('CARTONTYPE', in_cartontype, CI.cartontype);
   end if;
   if nvl(in_parseruleid,'z') != nvl(CI.parseruleid,'z') then
      write_custitem_import_changes('PARSERULEID', in_parseruleid, CI.parseruleid);
   end if;
   if nvl(in_parseentryfield,'z') != nvl(CI.parseentryfield,'z') then
      write_custitem_import_changes('PARSEENTRYFIELD', in_parseentryfield, CI.parseentryfield);
   end if;
   if nvl(in_parseruleaction,'z') != nvl(CI.parseruleaction,'z') then
      write_custitem_import_changes('PARSERULEACTION', in_parseruleaction, CI.parseruleaction);
   end if;
   select sequence, qty, fromuom, touom, weight, cube, length, width, height bulk collect into uoms
      from custitemuom
     where custid = in_custid
       and item = in_item
       and touom != nvl(in_ignore_to_uom,'z');

   i := 0;

   uom_sequence := 10;

   if (rtrim(in_to_uom1) is not null) and
      (nvl(in_to_uom1_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom1_qty;
      in_uoms(i).fromuom := nvl(upper(rtrim(in_baseuom)),'EA');
      in_uoms(i).touom   := in_to_uom1;
      in_uoms(i).weight  := in_to_uom1_weight;
      in_uoms(i).cube    := in_to_uom1_cube;
      in_uoms(i).length  := in_to_uom1_length;
      in_uoms(i).width   := in_to_uom1_width;
      in_uoms(i).height  := in_to_uom1_height;
   end if;

   if (rtrim(in_to_uom2) is not null) and
      (nvl(in_to_uom2_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom2_qty;
      in_uoms(i).fromuom := in_to_uom1;
      in_uoms(i).touom   := in_to_uom2;
      in_uoms(i).weight  := in_to_uom2_weight;
      in_uoms(i).cube    := in_to_uom2_cube;
      in_uoms(i).length  := in_to_uom2_length;
      in_uoms(i).width   := in_to_uom2_width;
      in_uoms(i).height  := in_to_uom2_height;
   end if;
   if (rtrim(in_to_uom3) is not null) and
      (nvl(in_to_uom3_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom3_qty;
      in_uoms(i).fromuom := in_to_uom2;
      in_uoms(i).touom   := in_to_uom3;
      in_uoms(i).weight  := in_to_uom3_weight;
      in_uoms(i).cube    := in_to_uom3_cube;
      in_uoms(i).length  := in_to_uom3_length;
      in_uoms(i).width   := in_to_uom3_width;
      in_uoms(i).height  := in_to_uom3_height;
   end if;
   if (rtrim(in_to_uom4) is not null) and
      (nvl(in_to_uom4_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom4_qty;
      in_uoms(i).fromuom := in_to_uom3;
      in_uoms(i).touom   := in_to_uom4;
      in_uoms(i).weight  := in_to_uom4_weight;
      in_uoms(i).cube    := in_to_uom4_cube;
      in_uoms(i).length  := in_to_uom4_length;
      in_uoms(i).width   := in_to_uom4_width;
      in_uoms(i).height  := in_to_uom4_height;
   end if;
   if (rtrim(in_to_uom5) is not null) and
      (nvl(in_to_uom5_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom5_qty;
      in_uoms(i).fromuom := in_to_uom4;
      in_uoms(i).touom   := in_to_uom5;
      in_uoms(i).weight  := in_to_uom5_weight;
      in_uoms(i).cube    := in_to_uom5_cube;
      in_uoms(i).length  := in_to_uom5_length;
      in_uoms(i).width   := in_to_uom5_width;
      in_uoms(i).height  := in_to_uom5_height;
   end if;
   if (rtrim(in_to_uom6) is not null) and
      (nvl(in_to_uom6_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom6_qty;
      in_uoms(i).fromuom := in_to_uom5;
      in_uoms(i).touom   := in_to_uom6;
      in_uoms(i).weight  := in_to_uom6_weight;
      in_uoms(i).cube    := in_to_uom6_cube;
      in_uoms(i).length  := in_to_uom6_length;
      in_uoms(i).width   := in_to_uom6_width;
      in_uoms(i).height  := in_to_uom6_height;
   end if;
   if (rtrim(in_to_uom7) is not null) and
      (nvl(in_to_uom7_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom7_qty;
      in_uoms(i).fromuom := in_to_uom6;
      in_uoms(i).touom   := in_to_uom7;
      in_uoms(i).weight  := in_to_uom7_weight;
      in_uoms(i).cube    := in_to_uom7_cube;
      in_uoms(i).length  := in_to_uom7_length;
      in_uoms(i).width   := in_to_uom7_width;
      in_uoms(i).height  := in_to_uom7_height;
   end if;
   if (rtrim(in_to_uom8) is not null) and
      (nvl(in_to_uom8_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom8_qty;
      in_uoms(i).fromuom := in_to_uom7;
      in_uoms(i).touom   := in_to_uom8;
      in_uoms(i).weight  := in_to_uom8_weight;
      in_uoms(i).cube    := in_to_uom8_cube;
      in_uoms(i).length  := in_to_uom8_length;
      in_uoms(i).width   := in_to_uom8_width;
      in_uoms(i).height  := in_to_uom8_height;
   end if;
   if (rtrim(in_to_uom9) is not null) and
      (nvl(in_to_uom9_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom9_qty;
      in_uoms(i).fromuom := in_to_uom8;
      in_uoms(i).touom   := in_to_uom9;
      in_uoms(i).weight  := in_to_uom9_weight;
      in_uoms(i).cube    := in_to_uom9_cube;
      in_uoms(i).length  := in_to_uom9_length;
      in_uoms(i).width   := in_to_uom9_width;
      in_uoms(i).height  := in_to_uom9_height;
   end if;
   if (rtrim(in_to_uom10) is not null) and
      (nvl(in_to_uom10_qty,0) <> 0) then
      i := i + 1;
      in_uoms(i).qty := in_to_uom10_qty;
      in_uoms(i).fromuom := in_to_uom9;
      in_uoms(i).touom   := in_to_uom10;
      in_uoms(i).weight  := in_to_uom10_weight;
      in_uoms(i).cube    := in_to_uom10_cube;
      in_uoms(i).length  := in_to_uom10_length;
      in_uoms(i).width   := in_to_uom10_width;
      in_uoms(i).height  := in_to_uom10_height;
   end if;
   
   i := 1;
   j := 1;
   k := 10;

   while i <= uoms.last or j <= in_uoms.last loop
      if i <= uoms.last and j <= in_uoms.last then
         if uoms(i).sequence = k then
            if nvl(uoms(i).qty,0) != nvl(in_uoms(j).qty,0) or
               uoms(i).fromuom != in_uoms(j).fromuom or
               uoms(i).touom != in_uoms(j).touom or
               nvl(uoms(i).weight,0) != nvl(in_uoms(j).weight,0) or
               nvl(uoms(i).cube,0) != nvl(in_uoms(j).cube,0) or
               nvl(uoms(i).length,0) != nvl(in_uoms(j).length,0) or
               nvl(uoms(i).width,0) != nvl(in_uoms(j).width,0) or
               nvl(uoms(i).height,0) != nvl(in_uoms(j).height,0)  then
               write_custitem_import_changes('UOM '||uoms(i).sequence,
                                             uoms(i).qty || ' f ' || uoms(i).fromuom || ' t ' ||
                                                uoms(i).touom || ' w ' || uoms(i).weight || ' c ' ||
                                                uoms(i).cube || ' l ' || uoms(i).length || ' w ' ||
                                                uoms(i).width || ' h ' || uoms(i).height,
                                             in_uoms(j).qty || ' f ' || in_uoms(j).fromuom || ' t ' ||
                                                in_uoms(j).touom || ' w ' || in_uoms(j).weight || ' c ' ||
                                                in_uoms(j).cube || ' l ' ||in_uoms(j).length || ' w ' ||
                                                in_uoms(j).width || ' h ' || in_uoms(j).height);

            end if;
            i := i + 1;
            j := j + 1;
            k := k + 10;
         elsif uoms(i).sequence > k then
            write_custitem_import_changes('UOM '||k, '(null)',
                                          in_uoms(j).qty || ' f ' || in_uoms(j).fromuom || ' t ' ||
                                          in_uoms(j).touom || ' w ' || in_uoms(j).weight || ' c ' ||
                                          in_uoms(j).cube || ' l ' || in_uoms(j).length || ' w ' ||
                                          in_uoms(j).width || ' h ' || in_uoms(j).height );
            j := j + 1;
            k := k + 10;
         else
            write_custitem_import_changes('UOM '||uoms(i).sequence,
                                          uoms(i).qty || ' f ' || uoms(i).fromuom || ' t ' ||
                                          uoms(i).touom || ' w ' || uoms(i).weight || ' c ' ||
                                          uoms(i).cube || ' l ' || uoms(i).length || ' w ' ||
                                          uoms(i).width || ' h ' || uoms(i).height,
                                          '(null)');
            i := i + 1;
         end if;
      else
         if i <= uoms.last then
            write_custitem_import_changes('UOM '||uoms(i).sequence,
                                          uoms(i).qty || ' f ' || uoms(i).fromuom || ' t ' ||
                                          uoms(i).touom || ' w ' || uoms(i).weight || ' c ' ||
                                          uoms(i).cube || ' l ' || uoms(i).length || ' w ' ||
                                          uoms(i).width || ' h ' || uoms(i).height,
                                          '(null)');
            i := i + 1;
         else
            write_custitem_import_changes('UOM '||k, '(null)',
                                          in_uoms(j).qty || ' f ' || in_uoms(j).fromuom || ' t ' ||
                                          in_uoms(j).touom || ' w ' || in_uoms(j).weight || ' c ' ||
                                          in_uoms(j).cube || ' l ' || in_uoms(j).length || ' w ' ||
                                          in_uoms(j).width || ' h ' || in_uoms(j).height);
            j := j + 1;
            k := k + 10;
         end if;
      end if;
   end loop;
   

   if in_alias is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS', in_alias, '(none)');
      end;
      if nvl(in_aliasdesc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIASDESC', in_aliasdesc, aliasDesc);
      end if;
   end if;

   if in_alias2 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias2;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS2', in_alias2, '(none)');
      end;
      if nvl(in_alias2desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS2DESC', in_alias2desc, aliasDesc);
      end if;
   end if;

   if in_alias3 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias3;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS3', in_alias3, '(none)');
      end;
      if nvl(in_alias3desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS3DESC', in_alias3desc, aliasDesc);
      end if;
   end if;

   if in_alias4 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias4;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS4', in_alias4, '(none)');
      end;
      if nvl(in_alias4desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS4DESC', in_alias4desc, aliasDesc);
      end if;
   end if;

   if in_alias5 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias5;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS5', in_alias5, '(none)');
      end;
      if nvl(in_alias5desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS5DESC', in_alias5desc, aliasDesc);
      end if;
   end if;

   if in_alias6 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias6;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS6', in_alias6, '(none)');
      end;
      if nvl(in_alias6desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS6DESC', in_alias6desc, aliasDesc);
      end if;
   end if;

   if in_alias7 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias7;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS7', in_alias7, '(none)');
      end;
      if nvl(in_alias7desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS7DESC', in_alias7desc, aliasDesc);
      end if;
   end if;

   if in_alias8 is not null then
      changed := 0;
      begin
         select aliasdesc into aliasDesc
           from custitemalias
          where custid = in_custid
            and item = in_item
            and itemalias = in_alias8;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('ALIAS8', in_alias8, '(none)');
      end;
      if nvl(in_alias8desc,'z') != nvl(aliasDesc,'z') and
         changed = 0 then
         write_custitem_import_changes('ALIAS8DESC', in_alias8desc, aliasDesc);
      end if;
   end if;

   if in_bolcomment is not null then
      changed := 0;
      begin
         select comment1 into cib_comment1
            from custitembolcomments
          where custid = in_custid
            and item = in_item
            and consignee is null;
      exception when no_data_found then
         changed := 1;
         write_custitem_import_changes('BOLCOMMENT ', in_bolcomment, '(none)');
      end;
      if changed = 0 and
         cib_comment1 != in_bolcomment then
         write_custitem_import_changes('BOLCOMMENT ', in_bolcomment, cib_comment1);
      end if;

   end if;



end check_832_changes;


procedure get_style_color_size_item(out_msg in out varchar2)
is
iStyle custitem.itmpassthruchar01%type;
iColor custitem.itmpassthruchar01%type;
iSize custitem.itmpassthruchar01%type;
styleColumn varchar2(32);
colorColumn varchar2(32);
sizeColumn varchar2(32);
pos1 pls_integer;
pos2 pls_integer;
   function get_value(in_column varchar2)
      return varchar2 is
   retval varchar2(32);
   begin
      retval := 'UNKNOWN';
      if in_column =  'in_passthruchar01' then
         retval := in_passthruchar01;
      elsif in_column = 'in_passthruchar02' then
         retval := in_passthruchar02;
      elsif in_column = 'in_passthruchar03' then
         retval := in_passthruchar03;
      elsif in_column = 'in_passthruchar04' then
         retval := in_passthruchar04;
      elsif in_column = 'in_passthruchar05' then
         retval := in_passthruchar05;
      elsif in_column = 'in_passthruchar06' then
         retval := in_passthruchar06;
      elsif in_column = 'in_passthruchar07' then
         retval := in_passthruchar07;
      elsif in_column = 'in_passthruchar08' then
         retval := in_passthruchar08;
      elsif in_column = 'in_passthruchar09' then
         retval := in_passthruchar09;
      elsif in_column = 'in_passthruchar10' then
         retval := in_passthruchar10;
      end if;

      return retval;
   end get_value;

begin
   -- valid values are in_passthruchar01 .. in_passthruchar10
   -- columns seperated by |
   -- example in_passthruchar05|in_passthruchar06|in_passthruchar07
   pos1 := instr(in_style_color_size_columns, '|');
   if pos1 = 0 then
      out_msg := 'Invalid format: in_style_color_size_columns ';
      return;
   end if;
   pos2 := instr(substr(in_style_color_size_columns, pos1 + 1), '|');
   if pos2 = 0 then
      out_msg := 'Invalid format: in_style_color_size_columns ';
      return;
   end if;

   styleColumn := substr(in_style_color_size_columns, 1, pos1 - 1);
   colorColumn := substr(in_style_color_size_columns, pos1 + 1, pos2 - 1);
   sizeColumn := substr(in_style_color_size_columns, pos1 + pos2 + 1);

   iStyle := get_value(styleColumn);
   if iStyle = 'UNKNOWN'  then
      out_msg := 'Invalid column for style ' || styleColumn;
      return;
   end if;
   iColor := get_value(colorColumn);
   if icolor = 'UNKNOWN'  then
      out_msg := 'Invalid column for color ' || colorColumn;
      return;
   end if;
   iSize := get_value(sizeColumn);
   if iSize = 'UNKNOWN'  then
      out_msg := 'Invalid column for size ' || sizeColumn;
      return;
   end if;
   if length(iStyle) + length(iColor) + length(iSize) + 2 > 50 then
      out_msg := 'Data too long ' || iStyle || '+' || iColor || '+' || iSize;
      return;
   end if;
   l_item := iStyle || '-' || iColor || '-' || iSize;
end get_style_color_size_item;

begin
out_errorno := 0;
out_msg := '';

l_item := in_item;

if in_style_color_size_columns is not null then
   l_msg := null;
   get_style_color_size_item(l_msg);
   if l_msg is not null then
      out_errorno := 8;
      out_msg := l_msg;
      log_msg('E');
      return;
   end if;
end if;

if rtrim(upper(in_func)) not in ('A','U','D') then
  out_errorno := 4;
  out_msg := 'Invalid function code: ' || in_func;
  log_msg('E');
  return;
end if;

if rtrim(in_custid) is null then
  out_errorno := 1;
  out_msg := 'Customer ID is required';
  log_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.name is null then
  out_errorno := 2;
  out_msg := 'Invalid Customer ID: ' || in_custid;
  log_msg('E');
  return;
end if;

if rtrim(l_item) is null then
  out_errorno := 3;
  out_msg := 'Item ID is required';
  log_msg('E');
  return;
end if;

ci := null;
open curCustItem(l_item);
fetch curCustItem into ci;
close curCustItem;

if ci.descr is null then
  if upper(rtrim(in_func)) = 'D' then
    out_errorno := 5;
    out_msg := 'Item not found for deletion: ' || l_item;
    log_msg('E');
    return;
  end if;
  if upper(rtrim(in_func)) = 'U' then
    if nvl(in_update_existing_item_yn, 'N') = 'N' then
      out_msg := 'Item not found for update. (No update performed): ' || l_item;
      log_msg('E');
    else
      out_msg := 'Item not found for update (add performed): ' || l_item;
      log_msg('W');
      in_func := 'A';
    end if;
  end if;
else
  if upper(rtrim(in_func)) = 'A' then
    if nvl(in_update_existing_item_yn, 'N') = 'N' then
      out_msg := 'Item to be added already on file. (No add performed): ' || l_item;
      log_msg('E');
      return;
    else
      out_msg := 'Item to be added already on file (update performed): ' || l_item;
      log_msg('W');
      in_func := 'U';
    end if;
  end if;
end if;

if (rtrim(in_productgroup)) is not null then
    pg := null;
    open curCustProdGroup(in_custid, in_productgroup);
    fetch curCustProdGroup into pg;
    close curCustProdGroup;
    if pg.custid is null then
        out_errorno := 6;
        out_msg := 'Product Group not found: ' || in_productgroup;
        log_msg('E');
        return;
    end if;
end if;

if nvl(rtrim(in_table_changes),'N') = 'Y' then
   if ci.descr is not null then
      check_832_changes;
      return;
   end if;
end if;

if (rtrim(in_rategroup)) is not null then
    rg := null;
    open curCustRategroup(in_custid, in_rategroup);
    fetch curCustRategroup into rg;
    close curCustRategroup;
    if rg.custid is null then
        out_errorno := 7;
        out_msg := 'Rategroup not found: ' || in_rategroup;
        log_msg('E');
        return;
    end if;
end if;

if upper(rtrim(in_func)) = 'A' then
  wrk.status := in_add_status;
  wrk.needs_review_yn := in_add_review_yn;
elsif upper(rtrim(in_func)) = 'U' then
  wrk.status := ci.status;
  wrk.needs_review_yn := in_update_review_yn;
else
  wrk.status := in_delete_status;
  wrk.needs_review_yn := in_delete_review_yn;
end if;

if nvl(upper(rtrim(in_allow_uom_chgs)), 'N') = 'Y' then
 wrk.allow_uom_chgs := 'Y';
end if;

if rtrim(in_abbrev) is null then
  in_abbrev := substr(in_descr,1,12);
end if;

if rtrim(in_productgroup) is not null
  and upper(rtrim(in_func)) in ('A','U') then
    cnt := 0;
    select count(1)
      into cnt
      from custproductgroup
     where custid = upper(rtrim(in_custid))
       and productgroup = upper(rtrim(in_productgroup));
    if nvl(cnt,0) < 1 then
        out_errorno := 6;
        out_msg := 'Product Group not found: ' || in_productgroup;
        log_msg('E');
        return;
    end if;
end if;

if rtrim(in_recvinvstatus) is not null then
    begin
        cnt := 0;
        select count(1)
          into cnt
          from inventorystatus
         where code = upper(rtrim(in_recvinvstatus));
    exception when others then
        cnt := 0;
    end;
    if nvl(cnt, 0) <= 0 then
        out_errorno := 7;
        out_msg := 'Invalid inventory status : ' || in_recvinvstatus;
        log_msg('E');
        return;
    end if;
end if;


if in_parseruleid is not null and in_parseentryfield is not null and in_parseruleaction is not null then 
    if rtrim(in_parseruleid) is null and (rtrim(in_parseentryfield) is not null or rtrim(in_parseruleaction) is not null) then
        if rtrim(in_parseentryfield) is not null and rtrim(in_parseruleaction) is not null then
    	   out_msg := 'Parse Rule is empty. Both Parse Entry Field(' || in_parseentryfield || ') and Parse Rule Action(' || in_parseruleaction || ') should be empty as well';
           log_msg('E');
           return;
    	elsif rtrim(in_parseentryfield) is not null then
    	   out_msg := 'Parse Rule is empty. Parse Entry Field(' || in_parseentryfield || ') should be empty as well';
           log_msg('E');
           return;
    	else
    	   out_msg := 'Parse Rule is empty. Parse Rule Action(' || in_parseruleaction || ') should be empty as well';
           log_msg('E');
           return;	   
    	end if;
    end if;

    if rtrim(in_parseruleid) is not null and (rtrim(in_parseentryfield) is null or rtrim(in_parseruleaction) is null) then
        if rtrim(in_parseentryfield) is null and rtrim(in_parseruleaction) is null then
    	   out_msg := 'Empty Parse Entry Field and Parse Rule Action are invalid for Parse Rule: ' || in_parseruleid;
           log_msg('E');
           return;
    	elsif rtrim(in_parseentryfield) is null then
    	   out_msg := 'Empty Parse Entry Field is invalid for Parse Rule: ' || in_parseruleid;
           log_msg('E');
           return;
    	else
    	   out_msg := 'Empty Parse Rule Action is invalid for Parse Rule: ' || in_parseruleid;
           log_msg('E');
           return;	   
    	end if;
    else
        cnt := 0;
        select count(1)
          into cnt
          from (select ruleid
    	          from parserule where ruleid = rtrim(in_parseruleid)
    	        union all
    	        select groupid
    	          from parserulegroup where groupid = rtrim(in_parseruleid));

        if nvl(cnt,0) < 1 then
            out_msg := 'Invalid Parse Rule: ' || in_parseruleid;
            log_msg('E');
            return;
        end if;

    	cnt := 0;
    	select count(1)
    	  into cnt
    	  from parseentryfield where code = rtrim(in_parseentryfield);
    	  
    	if nvl(cnt,0) < 1 then
            out_msg := 'Invalid Parse Entry Field: ' || in_parseentryfield;
            log_msg('E');
            return;
        end if;
    	
    	if rtrim(in_parseruleaction) not in ('C', 'Y', 'N') then
            out_msg := 'Invalid Parse Rule Action: ' || in_parseruleaction || '. Valid value should be C, Y, or N';
            log_msg('E');
            return;
    	end if;
    end if;
end if;

if upper(rtrim(in_func)) = 'A' then
   if ci.descr is null then
      if nvl(in_use_zero_as_null, 'N') = 'Y' then
         insert into custitem
           (custid,item,
            descr,abbrev,status,baseuom,
            cube,weight,tareweight,hazardous,shelflife,
            lotrequired,serialrequired,user1required,user2required,user3required,
            mfgdaterequired,expdaterequired,countryrequired,
            allowsub,backorder,invstatusind,invclassind,
            qtytype,velocity,recvinvstatus,
            weightcheckrequired,ordercheckrequired,
            fifowindowdays,putawayconfirmation,
            nodamaged,iskit,picktotype,cartontype,subslprsnrequired,
            lotsumreceipt,lotsumrenewal,lotsumbol,lotsumaccess,
            lotfmtaction,serialfmtaction,
            user1fmtaction,user2fmtaction,user3fmtaction,
            maxqtyof1,rategroup,
            serialasncapture,user1asncapture,user2asncapture,user3asncapture,
            lastuser,lastupdate,needs_review_yn,countryof,
            length,width,height,tms_commodity_code, nmfc, nmfc_article,
            useramt1,useramt2,
            itmpassthrunum01,itmpassthrunum02,itmpassthrunum03,itmpassthrunum04,itmpassthrunum05,
            itmpassthrunum06,itmpassthrunum07,itmpassthrunum08,itmpassthrunum09,itmpassthrunum10,
            itmpassthruchar01,itmpassthruchar02,itmpassthruchar03,itmpassthruchar04,itmpassthruchar05,
            itmpassthruchar06,itmpassthruchar07,itmpassthruchar08,itmpassthruchar09,itmpassthruchar10,
            productgroup,labelqty,labeluom,allow_uom_chgs,lotfmtruleid,serialfmtruleid,
            user1fmtruleid,user2fmtruleid,user3fmtruleid,inventoryclass,invstatus,use_fifo,
			parseruleid, parseentryfield, parseruleaction)
         values
           (upper(rtrim(in_custid)),upper(rtrim(in_item)),
            rtrim(in_descr),rtrim(in_abbrev),wrk.status,nvl(upper(rtrim(in_baseuom)),'EA'),
            decode(in_cube,0,null, in_cube),decode(in_weight,0,null, in_weight),decode(in_tareweight,0,null, in_tareweight),nvl(upper(rtrim(in_hazardous)),'N'),decode(in_shelflife,0,null, in_shelflife),
            nvl(in_lotrequired,'C'),nvl(in_serialrequired,'C'),nvl(in_user1required,'C'),nvl(in_user2required,'C'),nvl(in_user3required,'C'),
            nvl(in_mfgdaterequired,'C'),nvl(in_expdaterequired,'C'),nvl(in_countryrequired,'C'),
            nvl(in_allowsub,'C'),nvl(in_backorder,'C'),nvl(in_invstatusind,'C'),nvl(in_invclassind,'C'),
            nvl(in_qtytype,'C'),nvl(upper(rtrim(in_velocity)),'C'),nvl(upper(rtrim(in_recvinvstatus)),'AV'),
            nvl(in_weightcheckrequired,'C'),nvl(in_ordercheckrequired,'C'),
            decode(in_fifowindowdays,0,null, in_fifowindowdays),nvl(in_putawayconfirmation,'C'),
            nvl(in_nodamaged,'C'),rtrim(in_iskit),nvl(upper(rtrim(in_picktotype)),'PAL'),nvl(upper(rtrim(in_cartontype)),'PAL'),nvl(in_subslprsnrequired,'C'),
            nvl(in_lotsumreceipt,'N'),nvl(in_lotsumrenewal,'N'),nvl(in_lotsumbol,'N'),nvl(in_lotsumaccess,'N'),
            nvl(in_lotfmtaction,'C'),nvl(in_serialfmtaction,'C'),
            nvl(in_user1fmtaction,'C'),nvl(in_user2fmtaction,'C'),nvl(in_user3fmtaction,'C'),
            nvl(in_maxqtyof1,'C'),nvl(in_rategroup,'C'),
            nvl(in_serialasncapture,'C'),nvl(in_user1asncapture,'C'),nvl(in_user2asncapture,'C'),nvl(in_user3asncapture,'C'),
            'IMPITEM',sysdate,wrk.needs_review_yn,upper(rtrim(in_countryof)),
            decode(in_length,0,null, in_length), decode(in_width,0,null, in_width), decode(in_height,0,null, in_height), in_tms_commodity_code, in_nmfc,
            in_nmfc_article, decode(in_useramt1,0,null, in_useramt1), decode(in_useramt2,0,null, in_useramt2),
            decode(in_passthrunum01,0,null,in_passthrunum01),decode(in_passthrunum02,0,null,in_passthrunum02), 
            decode(in_passthrunum03,0,null,in_passthrunum03), decode(in_passthrunum04,0,null,in_passthrunum04),
            decode(in_passthrunum05,0,null,in_passthrunum05), decode(in_passthrunum06,0,null,in_passthrunum06), 
            decode(in_passthrunum07,0,null,in_passthrunum07),decode(in_passthrunum08,0,null,in_passthrunum08), 
            decode(in_passthrunum09,0,null,in_passthrunum09), decode(in_passthrunum10,0,null,in_passthrunum10),
            in_passthruchar01, in_passthruchar02, in_passthruchar03, in_passthruchar04, in_passthruchar05,
            in_passthruchar06, in_passthruchar07, in_passthruchar08, in_passthruchar09, in_passthruchar10,
            upper(rtrim(in_productgroup)),decode(in_labelqty,0,null, in_labelqty),in_labeluom,wrk.allow_uom_chgs,in_lotfmtruleid,
            in_serialfmtruleid,in_user1fmtruleid,in_user2fmtruleid,
            in_user3fmtruleid,in_inventoryclass,in_invstatus,nvl(rtrim(in_use_fifo),'N'),
			rtrim(in_parseruleid), rtrim(in_parseentryfield), rtrim(in_parseruleaction));
      else
         insert into custitem
           (custid,item,
            descr,abbrev,status,baseuom,
            cube,weight,tareweight,hazardous,shelflife,
            lotrequired,serialrequired,user1required,user2required,user3required,
            mfgdaterequired,expdaterequired,countryrequired,
            allowsub,backorder,invstatusind,invclassind,
            qtytype,velocity,recvinvstatus,
            weightcheckrequired,ordercheckrequired,
            fifowindowdays,putawayconfirmation,
            nodamaged,iskit,picktotype,cartontype,subslprsnrequired,
            lotsumreceipt,lotsumrenewal,lotsumbol,lotsumaccess,
            lotfmtaction,serialfmtaction,
            user1fmtaction,user2fmtaction,user3fmtaction,
            maxqtyof1,rategroup,
            serialasncapture,user1asncapture,user2asncapture,user3asncapture,
            lastuser,lastupdate,needs_review_yn,countryof,
            length,width,height,tms_commodity_code, nmfc, nmfc_article,
            useramt1, useramt2,
            itmpassthrunum01,itmpassthrunum02,itmpassthrunum03,itmpassthrunum04,itmpassthrunum05,
            itmpassthrunum06,itmpassthrunum07,itmpassthrunum08,itmpassthrunum09,itmpassthrunum10,
            itmpassthruchar01,itmpassthruchar02,itmpassthruchar03,itmpassthruchar04,itmpassthruchar05,
            itmpassthruchar06,itmpassthruchar07,itmpassthruchar08,itmpassthruchar09,itmpassthruchar10,
            productgroup,labelqty,labeluom,allow_uom_chgs,lotfmtruleid,serialfmtruleid,
            user1fmtruleid,user2fmtruleid,user3fmtruleid,inventoryclass,invstatus,use_fifo,
			parseruleid, parseentryfield, parseruleaction)
         values
           (upper(rtrim(in_custid)),upper(rtrim(in_item)),
            rtrim(in_descr),rtrim(in_abbrev),wrk.status,nvl(upper(rtrim(in_baseuom)),'EA'),
            nvl(in_cube,0),nvl(in_weight,0),nvl(in_tareweight,0),nvl(upper(rtrim(in_hazardous)),'N'),nvl(in_shelflife,0),
            nvl(in_lotrequired,'C'),nvl(in_serialrequired,'C'),nvl(in_user1required,'C'),nvl(in_user2required,'C'),nvl(in_user3required,'C'),
            nvl(in_mfgdaterequired,'C'),nvl(in_expdaterequired,'C'),nvl(in_countryrequired,'C'),
            nvl(in_allowsub,'C'),nvl(in_backorder,'C'),nvl(in_invstatusind,'C'),nvl(in_invclassind,'C'),
            nvl(in_qtytype,'C'),nvl(upper(rtrim(in_velocity)),'C'),nvl(upper(rtrim(in_recvinvstatus)),'AV'),
            nvl(in_weightcheckrequired,'C'),nvl(in_ordercheckrequired,'C'),
            in_fifowindowdays,nvl(in_putawayconfirmation,'C'),
            nvl(in_nodamaged,'C'),rtrim(in_iskit),nvl(upper(rtrim(in_picktotype)),'PAL'),nvl(upper(rtrim(in_cartontype)),'PAL'),nvl(in_subslprsnrequired,'C'),
            nvl(in_lotsumreceipt,'N'),nvl(in_lotsumrenewal,'N'),nvl(in_lotsumbol,'N'),nvl(in_lotsumaccess,'N'),
            nvl(in_lotfmtaction,'C'),nvl(in_serialfmtaction,'C'),
            nvl(in_user1fmtaction,'C'),nvl(in_user2fmtaction,'C'),nvl(in_user3fmtaction,'C'),
            nvl(in_maxqtyof1,'C'),nvl(in_rategroup,'C'),
            nvl(in_serialasncapture,'C'),nvl(in_user1asncapture,'C'),nvl(in_user2asncapture,'C'),nvl(in_user3asncapture,'C'),
            'IMPITEM',sysdate,wrk.needs_review_yn,upper(rtrim(in_countryof)),
            in_length,in_width,in_height,in_tms_commodity_code, in_nmfc,
            in_nmfc_article, in_useramt1, in_useramt2,
            in_passthrunum01,  in_passthrunum02,  in_passthrunum03,  in_passthrunum04, in_passthrunum05,
            in_passthrunum06,  in_passthrunum07,  in_passthrunum08,  in_passthrunum09, in_passthrunum10,
            in_passthruchar01, in_passthruchar02, in_passthruchar03, in_passthruchar04, in_passthruchar05,
            in_passthruchar06, in_passthruchar07, in_passthruchar08, in_passthruchar09, in_passthruchar10,
            upper(rtrim(in_productgroup)),in_labelqty,in_labeluom,wrk.allow_uom_chgs,in_lotfmtruleid,
            in_serialfmtruleid,in_user1fmtruleid,in_user2fmtruleid,
            in_user3fmtruleid,in_inventoryclass,in_invstatus,nvl(rtrim(in_use_fifo),'N'),
			rtrim(in_parseruleid), rtrim(in_parseentryfield), rtrim(in_parseruleaction));
      end if;
   end if;
elsif upper(rtrim(in_func)) = 'U' then
   if nvl(in_use_zero_as_null, 'N') = 'Y' then
      update custitem
        set descr = nvl(rtrim(in_descr),descr),
            abbrev = nvl(rtrim(in_abbrev),abbrev),
            status = wrk.status,
            baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
            cube = decode(rtrim(in_cube), null,cube, 0,cube, rtrim(in_cube)),
            weight = decode(rtrim(in_weight), null,weight, 0,weight, rtrim(in_weight)),
            tareweight = nvl(in_tareweight,tareweight),
            hazardous = nvl(upper(rtrim(in_hazardous)),hazardous),
            shelflife=decode(in_shelflife, null,shelflife, 0,shelflife, in_shelflife),
            lastuser = 'IMPITEM',
            lastupdate = sysdate,
            needs_review_yn = wrk.needs_review_yn,
            length = decode(rtrim(in_length), null,length, 0,length, rtrim(in_length)),
            width = decode(rtrim(in_width), null,width, 0,width, rtrim(in_width)),
            height = decode(rtrim(in_height), null,height, 0,height, rtrim(in_height)),
            nmfc = nvl(in_nmfc,nmfc),
            nmfc_article = nvl(in_nmfc_article,nmfc_article),
            tms_commodity_code = in_tms_commodity_code,
            useramt1=decode(in_useramt1, null,useramt1, 0,useramt1, in_useramt1),
            useramt2=decode(in_useramt2, null,useramt2, 0,useramt2, in_useramt2),
            itmpassthrunum01=decode(in_passthrunum01, null,itmpassthrunum01, 0,itmpassthrunum01, in_passthrunum01),
            itmpassthrunum02=decode(in_passthrunum02, null,itmpassthrunum02, 0,itmpassthrunum02, in_passthrunum02),
            itmpassthrunum03=decode(in_passthrunum03, null,itmpassthrunum03, 0,itmpassthrunum03, in_passthrunum03),
            itmpassthrunum04=decode(in_passthrunum04, null,itmpassthrunum04, 0,itmpassthrunum04, in_passthrunum04),
            itmpassthrunum05=decode(in_passthrunum05, null,itmpassthrunum05, 0,itmpassthrunum05, in_passthrunum05),
            itmpassthrunum06=decode(in_passthrunum06, null,itmpassthrunum06, 0,itmpassthrunum06, in_passthrunum06),
            itmpassthrunum07=decode(in_passthrunum07, null,itmpassthrunum07, 0,itmpassthrunum07, in_passthrunum07),
            itmpassthrunum08=decode(in_passthrunum08, null,itmpassthrunum08, 0,itmpassthrunum08, in_passthrunum08),
            itmpassthrunum09=decode(in_passthrunum09, null,itmpassthrunum09, 0,itmpassthrunum09, in_passthrunum09),
            itmpassthrunum10=decode(in_passthrunum10, null,itmpassthrunum10, 0,itmpassthrunum10, in_passthrunum10),
            itmpassthruchar01=nvl(in_passthruchar01, itmpassthruchar01),
            itmpassthruchar02=nvl(in_passthruchar02, itmpassthruchar02),
            itmpassthruchar03=nvl(in_passthruchar03, itmpassthruchar03),
            itmpassthruchar04=nvl(in_passthruchar04, itmpassthruchar04),
            itmpassthruchar05=nvl(in_passthruchar05, itmpassthruchar05),
            itmpassthruchar06=nvl(in_passthruchar06, itmpassthruchar06),
            itmpassthruchar07=nvl(in_passthruchar07, itmpassthruchar07),
            itmpassthruchar08=nvl(in_passthruchar08, itmpassthruchar08),
            itmpassthruchar09=nvl(in_passthruchar09, itmpassthruchar09),
            itmpassthruchar10=nvl(in_passthruchar10, itmpassthruchar10),
            productgroup=nvl(upper(rtrim(in_productgroup)),productgroup),
            recvinvstatus=nvl(upper(rtrim(in_recvinvstatus)),recvinvstatus),
            lotrequired=nvl(in_lotrequired, lotrequired),
            serialrequired=nvl(in_serialrequired, serialrequired),
            user1required=nvl(in_user1required, user1required),
            user2required=nvl(in_user2required, user2required),
            user3required=nvl(in_user3required, user3required),
            mfgdaterequired=nvl(in_mfgdaterequired, mfgdaterequired),
            expdaterequired=nvl(in_expdaterequired, expdaterequired),
            countryrequired=nvl(in_countryrequired, countryrequired),
            allowsub=nvl(in_allowsub, allowsub),
            backorder=nvl(in_backorder, backorder),
            invstatusind=nvl(in_invstatusind, invstatusind),
            invclassind=nvl(in_invclassind, invclassind),
            qtytype=nvl(in_qtytype, qtytype),
            weightcheckrequired=nvl(in_weightcheckrequired, weightcheckrequired),
            ordercheckrequired=nvl(in_ordercheckrequired, ordercheckrequired),
            fifowindowdays=decode(in_fifowindowdays, null,fifowindowdays, 0,fifowindowdays, in_fifowindowdays),
            putawayconfirmation=nvl(in_putawayconfirmation, putawayconfirmation),
            velocity=nvl(upper(rtrim(in_velocity)),velocity),
            nodamaged=nvl(in_nodamaged, nodamaged),
            iskit=nvl(upper(rtrim(in_iskit)),iskit),
            picktotype=nvl(upper(rtrim(in_picktotype)), picktotype),
            cartontype = nvl(upper(rtrim(in_cartontype)),cartontype),
            subslprsnrequired = nvl(upper(rtrim(in_subslprsnrequired)),subslprsnrequired),
            lotsumreceipt = nvl(upper(rtrim(in_lotsumreceipt)),lotsumreceipt),
            lotsumrenewal = nvl(upper(rtrim(in_lotsumrenewal)),lotsumrenewal),
            lotsumbol = nvl(upper(rtrim(in_lotsumbol)),lotsumbol),
            lotsumaccess = nvl(upper(rtrim(in_lotsumaccess)),lotsumaccess),
            lotfmtaction = nvl(upper(rtrim(in_lotfmtaction)),lotfmtaction),
            serialfmtaction = nvl(upper(rtrim(in_serialfmtaction)),serialfmtaction),
            user1fmtaction = nvl(upper(rtrim(in_user1fmtaction)),user1fmtaction),
            user2fmtaction = nvl(upper(rtrim(in_user2fmtaction)),user2fmtaction),
            user3fmtaction = nvl(upper(rtrim(in_user3fmtaction)),user3fmtaction),
            maxqtyof1 = nvl(upper(rtrim(in_maxqtyof1)),maxqtyof1),
            rategroup = nvl(upper(rtrim(in_rategroup)),rategroup),
            serialasncapture = nvl(upper(rtrim(in_serialasncapture)),serialasncapture),
            user1asncapture = nvl(upper(rtrim(in_user1asncapture)),user1asncapture),
            user2asncapture = nvl(upper(rtrim(in_user2asncapture)),user2asncapture),
            user3asncapture = nvl(upper(rtrim(in_user3asncapture)),user3asncapture),
            labelqty=decode(in_labelqty, null,labelqty, 0,labelqty, in_labelqty),
            labeluom=nvl(upper(rtrim(in_labeluom)), labeluom),
            allow_uom_chgs=wrk.allow_uom_chgs,
            lotfmtruleid = nvl(upper(rtrim(in_lotfmtruleid)),lotfmtruleid),
            serialfmtruleid = nvl(upper(rtrim(in_serialfmtruleid)),serialfmtruleid),
            user1fmtruleid = nvl(upper(rtrim(in_user1fmtruleid)),user1fmtruleid),
            user2fmtruleid = nvl(upper(rtrim(in_user2fmtruleid)),user2fmtruleid),
            user3fmtruleid = nvl(upper(rtrim(in_user3fmtruleid)),user3fmtruleid),
            inventoryclass = nvl(upper(rtrim(in_inventoryclass)),inventoryclass),
            invstatus = nvl(upper(rtrim(in_invstatus)),invstatus),
            use_fifo = nvl(upper(rtrim(in_use_fifo)),use_fifo),
			parseruleid = rtrim(in_parseruleid),
			parseentryfield = rtrim(in_parseentryfield),
			parseruleaction = rtrim(in_parseruleaction)
      where custid = upper(rtrim(in_custid))
        and item = upper(rtrim(in_item));
   else
      update custitem
        set descr = nvl(rtrim(in_descr),descr),
            abbrev = nvl(rtrim(in_abbrev),abbrev),
            status = wrk.status,
            baseuom = nvl(upper(rtrim(in_baseuom)),baseuom),
            cube = nvl(in_cube,cube),
            weight = nvl(in_weight,weight),
            tareweight = nvl(in_tareweight,tareweight),
            hazardous = nvl(upper(rtrim(in_hazardous)),hazardous),
            shelflife = nvl(in_shelflife,shelflife),
            lastuser = 'IMPITEM',
            lastupdate = sysdate,
            needs_review_yn = wrk.needs_review_yn,
            length = nvl(in_length,length),
            width = nvl(in_width,width),
            height = nvl(in_height,height),
            nmfc = nvl(in_nmfc,nmfc),
            nmfc_article = nvl(in_nmfc_article,nmfc_article),
            tms_commodity_code = in_tms_commodity_code,
            useramt1 = in_useramt1,
            useramt2 = in_useramt2,
            itmpassthrunum01=nvl(in_passthrunum01, itmpassthrunum01),
            itmpassthrunum02=nvl(in_passthrunum02, itmpassthrunum02),
            itmpassthrunum03=nvl(in_passthrunum03, itmpassthrunum03),
            itmpassthrunum04=nvl(in_passthrunum04, itmpassthrunum04),
            itmpassthrunum05=nvl(in_passthrunum05, itmpassthrunum05),
            itmpassthrunum06=nvl(in_passthrunum06, itmpassthrunum06),
            itmpassthrunum07=nvl(in_passthrunum07, itmpassthrunum07),
            itmpassthrunum08=nvl(in_passthrunum08, itmpassthrunum08),
            itmpassthrunum09=nvl(in_passthrunum09, itmpassthrunum09),
            itmpassthrunum10=nvl(in_passthrunum10, itmpassthrunum10),
            itmpassthruchar01=nvl(in_passthruchar01, itmpassthruchar01),
            itmpassthruchar02=nvl(in_passthruchar02, itmpassthruchar02),
            itmpassthruchar03=nvl(in_passthruchar03, itmpassthruchar03),
            itmpassthruchar04=nvl(in_passthruchar04, itmpassthruchar04),
            itmpassthruchar05=nvl(in_passthruchar05, itmpassthruchar05),
            itmpassthruchar06=nvl(in_passthruchar06, itmpassthruchar06),
            itmpassthruchar07=nvl(in_passthruchar07, itmpassthruchar07),
            itmpassthruchar08=nvl(in_passthruchar08, itmpassthruchar08),
            itmpassthruchar09=nvl(in_passthruchar09, itmpassthruchar09),
            itmpassthruchar10=nvl(in_passthruchar10, itmpassthruchar10),
            productgroup=nvl(upper(rtrim(in_productgroup)),productgroup),
            recvinvstatus=nvl(upper(rtrim(in_recvinvstatus)),recvinvstatus),
            lotrequired=nvl(in_lotrequired, lotrequired),
            serialrequired=nvl(in_serialrequired, serialrequired),
            user1required=nvl(in_user1required, user1required),
            user2required=nvl(in_user2required, user2required),
            user3required=nvl(in_user3required, user3required),
            mfgdaterequired=nvl(in_mfgdaterequired, mfgdaterequired),
            expdaterequired=nvl(in_expdaterequired, expdaterequired),
            countryrequired=nvl(in_countryrequired, countryrequired),
            allowsub=nvl(in_allowsub, allowsub),
            backorder=nvl(in_backorder, backorder),
            invstatusind=nvl(in_invstatusind, invstatusind),
            invclassind=nvl(in_invclassind, invclassind),
            qtytype=nvl(in_qtytype, qtytype),
            weightcheckrequired=nvl(in_weightcheckrequired, weightcheckrequired),
            ordercheckrequired=nvl(in_ordercheckrequired, ordercheckrequired),
            fifowindowdays=nvl(in_fifowindowdays, fifowindowdays),
            putawayconfirmation=nvl(in_putawayconfirmation, putawayconfirmation),
            velocity=nvl(upper(rtrim(in_velocity)),velocity),
            nodamaged=nvl(in_nodamaged, nodamaged),
            iskit=nvl(upper(rtrim(in_iskit)),iskit),
            picktotype=nvl(upper(rtrim(in_picktotype)), picktotype),
            cartontype = nvl(upper(rtrim(in_cartontype)),cartontype),
            subslprsnrequired = nvl(upper(rtrim(in_subslprsnrequired)),subslprsnrequired),
            lotsumreceipt = nvl(upper(rtrim(in_lotsumreceipt)),lotsumreceipt),
            lotsumrenewal = nvl(upper(rtrim(in_lotsumrenewal)),lotsumrenewal),
            lotsumbol = nvl(upper(rtrim(in_lotsumbol)),lotsumbol),
            lotsumaccess = nvl(upper(rtrim(in_lotsumaccess)),lotsumaccess),
            lotfmtaction = nvl(upper(rtrim(in_lotfmtaction)),lotfmtaction),
            serialfmtaction = nvl(upper(rtrim(in_serialfmtaction)),serialfmtaction),
            user1fmtaction = nvl(upper(rtrim(in_user1fmtaction)),user1fmtaction),
            user2fmtaction = nvl(upper(rtrim(in_user2fmtaction)),user2fmtaction),
            user3fmtaction = nvl(upper(rtrim(in_user3fmtaction)),user3fmtaction),
            maxqtyof1 = nvl(upper(rtrim(in_maxqtyof1)),maxqtyof1),
            rategroup = nvl(upper(rtrim(in_rategroup)),rategroup),
            serialasncapture = nvl(upper(rtrim(in_serialasncapture)),serialasncapture),
            user1asncapture = nvl(upper(rtrim(in_user1asncapture)),user1asncapture),
            user2asncapture = nvl(upper(rtrim(in_user2asncapture)),user2asncapture),
            user3asncapture = nvl(upper(rtrim(in_user3asncapture)),user3asncapture),
            labelqty=nvl(upper(rtrim(in_labelqty)), labelqty),
            labeluom=nvl(upper(rtrim(in_labeluom)), labeluom),
            allow_uom_chgs=wrk.allow_uom_chgs,
            lotfmtruleid = nvl(upper(rtrim(in_lotfmtruleid)),lotfmtruleid),
            serialfmtruleid = nvl(upper(rtrim(in_serialfmtruleid)),serialfmtruleid),
            user1fmtruleid = nvl(upper(rtrim(in_user1fmtruleid)),user1fmtruleid),
            user2fmtruleid = nvl(upper(rtrim(in_user2fmtruleid)),user2fmtruleid),
            user3fmtruleid = nvl(upper(rtrim(in_user3fmtruleid)),user3fmtruleid),
            inventoryclass = nvl(upper(rtrim(in_inventoryclass)),inventoryclass),
            invstatus = nvl(upper(rtrim(in_invstatus)),invstatus),
            use_fifo = nvl(upper(rtrim(in_use_fifo)),use_fifo),
			parseruleid = rtrim(in_parseruleid),
			parseentryfield = rtrim(in_parseentryfield),
			parseruleaction = rtrim(in_parseruleaction)
      where custid = upper(rtrim(in_custid))
        and item = upper(rtrim(in_item));
   end if;
end if;

if (upper(rtrim(in_func)) = 'A' or 
    (upper(rtrim(in_func)) = 'U' and nvl(in_uom_update,'N') = 'Y')) then
    null; 
  if (rtrim(in_to_uom1) is not null) and
     (nvl(in_to_uom1_qty,0) <> 0) then
    uom_sequence := 10;
    update_uom(uom_sequence, in_to_uom1_qty,
        nvl(upper(rtrim(in_baseuom)),'EA'),
        upper(rtrim(in_to_uom1)),
        in_to_uom1_weight,
        in_to_uom1_cube,
        in_to_uom1_length,
        in_to_uom1_width,
        in_to_uom1_height,
        in_velocity1,
        in_picktotype1,
        in_cartontype1);

    if (rtrim(in_to_uom2) is not null) and
       (nvl(in_to_uom2_qty,0) <> 0) then
      uom_sequence := uom_sequence + 10;
      update_uom(uom_sequence, in_to_uom2_qty,
        upper(rtrim(in_to_uom1)),
        upper(rtrim(in_to_uom2)),
        in_to_uom2_weight,
        in_to_uom2_cube,
        in_to_uom2_length,
        in_to_uom2_width,
        in_to_uom2_height,
        in_velocity2,
        in_picktotype2,
        in_cartontype2);

      if (rtrim(in_to_uom3) is not null) and
         (nvl(in_to_uom3_qty,0) <> 0) then
        uom_sequence := uom_sequence + 10;

      update_uom(uom_sequence, in_to_uom3_qty,
        upper(rtrim(in_to_uom2)),
        upper(rtrim(in_to_uom3)),
        in_to_uom3_weight,
        in_to_uom3_cube,
        in_to_uom3_length,
        in_to_uom3_width,
        in_to_uom3_height,
        in_velocity3,
        in_picktotype3,
        in_cartontype3);

        if (rtrim(in_to_uom4) is not null) and
           (nvl(in_to_uom4_qty,0) <> 0) then
          uom_sequence := uom_sequence + 10;

          update_uom(uom_sequence, in_to_uom4_qty,
            upper(rtrim(in_to_uom3)),
            upper(rtrim(in_to_uom4)),
            in_to_uom4_weight,
            in_to_uom4_cube,
            in_to_uom4_length,
            in_to_uom4_width,
            in_to_uom4_height,
            in_velocity4,
            in_picktotype4,
            in_cartontype4);

          if (rtrim(in_to_uom5) is not null) and
             (nvl(in_to_uom5_qty,0) <> 0) then
            uom_sequence := uom_sequence + 10;

            update_uom(uom_sequence, in_to_uom5_qty,
              upper(rtrim(in_to_uom4)),
              upper(rtrim(in_to_uom5)),
              in_to_uom5_weight,
              in_to_uom5_cube,
              in_to_uom5_length,
              in_to_uom5_width,
              in_to_uom5_height,
              in_velocity5,
              in_picktotype5,
              in_cartontype5);

            if (rtrim(in_to_uom6) is not null) and
               (nvl(in_to_uom6_qty,0) <> 0) then
              uom_sequence := uom_sequence + 10;

              update_uom(uom_sequence, in_to_uom6_qty,
                upper(rtrim(in_to_uom5)),
                upper(rtrim(in_to_uom6)),
                in_to_uom6_weight,
                in_to_uom6_cube,
                in_to_uom6_length,
                in_to_uom6_width,
                in_to_uom6_height,
                in_velocity6,
                in_picktotype6,
                in_cartontype6);

              if (rtrim(in_to_uom7) is not null) and
                 (nvl(in_to_uom7_qty,0) <> 0) then
                uom_sequence := uom_sequence + 10;

                update_uom(uom_sequence, in_to_uom7_qty,
                  upper(rtrim(in_to_uom6)),
                  upper(rtrim(in_to_uom7)),
                  in_to_uom7_weight,
                  in_to_uom7_cube,
                  in_to_uom7_length,
                  in_to_uom7_width,
                  in_to_uom7_height,
                  in_velocity7,
                  in_picktotype7,
                  in_cartontype7);

                if (rtrim(in_to_uom8) is not null) and
                   (nvl(in_to_uom8_qty,0) <> 0) then
                  uom_sequence := uom_sequence + 10;

                  update_uom(uom_sequence, in_to_uom8_qty,
                    upper(rtrim(in_to_uom7)),
                    upper(rtrim(in_to_uom8)),
                    in_to_uom8_weight,
                    in_to_uom8_cube,
                    in_to_uom8_length,
                    in_to_uom8_width,
                    in_to_uom8_height,
                    in_velocity8,
                    in_picktotype8,
                    in_cartontype8);

                  if (rtrim(in_to_uom9) is not null) and
                     (nvl(in_to_uom9_qty,0) <> 0) then
                    uom_sequence := uom_sequence + 10;

                    update_uom(uom_sequence, in_to_uom9_qty,
                      upper(rtrim(in_to_uom8)),
                      upper(rtrim(in_to_uom9)),
                      in_to_uom9_weight,
                      in_to_uom9_cube,
                      in_to_uom9_length,
                      in_to_uom9_width,
                      in_to_uom9_height,
                      in_velocity9,
                      in_picktotype9,
                      in_cartontype9);

                    if (rtrim(in_to_uom10) is not null) and
                       (nvl(in_to_uom10_qty,0) <> 0) then
                      uom_sequence := uom_sequence + 10;

                      update_uom(uom_sequence, in_to_uom10_qty,
                        upper(rtrim(in_to_uom9)),
                        upper(rtrim(in_to_uom10)),
                        in_to_uom10_weight,
                        in_to_uom10_cube,
                        in_to_uom10_length,
                        in_to_uom10_width,
                        in_to_uom10_height,
                        in_velocity10,
                        in_picktotype10,
                        in_cartontype10);

                    end if;
                  end if;
                end if;
              end if;

        end if;
      end if;
    end if;
      end if;
    end if;

    if upper(rtrim(in_func)) = 'U' then
       delete from custitemuom
          where custid = upper(rtrim(in_custid))
            and item = upper(rtrim(in_item))
            and sequence > uom_sequence;
       out_msg := 'Highest UOM sequence added or updated: '|| uom_sequence||'. '||sql%rowcount||' UOM sequences deleted.';
       log_msg('W');
    end if;

  end if;
end if;


if rtrim(in_bolcomment) is not null then
  begin
    insert into custitembolcomments
     (custid,item,consignee,comment1,lastuser,lastupdate)
    values
     (upper(rtrim(in_custid)),upper(rtrim(in_item)),null,
      in_bolcomment,'IMPITEM',sysdate);
  exception when dup_val_on_index then
    update custitembolcomments
       set comment1 = in_bolcomment,
           lastuser = 'IMPITEM',
           lastupdate = sysdate
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and consignee is null;
  end;

end if;


-- Add the aliases if they have been provided

if rtrim(in_alias) is not null then
    add_alias(in_alias, in_aliasdesc, in_alias_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias2) is not null then
    add_alias(in_alias2, in_alias2desc, in_alias2_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias3) is not null then
    add_alias(in_alias3, in_alias3desc, in_alias3_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias4) is not null then
    add_alias(in_alias4, in_alias4desc, in_alias4_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias5) is not null then
    add_alias(in_alias5, in_alias5desc, in_alias5_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias6) is not null then
    add_alias(in_alias6, in_alias6desc, in_alias6_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias7) is not null then
    add_alias(in_alias7, in_alias7desc, in_alias7_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
if rtrim(in_alias8) is not null then
    add_alias(in_alias8, in_alias8desc, in_alias8_partial_match_yn, cs.duplicate_aliases_allowed);
end if;
  exception when others then
  out_msg := 'zimi ' || sqlerrm;
  out_errorno := sqlcode;
end import_832_item;

procedure import_832_component
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_component IN varchar2
,in_qty IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
cursor curCustomer is
  select name
    from customer
   where custid = upper(rtrim(in_custid));
cs curCustomer%rowtype;

cursor curCustItem(in_item varchar2) is
  select item,descr,status, iskit
    from custitem
   where custid = upper(rtrim(in_custid))
     and item = upper(rtrim(in_item));
ci curCustItem%rowtype;

cursor curCustComponent is
  select *
    from workordercomponents
   where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and component = upper(rtrim(in_component));
woc workordercomponents%rowtype;

procedure log_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := ' Item: ' || rtrim(in_item) || ': ' || out_msg;
  zms.log_msg('IMPEXP', null, rtrim(in_custid),
    out_msg, nvl(rtrim(in_msgtype),'E'), 'IMPCOMP', strMsg);
end;

begin
  out_msg := '';
  out_errorno := 0;

if rtrim(upper(in_func)) not in ('A','U','D') then
      out_errorno := 4;
      out_msg := 'Invalid function code: ' || in_func;
  log_msg('E');
  return;
end if;

if rtrim(in_custid) is null then
  out_errorno := 1;
  out_msg := 'Customer ID is required';
  log_msg('E');
  return;
end if;

if nvl(in_qty,0) <= 0 then
  out_errorno := 7;
  out_msg := 'Quantity is required';
  log_msg('E');
  return;
end if;

-- verify customer

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.name is null then
  out_errorno := 2;
  out_msg := 'Invalid Customer ID: ' || in_custid;
      log_msg('E');
      return;
    end if;

if rtrim(in_item) is null then
  out_errorno := 3;
  out_msg := 'Item ID is required';
  log_msg('E');
  return;
end if;

-- verify item
ci := null;
open curCustItem(in_item);
fetch curCustItem into ci;
close curCustItem;

if ci.item is null then
  out_errorno := 5;
  out_msg := 'Invalid Item:'||in_custid||'/'||in_item;
  log_msg('E');
  return;
end if;

--verify kit type

if nvl(ci.iskit,'N') not in ('S','O','C','P') then
  out_errorno := 6;
out_msg := 'Invalid kit type for item:'||ci.iskit;
  log_msg('E');
  return;
end if;

-- verify component
ci := null;
open curCustItem(in_component);
fetch curCustItem into ci;
close curCustItem;

if ci.item is null then
  out_errorno := 5;
  out_msg := 'Invalid Component:'||in_custid||'/'||in_component;
  log_msg('E');
  return;
end if;

-- read component
woc := null;
open curCustComponent;
fetch curCustComponent into woc;
close curCustComponent;

if woc.item is null then
    if upper(rtrim(in_func)) = 'D' then
        out_errorno := 7;
        out_msg := 'Component not found for deletion:'||in_component;
        log_msg('E');
        return;
    end if;
  if upper(rtrim(in_func)) = 'U' then
    out_msg := 'Component not found for update (add performed): '
        || in_component;
    log_msg('W');
    in_func := 'A';
  end if;
else
  if upper(rtrim(in_func)) = 'A' then
    out_msg := 'Component to be added already on file (update performed): '
            || in_component;
    log_msg('W');
    in_func := 'U';
  end if;
end if;


if upper(rtrim(in_func)) = 'A' then
    insert into workordercomponents (custid, item, component, qty)
        values (upper(rtrim(in_custid)),upper(rtrim(in_item)),
            upper(rtrim(in_component)), in_qty);
elsif upper(rtrim(in_func)) = 'U' then
    update workordercomponents
       set qty = in_qty
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and component = upper(rtrim(in_component));

elsif upper(rtrim(in_func)) = 'D' then
    delete workordercomponents
     where custid = upper(rtrim(in_custid))
       and item = upper(rtrim(in_item))
       and component = upper(rtrim(in_component));
end if;

exception when others then
  out_msg := 'zimc ' || sqlerrm;
  out_errorno := sqlcode;
end import_832_component;

FUNCTION order_count_on_load
(in_loadno IN number
) return number is

out_count integer;

begin

out_count := 0;

select count(1)
  into out_count
  from orderhdr
 where loadno = in_loadno
   and orderstatus != 'X';

return out_count;

exception when others then
  return 0;
end order_count_on_load;

FUNCTION order_seq_on_load
(in_loadno IN number
,in_orderid IN number
,in_shipid IN number
) return number is

cursor curOrders is
  select orderid,shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X'
   order by orderid,shipid;

out_seq integer;
orderfound boolean;
begin

out_seq := 0;
orderfound := False;

for oh in curOrders
loop
  out_seq := out_seq + 1;
  if oh.orderid = in_orderid and
     oh.shipid = in_shipid then
    orderfound := True;
    exit;
  end if;
end loop;

if orderfound = False then
  out_seq := 0;
end if;

return out_seq;

exception when others then
  return 0;
end order_seq_on_load;

end zimportprocsb;
/
show error package body zimportprocsb;
exit;
