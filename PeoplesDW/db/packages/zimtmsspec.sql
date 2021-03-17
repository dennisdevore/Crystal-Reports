--
-- $Id$
--
CREATE OR REPLACE PACKAGE ALPS.zimportproctrans

IS

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

procedure import_planship_tail
(in_func in out varchar2
,in_record_type in varchar2
,in_sendertransmissionno in number
,out_orderid in out number
,out_shipid in out number
,out_errorno in out number
,out_msg in out varchar2
);

procedure process_planship
(in_userid in varchar2
,out_errorno in out NUMBER
,out_msg in out varchar2
);

procedure begin_transynd_actualshipment
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_transynd_actualshipment
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_transynd_item
(in_custid IN varchar2
,in_item IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_transynd_item
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_transynd_orderrelease
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_orderstatus_values IN varchar2
,in_ordertype_values IN varchar2
,in_exclude_impexp IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_transynd_orderrelease
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_transynd_shipeventstatus
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_transynd_shipeventstatus
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure begin_transynd_transorder
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_transynd_transorder
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure update_tms_status
(in_custid IN varchar2
,in_transorder IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure import_sterling_load
(in_shipmentid in varchar2
,in_scac in varchar2
,in_custid in varchar2
,in_shiptype in varchar2
,in_shipterms in varchar2
,out_errorno in out number
,out_msg in out varchar2
);

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
);

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
);

end zimportproctrans;
/
show error package zimportproctrans;
exit;
