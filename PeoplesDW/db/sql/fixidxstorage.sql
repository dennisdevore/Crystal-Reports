--
-- $Id$
--
alter index activityminimumcategory_idx storage(pctincrease 0 maxextents unlimited);
alter index activityminimumcategory_idx rebuild pctfree 1;

alter index activitytriggers_idx storage(pctincrease 0 maxextents unlimited);
alter index activitytriggers_idx rebuild pctfree 1;

alter index activity_unique storage(pctincrease 0 maxextents unlimited);
alter index activity_unique rebuild pctfree 1;

alter index aisle_unique storage(pctincrease 0 maxextents unlimited);
alter index aisle_unique rebuild pctfree 1;

alter index applocks_unique storage(pctincrease 0 maxextents unlimited);
alter index applocks_unique rebuild pctfree 1;

alter index appmsgs_author storage(pctincrease 0 maxextents unlimited);
alter index appmsgs_author rebuild pctfree 1;

alter index appmsgs_created storage(pctincrease 0 maxextents unlimited);
alter index appmsgs_created rebuild pctfree 1;

alter index autopromptvalues_idx storage(pctincrease 0 maxextents unlimited);
alter index autopromptvalues_idx rebuild pctfree 1;

alter index backorderpolicy_idx storage(pctincrease 0 maxextents unlimited);
alter index backorderpolicy_idx rebuild pctfree 1;

alter index billingmethod_idx storage(pctincrease 0 maxextents unlimited);
alter index billingmethod_idx rebuild pctfree 1;

alter index billstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index billstatus_idx rebuild pctfree 1;

alter index campusidentifiers_idx storage(pctincrease 0 maxextents unlimited);
alter index campusidentifiers_idx rebuild pctfree 1;

alter index cants_nameid storage(pctincrease 0 maxextents unlimited);
alter index cants_nameid rebuild pctfree 1;

alter index carrierstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index carrierstatus_idx rebuild pctfree 1;

alter index carrier_unique storage(pctincrease 0 maxextents unlimited);
alter index carrier_unique rebuild pctfree 1;

alter index commitments_custid_idx storage(pctincrease 0 maxextents unlimited);
alter index commitments_custid_idx rebuild pctfree 1;

alter index commitments_facility_idx storage(pctincrease 0 maxextents unlimited);
alter index commitments_facility_idx rebuild pctfree 1;

alter index commitments_order_idx storage(pctincrease 0 maxextents unlimited);
alter index commitments_order_idx rebuild pctfree 1;

alter index commitstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index commitstatus_idx rebuild pctfree 1;

alter index consigneecomments_unique storage(pctincrease 0 maxextents unlimited);
alter index consigneecomments_unique rebuild pctfree 1;

alter index consigneestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index consigneestatus_idx rebuild pctfree 1;

alter index consignee_unique storage(pctincrease 0 maxextents unlimited);
alter index consignee_unique rebuild pctfree 1;

alter index conversions_idx storage(pctincrease 0 maxextents unlimited);
alter index conversions_idx rebuild pctfree 1;

alter index countrycodes_idx storage(pctincrease 0 maxextents unlimited);
alter index countrycodes_idx rebuild pctfree 1;

alter index custconsignee_unique storage(pctincrease 0 maxextents unlimited);
alter index custconsignee_unique rebuild pctfree 1;

alter index custdict_unique storage(pctincrease 0 maxextents unlimited);
alter index custdict_unique rebuild pctfree 1;

alter index custitemalias_idx storage(pctincrease 0 maxextents unlimited);
alter index custitemalias_idx rebuild pctfree 1;

alter index custitemalias_unique storage(pctincrease 0 maxextents unlimited);
alter index custitemalias_unique rebuild pctfree 1;

alter index custitemcount_unique storage(pctincrease 0 maxextents unlimited);
alter index custitemcount_unique rebuild pctfree 1;

alter index custitemsubs_seq storage(pctincrease 0 maxextents unlimited);
alter index custitemsubs_seq rebuild pctfree 1;

alter index custitemsubs_unique storage(pctincrease 0 maxextents unlimited);
alter index custitemsubs_unique rebuild pctfree 1;

alter index custitemtot_unique_custid storage(pctincrease 0 maxextents unlimited);
alter index custitemtot_unique_custid rebuild pctfree 1;

alter index custitemtot_unique_facility storage(pctincrease 0 maxextents unlimited);
alter index custitemtot_unique_facility rebuild pctfree 1;

