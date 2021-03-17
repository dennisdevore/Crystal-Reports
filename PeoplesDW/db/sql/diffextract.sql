--
-- $Id$
--
set serveroutput on

create table synapse_excluded_objects
(object_name varchar2(128)
);

truncate table synapse_excluded_objects;

create or replace function search_condition_varchar2
(in_constraint_name varchar2
,in_constraint_type varchar2
,in_table_name varchar2
)
return varchar2

is

l_varchar2 varchar2(4000);
l_sql_cmd varchar2(2000);

begin

l_sql_cmd := 'select search_condition from user_constraints where constraint_name = ''' ||
             in_constraint_name || ''' and constraint_type = ''' || in_constraint_type ||
             ''' and table_name = ''' || in_table_name || '''';
execute immediate l_sql_cmd into l_varchar2;

l_varchar2 := replace(substr(l_varchar2,1,2000),'"','');

return nvl(l_varchar2,'nosearch');

exception when others then
  return null;
end;
/

create or replace function data_default_varchar2
(in_table_name varchar2
,in_column_name varchar2
)
return varchar2

is

l_varchar2 varchar2(32767);
l_sql_cmd varchar2(2000);

begin

if (in_table_name = 'ORDERHDR' and in_column_name = 'EXPANDED_WEBSYNAPSE_FIELDS') or
   (in_table_name = 'CUSTOMER' and in_column_name = 'SHORTSHIPSMALLPKGYN') or -- from matson
   (in_table_name = 'ORDERDTL' and in_column_name = 'RECEIPT_WEIGHT_CONFIRMED') then -- from itl
  return null;
end if;

l_sql_cmd := 'select data_default from user_tab_columns where table_name = ''' ||
             in_table_name || ''' and column_name = ''' || in_column_name || '''';
execute immediate l_sql_cmd into l_varchar2;

l_varchar2 := substr(l_varchar2,1,2000);

return l_varchar2;

exception when others then
  return null;
end;
/

create or replace function data_precision_value
(in_table_name varchar2
,in_column_name varchar2
,in_data_precision number
)
return number

is

begin

if in_data_precision is null then
  if (in_table_name = 'BBB_OVERSIZE_PACKAGES' and in_column_name = 'OVERSIZE_CARTON_COUNT') or
     (in_table_name = 'BBB_ROUTING_SHIPMENT' and in_column_name = 'CARTON_COUNT') or
     (in_table_name = 'IMPEXP_LOG' and in_column_name = 'LOGSEQ') or
     (in_table_name = 'IMPEXP_LOG_DETAIL' and in_column_name = 'LOGSEQ') or
     (in_table_name = 'LBL_SB_VIEW' and in_column_name = 'ITEMINNER') or
     (in_table_name = 'UCC_STANDARD_LABELS' and in_column_name = 'ITEMINNER') or
     (in_table_name = 'UCC_STANDARD_LABELS_TEMP' and in_column_name = 'ITEMINNER') then
    return 38;
  end if;
end if;

return in_data_precision;

exception when others then
  return null;
end;
/

create or replace function data_nullable_value
(in_table_name varchar2
,in_column_name varchar2
,in_nullable varchar2
)
return varchar2

is

begin

if (in_table_name = 'BOLRPT_PRELIM' and in_column_name = 'OD_ITEM') or
   (in_table_name = 'BOLRPT_PRELIM' and in_column_name = 'OD_ORDERID') or
   (in_table_name = 'BOLRPT_PRELIM' and in_column_name = 'OD_SHIPID') then
  return 'Y';
end if;

return in_nullable;

exception when others then
  return null;
end;
/

begin

--dbms_output.put_line('inserting all objects...');

insert into synapse_excluded_objects
  select distinct object_name
    from user_objects;
commit;

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('exiting from load table others...');
  return;
end;
/
declare

cursor curExclude is
  select object_name
    from synapse_excluded_objects;

cntPosition integer;
cntLength integer;
flgUnderScore boolean;
flgCustId boolean;
strCustId varchar2(128);
strExcludePrefix varchar2(128);
lenExcludePrefix integer;
strExcludePrefix2 varchar2(128);
lenExcludePrefix2 integer;
strExcludePrefix3 varchar2(128);
lenExcludePrefix3 integer;
strExcludePrefix4 varchar2(128);
lenExcludePrefix4 integer;
strExcludePrefix5 varchar2(128);
lenExcludePrefix5 integer;

function check_for_valid_custid(in_objectname varchar2,
                                in_objectkey  varchar2) return boolean
is

cntCust integer;
cntLength integer;
begin

if in_objectname like 'OLSON_LBL_%' or
   in_objectname = 'RCPT_NOTE_944_PAL' or
   in_objectname = 'CS3_HP_RETURN_LABEL_VIEW' or
   in_objectname = 'I9_INV_ADJ_DTL' or
   in_objectname = 'I9_INV_ADJ_SUM' or
   in_objectname = 'I9_INV_ADJ_HDR' or
   in_objectname = 'CARRIERSHEET_PALLETS' or
   in_objectname = 'LBL_BP_CS_VIEW' or
   in_objectname = 'LBL_BP_TASK_CS_VIEW' or
   in_objectname = 'SHIP_NT_945_ID_MM' or
   in_objectname = 'SHIP_NT_945_PL_MM' or
   in_objectname = 'BARRETT_TOT_ITEM_CS' or
   in_objectname = 'BARRETT_TOT_ORDER_CS' or
   in_objectname like 'HOR_GIL%' or
   in_objectname = 'LBL_AMAZONGEN_VIEW' or
   in_objectname = 'LBL_HF_TASK_CS_VIEW' or
   in_objectname = 'LBL_HF_WALMART_CS_VIEW' or
   in_objectname = 'LBL_SEARS_VIEW' or
   in_objectname = 'FREIGHT_AIMS_ST' or
   in_objectname = 'SIP_ASN_856_ST' or
   in_objectname = 'SIP_STR_944_ST' or
   in_objectname = 'SIP_WSA_945_ST' or
   in_objectname = 'BILL_EXPORT_QB_SF' or
   in_objectname = 'FREIGHT_AIMS_SE' or
   in_objectname = 'SHIP_NOTE_945_HD' or
   in_objectname = 'SHIP_NT_945_HD' or
   in_objectname = 'SIP_STR_944_HD' or
   in_objectname = 'SIP_WSA_945_HD' or
   in_objectname = 'VICS_BOL_CARRIER_CTN_INFO' or
   in_objectname = 'FREIGHT_BILL_RESULTS' or
   in_objectname = 'SHIP_NOTE_945_PAL' or
   in_objectname = 'CONFIRM_855_HDR' or
   in_objectname = 'CONFIRM_855_LINE' or
   in_objectname = 'GET_210_CHGDTL_VIEW' or
   in_objectname = 'GET_210_HDRHDR_VIEW' or
   in_objectname = 'GET_210_HDR_VIEW' or
   in_objectname = 'GET_210_INVDTL_VIEW' or
   in_objectname = 'GET_210_ORDER_VIEW' or
   in_objectname = 'GET_210_PLATESUM_VIEW' or
   in_objectname = 'GET_210_PLATE_VIEW' or
   in_objectname = 'RCPT_NOTE_944_BDN' or
   in_objectname = 'RCPT_NOTE_944_HDR' or
   in_objectname = 'RCPT_NOTE_944_DTL' or
   in_objectname = 'RCPT_NOTE_944_TRL' or
   in_objectname = 'RCPT_NOTE_944_IDE' or
   in_objectname = 'RCPT_NOTE_944_IHR' or
   in_objectname = 'RCPT_NOTE_944_LIP' or
   in_objectname = 'RCPT_NOTE_944_LTRL' or
   in_objectname = 'RCPT_NOTE_944_LU1' or
   in_objectname = 'RCPT_NOTE_944_MBR' or
   in_objectname = 'RCPT_NOTE_944_NTE' or
   in_objectname = 'SHIP_NOTE_945_NTE' or
   in_objectname = 'SHIP_NOTE_945_IHR' or
   in_objectname = 'SHIP_NOTE_945_HDR' or
   in_objectname = 'SHIP_NOTE_945_DTL' or
   in_objectname = 'SHIP_NOTE_945_DTLT' or
   in_objectname = 'SHIP_NOTE_945_FAC' or
   in_objectname = 'SHIP_NOTE_945_FHD' or
   in_objectname = 'SHIP_NOTE_945_FS' or
   in_objectname = 'SHIP_NOTE_945_IHR' or
   in_objectname = 'SHIP_NOTE_945_MAN' or
   in_objectname = 'SHIP_NOTE_945_MBR' or
   in_objectname = 'SHIP_NOTE_945_LOT' or
   in_objectname = 'SHIP_NOTE_945_LXD' or
   in_objectname = 'SHIP_NOTE_945_TRL' or
   in_objectname = 'SHIP_NOTE_945_SAD' or
   in_objectname = 'SHIP_NOTE_945_SAH' or
   in_objectname = 'SHIP_NOTE_945_SN' or
   in_objectname = 'SHIP_NOTE_945_LTRL' or
   in_objectname = 'SHIP_NOTE_945_NOT' or
   in_objectname = 'SHIP_NOTE_945_OHI' or
   in_objectname = 'SHIP_NOTE_945_LU1' or
   in_objectname = 'SHIP_NOTE_945_MBR' or
   in_objectname = 'SHIP_NOTE_945_ID' or
   in_objectname = 'RCPT_NOTE_944_FAC' or
   in_objectname = 'RCPT_NOTE_944_IDE' or
   in_objectname = 'SHIP_NOTE_856_HDR' or
   in_objectname = 'SHIP_NOTE_856_BOL' or
   in_objectname = 'SHIP_NOTE_856_ID' or
   in_objectname = 'SHIP_NOTE_945_HDR' or
   in_objectname = 'SHIP_NOTE_945_IDE' or
   in_objectname = 'SHIP_NOTE_945_RTV' or
   in_objectname = 'SHIP_NOTE_945_S18' or
   in_objectname = 'SHIP_NOTE_945_BOL' or
   in_objectname = 'SHIP_NOTE_945_CNT' or
   in_objectname = 'SHIP_NOTE_945_CTR' or
   in_objectname = 'SHIP_NOTE_945_DLL' or
   in_objectname = 'SHIP_NT_945_CNT' or
   in_objectname = 'SHIP_NT_945_DTL' or
   in_objectname = 'SHIP_NT_945_HDR' or
   in_objectname = 'SHIP_NT_945_LOT' or
   in_objectname = 'SHIP_NT_945_LXD' or
   in_objectname = 'SHIP_NT_945_MAN' or
   in_objectname = 'SHIP_NT_945_PL' or
   in_objectname = 'SHIP_NT_945_RTV' or
   in_objectname = 'SHIP_NT_945_S18' or
   in_objectname = 'SHIP_NT_945_TRL' or
   in_objectname = 'SHIP_NT_945_ID' or
   in_objectname = 'SIP_ASN_856_DL' or
   in_objectname = 'SIP_ASN_856_HDR' or
   in_objectname = 'SIP_ASN_856_HA' or
   in_objectname = 'SIP_ASN_856_HO' or
   in_objectname = 'SIP_ASN_856_HS' or
   in_objectname = 'SIP_ASN_856_LI' or
   in_objectname = 'SIP_ASN_856_LI2' or
   in_objectname = 'SIP_ASN_856_LK' or
   in_objectname = 'SIP_ASN_856_OA' or
   in_objectname = 'SIP_ASN_856_PO' or
   in_objectname = 'SIP_ASN_856_PO2' or
   in_objectname = 'SIP_STR_944_DR' or
   in_objectname = 'SIP_STR_944_HA' or
   in_objectname = 'SIP_STR_944_HO' or
   in_objectname = 'SIP_STR_944_LI' or
   in_objectname = 'SIP_STR_944_LR' or
   in_objectname = 'SIP_STR_944_RR' or
   in_objectname = 'SIP_WSA_945_AD' or
   in_objectname = 'SIP_WSA_945_DR' or
   in_objectname = 'SIP_WSA_945_HA' or
   in_objectname = 'SIP_WSA_945_AD' or
   in_objectname = 'SIP_WSA_945_HC' or
   in_objectname = 'SIP_WSA_945_HO' or
   in_objectname = 'SIP_WSA_945_LI' or
   in_objectname = 'SIP_WSA_945_LR' or
   in_objectname = 'SIP_WSA_945_HC' or
   in_objectname = 'SIP_WSA_945_RR' or
   in_objectname = 'STOCK_STATUS_846_DTL' or
   in_objectname = 'STOCK_STATUS_846_HDR' or
   in_objectname = 'STOCK_STATUS_846_QTY' or
   in_objectname = 'TEMP_INVENTORY_ADJUSTMENT' or
   in_objectname = 'BOLRPT_FREIGHT' or
   in_objectname = 'WEB_TRANS_LOG' or
   in_objectname = 'ASN_856_DESADV_DEFLT' or
   in_objectname = 'DATA_AUDIT' or
   in_objectname = 'ORDERHDR_AUDIT' or
   in_objectname = 'ORDERHISTORY_TEST' or
   in_objectname = 'SHIPPINGPLATE_AUDIT' or
   in_objectname = 'SHIPPINGPLATE_TEST' or
   in_objectname = 'SHIPSUM_GRAND_TOT' or
   in_objectname = 'SHIPSUM_TOT' or
   in_objectname = 'SHIP_SUMMARY_GRAND_TOT' or
   in_objectname = 'SHIP_SUMMARY_TOT' or
   in_objectname = 'WEBER_ESO_ORDLBL_TABLE' or
   in_objectname = 'WEBER_ESO_ORDLBL_VIEW' or
   in_objectname = 'DATA_AUDIT_SEQ' or
   in_objectname = 'ALERT_CONTACTS_BI' or
   in_objectname = 'ALERT_ESCALATION_BI' or
   in_objectname = 'LOADS_BI' or
   in_objectname = 'MULTISHIP_CHARGES_BI' or
   in_objectname = 'ORDERDTL_BI' or
   in_objectname = 'ORDERHDR_BI' or
   in_objectname = 'APPMSGS_BI' or
   in_objectname = 'PARCELTRACKING_BI' or
   in_objectname = 'PLATE_BI' or
   in_objectname = 'BILL_EXPORT_GP_HDR' or
   in_objectname = 'BILL_EXPORT_GP_DTL' or
   in_objectname = 'BILL_EXPORT_GP_DTS' or
   in_objectname = 'CNTNRS_IN_YARD_RPT_VIEW' or
   in_objectname = 'EMAIL_IN' or
   in_objectname = 'AQ$_QT_RP_EMAIL_IN_E' or
   in_objectname = 'AQ$_QT_RP_PECAS_IN_E' or
   in_objectname = 'IMPORT_846_DETAIL' or
   in_objectname = 'IMPORT_846_HEADER' or
   in_objectname = 'IMPORT_846_QUANTITY' or
   in_objectname = 'IMPORT_945_DETAIL' or
   in_objectname = 'IMPORT_945_HEADER' or
   in_objectname = 'IMPORT_945_QUANTITY' or
   in_objectname = 'LD_TDR_204_ADDR' or
   in_objectname = 'LD_TDR_204_DTL' or
   in_objectname = 'LD_TDR_204_HDR' or
   in_objectname = 'STOCK_STATUS_846_LIP' or
   in_objectname = 'CONSIGNEE_DUNS' or
   in_objectname = 'CONSIGNEE_GLN' or
   in_objectname = 'IMPORT_945_SEQ' or
   in_objectname = 'TBL_GLOBAL_LABEL_REPOSITORY' or
   in_objectname like 'LBL_BERLIN_%' or
   in_objectname = 'WEBER_TMS_214_EXPORT' or
   in_objectname = 'WEBER_TMS_EXPORT' or
   in_objectname = 'PECAS_IN' then
  return False;
end if;

if in_objectname like 'EXPORTFILESEQ_%' then
  return TRUE;
end if;

if in_objectname like 'LAST%' then
  return TRUE;
end if;

cntCust := 0;
begin
  select count(1)
    into cntCust
    from customer
   where custid = in_objectkey;
exception when others then
  null;
end;
if cntCust != 0 then
  return True;
end if;

cntLength := length(in_objectkey);

if (cntLength > 1) and
   (substr(in_objectkey,cntLength,1) >= '0') and
   (substr(in_objectkey,cntLength,1) <= '9') then
  begin
    select count(1)
      into cntCust
      from customer
     where custid = substr(in_objectkey,1,cntLength-1);
  exception when others then
    null;
  end;
  if cntCust != 0 then
    return True;
  end if;
end if;

if (cntLength > 2) and
   (substr(in_objectkey,cntLength,1)   >= '0') and
   (substr(in_objectkey,cntLength,1)   <= '9') and
   (substr(in_objectkey,cntLength-1,1) >= '0') and
   (substr(in_objectkey,cntLength-1,1) <= '9') then
  begin
    select count(1)
      into cntCust
      from customer
     where custid = substr(in_objectkey,1,cntLength-2);
  exception when others then
    null;
  end;
  if cntCust != 0 then
    return True;
  end if;
end if;

return False;

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('valid custid others...');
  return False;
end;

begin

strExcludePrefix := rtrim(upper('&&1'));
lenExcludePrefix := length(strExcludePrefix);
strExcludePrefix2 := rtrim(upper('&&2'));
lenExcludePrefix2 := length(strExcludePrefix2);
strExcludePrefix3 := rtrim(upper('&&3'));
lenExcludePrefix3 := length(strExcludePrefix3);
strExcludePrefix4 := rtrim(upper('&&4'));
lenExcludePrefix4 := length(strExcludePrefix4);
strExcludePrefix5 := rtrim(upper('&&5'));
lenExcludePrefix5 := length(strExcludePrefix5);

for ex in curExclude
loop
--  dbms_output.put_line('processing object ' || ex.object_name);
  cntLength := Length(ex.object_name);
  cntPosition := 1;
  flgUnderScore := False;
  strCustId := '';
  if ex.object_name in ('WEBER_CASE_LABELS',
                        'WEBER_CASE_LABELS_TEMP',
                        'WEBER_ESO_ORDLBL_TABLE',
                        'WEBER_PALLET_LABELS',
                        'WEBER_PALLET_LABELS_TEMP',
                        'WEBER_PLATELBLS',
                        'WEBER_CASLBLS',
                        'WEBER_PLTLBLS',
                        'WEBER_PRPLBLS',
                        'WEBER_LABELS',
                        'BAR_BOLITMCMTVIEWA',
                        'BAR_BOLNMFC_PRELIM',
                        'BAR_BOLRPT',
                        'BAR_BOLRPT_PRELIM',
                        'BAR_PEACHTREE_VIEW',
                        'PACAM_BECO_LABEL_TABLE',
                        'PACAM_BECO_LABEL_TABLE_TEMP',
                        'WEBER_ESO_ORDLBL_VIEW') then
    delete from synapse_excluded_objects
          where object_name = ex.object_name;
    goto continue_exclude_loop;
  end if;
  if (strExcludePrefix <> 'NONE') and
     (substr(ex.object_name,1,lenExcludePrefix) = strExcludePrefix) then
    goto continue_exclude_loop;
  end if;
  if (strExcludePrefix2 <> 'NONE') and
     (substr(ex.object_name,1,lenExcludePrefix2) = strExcludePrefix2) then
    goto continue_exclude_loop;
  end if;
  if (strExcludePrefix3 <> 'NONE') and
     (substr(ex.object_name,1,lenExcludePrefix3) = strExcludePrefix3) then
    goto continue_exclude_loop;
  end if;
  if (strExcludePrefix4 <> 'NONE') and
     (substr(ex.object_name,1,lenExcludePrefix4) = strExcludePrefix4) then
    goto continue_exclude_loop;
  end if;
  if (strExcludePrefix5 <> 'NONE') and
     (substr(ex.object_name,1,lenExcludePrefix5) = strExcludePrefix5) then
    goto continue_exclude_loop;
  end if;
  while (1=1)
  loop
    if substr(ex.object_name,cntPosition,1) = '_' then
      if flgUnderScore = True then
        if check_for_valid_custid(ex.object_name, strCustid) = True then
--          dbms_output.put_line('object has cust ' || ex.object_name || ' ' || strCustId);
          exit;
        end if;
      end if;
      flgUnderScore := True;
      strCustId := '';
    elsif flgUnderScore = True then
      strCustId := strCustId || substr(ex.object_name,cntPosition,1);
    end if;
    cntPosition := cntPosition + 1;
    if cntPosition > cntLength then
--      dbms_output.put_line('end of object ' || ex.object_name || ' ' || strCustId);
      if flgUnderScore = True then
        if check_for_valid_custid(ex.object_name, strCustid) = False then
--          dbms_output.put_line('delete no customer');
          delete from synapse_excluded_objects
           where object_name = ex.object_name;
          commit;
--        else
--          dbms_output.put_line('object has cust ' || ex.object_name);
        end if;
      else
--        dbms_output.put_line('delete no underscore');
        delete from synapse_excluded_objects
         where object_name = ex.object_name;
        commit;
      end if;
      exit;
    end if;
  end loop;
<< continue_exclude_loop>>
  null;
end loop;

insert into synapse_excluded_objects
values ('PLAN_TABLE');
insert into synapse_excluded_objects
values ('SIPFILESEQ_ALL');
insert into synapse_excluded_objects
  select object_name
    from user_objects
   where object_name like 'TMP%';
insert into synapse_excluded_objects
  select object_name
    from recyclebin;
insert into synapse_excluded_objects
values ('usersession_mgmt;');
insert into synapse_excluded_objects
  select distinct object_name
    from user_objects
   where (object_name like 'AUTO_LOT_%' or
          object_name like 'AUTO_SER_%' or
          object_name like 'AUTO_US1_%' or
          object_name like 'AUTO_US2_%' or
          object_name like 'AUTO_US3_%' or
          object_name like 'CLASS_TO_COMPANY%' or
          object_name like 'CLASS_TO_WAREHOUSE%' or
          object_name like 'HITACHI_CARRIER%' or
          object_name like 'LASTCHEPFILE_%' or
          object_name like 'OHL_TOTAL_%' or
          object_name like 'SAP_PARAMETERS_FOR_%' or
          object_name like 'SAP_PARMS_FOR_%' or
          object_name like 'EDI_PARAMETERS_FOR_%' or
          object_name like 'EDI_PARMS_FOR_%' or
          object_name like 'OHL_PET_%' or
          object_name like 'OHL_INVLOTUSAGE_%' or
          object_name like 'OHL_ORDERLINE_%' or
          object_name like 'COMMENT_SEQ_MAP_%' or
          object_name like 'CONVASOFINVENTORY%' or
          object_name like 'CONVCUSTITEM%' or
          object_name like 'EMBARCADERO_%' or
          object_name like 'INVSTATUS_CATEGORY_%' or
          object_name like 'LASTIRIS%' or
          object_name like 'LASTRCPTNOTE%' or
          object_name like 'LASTSHORTNOTE%' or
          object_name like 'LASTRCPTONLY%' or
          object_name like 'LAST_INV_ADJ_%' or
          object_name like 'LASTRTRNDATE%' or
          object_name like 'LASTSHIPNOTE%' or
          object_name like 'LAST_RECEIPTS_%' or
          object_name like 'LAST_SHIPMENTS_%' or
          object_name like 'MEDEGEN%' or
          object_name like 'MED_INV_ADJ_%' or
          object_name like 'MICROSOFTDT%' or
          object_name like 'MURRAY%' or
          object_name like 'NOVARTIS%' or
          object_name like 'OHL_LBL_%' or
          object_name like 'OHL_MBOLRPT%' or
          object_name like 'OHL_MINOV%' or
          object_name like 'OHL_ORDER_NMFC%' or
          object_name like 'OHL_SMALLPACKAGE%' or
          object_name like 'OHL_STOCKSTATUS%' or
          object_name like 'OH_STATS%' or
          object_name like 'OL_STATS%' or
          object_name like 'PTL_ORDER_MAP_%' or
          object_name like 'RALEIGH_PI%' or
          object_name like 'TMS_TRANSORDER_DTL_ALL%' or
          object_name like 'TEMP_CHUNKS%' or
          object_name like 'TEMP_BILLFREIGHT_%' or
          object_name like 'FEDEX_GLOBAL_%' or
          object_name like 'QUEST_SL_TEMP_EXPLAIN%' or
          object_name like 'SNP_CDC_%' or
          object_name = 'ASOFINVACTLOT_COMBE' or
          object_name = 'ASOFINVREPORT' or
          object_name = 'ASOFINV_BACKUP' or
          object_name = 'ASOFINV_COMBE' or
          object_name = 'ASOFVENDORTEST' or
          object_name = 'ASOFINVDTL_BACKUP' or
          object_name = 'ASOFINVDTL_COMBE' or
          object_name = 'ASOFVENDORTESTDTL' or
          object_name = 'CABLEVISIONTEMP' or
          object_name = 'CASELABELS_BCKUP' or
          object_name = 'CASELABELS_0709' or
          object_name = 'CHKASOFRCPT' or
          object_name = 'CONVINVADJACTIVITY' or
          object_name = 'CUSTITEMIMPERIAL' or
          object_name = 'CUST_OH_STATS' or
          object_name = 'CUST_OL_STATS' or
          object_name = 'IRISSHIPEX_BK' or
          object_name = 'ISUGA945SELECT' or
          object_name = 'ISUGA944SELECT' or
          object_name = 'ORDTEMP' or
          object_name = 'PKCV' or
          object_name = 'RNV' or
          object_name = 'SBUXTRANS' or
          object_name = 'PLATE_TEMP' or
          object_name = 'PLATE_TEMP2' or
          object_name = 'TEMPUSERHEADER' or
          object_name = 'TEMP' or
          object_name = 'TEMP2' or
          object_name = 'TEMP_DATA' or
          object_name = 'TEMP_DELETE' or
          object_name = 'T1' or
          object_name = 'CONVPLATE' or
          object_name = 'CUSTITEMIMPSUG' or
          object_name = 'ORD_TEMP' or
          object_name = 'ORDERHDR_TMP' or
          object_name = 'J$ACCOUNTPERIOD' or
          object_name = 'LOWES211' or
          object_name = 'LOWESWATERPIK211' or
          object_name = 'MLOG$_TASKS' or
          object_name = 'NOVOTCADJ' or
          object_name = 'OHL_CUSTADDR_VIEW' or
          object_name = 'OHL_MULTISHIP_PACKAGE_VIEW' or
          object_name = 'OHL_NUTRI_PL_VIEW' or
          object_name = 'OHL_RACKANDFLOOR_VIEW' or
          object_name = 'OHL_PICKFRONTANDBIN_VIEW' or
          object_name = 'OHL_FEL_VIEW' or
          object_name = 'OHL_MASTERCARTON_PACKINGLIST' or
          object_name = 'OHL_INV_AGING_VIEW' or
          object_name = 'OHL_STARBUCKS_PL_VIEW' or
          object_name = 'OHL_INVOICEHDRRPT_VIEW' or
          object_name = 'OHL_SMALLPACKAGE_II' or
          object_name = 'OHL_SMALLPACKAGE_DETAIL_VIEW' or
          object_name = 'CARRIERPICKUPSCHEDULE' or
          object_name = 'MS_LOG' or
          object_name = 'PRINTSETSMALLPACKAGEVIEW' or
          object_name = 'LBL_HF_TASK_SSC14_CS_VIEW' or
          object_name = 'OHL_PRESHIP_BOLRPTVIEW' or
          object_name = 'PACAMBOLNMFC' or
          object_name = 'PACAM_BOLRPT' or
          object_name = 'PACAM_MBOLDTL_SYSCO' or
          object_name = 'PACAM_MBOLRPT_SYSCO' or
          object_name = 'PACAMBOLNMFC' or
          object_name = 'LOADFLAGLABELS' or
          object_name like 'SPE_%' or
          object_name like 'LASTGIL%' or
          object_name = 'LASTOPENBILL_ALL' or
          object_name = 'LASTAIPBILL_ALL' or
          object_name like 'CSLBL_%_SEQ' or
          object_name = 'HOR_GIL_ITEMVIEW_OLD' or
          object_name like 'CARRIERTABLEXREF%'  or-- from d2k
          object_name like 'D2_DEFAULT%' or -- from d2k
          object_name like 'D2_NMFC%' or -- from d2k
          object_name like 'D2_ZEBRA_%' or -- from d2k
          object_name = 'STL_COMMODITY' or -- from d2k
          object_name = 'SUPPLIERS' or -- from d2k
          object_name = 'CARRIERTERMSXREF' or -- from d2k
          object_name = 'D2_ALLOCABLEINV' or -- from d2k
          object_name = 'D2_ALLOCABLEINVORDERS' or -- from d2k
          object_name = 'D2_BB_CUSTITEMVIEW' or -- from d2k
          object_name like 'D2K_%' or -- from d2k
          object_name like 'D2_BB%' or -- from d2k
          object_name like 'STOCKSTAT_SUMM_RPT' or -- from d2k
          object_name like 'D2_ALLOCABLEINVPKG' or -- from d2k
          object_name = 'BILL_EXPORT_FOR_SAGE_VIEW' or -- from inlandstar
          object_name = 'LASTSAGEBILL_ALL' or -- from inlandstar
          object_name = 'QUEST_TEMP_EXPLAIN' or -- from dreisbach
          object_name like 'CHEPSEQ%' or -- from dreisbach
          object_name = 'TOAD_PLAN_TABLE' or -- from ohl
          object_name = 'XMLFORMAT' or -- from ohl
          object_name like 'MD~_%' escape '~' or -- from ohl
          object_name in ('ANV_ASOF','ANV_ASOFDTL','ANV_CUSTLIST',
                          'INVOICEDTLTST','INVOICE_ANV',
                          'INVOICE_ANV2','PLATEFIX',
                          'SAVE_INVDTL','SINGLEDIGITYEAR',
                          'LASTDREISBACHBILL_ALL') or -- from dreisbach
          object_name like 'DRE2~_%' escape '~' or -- from dreisbach
          object_name like 'DRE1~_%' escape '~' or -- from dreisbach
          object_name like 'DREV~_%' escape '~' or -- from dreisbach
          object_name like 'DRES~_%' escape '~' or -- from dreisbach
          object_name = 'GET_USERITEM' or -- from dreisbach
          object_name like 'SYS_EXPORT%' or -- from datapump export
          object_name like 'SYS_IMPORT%' or -- from datapump import
          object_name like '%~_ITL' escape '~' or -- from itl
          object_name = 'ALPS_CUSTRENEWAL' or -- from lineage
          object_name = 'LASTMASBILL_ALL' or -- from lineage
          object_name = 'EXPERATIONDAILYJOB' or -- from lineage
          object_name = 'BEMD_TEST' or -- from lineage
          object_name = 'LAST_BARBOURORVIS801_ALL' or -- from barrett
          object_name = 'LAST94716_TYSFO' or -- from dean
          object_name = 'LAST947_HUHPK' or -- from dean
          object_name = 'DW_CARTONPACKRPTVIEW' or -- from dean
          object_name = 'CG' or -- from dean
          object_name = 'ASAHI_EXP' or -- from barrett
          object_name = 'REVENUEREPORTGROUPSSORT' or -- from barrett
          object_name = 'TEST_CODE' or -- from barrett
          object_name like 'BGG~_%' escape '~' or -- from barrett
          object_name like 'ALES~_%' escape '~' or -- from barrett
          object_name = 'BOLDTLNOTNULL_V2' or -- from barrett
          object_name = 'BOL_BILLTOVIEW' or -- from barrett
          object_name = 'BOL_HAZMAT_CHEMCODES' or -- from barrett
          object_name = 'BOL_SHIPTOVIEW' or -- from barrett
          object_name like 'BBC~_%' escape '~' or -- from barrett
          object_name = 'CUSTITEMUPCVIEWV2' or -- from barrett
          object_name = 'CUSTITEMUPCVIEW_V2' or -- from barrett
          object_name like 'ORDDTLLINE~_%' escape '~' or -- from barrett
          object_name = 'PFSETUPVIEW' or -- from barrett
          object_name like 'RECEIVERDTLVIEW~_%' escape '~' or -- from barrett
          object_name like 'VIBRAM~_%' escape '~' or -- from barrett
          object_name = 'ORDERDTLLINE_SUM' or -- from barrett
          object_name = 'SHIP_NOTE_945_HDR_XENITH' or -- from barrett
          object_name = 'SHIP_NOTE_945_MAN_TRAVIS' or -- from barrett
          object_name = 'SHIP_NOTE_945_SSC' or -- from barrett
          object_name = 'SHIP_NOTE_945_TRV' or -- from barrett
          object_name = 'WEBORDERHDRVIEW_V2' or -- from barrett
          object_name = 'ZINVADJ_BAR' or -- from barrett
          object_name = 'ZCLONETOTEST' or -- from barrett
          object_name = 'CUSTITEM_NMFC_IDX' or -- from barrett
          object_name = 'ORDERHDR_BANYAN2_IDX' or -- from barrett
          object_name = 'HASPDFATTACHMENT' or -- from barrett
          object_name = 'WEBORDERATTACHMENT' or -- from barrett
          object_name like 'BILL_EXPORT_GP_HDR_ALL%' or -- from lt
          object_name = 'TEMP_OBJECTS_TEST' or -- from ohl
          object_name = 'INV_BUCKETS_TEST' or -- from ohl
          object_name = 'ASOFINVACT_TEST' or -- from ohl
          object_name = 'I59_SUM_QTYVDR_TEST' or -- from ohl
          object_name = 'CARGILL_MONTHS' or -- from aip
          object_name = 'INVOICEHDR_NEW' or -- from aip
          object_name = 'INVOICEHDR_OLD' or -- from aip
          object_name = 'INVOICEDTL_NEW' or -- from aip
          object_name = 'INVOICEDTL_OLD' or -- from aip
          object_name = 'POSTHDR_NEW' or -- from aip
          object_name = 'POSTHDR_OLD' or -- from aip
          object_name = 'POSTDTL_NEW' or -- from aip
          object_name = 'POSTDTL_OLD' or -- from aip
          object_name like 'VICSBOL~_TEST%' escape '~' or -- from logisticsteam
          object_name = 'DAY' or -- from port jersey
          object_name = 'MONTH' or -- from port jersey
          object_name = 'YEAR' or -- from port jersey
          object_name = 'SAMPLE_01' or -- from port jersey
          object_name = 'TEST_01' or -- from port jersey
          object_name = 'LBL_TRU_VIEW' or -- from d2k
          object_name = 'ACCOUNTING_CURRENT_MONTH' or -- from barrett
          object_name = 'AMAZON_CARTON_LBL' OR -- from barrett
          object_name = 'AMAZON_CARTON_LBL_CS' OR -- from barrett
          object_name = 'AVAILABLE_PLATE_TABLE_HGST' OR -- from barrett
          object_name = 'AVAILABLE_PLATE_TABLE_HGST_BCK' OR -- from barrett
          object_name = 'AVAILABLE_PLATE_TABLE_HGST_LOT' OR -- from barrett
          object_name = 'AVAILABLE_PLATE_TABLE_HGST_V2' OR -- from barrett
          object_name = 'BOL_SHIPTOVIEW_MASTERBOL' OR -- from barrett
          object_name = 'CSW_ALLPLATEVIEW' OR -- from barrett
          object_name = 'CUSTITEM_GTIN14_VIEW' OR -- from barrett
          object_name = 'HGST_OHAVOD_INVENTORY_V2' OR -- from barrett
          object_name = 'HGST_ONORDER_NOTINSTOCK' OR -- from barrett
          object_name = 'HYTEC_944_DTL' OR -- from barrett
          object_name = 'HYTEC_944_HDR' OR -- from barrett
          object_name = 'ITEM_ONHAND_AV_FACILITY' OR -- from barrett
          object_name = 'JSHOES_ITEM_LABEL_INFO' OR -- from barrett
          object_name = 'KELLOGS_ALL_PLATES' OR -- from barrett
          object_name = 'KELLOGS_OUTBOUND_PLATE_INFO' OR -- from barrett
          object_name = 'SHIP_NOTE_945_CNT_NAGE' OR -- from barrett
          object_name = 'SHIP_NOTE_945_CNT_NEWA' OR -- from barrett
          object_name = 'SHIP_NOTE_945_CNT_IBCC' OR -- from barrett
          object_name = 'SHIP_NOTE_945_DTL_NAGE' OR -- from barrett
          object_name = 'SHIP_NOTE_945_DTL_NEWA' OR -- from barrett
          object_name = 'SHIP_NOTE_945_DTL_IBCC' OR -- from barrett
          object_name = 'SHIP_NOTE_945_HDR_NAGE' OR -- from barrett
          object_name = 'SHIP_NOTE_945_HDR_NEWA' OR -- from barrett
          object_name = 'SHIP_NOTE_945_HDR_IBCC' OR -- from barrett
          object_name = 'SHIP_NOTE_945_LD' OR -- from barrett
          object_name = 'ASOFINVACTBYITEMPROC2' OR -- from barrett
          object_name = 'ASOFINVACTPROCFAC' OR -- from barrett
          object_name = 'CONFIRM_855_FID' or -- from bcf
          object_name like 'TEST_CHILD%' or -- from bcf
          object_name like 'TEST_PF%' or -- from bcf
          object_name like 'TEST_PICK%' or -- from bcf
          object_name like 'TEST_STAGE%' or -- from bcf
          object_name like 'TEST_STATUS%' or -- from bcf
          object_name = 'DATE_LASTDAY' or -- from port jersey
          object_name = 'ORDERPICKCOMPLETEDATE' or -- from taylored
          object_name = 'RECEIPTDETAILVIEW' or -- from taylored
          object_name = 'RECEIPTHEADERVIEW' or -- from taylored
          object_name = 'WAVERELEASEDATE' or -- from taylored
          object_name = 'LDARRIVALPLATEVIEW_JDG' or -- from lineage
          object_name = 'DRE_ASOFSUMMARY2_LASTUPDAT_IDX' or -- from dreisbach
          object_name = 'DRE_ASOFSUMMARY2_SESSIONID_IDX' or -- from dreisbach
          object_name = 'CUSTITEMUOM_EA_CS' or -- from taylored
          object_name = 'CUSTITEMUOM_EA_IN' or -- from taylored
          object_name = 'CUSTITEMUOM_IN_CS' or -- from taylored
          object_name = 'PACKLISTDTL' or -- from spx
          object_name = 'PACKLISTHDRSHIPTO' or -- from spx
          object_name = 'SP_SHIPPINGREPORT' or -- from spx
          object_name = 'HGSF' or -- from spx
          object_name = 'ORDER_COUNT' or -- from taylored
          object_name = 'DYNAMIC_PIVOT' or -- from taylored
          object_name = 'LAMEX' or -- from portjersey
          object_name = 'KAN_MONTH' or -- from unitedwarehouse
          object_name = 'PACAM_XANT945' or -- from matson
          object_name like 'DEMO_%' or -- from matson
          object_name = 'DEPT' or -- from matson
          object_name = 'PACAM_MULTISHIP' or -- from matson
          object_name = 'PACAM_NESTLERCPT' or -- from matson
          object_name = 'PACAM_GETITEM' or -- from matson
          object_name = 'ASOFCUSTFAC' or -- from weber
          object_name = 'BEF_DAY' or -- from weber
          object_name = 'BEF_MONTH2' or -- from weber
          object_name = 'BEF_YEAR10' or -- from weber
          object_name = 'BEF_YEAR20' or -- from weber
          object_name = 'CASELABELS_ARCHIVE' or -- from weber
          object_name = 'CASELABELS_HISTORY' or -- from weber
          object_name = 'CONSIGNEE_TEMP' or -- from weber
          object_name = 'DBD_TEST__LIST_TABLE' or -- from weber
          object_name = 'DBD_TEST__NEST_TABLE' or -- from weber
          object_name = 'DBD_TEST__OBJ_TABLE' or -- from weber
          object_name = 'DIAGEO_MON' or -- from weber
          object_name = 'GLAC_Y' or -- from weber
          object_name = 'INDEX_USAGE' or -- from weber
          object_name = 'LAWSONCMTEX_OLD' or -- from weber
          object_name = 'LAWSONHDREX_OLD' or -- from weber
          object_name = 'LOADING_MSG' or -- from weber
          object_name = 'OHL_ASOFINVACTLOT' or -- from weber
          object_name = 'ORDERDTLRCPT_TEMP' or -- from weber
          object_name = 'POU2_GFOODS' or -- from weber
          object_name = 'POU2_KIKKOM' or -- from weber
          object_name = 'POU2_KIKKOM2' or -- from weber
          object_name = 'POU2_MONTH' or -- from weber
          object_name = 'TOAD_PLAN_SQL' or -- from weber
          object_name = 'USERHISTORY_VIT1' or -- from weber
          object_name = 'WEB_MONTH' or -- from weber
          object_name = 'WELCHMO' or -- from weber
          object_name = 'WELCHMONTH' or -- from weber
          object_name = 'WELCH_YR' or -- from weber
          object_name = 'WORLD_Y' or -- from weber
          object_name = 'YOKUM' or -- from weber
          object_name = 'ZWEBER_ITEMTEMP' or -- from weber
          object_name in ('BEF_ALESDATE') or --from barrett
          object_name in ('BEF_ALESDATE10') or --from barrett
          object_name in ('BEF_ALESDATE4') or --from barrett
          object_name in ('BEF_ALESDATE6') or --from barrett
          object_name in ('BEF_ALESDATE7') or --from barrett
          object_name in ('BEF_ALESDATE8') or --from barrett
          object_name in ('BEF_ALESDATE9') or --from barrett
          object_name in ('BEF_ALESDATENONW') or --from barrett
          object_name in ('BEF_PCPG') or --from barrett
          object_name in ('LASTBAR945ALL') or --from barrett
          object_name in ('LASTFL') or --from barrett
          object_name in ('LASTLEKKERSC') or --from barrett
          object_name in ('AVALLON_LTL_ORDER') or --from barrett
          object_name in ('BARRETT_ALLOCQTYLOTS') or --from barrett
          object_name in ('BARRETT_GETSHIPCOST') or --from barrett
          object_name in ('COMMENTS_ORDERHDR') or --from barrett
          object_name in ('LPID_NEXTVAL') or --from barrett
          object_name in ('GET_TOKEN') or --from barrett
          object_name in ('HOLD_QTY') or --from barrett
          object_name in ('TEST_BAR_ACADEMY_BUFFTOTALCART') or --from barrett
          object_name in ('SHIPPINGPLATE_BANYAN3_IDX') or --from barrett
          object_name in ('SHIPPINGPLATE_BANYAN_IDX') or --from barrett
          object_name in ('SHIPPINGPLATE_BAR1_IDX') or --from barrett
          object_name in ('BARRETT_GETSHIPCOST_V2') or --from barrett
          object_name in ('BARRETT_GETSHIPCOST_V3') or --from barrett
          object_name in ('SHIPPINGPLATE_BANYAN3_IDX') or --from barrett
          object_name in ('SHIPPINGPLATE_BANYAN_IDX') or --from barrett
          object_name in ('SHIPPINGPLATE_BAR1_IDX') or --from barrett
          object_name in ('AATESTDENTPACK') or --from barrett
          object_name in ('AMAZON_CARTON_LBL_GOETZE') or --from barrett
          object_name in ('BAGSTER_INVTOTALVIEW') or --from barrett
          object_name in ('BILL_EXPORT_FOR_PEACHTREEVIEW2') or --from barrett
          object_name in ('BOLDTL_SN_V2') or --from barrett
          object_name in ('BOLNMFC_V2') or --from barrett
          object_name in ('BOL_HAZMAT_CHEMCODES_EMD') or --from barrett
          object_name in ('BOL_HAZMAT_ITEMTEXT_EMD') or --from barrett
          object_name in ('BOL_HAZMAT_ITEMTEXT_EMD') or --from barrett
          object_name in ('CUSTITEMCASEUPCVIEW') or --from barrett
          object_name in ('CUSTITEM_CASEUPCVIEW') or --from barrett
          object_name in ('FACILITY_LOT_LOCATION_AUDIT') or --from barrett
          object_name in ('FREIGHTLINK_DATA') or --from barrett
          object_name in ('IBCC_PALLET_COUNT') or --from barrett
          object_name in ('INVENTORY_STATUS_DETAIL_LOT') or --from barrett
          object_name in ('INVENTORY_STATUS_DETAIL_LOT_A') or --from barrett
          object_name in ('INVENTORY_STATUS_DETAIL_LOT_G') or --from barrett
          object_name in ('INVENTORY_STATUS_DETAIL_LOT_W') or --from barrett
          object_name in ('INVENTORY_STATUS_DETAIL_LOT_WQ') or --from barrett
          object_name in ('INVENTORY_STATUS_ITEM_MASTER') or --from barrett
          object_name in ('INVENTORY_STATUS_ITEM_MASTER_A') or --from barrett
          object_name in ('INVENTORY_STATUS_ITEM_MASTER_W') or --from barrett
          object_name in ('INVENTORY_STATUS_ITM_MASTER_WQ') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT_A') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT_B') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT_G') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT_T') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LOT_W') or --from barrett
          object_name in ('INVENTORY_STATUS_SUMMARY_LT_WQ') or --from barrett
          object_name in ('INVITEMRPT_BAR') or --from barrett
          object_name in ('INV_DTL_LOADID') or --from barrett
          object_name in ('LBL_IBCC_PACCAR_CONTR') or --from barrett
          object_name in ('LBL_IBCC_PACCAR_PARTS') or --from barrett
          object_name in ('LBL_LINDT_PROJECT') or --from barrett
          object_name in ('LBL_SHIPADDR') or --from barrett
          object_name in ('LBL_VALSPAR') or --from barrett
          object_name in ('LIST_EDI_ORDERS') or --from barrett
          object_name in ('LOADPALLETCOUNT') or --from barrett
          object_name in ('LOT_LOCATION_AUDIT') or --from barrett
          object_name in ('MASTER_LOAD_PALLET_CNT') or --from barrett
          object_name in ('ORDERHDRDTLNTFYVIEW') or --from barrett
          object_name in ('PALLET_COUNT_ABSOLUTE') or --from barrett
          object_name in ('PEACHTREE_VIEW') or --from barrett
          object_name in ('PRINT_LP_VIEW') or --from barrett
          object_name in ('RCPT_NOTE_944_IDE2') or --from barrett
          object_name in ('SHOW_HEADER_PASSTHRU') or --from barrett
          object_name in ('TEMP_WASTEQUIP_TABLE') or --from barrett
          object_name in ('TESTDENTPACK') or --from barrett
          object_name in ('RETURNSRPTPROC_TEST') or --from barrett
          object_name in ('ZIMPORTPROCFREIGHTLINK') or --from barrett
          object_name in ('WEBERTMSCUSTCONSNVIEW') or --from weber
          object_name like '#Tsid:%' or -- from barrett
          object_name like 'LAWSONHDREX_DBARAIT_ALL%' or -- from weber
          object_name like 'WEBERTMS_DETAIL%' or -- from weber
          object_name = 'CUSTITEM_GTIN14_1608' or -- from barrett
          object_name = 'ZIMPORTPROCBAR' or --from barrett
          object_name = 'CONSIGNEE_STORECODE' or -- from barrett
          object_name = 'RCPT_NOTE_944_HDR_ED' or -- from weber
          object_name like 'EXPORT_TMP_%' or -- from selected_import_export
          object_name = 'MAKE_ORDER_UTIL' or -- from barrett
          object_name like 'MRCSEC%' or -- from barrett
          object_name = 'BEF_ENDMONTHDAY' or -- from barrett
          object_name = 'BAR_BOLITMCMTVIEWA' or -- from barrett
          object_name = 'COMMENTSVIEW_ORDERHDR_BOL' or -- from barrett
          object_name = 'LOADPALLETCOUNT_TEMP' or -- from barrett
          object_name = 'PALLET_COUNT_BY_TYPE' or -- from barrett
          object_name = 'PLATE_LOCATION_COUNT' or -- from barrett
          object_name = 'MONTHXYZ' or -- from weber
          object_name = 'LAWSONDTLEX_DBARAIT' or -- from weber
          object_name = 'LAWSONHDREX_DBARAIT' or -- from weber
          object_name = 'BEF_MONTH_AL' or -- from weber
          object_name = 'BEF_MONTHS81_92' or -- from weber
          object_name = 'BEF_MONTH81_92' or -- from weber
          object_name = 'BEF_MONTHXYZ' or -- from weber
          object_name = 'BEF_WEEK' or -- from weber
          object_name = 'PACKLIST_TRACKINGPICKSHIP' or -- from weber
          object_name = 'VWITLMULTICOUNTER' or -- from itl
          object_name = 'MULTIITL' or -- from itl
          object_name = 'GETLPSRATINGNEEDCOMMENTS' or -- from itl
          object_name = 'GETLPSRATINGNEEDCOMMENTSV2' or -- from itl
          object_name = 'VICSBOLPROCRP' or -- from itl
          object_name = 'CUSTITEM_DIAGEO' or -- from matson
          object_name = 'MWL_SEQ_DATE' or -- from matson
          object_name like 'XXTEMP%' or -- from matson
          object_name = 'BEF_DGMON' or -- from matson
          object_name = 'CUSTOMERDEFHANDLING' or -- from matson
          object_name = 'INVITEMRPT_UOMS' or -- from matson
          object_name = 'LBL_MULTIUOM_SUBTASKS_VIEW' or -- from matson
          object_name = 'VICS_BOL_CARRIER_INFO_ALT' or -- from matson
          object_name like 'TEMP_WHOLE_DIST%' or -- from taylored
          object_name like 'TEMP_RETAIL_DIST%' or -- from taylored
          object_name = 'AATESTAFIXCUBE' or -- from matson
          object_name = 'CHAINED_ROWS' or -- from matson
          object_name = 'EMP' or -- from matson
          object_name = 'EXEC_LOG' or -- from matson
          object_name = 'UCC_STANDARD_LABELS_HISTORY' or -- from matson
          object_name = 'BOLRPT_ALL_STATUSES' or -- from matson
          object_name = 'BOLRPT_NW' or -- from matson
          object_name = 'GET_210_INVOICEDTL_VIEW' or -- from matson
          object_name = 'AFIXCUBE' or -- from matson
          object_name = 'CUSTOM_IMAGE_DISPLAY' or -- from matson
          object_name = 'EXEC_LOGGER' or -- from matson
          object_name = 'HOST' or -- from matson
          object_name = 'PACAMASOFINVACTLOTPKGN' or -- from matson
          object_name = 'ZIMPORTPROCMLW' or -- from matson
          object_name = 'BOLRPT_NWW' or -- from matson
          object_name = 'INVITEMRPT_XX' or -- from matson
          object_name = 'ITEMSUMMARY' or -- from matson
          object_name = 'MATSON_STOKKE_KITTING_BILLING' or -- from matson
          object_name = 'SHIP_NOTE_945_CRT' or -- from matson
          object_name = 'SMALLPACKAGE_DC' or -- from matson
          object_name = 'SMALLPACKAGE_TEST' or -- from matson
          object_name = 'PCAM_RICKCOMM' or -- from matson
          object_name = 'INVACCRPT' or -- from united
          object_name = 'OLE DB Destination' or -- from united
          object_name = 'UNITEDWHS_TRANSMITTEDINV' or -- from united
          object_name = 'LOT_MONTH' or -- from united
          object_name = 'LOT_YEAR' or -- from united
          object_name = 'MOR_CLOSE_MONTH' or -- from united
          object_name = 'MOR_CLOSE_YEAR' or -- from united
          object_name = 'AVAILCHILDBASEVIEWNOASN' or -- from united
          object_name = 'AVAILCHILDBASEVIEWNOLOTASN' or -- from united
          object_name = 'AVAILCHILDVIEWNOASN' or -- from united
          object_name = 'AVAILCHILDVIEWNOLOTASN' or -- from united
          object_name = 'AVAILSTATUSCLASSBASEVIEWNOASN' or -- from united
          object_name = 'AVAILSTATUSCLASSBASEVIEWNOLOTA' or -- from united
          object_name = 'AVAILSTATUSCLASSVIEWNOASN' or -- from united
          object_name = 'AVAILSTATUSCLASSVIEWNOLOTASN' or -- from united
          object_name = 'STOCK_STATUS_846_QTY_LOT' or -- from united
          object_name = 'INVACCRPTPKG' or -- from united
		  object_name like 'RCPT_NOTE_944_HDR_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_LIP_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_TRL_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_PAL_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_NTE_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_MBR_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_LU1_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_LTRL_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_IHR_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_IDE2_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_FAC_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_DTL_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_BDN_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_ADDLN_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_ADD_%' or -- from terminal
		  object_name like 'RCPT_NOTE_944_IDE_%' or -- from terminal
          object_name like 'BILL_EXPORT_PT%' -- from aip
          );

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('exiting exclude table update others...');
  return;
end;
/

set linesize 4000
set heading off
set verify off
set echo off
set term off
set long 2000000000
set pagesize 0
set trimspool on
set null ?

spool cons.txt
select substr(upper(replace(decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name),'"','')),1,30) constraint_name,
       constraint_type,table_name,
       status, deferrable,
       nvl(deferred,'d'),
       nvl(validated,'v'),
       nvl(bad,'b'),
       nvl(rely,'r'),index_owner,
--     generated,
       decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       nvl(invalid,'i'),
       nvl(view_related,'v'),
       search_condition_varchar2(constraint_name,constraint_type,table_name) search_condition
  from user_constraints
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not like 'AQ$%'
   and table_name not like 'BIN$%'
   and search_condition is not null
   and table_name not in (select queue_table from user_queues)
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
union all
select substr(decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name),1,32) constraint_name,
       constraint_type,table_name,
       status, deferrable,
       nvl(deferred,'d'),
       nvl(validated,'v'),
       nvl(bad,'b'),
       nvl(rely,'r'),index_owner,
--     generated,
       decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       nvl(invalid,'i'),
       nvl(view_related,'v'),
       'nullsearch' search_condition
  from user_constraints
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not like 'AQ$%'
   and table_name not like 'BIN$%'
   and search_condition is null
   and table_name not in (select queue_table from user_queues)
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
 order by constraint_name,constraint_type,table_name,search_condition;
spool off;

spool conscols.txt
select decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name) constraint_name,
       table_name,column_name,position
  from user_cons_columns
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and table_name not like 'BIN$%'
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
 order by constraint_name,table_name,column_name,position;
spool off;

spool valcons.txt
select substr(upper(replace(decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name),'"','')),1,30) constraint_name,
       constraint_type,table_name,
       status, deferrable,
       nvl(deferred,'d'),
       nvl(validated,'v'),
       nvl(bad,'b'),
       nvl(rely,'r'),index_owner,
--     generated,
       decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       nvl(invalid,'i'),
       nvl(view_related,'v'),
       search_condition_varchar2(constraint_name,constraint_type,table_name) search_condition
  from user_constraints
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not like 'AQ$%'
   and table_name not like 'BIN$%'
   and search_condition is not null
   and table_name not in (select queue_table from user_queues)
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
union all
select substr(decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name),1,32) constraint_name,
       constraint_type,table_name,
       status, deferrable,
       nvl(deferred,'d'),
       nvl(validated,'v'),
       nvl(bad,'b'),
       nvl(rely,'r'),index_owner,
--     generated,
       decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       nvl(invalid,'i'),
       nvl(view_related,'v'),
       'nullsearch' search_condition
  from user_constraints
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not like 'AQ$%'
   and table_name not like 'BIN$%'
   and search_condition is null
   and table_name not in (select queue_table from user_queues)
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
 order by constraint_name,constraint_type,table_name,search_condition;
spool off;

spool valconscols.txt
select decode(substr(constraint_name,1,4),'SYS_',substr(constraint_name,1,4),constraint_name) constraint_name,
       table_name,column_name,position
  from user_cons_columns
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
 order by constraint_name,table_name,column_name,position;
spool off;

spool funcsrc.txt;
select upper(name), upper(type), line, upper(replace(text,'"',''))
  from user_source
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and type = 'FUNCTION'
   and text not like '%$Id%'
   and name not in ('DATA_DEFAULT_VARCHAR2',
                    'SEARCH_CONDITION_VARCHAR2',
                    'DATA_PRECISION_VALUE',
                    'DATA_NULLABLE_VALUE',
                    'COMMENTS_ORDERHDR_BOL')  -- from barrett
   and name not like 'ITEM_COMMENT_DEFAULT%' -- from matson
   and name not like 'BARRETT_%' -- from barrett
   and name not in ('AS_OF_INVENTORY',
                    'AS_OF_INVENTORY_BASE_OUM',
                    'CUSTOM_AUTH',
                    'CUSTOM_HASH',
                    'CUST_COMMENT_DEFAULT',
                    'FORMATTED_TIMEDIFF',
                    'GET_COUNTRY_OF_ORIGINE',
                    'INV_STATUS',
                    'IS_NUMBER',
                    'ITEM_ALLOCATED_QTY',
                    'STRAGG',
                    'UOM_CONVERSSION'
                   ) -- from matson
   and name not like 'BALSAM%' -- from matson
   and trim(text) != chr(10)
 order by name, type, line;
spool off;

spool idx.txt;
select decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       table_name, uniqueness, index_type, tablespace_name
  from user_indexes
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and table_name not in (select name from user_queues where name like 'AQ$%')
   and index_name != 'IDX$$_2BD40001' -- from dreisbach
   and index_name != 'IDX$$_2BD40002' -- from dreisbach
   and index_name != 'SPE_ORDERHDR_PASSTHRUCHAR06' -- from spx
   and index_name != 'SHIPPINGPLATE_BANYAN3_IDX' -- from barrett
   and index_name != 'SHIPPINGPLATE_BANYAN_IDX' -- from barrett
   and index_name != 'SHIPPINGPLATE_BAR1_IDX' -- from barrett
   and index_name != 'CUSTITEM_NMFC_IDX' -- from barrett
   and index_name != 'CONSIGNEE_STORECODE' -- from barrett
   and index_Name != 'INVOICEHDR_INVDATE_IDX' -- from matson
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
 order by index_name, table_name, uniqueness, index_type;
spool off;

spool validx.txt;
select decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       table_name, uniqueness
  from user_indexes
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
 order by index_name, table_name, uniqueness;
spool off;

spool idxcol.txt;
select decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       table_name, column_position,
       decode(substr(column_name,1,4),'SYS_','SYS_',column_name) column_name
  from user_ind_columns
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and index_name != 'IDX$$_2BD40001' -- from dreisbach
   and index_name != 'IDX$$_2BD40002' -- from dreisbach
   and index_name != 'SPE_ORDERHDR_PASSTHRUCHAR06' -- from spx
   and index_name != 'SHIPPINGPLATE_BANYAN3_IDX' -- from barrett
   and index_name != 'SHIPPINGPLATE_BANYAN_IDX' -- from barrett
   and index_name != 'SHIPPINGPLATE_BAR1_IDX' -- from barrett
   and index_name != 'CUSTITEM_NMFC_IDX' -- from barrett
   and index_name != 'CONSIGNEE_STORECODE' -- from barrett
   and index_Name != 'INVOICEHDR_INVDATE_IDX' -- from matson
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
 order by index_name, table_name, column_position, column_name;
spool off;

spool validxcol.txt;
select decode(substr(index_name,1,4),'SYS_',substr(index_name,1,4),index_name) index_name,
       table_name, column_position, column_name
  from user_ind_columns
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
 order by index_name, table_name, column_position, column_name;
spool off;

spool lob.txt;
select table_name, column_name
  from user_lobs
 where table_name not in
   (select object_name
      from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
 order by table_name, column_name;
spool off;

spool pkgsrc.txt;
select upper(name), upper(type), line, upper(replace(text,'"',''))
  from user_source
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and type = 'PACKAGE'
   and text not like '%$Id%'
   and trim(text) != chr(10)
 order by name, type, line;
spool off;

spool pkgbodysrc.txt;
select upper(name), upper(type), line, upper(replace(text,'"',''))
  from user_source
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and type = 'PACKAGE BODY'
   and text not like '%$Id%'
   and trim(text) != chr(10)
 order by name, type, line;
spool off;

spool procsrc.txt;
select upper(name), upper(type), line, upper(replace(text,'"',''))
  from user_source
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and type = 'PROCEDURE'
   and text not like '%$Id%'
   and trim(text) != chr(10)
 order by name, type, line;
spool off;

spool que.txt;
select name, queue_table, enqueue_enabled, dequeue_enabled
  from user_queues
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and name != 'AQ$_QT_RP_Q6206_E' -- from barrett
   and name != 'AQ$_QT_RP_Q8000_E' -- from barrett
   and name != 'AQ$_QT_RP_Q8049_E' -- from barrett
   and name != 'AQ$_QT_RP_Q92452_E' -- from barrett
   and name != 'AQ$_QT_RP_Q9245_E' -- from barrett
   and name != 'Q6206' -- from barrett
   and name != 'Q8000' -- from barrett
   and name != 'Q8049' -- from barrett
   and name != 'Q9245' -- from barrett
   and name != 'Q92452' -- from barrett
 order by name;
spool off;

spool jobs.txt;
select what,broken
  from user_jobs
 where what not in
   (select object_name
      from synapse_excluded_objects)
   and what not like ('ZCC.EXECUTE_JOB%')
 order by what;
spool off;

spool seq.txt;
select sequence_name, min_value, max_value, increment_by,
       cycle_flag, order_flag, cache_size
  from user_sequences
 where sequence_name not in
   (select object_name
      from synapse_excluded_objects)
   and sequence_name not like 'SSCC14~_%' escape '~'
   and sequence_name not like 'SSCC18~_%' escape '~'
   and sequence_name != 'MICROSOFTSEQDTPROPERTIES' -- from weber
   and sequence_name not like 'RRCSEQ%' -- from weber
   and sequence_name != 'SANITYREPORTS' -- from weber
   and sequence_name not in ('LICENSE_PLATE_PAPER_PRINT','SEQ_BBB810','SEQ_BBB850') -- from barrett
 order by sequence_name;
spool off;

spool syn.txt;
select owner, synonym_name, table_owner, table_name
  from all_synonyms
 where table_owner in ('ALPS','SDI')
   and synonym_name not in
   (select object_name
     from synapse_excluded_objects)
   and synonym_name != 'ZIMFL' -- from barrett
 order by owner, synonym_name, table_owner, table_name;
spool off;

spool tbl.txt;
--select table_name, decode(last_analyzed,null,'not analyzed','analyzed')
select table_name, temporary
  from user_tables
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and not exists (select 1
                     from user_queues
                    where queue_table = table_name)
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
  order by table_name;
spool off;

spool valtbl.txt;
--select table_name, decode(last_analyzed,null,'not analyzed','analyzed')
select table_name
  from user_tables
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
  order by table_name;
spool off;

spool tblcol.txt;
select table_name, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       upper(data_default_varchar2(table_name, column_name)) data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and data_default is not null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and not exists (select 1
                     from user_queues
                    where queue_table = table_name)
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
union all
select table_name, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       null data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and data_default is null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and not exists (select 1
                     from user_queues
                    where queue_table = table_name)
   and not exists (select 1
                     from tabledefs
                    where upper(tableid) = table_name)
  order by table_name, column_name;
spool off;

spool valtblcol.txt;
select table_name, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       data_default_varchar2(table_name, column_name) data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and data_default is not null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
union all
select table_name, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       null data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and data_default is null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and exists (select 1
                 from tabledefs
                where upper(tableid) = table_name)
  order by table_name, column_name;
spool off;

spool tblcolid.txt;
select table_name, column_id, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       data_default_varchar2(table_name, column_name) data_default
  from user_tab_columns utc1
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and table_name != 'INVADJ947DTLEX'
   and table_name != 'PRODACTIVITY852DTLEX'
   and data_default is not null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and exists (select 1
                 from user_tab_columns utc2
                where utc1.table_name = utc2.table_name
                  and utc2.column_name like '%SESSIONID%')
union all
select table_name, column_id, column_name, data_type, data_length,
       nullable,
       data_precision_value(table_name, column_name, data_precision), data_scale,
       null data_default
  from user_tab_columns utc1
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and table_name not in (select queue_table from user_queues)
   and table_name != 'INVADJ947DTLEX'
   and table_name != 'PRODACTIVITY852DTLEX'
   and data_default is null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'TABLE')
   and exists (select 1
                 from user_tab_columns utc2
                where utc1.table_name = utc2.table_name
                  and utc2.column_name like '%SESSIONID%')
  order by table_name, column_id;
spool off;

spool trig.txt;
select trigger_name, trigger_body
  from user_triggers
 where trigger_name not like 'BIN$%'
   and trigger_name != 'CUSTITEM_WEBER_INSERT' -- from weber
   and trigger_name not like 'INVOICEHDR_BUC%' -- from matson (had to use the like clause for some unknown reason)
   and trigger_name != 'BI_DEMO_USERS' -- from matson
   and trigger_name != 'CUSTOMER_BU' -- from matson
   and trigger_name not like 'INSERT_DEMO%' -- from matson 
   and trigger_name != 'ORDERHDR_AU_FDEX' -- from matson
   and trigger_name != 'ORDERHDR_AU_FDEX2' -- from matson
   and trigger_name != 'UCC_LABEL_AD' -- from matson
   and trigger_name != 'UPDATE_ORDER_TOTAL' -- from matson
   and trigger_name not in
   (select object_name
     from synapse_excluded_objects)
 order by trigger_name;
spool off;

spool typ.txt;
select type_name,attr_name,attr_type_name,
       length,precision,scale,attr_no
  from user_type_attrs
 where type_name not in
   (select object_name
      from synapse_excluded_objects)
   and type_name not in ('USER_DATA_TYPE',
                         'VARCHAR2_TT',
                         'NUMBER_TAB',
                         'STRING_AGG_TYPE') -- from matson
 order by type_name,attr_no;
spool off;

spool typesrc.txt;
select name, type, line, upper(replace(text,'"',null)) text
  from user_source
 where name not in
   (select object_name
      from synapse_excluded_objects)
   and type = 'TYPE'
   and text not like '%$Id%'
   and name != 'USER_DATA_TYPE' -- from matson
   and name != 'VARCHAR2_TT' -- from matson
   and name != 'NUMBER_TAB' -- from matson
   and name != 'STRING_AGG_TYPE' -- from matson
   and trim(text) != chr(10)
 order by name, type, line;
spool off;

spool view.txt;
select view_name, text
  from user_views
 where view_name not in
   (select object_name
      from synapse_excluded_objects)
   and instr(view_name,'$') = 0
 order by view_name;
spool off;

spool viewcol.txt;
select table_name, column_name, data_type, data_length,
       data_nullable_value(table_name, column_name, nullable),
       data_precision_value(table_name, column_name, data_precision), data_scale,
       data_default_varchar2(table_name, column_name) data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and data_default is not null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'VIEW')
   and instr(table_name,'$') = 0
union all
select table_name, column_name, data_type, data_length,
       data_nullable_value(table_name, column_name, nullable),
       data_precision_value(table_name, column_name, data_precision), data_scale,
       null data_default
  from user_tab_columns
 where table_name not in
   (select object_name
     from synapse_excluded_objects)
   and data_default is null
   and exists (select 1
                 from user_objects
                where object_name = table_name
                  and object_type = 'VIEW')
   and instr(table_name,'$') = 0
  order by table_name, column_name;
spool off;

spool dblinks.txt;
select db_link, username, host
  from user_db_links
 order by db_link, username, host;
spool off;

spool excluded.txt;
select object_name
  from synapse_excluded_objects;
spool off;

spool systemdefaults_defaultid.txt;
select defaultid
  from systemdefaults
 where defaultid != 'LABELCLIENTINIPATH' -- from matson
 order by defaultid;
spool off;

spool systemdefaults.txt;
select defaultid, defaultvalue
  from systemdefaults
 where defaultid != 'LABELCLIENTINIPATH' -- from matson
 order by defaultid;
spool off;

spool applicationobjects.txt;
select objectname,objecttype,
       decode(objectdescr,
              'LABOR',null,
              objectdescr)
  from applicationobjects
 order by objectname;
spool off;

spool businessevents_code.txt;
select code
  from businessevents
 where code not in ('ORDR','PRLP','PROD','PRSP','RPLP') -- from matson
 order by code;
spool off;

spool businessevents.txt;
select code,billing_yn,labels_yn
  from businessevents
 where code not in ('ORDR','PRLP','PROD','PRSP','RPLP') -- from matson
 order by code;
spool off;

spool billingmethod.txt;
select code
  from billingmethod
 where code not in ('CUFT','CUIN') -- from matson
 order by code;
spool off;

spool dba_users.txt;
select username,account_status
  from dba_users
 where account_status = 'OPEN'
 order by username;
spool off;

set verify on;
set echo on;
set term on;
drop table synapse_excluded_objects;
drop function search_condition_varchar2;
drop function data_default_varchar2;
drop function data_precision_value;
drop function data_nullable_value;
exit;
