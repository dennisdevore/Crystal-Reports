create or replace package body alps.zimportproc10 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure import_postalcodes
(in_code IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_code) is null then
  out_errorno := -1;
  out_msg := 'Code value is needed';
  return;
end if;

if rtrim(in_descr) is null then
  out_errorno := -1;
  out_msg := 'Description value is needed';
  return;
end if;

if rtrim(in_abbrev) is null then
  out_errorno := -1;
  out_msg := 'Abbreviation value is needed';
  return;
end if;

insert into postalcodes
(code,descr,abbrev,dtlupdate,lastuser,lastupdate)
values
(in_code,in_descr,in_abbrev,'Y','CONV',sysdate);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
    out_msg := 'zimipc' || sqlerrm;
    out_errorno := sqlcode;
end import_postalcodes;

procedure import_nmfc
(in_nmfc IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_class IN NUMBER
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_nmfc) is null then
  out_errorno := -1;
    out_msg := 'NMFC value is needed';
      return;
      end if;

      if rtrim(in_descr) is null then
        out_errorno := -1;
          out_msg := 'Description value is needed';
            return;
            end if;

            if rtrim(in_abbrev) is null then
              out_errorno := -1;
                out_msg := 'Abbreviation value is needed';
                  return;
                  end if;

                  insert into nmfclasscodes
                  (nmfc,descr,abbrev,class,lastuser,lastupdate)
                  values
                  (in_nmfc,in_descr,in_abbrev,in_class,'CONV',sysdate);

              out_msg := 'OKAY';
              out_errorno := 0;

                  exception when others then
                      out_msg := 'ziminm' || sqlerrm;
                          out_errorno := sqlcode;
                          end import_nmfc;


procedure import_custconsignee
(in_custid IN varchar2
,in_consignee IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_custid) is null then
  out_errorno := -1;
      out_msg := 'Custid value is needed';
            return;
                  end if;

   if rtrim(in_consignee) is null then
     out_errorno := -1;
      out_msg := 'Consignee value is needed';
         return;
                  end if;

insert into custconsignee
   (custid,consignee,lastuser,lastupdate)
      values
   (in_custid,in_consignee,'CONV',sysdate);

  out_msg := 'OKAY';
  out_errorno := 0;

 exception when others then
     out_msg := 'zimicc' || sqlerrm;
       out_errorno := sqlcode;
                                                                                 end import_custconsignee;