alter index custitemuom_unique storage(pctincrease 0 maxextents unlimited);
alter index custitemuom_unique rebuild pctfree 1;

alter index custitem_unique storage(pctincrease 0 maxextents unlimited);
alter index custitem_unique rebuild pctfree 1;

alter index customerstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index customerstatus_idx rebuild pctfree 1;

alter index customer_unique storage(pctincrease 0 maxextents unlimited);
alter index customer_unique rebuild pctfree 1;

alter index custrategroup_unique storage(pctincrease 0 maxextents unlimited);
alter index custrategroup_unique rebuild pctfree 1;

alter index custratewhen_unique storage(pctincrease 0 maxextents unlimited);
alter index custratewhen_unique rebuild pctfree 1;

alter index custrate_activity storage(pctincrease 0 maxextents unlimited);
alter index custrate_activity rebuild pctfree 1;

alter index custrate_unique storage(pctincrease 0 maxextents unlimited);
alter index custrate_unique rebuild pctfree 1;

alter index custshipper_unique storage(pctincrease 0 maxextents unlimited);
alter index custshipper_unique rebuild pctfree 1;

alter index custsqft_unique storage(pctincrease 0 maxextents unlimited);
alter index custsqft_unique rebuild pctfree 1;

alter index damageditemreasons_idx storage(pctincrease 0 maxextents unlimited);
alter index damageditemreasons_idx rebuild pctfree 1;

alter index deletedplate_unique storage(pctincrease 0 maxextents unlimited);
alter index deletedplate_unique rebuild pctfree 1;

alter index door_unique storage(pctincrease 0 maxextents unlimited);
alter index door_unique rebuild pctfree 1;

alter index employeeactivities_idx storage(pctincrease 0 maxextents unlimited);
alter index employeeactivities_idx rebuild pctfree 1;

alter index equipmentprofiles_idx storage(pctincrease 0 maxextents unlimited);
alter index equipmentprofiles_idx rebuild pctfree 1;

alter index equipmenttypes_idx storage(pctincrease 0 maxextents unlimited);
alter index equipmenttypes_idx rebuild pctfree 1;

alter index equipprofequip_unique storage(pctincrease 0 maxextents unlimited);
alter index equipprofequip_unique rebuild pctfree 1;

alter index expirationactions_idx storage(pctincrease 0 maxextents unlimited);
alter index expirationactions_idx rebuild pctfree 1;

alter index facilitystatus_idx storage(pctincrease 0 maxextents unlimited);
alter index facilitystatus_idx rebuild pctfree 1;

alter index facility_unique storage(pctincrease 0 maxextents unlimited);
alter index facility_unique rebuild pctfree 1;

alter index fitmethods_idx storage(pctincrease 0 maxextents unlimited);
alter index fitmethods_idx rebuild pctfree 1;

alter index handlingtypes_unique storage(pctincrease 0 maxextents unlimited);
alter index handlingtypes_unique rebuild pctfree 1;

alter index holdreasons_idx storage(pctincrease 0 maxextents unlimited);
alter index holdreasons_idx rebuild pctfree 1;

alter index inventoryclass_idx storage(pctincrease 0 maxextents unlimited);
alter index inventoryclass_idx rebuild pctfree 1;

alter index inventorystatus_idx storage(pctincrease 0 maxextents unlimited);
alter index inventorystatus_idx rebuild pctfree 1;

alter index invoicedtl_idx storage(pctincrease 0 maxextents unlimited);
alter index invoicedtl_idx rebuild pctfree 1;

alter index invoicehdr_idx storage(pctincrease 0 maxextents unlimited);
alter index invoicehdr_idx rebuild pctfree 1;

alter index invoicetypes_idx storage(pctincrease 0 maxextents unlimited);
alter index invoicetypes_idx rebuild pctfree 1;

alter index iteminventorystatus_idx storage(pctincrease 0 maxextents unlimited);
alter index iteminventorystatus_idx rebuild pctfree 1;

alter index itemlipstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index itemlipstatus_idx rebuild pctfree 1;

alter index itemstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index itemstatus_idx rebuild pctfree 1;

alter index itemvelocitycodes_idx storage(pctincrease 0 maxextents unlimited);
alter index itemvelocitycodes_idx rebuild pctfree 1;

alter index licenseplatestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index licenseplatestatus_idx rebuild pctfree 1;

