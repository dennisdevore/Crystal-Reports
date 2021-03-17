CREATE OR REPLACE PACKAGE BODY ALPS.zimportproctrans as
--
-- $Id$
--

strMsg varchar2(255);


procedure import_planship_hdr
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_transactioncount in number
,in_senderhostname in varchar2
,in_username in varchar2
,in_password in varchar2
,in_sendertransmissionno in number
,in_referencetransno in number
,in_status in number
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is


begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_hdr
  (
    transmissioncreatedatetime,
    transactioncount,
    senderhostname,
    username,
    password,
    sendertransmissionno,
    referencetransmissionno,
    status
  )
  values
  (
    in_transcreatedatetime,
    in_transactioncount,
    in_senderhostname,
    in_username,
    in_password,
    in_sendertransmissionno,
    in_referencetransno,
    in_status
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmshdr ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_hdr;

procedure import_planship_rel
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_releasedomainname in varchar2
,in_release in varchar2
,in_transorderheaderdomain in varchar2
,in_transorderheader in varchar2
,in_transordertranscode in varchar2
,in_paymentmethodcddomain in varchar2
,in_paymentmethodcode in varchar2
,in_planninggroupdomain in varchar2
,in_planninggroup in varchar2
,in_ordertypedomainname in varchar2
,in_ordertype in varchar2
,in_timewindowemphasis in varchar2
,in_shipfromlocrefdomain in varchar2
,in_shipfromlocationref in varchar2
,in_shiptolocrefdomain in varchar2
,in_shiptolocationref in varchar2
,in_earlydeliverydate in date
,in_latedeliverydate in date
,in_declaredvaluecurrcode in varchar2
,in_declaredvalmonetaryamt in varchar2
,in_mustshipalone in varchar2
,in_bulkplandomainname in varchar2
,in_bulkplan in varchar2
,in_bestdirbuycurrcode in varchar2
,in_bestdirbuymonetaryamt in varchar2
,in_bestdirbuyratedomain in varchar2
,in_bestdirectbuyrate in varchar2
,in_bestdirsellcurrcode in varchar2
,in_bestdirsellmonetaryamt in varchar2
,in_bestdirsellratedomain in varchar2
,in_bestdirectsellrate in varchar2
,in_totalweightvalue in varchar2
,in_totalweightuom in varchar2
,in_totalvolumevalue in varchar2
,in_totalvolumeuom in varchar2
,in_totalnetweightvalue in varchar2
,in_totalnetweightuom in varchar2
,in_totalnetvolumevalue in varchar2
,in_totalnetvolumeuom in varchar2
,in_totpackageditemspeccnt in number
,in_totalpackageditemcount in number
,in_shiptype in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_rel
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    releasedomainname,
    release,
    transorderheaderdomainname,
    transorderheader,
    transordertransactioncode,
    paymentmethodcodedomainname,
    paymentmethodcode,
    planninggroupdomainname,
    planninggroup,
    ordertypedomainname,
    ordertype,
    timewindowemphasis,
    shipfromlocationrefdomainname,
    shipfromlocationref,
    shiptolocationrefdomainname,
    shiptolocationref,
    earlydeliverydate,
    latedeliverydate,
    declaredvaluecurrencycode,
    declaredvaluemonetaryamount,
    mustshipalone,
    bulkplandomainname,
    bulkplan,
    bestdirectbuycurrencycode,
    bestdirectbuymonetaryamount,
    bestdirectbuyratedomainname ,
    bestdirectbuyrate,
    bestdirectsellcurrencycode,
    bestdirectsellmonetaryamount,
    bestdirectsellratedomainname,
    bestdirectsellrate,
    totalweightvalue,
    totalweightuom,
    totalvolumevalue,
    totalvolumeuom,
    totalnetweightvalue,
    totalnetweightuom,
    totalnetvolumevalue,
    totalnetvolumeuom,
    totalpackageditemspeccount,
    totalpackageditemcount,
    shiptype
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_releasedomainname,
    in_release,
    in_transorderheaderdomain,
    in_transorderheader,
    in_transordertranscode,
    in_paymentmethodcddomain,
    in_paymentmethodcode,
    in_planninggroupdomain,
    in_planninggroup,
    in_ordertypedomainname,
    in_ordertype,
    in_timewindowemphasis,
    in_shipfromlocrefdomain,
    in_shipfromlocationref,
    in_shiptolocrefdomain,
    in_shiptolocationref,
    in_earlydeliverydate,
    in_latedeliverydate,
    in_declaredvaluecurrcode,
    to_number(in_declaredvalmonetaryamt),
    in_mustshipalone,
    in_bulkplandomainname,
    in_bulkplan,
    in_bestdirbuycurrcode,
    to_number(in_bestdirbuymonetaryamt),
    in_bestdirbuyratedomain,
    in_bestdirectbuyrate,
    in_bestdirsellcurrcode,
    to_number(in_bestdirsellmonetaryamt),
    in_bestdirsellratedomain,
    in_bestdirectsellrate,
    to_number(in_totalweightvalue),
    in_totalweightuom,
    to_number(in_totalvolumevalue),
    in_totalvolumeuom,
    to_number(in_totalnetweightvalue),
    in_totalnetweightuom,
    to_number(in_totalnetvolumevalue),
    in_totalnetvolumeuom,
    in_totpackageditemspeccnt,
    in_totalpackageditemcount,
    in_shiptype
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsrel ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_rel;

procedure import_planship_relline
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_releaselinedomainname in varchar2
,in_releaseline in varchar2
,in_packageditemdomainname in varchar2
,in_packageditem in varchar2
,in_packagetype in varchar2
,in_packagingdescription in varchar2
,in_packageshipunitwghtval in varchar2
,in_packageshipunitwghtuom in varchar2
,in_isdefaultpackaging in varchar2
,in_ishazardous in varchar2
,in_itemtransactioncode in varchar2
,in_itemdomainname in varchar2
,in_item in varchar2
,in_itemname in varchar2
,in_itemdescription in varchar2
,in_commoditydomainname in varchar2
,in_commodity in varchar2
,in_nmfcarticledomainname in varchar2
,in_nmfcarticle in varchar2
,in_nmfcclass in varchar2
,in_refnumqualifierdomain in varchar2
,in_refnumqualifier in varchar2
,in_itemweightvalue in varchar2
,in_itemweightuom in varchar2
,in_itemvolumevalue in varchar2
,in_itemvolumeuom in varchar2
,in_packageditemcount in number
,in_declaredvaluecurrcode in varchar2
,in_declaredvalmonetaryamt in varchar2
,in_shipunitspecrefdomain in varchar2
,in_shipunitspecref in varchar2
,in_shipunitspecdomainname in varchar2
,in_shipunitspec in varchar2
,in_tareweightvalue in varchar2
,in_tareweightuom in varchar2
,in_maxweightvalue in varchar2
,in_maxweightuom in varchar2
,in_volumevalue in varchar2
,in_volumeuom in varchar2
,in_lengthvalue in varchar2
,in_lengthuom in varchar2
,in_widthvalue in varchar2
,in_widthuom in varchar2
,in_heightvalue in varchar2
,in_heightuom in varchar2
,in_packageditemspeccount in number
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_relline
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    releaselinedomainname,
    releaseline,
    packageditemdomainname,
    packageditem,
    packagetype,
    packagingdescription,
    packageshipunitweightvalue,
    packageshipunitweightuom,
    isdefaultpackaging,
    ishazardous,
    itemtransactioncode,
    itemdomainname,
    item,
    itemname,
    itemdescription,
    commoditydomainname,
    commodity,
    nmfcarticledomainname,
    nmfcarticle,
    nmfcclass,
    refnumqualifierdomainname,
    refnumqualifier,
    itemweightvalue,
    itemweightuom,
    itemvolumevalue,
    itemvolumeuom,
    packageditemcount,
    declaredvaluecurrencycode,
    declaredvaluemonetaryamount,
    shipunitspecrefdomainname,
    shipunitspecref,
    shipunitspecdomainname,
    shipunitspec,
    tareweightvalue,
    tareweightuom,
    maxweightvalue,
    maxweightuom,
    volumevalue,
    volumeuom,
    lengthvalue,
    lengthuom,
    widthvalue,
    widthuom,
    heightvalue,
    heightuom,
    packageditemspeccount
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_releaselinedomainname,
    in_releaseline,
    in_packageditemdomainname,
    in_packageditem,
    in_packagetype,
    in_packagingdescription,
    to_number(in_packageshipunitwghtval),
    in_packageshipunitwghtuom,
    in_isdefaultpackaging,
    in_ishazardous,
    in_itemtransactioncode,
    in_itemdomainname,
    in_item,
    in_itemname,
    in_itemdescription,
    in_commoditydomainname,
    in_commodity,
    in_nmfcarticledomainname,
    in_nmfcarticle,
    in_nmfcclass,
    in_refnumqualifierdomain,
    in_refnumqualifier,
    to_number(in_itemweightvalue),
    in_itemweightuom,
    to_number(in_itemvolumevalue),
    in_itemvolumeuom,
    in_packageditemcount,
    in_declaredvaluecurrcode,
    to_number(in_declaredvalmonetaryamt),
    in_shipunitspecrefdomain,
    in_shipunitspecref,
    in_shipunitspecdomainname,
    in_shipunitspec,
    to_number(in_tareweightvalue),
    in_tareweightuom,
    to_number(in_maxweightvalue),
    in_maxweightuom,
    to_number(in_volumevalue),
    in_volumeuom,
    to_number(in_lengthvalue),
    in_lengthuom,
    to_number(in_widthvalue),
    in_widthuom,
    to_number(in_heightvalue),
    in_heightuom,
    in_packageditemspeccount
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsrelline ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_relline;

procedure import_planship_relrefnum
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_releaserefnumdomain in varchar2
,in_releaserefnum in varchar2
,in_releaserefnumvalue in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_relrefnum
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    releaserefnumdomainname,
    releaserefnum,
    releaserefnumvalue
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_releaserefnumdomain,
    in_releaserefnum,
    in_releaserefnumvalue
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsrelrefnum ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_relrefnum;

procedure import_planship_relstat
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_statustypedomainname in varchar2
,in_statustype in varchar2
,in_statusvaluedomainname in varchar2
,in_statusvalue in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_relstat
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    statustypedomainname,
    statustype,
    statusvaluedomainname,
    statusvalue
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_statustypedomainname,
    in_statustype,
    in_statusvaluedomainname,
    in_statusvalue
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsrelstat ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_relstat;

procedure import_planship_relsu
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_shipunitdomainname in varchar2
,in_shipunit in varchar2
,in_shipunitspecdomainname in varchar2
,in_shipunitspec in varchar2
,in_weightvalue in varchar2
,in_weightuom in varchar2
,in_volumevalue in varchar2
,in_volumeuom in varchar2
,in_unitnetweightvalue in varchar2
,in_unitnetweightuom in varchar2
,in_unitnetvolumevalue in varchar2
,in_unitnetvolumeuom in varchar2
,in_lengthvalue in varchar2
,in_lengthuom in varchar2
,in_widthvalue in varchar2
,in_widthuom in varchar2
,in_heightvalue in varchar2
,in_heightuom in varchar2
,in_packageditemdomainname in varchar2
,in_packageditem in varchar2
,in_packagetype in varchar2
,in_packageshipunitwghtval in varchar2
,in_packageshipunitwghtuom in varchar2
,in_isdefaultpacking in varchar2
,in_ishazardous in varchar2
,in_itemtransactioncode in varchar2
,in_itemdomainname in varchar2
,in_item in varchar2
,in_itemname in varchar2
,in_itemdescription in varchar2
,in_commoditydomainname in varchar2
,in_commodity in varchar2
,in_nmfcarticledomainname in varchar2
,in_nmfcarticle in varchar2
,in_nmfcclass in varchar2
,in_refnumqualifierdomain in varchar2
,in_refnumqualifier in varchar2
,in_refnumvalue in number
,in_linenumber in number
,in_itemissplitallowed in varchar2
,in_itemweightvalue in varchar2
,in_itemweightuom in varchar2
,in_itemvolumevalue in varchar2
,in_itemvolumeuom in varchar2
,in_packageditemcount in number
,in_packitemsuspecrefdom in varchar2
,in_packageitemsuspecref in varchar2
,in_packitemsuspecdomain in varchar2
,in_packageitemsuspec in varchar2
,in_packageitemtarewghtval in varchar2
,in_packageitemtarewghtuom in varchar2
,in_packageditemmaxwghtval in varchar2
,in_packageditemmaxwghtuom in varchar2
,in_packageditemvolumeval in varchar2
,in_packageditemvolumeuom in varchar2
,in_packageditemlengthval in varchar2
,in_packageditemlengthuom in varchar2
,in_packageditemwidthvalue in varchar2
,in_packageditemwidthuom in varchar2
,in_packageditemheightval in varchar2
,in_packageditemheightuom in varchar2
,in_packageditemspeccount in number
,in_weightpershipunitvalue in varchar2
,in_weightpershipunituom in varchar2
,in_volumepershipunitvalue in varchar2
,in_volumepershipunituom in varchar2
,in_countpershipunit in number
,in_shipunitreleasedomain in varchar2
,in_shipunitrelease in varchar2
,in_shipunitrellinedom in varchar2
,in_shipunitreleaseline in varchar2
,in_issplitallowed in varchar2
,in_shipunitcount in number
,in_transordershipunitdom in varchar2
,in_transordershipunit in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_relsu
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    shipunitdomainname,
    shipunit,
    shipunitspecdomainname,
    shipunitspec,
    weightvalue,
    weightuom,
    volumevalue,
    volumeuom,
    unitnetweightvalue,
    unitnetweightuom,
    unitnetvolumevalue,
    unitnetvolumeuom,
    lengthvalue,
    lengthuom,
    widthvalue,
    widthuom,
    heightvalue,
    heightuom,
    packageditemdomainname,
    packageditem,
    packagetype,
    packageshipunitweightvalue,
    packageshipunitweightuom,
    isdefaultpacking,
    ishazardous,
    itemtransactioncode,
    itemdomainname,
    item,
    itemname,
    itemdescription,
    commoditydomainname,
    commodity,
    nmfcarticledomainname,
    nmfcarticle,
    nmfcclass,
    refnumqualifierdomainname,
    refnumqualifier,
    refnumvalue,
    linenumber,
    itemissplitallowed,
    itemweightvalue,
    itemweightuom,
    itemvolumevalue,
    itemvolumeuom,
    packageditemcount,
    packageitemsuspecrefdomainname,
    packageitemsuspecref,
    packageitemsuspecdomainname,
    packageitemsuspec,
    packageditemtareweightvalue,
    packageditemtareweightuom,
    packageditemmaxweightvalue,
    packageditemmaxweightuom,
    packageditemvolumevalue,
    packageditemvolumeuom,
    packageditemlengthvalue,
    packageditemlengthuom,
    packageditemwidthvalue,
    packageditemwidthuom,
    packageditemheightvalue,
    packageditemheightuom,
    packageditemspeccount,
    weightpershipunitvalue,
    weightpershipunituom,
    volumepershipunitvalue,
    volumepershipunituom,
    countpershipunit,
    shipunitreleasedomainname,
    shipunitrelease,
    shipunitreleaselinedomainname,
    shipunitreleaseline,
    issplitallowed,
    shipunitcount,
    transordershipunitdomainname,
    transordershipunit
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_shipunitdomainname,
    in_shipunit,
    in_shipunitspecdomainname,
    in_shipunitspec,
    to_number(in_weightvalue),
    in_weightuom,
    to_number(in_volumevalue),
    in_volumeuom,
    to_number(in_unitnetweightvalue),
    in_unitnetweightuom,
    to_number(in_unitnetvolumevalue),
    in_unitnetvolumeuom,
    to_number(in_lengthvalue),
    in_lengthuom,
    to_number(in_widthvalue),
    in_widthuom,
    to_number(in_heightvalue),
    in_heightuom,
    in_packageditemdomainname,
    in_packageditem,
    in_packagetype,
    to_number(in_packageshipunitwghtval),
    in_packageshipunitwghtuom,
    in_isdefaultpacking,
    in_ishazardous,
    in_itemtransactioncode,
    in_itemdomainname,
    in_item,
    in_itemname,
    in_itemdescription,
    in_commoditydomainname,
    in_commodity,
    in_nmfcarticledomainname,
    in_nmfcarticle,
    in_nmfcclass,
    in_refnumqualifierdomain,
    in_refnumqualifier,
    in_refnumvalue,
    in_linenumber,
    in_itemissplitallowed,
    to_number(in_itemweightvalue),
    in_itemweightuom,
    to_number(in_itemvolumevalue),
    in_itemvolumeuom,
    in_packageditemcount,
    in_packitemsuspecrefdom,
    in_packageitemsuspecref,
    in_packitemsuspecdomain,
    in_packageitemsuspec,
    to_number(in_packageitemtarewghtval),
    in_packageitemtarewghtuom,
    to_number(in_packageditemmaxwghtval),
    in_packageditemmaxwghtuom,
    to_number(in_packageditemvolumeval),
    in_packageditemvolumeuom,
    to_number(in_packageditemlengthval),
    in_packageditemlengthuom,
    to_number(in_packageditemwidthvalue),
    in_packageditemwidthuom,
    to_number(in_packageditemheightval),
    in_packageditemheightuom,
    in_packageditemspeccount,
    to_number(in_weightpershipunitvalue),
    in_weightpershipunituom,
    to_number(in_volumepershipunitvalue),
    in_volumepershipunituom,
    in_countpershipunit,
    in_shipunitreleasedomain,
    in_shipunitrelease,
    in_shipunitrellinedom,
    in_shipunitreleaseline,
    in_issplitallowed,
    in_shipunitcount,
    in_transordershipunitdom,
    in_transordershipunit
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsrelsu ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_relsu;

procedure import_planship_reltoip
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_involvedpartyqualifier in varchar2
,in_locationrefdomainname in varchar2
,in_locationref in varchar2
,in_contactrefdomainname in varchar2
,in_contactref in varchar2
,in_contacttransactioncode in varchar2
,in_contactemailaddress in varchar2
,in_contactlanguagespoken in varchar2
,in_isprimarycontact in varchar2
,in_commethodrank in number
,in_contactrefcommethod in varchar2
,in_expectedresponsedurval in number
,in_expectedresponseduruom in varchar2
,in_commethod in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_reltoip
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    involvedpartyqualifier,
    locationrefdomainname,
    locationref,
    contactrefdomainname,
    contactref,
    contacttransactioncode,
    contactemailaddress,
    contactlanguagespoken,
    isprimarycontact,
    commethodrank,
    contactrefcommethod,
    expectedresponsedurationvalue,
    expectedresponsedurationuom,
    commethod
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_involvedpartyqualifier,
    in_locationrefdomainname,
    in_locationref,
    in_contactrefdomainname,
    in_contactref,
    in_contacttransactioncode,
    in_contactemailaddress,
    in_contactlanguagespoken,
    in_isprimarycontact,
    in_commethodrank,
    in_contactrefcommethod,
    in_expectedresponsedurval,
    in_expectedresponseduruom,
    in_commethod
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsreltoip ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_reltoip;

procedure import_planship_reltorem
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_remarksequence in number
,in_remarkqualifier in varchar2
,in_remarklevel in number
,in_remarktext in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_reltorem
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    remarksequence,
    remarkqualifier,
    remarklevel,
    remarktext
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_remarksequence,
    in_remarkqualifier,
    in_remarklevel,
    in_remarktext
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsreltorem ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_reltorem;

procedure import_planship_reltorn
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_release in varchar2
,in_refnumqualifierdomain in varchar2
,in_refnumqualifier in varchar2
,in_refnumvalue in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_reltorn
  (
    tranmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    release,
    refnumqualifierdomainname,
    refnumqualifier,
    refnumvalue
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_release,
    in_refnumqualifierdomain,
    in_refnumqualifier,
    in_refnumvalue
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsreltorn ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_reltorn;

procedure import_planship_shiphdr
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_remarksequence in number
,in_remarkqualifier in varchar2
,in_sendreason in varchar2
,in_shipmentdomainname in varchar2
,in_shipment in varchar2
,in_transactioncode in varchar2
,in_serviceproviderdomain in varchar2
,in_serviceprovider in varchar2
,in_servprovideraliasqual in varchar2
,in_servprovideraliasval in varchar2
,in_servproviderdelserv in varchar2
,in_isserviceproviderfixed in varchar2
,in_contactdomainname in varchar2
,in_contact in varchar2
,in_istendercontactfixed in varchar2
,in_rateofferingdomainname in varchar2
,in_rateoffering in varchar2
,in_israteofferingfixed in varchar2
,in_rategeodomainname in varchar2
,in_rategeo in varchar2
,in_isrategeofixed in varchar2
,in_totalplannedcostcurrcd in varchar2
,in_totalplannedcostmonamt in varchar2
,in_totalactualcostcurrcd in varchar2
,in_totalactualcostmonamt in varchar2
,in_totalweightedcostcurcd in varchar2
,in_totalweightedcostmonam in varchar2
,in_iscostfixed in varchar2
,in_isservicetimefixed in varchar2
,in_itransactionno in number
,in_ishazardous in varchar2
,in_transportmode in varchar2
,in_totalweightvalue in varchar2
,in_totalweightuom in varchar2
,in_totalvolumevalue in varchar2
,in_totalvolumeuom in varchar2
,in_totalnetweightvalue in varchar2
,in_totalnetweightuom in varchar2
,in_totalnetvolumevalue in varchar2
,in_totalnetvolumeuom in varchar2
,in_totalshipunitcount in number
,in_totpackageditemspeccnt in number
,in_totalpackageditemcount in number
,in_startdate in date
,in_enddate in date
,in_commercialtermsdomain in varchar2
,in_commercialterms in varchar2
,in_stopcount in number
,in_numorderreleases in number
,in_totalshippingspaces in number
,in_istemperaturecontrol in varchar2
,in_earlieststarttime in date
,in_lateststarttime in date
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shiphdr
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    remarksequence,
    remarkqualifier,
    sendreason,
    shipmentdomainname,
    shipment,
    transactioncode,
    serviceproviderdomainname,
    serviceprovider,
    serviceprovideraliasqualifier,
    serviceprovideraliasvalue,
    serviceproviderdeliveryservice,
    isserviceproviderfixed,
    contactdomainname,
    contact,
    istendercontactfixed,
    rateofferingdomainname,
    rateoffering,
    israteofferingfixed,
    rategeodomainname,
    rategeo,
    isrategeofixed,
    totalplannedcostcurrencycode,
    totalplannedcostmonetaryamount,
    totalactualcostcurrencycode,
    totalactualcostmonetaryamount,
    totalweightedcostcurrencycode,
    totalweightedcostmonetaryamoun,
    iscostfixed,
    isservicetimefixed,
    itransactionno,
    ishazardous,
    transportmode,
    totalweightvalue,
    totalweightuom,
    totalvolumevalue,
    totalvolumeuom,
    totalnetweightvalue,
    totalnetweightuom,
    totalnetvolumevalue,
    totalnetvolumeuom,
    totalshipunitcount,
    totalpackageditemspeccount,
    totalpackageditemcount,
    startdate,
    enddate,
    commercialtermsdomainname,
    commercialterms,
    stopcount,
    numorderreleases,
    totalshippingspaces,
    istemperaturecontrol,
    earlieststarttime,
    lateststarttime
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_remarksequence,
    in_remarkqualifier,
    in_sendreason,
    in_shipmentdomainname,
    in_shipment,
    in_transactioncode,
    in_serviceproviderdomain,
    in_serviceprovider,
    in_servprovideraliasqual,
    in_servprovideraliasval,
    in_servproviderdelserv,
    in_isserviceproviderfixed,
    in_contactdomainname,
    in_contact,
    in_istendercontactfixed,
    in_rateofferingdomainname,
    in_rateoffering,
    in_israteofferingfixed,
    in_rategeodomainname,
    in_rategeo,
    in_isrategeofixed,
    in_totalplannedcostcurrcd,
    to_number(in_totalplannedcostmonamt),
    in_totalactualcostcurrcd,
    to_number(in_totalactualcostmonamt),
    in_totalweightedcostcurcd,
    to_number(in_totalweightedcostmonam),
    in_iscostfixed,
    in_isservicetimefixed,
    in_itransactionno,
    in_ishazardous,
    in_transportmode,
    to_number(in_totalweightvalue),
    in_totalweightuom,
    to_number(in_totalvolumevalue),
    in_totalvolumeuom,
    to_number(in_totalnetweightvalue),
    in_totalnetweightuom,
    to_number(in_totalnetvolumevalue),
    in_totalnetvolumeuom,
    in_totalshipunitcount,
    in_totpackageditemspeccnt,
    in_totalpackageditemcount,
    in_startdate,
    in_enddate,
    in_commercialtermsdomain,
    in_commercialterms,
    in_stopcount,
    in_numorderreleases,
    in_totalshippingspaces,
    in_istemperaturecontrol,
    in_earlieststarttime,
    in_lateststarttime
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshiphdr ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shiphdr;

procedure import_planship_shiphdr2
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_isautomergeconsolidate in varchar2
,in_perspective in varchar2
,in_itinerarydomainname in varchar2
,in_itinerary in varchar2
,in_parentlegdomainname in varchar2
,in_parentleg in varchar2
,in_shipmentaswork in varchar2
,in_feasibility in varchar2
,in_checktimeconstraint in varchar2
,in_checkcostconstraint in varchar2
,in_checkcapconstraint in varchar2
,in_weightcode in varchar2
,in_rule7 in varchar2
,in_shipmentreleased in varchar2
,in_dimweightvalue in varchar2
,in_dimweightuom in varchar2
,in_ispreload in varchar2
,in_bulkplandomainname in varchar2
,in_bulkplan in varchar2
,in_intrailerbuild in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shiphdr2
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    isautomergeconsolidate,
    perspective,
    itinerarydomainname,
    itinerary,
    parentlegdomainname,
    parentleg,
    shipmentaswork,
    feasibility,
    checktimeconstraint,
    checkcostconstraint,
    checkcapacityconstraint,
    weightcode,
    rule7,
    shipmentreleased,
    dimweightvalue,
    dimweightuom,
    ispreload,
    bulkplandomainname,
    bulkplan,
    intrailerbuild
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_isautomergeconsolidate,
    in_perspective,
    in_itinerarydomainname,
    in_itinerary,
    in_parentlegdomainname,
    in_parentleg,
    in_shipmentaswork,
    in_feasibility,
    in_checktimeconstraint,
    in_checkcostconstraint,
    in_checkcapconstraint,
    in_weightcode,
    in_rule7,
    in_shipmentreleased,
    to_number(in_dimweightvalue),
    in_dimweightuom,
    in_ispreload,
    in_bulkplandomainname,
    in_bulkplan,
    in_intrailerbuild
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshiphdr2 ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shiphdr2;

procedure import_planship_shipstop
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_stopsequence in number
,in_stopdurationvalue in number
,in_stopdurationuom in varchar2
,in_isappointment in varchar2
,in_locationrefdomainname in varchar2
,in_locationref in varchar2
,in_distfromprevstopvalue in varchar2
,in_distfromprevstopuom in varchar2
,in_stopreason in varchar2
,in_arrivaltimeplanned in date
,in_arrivaltimeestimated in date
,in_isarrivalplantimefix in varchar2
,in_departureplannedtime in date
,in_departureestimatedtime in date
,in_isdepestimatedtimefix in varchar2
,in_ispermanent in varchar2
,in_isdepot in varchar2
,in_accesstimedurationval in number
,in_accesstimedurationuom in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is

dteArrivalTimeEstimated date;
dteArrivalTimePlanned date;
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

begin
  if trunc(in_arrivaltimeestimated) = to_date('12/30/1899','mm/dd/yyyy') then
    dtearrivaltimeestimated := null;
  else
    dtearrivaltimeestimated := in_arrivaltimeestimated;
  end if;
exception when others then
  dtearrivaltimeestimated := null;
end;

begin
  if trunc(in_arrivaltimeplanned) = to_date('12/30/1899','mm/dd/yyyy') then
    dtearrivaltimeplanned := null;
  else
    dtearrivaltimeplanned := in_arrivaltimeplanned;
  end if;
exception when others then
  dtearrivaltimeplanned := null;
end;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shipstop
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    stopsequence,
    stopdurationvalue,
    stopdurationuom,
    isappointment,
    locationrefdomainname,
    locationref,
    distfromprevstopvalue,
    distfromprevstopuom,
    stopreason,
    arrivaltimeplanned,
    arrivaltimeestimated,
    isarrivalplannedtimefixed,
    departureplannedtime,
    departureestimatedtime,
    isdepartureestimatedtimefixed,
    ispermanent,
    isdepot,
    accessorialtimedurationvalue,
    accessorialtimedurationuom
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_stopsequence,
    in_stopdurationvalue,
    in_stopdurationuom,
    in_isappointment,
    in_locationrefdomainname,
    in_locationref,
    round(to_number(in_distfromprevstopvalue)),
    in_distfromprevstopuom,
    in_stopreason,
    dtearrivaltimeplanned,
    dtearrivaltimeestimated,
    in_isarrivalplantimefix,
    in_departureplannedtime,
    in_departureestimatedtime,
    in_isdepestimatedtimefix,
    in_ispermanent,
    in_isdepot,
    in_accesstimedurationval,
    in_accesstimedurationuom
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshipstop ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shipstop;

procedure import_planship_shipstopdtl
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_stopsequence in number
,in_shipmentstopactivity in varchar2
,in_activitydurationvalue in number
,in_activitydurationuom in varchar2
,in_shipunitdomainname in varchar2
,in_shipunit in varchar2
,in_isshipstoppermanent in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shipstopdtl
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    stopsequence,
    shipmentstopactivity,
    activitydurationvalue,
    activitydurationuom,
    shipunitdomainname,
    shipunit,
    isshipstoppermanent
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_stopsequence,
    in_shipmentstopactivity,
    in_activitydurationvalue,
    in_activitydurationuom,
    in_shipunitdomainname,
    in_shipunit,
    in_isshipstoppermanent
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshipstopdtl ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shipstopdtl;

procedure import_planship_bolcomments
(in_func in out varchar2
,in_record_type in varchar2
,in_sendertransmissionno in number
,in_shipto in varchar2
,in_bolcomment in varchar2
,in_addr in varchar2
,in_city in varchar2
,in_state in varchar2
,in_postalcode in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_bolcomments
  (
    sendertransmissionno,
    shipto,
    bolcomment,
    addr,
    city,
    state,
    postalcode
  )
  values
  (
    in_sendertransmissionno,
    in_shipto,
    in_bolcomment,
    in_addr,
    in_city,
    in_state,
    in_postalcode
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsbolcomments ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_bolcomments;

procedure import_planship_shipunit
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime in date
,in_sendertransmissionno in number
,in_referencetransno in number
,in_shipunitdomainname in varchar2
,in_shipunit in varchar2
,in_shipunitspecdomainname in varchar2
,in_shipunitspec in varchar2
,in_shiptolocationdomain in varchar2
,in_shiptolocation in varchar2
,in_weightvalue in varchar2
,in_weightuom in varchar2
,in_volumevalue in varchar2
,in_volumeuom in varchar2
,in_unitnetweightvalue in varchar2
,in_unitnetweightuom in varchar2
,in_unitnetvolumevalue in varchar2
,in_unitnetvolumeuom in varchar2
,in_lengthvalue in varchar2
,in_lengthuom in varchar2
,in_widthvalue in varchar2
,in_widthuom in varchar2
,in_heightvalue in varchar2
,in_heightuom in varchar2
,in_shipunitcount in number
,in_releaseshipunitdomain in varchar2
,in_releaseshipunit in varchar2
,in_receivednetweightvalue in varchar2
,in_receivednetweightuom in varchar2
,in_receivednetvolumevalue in varchar2
,in_receivednetvolumeuom in varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shipunit
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    shipunitdomainname,
    shipunit,
    shipunitspecdomainname,
    shipunitspec,
    shiptolocationdomainname,
    shiptolocation,
    weightvalue,
    weightuom,
    volumevalue,
    volumeuom,
    unitnetweightvalue,
    unitnetweightuom,
    unitnetvolumevalue,
    unitnetvolumeuom,
    lengthvalue,
    lengthuom,
    widthvalue,
    widthuom,
    heightvalue,
    heightuom,
    shipunitcount,
    releaseshipunitdomainname,
    releaseshipunit,
    receivednetweightvalue,
    receivednetweightuom,
    receivednetvolumevalue,
    receivednetvolumeuom
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_shipunitdomainname,
    in_shipunit,
    in_shipunitspecdomainname,
    in_shipunitspec,
    in_shiptolocationdomain,
    in_shiptolocation,
    to_number(in_weightvalue),
    in_weightuom,
    to_number(in_volumevalue),
    in_volumeuom,
    to_number(in_unitnetweightvalue),
    in_unitnetweightuom,
    to_number(in_unitnetvolumevalue),
    in_unitnetvolumeuom,
    to_number(in_lengthvalue),
    in_lengthuom,
    to_number(in_widthvalue),
    in_widthuom,
    to_number(in_heightvalue),
    in_heightuom,
    in_shipunitcount,
    in_releaseshipunitdomain,
    in_releaseshipunit,
    to_number(in_receivednetweightvalue),
    in_receivednetweightuom,
    to_number(in_receivednetvolumevalue),
    in_receivednetvolumeuom
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshipunit ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shipunit;

procedure import_planship_shipunitspec
(in_func in out varchar2
,in_record_type in varchar2
,in_transcreatedatetime date
,in_sendertransmissionno number
,in_referencetransno number
,in_shipunitspecdomainname varchar2
,in_shipunitspec varchar2
,in_shipunitspecname varchar2
,in_tareweightvalue varchar2
,in_tareweightuom varchar2
,in_maxweightvalue varchar2
,in_maxweightuom varchar2
,in_volumevalue varchar2
,in_volumeuom varchar2
,in_lengthvalue varchar2
,in_lengthuom varchar2
,in_widthvalue varchar2
,in_widthuom varchar2
,in_heightvalue varchar2
,in_heightuom varchar2
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is
begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_shipunitspec
  (
    transmissioncreatedatetime,
    sendertransmissionno,
    referencetransmissionno,
    shipunitspecdomainname,
    shipunitspec,
    shipunitspecname,
    tareweightvalue,
    tareweightuom,
    maxweightvalue,
    maxweightuom,
    volumevalue,
    volumeuom,
    lengthvalue,
    lengthuom,
    widthvalue,
    widthuom,
    heightvalue,
    heightuom
  )
  values
  (
    in_transcreatedatetime,
    in_sendertransmissionno,
    in_referencetransno,
    in_shipunitspecdomainname,
    in_shipunitspec,
    in_shipunitspecname,
    to_number(in_tareweightvalue),
    in_tareweightuom,
    to_number(in_maxweightvalue),
    in_maxweightuom,
    to_number(in_volumevalue),
    in_volumeuom,
    to_number(in_lengthvalue),
    in_lengthuom,
    to_number(in_widthvalue),
    in_widthuom,
    to_number(in_heightvalue),
    in_heightuom
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmsshipunitspec ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_shipunitspec;

procedure import_planship_tail
(in_func in out varchar2
,in_record_type in varchar2
,in_sendertransmissionno in number
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
)
is


begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  return;
end if;

if rtrim(in_func) in ('A','R') then
  insert into tmsplanship_tail
  (
    sendertransmissionno
  )
  values
  (
    in_sendertransmissionno
  );
end if;

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := substr('zimtmstail ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_planship_tail;

procedure process_planship
(in_userid in varchar2
,out_errorno in out NUMBER
,out_msg in out varchar2
)
is

cursor curTransmission(in_tran number) is
 select nvl(sendertransmissionno,0)
   from tmsplanship_hdr
  where status = 1
    and sendertransmissionno > in_tran
  order by sendertransmissionno
  for update;


last_transmission number;
transmission number;
tailcount number;
counter number;

begin

out_errorno := 0;
out_msg := 'OKAY';

last_transmission := 0;


loop
  transmission := null;
  tailcount := 0;
  counter := 0;

  open curTransmission(last_transmission);
  fetch curTransmission into transmission;
  close curTransmission;

  if transmission is null then
    exit;
  end if;

  last_transmission := transmission;

  update tmsplanship_hdr
     set status=2
   where sendertransmissionno=transmission;

  zms.log_msg('TMSPLAN', null, null,
    'Begin TMS planning update for Transmission ' || transmission,
    'I', in_userid, strMsg);

  commit;

  /* If there are no rows loaded into tail, wait 10 seconds and try again.
     Repeat for up to 20 minutes */
  while(tailcount=0 AND counter<=120)
  loop
     select count(1) into tailcount from tmsplanship_tail where sendertransmissionno=transmission;
     if tailcount=0 then
        dbms_lock.sleep(10);
     end if;
     counter := counter+1;
  end loop;

  if tailcount=0 then
     zms.log_msg('TMSPLAN', null, null,
     'No tail records found for Transmission ' || transmission,
     'E', in_userid, strMsg);
  else
     ztms.process_transmission(transmission, in_userid, out_msg);

     if out_msg != 'OKAY' then
       zms.log_msg('TMSPLAN', null, null,
         'TMS planning update error: ' || out_msg,
         'E', in_userid, strMsg);
     end if;
  end if;

  delete from tmsplanship_relline where sendertransmissionno=transmission;
  delete from tmsplanship_relrefnum where sendertransmissionno=transmission;
  delete from tmsplanship_relstat where sendertransmissionno=transmission;
  delete from tmsplanship_relsu where sendertransmissionno=transmission;
  delete from tmsplanship_reltoip where sendertransmissionno=transmission;
  delete from tmsplanship_reltorem where sendertransmissionno=transmission;
  delete from tmsplanship_reltorn where sendertransmissionno=transmission;
  delete from tmsplanship_shiphdr2 where sendertransmissionno=transmission;
  delete from tmsplanship_shipstop where sendertransmissionno=transmission;
  delete from tmsplanship_shipstopdtl where sendertransmissionno=transmission;
  delete from tmsplanship_bolcomments where sendertransmissionno=transmission;
  delete from tmsplanship_shipunit where sendertransmissionno=transmission;
  delete from tmsplanship_shipunitspec where sendertransmissionno=transmission;
  delete from tmsplanship_tail where sendertransmissionno=transmission;
  delete from tmsplanship_rel where sendertransmissionno=transmission;
  delete from tmsplanship_shiphdr where sendertransmissionno=transmission;
  delete from tmsplanship_hdr where sendertransmissionno=transmission;

  zms.log_msg('TMSPLAN', null, null,
    'End TMS planning update for Transmission ' || transmission,
    'I', in_userid, strMsg);
end loop;

exception when others then
  rollback;
  out_msg := substr('zimtmsprocess_planship ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end process_planship;

procedure begin_transynd_actualshipment
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
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
strDebugYN char(1);

strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);

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
   where view_name = 'TMS_ACTUALSHIP_SHDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_loadno != 0 then
     l_condition := ' WHERE OH.LOADNO = '||to_char(in_loadno)
                 || ' ';
  elsif in_orderid != 0 then
     l_condition := ' WHERE OH.ORDERID = '||to_char(in_orderid)
                 || ' AND OH.SHIPID = '||to_char(in_shipid)
                 || ' ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  if in_custid <> 'ALL' then
    cu := null;
    open curCustomer;
    fetch curCustomer into cu;
    close curCustomer;
    if cu.custid is null then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;

    l_condition := l_condition || ' AND OH.CUSTID = '''||in_custid||''' ';
  end if;

  debugmsg('Condition = '||l_condition);

  -- Create header view
debugmsg('create header view');
cmdSql := 'CREATE VIEW ALPS.TMS_ACTUALSHIP_SHDR_' || strSuffix ||
  ' (CUSTID,ORDERID,SHIPID,WAVE,LOADNO,' ||
  'SHIPMENT,SHIPMENTREFNUMQUALIFIER,SHIPMENTREFNUMVALUE,SHIPMENTREFNUM2VALUE,SERVICEPROVIDER,' ||
  'PRONO,FACILITY,DELIVERYSERVICE) '||
  'AS SELECT ' ||
  'OH.CUSTID,OH.ORDERID,OH.SHIPID,OH.WAVE,OH.LOADNO,OH.TMS_SHIPMENT_ID,''LD'',OH.REFERENCE,' ||
  '(SELECT NVL(SUM(NVL(PH.OUTPALLETS,0)),0) ' ||
  'FROM PALLETHISTORY PH ' ||
  'WHERE PH.LOADNO=OH.LOADNO ' ||
  'AND PH.CUSTID=OH.CUSTID ' ||
  'AND PH.FACILITY=OH.FROMFACILITY ' ||
  'AND PH.ORDERID=OH.ORDERID ' ||
  'AND PH.SHIPID=OH.SHIPID),' ||
  'OH.CARRIER, NVL(OH.PRONO,LD.PRONO),OH.FROMFACILITY,OH.DELIVERYSERVICE ' ||
  ' FROM LOADS LD, ORDERHDR OH ' ||
  l_condition ||
  ' AND OH.LOADNO = LD.LOADNO ' ||
  ' AND (NVL(OH.LOADNO,0)=0' ||
  ' OR NOT EXISTS(SELECT 1' ||
  ' FROM ORDERHDR OH1' ||
  ' WHERE OH1.TMS_SHIPMENT_ID = OH.TMS_SHIPMENT_ID' ||
  ' AND OH1.LOADNO = OH.LOADNO' ||
  ' AND OH1.ORDERID <> OH.ORDERID' ||
  ' AND OH1.SHIPID <> OH.SHIPID' ||
  ' AND OH1.ORDERSTATUS NOT IN (''9'',''X'')))';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

  -- Create header view
debugmsg('create actualship_stop view');
cmdSql := 'CREATE VIEW ALPS.TMS_ACTUALSHIP_STOP_' || strSuffix ||
  ' (CUSTID,ORDERID,SHIPID,WAVE,LOADNO,' ||
  'STOPSEQUENCE,ARRIVALPLANNEDTIME,ARRIVALESTIMATEDTIME,ARRIVALACTUALTTIME,ISARRIVALPLANTIMEFIXED,'||
  'DEPARTUREPLANNEDTIME,DEPARTUREESTIMATEDTIME,DEPARTUREACTUALTTIME,ISDEPARTUREPLANTIMEFIXED, ' ||
  'STATUSUPDATE) '||
  'AS SELECT ' ||
  'OH.CUSTID,OH.ORDERID,OH.SHIPID,OH.WAVE,OH.LOADNO,' ||
  'ROWNUM,NVL(TO_CHAR(OH.ARRIVALDATE,''YYYYMMDDHH24MISS''),'' ''),NVL(TO_CHAR(OH.ARRIVALDATE,''YYYYMMDDHH24MISS''),'' ''),NVL(TO_CHAR(OH.ARRIVALDATE,''YYYYMMDDHH24MISS''),'' ''),'' '',' ||
  'NVL(TO_CHAR(OH.SHIPDATE,''YYYYMMDDHH24MISS''),'' ''),NVL(TO_CHAR(OH.SHIPDATE,''YYYYMMDDHH24MISS''),'' ''),NVL(TO_CHAR(OH.DATESHIPPED,''YYYYMMDDHH24MISS''),'' ''),'' '',' ||
  'NVL(TO_CHAR(OH.STATUSUPDATE,''YYYYMMDDHH24MISS''),'' '') ' ||
  ' FROM ORDERHDR OH' ||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end begin_transynd_actualshipment;


procedure end_transynd_actualshipment
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'DROP VIEW TMS_ACTUALSHIP_STOP_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'DROP VIEW TMS_ACTUALSHIP_SHDR_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end end_transynd_actualshipment;

procedure begin_transynd_item
(in_custid IN varchar2
,in_item IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curItem is
  select custid
    from custitem
   where custid = in_custid
     and item = in_item;
ci curItem%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strDebugYN char(1);

strSuffix varchar2(32);
viewcount integer;

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

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
   where view_name = 'TMS_ITEM_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code:'||in_custid;
  return;
end if;

ci := null;
open curItem;
fetch curItem into ci;
close curItem;
if ci.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Item Code:'||in_item;
  return;
end if;

debugmsg('Custid = '||in_custid);
debugmsg('Item = '||in_item);

  -- Create header view
cmdSql := 'CREATE VIEW ALPS.TMS_ITEM_DTL_' || strSuffix ||
  ' (CUSTID,ITEMDOMAIN,ITEM,ITEMNAME,DESCRIPTION,COMMODITY,NMFCARTICLE,' ||
  'NMFCCLASS,REFNUMVALUE,PACKAGEDITEMDOMAIN,' ||
  'PACKAGEDITEM,PACKAGEDITEMDESCRIPTION,ISHAZARDOUS) '||
  'AS SELECT ' ||
  'CI.CUSTID,CI.CUSTID,CI.ITEM,CI.ITEM,CI.DESCR,CI.TMS_COMMODITY_CODE,CI.NMFC,' ||
  'LTRIM(TO_CHAR(ROUND(NCC.CLASS,1),''9999.9'')),CIA.ITEMALIAS,' ||
  'CI.CUSTID,CI.ITEM,CI.DESCR,CI.HAZARDOUS' ||
  ' FROM CUSTITEM CI,NMFCLASSCODES NCC,CUSTITEMALIAS CIA' ||
  ' WHERE CI.NMFC=NCC.NMFC(+)' ||
  ' AND CI.CUSTID=CIA.CUSTID(+)' ||
  ' AND CI.ITEM=CIA.ITEM(+)' ||
  ' AND CI.CUSTID = '''||in_custid||'''' ||
  ' AND CI.ITEM = '''||in_item||'''';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end begin_transynd_item;


procedure end_transynd_item
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'DROP VIEW TMS_ITEM_DTL_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end end_transynd_item;

procedure begin_transynd_orderrelease
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_orderstatus_values IN varchar2
,in_ordertype_values IN varchar2
,in_exclude_impexp IN varchar2
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
strDebugYN char(1);

strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);

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
   where view_name = 'TMS_ORDERREL_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' AND OH.ORDERID = '||to_char(in_orderid)
                 || ' AND OH.SHIPID = '||to_char(in_shipid)
                 || ' ';
  else
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  if in_custid <> 'ALL' then
    cu := null;
    open curCustomer;
    fetch curCustomer into cu;
    close curCustomer;
    if cu.custid is null then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;
    l_condition := l_condition || ' AND OH.CUSTID = '''||in_custid||'''';
  end if;

debugmsg('condition is ' || l_condition);
  -- Create header view
cmdSql := 'CREATE VIEW ALPS.TMS_ORDERREL_DTL_' || strSuffix ||
  ' (CUSTID,ORDERID,SHIPID,LOADNO,' ||
  'GENERICSTATUSUPDATEDOMAIN,GENERICSTATUSUPDATE,STATUSVALUE,REFERENCE, '||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02) '||
  'AS SELECT ' ||
  'OH.CUSTID,OH.ORDERID,OH.SHIPID,OH.LOADNO,' ||
  'OH.CUSTID,OH.TMS_RELEASE_ID,OH.ORDERSTATUS,OH.REFERENCE, ' ||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02 '||
  'FROM ORDERHDR OH WHERE OH.ORDERSTATUS ';

if rtrim(in_orderstatus_values) is null then
  debugmsg('default order status values');
  cmdSql := cmdSql ||
    ' in (''2'',''4'',''5'',''6'',''7'',''8'',''9'',''X'') ';
else
  debugmsg('use in_orderstatus_values ' || in_orderstatus_values);
  cmdSql := cmdSql || zcm.in_str_clause('I',in_orderstatus_values);
end if;

if rtrim(in_ordertype_values) is not null then
  cmdSql := cmdSQL || ' and OH.ORDERTYPE '
            ||zcm.in_str_clause('I', in_ordertype_values);
end if;

if nvl(rtrim(in_exclude_impexp),'N') = 'Y' then
  cmdSql := cmdSQL || ' and OH.STATUSUSER != ''IMPORDER'' ';
end if;

cmdSql := cmdSql || l_condition;

debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimtmsbto ' || sqlerrm;
  out_errorno := sqlcode;
end begin_transynd_orderrelease;


procedure end_transynd_orderrelease
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'DROP VIEW TMS_ORDERREL_DTL_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end end_transynd_orderrelease;

procedure begin_transynd_shipeventstatus
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
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
strDebugYN char(1);

strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

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
   where view_name = 'TMS_SHPEVNTSTAT_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' AND OH.ORDERID = '||to_char(in_orderid)
                 || ' AND OH.SHIPID = '||to_char(in_shipid)
                 || ' ';
  else
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  if in_custid <> 'ALL' then
    cu := null;
    open curCustomer;
    fetch curCustomer into cu;
    close curCustomer;
    if cu.custid is null then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;

    l_condition := l_condition || ' AND OH.CUSTID = '''||in_custid||'''';
  end if;

  debugmsg('Condition = '||l_condition);

  -- Create header view
cmdSql := 'CREATE VIEW ALPS.TMS_SHPEVNTSTAT_DTL_' || strSuffix ||
  ' (CUSTID,ORDERID,SHIPID,' ||
  'SERVICEPROVIDERDOMAIN,SERVICEPROVIDERALIASVALUE,SHIPMENTREFNUMVALUE,' ||
  'STATUSCODE,EVENTDATE,STATUSREASONCODE,SSSTOPSEQUENCENUM,SSREMARKS) ' ||
  'AS SELECT ' ||
  'OH.CUSTID,OH.ORDERID,OH.SHIPID,' ||
  ''' '',C.SCAC,OH.LOADNO,' ||
  ''' '','' '','' '','' '','' ''' ||
  ' FROM ORDERHDR OH,CARRIER C' ||
  ' WHERE OH.CARRIER = C.CARRIER' ||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end begin_transynd_shipeventstatus;


procedure end_transynd_shipeventstatus
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'DROP VIEW TMS_SHPEVNTSTAT_DTL_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end end_transynd_shipeventstatus;

procedure begin_transynd_transorder
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrders is
  select orderid,
         shipid
    FROM orderhdr oh
   WHERE in_custid IN (custid,'ALL')
     AND wave=in_loadno
     AND EXISTS(SELECT 1
                FROM ORDERDTL OD
                WHERE OH.ORDERID=OD.ORDERID
                AND OH.SHIPID=OD.SHIPID
                AND OH.CUSTID=OD.CUSTID
                AND OD.QTYCOMMIT<>0
                AND OD.LINESTATUS<>'X');
co curOrders%rowtype;

CURSOR curShipUnits(in_order NUMBER, in_ship NUMBER) IS
SELECT
OH.CUSTID custid,
OH.ORDERID orderid,
OH.SHIPID shipid,
OH.WAVE wave,
OH.WAVE loadno,
UPPER(OH.CUSTID) shipunitdomain,
UPPER(OH.ORDERID||'-'||OH.SHIPID||'-'||LPAD(ROWNUM,3,'0')) shipunit,
UPPER(OD.UOMENTERED) shipunitspec,
UPPER(OD.FROMFACILITY) shipfromlocation,
UPPER(NVL(OH.SHIPTO,SUBSTR(OH.SHIPTONAME,1,3)||SUBSTR(OH.SHIPTOADDR1,1,2)||SUBSTR(OH.SHIPTOPOSTALCODE,1,5))) shiptolocation,
UPPER(OH.SHIPTONAME) shiptolocationname,
UPPER(OH.SHIPTOADDR1) shiptolocationaddrline1,
UPPER(OH.SHIPTOADDR2) shiptolocationaddrline2,
UPPER(OH.SHIPTOCITY) shiptolocationcity,
UPPER(OH.SHIPTOSTATE) shiptolocationprovince,
UPPER(OH.SHIPTOPOSTALCODE) shiptolocationpostalcode,
UPPER(OH.SHIPTOCOUNTRYCODE) shiptolocationcountrycode,
TO_CHAR(OH.APPTDATE,'YYYYMMDDHH24MISS') earlypickupdate,
TO_CHAR(OH.APPTDATE,'YYYYMMDDHH24MISS') latepickupdate,
TO_CHAR(OH.ARRIVALDATE,'YYYYMMDDHH24MISS') earlydeliverydate,
TO_CHAR(OH.ARRIVALDATE,'YYYYMMDDHH24MISS') latedeliverydate,
ROUND(ZCI.ITEM_WEIGHT(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) shipunitweightvalue,
ROUND(ZCI.ITEM_CUBE(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) shipunitvolumevalue,
ROUND(ZCI.ITEM_WEIGHT(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) shipunitnetweightvalue,
ROUND(ZCI.ITEM_CUBE(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) shipunitnetvolumevalue,
' ' shipunitlengthvalue,
' ' shipunitwidthvalue,
' ' shipunitheightvalue,
UPPER(OH.CUSTID) packageditemrefdomain,
UPPER(OD.ITEM) packageditemref,
UPPER(OH.CUSTID) packageditemdomain,
UPPER(OD.ITEM) packageditem,
UPPER(CI.DESCR) packagedescription,
ROUND(ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED)*ZCI.ITEM_WEIGHT(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) packageshipunitweightval,
ROUND(ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED)*ZCI.ITEM_CUBE(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) packageshipunitvolumeval,
UPPER(OH.CUSTID) itemdomain,
UPPER(CI.ITEM) item,
UPPER(CI.ABBREV) itemname,
UPPER(CI.DESCR) itemdescription,
UPPER(NCC.ABBREV) commodity,
UPPER(CI.NMFC) nmfcarticle,
UPPER(NCC.CLASS) nmfcclass,
UPPER(CIA.ALIASDESC) itemrefnumqualifier,
UPPER(CIA.ITEMALIAS) itemrefnumvalue,
ROWNUM linenumber,
ROUND(ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED)*ZCI.ITEM_WEIGHT(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) itemweightvalue,
ROUND(ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED)*ZCI.ITEM_CUBE(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) itemvolumevalue,
ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED) packageditemcount,
UPPER(OD.UOMENTERED) packageditemspec,
ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED) packageditemspeccount,
ROUND(ZCI.ITEM_WEIGHT(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) weightpershipunitvalue,
ROUND(ZCI.ITEM_CUBE(OH.CUSTID,OD.ITEM,OD.UOMENTERED),5) volumepershipunitvalue,
ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED) shipunitcount,
ZCU.EQUIV_UOM_QTY(OH.CUSTID,OD.ITEM,OD.UOM,OD.QTYCOMMIT,OD.UOMENTERED) releasecount,
UPPER(OH.CUSTID) statustypedomain,
UPPER(OH.CUSTID) statusvaluedomain
FROM ORDERHDR OH,
     ORDERDTL OD,
     CUSTITEM CI,
     NMFCLASSCODES NCC,
     CUSTITEMALIAS CIA
WHERE OH.ORDERID = OD.ORDERID
AND OH.SHIPID = OD.SHIPID
AND OH.CUSTID = OD.CUSTID
AND OD.CUSTID = CI.CUSTID
AND OD.ITEM = CI.ITEM
AND CI.NMFC = NCC.NMFC(+)
AND CI.CUSTID = CIA.CUSTID(+)
AND CI.ITEM = CIA.ITEM(+)
AND OD.QTYCOMMIT<>0
AND OD.LINESTATUS<>'X'
AND in_custid IN (OH.CUSTID, 'ALL')
AND OH.ORDERID = in_order
AND OH.SHIPID = in_ship;
csu curShipUnits%rowtype;


curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strDebugYN char(1);

strSuffix varchar2(32);
viewcount integer;

l_condition varchar2(200);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

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
   where view_name = 'TMS_TRANSORDER_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_loadno != 0 then
     l_condition := ' AND OH.WAVE = '||to_char(in_loadno)
                 || ' ';
  elsif in_orderid != 0 then
     l_condition := ' AND OH.ORDERID = '||to_char(in_orderid)
                 || ' AND OH.SHIPID = '||to_char(in_shipid)
                 || ' ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  if in_custid <> 'ALL' then
    cu := null;
    open curCustomer;
    fetch curCustomer into cu;
    close curCustomer;
    if cu.custid is null then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;

    l_condition := l_condition || ' AND OH.CUSTID = '''||in_custid||'''';
  end if;

  debugmsg('Condition = '||l_condition);

  -- Create header view
cmdSql := 'CREATE VIEW ALPS.TMS_TRANSORDER_DTL_' || strSuffix ||
  ' (CUSTID,ORDERID,SHIPID,WAVE,LOADNO,TRANSORDERDOMAIN,TRANSORDER,CONTACT,CONTACTEMAILADDRESS,' ||
  'INVOLVEDPARTY2LOCATION,CONTACT2,INVOLVEDPARTY3LOCATION,CONTACT3,PAYMETHODCODE,PLANNINGGROUP,' ||
  'ORDERTYPE,SERVICEPROVIDERDOMAIN,SERVICEPROVIDER,ORDERREFNUM1VALUE,ORDERREFNUM3VALUE,' ||
  'ORDERREFNUM4VALUE,ORDERREFNUM5VALUE,ORDERREFNUM6QUALIFIER,ORDERREFNUM6VALUE,ORDERREFNUM7QUALIFIER,' ||
  'ORDERREFNUM7VALUE,REMARKTEXT,BATCHBALANCEORDERTYPE,BATCHBALANCESCHEDULE,SPECIALSERVICE,' ||
  'SPECIALSERVICEDESC,ACCESSORIALCODE,TOTALNETWEIGHTVALUE,TOTALNETVOLUMEVALUE,ORDERREFNUM8VALUE, ' ||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02) '||

  'AS SELECT ' ||
  'OH.CUSTID,OH.ORDERID,OH.SHIPID,OH.WAVE,OH.WAVE,UPPER(OH.CUSTID),UPPER(OH.ORDERID||''-''||OH.SHIPID),' ||
  'UPPER(OH.FROMFACILITY),'' '','' '',UPPER(OH.FROMFACILITY),UPPER(OH.CONSIGNEE),UPPER(OH.FROMFACILITY),' ||
  'UPPER(OH.SHIPTERMS),UPPER(OH.CUSTID),UPPER(OH.FROMFACILITY),' ||
  'CASE WHEN OH.CARRIER IS NULL THEN '' '' ELSE ''OHL'' END,' ||
  'UPPER(C.SCAC),UPPER(OH.PRIORITY),UPPER(OH.CUSTID),UPPER(OH.PO),UPPER(OH.REFERENCE),'' '','' '',' ||
  ''' '','' '',OH.COMMENT1,'' '','' '','' '','' '','' '',ROUND(OH.WEIGHTCOMMIT,5),' ||
  'ROUND(OH.CUBECOMMIT,5),OH.HDRPASSTHRUCHAR03, ' ||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02 '||
  'FROM ORDERHDR OH,CARRIER C ' ||
  'WHERE OH.CARRIER = C.CARRIER ' ||
  'AND EXISTS(SELECT 1 ' ||
  'FROM ORDERDTL OD ' ||
  'WHERE OH.ORDERID=OD.ORDERID ' ||
  'AND OH.SHIPID=OD.SHIPID ' ||
  'AND OH.CUSTID=OD.CUSTID ' ||
  'AND OD.QTYCOMMIT<>0 ' ||
  'AND OD.LINESTATUS<>''X'') ' ||
  l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create table TMS_TRANSORDER_SU_' || strSuffix);
cmdSql := 'create table TMS_TRANSORDER_SU_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,' ||
' WAVE NUMBER(9),LOADNO NUMBER(9),SHIPUNITDOMAIN VARCHAR2(10),SHIPUNIT VARCHAR2(85),' ||
' SHIPUNITSPEC VARCHAR2(4),SHIPFROMLOCATION VARCHAR2(3),SHIPTOLOCATION VARCHAR2(10),' ||
' SHIPTOLOCATIONNAME VARCHAR2(40),SHIPTOLOCATIONADDRLINE1 VARCHAR2(40),' ||
' SHIPTOLOCATIONADDRLINE2 VARCHAR2(40),SHIPTOLOCATIONCITY VARCHAR2(30),' ||
' SHIPTOLOCATIONPROVINCE VARCHAR2(2),SHIPTOLOCATIONPOSTALCODE VARCHAR2(12),' ||
' SHIPTOLOCATIONCOUNTRYCODE VARCHAR2(3),EARLYPICKUPDATE VARCHAR2(14),' ||
' LATEPICKUPDATE VARCHAR2(14),EARLYDELIVERYDATE VARCHAR2(14),LATEDELIVERYDATE VARCHAR2(14),' ||
' SHIPUNITWEIGHTVALUE NUMBER,SHIPUNITVOLUMEVALUE NUMBER,SHIPUNITNETWEIGHTVALUE NUMBER,' ||
' SHIPUNITNETVOLUMEVALUE NUMBER,SHIPUNITLENGTHVALUE CHAR(1),SHIPUNITWIDTHVALUE CHAR(1),' ||
' SHIPUNITHEIGHTVALUE CHAR(1),PACKAGEDITEMREFDOMAIN VARCHAR2(10),PACKAGEDITEMREF VARCHAR2(20),' ||
' PACKAGEDITEMDOMAIN VARCHAR2(10),PACKAGEDitem varchar2(50),PACKAGEDESCRIPTION VARCHAR2(40),' ||
' PACKAGESHIPUNITWEIGHTVAL NUMBER,PACKAGESHIPUNITVOLUMEVAL NUMBER,' ||
' ITEMDOMAIN VARCHAR2(10),item varchar2(50),ITEMNAME VARCHAR2(12),' ||
' ITEMDESCRIPTION VARCHAR2(255),COMMODITY VARCHAR2(12),NMFCARTICLE VARCHAR2(12),' ||
' NMFCCLASS VARCHAR2(40),ITEMREFNUMQUALIFIER VARCHAR2(32),ITEMREFNUMVALUE VARCHAR2(20),' ||
' LINENUMBER NUMBER,ITEMWEIGHTVALUE NUMBER,ITEMVOLUMEVALUE NUMBER,' ||
' PACKAGEDITEMCOUNT NUMBER,PACKAGEDITEMSPEC VARCHAR2(4),PACKAGEDITEMSPECCOUNT NUMBER,' ||
' WEIGHTPERSHIPUNITVALUE NUMBER,VOLUMEPERSHIPUNITVALUE NUMBER,SHIPUNITCOUNT NUMBER,' ||
' RELEASECOUNT NUMBER,STATUSTYPEDOMAIN VARCHAR2(10),STATUSVALUEDOMAIN VARCHAR2(10))';
execute immediate cmdSql;

IF in_loadno != 0 THEN
   for co in curOrders
   LOOP
      for csu in curShipUnits(co.orderid,co.shipid)
      LOOP
         execute immediate 'insert into TMS_TRANSORDER_SU_' || strSuffix ||
         ' values (:CUSTID,:ORDERID,:SHIPID,:WAVE,:LOADNO,:SHIPUNITDOMAIN,:SHIPUNIT,' ||
         ' :SHIPUNITSPEC,:SHIPFROMLOCATION,:SHIPTOLOCATION,:SHIPTOLOCATIONNAME,' ||
         ' :SHIPTOLOCATIONADDRLINE1,:SHIPTOLOCATIONADDRLINE2,:SHIPTOLOCATIONCITY,' ||
         ' :SHIPTOLOCATIONPROVINCE,:SHIPTOLOCATIONPOSTALCODE,:SHIPTOLOCATIONCOUNTRYCODE,' ||
         ' :EARLYPICKUPDATE,:LATEPICKUPDATE,:EARLYDELIVERYDATE,:LATEDELIVERYDATE,' ||
         ' :SHIPUNITWEIGHTVALUE,:SHIPUNITVOLUMEVALUE,:SHIPUNITNETWEIGHTVALUE,' ||
         ' :SHIPUNITNETVOLUMEVALUE,:SHIPUNITLENGTHVALUE,:SHIPUNITWIDTHVALUE,' ||
         ' :SHIPUNITHEIGHTVALUE,:PACKAGEDITEMREFDOMAIN,:PACKAGEDITEMREF,:PACKAGEDITEMDOMAIN,' ||
         ' :PACKAGEDITEM,:PACKAGEDESCRIPTION,:PACKAGESHIPUNITWEIGHTVAL,:PACKAGESHIPUNITVOLUMEVAL,' ||
         ' :ITEMDOMAIN,:ITEM,:ITEMNAME,:ITEMDESCRIPTION,:COMMODITY,:NMFCARTICLE,' ||
         ' :NMFCCLASS,:ITEMREFNUMQUALIFIER,:ITEMREFNUMVALUE,:LINENUMBER,:ITEMWEIGHTVALUE,' ||
         ' :ITEMVOLUMEVALUE,:PACKAGEDITEMCOUNT,:PACKAGEDITEMSPEC,:PACKAGEDITEMSPECCOUNT,' ||
         ' :WEIGHTPERSHIPUNITVALUE,:VOLUMEPERSHIPUNITVALUE,:SHIPUNITCOUNT,:RELEASECOUNT,' ||
         ' :STATUSTYPEDOMAIN,:STATUSVALUEDOMAIN )'
         using csu.CUSTID,csu.ORDERID,csu.SHIPID,csu.WAVE,csu.LOADNO,csu.SHIPUNITDOMAIN,
         csu.SHIPUNIT,csu.SHIPUNITSPEC,csu.SHIPFROMLOCATION,csu.SHIPTOLOCATION,
         csu.SHIPTOLOCATIONNAME,csu.SHIPTOLOCATIONADDRLINE1,csu.SHIPTOLOCATIONADDRLINE2,
         csu.SHIPTOLOCATIONCITY,csu.SHIPTOLOCATIONPROVINCE,csu.SHIPTOLOCATIONPOSTALCODE,
         csu.SHIPTOLOCATIONCOUNTRYCODE,csu.EARLYPICKUPDATE,csu.LATEPICKUPDATE,
         csu.EARLYDELIVERYDATE,csu.LATEDELIVERYDATE,csu.SHIPUNITWEIGHTVALUE,csu.SHIPUNITVOLUMEVALUE,
         csu.SHIPUNITNETWEIGHTVALUE,csu.SHIPUNITNETVOLUMEVALUE,csu.SHIPUNITLENGTHVALUE,
         csu.SHIPUNITWIDTHVALUE,csu.SHIPUNITHEIGHTVALUE,csu.PACKAGEDITEMREFDOMAIN,
         csu.PACKAGEDITEMREF,csu.PACKAGEDITEMDOMAIN,csu.PACKAGEDITEM,csu.PACKAGEDESCRIPTION,
         csu.PACKAGESHIPUNITWEIGHTVAL,csu.PACKAGESHIPUNITVOLUMEVAL,csu.ITEMDOMAIN,
         csu.ITEM,csu.ITEMNAME,csu.ITEMDESCRIPTION,csu.COMMODITY,csu.NMFCARTICLE,
         csu.NMFCCLASS,csu.ITEMREFNUMQUALIFIER,csu.ITEMREFNUMVALUE,csu.LINENUMBER,
         csu.ITEMWEIGHTVALUE,csu.ITEMVOLUMEVALUE,csu.PACKAGEDITEMCOUNT,csu.PACKAGEDITEMSPEC,
         csu.PACKAGEDITEMSPECCOUNT,csu.WEIGHTPERSHIPUNITVALUE,csu.VOLUMEPERSHIPUNITVALUE,
         csu.SHIPUNITCOUNT,csu.RELEASECOUNT,csu.STATUSTYPEDOMAIN,csu.STATUSVALUEDOMAIN;
      END LOOP;
   END LOOP;
ELSE
   for csu in curShipUnits(in_orderid,in_shipid)
   LOOP
      execute immediate 'insert into TMS_TRANSORDER_SU_' || strSuffix ||
      ' values (:CUSTID,:ORDERID,:SHIPID,:WAVE,:LOADNO,:SHIPUNITDOMAIN,:SHIPUNIT,' ||
      ' :SHIPUNITSPEC,:SHIPFROMLOCATION,:SHIPTOLOCATION,:SHIPTOLOCATIONNAME,' ||
      ' :SHIPTOLOCATIONADDRLINE1,:SHIPTOLOCATIONADDRLINE2,:SHIPTOLOCATIONCITY,' ||
      ' :SHIPTOLOCATIONPROVINCE,:SHIPTOLOCATIONPOSTALCODE,:SHIPTOLOCATIONCOUNTRYCODE,' ||
      ' :EARLYPICKUPDATE,:LATEPICKUPDATE,:EARLYDELIVERYDATE,:LATEDELIVERYDATE,' ||
      ' :SHIPUNITWEIGHTVALUE,:SHIPUNITVOLUMEVALUE,:SHIPUNITNETWEIGHTVALUE,' ||
      ' :SHIPUNITNETVOLUMEVALUE,:SHIPUNITLENGTHVALUE,:SHIPUNITWIDTHVALUE,' ||
      ' :SHIPUNITHEIGHTVALUE,:PACKAGEDITEMREFDOMAIN,:PACKAGEDITEMREF,:PACKAGEDITEMDOMAIN,' ||
      ' :PACKAGEDITEM,:PACKAGEDESCRIPTION,:PACKAGESHIPUNITWEIGHTVAL,:PACKAGESHIPUNITVOLUMEVAL,' ||
      ' :ITEMDOMAIN,:ITEM,:ITEMNAME,:ITEMDESCRIPTION,:COMMODITY,:NMFCARTICLE,' ||
      ' :NMFCCLASS,:ITEMREFNUMQUALIFIER,:ITEMREFNUMVALUE,:LINENUMBER,:ITEMWEIGHTVALUE,' ||
      ' :ITEMVOLUMEVALUE,:PACKAGEDITEMCOUNT,:PACKAGEDITEMSPEC,:PACKAGEDITEMSPECCOUNT,' ||
      ' :WEIGHTPERSHIPUNITVALUE,:VOLUMEPERSHIPUNITVALUE,:SHIPUNITCOUNT,:RELEASECOUNT,' ||
      ' :STATUSTYPEDOMAIN,:STATUSVALUEDOMAIN )'
      using csu.CUSTID,csu.ORDERID,csu.SHIPID,csu.WAVE,csu.LOADNO,csu.SHIPUNITDOMAIN,
      csu.SHIPUNIT,csu.SHIPUNITSPEC,csu.SHIPFROMLOCATION,csu.SHIPTOLOCATION,
      csu.SHIPTOLOCATIONNAME,csu.SHIPTOLOCATIONADDRLINE1,csu.SHIPTOLOCATIONADDRLINE2,
      csu.SHIPTOLOCATIONCITY,csu.SHIPTOLOCATIONPROVINCE,csu.SHIPTOLOCATIONPOSTALCODE,
      csu.SHIPTOLOCATIONCOUNTRYCODE,csu.EARLYPICKUPDATE,csu.LATEPICKUPDATE,
      csu.EARLYDELIVERYDATE,csu.LATEDELIVERYDATE,csu.SHIPUNITWEIGHTVALUE,csu.SHIPUNITVOLUMEVALUE,
      csu.SHIPUNITNETWEIGHTVALUE,csu.SHIPUNITNETVOLUMEVALUE,csu.SHIPUNITLENGTHVALUE,
      csu.SHIPUNITWIDTHVALUE,csu.SHIPUNITHEIGHTVALUE,csu.PACKAGEDITEMREFDOMAIN,
      csu.PACKAGEDITEMREF,csu.PACKAGEDITEMDOMAIN,csu.PACKAGEDITEM,csu.PACKAGEDESCRIPTION,
      csu.PACKAGESHIPUNITWEIGHTVAL,csu.PACKAGESHIPUNITVOLUMEVAL,csu.ITEMDOMAIN,
      csu.ITEM,csu.ITEMNAME,csu.ITEMDESCRIPTION,csu.COMMODITY,csu.NMFCARTICLE,
      csu.NMFCCLASS,csu.ITEMREFNUMQUALIFIER,csu.ITEMREFNUMVALUE,csu.LINENUMBER,
      csu.ITEMWEIGHTVALUE,csu.ITEMVOLUMEVALUE,csu.PACKAGEDITEMCOUNT,csu.PACKAGEDITEMSPEC,
      csu.PACKAGEDITEMSPECCOUNT,csu.WEIGHTPERSHIPUNITVALUE,csu.VOLUMEPERSHIPUNITVALUE,
      csu.SHIPUNITCOUNT,csu.RELEASECOUNT,csu.STATUSTYPEDOMAIN,csu.STATUSVALUEDOMAIN;
   END LOOP;
END IF;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end begin_transynd_transorder;


procedure end_transynd_transorder
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'DROP TABLE TMS_TRANSORDER_SU_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'DROP VIEW TMS_TRANSORDER_DTL_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end end_transynd_transorder;

procedure update_tms_status
(in_custid IN varchar2
,in_transorder IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

order_id integer;
ship_id integer;

begin

select nvl(to_number(substr(in_transorder,1,instr(in_transorder,'-',1,1)-1)),0),
       nvl(to_number(substr(in_transorder,instr(in_transorder,'-',1,1)+1)),0)
into order_id, ship_id
from dual;

out_msg := '';
out_errorno := 0;

update orderhdr
   set tms_status = 2,
       tms_status_update = sysdate
 where custid = in_custid
   and orderid = order_id
   and shipid = ship_id
   and tms_status not in ('4','X');

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zimtms ' || sqlerrm;
  out_errorno := sqlcode;
end update_tms_status;

procedure import_sterling_load
(in_shipmentid in varchar2
,in_scac in varchar2
,in_custid in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,out_errorno in out number
,out_msg in out varchar2
)
is

cursor curCarrier is
  select carrier
    from carrier
   where scac = in_scac;
ca curCarrier%rowtype;

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curShipmentTypes is
  select code
    from shipmenttypes
   where code = in_shiptype;
cstp curShipmentTypes%rowtype;

cursor curShipmentTerms is
  select code
    from shipmentterms
   where code = in_shipterms;
cstm curShipmentTerms%rowtype;

begin

out_errorno := 0;
out_msg := 'OKAY';

if trim(in_shipmentid) = '' then
  out_errorno := 1;
  out_msg := 'Invalid Shipment ID: ' || in_shipmentid;
  goto continue_load;
end if;

ca := null;
open curCarrier;
fetch curCarrier into ca;
close curCarrier;
if ca.carrier is null then
  out_errorno := 2;
  out_msg := 'Invalid SCAC: ' || in_scac;
  goto continue_load;
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := 3;
  out_msg := 'Invalid Customer Code: ' || in_custid;
  goto continue_load;
end if;

cstp := null;
open curShipmentTypes;
fetch curShipmentTypes into cstp;
close curShipmentTypes;
if cstp.code is null then
  out_errorno := 4;
  out_msg := 'Invalid Shipment Type: ' || in_shiptype;
  goto continue_load;
end if;

cstm := null;
open curShipmentTerms;
fetch curShipmentTerms into cstm;
close curShipmentTerms;
if cstm.code is null then
  out_errorno := 5;
  out_msg := 'Invalid Shipment Terms: ' || in_shipterms;
  goto continue_load;
end if;

<<continue_load>>
if (out_errorno <> 0) then
  zms.log_autonomous_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
end if;

exception when others then
  rollback;
  out_msg := substr('zimtmssl ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_sterling_load;

procedure import_sterling_stop
(in_shipmentid in varchar2
,in_scac in varchar2
,in_custid in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,in_stopno in number
,in_do_not_deliver_before varchar2
,in_do_not_deliver_after varchar2
,out_errorno in out number
,out_msg in out varchar2
)
is

cursor curCarrier is
  select carrier
    from carrier
   where scac = in_scac;
ca curCarrier%rowtype;

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curShipmentTypes is
  select code
    from shipmenttypes
   where code = in_shiptype;
cstp curShipmentTypes%rowtype;

cursor curShipmentTerms is
  select code
    from shipmentterms
   where code = in_shipterms;
cstm curShipmentTerms%rowtype;

begin

out_errorno := 0;
out_msg := 'OKAY';

if trim(in_shipmentid) = '' then
  out_errorno := 1;
  out_msg := 'Invalid Shipment ID';
  goto continue_stop;
end if;

ca := null;
open curCarrier;
fetch curCarrier into ca;
close curCarrier;
if ca.carrier is null then
  out_errorno := 2;
  out_msg := 'Invalid SCAC: ' || in_scac;
  goto continue_stop;
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := 3;
  out_msg := 'Invalid Customer Code: ' || in_custid;
  goto continue_stop;
end if;

cstp := null;
open curShipmentTypes;
fetch curShipmentTypes into cstp;
close curShipmentTypes;
if cstp.code is null then
  out_errorno := 4;
  out_msg := 'Invalid Shipment Type: ' || in_shiptype;
  goto continue_stop;
end if;

cstm := null;
open curShipmentTerms;
fetch curShipmentTerms into cstm;
close curShipmentTerms;
if cstm.code is null then
  out_errorno := 5;
  out_msg := 'Invalid Shipment Terms: ' || in_shipterms;
  goto continue_stop;
end if;

if nvl(in_stopno,0) <= 0 then
  out_errorno := 6;
  out_msg := 'Invalid Stop Number: ' || in_stopno;
  goto continue_stop;
end if;

<<continue_stop>>
if (out_errorno <> 0) then
  zms.log_autonomous_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
end if;

exception when others then
  rollback;
  out_msg := substr('zimtmsss ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_sterling_stop;

procedure import_sterling_order
(in_shipmentid in varchar2
,in_scac in varchar2
,in_custid in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,in_stopno in number
,in_do_not_deliver_before date
,in_do_not_deliver_after date
,in_reference varchar2
,in_importfileid IN varchar2
,out_errorno in out number
,out_msg in out varchar2
)
is

cursor curCarrier is
  select carrier
    from carrier
   where scac = in_scac;
ca curCarrier%rowtype;

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curShipmentTypes is
  select code
    from shipmenttypes
   where code = in_shiptype;
cstp curShipmentTypes%rowtype;

cursor curShipmentTerms is
  select code
    from shipmentterms
   where code = in_shipterms;
cstm curShipmentTerms%rowtype;

cursor curOrderHdr is
  select orderid,shipid,fromfacility,custid,orderstatus,ordertype
    from orderhdr
   where reference = in_reference
     and custid = in_custid
     and ordertype not in ('R', 'Q', 'P', 'A', 'C', 'I');
oh curOrderHdr%rowtype;

cursor curLoad(in_carrier varchar2) is
  select loadno
    from loads
   where recent_loadno is not null
     and carrier = in_carrier
     and billoflading = in_shipmentid
   order by loadno desc;
ld curLoad%rowtype;

cursor curLoadStop(in_loadno number, in_stopno number) is
  select stopno
    from loadstop
   where loadno = in_loadno
     and stopno = in_stopno;
ls curLoadStop%rowtype;

cursor curLoadStopShip(in_loadno number, in_stopno number) is
  select shipno
    from loadstopship
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = 1;
lss curLoadStopShip%rowtype;

l_loadno number;
l_stopno number;

begin

out_errorno := 0;
out_msg := 'OKAY';

if trim(in_shipmentid) = '' then
  out_errorno := 1;
  out_msg := 'Invalid Shipment ID';
  goto continue_order;
end if;

ca := null;
open curCarrier;
fetch curCarrier into ca;
close curCarrier;
if ca.carrier is null then
  out_errorno := 2;
  out_msg := 'Invalid SCAC: ' || in_scac;
  goto continue_order;
end if;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := 3;
  out_msg := 'Invalid Customer Code: ' || in_custid;
  goto continue_order;
end if;

cstp := null;
open curShipmentTypes;
fetch curShipmentTypes into cstp;
close curShipmentTypes;
if cstp.code is null then
  out_errorno := 4;
  out_msg := 'Invalid Shipment Type: ' || in_shiptype;
  goto continue_order;
end if;

cstm := null;
open curShipmentTerms;
fetch curShipmentTerms into cstm;
close curShipmentTerms;
if cstm.code is null then
  out_errorno := 5;
  out_msg := 'Invalid Shipment Terms: ' || in_shipterms;
  goto continue_order;
end if;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderstatus is null then
  out_errorno := 6;
  out_msg := 'Invalid Outbound Order Reference: ' || in_reference;
  goto continue_order;
end if;

for oh in curOrderHdr loop
  if oh.orderstatus in ('0','1','2','3','4','5') then
    update orderhdr
       set billoflading = in_shipmentid,
           carrier = ca.carrier,
           shiptype = in_shiptype,
           shipterms = in_shipterms,
           loadno = null,
           stopno = null,
           shipno = null,
           do_not_deliver_before = nvl(in_do_not_deliver_before,do_not_deliver_before),
           do_not_deliver_after = nvl(in_do_not_deliver_after,do_not_deliver_after),
           lastuser = 'IMPEXP',
           lastupdate = sysdate
     where orderid = oh.orderid
       and shipid = oh.shipid;
       
    if (in_shiptype in ('T','P','R')) then
      if (oh.orderstatus <> '0') then
        l_stopno := in_stopno - 1;
  
        if (in_stopno >= 1) then
          ld := null;
          open curLoad(ca.carrier);
          fetch curLoad into ld;
          close curLoad;
    
          if (ld.loadno is null) then
            if (l_stopno > 1) then
              out_errorno := 7;
              out_msg := 'Unable to find load: ' || in_shipmentid;
              goto continue_order;
            else
              zld.get_next_loadno(l_loadno,out_msg);
              if substr(out_msg,1,4) != 'OKAY' then
                out_errorno := 8;
                out_msg := 'Unable to create load';
                goto continue_order;
              end if;
              
            	insert into loads
             	(loadno, entrydate, loadstatus, facility,
                 carrier, statususer, statusupdate,
                 lastuser, lastupdate, billoflading, loadtype)
            	values
             	(l_loadno, sysdate, '2', oh.fromfacility,
              	 ca.carrier, 'IMPEXP', sysdate,
              	 'IMPEXP', sysdate, in_shipmentid,
                 decode(oh.ordertype, 'T', 'OUTT', 'U', 'OUTT', 'OUTC'));
            end if;
          else
            l_loadno := ld.loadno;
          end if;
            
          ls := null;
          open curLoadStop(l_loadno,l_stopno);
          fetch curLoadStop into ls;
          close curLoadStop;
    
          if (ls.stopno is null) then
          	insert into loadstop
           	(loadno, stopno, entrydate, loadstopstatus,
               statususer, statusupdate, lastuser, lastupdate, facility)
          	values
           	(l_loadno, l_stopno, sysdate, '2',
               'IMPEXP', sysdate, 'IMPEXP', sysdate, oh.fromfacility);
          end if;
            
          lss := null;
          open curLoadStopShip(l_loadno,l_stopno);
          fetch curLoadStopShip into lss;
          close curLoadStopShip;
    
          if (lss.shipno is null) then
          	insert into loadstopship
           	(loadno, stopno, shipno, entrydate,
               qtyorder, weightorder, cubeorder, amtorder,
               qtyship, weightship, cubeship, amtship,
               qtyrcvd, weightrcvd, cubercvd, amtrcvd,
               lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
          	values
           	(l_loadno, l_stopno, 1, sysdate,
               0, 0, 0, 0,
               0, 0, 0, 0,
               0, 0, 0, 0,
               'IMPEXP', sysdate, 0, 0);
          end if;
    
          update orderhdr
             set billoflading = in_shipmentid||decode(l_stopno,1,'','-'||to_char(l_stopno)),
                 loadno = l_loadno,
                 stopno = l_stopno,
                 shipno = 1,
                 lastuser = 'IMPEXP',
                 lastupdate = sysdate
           where orderid = oh.orderid
             and shipid = oh.shipid;
    
          update shippingplate
             set loadno = l_loadno,
                 stopno = l_stopno,
                 shipno = 1,
                 lastuser = 'IMPEXP',
                 lastupdate = sysdate
           where orderid = oh.orderid
             and shipid = oh.shipid;
    
          if (l_stopno > 1) then
            update orderhdr
               set billoflading = in_shipmentid||'-1',
                   lastuser = 'IMPEXP',
                   lastupdate = sysdate
             where loadno = l_loadno
               and stopno = 1
               and shipno = 1
               and billoflading = in_shipmentid;
          end if;
        end if;
  
        zoh.add_orderhistory(oh.orderid, oh.shipid,
          'Order To Load',
          'Order Assigned to Load '||l_loadno||'/'||l_stopno||'/'||1,
          'IMPEXP',strMsg);
      else
        zms.log_autonomous_msg('TMSPLAN', null, null,
          'Order '||oh.orderid||'-'||oh.shipid||' status On Hold. Unable to assign load',
          'W', 'TMSPLAN', strMsg);
      end if;
    end if;

    zoh.add_orderhistory(oh.orderid, oh.shipid,
      '204 Update',
      '204 Update '||in_importfileid,
      'IMPEXP',strMsg);
  else 
    out_errorno := 9;
    out_msg := 'Order '||oh.orderid||'-'||oh.shipid||' invalid status for update: ' || oh.orderstatus;
    goto continue_order;
  end if;
end loop;

<<continue_order>>
if (out_errorno <> 0) then
  zms.log_autonomous_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
else
  zms.log_autonomous_msg('TMSPLAN', null, null,
    '204 Import successful: '||in_importfileid,
    'I', 'TMSPLAN', strMsg);
end if;

exception when others then
  rollback;
  out_msg := substr('zimtmsso ' || sqlerrm,1,255);
  out_errorno := sqlcode;
  zms.log_msg('TMSPLAN', null, null,
    out_msg,
    'E', 'TMSPLAN', strMsg);
  commit;
end import_sterling_order;

end zimportproctrans;

/
show error package body zimportproctrans;
exit;