procedure import_countrycodes
(in_code in varchar2
,in_descr in varchar2
,in_abbrev in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin
if rtrim(in_code) is null then
  out_errorno := -1;
  out_msg := 'Code value is needed';
                    return;
                                      end if;

  if rtrim(in_descr) is null then
       out_errorno := -1;
       out_msg := 'Description value is needed';
                   return;
                                     end if;

     if rtrim(in_abbrev) is null then
          out_errorno := -1;
          out_msg := 'Abbreviation value is needed';
                   return;
                                     end if;

 insert into countrycodes
    (code,descr,abbrev,dtlupdate,lastuser,lastupdate)
     values
    (in_code,in_descr,in_abbrev,'Y','CONV',sysdate);

     out_msg := 'OKAY';
     out_errorno := 0;


   exception when others then
     out_msg := 'zimico' || sqlerrm;
      out_errorno := sqlcode;

    end import_countrycodes;

procedure import_custitembolcomments
(in_custid in varchar2
,in_item in varchar2
,in_consignee in varchar2
,in_comment1 in LONG
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

insert into custitembolcomments
(custid,item,consignee,comment1,lastuser,lastupdate)
values
(in_custid,in_item,in_consignee,in_comment1,'CONV',sysdate);

 out_msg := 'OKAY';
      out_errorno := 0;

  exception when others then
   out_msg := 'zimicb' || sqlerrm;
         out_errorno := sqlcode;


             end import_custitembolcomments;

procedure import_consignee
(in_custid IN varchar2
,in_func IN OUT varchar2
,in_consignee IN varchar2
,in_name IN varchar2
,in_contact IN varchar2
,in_addr1 IN varchar2
,in_addr2 IN varchar2
,in_city IN varchar2
,in_state IN varchar2
,in_postalcode in varchar2
,in_countrycode in varchar2
,in_phone in varchar2
,in_fax in varchar2
,in_email in varchar2
,in_consigneestatus in varchar2
,in_ltlcarrier in varchar2
,in_tlcarrier in varchar2
,in_spscarrier in varchar2
,in_billto in varchar2
,in_shipto in varchar2
,in_railcarrier in varchar2
,in_billtoconsignee in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,in_apptrequired in varchar2
,in_billforpallets in varchar2
,in_masteraccount in varchar2
,in_bolemail in varchar2
,in_importfileid in varchar2
,in_transaction in varchar2
,in_edi_logging_yn in varchar2
,in_facilitycode in varchar2
,in_shiplabelcode in varchar2
,in_retailabelcode in varchar2
,in_packslipcode in varchar2
,in_tpacct in varchar2
,in_storenumber in varchar2
,in_distctrnumber in varchar2
,in_conspassthruchar01 in varchar2
,in_conspassthruchar02 in varchar2
,in_conspassthruchar03 in varchar2
,in_conspassthruchar04 in varchar2
,in_conspassthruchar05 in varchar2
,in_conspassthruchar06 in varchar2
,in_conspassthruchar07 in varchar2
,in_conspassthruchar08 in varchar2
,in_consorderupdate in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2)
is
cursor curConsignee(in_consignee varchar2) is
  select consignee,consorderupdate,facilitycode,shiplabelcode,retailabelcode,
         packslipcode,tpacct,storenumber,distctrnumber
    from consignee
   where consignee = in_consignee;




co curConsignee%rowtype;
cntRows integer;
procedure consignee_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Cons. ' || rtrim(in_consignee)
        || ': ' || out_msg || ' ' || in_importfileid;
  zms.log_autonomous_msg(IMP_USERID, null, rtrim(in_custid), out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

procedure imp_cons_update_orders(inFacilityCode varchar2, inShipLabelCode varchar2,
                                 inRetaiLabelCode varchar2, inPackSlipCode varchar2,
                                 inTpAcct varchar2, inStoreNumber varchar2,
                                 inDistCtrNumber varchar2) is
cursor curOrder is
  select orderid, shipid, ordertype, shipto
    from orderhdr
   where orderstatus in ('0','1');


begin
for OH in curOrder loop
   if OH.ordertype = 'O' and
      OH.shipto = in_consignee then
       update orderhdr
          set hdrpassthruchar12 = nvl(inFacilityCode,hdrpassthruchar12),
              hdrpassthruchar10 = nvl(inShipLabelCode,hdrpassthruchar10),
              hdrpassthruchar11 = nvl(inRetaiLabelCode,hdrpassthruchar11),
              hdrpassthruchar06 = nvl(inPackSlipCode,hdrpassthruchar06),
              hdrpassthruchar08 = nvl(inTpAcct,hdrpassthruchar08),
              hdrpassthruchar33 = nvl(inStoreNumber,hdrpassthruchar33),
              hdrpassthruchar50 = nvl(inDistCtrNumber,hdrpassthruchar50),
              lastuser = IMP_USERID,
              lastupdate = SYSDATE
          where orderid = OH.orderid
            and shipid = OH.shipid;
   end if;
end loop;

end imp_cons_update_orders;

begin
if nvl(in_edi_logging_yn,'N') = 'Y' then
   zedi.edi_import_log(in_transaction, in_importfileid, in_custid, 'CONSIGNEE: ' || in_consignee, out_msg);
end if;
out_msg := 0;
out_errorno := 0;

if in_consignee is null then
   out_errorno := 2;
   out_msg := 'Consignee not provided';
   consignee_msg('E');
   return;
end if;
if nvl(rtrim(in_func),'x') not in ('A','U','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  consignee_msg('E');
  return;
end if;

open curconsignee(in_consignee);
fetch curconsignee into co;
if curconsignee%found then
   if rtrim(in_func) = 'A' then
      out_msg := 'Add requested--cosignee already on file--update performed';
      consignee_msg('W');
      in_func := 'U';
   end if;
else
  if rtrim(in_func) in ('U','R') then
     out_msg := 'Update requested--consignee not on file--add performed';
     consignee_msg('W');
     in_func := 'A';
  end if;
end if;

close curconsignee;

if in_func = 'A' then
  insert into consignee
   (consignee,name,contact,addr1,addr2,city,state,
    postalcode,countrycode,phone,fax,email,consigneestatus,
    lastuser,lastupdate,ltlcarrier,tlcarrier,spscarrier,billto,
    shipto,railcarrier,billtoconsignee,shiptype,shipterms,
    apptrequired,billforpallets,masteraccount,bolemail,
    facilitycode,shiplabelcode,retailabelcode,packslipcode,tpacct,
    storenumber,distctrnumber,conspassthruchar01,conspassthruchar02,
    conspassthruchar03,conspassthruchar04,conspassthruchar05,
    conspassthruchar06,conspassthruchar07,conspassthruchar08,
    consorderupdate, importfileid, importdate)
    values
      (rtrim(in_consignee),rtrim(in_name),rtrim(in_contact),rtrim(in_addr1),rtrim(in_addr2),rtrim(in_city),rtrim(in_state),
       rtrim(in_postalcode),rtrim(in_countrycode),rtrim(in_phone),rtrim(in_fax),rtrim(in_email),rtrim(in_consigneestatus),
       IMP_USERID,sysdate,rtrim(in_ltlcarrier),rtrim(in_tlcarrier),rtrim(in_spscarrier),rtrim(in_billto),
       rtrim(in_shipto),rtrim(in_railcarrier),rtrim(in_billtoconsignee),rtrim(in_shiptype),rtrim(in_shipterms),
       rtrim(in_apptrequired),rtrim(in_billforpallets),rtrim(in_masteraccount),rtrim(in_bolemail),
       rtrim(in_facilitycode),rtrim(in_shiplabelcode),rtrim(in_retailabelcode),rtrim(in_packslipcode),rtrim(in_tpacct),
       rtrim(in_storenumber),rtrim(in_distctrnumber),rtrim(in_conspassthruchar01),rtrim(in_conspassthruchar02),
       rtrim(in_conspassthruchar03),rtrim(in_conspassthruchar04),rtrim(in_conspassthruchar05),
       rtrim(in_conspassthruchar06),rtrim(in_conspassthruchar07),rtrim(in_conspassthruchar08),
       rtrim(in_consorderupdate), rtrim(in_importfileid), sysdate);
elsif in_func = 'U' then
   update consignee
      set name = nvl(in_name,name),
          contact = nvl(in_contact,contact),
          addr1 = nvl(in_addr1,addr1),
          addr2 = nvl(in_addr2,addr2),
          city = nvl(in_city,city),
          state = nvl(in_state,state),
          postalcode = nvl(in_postalcode,postalcode),
          countrycode = nvl(in_countrycode,countrycode),
          phone = nvl(in_phone,phone),
          fax = nvl(in_fax,fax),
          email = nvl(in_email,email),
          consigneestatus = nvl(in_consigneestatus,consigneestatus),
          lastuser = IMP_USERID,
          lastupdate = SYSDATE,
          ltlcarrier = nvl(in_ltlcarrier,ltlcarrier),
          tlcarrier = nvl(in_tlcarrier,tlcarrier),
          spscarrier = nvl(in_spscarrier,spscarrier),
          billto = nvl(in_billto,billto),
          shipto = nvl(in_shipto,shipto),
          railcarrier = nvl(in_railcarrier,railcarrier),
          billtoconsignee = nvl(in_billtoconsignee,billtoconsignee),
          shiptype = nvl(in_shiptype,shiptype),
          shipterms = nvl(in_shipterms,shipterms),
          apptrequired = nvl(in_apptrequired,apptrequired),
          billforpallets = nvl(in_billforpallets,billforpallets),
          masteraccount = nvl(in_masteraccount,masteraccount),
          bolemail = nvl(in_bolemail,bolemail),
          facilitycode = nvl(in_facilitycode,facilitycode),
          shiplabelcode = nvl( in_shiplabelcode,shiplabelcode),
          retailabelcode = nvl(in_retailabelcode, retailabelcode),
          packslipcode = nvl(in_packslipcode,packslipcode),
          tpacct = nvl(in_tpacct,tpacct),
          storenumber = nvl(in_storenumber, storenumber),
          distctrnumber = nvl( in_distctrnumber,distctrnumber),
          conspassthruchar01 = nvl(in_conspassthruchar01,conspassthruchar01),
          conspassthruchar02 = nvl(in_conspassthruchar02,conspassthruchar02),
          conspassthruchar03 = nvl(in_conspassthruchar03,conspassthruchar03),
          conspassthruchar04 = nvl(in_conspassthruchar04,conspassthruchar04),
          conspassthruchar05 = nvl(in_conspassthruchar05,conspassthruchar05),
          conspassthruchar06 = nvl(in_conspassthruchar06,conspassthruchar06),
          conspassthruchar07 = nvl(in_conspassthruchar07,conspassthruchar07),
          conspassthruchar08 = nvl(in_conspassthruchar08,conspassthruchar08),
          consorderupdate = nvl(in_consorderupdate,consorderupdate),
          importfileid = in_importfileid,
          importdate = sysdate
      where consignee = rtrim(in_consignee);
elsif in_func = 'R' then
   update consignee
      set name = in_name,
          contact = in_contact,
          addr1 = in_addr1,
          addr2 = in_addr2,
          city = in_city,
          state = in_state,
          postalcode = in_postalcode,
          countrycode = in_countrycode,
          phone = in_phone,
          fax = in_fax,
          email = in_email,
          consigneestatus = in_consigneestatus,
          lastuser = IMP_USERID,
          lastupdate = SYSDATE,
          ltlcarrier = in_ltlcarrier,
          tlcarrier = in_tlcarrier,
          spscarrier = in_spscarrier,
          billto = in_billto,
          shipto = in_shipto,
          railcarrier = in_railcarrier,
          billtoconsignee = in_billtoconsignee,
          shiptype = in_shiptype,
          shipterms = in_shipterms,
          apptrequired = in_apptrequired,
          billforpallets = in_billforpallets,
          masteraccount = in_masteraccount,
          bolemail = in_bolemail,
          facilitycode = in_facilitycode,
          shiplabelcode = in_shiplabelcode,
          retailabelcode = in_retailabelcode,
          packslipcode = in_packslipcode,
          tpacct = in_tpacct,
          storenumber = in_storenumber,
          distctrnumber = in_distctrnumber,
          conspassthruchar01 = in_conspassthruchar01,
          conspassthruchar02 = in_conspassthruchar02,
          conspassthruchar03 = in_conspassthruchar03,
          conspassthruchar04 = in_conspassthruchar04,
          conspassthruchar05 = in_conspassthruchar05,
          conspassthruchar06 = in_conspassthruchar06,
          conspassthruchar07 = in_conspassthruchar07,
          conspassthruchar08 = in_conspassthruchar08,
          consorderupdate = consorderupdate,
          importfileid = in_importfileid,
          importdate = sysdate
      where consignee = in_consignee;
end if;
out_msg := 'OKAY';
if in_custid is not null then
   select count(1) into cntRows
      from custconsignee
      where custid = in_custid
        and consignee = in_consignee;
   if cntRows = 0 then
      insert into custconsignee
         (custid,consignee,export_format_856,lastuser,lastupdate)
      values
         (in_custid,in_consignee,'Use SIP Default', IMP_USERID,sysdate);
   end if;
end if;

if nvl(in_consorderupdate,'N') = 'Y' or
   nvl(co.consorderupdate,'N') = 'Y' then
    if in_func = 'A' then
       imp_cons_update_orders(in_facilitycode, in_shiplabelcode,in_retailabelcode,
                              in_packslipcode,in_tpacct,in_storenumber,in_distctrnumber);
    else
       if in_facilitycode is not null or
          in_shiplabelcode is not null or
          in_retailabelcode is not null or
          in_packslipcode is not null or
          in_tpacct is not null or
          in_storenumber is not null or
          in_distctrnumber is not null then
          if in_func = 'U' then
             imp_cons_update_orders(nvl(in_facilitycode,co.facilitycode), nvl(in_shiplabelcode,co.shiplabelcode),
                                    nvl(in_retailabelcode,co.retailabelcode),
                                    nvl(in_packslipcode,co.packslipcode),nvl(in_tpacct,co.tpacct),
                                    nvl(in_storenumber,co.storenumber),nvl(in_distctrnumber,co.distctrnumber));
          else
             imp_cons_update_orders(in_facilitycode,in_shiplabelcode,in_retailabelcode,
                                    in_packslipcode,in_tpacct,in_storenumber,in_distctrnumber);
          end if;
       end if;
    end if;
end if;
exception when others then
  out_msg := 'zimcons ' || sqlerrm;
  out_errorno := sqlcode;
end import_consignee;

procedure import_label_profile
(
in_profid IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_businessevent IN varchar2
,in_uom IN varchar2
,in_seq IN number
,in_printerstock IN varchar2
,in_copies IN number
,in_print IN varchar2
,in_apply IN varchar2
,in_rfline1 IN varchar2
,in_rfline2 IN varchar2
,in_rfline3 IN varchar2
,in_rfline4 IN varchar2
,in_postprintproc IN varchar2
,in_viewname IN varchar2
,in_viewkeycol IN varchar2
,in_viewkeyorigin IN varchar2
,in_lpspath IN varchar2
,in_passthrufield IN varchar2
,in_passthruvalue IN varchar2
,in_nicewatchport IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)

is
cursor c_lp(in_code varchar2)
is
select *
  from labelprofiles
 where code = in_code;

lp c_lp%rowtype;

cursor c_lpl(in_code varchar2, in_event varchar2, in_uom varchar2,
        in_seq number)
is
select *
  from labelprofileline
 where profid = in_code
   and businessevent = in_event
   and nvl(uom,'(none)') = nvl(in_uom,'(none)')
   and seq = in_seq;

lpl c_lpl%rowtype;

l_cnt integer;
l_pos integer;
l_pos2 integer;
l_owner varchar2(20);
l_schema varchar2(100);
l_pkg   varchar2(30);
l_vn    varchar2(100);
l_str   varchar2(255);

begin
    out_errorno := 0;
    out_msg := '';

-- Verify labelprofiles data
    if in_profid is null then
        out_msg := 'Profile ID required';
        out_errorno := 1;
        return;
    end if;

    if in_descr is null then
        out_msg := 'Profile description required';
        out_errorno := 1;
        return;
    end if;

    if in_abbrev is null then
        out_msg := 'Profile abbreviation required';
        out_errorno := 1;
        return;
    end if;

    lp := null;
    open c_lp(upper(in_profid));
    fetch c_lp into lp;
    close c_lp;

    if lp.code is null then
        insert into labelprofiles (code, descr, abbrev, lastuser, lastupdate)
        values (upper(in_profid), in_descr, in_abbrev, 'IMPPROFILE',sysdate);
    else
        update labelprofiles
           set descr = in_descr,
               abbrev = in_abbrev,
               lastuser = 'IMPPROFILE',
               lastupdate = sysdate
        where code = upper(in_profid);
    end if;

-- Validate the values
    l_cnt := 0;
    select count(1)
      into l_cnt
      from businessevents
     where code = nvl(upper(in_businessevent),'x');
    if nvl(l_cnt,0) = 0 then
        out_msg := 'Invalid business event:'||nvl(in_businessevent,'(none)');
        out_errorno := 1;
        return;
    end if;

    if in_uom is not null then
        l_cnt := 0;
        select count(1)
          into l_cnt
          from unitsofmeasure
         where code = nvl(upper(in_uom),'x');
        if nvl(l_cnt,0) = 0 then
            out_msg := 'Invalid unit of measure:'||nvl(in_uom,'(none)');
            out_errorno := 1;
            return;
        end if;
    end if;

    if in_seq is null then
        out_msg := 'Sequence must be provided';
        out_errorno := 1;
        return;
    end if;

    if in_copies is null then
        out_msg := 'Number of copies must be provided';
        out_errorno := 1;
        return;
    end if;

    if nvl(in_printerstock,'x') not in ('S','M','L') then
        out_msg := 'Invalid printer stock:'||nvl(in_printerstock,'(none)');
        out_errorno := 1;
        return;
    end if;

    if nvl(in_print,'x') not in ('Y','N') then
        out_msg := 'Invalid print option:'||nvl(in_print,'(none)');
        out_errorno := 1;
        return;
    end if;
    if nvl(in_apply,'x') not in ('Y','N') then
        out_msg := 'Invalid apply option:'||nvl(in_apply,'(none)');
        out_errorno := 1;
        return;
    end if;

    if nvl(in_print,'x') = 'Y' then
        if in_lpspath is null then
            out_msg := 'Label Path must be provided if print specified.';
            out_errorno := 1;
            return;
        end if;
    end if;

    if  nvl(in_passthrufield,'x') is not null then
        if substr(in_passthrufield,1,15) != 'HDRPASSTHRUCHAR' then
            out_msg := 'Invalid passthru field:'||in_passthrufield;
            out_errorno := 1;
            return;
        end if;
        begin
            l_cnt := to_number(substr(in_passthrufield,16));
        exception when others then
            l_cnt := 0;
        end;
        if (l_cnt < 1) or (l_cnt > 60) then
            out_msg := 'Invalid passthru field:'||in_passthrufield;
            out_errorno := 1;
            return;
        end if;
    end if;

    if nvl(in_viewkeyorigin,'x') not in ('P','S') then
        out_msg := 'Invalid view key origin:'||nvl(in_viewkeyorigin,'(none)');
        out_errorno := 1;
        return;
    end if;



-- Check view
    begin
        select upper(defaultvalue)
          into l_schema
         from systemdefaults
         where defaultid = 'CUSTOM_SCHEMA';
    exception when others then
        l_schema := '';
    end;

    if in_viewname is null then
        out_msg := 'View name cannot be null';
        out_errorno := 1;
        return;
    end if;

    l_str := upper(in_viewname);

    l_pos := instr(l_str, '.');
    l_pos2 := instr(l_str, '.',l_pos+1);
    l_pkg := '';
    if l_pos = 0 then
        l_owner := 'ALPS';
    else
        l_owner := substr(l_str,1, l_pos-1);
        if (l_owner = nvl(l_schema,'ALPS'))
         and (l_pos2 > 0) then
                l_pkg := substr(l_str, l_pos+1, l_pos2-l_pos-1);
                l_pos := l_pos2;
        else
                l_pkg := l_owner;
                l_owner := 'ALPS';
        end if;

    end if;

    l_vn := substr(l_str, l_pos+1);

    if l_pkg is null then
        select count(1)
          into l_cnt
          from all_views
         where owner = l_owner
           and view_name = l_vn;
    else
        select count(1)
          into l_cnt
          from all_arguments
         where owner = l_owner
           and package_name = l_pkg
           and object_name = l_vn;
    end if;

    if l_cnt < 1 then
        out_msg := 'Invalid view name:'||nvl(in_viewname,'(none)');
        out_errorno := 1;
        return;
    end if;



-- Check view column
    if upper(in_viewkeycol) is not null then
        select count(1)
          into l_cnt
          from user_tab_cols
         where table_name = l_vn
           and column_name = upper(in_viewkeycol);

        if l_cnt < 1 then
            out_msg := 'Invalid view key column name:'||nvl(in_viewkeycol,'(none)');
            out_errorno := 1;
            return;
        end if;
    end if;

-- Check Package
    if in_postprintproc is not null then

        l_str := upper(in_postprintproc);

        l_pos := instr(l_str, '.');
        l_pos2 := instr(l_str, '.', l_pos+1);

        if l_pos2 = 0 then
            l_owner := 'ALPS';
            l_pkg := substr(l_str,1, l_pos-1);
            l_vn := substr(l_str, l_pos+1);
        else
            l_owner := substr(l_str, 1, l_pos-1);
            l_pkg := substr(l_str,l_pos+1, l_pos2-l_pos-1);
            l_vn := substr(l_str, l_pos2+1);
        end if;

        select count(1)
          into l_cnt
          from all_arguments
         where owner = l_owner
           and package_name = l_pkg
           and object_name = l_vn;

        if l_cnt < 1 then
            out_msg := 'Invalid Post Print Proc:'||nvl(in_postprintproc,'(none)');
            out_errorno := 1;
            return;
        end if;

    end if;



    lpl := null;
    open c_lpl(upper(in_profid), in_businessevent, upper(in_uom), in_seq);
    fetch c_lpl into lpl;
    close c_lpl;

    if lpl.profid is null then
        insert into labelprofileline (
            profid,
            businessevent,
            uom,
            seq,
            printerstock,
            copies,
            print,
            apply,
            rfline1,
            rfline2,
            rfline3,
            rfline4,
            scfpath,
            viewname,
            viewkeycol,
            viewkeyorigin,
            facility,
            station,
            prtid,
            lpspath,
            passthrufield,
            passthruvalue,
            nicewatchport,
            lastuser,
            lastupdate
        )
        values
        (
            upper(in_profid),
            upper(in_businessevent),
            upper(in_uom),
            in_seq,
            in_printerstock,
            in_copies,
            in_print,
            in_apply,
            in_rfline1,
            in_rfline2,
            in_rfline3,
            in_rfline4,
            upper(in_postprintproc),
            upper(in_viewname),
            upper(in_viewkeycol),
            in_viewkeyorigin,
            '', --in_facility,
            '', --in_station,
            '', --in_prtid,
            in_lpspath,
            upper(in_passthrufield),
            in_passthruvalue,
            in_nicewatchport,
            'IMPPROFILE',
            sysdate
        );
    else
        update labelprofileline
           set
            printerstock = in_printerstock,
            copies = in_copies,
            print = in_print,
            apply = in_apply,
            rfline1 = in_rfline1,
            rfline2 = in_rfline2,
            rfline3 = in_rfline3,
            rfline4 = in_rfline4,
            scfpath = upper(in_postprintproc),
            viewname = upper(in_viewname),
            viewkeycol = upper(in_viewkeycol),
            viewkeyorigin = in_viewkeyorigin,
            lpspath = in_lpspath,
            passthrufield = upper(in_passthrufield),
            passthruvalue = in_passthruvalue,
            nicewatchport = in_nicewatchport,
            lastuser = 'IMPPROFILE',
            lastupdate = sysdate
         where profid = upper(in_profid)
           and businessevent = upper(in_businessevent)
           and nvl(uom,'(none)') = nvl(upper(in_uom),'(none)')
           and seq = in_seq;

    end if;

exception when others then
    out_errorno := sqlcode;
    out_msg := sqlerrm;
end import_label_profile;



end zimportproc10;
/
show error package body zimportproc10;
exit;