alter index licenseplatetypes_idx storage(pctincrease 0 maxextents unlimited);
alter index licenseplatetypes_idx rebuild pctfree 1;

alter index loadsbolcomments_unique storage(pctincrease 0 maxextents unlimited);
alter index loadsbolcomments_unique rebuild pctfree 1;

alter index loadstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index loadstatus_idx rebuild pctfree 1;

alter index loadstopbolcomments_unique storage(pctincrease 0 maxextents unlimited);
alter index loadstopbolcomments_unique rebuild pctfree 1;

alter index loadstopshipbolcomments_unique storage(pctincrease 0 maxextents unlimited);
alter index loadstopshipbolcomments_unique rebuild pctfree 1;

alter index loadstopship_idx storage(pctincrease 0 maxextents unlimited);
alter index loadstopship_idx rebuild pctfree 1;

alter index loadstop_idx storage(pctincrease 0 maxextents unlimited);
alter index loadstop_idx rebuild pctfree 1;

alter index loads_idx storage(pctincrease 0 maxextents unlimited);
alter index loads_idx rebuild pctfree 1;

alter index loadtypes_idx storage(pctincrease 0 maxextents unlimited);
alter index loadtypes_idx rebuild pctfree 1;

alter index locationattributes_idx storage(pctincrease 0 maxextents unlimited);
alter index locationattributes_idx rebuild pctfree 1;

alter index locationstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index locationstatus_idx rebuild pctfree 1;

alter index locationtypes_idx storage(pctincrease 0 maxextents unlimited);
alter index locationtypes_idx rebuild pctfree 1;

alter index location_unique storage(pctincrease 0 maxextents unlimited);
alter index location_unique rebuild pctfree 1;

alter index messageauthors_idx storage(pctincrease 0 maxextents unlimited);
alter index messageauthors_idx rebuild pctfree 1;

alter index messagestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index messagestatus_idx rebuild pctfree 1;

alter index messagetypes_idx storage(pctincrease 0 maxextents unlimited);
alter index messagetypes_idx rebuild pctfree 1;

alter index movementchangereasons_unique storage(pctincrease 0 maxextents unlimited);
alter index movementchangereasons_unique rebuild pctfree 1;

alter index nationalmotorfreightclass_idx storage(pctincrease 0 maxextents unlimited);
alter index nationalmotorfreightclass_idx rebuild pctfree 1;

alter index nixedputloc_lpid storage(pctincrease 0 maxextents unlimited);
alter index nixedputloc_lpid rebuild pctfree 1;

alter index orderdtlbolcommmnents_unique storage(pctincrease 0 maxextents unlimited);
alter index orderdtlbolcommmnents_unique rebuild pctfree 1;

alter index orderdtl_unique storage(pctincrease 0 maxextents unlimited);
alter index orderdtl_unique rebuild pctfree 1;

alter index orderhdrbolcommmnents_unique storage(pctincrease 0 maxextents unlimited);
alter index orderhdrbolcommmnents_unique rebuild pctfree 1;

alter index orderhdr_commit_idx storage(pctincrease 0 maxextents unlimited);
alter index orderhdr_commit_idx rebuild pctfree 1;

alter index orderhdr_idx storage(pctincrease 0 maxextents unlimited);
alter index orderhdr_idx rebuild pctfree 1;

alter index orderhdr_load_idx storage(pctincrease 0 maxextents unlimited);
alter index orderhdr_load_idx rebuild pctfree 1;

alter index orderhdr_status_idx storage(pctincrease 0 maxextents unlimited);
alter index orderhdr_status_idx rebuild pctfree 1;

alter index orderhdr_wave_idx storage(pctincrease 0 maxextents unlimited);
alter index orderhdr_wave_idx rebuild pctfree 1;

alter index orderitemstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index orderitemstatus_idx rebuild pctfree 1;

alter index orderpriority_idx storage(pctincrease 0 maxextents unlimited);
alter index orderpriority_idx rebuild pctfree 1;

alter index orderquantitytypes_idx storage(pctincrease 0 maxextents unlimited);
alter index orderquantitytypes_idx rebuild pctfree 1;

alter index orderstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index orderstatus_idx rebuild pctfree 1;

alter index ordertypes_idx storage(pctincrease 0 maxextents unlimited);
alter index ordertypes_idx rebuild pctfree 1;

alter index pk_custitemuomuos storage(pctincrease 0 maxextents unlimited);
alter index pk_custitemuomuos rebuild pctfree 1;

