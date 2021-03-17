CREATE OR REPLACE package body zcloneitem as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--

CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

CURSOR C_ITEM(in_cust varchar2, in_item varchar2)
 RETURN custitem%rowtype
IS
    SELECT *
      FROM custitem
     WHERE custid = in_cust
       AND item = in_item;

CURSOR C_WOC(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERCLASSES
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_WOI(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERINSTRUCTIONS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_WOD(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM WORKORDERDESTINATIONS
     WHERE custid = in_custid
       AND item = in_item;

--
-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- clone_item
--
----------------------------------------------------------------------
PROCEDURE clone_item
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_new_custid IN      varchar2,
    in_new_item   IN      varchar2,
    in_userid     IN      varchar2,
    out_errmsg  OUT     varchar2
)
IS

CURSOR C_ITEM(in_cust varchar2, in_item varchar2)
 RETURN custitem%rowtype
IS
    SELECT *
      FROM custitem
     WHERE custid = in_cust
       AND item = in_item;

CURSOR C_ITEMALIAS(in_custid varchar2, in_item varchar2)
 RETURN custitemalias%rowtype
IS
    SELECT *
      FROM custitemalias
     WHERE custid = in_custid
       AND itemalias = in_item;


CURSOR C_PG(in_custid varchar2, in_group varchar2)
RETURN custproductgroup%rowtype
IS
    SELECT *
      FROM custproductgroup
     WHERE custid = in_custid
       AND productgroup = in_group;

CURSOR C_RG(in_custid varchar2, in_group varchar2)
RETURN custrategroup%rowtype
IS
    SELECT *
      FROM custrategroup
     WHERE custid = in_custid
       AND rategroup = in_group;

CURSOR C_BOL(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMBOLCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_OUT(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMOUTCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CURSOR C_IN(in_custid varchar2, in_item varchar2)
IS
    SELECT *
      FROM CUSTITEMINCOMMENTS
     WHERE custid = in_custid
       AND item = in_item;

CUST customer%rowtype;

ITM custitem%rowtype;
NEWITM custitem%rowtype;

ALIAS custitemalias%rowtype;

PG custproductgroup%rowtype;
RG custrategroup%rowtype;

cmt1 long;


BEGIN

   if rtrim(in_new_custid) is null then
     out_errmsg := 'A new Customer ID must be specified';
     return;
   end if;

   if rtrim(in_new_item) is null then
     out_errmsg := 'A new Item identifier must be specified';
     return;
   end if;

-- If new customer verify it is a valid customer
    if in_custid != in_new_custid then
       CUST := null;
       OPEN C_CUST(in_new_custid);
       FETCH C_CUST into CUST;
       CLOSE C_CUST;
       if CUST.custid is null then
          out_errmsg := 'Invalid new customer ID:'||in_new_custid;
          return;
       end if;
    end if;

    ITM := null;
    OPEN C_ITEM(in_custid, in_item);
    FETCH C_ITEM into ITM;
    CLOSE C_ITEM;

    if ITM.item is null then
       out_errmsg := 'Invalid item: does not exist.';
       return;
    end if;

    NEWITM := null;
    OPEN C_ITEM(in_new_custid, in_new_item);
    FETCH C_ITEM into NEWITM;
    CLOSE C_ITEM;

    if NEWITM.item is not null then
       out_errmsg := 'Invalid new item: already exists.';
       return;
    end if;

    ALIAS := null;
    OPEN C_ITEMALIAS(in_new_custid, in_new_item);
    FETCH C_ITEMALIAS into ALIAS;
    CLOSE C_ITEMALIAS;

    if ALIAS.item is not null then
       out_errmsg := 'Invalid new item: is alias for '
                  ||ALIAS.custid||'/'||ALIAS.item||'.';
       return;
    end if;


-- Begin set up of new item


    NEWITM := ITM;

    NEWITM.custid := in_new_custid;
    NEWITM.item := in_new_item;
    NEWITM.lastuser := in_userid;
    NEWITM.lastupdate := sysdate;

-- if changing customer verify rategroup and productgroup
   if in_custid != in_new_custid then
      PG := null;
      OPEN C_PG(in_new_custid, NEWITM.productgroup);
      FETCH C_PG into PG;
      CLOSE C_PG;

      NEWITM.productgroup := PG.productgroup;

      RG := null;
      OPEN C_RG(in_new_custid, NEWITM.rategroup);
      FETCH C_RG into RG;
      CLOSE C_RG;

      NEWITM.rategroup := nvl(RG.rategroup,'Invalid');


   end if;


    insert into custitem
    (
        custid,
        item,
        descr,
        abbrev,
        status,
        rategroup,
        baseuom,
        displayuom,
        lastuser,
        lastupdate,
        shelflife,
        stackheight,
        countryof,
        expiryaction,
        velocity,
        lotrequired,
        lotrftag,
        serialrequired,
        serialrftag,
        user1required,
        user1rftag,
        user2required,
        user2rftag,
        user3required,
        user3rftag,
        mfgdaterequired,
        expdaterequired,
        nodamaged,
        countryrequired,
        weight,
        cube,
        useramt1,
        useramt2,
        labeluom,
        profid,
        stackheightuom,
        labelprofile,
        recvinvstatus,
        productgroup,
        backorder,
        allowsub,
        hazardous,
        invstatusind,
        invstatus,
        invclassind,
        inventoryclass,
        qtytype,
        nmfc,
        tareweight,
        allocrule,
        variancepct,
        weightcheckrequired,
        ordercheckrequired,
        fifowindowdays,
        putawayconfirmation,
        iskit,
        picktotype,
        cartontype,
        cyclecountinterval,
        lottrackinggeneration,
        subslprsnrequired,
        lotsumreceipt,
        lotsumrenewal,
        lotsumbol,
        ltlfc,
        lotfmtruleid,
        lotfmtaction,
        serialfmtruleid,
        serialfmtaction,
        user1fmtruleid,
        user1fmtaction,
        user2fmtruleid,
        user2fmtaction,
        user3fmtruleid,
        user3fmtaction,
        maxqtyof1,
        primaryhazardclass,
        secondaryhazardclass,
        primarychemcode,
        secondarychemcode,
        tertiarychemcode,
        quaternarychemcode,
        parseentryfield,
        parseruleid,
        parseruleaction,
        returnsdisposition,
        ctostoprefix,
        lotsumaccess,
        critlevel1,
        critlevel2,
        critlevel3,
        serialasncapture,
        user1asncapture,
        user2asncapture,
        user3asncapture,
        length,
        width,
        height,
        reorderqty,
        needs_review_yn,
        use_catch_weights,
        catch_weight_out_cap_type,
        catch_weight_in_cap_type,
        nmfc_article,
        tms_uom,
        tms_commodity_code,
        labelqty,
        itmpassthruchar01,
        itmpassthruchar02,
        itmpassthruchar03,
        itmpassthruchar04,
        itmpassthrunum01,
        itmpassthrunum02,
        itmpassthrunum03,
        itmpassthrunum04,
        sip_carton_uom,
        imoprimarychemcode,
        imosecondarychemcode,
        imotertiarychemcode,
        imoquaternarychemcode,
        iataprimarychemcode,
        iatasecondarychemcode,
        iatatertiarychemcode,
        iataquaternarychemcode,
        unitsofstorage,
        require_cyclecount_item,
        use_fifo,
        msdsformat,
        printmsds,
        prtlps_on_load_arrival,
        prtlps_profid,
        prtlps_def_handling,
        prtlps_putaway_dir,
        allow_uom_chgs,
        sara_pt_gas_yn,
        sara_pt_mixture_yn,
        sara_pt_liquid_yn,
        sara_pt_pure_yn,
        sara_pt_solid_yn,
        sara_hc_delayed_yn,
        sara_hc_immediate_yn,
        sara_hc_fire_yn,
        sara_hc_reactivity_yn,
        sara_hc_pressure_yn,
        sara_ct_container,
        sara_ct_pressure,
        sara_ct_temperature,
        sara_trade_secret_yn,
        sara_cas_number1,
        sara_cas_percent1,
        sara_cas_number2,
        sara_cas_percent2,
        sara_cas_number3,
        sara_cas_percent3,
        sara_cas_number4,
        sara_cas_percent4,
        sara_cas_number5,
        sara_cas_percent5,
        sara_cas_number6,
        sara_cas_percent6,
        sara_cas_number7,
        sara_cas_percent7,
        sara_cas_number8,
        sara_cas_percent8,
        sara_cas_number9,
        sara_cas_percent9,
        sara_cas_number10,
        sara_cas_percent10,
        sara_cas_number11,
        sara_cas_percent11,
        sara_cas_number12,
        sara_cas_percent12,
        sara_cas_number13,
        sara_cas_percent13,
        sara_cas_number14,
        sara_cas_percent14,
        sara_cas_number15,
        sara_cas_percent15,
        sara_cas_number16,
        sara_cas_percent16,
        sara_cas_number17,
        sara_cas_percent17,
        sara_cas_number18,
        sara_cas_percent18,
        sara_cas_number19,
        sara_cas_percent19,
        sara_cas_number20,
        sara_cas_percent20,
        pallet_qty,
        pallet_uom,
        limit_pallet_to_qty_yn,
        putaway_highest_whole_uom_yn,
        unkitted_class,
        require_phyinv_item
      )
      values
      (
        NEWITM.custid,
        NEWITM.item,
        NEWITM.descr,
        NEWITM.abbrev,
        NEWITM.status,
        NEWITM.rategroup,
        NEWITM.baseuom,
        NEWITM.displayuom,
        NEWITM.lastuser,
        NEWITM.lastupdate,
        NEWITM.shelflife,
        NEWITM.stackheight,
        NEWITM.countryof,
        NEWITM.expiryaction,
        NEWITM.velocity,
        NEWITM.lotrequired,
        NEWITM.lotrftag,
        NEWITM.serialrequired,
        NEWITM.serialrftag,
        NEWITM.user1required,
        NEWITM.user1rftag,
        NEWITM.user2required,
        NEWITM.user2rftag,
        NEWITM.user3required,
        NEWITM.user3rftag,
        NEWITM.mfgdaterequired,
        NEWITM.expdaterequired,
        NEWITM.nodamaged,
        NEWITM.countryrequired,
        NEWITM.weight,
        NEWITM.cube,
        NEWITM.useramt1,
        NEWITM.useramt2,
        NEWITM.labeluom,
        NEWITM.profid,
        NEWITM.stackheightuom,
        NEWITM.labelprofile,
        NEWITM.recvinvstatus,
        NEWITM.productgroup,
        NEWITM.backorder,
        NEWITM.allowsub,
        NEWITM.hazardous,
        NEWITM.invstatusind,
        NEWITM.invstatus,
        NEWITM.invclassind,
        NEWITM.inventoryclass,
        NEWITM.qtytype,
        NEWITM.nmfc,
        NEWITM.tareweight,
        NEWITM.allocrule,
        NEWITM.variancepct,
        NEWITM.weightcheckrequired,
        NEWITM.ordercheckrequired,
        NEWITM.fifowindowdays,
        NEWITM.putawayconfirmation,
        NEWITM.iskit,
        NEWITM.picktotype,
        NEWITM.cartontype,
        NEWITM.cyclecountinterval,
        NEWITM.lottrackinggeneration,
        NEWITM.subslprsnrequired,
        NEWITM.lotsumreceipt,
        NEWITM.lotsumrenewal,
        NEWITM.lotsumbol,
        NEWITM.ltlfc,
        NEWITM.lotfmtruleid,
        NEWITM.lotfmtaction,
        NEWITM.serialfmtruleid,
        NEWITM.serialfmtaction,
        NEWITM.user1fmtruleid,
        NEWITM.user1fmtaction,
        NEWITM.user2fmtruleid,
        NEWITM.user2fmtaction,
        NEWITM.user3fmtruleid,
        NEWITM.user3fmtaction,
        NEWITM.maxqtyof1,
        NEWITM.primaryhazardclass,
        NEWITM.secondaryhazardclass,
        NEWITM.primarychemcode,
        NEWITM.secondarychemcode,
        NEWITM.tertiarychemcode,
        NEWITM.quaternarychemcode,
        NEWITM.parseentryfield,
        NEWITM.parseruleid,
        NEWITM.parseruleaction,
        NEWITM.returnsdisposition,
        NEWITM.ctostoprefix,
        NEWITM.lotsumaccess,
        NEWITM.critlevel1,
        NEWITM.critlevel2,
        NEWITM.critlevel3,
        NEWITM.serialasncapture,
        NEWITM.user1asncapture,
        NEWITM.user2asncapture,
        NEWITM.user3asncapture,
        NEWITM.length,
        NEWITM.width,
        NEWITM.height,
        NEWITM.reorderqty,
        NEWITM.needs_review_yn,
        NEWITM.use_catch_weights,
        NEWITM.catch_weight_out_cap_type,
        NEWITM.catch_weight_in_cap_type,
        NEWITM.nmfc_article,
        NEWITM.tms_uom,
        NEWITM.tms_commodity_code,
        NEWITM.labelqty,
        NEWITM.itmpassthruchar01,
        NEWITM.itmpassthruchar02,
        NEWITM.itmpassthruchar03,
        NEWITM.itmpassthruchar04,
        NEWITM.itmpassthrunum01,
        NEWITM.itmpassthrunum02,
        NEWITM.itmpassthrunum03,
        NEWITM.itmpassthrunum04,
        NEWITM.sip_carton_uom,
        NEWITM.imoprimarychemcode,
        NEWITM.imosecondarychemcode,
        NEWITM.imotertiarychemcode,
        NEWITM.imoquaternarychemcode,
        NEWITM.iataprimarychemcode,
        NEWITM.iatasecondarychemcode,
        NEWITM.iatatertiarychemcode,
        NEWITM.iataquaternarychemcode,
        NEWITM.unitsofstorage,
        NEWITM.require_cyclecount_item,
        NEWITM.use_fifo,
        NEWITM.msdsformat,
        NEWITM.printmsds,
        NEWITM.prtlps_on_load_arrival,
        NEWITM.prtlps_profid,
        NEWITM.prtlps_def_handling,
        NEWITM.prtlps_putaway_dir,
        NEWITM.allow_uom_chgs,
        NEWITM.sara_pt_gas_yn,
        NEWITM.sara_pt_mixture_yn,
        NEWITM.sara_pt_liquid_yn,
        NEWITM.sara_pt_pure_yn,
        NEWITM.sara_pt_solid_yn,
        NEWITM.sara_hc_delayed_yn,
        NEWITM.sara_hc_immediate_yn,
        NEWITM.sara_hc_fire_yn,
        NEWITM.sara_hc_reactivity_yn,
        NEWITM.sara_hc_pressure_yn,
        NEWITM.sara_ct_container,
        NEWITM.sara_ct_pressure,
        NEWITM.sara_ct_temperature,
        NEWITM.sara_trade_secret_yn,
        NEWITM.sara_cas_number1,
        NEWITM.sara_cas_percent1,
        NEWITM.sara_cas_number2,
        NEWITM.sara_cas_percent2,
        NEWITM.sara_cas_number3,
        NEWITM.sara_cas_percent3,
        NEWITM.sara_cas_number4,
        NEWITM.sara_cas_percent4,
        NEWITM.sara_cas_number5,
        NEWITM.sara_cas_percent5,
        NEWITM.sara_cas_number6,
        NEWITM.sara_cas_percent6,
        NEWITM.sara_cas_number7,
        NEWITM.sara_cas_percent7,
        NEWITM.sara_cas_number8,
        NEWITM.sara_cas_percent8,
        NEWITM.sara_cas_number9,
        NEWITM.sara_cas_percent9,
        NEWITM.sara_cas_number10,
        NEWITM.sara_cas_percent10,
        NEWITM.sara_cas_number11,
        NEWITM.sara_cas_percent11,
        NEWITM.sara_cas_number12,
        NEWITM.sara_cas_percent12,
        NEWITM.sara_cas_number13,
        NEWITM.sara_cas_percent13,
        NEWITM.sara_cas_number14,
        NEWITM.sara_cas_percent14,
        NEWITM.sara_cas_number15,
        NEWITM.sara_cas_percent15,
        NEWITM.sara_cas_number16,
        NEWITM.sara_cas_percent16,
        NEWITM.sara_cas_number17,
        NEWITM.sara_cas_percent17,
        NEWITM.sara_cas_number18,
        NEWITM.sara_cas_percent18,
        NEWITM.sara_cas_number19,
        NEWITM.sara_cas_percent19,
        NEWITM.sara_cas_number20,
        NEWITM.sara_cas_percent20,
        NEWITM.pallet_qty,
        NEWITM.pallet_uom,
        NEWITM.limit_pallet_to_qty_yn,
        NEWITM.putaway_highest_whole_uom_yn,
        NEWITM.unkitted_class,
        NEWITM.require_phyinv_item
      );

   for crec in C_BOL(in_custid, in_item) loop
     insert into custitembolcomments
      (
        custid,
        item,
        consignee,
        comment1,
        lastuser,
        lastupdate
      )
     values
      (
        in_new_custid,
        in_new_item,
        crec.consignee,
        crec.comment1,
        in_userid,
        sysdate
      );

   end loop;

   for crec in C_OUT(in_custid, in_item) loop
     insert into custitemoutcomments
      (
        custid,
        item,
        consignee,
        comment1,
        rfautodisplay,
        lastuser,
        lastupdate
      )
     values
      (
        in_new_custid,
        in_new_item,
        crec.consignee,
        crec.comment1,
        crec.rfautodisplay,
        in_userid,
        sysdate
      );

   end loop;

   for crec in C_IN(in_custid, in_item) loop
     insert into custitemincomments
      (
        custid,
        item,
        comment1,
        rfautodisplay,
        lastuser,
        lastupdate
      )
     values
      (
        in_new_custid,
        in_new_item,
        crec.comment1,
        crec.rfautodisplay,
        in_userid,
        sysdate
      );

   end loop;

-- Custitemlabelprofiles
   insert into custitemlabelprofiles
     (
        custid,
        item,
        consignee,
        profid,
        lastuser,
        lastupdate
     )
     select
        in_new_custid,
        in_new_item,
        consignee,
        profid,
        in_userid,
        sysdate
       from custitemlabelprofiles
      where custid = in_custid
        and item = in_item;

-- Custitemuom
   insert into custitemuom
     (
        custid,
        item,
        sequence,
        qty,
        fromuom,
        touom,
        putawayprofile,
        picktotype,
        velocity,
        cyclecountinterval,
        tareweight,
        cartontype,
        weight,
        cube,
        lastuser,
        lastupdate,
        length,
        width,
        height
     )
     select
        in_new_custid,
        in_new_item,
        sequence,
        qty,
        fromuom,
        touom,
        putawayprofile,
        picktotype,
        velocity,
        cyclecountinterval,
        tareweight,
        cartontype,
        weight,
        cube,
        in_userid,
        sysdate,
        length,
        width,
        height
       from custitemuom
      where custid = in_custid
        and item = in_item;

-- Custitemuomuos
   insert into custitemuomuos
     (
        custid,
        item,
        uomseq,
        unitofmeasure,
        uosseq,
        unitofstorage,
        uominuos,
        lastuser,
        lastupdate
     )
     select
        in_new_custid,
        in_new_item,
        uomseq,
        unitofmeasure,
        uosseq,
        unitofstorage,
        uominuos,
        in_userid,
        sysdate
       from custitemuomuos
      where custid = in_custid
        and item = in_item;

-- Custitemfacility
   insert into custitemfacility
     (
        custid,
        item,
        facility,
        profid,
        allocrule,
        replallocrule,
        lastuser,
        lastupdate
     )
     select
        in_new_custid,
        in_new_item,
        facility,
        profid,
        allocrule,
        replallocrule,
        in_userid,
        sysdate
       from custitemfacility
      where custid = in_custid
        and item = in_item;

-- Itempickfronts
   insert into itempickfronts
     (
        custid,
        item,
        facility,
        pickfront,
        pickuom,
        replenishqty,
        replenishuom,
        maxqty,
        maxuom,
        replenishwithuom,
        topoffqty,
        topoffuom,
        lastuser,
        lastupdate,
        dynamic
     )
     select
        in_new_custid,
        in_new_item,
        facility,
        pickfront,
        pickuom,
        replenishqty,
        replenishuom,
        maxqty,
        maxuom,
        replenishwithuom,
        topoffqty,
        topoffuom,
        in_userid,
        sysdate,
        dynamic
       from itempickfronts
      where custid = in_custid
        and item = in_item;

-- Kitting stuff only if same custid
   if in_custid = in_new_custid then
  -- Workordercomponents
     insert into workordercomponents
     (
        custid,
        item,
        component,
        qty,
        kitted_class,
        lastuser,
        lastupdate
     )
     select
        in_new_custid,
        in_new_item,
        component,
        qty,
        kitted_class,
        in_userid,
        sysdate
       from workordercomponents
      where custid = in_custid
        and item = in_item;

  -- custitemminmax
     insert into custitemminmax
     (
        custid,
        item,
        facility,
        qtymin,
        qtymax,
        qtyworkordermin,
        kitted_class,
        lastuser,
        lastupdate
     )
     select
        in_new_custid,
        in_new_item,
        facility,
        qtymin,
        qtymax,
        qtyworkordermin,
        kitted_class,
        in_userid,
        sysdate
       from custitemminmax
      where custid = in_custid
        and item = in_item;

     for crec in C_WOC(in_custid, in_item) loop
       insert into workorderclasses
        (
          custid,
          item,
          kitted_class,
          descr,
          lastuser,
          lastupdate
        )
       values
        (
          in_new_custid,
          in_new_item,
          crec.kitted_class,
          crec.descr,
          in_userid,
          sysdate
        );

     end loop;
     for crec in C_WOI(in_custid, in_item) loop
       insert into workorderinstructions
        (
          seq,
          parent,
          action,
          notes,
          custid,
          item,
          title,
          qty,
          component,
          kitted_class,
          lastuser,
          lastupdate
        )
       values
        (
          crec.seq,
          crec.parent,
          crec.action,
          crec.notes,
          in_new_custid,
          in_new_item,
          crec.title,
          crec.qty,
          crec.component,
          crec.kitted_class,
          in_userid,
          sysdate
        );

     end loop;

     for crec in C_WOD(in_custid, in_item) loop
       insert into workorderdestinations
        (
          custid,
          item,
          kitted_class,
          seq,
          facility,
          location,
          loctype,
          lastuser,
          lastupdate
        )
       values
        (
          in_new_custid,
          in_new_item,
          crec.kitted_class,
          crec.seq,
          crec.facility,
          crec.location,
          crec.loctype,
          in_userid,
          sysdate
        );

     end loop;


   end if;

   out_errmsg := 'OKAY';
EXCEPTION WHEN OTHERS THEN
  out_errmsg := sqlerrm;
END clone_item;

PROCEDURE clone_kit
(
    in_from_custid   IN      varchar2,
    in_from_item     IN      varchar2,
    in_to_custid     IN      varchar2,
    in_to_item       IN      varchar2,
    in_userid        IN      varchar2,
    out_errmsg       OUT     varchar2
) is

FROMCUST C_CUST%rowtype;
TOCUST   C_CUST%rowtype;
FROMITM  C_ITEM%rowtype;
TOITM    C_ITEM%rowtype;

BEGIN

   out_errmsg := 'OKAY';

   if rtrim(in_from_custid) is null then
     out_errmsg := 'A ''from'' Customer ID must be specified';
     return;
   end if;

   if rtrim(in_from_item) is null then
     out_errmsg := 'A ''from'' Item identifier must be specified';
     return;
   end if;

   if rtrim(in_to_custid) is null then
     out_errmsg := 'A ''to'' Customer ID must be specified';
     return;
   end if;

   if rtrim(in_to_item) is null then
     out_errmsg := 'A ''to'' Item identifier must be specified';
     return;
   end if;

   FROMCUST := null;
   OPEN C_CUST(in_from_custid);
   FETCH C_CUST into FROMCUST;
   CLOSE C_CUST;
   if FROMCUST.custid is null then
      out_errmsg := 'Invalid ''from'' Customer ID:'|| in_from_custid;
      return;
   end if;

   TOCUST := null;
   OPEN C_CUST(in_to_custid);
   FETCH C_CUST into TOCUST;
   CLOSE C_CUST;
   if TOCUST.custid is null then
      out_errmsg := 'Invalid ''to'' Customer ID:'|| in_to_custid;
      return;
   end if;

   FROMITM := null;
   OPEN C_ITEM(in_from_custid, in_from_item);
   FETCH C_ITEM into FROMITM;
   CLOSE C_ITEM;

   if FROMITM.item is null then
      out_errmsg := 'Invalid ''from'' item: does not exist.';
      return;
   end if;

   TOITM := null;
   OPEN C_ITEM(in_to_custid, in_to_item);
   FETCH C_ITEM into TOITM;
   CLOSE C_ITEM;

   if TOITM.item is null then
      out_errmsg := 'Invalid ''TO'' item: does not exist.';
      return;
   end if;

   if in_from_custid = in_to_custid and
      in_from_item = in_to_item then
     out_errmsg := 'The ''from'' and ''to'' items must be different';
     return;
   end if;

   if FROMITM.iskit <> TOITM.iskit then
     out_errmsg := 'The ''from'' and ''to'' items must have the same kit type';
     return;
   end if;

   delete from workorderclasses
         where custid = in_to_custid
           and item = in_to_item;

   delete from workordercomponents
         where custid = in_to_custid
           and item = in_to_item;

   delete from workorderinstructions
         where custid = in_to_custid
           and item = in_to_item;

   delete from workorderdestinations
         where custid = in_to_custid
           and item = in_to_item;

   delete from custitemminmax
         where custid = in_to_custid
           and item = in_to_item;

   insert into workordercomponents
   (
      custid,
      item,
      component,
      qty,
      kitted_class,
      lastuser,
      lastupdate
   )
   select
      in_to_custid,
      in_to_item,
      component,
      qty,
      kitted_class,
      in_userid,
      sysdate
     from workordercomponents
    where custid = in_from_custid
      and item = in_from_item;

  -- custitemminmax
     insert into custitemminmax
     (
        custid,
        item,
        facility,
        qtymin,
        qtymax,
        qtyworkordermin,
        kitted_class,
        lastuser,
        lastupdate
     )
     select
        in_to_custid,
        in_to_item,
        facility,
        qtymin,
        qtymax,
        qtyworkordermin,
        kitted_class,
        in_userid,
        sysdate
       from custitemminmax
      where custid = in_from_custid
        and item = in_from_item;

     for crec in C_WOC(in_from_custid, in_from_item) loop
       insert into workorderclasses
        (
          custid,
          item,
          kitted_class,
          descr,
          lastuser,
          lastupdate
        )
       values
        (
          in_to_custid,
          in_to_item,
          crec.kitted_class,
          crec.descr,
          in_userid,
          sysdate
        );

     end loop;

     for crec in C_WOI(in_from_custid, in_from_item) loop
       insert into workorderinstructions
        (
          seq,
          parent,
          action,
          notes,
          custid,
          item,
          title,
          qty,
          component,
          kitted_class,
          lastuser,
          lastupdate
        )
       values
        (
          crec.seq,
          crec.parent,
          crec.action,
          crec.notes,
          in_to_custid,
          in_to_item,
          crec.title,
          crec.qty,
          crec.component,
          crec.kitted_class,
          in_userid,
          sysdate
        );

     end loop;

     for crec in C_WOD(in_from_custid, in_from_item) loop
       insert into workorderdestinations
        (
          custid,
          item,
          kitted_class,
          seq,
          facility,
          location,
          loctype,
          lastuser,
          lastupdate
        )
       values
        (
          in_to_custid,
          in_to_item,
          crec.kitted_class,
          crec.seq,
          crec.facility,
          crec.location,
          crec.loctype,
          in_userid,
          sysdate
        );

     end loop;

EXCEPTION WHEN OTHERS THEN
  out_errmsg := sqlerrm;
END clone_kit;

end zcloneitem;
/
show error package body zcloneitem;

exit;
