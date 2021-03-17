--
-- $Id$
--
create unique index alps.activity_unique
    on alps.activity(code)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.activityminimumcategory_idx
    on alps.activityminimumcategory(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.adjustmentreasons_idx
    on alps.adjustmentreasons(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.aisle_unique
    on alps.aisle(facility,aisleid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.allocrulesdtl_unique
    on alps.allocrulesdtl(facility,allocrule,priority)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.allocruleshdr_unique
    on alps.allocruleshdr(facility,allocrule)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.applocks_unique
    on alps.applocks(lockid)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.appmsgs_author
    on alps.appmsgs(author,created)
pctfree 20
tablespace synapse_act_index
/

create index alps.appmsgs_created
    on alps.appmsgs(created)
pctfree 20
tablespace synapse_act_index
/

create index alps.appmsgs_status_idx
    on alps.appmsgs(status)
pctfree 10
tablespace synapse_act_index
/

create index alps.app_msgs_contacts_author
    on alps.app_msgs_contacts(author,msgtype)
pctfree 10
tablespace synapse_act_index
/

create index alps.asncartondtl_created_idx
    on alps.asncartondtl(created)
pctfree 20
tablespace synapse_inv_index
/

create index alps.asncartondtl_custreference_idx
    on alps.asncartondtl(custreference)
pctfree 20
tablespace synapse_inv_index
/

create index alps.asncartondtl_order_idx
    on alps.asncartondtl(orderid,shipid,item,lotnumber,serialnumber,useritem1,useritem2,useritem3,trackingno,custreference,qty)
pctfree 10
tablespace synapse_inv_index
/

create index alps.asncartondtl_trackingno_idx
    on alps.asncartondtl(trackingno)
pctfree 20
tablespace synapse_inv_index
/

create unique index alps.asofinventory_index
    on alps.asofinventory(facility,custid,item,lotnumber,uom,effdate,inventoryclass,invstatus)
pctfree 20
tablespace synapse_inv_index
/

create index alps.asofinventory_item_idx
    on alps.asofinventory(facility,custid,item,effdate)
pctfree 10
tablespace synapse_inv_index
/

create index alps.asofinventorydtl_index
    on alps.asofinventorydtl(facility,custid,item,lotnumber,uom,effdate,inventoryclass,invstatus)
pctfree 20
tablespace synapse_inv_index
/

create index alps.asofinventorydtl_item_idx
    on alps.asofinventorydtl(facility,custid,item,effdate)
pctfree 10
tablespace synapse_inv_index
/

create unique index alps.autopromptvalues_idx
    on alps.autopromptvalues(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.backorderpolicy_idx
    on alps.backorderpolicy(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.backoutaccessorial_idx
    on alps.backoutaccessorial(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.backoutmisc_idx
    on alps.backoutmisc(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.backoutreceipt_idx
    on alps.backoutreceipt(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.backoutrenewal_idx
    on alps.backoutrenewal(code)
pctfree 10
tablespace synapse_temp_index
/

create index alps.batchtasks_order_idx
    on alps.batchtasks(orderid,shipid)
pctfree 10
tablespace synapse_lod_index
/

create index alps.batchtasks_taskid_idx
    on alps.batchtasks(taskid)
pctfree 10
tablespace synapse_lod_index
/

create index alps.batchtasks_wave_idx
    on alps.batchtasks(wave)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.billbylocationactivity_idx
    on alps.billbylocationactivity(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.billingmethod_idx
    on alps.billingmethod(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.billpalletcnt_pk_idx
    on alps.billpalletcnt(facility,custid,effdate,item,lotnumber)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.billstatus_idx
    on alps.billstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index bill_lot_renewal_idx 
    on bill_lot_renewal(facility, custid, item, lotnumber)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.activitytriggers_idx
    on alps.businessevents(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.campusidentifiers_idx
    on alps.campusidentifiers(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.cantpickreasons_idx
    on alps.cantpickreasons(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.cants_nameid
    on alps.cants(nameid)
pctfree 10
tablespace synapse_lod_index
/

create index alps.carrier_scac_idx
    on alps.carrier(scac)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.carrier_unique
    on alps.carrier(carrier)
pctfree 10
tablespace synapse_lod_index
/

create index alps.carrierprono_assign_status_idx
    on alps.carrierprono(carrier, zone, assign_status)
pctfree 10
tablespace synapse_act_index
/

create unique index alps.carrierprono_idx
    on alps.carrierprono(carrier, zone, seq)
pctfree 10
tablespace synapse_act_index
/

create unique index alps.carrierprono_prono_idx
    on alps.carrierprono(carrier, zone, prono)
pctfree 10
tablespace synapse_act_index
/

create unique index alps.carrierservicecodes_idx
    on alps.carrierservicecodes(carrier,servicecode)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.carrierspecialservice_idx
    on alps.carrierspecialservice(carrier,servicecode,specialservice)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.carrierstageloc_unique
    on alps.carrierstageloc(carrier,facility,shiptype)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.carrierstatus_idx
    on alps.carrierstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.carrierzone_idx
	 on alps.carrierzone(carrier, zone)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.cartongroups_unique
    on alps.cartongroups(cartongroup,code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.cartontypes_unique
    on alps.cartontypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.caselabels_idx1
    on alps.caselabels(orderid,shipid,custid,item,lotnumber)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.caselabels_uniq
    on alps.caselabels(barcode)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.catchweightoutboundcapture_idx
    on alps.catchweightoutboundcapture(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.chemicalcodes_unique
    on alps.chemicalcodes(chemcode)
pctfree 10
tablespace synapse_user_index
/

create index alps.commitments_custid_idx
    on alps.commitments(custid,item,inventoryclass,invstatus,status,lotnumber,facility)
pctfree 20
tablespace synapse_act2_index
/

create index alps.commitments_facility_idx
    on alps.commitments(facility,custid,item,inventoryclass,invstatus,status,lotnumber)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.commitments_order_idx
    on alps.commitments(orderid,shipid,orderitem,orderlot,item,lotnumber,inventoryclass,invstatus,status)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.commitstatus_idx
    on alps.commitstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.consignee_unique
    on alps.consignee(consignee)
pctfree 10
tablespace synapse_lod2_index
/

create unique index consshipwghtzip 
   on consigneecarriers (consignee, shiptype, assigned_ship_type, fromweight, begzip)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.consigneestatus_idx
    on alps.consigneestatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.controldescr_unique
    on alps.controldescr(controlnumber)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.conversions_idx
    on alps.conversions(fromuom,touom)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.counted_by_types_idx
    on alps.counted_by_types(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.countrycodes_idx
    on alps.countrycodes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custactvfacilities_idx
    on alps.custactvfacilities(custid,activity)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custauditstageloc_custid
    on alps.custauditstageloc(custid,facility)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custauditstageloc_unique
    on alps.custauditstageloc(facility,custid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custbilldates_index
    on alps.custbilldates(custid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custcarrierprono_idx
    on alps.custcarrierprono(custid,carrier)
pctfree 10
tablespace synapse_act_index
/

create unique index alps.custconsignee_unique
    on alps.custconsignee(custid,consignee)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custconsigneenotice_idx
    on alps.custconsigneenotice(custid,ordertype,shipto,formatname)
pctfree 10
tablespace synapse_act2_index
/

create unique index alps.custconsigneesipname_unique
    on alps.custconsigneesipname(custid,sipname,sipaddr,sipcity,sipstate,sipzip)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.custdict_unique
    on alps.custdict(custid,fieldname)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custdispositionfacility_unique
    on alps.custdispositionfacility(custid,disposition,facility)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custfacility_unique
    on alps.custfacility(custid,facility)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custitem_unique
    on alps.custitem(custid,item)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.custitemalias_idx
    on alps.custitemalias(custid,itemalias)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.custitemalias_unique
    on alps.custitemalias(custid,item,itemalias)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.custitembolcomments_con
    on alps.custitembolcomments(consignee,custid,item)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitembolcomments_unique
    on alps.custitembolcomments(custid,item,consignee)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemcatchweight_unique
    on alps.custitemcatchweight(custid,item)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.custitemcount_unique
    on alps.custitemcount(custid,item,type,uom)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.custitemfacility_unique
    on alps.custitemfacility(custid,item,facility)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.custitemincomments_unique
    on alps.custitemincomments(custid,item)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custitemlabelprofiles_unique
    on alps.custitemlabelprofiles(custid,item,consignee)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemoutcomments_con
    on alps.custitemoutcomments(consignee,custid,item)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemoutcomments_unique
    on alps.custitemoutcomments(custid,item,consignee)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemsubs_seq
    on alps.custitemsubs(custid,item,seq)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemsubs_unique
    on alps.custitemsubs(custid,item,itemsub)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custitemtot_unique_custid
    on alps.custitemtot(custid,item,inventoryclass,invstatus,status,lotnumber,uom,facility)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.custitemtot_unique_facility
    on alps.custitemtot(facility,custid,item,inventoryclass,invstatus,status,lotnumber,uom)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.custitemuom_unique
    on alps.custitemuom(custid,item,sequence)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pk_custitemuomuos
    on alps.custitemuomuos(custid,item,uomseq,uosseq)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.custlastrenewal_index
    on alps.custlastrenewal(facility,custid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.customcode_be_idx
    on alps.customcode(businessevent)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.customer_unique
    on alps.customer(custid)
pctfree 20
tablespace synapse_act_index
/

create unique index custshipwghtzip 
   on customercarriers (custid, shiptype, assigned_ship_type, fromweight, begzip)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.customerstatus_idx
    on alps.customerstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custpacklist_unique
    on alps.custpacklist(custid,carrier,servicecode)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custproductgroup_unique
    on alps.custproductgroup(custid,productgroup)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custprodgroupfacility_unique
    on alps.custproductgroupfacility(custid,productgroup,facility)
pctfree 10
tablespace synapse_lod_index
/

create index alps.custrate_activity
    on alps.custrate(custid,rategroup,activity,billmethod)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custrate_unique
    on alps.custrate(custid,rategroup,effdate,activity,billmethod)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custratebreak_idx
   on alps.custratebreak(custid, rategroup, effdate,activity, billmethod,quantity)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custrategroup_unique
    on alps.custrategroup(custid,rategroup)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custratewhen_unique
    on alps.custratewhen(custid,rategroup,effdate,activity,billmethod,businessevent)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custrenewal_index
    on alps.custrenewal(custid,renewal)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custreturnreasons_unique
    on alps.custreturnreasons(custid,code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.custshipper_unique
    on alps.custshipper(custid,shipper)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.custsqft_unique
    on alps.custsqft(facility,custid)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.custtradingpartner_custid_idx
    on alps.custtradingpartner(custid,tradingpartner)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.custtradingpartner_idx
    on alps.custtradingpartner(tradingpartner)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.custvicsbol_idx
    on alps.custvicsbol(custid,ordertype,shipto,reportname)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.custvicsbolcopies_idx
    on alps.custvicsbolcopies(custid,shipto,ordertype,reportname,boltype,copynumber)
pctfree 10
tablespace synapse_user_index
/

create index alps.custworkorderinst_parent
    on alps.custworkorderinstructions(seq,parent)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.cyclecountactivity_taskitem
    on alps.cyclecountactivity(taskid,custid,item,lotnumber)
pctfree 20
tablespace synapse_act2_index
/

create index alps.cyclecountactivity_tasklp
    on alps.cyclecountactivity(taskid,lpid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.cyclecountadjustmenttypes_idx
    on alps.cyclecountadjustmenttypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.damageditemreasons_idx
    on alps.damageditemreasons(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.deletedplate_child_idx
    on alps.deletedplate(childfacility,childitem)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_controlno_idx
    on alps.deletedplate(controlnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_custitem_idx
    on alps.deletedplate(custid,item)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_customer_idx
    on alps.deletedplate(facility,custid,item,lotnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_destination_idx
    on alps.deletedplate(destfacility,destlocation)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_fromshiplip_idx
    on alps.deletedplate(fromshippinglpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_invclass_idx
    on alps.deletedplate(facility,inventoryclass)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_invstatus_idx
    on alps.deletedplate(facility,invstatus)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_loadno_idx
    on alps.deletedplate(loadno)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_location_idx
    on alps.deletedplate(facility,location)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_lotnumber_idx
    on alps.deletedplate(lotnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_orderid_idx
    on alps.deletedplate(orderid,shipid)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_parentlpid_idx
    on alps.deletedplate(parentlpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_parent_idx
    on alps.deletedplate(parentfacility,parentitem)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_serialnumber_idx
    on alps.deletedplate(serialnumber)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.deletedplate_unique
    on alps.deletedplate(lpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_useritem1_idx
    on alps.deletedplate(useritem1)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_useritem2_idx
    on alps.deletedplate(useritem2)
pctfree 20
tablespace synapse_act_index
/

create index alps.deletedplate_useritem3_idx
    on alps.deletedplate(useritem3)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.delivery_point_types_idx
    on alps.delivery_point_types(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.docappointments_idx
    on alps.docappointments(appointmentid)
pctfree 10
tablespace synapse_lod_index
/

create index alps.docappointments_endtime_idx
    on alps.docappointments(endtime)
pctfree 10
tablespace synapse_lod_index
/

create index alps.docappointments_facility_idx
    on alps.docappointments(facility)
pctfree 10
tablespace synapse_lod_index
/

create index alps.docappointments_starttime_idx
    on alps.docappointments(starttime)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.docschedule_idx
    on alps.docschedule(scheduleid)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.docschedule_facility_idx
    on alps.docschedule(facility)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.docschedule_startdate_idx
    on alps.docschedule(startdate)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.docschedule_enddate_idx
    on alps.docschedule(enddate)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.door_unique
    on alps.door(facility,doorloc)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.employeeactivities_idx
    on alps.employeeactivities(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.equipmentprofiles_idx
    on alps.equipmentprofiles(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.equipmenttypes_idx
    on alps.equipmenttypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.equipprofequip_unique
    on alps.equipprofequip(profid,equipid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.pk_equiptask
    on alps.equiptask(equipid,tasktype)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.expirationactions_idx
    on alps.expirationactions(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.facility_unique
    on alps.facility(facility)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.facilitycarrier_idx
    on alps.facilitycarrierpronozone(facility, carrier)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.facilitystatus_idx
    on alps.facilitystatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.fitmethods_idx
    on alps.fitmethods(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.formatvalidationactions_idx
    on alps.formatvalidationactions(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.formatvalidationdatatypes_idx
    on alps.formatvalidationdatatypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.formatvalidationrule_unique
    on alps.formatvalidationrule(ruleid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.handlingtypes_unique
    on alps.handlingtypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.hazardousclasses_idx
    on alps.hazardousclasses(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.holdreasons_idx
    on alps.holdreasons(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.impexp_definitions_name
    on alps.impexp_definitions(name)
pctfree 10
tablespace synapse_lod_index
/

create index alps.invadjactivity_custid_idx
    on alps.invadjactivity(custid,item)
pctfree 20
tablespace synapse_inv_index
/

create index alps.invadjactivity_lpid_idx
    on alps.invadjactivity(lpid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.invadjactivity_when_idx
    on alps.invadjactivity(whenoccurred,facility,custid,item,invstatus,inventoryclass)
pctfree 10
tablespace synapse_inv_index
/

create index alps.invadjactivity_custref_idx
	on alps.invadjactivity(custreference)
pctfree 10
tablespace synapse_inv_index
/

create unique index alps.inventoryclass_idx
    on alps.inventoryclass(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.inventorystatus_idx
    on alps.inventorystatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.invoicedtl_idx
    on alps.invoicedtl(billstatus,facility,custid,orderid,shipid,item,activity,activitydate)
pctfree 10
tablespace synapse_ord_index
/

create index alps.invoicedtl_inv_idx
    on alps.invoicedtl(invoice,orderid,shipid,item,lotnumber)
pctfree 10
tablespace synapse_ord_index
/

create index alps.invoicedtl_load_idx
    on alps.invoicedtl(loadno,custid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.invoicedtl_ord_idx
    on alps.invoicedtl(orderid,shipid,orderitem,orderlot)
pctfree 10
tablespace synapse_ord_index
/

create index alps.invoicehdr_custid_idx
    on alps.invoicehdr(custid,facility,invtype,invstatus)
pctfree 10
tablespace synapse_act2_index
/

create unique index alps.invoicehdr_idx
    on alps.invoicehdr(invoice)
pctfree 20
tablespace synapse_act2_index
/

create index alps.invoicehdr_mi_idx
    on alps.invoicehdr(masterinvoice)
pctfree 20
tablespace synapse_act2_index
/

create index alps.invoicehdr_postdate_idx
    on alps.invoicehdr(postdate)
pctfree 10
tablespace synapse_act2_index
/

create index alps.invoicehdr_post_idx
    on alps.invoicehdr(custid,postdate)
pctfree 10
tablespace synapse_act2_index
/

create index alps.invoicehdr_status_idx
    on alps.invoicehdr(invstatus)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.invoicetypes_idx
    on alps.invoicetypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pk_invoicesession
    on alps.invsession(userid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.irisclasses_idx
    on alps.irisclasses(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.iristypes_idx
    on alps.iristypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.iris_del_service_exception_idx
    on alps.iris_del_service_exception(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.itemdemand_item_idx
    on alps.itemdemand(facility,item,lotnumber)
pctfree 10
tablespace synapse_lod_index
/

create index alps.itemdemand_order_idx
    on alps.itemdemand(orderid,shipid,orderitem,orderlot)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.iteminventorystatus_idx
    on alps.iteminventorystatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.itemlipstatus_idx
    on alps.itemlipstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create index alps.itempickfronts_facility_idx
    on alps.itempickfronts(facility,pickfront)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.itempickfronts_unique
    on alps.itempickfronts(custid,item,facility,pickfront,pickuom)
pctfree 10
tablespace synapse_act_index
/

create unique index alps.itemstatus_idx
    on alps.itemstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.itemvelocitycodes_idx
    on alps.itemvelocitycodes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.labelprintactions_idx
    on alps.labelprintactions(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.labelprofileline_unique
    on alps.labelprofileline(profid,businessevent,uom,seq)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.labelprofiles_idx
    on alps.labelprofiles(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.laborreportcountgroups_idx
    on alps.laborreportcountgroups(code)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.laborreportgroups_idx
    on alps.laborreportgroups(code)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.laborstandards_unique
    on alps.laborstandards(facility,custid,category,zoneid,uom)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.lastfreightbill_all_idx
    on alps.lastfreightbill_all(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.lastlawsonbill_all_idx
    on alps.lastlawsonbill_all(code)
pctfree 20
tablespace synapse_user_index
/

create unique index alps.lasttmscust_all_idx
    on alps.lasttmscust_all(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.lasttms_all_idx
    on alps.lasttms_all(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.licenseplatestatus_idx
    on alps.licenseplatestatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.licenseplatetypes_idx
    on alps.licenseplatetypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.loaded_by_types_idx
    on alps.loaded_by_types(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.loads_idx
    on alps.loads(loadno)
pctfree 20
tablespace synapse_act2_index
/

create index alps.loads_rcvddate_idx
    on alps.loads(rcvddate)
pctfree 10
tablespace synapse_act2_index
/

create index alps.loads_stageloc_idx
    on alps.loads(facility,stageloc)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.loadsbolcomments_unique
    on alps.loadsbolcomments(loadno)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.loadstatus_idx
    on alps.loadstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.loadstop_idx
    on alps.loadstop(loadno,stopno)
pctfree 20
tablespace synapse_act_index
/

create index alps.loadstop_stageloc_idx
    on alps.loadstop(facility,stageloc)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.loadstopbolcomments_unique
    on alps.loadstopbolcomments(loadno,stopno)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.loadstopship_idx
    on alps.loadstopship(loadno,stopno,shipno)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.loadstopshipbolcomments_unique
    on alps.loadstopshipbolcomments(loadno,stopno,shipno)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.loadtypes_idx
    on alps.loadtypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.location_loctype_idx
    on alps.location(facility,loctype)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.location_unique
    on alps.location(facility,locid)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.locationattributes_idx
    on alps.locationattributes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.locationstatus_idx
    on alps.locationstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.locationtypes_idx
    on alps.locationtypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index lotreceiptcapture_idx
   on lotreceiptcapture(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.ltlfreightclass_idx
    on alps.ltlfreightclass(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.mass_manifest_ctn_idx
   on alps.mass_manifest_ctn(ctnid)
pctfree 10
tablespace synapse_temp_index
/

create index alps.mass_manifest_ctn_item
   on alps.mass_manifest_ctn(orderid, shipid, item)
pctfree 10
tablespace synapse_temp_index
/

create index alps.mass_manifest_ctn_wave
   on alps.mass_manifest_ctn(wave)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.messageauthors_idx
    on alps.messageauthors(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.messagestatus_idx
    on alps.messagestatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.messagetypes_idx
    on alps.messagetypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.movementchangereasons_idx
    on alps.movementchangereasons(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.ix_multishipdtl_cartonid
    on alps.multishipdtl(cartonid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.multishipdtl_status_idx
    on alps.multishipdtl(status)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.pk_multishipdtl
    on alps.multishipdtl(orderid,shipid,cartonid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.pk_multishiphdr
    on alps.multishiphdr(orderid,shipid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.pk_multishipterminal
    on alps.multishipterminal(facility,termid)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.nationalmotorfreightclass_idx
    on alps.nationalmotorfreightclass(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.neworderdtl_date_idx
    on alps.neworderdtl(chgdate,chguser)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.neworderdtl_idx
    on alps.neworderdtl(orderid,shipid)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.neworderhdr_date_idx
    on alps.neworderhdr(chgdate,chguser)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.neworderhdr_idx
    on alps.neworderhdr(orderid,shipid)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.nixedpickloc_lpid
    on alps.nixedpickloc(nameid,facility)
pctfree 10
tablespace synapse_lod_index
/

create index alps.nixedputloc_lpid
    on alps.nixedputloc(lpid,facility,location)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.nmfclasscodes_unique
    on alps.nmfclasscodes(nmfc)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.nontaskactivities_idx
    on alps.nontaskactivities(code)
pctfree 20
tablespace synapse_act2_index
/

create index alps.oldorderdtl_date_idx
    on alps.oldorderdtl(chgdate,chguser)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.oldorderdtl_idx
    on alps.oldorderdtl(orderid,shipid)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.oldorderhdr_date_idx
    on alps.oldorderhdr(chgdate,chguser)
pctfree 10
tablespace synapse_ohis_index
/

create index alps.oldorderhdr_idx
    on alps.oldorderhdr(orderid,shipid)
pctfree 10
tablespace synapse_ohis_index
/

create unique index alps.ordercancellationreasons_idx
    on alps.ordercancellationreasons(code)
pctfree 20
tablespace synapse_ord_index
/

create index alps.ordercheck_order
    on alps.ordercheck(orderid,shipid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderdtl_childorderid
    on alps.orderdtl(childorderid)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderdtl_unique
    on alps.orderdtl(orderid,shipid,item,lotnumber)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderdtl_xdockorderid
    on alps.orderdtl(xdockorderid)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderdtlbolcomments_unique
    on alps.orderdtlbolcomments(orderid,shipid,item,lotnumber)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderdtlline_item
    on alps.orderdtlline(orderid,shipid,item,lotnumber,linenumber)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderdtlline_linenumber
    on alps.orderdtlline(orderid,shipid,linenumber)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_created_idx
    on alps.orderdtlrcpt(lastupdate)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_idx
    on alps.orderdtlrcpt(serialnumber,useritem1,useritem2,useritem3)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_lpid_idx
    on alps.orderdtlrcpt(lpid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_orderdtl_idx
    on alps.orderdtlrcpt(orderid,shipid,orderitem,orderlot,lpid)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_serial_idx
    on alps.orderdtlrcpt(custid,item,serialnumber)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_user1_idx
    on alps.orderdtlrcpt(custid,item,useritem1)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_user2_idx
    on alps.orderdtlrcpt(custid,item,useritem2)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_user3_idx
    on alps.orderdtlrcpt(custid,item,useritem3)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_useritem1_idx
    on alps.orderdtlrcpt(useritem1)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_useritem2_idx
    on alps.orderdtlrcpt(useritem2)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderdtlrcpt_useritem3_idx
    on alps.orderdtlrcpt(useritem3)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderhdr_arrivaldate_idx
    on alps.orderhdr(arrivaldate)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_commit_idx
    on alps.orderhdr(fromfacility,commitstatus)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_dateshipped_idx
    on alps.orderhdr(dateshipped)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_edicancelpending_idx
    on alps.orderhdr(edicancelpending)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_entrydate_idx
    on alps.orderhdr(entrydate)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderhdr_idx
    on alps.orderhdr(orderid,shipid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_importfileid_idx
    on alps.orderhdr(importfileid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_load_idx
    on alps.orderhdr(loadno,stopno,shipno)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_parentorderid
    on alps.orderhdr(parentorderid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_po_idx
    on alps.orderhdr(po)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_prono_idx
    on alps.orderhdr(prono)
pctfree 10
tablespace synapse_ord_index
/

create unique index alps.orderhdr_recent_order_id_idx
    on alps.orderhdr(recent_order_id)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderhdr_ref_idx
    on alps.orderhdr(reference)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_rma_idx
    on alps.orderhdr(rma)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_stageloc_idx
    on alps.orderhdr(fromfacility,stageloc)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_statusupdate_idx
    on alps.orderhdr(statusupdate)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_status_idx
    on alps.orderhdr(fromfacility,orderstatus)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_tms_release_idx
    on alps.orderhdr(tms_release_id)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderhdr_tms_shipment_idx
    on alps.orderhdr(tms_shipment_id)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderhdr_type_idx
    on alps.orderhdr(ordertype,orderid,shipid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_wave_idx
    on alps.orderhdr(wave)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhdr_workorderseq
    on alps.orderhdr(workorderseq)
pctfree 20
tablespace synapse_ord_index
/

create unique index alps.orderhdrbolcommmnents_unique
    on alps.orderhdrbolcomments(orderid,shipid)
pctfree 20
tablespace synapse_ord_index
/

create index alps.orderhistory_order_idx
    on alps.orderhistory(orderid,shipid,chgdate,userid)
pctfree 10
tablespace synapse_ohis_index
/

create unique index alps.orderitemstatus_idx
    on alps.orderitemstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.orderlabor_order_idx
    on alps.orderlabor(orderid,shipid,item,lotnumber)
pctfree 10
tablespace synapse_ord_index
/

create index alps.orderlabor_wave_idx
    on alps.orderlabor(wave)
pctfree 10
tablespace synapse_ord_index
/

create unique index alps.orderpriority_idx
    on alps.orderpriority(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.orderquantitytypes_idx
    on alps.orderquantitytypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.orderstatus_idx
    on alps.orderstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.ordertypes_idx
    on alps.ordertypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.ordervalidationerrors_idx
    on alps.ordervalidationerrors(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.p1pkcaselabels_unique
    on alps.p1pkcaselabels(orderid,shipid,custid,item)
pctfree 10
tablespace synapse_user_index
/

create index alps.pallethistory_carrier
    on alps.pallethistory(carrier,custid,facility)
pctfree 10
tablespace synapse_temp_index
/

create index alps.pallethistory_customer
    on alps.pallethistory(custid,facility,carrier)
pctfree 10
tablespace synapse_temp_index
/

create index alps.pallethistory_loadno
    on alps.pallethistory(loadno,custid,facility)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.pallethistory_unique
    on alps.pallethistory(custid,facility,pallettype,carrier,lastupdate)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.palletinvadjreason_idx
    on alps.palletinvadjreason(code)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.palletinventory_unique
    on alps.palletinventory(custid,facility,pallettype)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.pallettypes_idx
    on alps.pallettypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.parseentryfield_idx
    on alps.parseentryfield(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.parserule_pk
    on alps.parserule(ruleid)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.idx_phinvdtl_custid
    on alps.physicalinventorydtl(custid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.idx_phinvdtl_taskid
    on alps.physicalinventorydtl(taskid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.idx_phynvdtl_location
    on alps.physicalinventorydtl(facility,location)
pctfree 20
tablespace synapse_inv_index
/

create index alps.idx_phynvdtl_lpid
    on alps.physicalinventorydtl(lpid)
pctfree 20
tablespace synapse_inv_index
/

create unique index alps.pk_phinvdtl
    on alps.physicalinventorydtl(id,facility,location,custid,item,lotnumber,lpid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.idx_phinvhdr_status
    on alps.physicalinventoryhdr(status)
pctfree 20
tablespace synapse_inv_index
/

create unique index alps.pk_phinvhdr
    on alps.physicalinventoryhdr(id)
pctfree 20
tablespace synapse_inv_index
/

create unique index alps.physicalinventorystatus_idx
    on alps.physicalinventorystatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.pickdirections_idx
    on alps.pickdirections(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pickrequestqueues_idx
    on alps.pickrequestqueues(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.picktotypes_idx
    on alps.picktotypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.picktypes_idx
    on alps.picktypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.plate_asnvariance_idx
    on alps.plate(serialnumber,useritem1,orderid,shipid,lpid,fromlpid)
pctfree 10
tablespace synapse_act_index
/

create index alps.plate_child_idx
    on alps.plate(childfacility,childitem)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_controlnumber_idx
    on alps.plate(controlnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_custitem_idx
    on alps.plate(custid,item,facility,serialnumber,location)
pctfree 10
tablespace synapse_act_index
/

create index alps.plate_customer
    on alps.plate(facility,custid,item,lotnumber,invstatus,inventoryclass)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_destination
    on alps.plate(destfacility,destlocation)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_fromshippinglpid
    on alps.plate(fromshippinglpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_invclass_idx
    on alps.plate(facility,inventoryclass)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_invstatus_idx
    on alps.plate(facility,invstatus)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_loadno_idx
    on alps.plate(loadno)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_location
    on alps.plate(facility,location)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_lotnumber_idx
    on alps.plate(lotnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_order_item_idx
    on alps.plate(orderid,shipid,item,lotnumber)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_parentlpid
    on alps.plate(parentlpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_parent_idx
    on alps.plate(parentfacility,parentitem)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_serialnumber_idx
    on alps.plate(serialnumber)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.plate_unique
    on alps.plate(lpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_useritem1_idx
    on alps.plate(useritem1)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_useritem2_idx
    on alps.plate(useritem2)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_useritem3_idx
    on alps.plate(useritem3)
pctfree 20
tablespace synapse_act_index
/

create index alps.plate_workorder
    on alps.plate(facility,workorderseq,workordersubseq)
pctfree 20
tablespace synapse_act_index
/

create index alps.platehistory_idx
    on alps.platehistory(lpid,whenoccurred)
pctfree 10
tablespace synapse_his_index
/

create unique index alps.postalcodes_idx
    on alps.postalcodes(code)
pctfree 10
tablespace synapse_lod_index
/

create index alps.postdtl_idx
    on alps.postdtl(invoice,account)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.printer_unique
    on alps.printer(facility,prtid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.printerstock_idx
    on alps.printerstock(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.printertypes_idx
    on alps.printertypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.productgroups_idx
    on alps.productgroups(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pronostatus_idx
    on alps.pronostatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.purgerules
    on alps.purgerules(tablename,rule1field,rule1operator,rule1value,rule2field,rule2operator,rule2value,rule3field,rule3operator,rule3value)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.purgerulesdtl_idx
    on alps.purgerulesdtl(tablename,rule1field,rule1operator,rule1value,rule2field,rule2operator,rule2value,rule3field,rule3operator,rule3value,custid,facility)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.purgetablelist_parent_idx
    on alps.purgetablelist(parenttable,childtable)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.putawaychangereasons_idx
    on alps.putawaychangereasons(code)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.putawayconfirmations_idx
    on alps.putawayconfirmations(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.putawayprof_idx
    on alps.putawayprof(facility,profid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.putawayprofline_idx
    on alps.putawayprofline(facility,profid,priority)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.putawayqueues_idx
    on alps.putawayqueues(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.putawayunitdispositions_idx
    on alps.putawayunitdispositions(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.qcconditions_idx
    on alps.qcconditions(code)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.qcdispositions_idx
    on alps.qcdispositions(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pk_qcrequest
    on alps.qcrequest(id)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.qcrequesttype_idx
    on alps.qcrequesttype(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.pk_qcresult
    on alps.qcresult(id,orderid,shipid,item,lotnumber)
pctfree 10
tablespace synapse_user_index
/

create index alps.qcresult_order_idx
    on alps.qcresult(orderid,shipid,id)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.pk_qcresultdtl
    on alps.qcresultdtl(id,orderid,shipid,lpid)
pctfree 10
tablespace synapse_user_index
/

create index alps.qcresultdtl_lpid_idx
    on alps.qcresultdtl(lpid)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.qcsampletype_idx
    on alps.qcsampletype(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.qcstatus_idx
    on alps.qcstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.ratecalculationtypes_idx
    on alps.ratecalculationtypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.ratestatus_idx
    on alps.ratestatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.receiptcondition_idx
    on alps.receiptcondition(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.renewalstoragemethod_idx
    on alps.renewalstoragemethod(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.replenishrequestqueues_idx
    on alps.replenishrequestqueues(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.unique_report
    on alps.report_security(nameid,report_name)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.requests_unique
    on alps.requests(facility,reqtype,descr)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.returnsdisposition_idx
    on alps.returnsdisposition(code)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.revenuereportgroups_idx
    on alps.revenuereportgroups(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.rfoperatingmodes_idx
    on alps.rfoperatingmodes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.pk_scd_batches
    on alps.scd_batches(batchid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.pk_scd_items
    on alps.scd_items(batchid,iteminc)
pctfree 10
tablespace synapse_lod_index
/

create index alps.scd_batches
    on alps.scd_items(batchid)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_enabled_18ebb532"
    on alps.scd_items(enabled)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_endtime_18ebb532"
    on alps.scd_items(endtime)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_iteminc_18ebb532"
    on alps.scd_items(iteminc)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_onesc_18ebb532"
    on alps.scd_items(onesc)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_onfailure_18ebb532"
    on alps.scd_items(onfailure)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_onnorecords_18ebb532"
    on alps.scd_items(onnorecords)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_onsuccess_18ebb532"
    on alps.scd_items(onsuccess)
pctfree 10
tablespace synapse_lod_index
/

create index alps."_wa_sys_starttime_18ebb532"
    on alps.scd_items(starttime)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.section_unique
    on alps.section(facility,sectionid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.sectionsearch_unique
    on alps.sectionsearch(facility,sectionid)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.shipdays_unique
    on alps.shipdays(facility,postalkey)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.shipmentterms_idx
    on alps.shipmentterms(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.shipmenttypes_idx
    on alps.shipmenttypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.shipper_unique
    on alps.shipper(shipper)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.shipperstatus_idx
    on alps.shipperstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create index alps.shippingaudit_lpid
    on alps.shippingaudit(lpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.shippingaudit_toplpid
    on alps.shippingaudit(toplpid)
pctfree 20
tablespace synapse_act_index
/

create index alps.shippingplate_custitem
    on alps.shippingplate(facility,custid,item,lotnumber)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_faccustorder_idx
    on alps.shippingplate(facility,custid,orderid,shipid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_fromlpid
    on alps.shippingplate(fromlpid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_invclass_idx
    on alps.shippingplate(facility,inventoryclass)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_invstatus_idx
    on alps.shippingplate(facility,invstatus)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_load
    on alps.shippingplate(loadno,stopno,shipno)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_location
    on alps.shippingplate(facility,location)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_lotnumber_idx
    on alps.shippingplate(lotnumber)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_openfacility_idx
    on alps.shippingplate(openfacility)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_order
    on alps.shippingplate(orderid,shipid,orderitem,orderlot)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_parentlpid
    on alps.shippingplate(parentlpid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_serialno_idx
    on alps.shippingplate(serialnumber)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_statusitem_idx
    on alps.shippingplate(status,facility,custid,item)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_subtask
    on alps.shippingplate(taskid,orderid,shipid,orderitem,orderlot)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_trackingno_idx
    on alps.shippingplate(trackingno)
pctfree 20
tablespace synapse_inv_index
/

create unique index alps.shippingplate_unique
    on alps.shippingplate(lpid)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_useritem1_idx
    on alps.shippingplate(useritem1)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_useritem2_idx
    on alps.shippingplate(useritem2)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplate_useritem3_idx
    on alps.shippingplate(useritem3)
pctfree 20
tablespace synapse_inv_index
/

create index alps.shippingplatehistory_idx
    on alps.shippingplatehistory(lpid,whenoccurred)
pctfree 10
tablespace synapse_his_index
/

create unique index alps.shippingplatestatus_idx
    on alps.shippingplatestatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.shippingplatetypes_idx
    on alps.shippingplatetypes(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.sip_parameters_idx
    on alps.sip_parameters(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.spoolerqueues_unique
    on alps.spoolerqueues(prtqueue)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.stateorprovince_idx
    on alps.stateorprovince(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.storageparms_pk_idx
    on alps.storageparms(objectclass)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.storagetypes_idx
    on alps.storagetypes(code)
pctfree 10
tablespace synapse_lod_index
/

create index alps.subtasks_location_idx
    on alps.subtasks(facility,fromloc)
pctfree 20
tablespace synapse_act2_index
/

create index alps.subtasks_lpid
    on alps.subtasks(lpid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.subtasks_order_idx
    on alps.subtasks(orderid,shipid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.subtasks_taskid
    on alps.subtasks(taskid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.subtasks_wave_idx
    on alps.subtasks(wave)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.systemdefaults_unique
    on alps.systemdefaults(defaultid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.tabledefs_unique
    on alps.tabledefs(tableid)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.taskpriorities_idx
    on alps.taskpriorities(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.taskrequestqueues_idx
    on alps.taskrequestqueues(code)
pctfree 10
tablespace synapse_lod_index
/

create index alps.tasks_facility_idx
    on alps.tasks(facility,priority,taskid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.tasks_load_idx
    on alps.tasks(loadno,stopno,shipno)
pctfree 20
tablespace synapse_act2_index
/

create index alps.tasks_locseq_idx
    on alps.tasks(locseq)
pctfree 20
tablespace synapse_act2_index
/

create index alps.tasks_lpid_idx
    on alps.tasks(lpid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.tasks_order_idx
    on alps.tasks(orderid,shipid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.tasks_unique
    on alps.tasks(taskid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.tasks_wave_idx
    on alps.tasks(wave)
pctfree 20
tablespace synapse_act2_index
/

create index alps.task_idx2
    on alps.tasks(priority,taskid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.task_idx3
    on alps.tasks(touserid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.tasktypes_idx
    on alps.tasktypes(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.temp_cust_item
    on alps.tempcustitem(nameid,custid,item,lotnumber)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.temp_cust_item_out
    on alps.tempcustitemout(nameid,custid,item,lotnumber)
pctfree 10
tablespace synapse_act2_index
/

create unique index alps.temp_inbound_entry
    on alps.temp_inbound_entry(nameid)
pctfree 10
tablespace synapse_act2_index
/

create unique index alps.temp_outbound_entry
    on alps.temp_outbound_entry(nameid)
pctfree 10
tablespace synapse_act2_index
/

create unique index alps.transarea_idx
    on alps.tmsarea(code)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.tmscarriers_idx
    on alps.tmscarriers(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.tmsfacilitygroup_idx
    on alps.tmsfacilitygroup(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.tmsorderstatus_idx
    on alps.tmsorderstatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.transroute_idx
    on alps.tmsroute(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.facilityarea
    on alps.tmsserviceroute(facilitygroup,area)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.begzipendzip
    on alps.tmsservicezip(begzip,endzip)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.tmsstatecode_idx
    on alps.tmsstatecode(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.tms_status_idx
    on alps.tms_status(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.pk_unitofstorage
    on alps.unitofstorage(unitofstorage)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.unitsofmeasure_idx
    on alps.unitsofmeasure(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.ursa_idx
    on alps.ursa(zipcode,state)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.usercustomer_unique
    on alps.usercustomer(nameid,custid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.userdetail_unique
    on alps.userdetail(nameid,formid,facility)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.userfacility_unique
    on alps.userfacility(nameid,facility)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.userforms_unique
    on alps.userforms(nameid,formid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.usergrids_unique
    on alps.usergrids(nameid,formid,gridid)
pctfree 20
tablespace synapse_act2_index
/

create unique index alps.userheader_unique
    on alps.userheader(nameid)
pctfree 20
tablespace synapse_act2_index
/

create index alps.userhistory_idx
    on alps.userhistory(nameid,begtime)
pctfree 10
tablespace synapse_his_index
/

create index alps.userhistory_name_end
    on alps.userhistory(nameid,endtime)
pctfree 10
tablespace synapse_his_index
/

create index alps.userhistory_name_event_begin
    on alps.userhistory(nameid,event,begtime)
pctfree 10
tablespace synapse_his_index
/

create index alps.userhistory_name_event_end
    on alps.userhistory(nameid,event,endtime)
pctfree 10
tablespace synapse_his_index
/

create unique index alps.userstatus_idx
    on alps.userstatus(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.usertoolbar_unique
    on alps.usertoolbar(userid)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.vics_bol_types_idx
    on alps.vics_bol_types(code)
pctfree 10
tablespace synapse_temp_index
/

create unique index alps.waves_facility
    on alps.waves(facility,wave,wavestatus)
pctfree 20
tablespace synapse_act_index
/

create index alps.waves_openfacility_idx
    on alps.waves(openfacility)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.waves_status
    on alps.waves(facility,wavestatus,wave)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.waves_unique
    on alps.waves(wave)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.wavestatus_idx
    on alps.wavestatus(code)
pctfree 10
tablespace synapse_lod_index
/

create unique index alps.web_userheader_unique
    on alps.webuserheader(nameid)
pctfree 20
tablespace synapse_act_index
/

create unique index alps.whentoverifyporeceipts_idx
    on alps.whentoverifyporeceipts(code)
pctfree 10
tablespace synapse_lod2_index
/

create unique index alps.ix_worldshipdtl_cartonid
    on alps.worldshipdtl(cartonid)
pctfree 10
tablespace synapse_user_index
/

create unique index alps.zone_unique
    on alps.zone(facility,zoneid)
pctfree 10
tablespace synapse_lod_index
/

exit;