alter index pk_equiptask storage(pctincrease 0 maxextents unlimited);
alter index pk_equiptask rebuild pctfree 1;

alter index pk_unitofstorage storage(pctincrease 0 maxextents unlimited);
alter index pk_unitofstorage rebuild pctfree 1;

alter index pk_uomcombos storage(pctincrease 0 maxextents unlimited);
alter index pk_uomcombos rebuild pctfree 1;

alter index pk_xferfiles storage(pctincrease 0 maxextents unlimited);
alter index pk_xferfiles rebuild pctfree 1;

alter index pk_xfernodes storage(pctincrease 0 maxextents unlimited);
alter index pk_xfernodes rebuild pctfree 1;

alter index platehistory_idx storage(pctincrease 0 maxextents unlimited);
alter index platehistory_idx rebuild pctfree 1;

alter index plate_destination storage(pctincrease 0 maxextents unlimited);
alter index plate_destination rebuild pctfree 1;

alter index plate_location storage(pctincrease 0 maxextents unlimited);
alter index plate_location rebuild pctfree 1;

alter index plate_unique storage(pctincrease 0 maxextents unlimited);
alter index plate_unique rebuild pctfree 1;

alter index postalcodes_idx storage(pctincrease 0 maxextents unlimited);
alter index postalcodes_idx rebuild pctfree 1;

alter index postdtl_idx storage(pctincrease 0 maxextents unlimited);
alter index postdtl_idx rebuild pctfree 1;

alter index printerstock_idx storage(pctincrease 0 maxextents unlimited);
alter index printerstock_idx rebuild pctfree 1;

alter index printertypes_idx storage(pctincrease 0 maxextents unlimited);
alter index printertypes_idx rebuild pctfree 1;

alter index printer_unique storage(pctincrease 0 maxextents unlimited);
alter index printer_unique rebuild pctfree 1;

alter index productgroups_idx storage(pctincrease 0 maxextents unlimited);
alter index productgroups_idx rebuild pctfree 1;

alter index putawaychangereasons_idx storage(pctincrease 0 maxextents unlimited);
alter index putawaychangereasons_idx rebuild pctfree 1;

alter index putawayprofline_idx storage(pctincrease 0 maxextents unlimited);
alter index putawayprofline_idx rebuild pctfree 1;

alter index putawayprof_idx storage(pctincrease 0 maxextents unlimited);
alter index putawayprof_idx rebuild pctfree 1;

alter index putawayunitdispositions_idx storage(pctincrease 0 maxextents unlimited);
alter index putawayunitdispositions_idx rebuild pctfree 1;

alter index ratecalculationtypes_idx storage(pctincrease 0 maxextents unlimited);
alter index ratecalculationtypes_idx rebuild pctfree 1;

alter index ratestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index ratestatus_idx rebuild pctfree 1;

alter index receiptcondition_idx storage(pctincrease 0 maxextents unlimited);
alter index receiptcondition_idx rebuild pctfree 1;

alter index renewalstoragemethod_idx storage(pctincrease 0 maxextents unlimited);
alter index renewalstoragemethod_idx rebuild pctfree 1;

alter index requests_unique storage(pctincrease 0 maxextents unlimited);
alter index requests_unique rebuild pctfree 1;

alter index rfoperatingmodes_idx storage(pctincrease 0 maxextents unlimited);
alter index rfoperatingmodes_idx rebuild pctfree 1;

alter index rfpickmodes_idx storage(pctincrease 0 maxextents unlimited);
alter index rfpickmodes_idx rebuild pctfree 1;

alter index sectionsearch_unique storage(pctincrease 0 maxextents unlimited);
alter index sectionsearch_unique rebuild pctfree 1;

alter index section_unique storage(pctincrease 0 maxextents unlimited);
alter index section_unique rebuild pctfree 1;

alter index shipdays_unique storage(pctincrease 0 maxextents unlimited);
alter index shipdays_unique rebuild pctfree 1;

alter index shipmentterms_idx storage(pctincrease 0 maxextents unlimited);
alter index shipmentterms_idx rebuild pctfree 1;

alter index shipmenttypes_idx storage(pctincrease 0 maxextents unlimited);
alter index shipmenttypes_idx rebuild pctfree 1;

alter index shipperstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index shipperstatus_idx rebuild pctfree 1;

alter index shipper_unique storage(pctincrease 0 maxextents unlimited);
alter index shipper_unique rebuild pctfree 1;

alter index shippingplatestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index shippingplatestatus_idx rebuild pctfree 1;

alter index shippingplatetypes_idx storage(pctincrease 0 maxextents unlimited);
alter index shippingplatetypes_idx rebuild pctfree 1;

alter index shippingplate_load storage(pctincrease 0 maxextents unlimited);
alter index shippingplate_load rebuild pctfree 1;

alter index shippingplate_location storage(pctincrease 0 maxextents unlimited);
alter index shippingplate_location rebuild pctfree 1;

alter index shippingplate_order storage(pctincrease 0 maxextents unlimited);
alter index shippingplate_order rebuild pctfree 1;

alter index shippingplate_subtask storage(pctincrease 0 maxextents unlimited);
alter index shippingplate_subtask rebuild pctfree 1;

alter index shippingplate_unique storage(pctincrease 0 maxextents unlimited);
alter index shippingplate_unique rebuild pctfree 1;

alter index stateorprovince_idx storage(pctincrease 0 maxextents unlimited);
alter index stateorprovince_idx rebuild pctfree 1;

alter index storagetypes_idx storage(pctincrease 0 maxextents unlimited);
alter index storagetypes_idx rebuild pctfree 1;

alter index subtasks_lpid storage(pctincrease 0 maxextents unlimited);
alter index subtasks_lpid rebuild pctfree 1;

alter index subtasks_taskid storage(pctincrease 0 maxextents unlimited);
alter index subtasks_taskid rebuild pctfree 1;

alter index systemdefaults_unique storage(pctincrease 0 maxextents unlimited);
alter index systemdefaults_unique rebuild pctfree 1;

alter index tabledefs_unique storage(pctincrease 0 maxextents unlimited);
alter index tabledefs_unique rebuild pctfree 1;

alter index taskpriorities_idx storage(pctincrease 0 maxextents unlimited);
alter index taskpriorities_idx rebuild pctfree 1;

alter index taskrequestqueues_idx storage(pctincrease 0 maxextents unlimited);
alter index taskrequestqueues_idx rebuild pctfree 1;

alter index tasks_load_idx storage(pctincrease 0 maxextents unlimited);
alter index tasks_load_idx rebuild pctfree 1;

alter index tasks_unique storage(pctincrease 0 maxextents unlimited);
alter index tasks_unique rebuild pctfree 1;

alter index tasktypes_idx storage(pctincrease 0 maxextents unlimited);
alter index tasktypes_idx rebuild pctfree 1;

alter index unitsofmeasure_idx storage(pctincrease 0 maxextents unlimited);
alter index unitsofmeasure_idx rebuild pctfree 1;

alter index usercustomer_unique storage(pctincrease 0 maxextents unlimited);
alter index usercustomer_unique rebuild pctfree 1;

alter index userdetail_unique storage(pctincrease 0 maxextents unlimited);
alter index userdetail_unique rebuild pctfree 1;

alter index userfacility_unique storage(pctincrease 0 maxextents unlimited);
alter index userfacility_unique rebuild pctfree 1;

alter index userforms_unique storage(pctincrease 0 maxextents unlimited);
alter index userforms_unique rebuild pctfree 1;

alter index usergrids_unique storage(pctincrease 0 maxextents unlimited);
alter index usergrids_unique rebuild pctfree 1;

alter index userheader_unique storage(pctincrease 0 maxextents unlimited);
alter index userheader_unique rebuild pctfree 1;

alter index userhistory_idx storage(pctincrease 0 maxextents unlimited);
alter index userhistory_idx rebuild pctfree 1;

alter index userstatus_idx storage(pctincrease 0 maxextents unlimited);
alter index userstatus_idx rebuild pctfree 1;

alter index wavestatus_idx storage(pctincrease 0 maxextents unlimited);
alter index wavestatus_idx rebuild pctfree 1;

alter index waves_facility storage(pctincrease 0 maxextents unlimited);
alter index waves_facility rebuild pctfree 1;

alter index waves_status storage(pctincrease 0 maxextents unlimited);
alter index waves_status rebuild pctfree 1;

alter index waves_unique storage(pctincrease 0 maxextents unlimited);
alter index waves_unique rebuild pctfree 1;

alter index whentoverifyporeceipts_idx storage(pctincrease 0 maxextents unlimited);
alter index whentoverifyporeceipts_idx rebuild pctfree 1;

alter index zone_unique storage(pctincrease 0 maxextents unlimited);
alter index zone_unique rebuild pctfree 1;
