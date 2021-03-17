--
-- $Id$
--

create or replace type cdata as object
(
    orderid     number(9),
    shipid      number(2),
    loadno      number(7),
    stopno      number(7),
    shipno      number(7),
    lpid        varchar2(15),
    custid      varchar2(10),
    item        varchar2(20),
    lotnumber   varchar2(30),
    quantity    number(7),
    reason      varchar2(10),
    userid      varchar2(12),
    char01      varchar2(100),
    char02      varchar2(100),
    char03      varchar2(100),
    num01       number,
    num02       number,
    num03       number,
    out_no      number,
    out_char    varchar2(100)
)
/


create table alps.accountperiod
(
    cutoffdate date             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.activity
(
    code         varchar2(4)  not null,
    descr        varchar2(32) not null,
    abbrev       varchar2(12) not null,
    glacct       varchar2(20) not null,
    lastuser     varchar2(12)     null,
    lastupdate   date             null,
    mincategory  varchar2(1)      null,
    revenuegroup varchar2(4)      null,
    irisclass    varchar2(8)      null,
    irisname     varchar2(4)      null,
    irischarge   varchar2(1)      null,
    iristype     varchar2(4)      null,
    irisorder    number(3)        null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.activityminimumcategory
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.adjustmentreasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.aisle
(
    facility   varchar2(3)  not null,
    aisleid    varchar2(5)  not null,
    aislen     varchar2(5)      null,
    aislene    varchar2(5)      null,
    aislee     varchar2(5)      null,
    aislese    varchar2(5)      null,
    aisles     varchar2(5)      null,
    aislesw    varchar2(5)      null,
    aislew     varchar2(5)      null,
    aislenw    varchar2(5)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.allocrulesdtl
(
    facility       varchar2(3)      null,
    allocrule      varchar2(10) not null,
    priority       number(7)        null,
    invstatus      varchar2(2)      null,
    inventoryclass varchar2(2)      null,
    uom            varchar2(4)      null,
    qtymin         number(7)        null,
    qtymax         number(7)        null,
    pickingzone    varchar2(10)     null,
    usefwdpick     char(1)          null,
    lifofifo       char(1)          null,
    datetype       char(1)          null,
    picktoclean    char(1)          null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    wholeunitsonly char(1)          null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.allocruleshdr
(
    facility   varchar2(3)      null,
    allocrule  varchar2(10) not null,
    descr      varchar2(36)     null,
    abbrev     varchar2(12)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.applocks
(
    lockid     varchar2(36)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.appmsgs
(
    created    date          not null,
    author     varchar2(12)  not null,
    facility   varchar2(3)       null,
    custid     varchar2(10)      null,
    msgtext    varchar2(255)     null,
    status     varchar2(4)       null,
    lastuser   varchar2(12)      null,
    lastupdate date              null,
    msgtype    varchar2(1)       null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.app_msgs_contacts
(
    author      varchar2(12)  not null,
    msgtype     varchar2(3)       null,
    notify      varchar2(12)      null,
    notify_type varchar2(10)      null,
    lastuser    varchar2(12)      null,
    lastupdate  date              null,
    comments    varchar2(100)     null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.asncartondtl
(
    orderid        number(9)     not null,
    shipid         number(7)     not null,
    item           varchar2(20)  not null,
    lotnumber      varchar2(30)      null,
    serialnumber   varchar2(30)      null,
    useritem1      varchar2(20)      null,
    useritem2      varchar2(20)      null,
    useritem3      varchar2(20)      null,
    inventoryclass varchar2(2)       null,
    uom            varchar2(4)       null,
    qty            number(7)         null,
    trackingno     varchar2(22)      null,
    custreference  varchar2(30)      null,
    importfileid   varchar2(255)     null,
    created        date              null,
    lastuser       varchar2(12)      null,
    lastupdate     date              null,
    expdate        date              null,
    weight         number(13,4)
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.asofinventory
(
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    item           varchar2(20) not null,
    lotnumber      varchar2(30)     null,
    uom            varchar2(4)  not null,
    effdate        date             null,
    previousqty    number(10)       null,
    currentqty     number(10)       null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    invstatus      varchar2(2)      null,
    inventoryclass varchar2(2)      null,
    previousweight number(13,4)     null,
    currentweight  number(13,4)     null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.asofinventorydtl
(
    facility         varchar2(3)  not null,
    custid           varchar2(10) not null,
    item             varchar2(20) not null,
    lotnumber        varchar2(30)     null,
    uom              varchar2(4)  not null,
    effdate          date             null,
    adjustment       number(10)       null,
    reason           varchar2(12)     null,
    lastuser         varchar2(12)     null,
    lastupdate       date             null,
    invstatus        varchar2(2)      null,
    inventoryclass   varchar2(2)      null,
    trantype         varchar2(2)      null,
    weightadjustment number(13,4)     null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.autopromptvalues
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.backorderpolicy
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.backoutaccessorial
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.backoutmisc
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.backoutreceipt
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.backoutrenewal
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.batchtasks
(
    taskid         number(15)   not null,
    tasktype       varchar2(2)      null,
    facility       varchar2(3)      null,
    fromsection    varchar2(10)     null,
    fromloc        varchar2(10)     null,
    fromprofile    varchar2(2)      null,
    tosection      varchar2(10)     null,
    toloc          varchar2(10)     null,
    toprofile      varchar2(2)      null,
    touserid       varchar2(10)     null,
    custid         varchar2(10)     null,
    item           varchar2(20)     null,
    lpid           varchar2(15)     null,
    uom            varchar2(4)      null,
    qty            number(7)        null,
    locseq         number(7)        null,
    loadno         number(7)        null,
    stopno         number(7)        null,
    shipno         number(7)        null,
    orderid        number(9)        null,
    shipid         number(2)        null,
    orderitem      varchar2(20)     null,
    orderlot       varchar2(30)     null,
    priority       varchar2(1)      null,
    prevpriority   varchar2(1)      null,
    curruserid     varchar2(10)     null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    pickuom        varchar2(4)      null,
    pickqty        number(7)        null,
    picktotype     varchar2(4)      null,
    wave           number(9)        null,
    pickingzone    varchar2(10)     null,
    cartontype     varchar2(4)      null,
    weight         number(13,4)     null,
    cube           number(10,4)     null,
    staffhrs       number(10,4)     null,
    cartonseq      number(4)        null,
    shippinglpid   varchar2(15)     null,
    shippingtype   varchar2(2)      null,
    invstatus      varchar2(2)      null,
    inventoryclass varchar2(2)      null,
    qtytype        char(1)          null,
    lotnumber      varchar2(30)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.billbylocationactivity
(
    code       varchar2(3)  not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.billingmethod
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.billpalletcnt
(
    facility   varchar2(3)  not null,
    custid     varchar2(10) not null,
    effdate    date         not null,
    item       varchar2(20) not null,
    uom        varchar2(4)  not null,
    lotnumber  varchar2(30)     null,
    pltqty     number(20)       null,
    uomqty     number(10)       null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.billstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table bill_lot_renewal
(
    facility    varchar2(3)     not null,
    custid      varchar2(10)    not null,
    item        varchar2(20)    not null,
    lotnumber   varchar2(30),
    receiptdate date            not null,
    quantity    number(12,2),
    uom         varchar2(4),
    weight      number(13,4),
    renewalrate number(12,6),
    lastuser    varchar2(12),
    lastupdate  date
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.businessevents
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.campusidentifiers
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.cantpickreasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.cants
(
    taskid   number(15)   not null,
    nameid   varchar2(12) not null,
    cantedat date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.carrier
(
    carrier                varchar2(4)   not null,
    name                   varchar2(40)      null,
    contact                varchar2(40)      null,
    addr1                  varchar2(40)      null,
    addr2                  varchar2(40)      null,
    city                   varchar2(30)      null,
    state                  varchar2(2)       null,
    postalcode             varchar2(12)      null,
    countrycode            varchar2(3)       null,
    phone                  varchar2(25)      null,
    fax                    varchar2(25)      null,
    email                  varchar2(255)     null,
    carriertype            varchar2(1)       null,
    carrierstatus          varchar2(1)       null,
    lastuser               varchar2(12)      null,
    lastupdate             date              null,
    scac                   varchar2(4)       null,
    multiship              char(1)           null,
    enableonetimeshipto    char(1)           null,
    trackerurl             varchar2(255)     null,
    min_unused_prono_count number(12)        null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.carrierprono
(
    carrier        varchar2(4)  not null,
    seq            number(12)       null,
    prono          varchar2(20)     null,
    assign_status  char(1)          null,
    assign_time    date             null,
    assign_orderid number(9)        null,
    assign_shipid  number(2)        null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
	 zone           varchar2(32)     null
)
tablespace synapse_act_data
pctfree 10
pctused 40
/

create table alps.carrierservicecodes
(
    carrier       varchar2(4)  not null,
    servicecode   varchar2(4)  not null,
    descr         varchar2(32)     null,
    abbrev        varchar2(12)     null,
    upgradecode   varchar2(4)      null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    multishipcode varchar2(4)      null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.carrierspecialservice
(
    carrier        varchar2(4)  not null,
    servicecode    varchar2(4)  not null,
    specialservice varchar2(4)  not null,
    descr          varchar2(32)     null,
    abbrev         varchar2(12)     null,
    multishipcode  varchar2(30)     null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.carrierstageloc
(
    carrier    varchar2(4)  not null,
    facility   varchar2(3)  not null,
    stageloc   varchar2(10) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    shiptype   char(1)          null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.carrierstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table carrierzone
(
    carrier                 varchar2(4)  not null,
    zone                    varchar2(32) not null,
    min_unused_prono_count  number(12)       null,
    lastuser                varchar2(12)     null,
    lastupdate              date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.cartongroups
(
    cartongroup varchar2(4)  not null,
    code        varchar2(4)  not null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.cartontypes
(
    code        varchar2(4)  not null,
    descr       varchar2(36) not null,
    abbrev      varchar2(12) not null,
    length      number(10,4)     null,
    width       number(10,4)     null,
    height      number(10,4)     null,
    maxweight   number(13,4)     null,
    maxcube     number(10,4)     null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null,
    typeorgroup char(1)          null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.caselabels
(
    orderid   number           null,
    shipid    number           null,
    custid    varchar2(10)     null,
    item      varchar2(20)     null,
    lotnumber varchar2(30)     null,
    lpid      varchar2(15)     null,
    barcode   varchar2(20)     null,
    seq       number           null,
    seqof     number           null,
    created   date             null,
    auxtable  varchar2(30)     null,
    auxkey    varchar2(30)     null,
    quantity  number(7)        null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.catchweightoutboundcapture
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.chemicalcodes
(
    chemcode             varchar2(12)  not null,
    abbrev               varchar2(12)  not null,
    propershippingname1  varchar2(255)     null,
    propershippingname2  varchar2(255)     null,
    chemicalconstituents varchar2(255)     null,
    primaryhazardclass   varchar2(12)      null,
    secondaryhazardclass varchar2(12)      null,
    tertiaryhazardclass  varchar2(12)      null,
    naergnumber          varchar2(36)      null,
    dotbolcomment        varchar2(255)     null,
    iatabolcomment       varchar2(255)     null,
    imobolcomment        varchar2(255)     null,
    otherdescr           varchar2(255)     null,
    unnum                varchar2(20)      null,
    packinggroup         varchar2(20)      null,
    donotprintbol        varchar2(1)       null,
    lastuser             varchar2(12)      null,
    lastupdate           date              null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.chemicalcodes_old
(
    chemcode             varchar2(12)  not null,
    descr                varchar2(50)  not null,
    abbrev               varchar2(12)  not null,
    propershippingname   varchar2(50)      null,
    chemicalconstituents varchar2(255)     null,
    primaryhazardclass   varchar2(12)      null,
    secondaryhazardclass varchar2(12)      null,
    tertiaryhazardclass  varchar2(12)      null,
    naergnumber          varchar2(36)      null,
    dotbolcomment        varchar2(255)     null,
    iatabolcomment       varchar2(255)     null,
    imobolcomment        varchar2(255)     null,
    lastuser             varchar2(12)      null,
    lastupdate           date              null,
    unnum                varchar2(20)      null,
    packinggroup         varchar2(20)      null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.commitments
(
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    item           varchar2(20) not null,
    inventoryclass varchar2(2)      null,
    invstatus      varchar2(2)      null,
    status         varchar2(2)      null,
    lotnumber      varchar2(30)     null,
    uom            varchar2(4)      null,
    qty            number(16)       null,
    orderid        number(9)        null,
    shipid         number(2)        null,
    orderitem      varchar2(20)     null,
    priority       varchar2(1)      null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    orderlot       varchar2(30)     null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.commitstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.consignee
(
    consignee       varchar2(10)  not null,
    name            varchar2(40)      null,
    contact         varchar2(40)      null,
    addr1           varchar2(40)      null,
    addr2           varchar2(40)      null,
    city            varchar2(30)      null,
    state           varchar2(2)       null,
    postalcode      varchar2(12)      null,
    countrycode     varchar2(3)       null,
    phone           varchar2(25)      null,
    fax             varchar2(25)      null,
    email           varchar2(255)     null,
    consigneestatus varchar2(1)       null,
    lastuser        varchar2(12)      null,
    lastupdate      date              null,
    ltlcarrier      varchar2(4)       null,
    tlcarrier       varchar2(4)       null,
    spscarrier      varchar2(4)       null,
    billto          varchar2(1)       null,
    shipto          varchar2(1)       null,
    railcarrier     varchar2(4)       null,
    billtoconsignee varchar2(10)      null,
    shiptype        varchar2(1)       null,
    shipterms       varchar2(3)       null,
    apptrequired    char(1)           null,
    billforpallets  char(1)           null,
    masteraccount   varchar2(10)      null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.consigneecarriers
(
    consignee          varchar2(10) not null,
    shiptype           varchar2(1)      null,
    fromweight         number       not null,
    toweight           number       not null,
    carrier            varchar2(4)  not null,
    lastuser           varchar2(12)     null,
    lastupdate         date             null,
    begzip             varchar2(5)      null,
    endzip             varchar2(5)      null,
    assigned_ship_type varchar2(1),
    servicecode        varchar2(4)
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.consigneestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.controldescr
(
    controlnumber varchar2(10) not null,
    comment1      long             null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.conversions
(
    fromuom    varchar2(4)      null,
    touom      varchar2(4)      null,
    qty        number(11,4)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.counted_by_types
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.countrycodes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.countschedules
(
    schedid  number       not null,
    countid  varchar2(36) not null,
    period   varchar2(22)     null,
    datetime date             null,
    jobid    number           null,
    active   char(1)      default 'N'     null,
    facility varchar2(3)      null,
    reqtype  varchar2(12)     null,
    constraint pk1
    primary key (schedid)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custactvfacilities
(
    custid     varchar2(10)  not null,
    activity   varchar2(4)   not null,
    facilities varchar2(200)     null,
    lastuser   varchar2(12)      null,
    lastupdate date              null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custauditstageloc
(
    facility      varchar2(3)  not null,
    custid        varchar2(10) not null,
    auditstageloc varchar2(10) not null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custbilldates
(
    custid            varchar2(10) not null,
    nextrenewal       date             null,
    nextreceipt       date             null,
    nextmiscellaneous date             null,
    nextassessorial   date             null,
    lastuser          varchar2(12)     null,
    lastupdate        date             null,
    lastrenewal       date             null,
    lastreceipt       date             null,
    lastmiscellaneous date             null,
    lastassessorial   date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custcarrierprono
(
    custid     varchar2(10) not null,
    carrier    varchar2(4)  not null,
    event      varchar2(12)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act_data
pctfree 10
pctused 40
/

create table alps.custconsignee
(
    custid                      varchar2(10) not null,
    consignee                   varchar2(10) not null,
    lastuser                    varchar2(12)     null,
    lastupdate                  date             null,
    sip_tradingpartnerid        varchar2(15)     null,
    generate_order_confirmation char(1)          null,
    generate_ship_notice        char(1)          null,
    generate_ship_advice        char(1)          null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custconsigneenotice
(
    custid     varchar2(10) not null,
    shipto     varchar2(10)     null,
    ordertype  char(1)      not null,
    formatname varchar2(35) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 10
pctused 40
/

create table alps.custconsigneesipname
(
    custid     varchar2(10) not null,
    consignee  varchar2(10) not null,
    sipname    varchar2(10)     null,
    sipaddr    varchar2(4)      null,
    sipcity    varchar2(10)     null,
    sipstate   varchar2(2)      null,
    sipzip     varchar2(5)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.custdict
(
    custid     varchar2(10) not null,
    fieldname  varchar2(36) not null,
    labelvalue varchar2(36) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custdispositionfacility
(
    custid       varchar2(10) not null,
    disposition  varchar2(10) not null,
    facility     varchar2(3)  not null,
    sortationloc varchar2(10)     null,
    lastuser     varchar2(12)     null,
    lastupdate   date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custfacility
(
    custid          varchar2(10) not null,
    facility        varchar2(3)  not null,
    profid          varchar2(2)      null,
    allocrule       varchar2(10)     null,
    replallocrule   varchar2(10)     null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    returnslocation varchar2(10)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custitem
(
    custid                    varchar2(10)  not null,
    item                      varchar2(20)  not null,
    descr                     varchar2(40)  not null,
    abbrev                    varchar2(12)  not null,
    status                    varchar2(4)   not null,
    rategroup                 varchar2(10)  not null,
    baseuom                   varchar2(4)       null,
    displayuom                varchar2(4)       null,
    lastuser                  varchar2(12)      null,
    lastupdate                date              null,
    shelflife                 number(4)         null,
    stackheight               number(3)         null,
    countryof                 varchar2(3)       null,
    expiryaction              varchar2(2)       null,
    velocity                  varchar2(1)       null,
    lotrequired               varchar2(1)       null,
    lotrftag                  varchar2(3)       null,
    serialrequired            varchar2(1)       null,
    serialrftag               varchar2(3)       null,
    user1required             varchar2(1)       null,
    user1rftag                varchar2(5)       null,
    user2required             varchar2(1)       null,
    user2rftag                varchar2(5)       null,
    user3required             varchar2(1)       null,
    user3rftag                varchar2(5)       null,
    mfgdaterequired           varchar2(1)       null,
    expdaterequired           varchar2(1)       null,
    nodamaged                 varchar2(1)       null,
    countryrequired           varchar2(1)       null,
    weight                    number(13,4)      null,
    cube                      number(10,4)      null,
    useramt1                  number(10,2)      null,
    useramt2                  number(10,2)      null,
    labeluom                  varchar2(4)       null,
    profid                    varchar2(2)       null,
    stackheightuom            varchar2(4)       null,
    labelprofile              varchar2(4)       null,
    recvinvstatus             varchar2(2)       null,
    productgroup              varchar2(4)       null,
    backorder                 varchar2(2)       null,
    allowsub                  varchar2(1)       null,
    hazardous                 varchar2(1)       null,
    invstatusind              varchar2(1)       null,
    invstatus                 varchar2(255)     null,
    invclassind               varchar2(1)       null,
    inventoryclass            varchar2(255)     null,
    qtytype                   varchar2(1)       null,
    nmfc                      varchar2(12)      null,
    tareweight                number(13,4)      null,
    allocrule                 varchar2(10)      null,
    variancepct               number(3)         null,
    weightcheckrequired       char(1)           null,
    ordercheckrequired        char(1)           null,
    fifowindowdays            number(3)         null,
    putawayconfirmation       char(1)           null,
    iskit                     char(1)           null,
    picktotype                varchar2(4)       null,
    cartontype                varchar2(4)       null,
    cyclecountinterval        number(3)         null,
    lottrackinggeneration     char(1)           null,
    subslprsnrequired         char(1)           null,
    lotsumreceipt             varchar2(1)       null,
    lotsumrenewal             varchar2(1)       null,
    lotsumbol                 varchar2(1)       null,
    ltlfc                     varchar2(10)      null,
    lastcount                 date              null,
    lotfmtruleid              varchar2(10)      null,
    lotfmtaction              varchar2(1)       null,
    serialfmtruleid           varchar2(10)      null,
    serialfmtaction           varchar2(1)       null,
    user1fmtruleid            varchar2(10)      null,
    user1fmtaction            varchar2(1)       null,
    user2fmtruleid            varchar2(10)      null,
    user2fmtaction            varchar2(1)       null,
    user3fmtruleid            varchar2(10)      null,
    user3fmtaction            varchar2(1)       null,
    maxqtyof1                 varchar2(1)       null,
    primaryhazardclass        varchar2(12)      null,
    secondaryhazardclass      varchar2(12)      null,
    primarychemcode           varchar2(12)      null,
    secondarychemcode         varchar2(12)      null,
    tertiarychemcode          varchar2(12)      null,
    quaternarychemcode        varchar2(12)      null,
    parseentryfield           varchar2(12)      null,
    parseruleid               varchar2(10)      null,
    parseruleaction           varchar2(1)       null,
    returnsdisposition        varchar2(10)      null,
    ctostoprefix              number(8)         null,
    lotsumaccess              varchar2(1)       null,
    critlevel1                number(4)         null,
    critlevel2                number(4)         null,
    critlevel3                number(4)         null,
    serialasncapture          varchar2(1)       null,
    user1asncapture           varchar2(1)       null,
    user2asncapture           varchar2(1)       null,
    user3asncapture           varchar2(1)       null,
    imoprimarychemcode        varchar2(12)      null,
    imosecondarychemcode      varchar2(12)      null,
    imotertiarychemcode       varchar2(12)      null,
    imoquaternarychemcode     varchar2(12)      null,
    iataprimarychemcode       varchar2(12)      null,
    iatasecondarychemcode     varchar2(12)      null,
    iatatertiarychemcode      varchar2(12)      null,
    iataquaternarychemcode    varchar2(12)      null,
    unitsofstorage            varchar2(255)     null,
    length                    number(10,4)      null,
    width                     number(10,4)      null,
    height                    number(10,4)      null,
    reorderqty                number(10)        null,
    needs_review_yn           char(1)           null,
    nmfc_article              varchar2(15)      null,
    tms_uom                   varchar2(4)       null,
    tms_commodity_code        varchar2(30)      null,
    use_catch_weights         char(1)           null,
    catch_weight_out_cap_type char(1)           null,
    itmpassthruchar01         varchar2(255)     null,
    itmpassthruchar02         varchar2(255)     null,
    itmpassthruchar03         varchar2(255)     null,
    itmpassthruchar04         varchar2(255)     null,
    itmpassthrunum01          number(16,4)      null,
    itmpassthrunum02          number(16,4)      null,
    itmpassthrunum03          number(16,4)      null,
    itmpassthrunum04          number(16,4)      null,
    labelqty                  number(3)         null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.custitemalias
(
    custid     varchar2(10) not null,
    item       varchar2(20) not null,
    itemalias  varchar2(20) not null,
    aliasdesc  varchar2(32)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.custitembolcomments
(
    custid     varchar2(10)     null,
    item       varchar2(20)     null,
    consignee  varchar2(10)     null,
    comment1   long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custitemcatchweight
(
    custid     varchar2(10) not null,
    item       varchar2(20) not null,
    orderid    number(9)        null,
    shipid     number(7)        null,
    uom        varchar2(4)      null,
    totqty     number(10)       null,
    totweight  number(15,4)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.custitemcount
(
    custid     varchar2(10) not null,
    item       varchar2(20) not null,
    type       varchar2(4)  not null,
    uom        varchar2(4)      null,
    cnt        number(15)       null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.custitemfacility
(
    custid        varchar2(10) not null,
    item          varchar2(20) not null,
    facility      varchar2(3)  not null,
    profid        varchar2(2)      null,
    allocrule     varchar2(10)     null,
    replallocrule varchar2(10)     null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.custitemincomments
(
    custid        varchar2(10) not null,
    item          varchar2(20)     null,
    comment1      long             null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    rfautodisplay varchar2(1)      null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custitemlabelprofiles
(
    custid     varchar2(10) not null,
    item       varchar2(20)     null,
    consignee  varchar2(10)     null,
    profid     varchar2(4)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custitemminmax
(
    custid          varchar2(10) not null,
    item            varchar2(20) not null,
    facility        varchar2(3)  not null,
    qtymin          number(16)       null,
    qtymax          number(16)       null,
    qtyworkordermin number(7)        null,
    constraint pk_custitemminmax
    primary key (custid,item,facility)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custitemoutcomments
(
    custid        varchar2(10)     null,
    item          varchar2(20)     null,
    consignee     varchar2(10)     null,
    comment1      long             null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    rfautodisplay varchar2(1)      null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custitemsubs
(
    custid     varchar2(10) not null,
    item       varchar2(20) not null,
    seq        number(7)        null,
    itemsub    varchar2(20) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custitemtot
(
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    item           varchar2(20) not null,
    inventoryclass varchar2(2)      null,
    invstatus      varchar2(2)      null,
    status         varchar2(2)      null,
    lotnumber      varchar2(30)     null,
    uom            varchar2(4)      null,
    lipcount       number(15)       null,
    qty            number(16)       null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    refid          varchar2(2)      null,
    eventdate      date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.custitemuom
(
    custid             varchar2(10) not null,
    item               varchar2(20) not null,
    sequence           number(3)        null,
    qty                number(7)    not null,
    fromuom            varchar2(4)  not null,
    touom              varchar2(4)  not null,
    lastuser           varchar2(12)     null,
    lastupdate         date             null,
    putawayprofile     varchar2(2)      null,
    picktotype         varchar2(4)      null,
    velocity           char(1)          null,
    cyclecountinterval number(3)        null,
    tareweight         number(13,4)     null,
    cartontype         varchar2(4)      null,
    weight             number(13,4)     null,
    cube               number(10,4)     null,
    length             number(10,4)     null,
    width              number(10,4)     null,
    height             number(10,4)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custitemuomuos
(
    custid        varchar2(10) not null,
    item          varchar2(20) not null,
    uomseq        number(3)    not null,
    unitofmeasure varchar2(4)      null,
    uosseq        number(3)    not null,
    unitofstorage varchar2(4)      null,
    uominuos      number(7,2)      null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.custlastrenewal
(
    facility    varchar2(3)      null,
    custid      varchar2(10)     null,
    lastrenewal date             null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.customcode
(
    businessevent varchar2(4)        null,
    code          varchar2(2000)     null,
    lastuser      varchar2(12)       null,
    lastupdate    date               null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.customer
(
    custid                        varchar2(10)  not null,
    name                          varchar2(40)  not null,
    lookup                        varchar2(40)      null,
    contact                       varchar2(40)      null,
    addr1                         varchar2(40)      null,
    addr2                         varchar2(40)      null,
    city                          varchar2(30)      null,
    state                         varchar2(2)       null,
    postalcode                    varchar2(12)      null,
    countrycode                   varchar2(3)       null,
    phone                         varchar2(25)      null,
    fax                           varchar2(25)      null,
    email                         varchar2(255)     null,
    rnewname                      varchar2(40)      null,
    rnewcontact                   varchar2(40)      null,
    rnewaddr1                     varchar2(40)      null,
    rnewaddr2                     varchar2(40)      null,
    rnewcity                      varchar2(30)      null,
    rnewstate                     varchar2(2)       null,
    rnewpostalcode                varchar2(12)      null,
    rnewcountrycode               varchar2(3)       null,
    rnewphone                     varchar2(25)      null,
    rnewfax                       varchar2(25)      null,
    rnewemail                     varchar2(255)     null,
    rnewbilltype                  varchar2(1)       null,
    rnewbillfreq                  varchar2(1)       null,
    rnewbillday                   number(2)         null,
    rnewautobill                  varchar2(1)       null,
    rcptname                      varchar2(40)      null,
    rcptcontact                   varchar2(40)      null,
    rcptaddr1                     varchar2(40)      null,
    rcptaddr2                     varchar2(40)      null,
    rcptcity                      varchar2(30)      null,
    rcptstate                     varchar2(2)       null,
    rcptpostalcode                varchar2(12)      null,
    rcptcountrycode               varchar2(3)       null,
    rcptphone                     varchar2(25)      null,
    rcptfax                       varchar2(25)      null,
    rcptemail                     varchar2(255)     null,
    rcptbilltype                  varchar2(1)       null,
    rcptbillfreq                  varchar2(1)       null,
    rcptbillday                   number(2)         null,
    rcptautobill                  varchar2(1)       null,
    miscname                      varchar2(40)      null,
    misccontact                   varchar2(40)      null,
    miscaddr1                     varchar2(40)      null,
    miscaddr2                     varchar2(40)      null,
    misccity                      varchar2(30)      null,
    miscstate                     varchar2(2)       null,
    miscpostalcode                varchar2(12)      null,
    misccountrycode               varchar2(3)       null,
    miscphone                     varchar2(25)      null,
    miscfax                       varchar2(25)      null,
    miscemail                     varchar2(255)     null,
    miscbilltype                  varchar2(1)       null,
    miscbillfreq                  varchar2(1)       null,
    miscbillday                   number(2)         null,
    miscautobill                  varchar2(1)       null,
    outbname                      varchar2(40)      null,
    outbcontact                   varchar2(40)      null,
    outbaddr1                     varchar2(40)      null,
    outbaddr2                     varchar2(40)      null,
    outbcity                      varchar2(30)      null,
    outbstate                     varchar2(2)       null,
    outbpostalcode                varchar2(12)      null,
    outbcountrycode               varchar2(3)       null,
    outbphone                     varchar2(25)      null,
    outbfax                       varchar2(25)      null,
    outbemail                     varchar2(255)     null,
    outbbilltype                  varchar2(1)       null,
    outbbillfreq                  varchar2(1)       null,
    outbbillday                   number(2)         null,
    outbautobill                  varchar2(1)       null,
    status                        varchar2(4)       null,
    poverify                      varchar2(1)       null,
    splitrecvstorage              varchar2(1)       null,
    credithold                    varchar2(1)       null,
    sqft                          number(7)         null,
    lotrequired                   varchar2(1)       null,
    lotrftag                      varchar2(3)       null,
    serialrequired                varchar2(1)       null,
    serialrftag                   varchar2(3)       null,
    user1required                 varchar2(1)       null,
    user1rftag                    varchar2(5)       null,
    user2required                 varchar2(1)       null,
    user2rftag                    varchar2(5)       null,
    user3required                 varchar2(1)       null,
    user3rftag                    varchar2(5)       null,
    lastuser                      varchar2(12)      null,
    lastupdate                    date              null,
    mfgdaterequired               varchar2(1)       null,
    expdaterequired               varchar2(1)       null,
    nodamaged                     varchar2(1)       null,
    countryrequired               varchar2(1)       null,
    powhenverify                  varchar2(1)       null,
    pomapfile                     varchar2(255)     null,
    porptfile                     varchar2(255)     null,
    poverifyemail                 varchar2(1)       null,
    poverifyfax                   varchar2(1)       null,
    poverifyonline                varchar2(1)       null,
    poverifybatch                 varchar2(1)       null,
    pomaponline                   varchar2(255)     null,
    poemailfile                   varchar2(255)     null,
    pofaxfile                     varchar2(255)     null,
    powhenfax                     varchar2(1)       null,
    powhenemail                   varchar2(1)       null,
    powhenbatch                   varchar2(1)       null,
    powhenonline                  varchar2(1)       null,
    receiverptfile                varchar2(255)     null,
    rategroup                     varchar2(10)      null,
    backorder                     varchar2(2)       null,
    allowsub                      varchar2(1)       null,
    ltlcarrier                    varchar2(4)       null,
    tlcarrier                     varchar2(4)       null,
    spscarrier                    varchar2(4)       null,
    railcarrier                   varchar2(4)       null,
    rnewlastbilled                date              null,
    misclastbilled                date              null,
    rcptlastbilled                date              null,
    outblastbilled                date              null,
    mastlastbilled                date              null,
    sqftbillmethod                varchar2(1)       null,
    csr                           varchar2(10)      null,
    invstatusind                  varchar2(1)       null,
    invstatus                     varchar2(255)     null,
    invclassind                   varchar2(1)       null,
    inventoryclass                varchar2(255)     null,
    qtytype                       varchar2(1)       null,
    variancepct                   number(3)         null,
    weightcheckrequired           char(1)           null,
    ordercheckrequired            char(1)           null,
    fifowindowdays                number(3)         null,
    putawayconfirmation           char(1)           null,
    billfreightto                 varchar2(10)      null,
    allocrule                     varchar2(10)      null,
    wavetemplate                  varchar2(36)      null,
    outconfirmonline              char(1)           null,
    outconfirmbatch               char(1)           null,
    outconfirmonlinemap           varchar2(255)     null,
    outconfirmbatchmap            varchar2(255)     null,
    outconfirmonlinewhen          char(1)           null,
    outconfirmbatchwhen           char(1)           null,
    outackonline                  char(1)           null,
    outackbatch                   char(1)           null,
    outackonlinemap               varchar2(255)     null,
    outackbatchmap                varchar2(255)     null,
    outackonlinewhen              char(1)           null,
    outackbatchwhen               char(1)           null,
    subslprsnrequired             char(1)           null,
    sumassessorial                varchar2(1)       null,
    lastaccountmin                date              null,
    prevaccountmin                date              null,
    packlist                      char(1)           null,
    packlistrptfile               varchar2(255)     null,
    rmarequired                   char(1)           null,
    resubmitorder                 char(1)           null,
    lastshipsum                   date              null,
    lastrcptnote                  date              null,
    lastshipnote                  date              null,
    outrejectbatchmap             varchar2(255)     null,
    outstatusbatchmap             varchar2(255)     null,
    outshipsumbatchmap            varchar2(255)     null,
    bolrptfile                    varchar2(255)     null,
    cycleapercent                 number(3)         null,
    cycleafrequency               number(2)         null,
    cyclebpercent                 number(3)         null,
    cyclebfrequency               number(2)         null,
    cyclecpercent                 number(3)         null,
    cyclecfrequency               number(2)         null,
    lastcyclerequest              date              null,
    cycleacounts                  number(6)         null,
    cyclebcounts                  number(6)         null,
    cycleccounts                  number(6)         null,
    lotfmtruleid                  varchar2(10)      null,
    lotfmtaction                  varchar2(1)       null,
    serialfmtruleid               varchar2(10)      null,
    serialfmtaction               varchar2(1)       null,
    user1fmtruleid                varchar2(10)      null,
    user1fmtaction                varchar2(1)       null,
    user2fmtruleid                varchar2(10)      null,
    user2fmtaction                varchar2(1)       null,
    user3fmtruleid                varchar2(10)      null,
    user3fmtaction                varchar2(1)       null,
    bolfax                        char(1)           null,
    bolemail                      char(1)           null,
    irisexport                    varchar2(1)       null,
    maxqtyof1                     varchar2(1)       null,
    proratedays                   number(2)         null,
    proratepct                    number(3)         null,
    parseentryfield               varchar2(12)      null,
    parseruleid                   varchar2(10)      null,
    parseruleaction               varchar2(1)       null,
    contact1phone                 varchar2(25)      null,
    contact1fax                   varchar2(25)      null,
    contact1email                 varchar2(255)     null,
    contact2phone                 varchar2(25)      null,
    contact2fax                   varchar2(25)      null,
    contact2email                 varchar2(255)     null,
    contact3phone                 varchar2(25)      null,
    contact3fax                   varchar2(25)      null,
    contact3email                 varchar2(255)     null,
    contact4phone                 varchar2(25)      null,
    contact4fax                   varchar2(25)      null,
    contact4email                 varchar2(255)     null,
    contact5phone                 varchar2(25)      null,
    contact5fax                   varchar2(25)      null,
    contact5email                 varchar2(255)     null,
    contact1name                  varchar2(40)      null,
    contact2name                  varchar2(40)      null,
    contact3name                  varchar2(40)      null,
    contact4name                  varchar2(40)      null,
    contact5name                  varchar2(40)      null,
    returnsdisposition            varchar2(10)      null,
    trackpallets                  char(1)       default 'N'     null,
    manufacturerucc               varchar2(7)       null,
    approvallimitaccessorial      number(6)         null,
    approvallimitmiscellaneous    number(6)         null,
    approvallimitreceipt          number(6)         null,
    approvallimitrenewal          number(6)         null,
    billforpallets                char(1)           null,
    masteraccount                 varchar2(10)      null,
    maxrfqtylength                number(1)         null,
    serialasncapture              varchar2(1)       null,
    user1asncapture               varchar2(1)       null,
    user2asncapture               varchar2(1)       null,
    user3asncapture               varchar2(1)       null,
    qaallowed                     varchar2(1)       null,
    qaholdreceipt                 varchar2(1)       null,
    collectpronumbers             varchar2(1)       null,
    qaenforcesamples              varchar2(1)       null,
    returnoriginalreq             varchar2(1)       null,
    dup_reference_ynw             char(1)           null,
    linenumbersyn                 varchar2(1)       null,
    shortshipsmallpkgyn           varchar2(1)       null,
    sip_tradingpartnerid          varchar2(15)      null,
    sip_default_fromfacility      varchar2(3)       null,
    sip_wsa_945_summarize_lots_yn char(1)           null,
    defhandlingpct                number(3)         null,
    allowpickpassing              varchar2(1)       null,
    paperbased                    varchar2(1)       null,
    invbaserptfile                varchar2(255)     null,
    invmstrrptfile                varchar2(255)     null,
    invsummrptfile                varchar2(255)     null,
    picklistrptfile               varchar2(255)     null,
    recv_line_check_yn            char(1)           null,
    recv_line_variance_pct        number(3)         null,
    mastbolemail                  char(1)           null,
    mastbolfax                    char(1)           null,
    mastbolrptfile                varchar2(255)     null,
    shipnote_include_cancelled_yn char(1)           null,
    rcptnote_include_cancelled_yn char(1)           null,
    pallet_tracking_export_map    varchar2(255)     null,
    chep_communicator_code        varchar2(255)     null,
    masterpacklist                char(1)           null,
    masterpacklistrptfile         varchar2(255)     null,
    tms_planned_shipments_format  varchar2(255)     null,
    tms_item_format               varchar2(255)     null,
    tms_orders_to_plan_format     varchar2(255)     null,
    tms_status_changes_format     varchar2(255)     null,
    tms_actual_ship_format        varchar2(255)     null,
    freight_bill_export_format    varchar2(255)     null,
    use_catch_weights             char(1)           null,
    catch_weight_out_cap_type     char(1)           null,
    prono_summary_column          varchar2(30)      null,
    recent_order_days             number(7)         null,
    pick_by_line_number_yn        char(1)           null,
    defconsolidated               char(1)           null,
    defshiptype                   varchar2(1)       null,
    defcarrier                    varchar2(4)       null,
    defservicelevel               varchar2(4)       null,
    defshipcost                   number(10,2)      null,
	 defpalletqty                  number(7)         null,
	 defpallettype                 varchar2(12)      null,
    multifac_picking              char(1)           null,
    shortreasonreqd               varchar2(1)       null,
    latereasonreqd                varchar2(1)       null,
    shiptimevariance              number(7)         null,
    prelimbolrptfile              varchar2(255)     null,
    print_prelim_at_rel           varchar2(1) default 'N' null,
    ordshiprptfile                varchar2(255),
    ordshipemail                  varchar2(1) default 'N',
    overageunits                  number(10,2),
    overageunitstype              char(1) default 'N',
    overagedollars                number(10,2),
    overagedollarstype            char(1) default 'N',
    overagedollarsfield           char(1) default '1',
    overagesupcode                varchar2(10)
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.customercarriers
(
    custid             varchar2(10) not null,
    shiptype           varchar2(1)      null,
    fromweight         number       not null,
    toweight           number       not null,
    carrier            varchar2(4)  not null,
    lastuser           varchar2(12)     null,
    lastupdate         date             null,
    begzip             varchar2(5)      null,
    endzip             varchar2(5)      null,
    assigned_ship_type varchar2(1),
    servicecode        varchar2(4)
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.customerstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custpacklist
(
    custid                varchar2(10)      null,
    carrier               varchar2(4)       null,
    servicecode           varchar2(4)       null,
    packlistyn            char(1)           null,
    packlistformat        varchar2(255)     null,
    lastuser              varchar2(12)      null,
    lastupdate            date              null,
    masterpacklist        char(1)           null,
    masterpacklistrptfile varchar2(255)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custproductgroup
(
    custid                    varchar2(10)  not null,
    productgroup              varchar2(4)   not null,
    descr                     varchar2(32)  not null,
    abbrev                    varchar2(12)      null,
    rategroup                 varchar2(10)      null,
    lotrequired               varchar2(1)       null,
    lotrftag                  varchar2(3)       null,
    serialrequired            varchar2(1)       null,
    serialrftag               varchar2(3)       null,
    user1required             varchar2(1)       null,
    user1rftag                varchar2(5)       null,
    user2required             varchar2(1)       null,
    user2rftag                varchar2(5)       null,
    user3required             varchar2(1)       null,
    user3rftag                varchar2(5)       null,
    mfgdaterequired           varchar2(1)       null,
    expdaterequired           varchar2(1)       null,
    nodamaged                 varchar2(1)       null,
    countryrequired           varchar2(1)       null,
    backorder                 varchar2(2)       null,
    allowsub                  varchar2(1)       null,
    invstatusind              varchar2(1)       null,
    invstatus                 varchar2(255)     null,
    invclassind               varchar2(1)       null,
    inventoryclass            varchar2(255)     null,
    qtytype                   varchar2(1)       null,
    variancepct               number(3)         null,
    subslprsnrequired         char(1)           null,
    fifowindowdays            number(3)         null,
    maxqtyof1                 varchar2(1)       null,
    lotfmtruleid              varchar2(10)      null,
    lotfmtaction              varchar2(1)       null,
    serialfmtruleid           varchar2(10)      null,
    serialfmtaction           varchar2(1)       null,
    user1fmtruleid            varchar2(10)      null,
    user1fmtaction            varchar2(1)       null,
    user2fmtruleid            varchar2(10)      null,
    user2fmtaction            varchar2(1)       null,
    user3fmtruleid            varchar2(10)      null,
    user3fmtaction            varchar2(1)       null,
    lastuser                  varchar2(12)      null,
    lastupdate                date              null,
    putawayconfirmation       char(1)           null,
    ordercheckrequired        char(1)           null,
    weightcheckrequired       char(1)           null,
    status                    varchar2(4)       null,
    parseentryfield           varchar2(12)      null,
    parseruleid               varchar2(10)      null,
    parseruleaction           varchar2(1)       null,
    returnsdisposition        varchar2(10)      null,
    critlevel1                number(4)         null,
    critlevel2                number(4)         null,
    critlevel3                number(4)         null,
    serialasncapture          varchar2(1)       null,
    user1asncapture           varchar2(1)       null,
    user2asncapture           varchar2(1)       null,
    user3asncapture           varchar2(1)       null,
    use_catch_weights         char(1)           null,
    catch_weight_out_cap_type char(1)           null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custproductgroupfacility
(
    custid        varchar2(10) not null,
    productgroup  varchar2(4)  not null,
    facility      varchar2(3)  not null,
    profid        varchar2(2)      null,
    allocrule     varchar2(10)     null,
    replallocrule varchar2(10)     null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custrate
(
    custid     varchar2(10) not null,
    rategroup  varchar2(10) not null,
    effdate    date         not null,
    activity   varchar2(4)  not null,
    billmethod varchar2(4)  not null,
    uom        varchar2(4)      null,
    rate       number(12,6)     null,
    gracedays  number(2)        null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    calctype   varchar2(1)      null,
    moduom     varchar2(4)      null,
    annvdays   number(2)        null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custratebreak
(
    custid      varchar2(10)  not null,
    rategroup   varchar2(10)  not null,
    effdate     date          not null,
    activity    varchar2(4)   not null,
    billmethod  varchar2(4)   not null,
    quantity    number(12,2)  not null,
    rate        number(12,6)      null,
    lastuser    varchar2(12)      null,
    lastupdate  date              null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custrategroup
(
    custid        varchar2(10) not null,
    rategroup     varchar2(10) not null,
    descr         varchar2(36) not null,
    abbrev        varchar2(12) not null,
    status        varchar2(4)  not null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    linkyn        char(1)          null,
    linkrategroup varchar2(10)     null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custratewhen
(
    custid        varchar2(10) not null,
    rategroup     varchar2(10) not null,
    effdate       date         not null,
    activity      varchar2(4)  not null,
    billmethod    varchar2(4)  not null,
    businessevent varchar2(4)  not null,
    automatic     varchar2(1)  not null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custrenewal
(
    custid     varchar2(10)     null,
    renewal    date             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custreturnreasons
(
    custid     varchar2(10) not null,
    code       varchar2(2)  not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custshipper
(
    custid     varchar2(10) not null,
    shipper    varchar2(10) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custsqft
(
    facility   varchar2(3)  not null,
    custid     varchar2(10) not null,
    sqft       number(7)        null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.custtradingpartner
(
    custid         varchar2(10) not null,
    tradingpartner varchar2(10) not null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.custvicsbol
(
    custid     varchar2(10)  not null,
    shipto     varchar2(10)      null,
    ordertype  char(1)       not null,
    reportname varchar2(255) not null,
    lastuser   varchar2(12)      null,
    lastupdate date              null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.custvicsbolcopies
(
    custid     varchar2(10)  not null,
    shipto     varchar2(10)      null,
    ordertype  char(1)       not null,
    reportname varchar2(255) not null,
    boltype    varchar2(4)       null,
    copynumber number(2)         null,
    copymsg    varchar2(36)      null,
    lastuser   varchar2(12)      null,
    lastupdate date              null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.custworkorder
(
    seq          number(16)   not null,
    custid       varchar2(10) not null,
    item         varchar2(20) not null,
    requestedqty number(16)   not null,
    status       char(1)      not null,
    completedqty number(8)        null,
    constraint pk_custworkorder
    primary key (seq)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.custworkorderinstructions
(
    seq          number(8)    not null,
    subseq       number(8)    not null,
    parent       number(8)        null,
    action       varchar2(2)      null,
    notes        long             null,
    title        varchar2(35)     null,
    qty          number(8)        null,
    component    varchar2(20)     null,
    destfacility varchar2(3)      null,
    destlocation varchar2(10)     null,
    destloctype  varchar2(12)     null,
    status       char(1)          null,
    completedqty number(8)        null,
    constraint pk_custworkorderinstructions
    primary key (seq,subseq)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.cyclecountactivity
(
    facility       varchar2(3)  not null,
    location       varchar2(10)     null,
    lpid           varchar2(15)     null,
    custid         varchar2(10)     null,
    item           varchar2(20)     null,
    lotnumber      varchar2(30)     null,
    uom            varchar2(4)      null,
    quantity       number(7)        null,
    entlocation    varchar2(10)     null,
    entcustid      varchar2(10)     null,
    entitem        varchar2(20)     null,
    entlotnumber   varchar2(30)     null,
    entquantity    number(7)        null,
    taskid         varchar2(15)     null,
    adjustmenttype varchar2(3)      null,
    whenoccurred   date             null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.cyclecountadjustmenttypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.daily_billing_run
(
    effdate     date    null,
    start_dt    date    null,
    end_dt      date    null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.damageditemreasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.deletedplate
(
    lpid             varchar2(15) not null,
    item             varchar2(20)     null,
    custid           varchar2(10)     null,
    facility         varchar2(3)      null,
    location         varchar2(10)     null,
    status           varchar2(2)      null,
    holdreason       varchar2(2)      null,
    unitofmeasure    varchar2(4)      null,
    quantity         number(7)        null,
    type             varchar2(2)      null,
    serialnumber     varchar2(30)     null,
    lotnumber        varchar2(30)     null,
    creationdate     date             null,
    manufacturedate  date             null,
    expirationdate   date             null,
    expiryaction     varchar2(2)      null,
    lastcountdate    date             null,
    po               varchar2(20)     null,
    recmethod        varchar2(2)      null,
    condition        varchar2(2)      null,
    lastoperator     varchar2(12)     null,
    lasttask         varchar2(2)      null,
    fifodate         date             null,
    destlocation     varchar2(10)     null,
    destfacility     varchar2(3)      null,
    countryof        varchar2(3)      null,
    parentlpid       varchar2(15)     null,
    useritem1        varchar2(20)     null,
    useritem2        varchar2(20)     null,
    useritem3        varchar2(20)     null,
    disposition      varchar2(4)      null,
    lastuser         varchar2(12)     null,
    lastupdate       date             null,
    invstatus        varchar2(2)      null,
    qtyentered       number(7)        null,
    itementered      varchar2(20)     null,
    uomentered       varchar2(4)      null,
    inventoryclass   varchar2(2)      null,
    loadno           number(7)        null,
    stopno           number(7)        null,
    shipno           number(7)        null,
    orderid          number(9)        null,
    shipid           number(2)        null,
    weight           number(13,4)     null,
    adjreason        varchar2(2)      null,
    qtyrcvd          number(7)        null,
    controlnumber    varchar2(10)     null,
    qcdisposition    varchar2(2)      null,
    fromlpid         varchar2(15)     null,
    taskid           number(15)       null,
    dropseq          number(5)        null,
    fromshippinglpid varchar2(15)     null,
    workorderseq     number(8)        null,
    workordersubseq  number(8)        null,
    qtytasked        number(7)        null,
    childfacility    varchar2(3)      null,
    childitem        varchar2(20)     null,
    parentfacility   varchar2(3)      null,
    parentitem       varchar2(20)     null,
    prevlocation     varchar2(10)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.delivery_point_types
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.docappointments
(
    appointmentid  number(7)     not null,
    apttype        varchar2(1)   null,
    facility 		 varchar2(3)   null,
    starttime 		 date          null,
    endtime 		 date          null,
    appointmentnum number(7)     null,
    subject			 varchar2(30)  null,
    notes			 varchar2(500) null,
    loadno			 number(7)     null,
    lastuser		 varchar2(12)  null,
    lastupdate   	 date          null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.docschedule
(
    scheduleid      number(7)    not null,
    facility        varchar2(3)  not null,
    apttype         varchar2(1)      null,
    startdate       date             null,
    enddate         date             null,
    starttime       varchar2(5)      null,
    endtime         varchar2(5)      null,
    maxappointments number(4)        null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.door
(
    facility   varchar2(3)  not null,
    doorloc    varchar2(10) not null,
    loadno     number(7)        null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.employeeactivities
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.equipmentprofiles
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.equipmenttypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.equipprofequip
(
    profid     varchar2(2)  not null,
    equipid    varchar2(2)  not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.equiptask
(
    equipid    varchar2(2)  not null,
    tasktype   varchar2(2)  not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.expirationactions
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.facility
(
    facility                  varchar2(3)   not null,
    name                      varchar2(40)      null,
    addr1                     varchar2(40)      null,
    addr2                     varchar2(40)      null,
    city                      varchar2(30)      null,
    state                     varchar2(2)       null,
    postalcode                varchar2(12)      null,
    countrycode               varchar2(3)       null,
    phone                     varchar2(25)      null,
    fax                       varchar2(25)      null,
    lastuser                  varchar2(12)      null,
    lastupdate                date              null,
    email                     varchar2(255)     null,
    glid                      varchar2(20)      null,
    campus                    varchar2(3)       null,
    manager                   varchar2(40)      null,
    facilitystatus            varchar2(1)       null,
    tasklimit                 number(3)         null,
    remitname                 varchar2(40)      null,
    remitaddr1                varchar2(40)      null,
    remitaddr2                varchar2(40)      null,
    remitcity                 varchar2(30)      null,
    remitstate                varchar2(2)       null,
    remitpostalcode           varchar2(12)      null,
    remitcountrycode          varchar2(3)       null,
    xdockloc                  varchar2(10)      null,
    facilitygroup             varchar2(4)       null,
    shippersignature          varchar2(255)     null,
    chep_communicator_code    varchar2(255)     null,
    use_location_checkdigit   char(1)           null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table facilitycarrierpronozone
(
    facility		varchar2(3) not null,
    carrier			varchar2(4) not null,
    zone         	varchar2(32)    null,
    lastuser      varchar2(12)    null,
    lastupdate    date            null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.facilitystatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.fitmethods
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.formatvalidationactions
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.formatvalidationdatatypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.formatvalidationrule
(
    ruleid     varchar2(10) not null,
    descr      varchar2(32)     null,
    minlength  number(3)        null,
    maxlength  number(3)        null,
    datatype   varchar2(1)      null,
    mask       varchar2(30)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    dupesok    varchar2(1)      null,
    mod10check varchar2(1)      null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.handlingtypes
(
    code        varchar2(4)  not null,
    descr       varchar2(32) not null,
    abbrev      varchar2(12) not null,
    activity    varchar2(4)  not null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null,
    minactivity varchar2(4)      null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.hazardousclasses
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.holdreasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.i52_item_bal
(
   custid         varchar2(10)   null,
   warehouse      varchar2(3)    null,
   facility       varchar2(4)    null,
   item           varchar2(20)   null,
   invstatus      varchar2(2)    null,
   inventoryclass varchar2(2)    null,
   qty            number         null,
   refid          varchar2(2)    null,
   lotnumber      varchar2(30)   null,
   unitofmeasure  varchar2(4)    null,
   eventdate      date           null,
   eventtime      number         null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.impexp_afterprocessprocparams
(
    definc    number(4)    not null,
    lineinc   number(4)    not null,
    paramname varchar2(25) not null,
    chunkinc  number(4)        null,
    defvalue  varchar2(35)     null,
    constraint pk_afterprocessprocparams
    primary key (definc,lineinc,paramname)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.impexp_chunks
(
    definc             number(4)     not null,
    lineinc            number(4)     not null,
    chunkinc           number(4)     not null,
    chunktype          number(2)         null,
    paramname          varchar2(35)      null,
    offset             number(8)         null,
    length             number(8)         null,
    defvalue           varchar2(35)      null,
    description        varchar2(35)      null,
    lktable            varchar2(35)      null,
    lkfield            varchar2(35)      null,
    lkkey              varchar2(35)      null,
    mappings           long              null,
    parentlineparam    varchar2(35)      null,
    chunkdecimals      char(1)       default 'N'     null,
    fieldprefix        varchar2(255)     null,
    substring_position number(7)         null,
    substring_length   number(7)         null,
    no_fieldprefix_on_null_value   char(1) null,
    from_another_chunk_description varchar2(35) null,
constraint pk_impexp_chunks
    primary key (definc,lineinc,chunkinc)
        using index pctfree 10
                    tablespace synapse_act_index
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.impexp_definitions
(
    definc                  number(4)      not null,
    name                    varchar2(35)   not null,
    targetalias             varchar2(35)   not null,
    deffilename             varchar2(200)      null,
    dateformat              varchar2(20)       null,
    deftype                 char(1)            null,
    floatdecimals           number(4)      default 0     null,
    amountdecimals          number(4)      default 0     null,
    linelength              number(8)      default 0     null,
    afterprocessproc        varchar2(35)       null,
    beforeprocessproc       varchar2(35)       null,
    afterprocessprocparams  varchar2(1000)     null,
    beforeprocessprocparams varchar2(1000)     null,
    timeformat              varchar2(20)       null,
    includecrlf             char(1)            null,
    separatefiles           char(1)            null,
    sip_format_yn           char(1)            null,
    constraint pk_impexp_definitions
    primary key (definc)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.impexp_lines
(
    definc               number(4)     not null,
    lineinc              number(4)     not null,
    parent               number(2)         null,
    type                 number(2)         null,
    identifier           varchar2(15)      null,
    delimiter            varchar2(1)       null,
    linealias            varchar2(35)      null,
    procname             varchar2(35)      null,
    delimiteroffset      number(4)     default 0     null,
    afterprocessprocname varchar2(35)      null,
    headertrailerflag    char(1)       default 'N'     null,
    orderbycolumns       varchar2(255)     null,
    constraint pk_impexp_lines
    primary key (definc,lineinc)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.invadj947dtlex
(
    sessionid           varchar2(12)     null,
    whenoccurred        date             null,
    lpid                varchar2(15)     null,
    facility            varchar2(3)      null,
    custid              varchar2(10)     null,
    rsncode             varchar2(20)     null,
    quantity            number(5)        null,
    uom                 varchar2(4)      null,
    upc                 varchar2(20)     null,
    item                varchar2(20)     null,
    lotno               varchar2(30)     null,
    dmgdesc             varchar2(45)     null,
    newlotno            varchar2 (30)    null,
	 oldinvstatus        varchar2 (2)     null,
	 oldinventoryclass   varchar2 (2)     null,
	 oldtaxcode          varchar2 (2)     null,
	 newtaxcode          varchar2 (2)     null,
	 newinventoryclass   varchar2 (2)     null,
	 newinvstatus        varchar2 (2)     null,
	 sapmovecode         varchar2 (3)     null,
	 custreference       varchar2 (32)    null,
    newitemno           varchar2 (20)    null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.invadjactivity
(
    whenoccurred      date             null,
    lpid              varchar2(15) not null,
    facility          varchar2(3)  not null,
    custid            varchar2(10) not null,
    item              varchar2(20)     null,
    lotnumber         varchar2(30)     null,
    inventoryclass    varchar2(2)      null,
    invstatus         varchar2(2)      null,
    uom               varchar2(4)      null,
    adjqty            number(7)        null,
    adjreason         varchar2(2)      null,
    tasktype          varchar2(4)      null,
    adjuser           varchar2(12)     null,
    lastuser          varchar2(12)     null,
    lastupdate        date             null,
    serialnumber      varchar2(30)     null,
    useritem1         varchar2(20)     null,
    useritem2         varchar2(20)     null,
    useritem3         varchar2(20)     null,
    oldcustid         varchar2(10)     null,
    olditem           varchar2(20)     null,
    oldlotnumber      varchar2(30)     null,
    oldinventoryclass varchar2(2)      null,
    oldinvstatus      varchar2(2)      null,
    newcustid         varchar2(10)     null,
    newitem           varchar2(20)     null,
    newlotnumber      varchar2(30)     null,
    newinventoryclass varchar2(2)      null,
    newinvstatus      varchar2(2)      null,
    adjweight         number(13,4)     null,
    custreference     varchar2(32)     null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.inventoryclass
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.inventorystatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.invoicedtl
(
    billstatus    varchar2(1)  not null,
    facility      varchar2(3)  not null,
    custid        varchar2(10) not null,
    orderid       number(9)    not null,
    item          varchar2(20)     null,
    lotnumber     varchar2(30)     null,
    activity      varchar2(4)  not null,
    activitydate  date             null,
    handling      varchar2(4)      null,
    invoice       number(8)        null,
    invdate       date             null,
    invtype       varchar2(1)      null,
    po            varchar2(20)     null,
    lpid          varchar2(15)     null,
    enteredqty    number(12,2)     null,
    entereduom    varchar2(4)      null,
    enteredrate   number(12,6)     null,
    enteredamt    number(10,2)     null,
    calcedqty     number(12,2)     null,
    calceduom     varchar2(4)      null,
    calcedrate    number(12,6)     null,
    calcedamt     number(10,2)     null,
    minimum       number(10,2)     null,
    billedqty     number(12,2)     null,
    billedrate    number(12,6)     null,
    billedamt     number(10,2)     null,
    expiregrace   date             null,
    statusrsn     varchar2(4)      null,
    exceptrsn     varchar2(4)      null,
    comment1      long             null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    statususer    varchar2(12)     null,
    statusupdate  date             null,
    loadno        number(7)        null,
    stopno        number(7)        null,
    shipno        number(7)        null,
    billmethod    varchar2(4)      null,
    orderitem     varchar2(20)     null,
    orderlot      varchar2(30)     null,
    shipid        number(2)        null,
    useinvoice    varchar2(8)      null,
    weight        number(13,4)     null,
    moduom        varchar2(4)      null,
    enteredweight number(13,4)     null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.invoicehdr
(
    invoice       number(8)    not null,
    invdate       date         not null,
    invtype       varchar2(1)  not null,
    invstatus     varchar2(1)  not null,
    custid        varchar2(10) not null,
    facility      varchar2(3)  not null,
    postdate      date             null,
    printdate     date             null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    orderid       number(9)        null,
    masterinvoice varchar2(8)      null,
    loadno        number(7)        null,
    statususer    varchar2(12)     null,
    statusupdate  date             null,
    invoicedate   date             null,
    renewfromdate date             null,
    renewtodate   date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.invoiceorders
(
    invoice number(8) not null,
    orderid number(9)     null,
    shipid  number(2)     null,
    loadno  number(7)     null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.invoicetypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.invsession
(
    userid     varchar2(12) not null,
    facility   varchar2(3)      null,
    custid     varchar2(10)     null,
    csr        varchar2(10)     null,
    invdate    date             null,
    reference  number(8)        null,
    invtype    varchar2(1)      null,
    orderid    number(9)        null,
    onlydueinv varchar2(1)      null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.irisanclex
(
    sessionid varchar2(8)      null,
    orderid   number(9)        null,
    shipid    number(7)        null,
    service   varchar2(4)      null,
    class     varchar2(8)      null,
    custid    varchar2(10)     null,
    irisid    varchar2(4)      null,
    company   varchar2(4)      null,
    warehouse varchar2(4)      null,
    quantity  number(10,2)     null,
    charge    number(10,2)     null,
    postdate  date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.irisclasses
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.irisrecvex
(
    sessionid    varchar2(8)      null,
    orderid      number(9)        null,
    shipid       number(7)        null,
    line         number(11)       null,
    sortord      number(3)        null,
    item         varchar2(20)     null,
    lotnumber    varchar2(30)     null,
    serialnumber varchar2(30)     null,
    service      varchar2(4)      null,
    class        varchar2(8)      null,
    custid       varchar2(10)     null,
    company      varchar2(4)      null,
    warehouse    varchar2(4)      null,
    quantity     number(10,2)     null,
    charge       number(10,2)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.irisshipex
(
    sessionid       varchar2(8)      null,
    orderid         number(9)        null,
    shipid          number(7)        null,
    line            number(11)       null,
    sortord         number(3)        null,
    item            varchar2(20)     null,
    lotnumber       varchar2(30)     null,
    serialnumber    varchar2(30)     null,
    service         varchar2(4)      null,
    class           varchar2(8)      null,
    custid          varchar2(10)     null,
    company         varchar2(4)      null,
    warehouse       varchar2(4)      null,
    quantity        number(10,2)     null,
    charge          number(10,2)     null,
    weight          number(13,4)     null,
    trackingno      varchar2(20)     null,
    pkgcount        number(3)        null,
    deliveryservice varchar2(4)      null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.iristypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.iris_del_service_exception
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.itemdemand
(
    facility       varchar2(3)   not null,
    item           varchar2(20)  not null,
    lotnumber      varchar2(30)      null,
    priority       char(1)           null,
    invstatusind   char(1)           null,
    invclassind    char(1)           null,
    invstatus      varchar2(255)     null,
    inventoryclass varchar2(255)     null,
    demandtype     char(1)           null,
    orderid        number(9)         null,
    shipid         number(2)         null,
    loadno         number(7)         null,
    stopno         number(7)         null,
    shipno         number(7)         null,
    orderitem      varchar2(20)      null,
    orderlot       varchar2(30)      null,
    qty            number(7)         null,
    lastuser       varchar2(12)      null,
    lastupdate     date              null,
    custid         varchar2(10)      null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.iteminventorystatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.itemlipstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.itempickfronts
(
    custid           varchar2(10) not null,
    item             varchar2(20)     null,
    facility         varchar2(3)      null,
    pickfront        varchar2(10)     null,
    pickuom          varchar2(4)      null,
    replenishqty     number(7)        null,
    replenishuom     varchar2(4)      null,
    maxqty           number(7)        null,
    maxuom           varchar2(4)      null,
    replenishwithuom varchar2(4)      null,
    lastuser         varchar2(12)     null,
    lastupdate       date             null,
    topoffqty        number(7)        null,
    topoffuom        varchar2(4)      null,
    lastpickeddate   date             null,
    pendingitem      varchar2(20)     null,
    olditem          varchar2(20)     null,
    pendingcustid    varchar2(10)     null,
    oldpickfront     varchar2(10)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.itemstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.itemvelocitycodes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.labelprintactions
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.labelprofileline
(
    profid        varchar2(4)   not null,
    businessevent varchar2(4)   not null,
    uom           varchar2(4)       null,
    seq           number(3)     not null,
    printerstock  varchar2(1)       null,
    copies        number(4)     not null,
    print         varchar2(1)   not null,
    apply         varchar2(1)   not null,
    rfline1       varchar2(20)      null,
    rfline2       varchar2(20)      null,
    rfline3       varchar2(20)      null,
    rfline4       varchar2(20)      null,
    scfpath       varchar2(255)     null,
    viewname      varchar2(255) not null,
    viewkeycol    varchar2(30)      null,
    viewkeyorigin varchar2(1)   not null,
    facility      varchar2(3)       null,
    station       varchar2(10)      null,
    prtid         varchar2(5)       null,
    lastuser      varchar2(12)      null,
    lastupdate    date              null,
    lpspath       varchar2(255)     null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.labelprofiles
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.laborreportcountgroups
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.laborreportgroups
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.laborstandards
(
    facility   varchar2(3)      null,
    category   varchar2(4)      null,
    zoneid     varchar2(10)     null,
    uom        varchar2(4)      null,
    qtyperhour number(10,4)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    custid     varchar2(12)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.lastfreightbill_all
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.lastlawsonbill_all
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 30
pctused 40
/

create table alps.lasttmscust_all
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.lasttms_all
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table lateshipreasons
(
  code        varchar2(12),
  descr       varchar2(32),
  abbrev      varchar2(12),
  dtlupdate   varchar2(1),
  lastuser    varchar2(12),
  lastupdate  date
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.lawsoncmtex
(
    sessionid  varchar2(8)      null,
    prefix     varchar2(2)      null,
    invoice    number(8)        null,
    linenumber number(6)        null,
    sequence   number(6)        null,
    comment1   varchar2(80)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.lawsondtlex
(
    sessionid    varchar2(8)      null,
    prefix       varchar2(2)      null,
    invoice      number(8)        null,
    linenumber   number(6)        null,
    facility     varchar2(3)      null,
    item         varchar2(20)     null,
    lotnumber    varchar2(30)     null,
    descr        varchar2(32)     null,
    quantity     number(9,2)      null,
    price        number(12,6)     null,
    amount       number(10,2)     null,
    uom          varchar2(4)      null,
    glaccount    varchar2(6)      null,
    araccount    varchar2(6)      null,
    orderid      number(9)        null,
    activity     varchar2(4)      null,
    activitydesc varchar2(32)     null,
    reference    varchar2(20)     null,
    po           varchar2(20)     null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.lawsonhdrex
(
    sessionid   varchar2(8)      null,
    postdate    date             null,
    prefix      varchar2(2)      null,
    invoice     number(8)        null,
    facility    varchar2(3)      null,
    custid      varchar2(10)     null,
    invoicedate date             null,
    glid        varchar2(20)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.licenseplatestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.licenseplatetypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.loaded_by_types
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.loadflaglabels
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40

create table alps.loads
(
    loadno           number(7)        null,
    entrydate        date             null,
    rcvddate         date             null,
    billdate         date             null,
    loadstatus       varchar2(1)      null,
    trailer          varchar2(12)     null,
    seal             varchar2(15)     null,
    facility         varchar2(3)      null,
    doorloc          varchar2(10)     null,
    stageloc         varchar2(10)     null,
    carrier          varchar2(4)      null,
    source           varchar2(4)      null,
    qtyorder         number(10)       null,
    weightorder      number(13,4)     null,
    cubeorder        number(10,4)     null,
    amtorder         number(10,2)     null,
    qtyship          number(10)       null,
    weightship       number(13,4)     null,
    cubeship         number(10,4)     null,
    amtship          number(10,2)     null,
    qtyrcvd          number(10)       null,
    weightrcvd       number(13,4)     null,
    cubercvd         number(10,4)     null,
    amtrcvd          number(10,2)     null,
    comment1         long             null,
    statususer       varchar2(12)     null,
    statusupdate     date             null,
    lastuser         varchar2(12)     null,
    lastupdate       date             null,
    billoflading     varchar2(40)     null,
    loadtype         varchar2(4)      null,
    prono            varchar2(20)     null,
    apptdate         date             null,
    shiptype         char(1)          null,
    shipterms        varchar2(3)      null,
    loadedby         char(1)          null,
    countedby        char(1)          null,
    appointmentid    number(7)        null,
    lateshipreason   varchar2(12)     null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.loadsbolcomments
(
    loadno     number(7)    not null,
    bolcomment long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.loadstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.loadstop
(
    loadno         number(7)        null,
    stopno         number(7)        null,
    entrydate      date             null,
    shipto         varchar2(10)     null,
    loadstopstatus varchar2(1)      null,
    stageloc       varchar2(10)     null,
    qtyorder       number(10)       null,
    weightorder    number(13,4)     null,
    cubeorder      number(10,4)     null,
    amtorder       number(10,2)     null,
    qtyship        number(10)       null,
    weightship     number(13,4)     null,
    cubeship       number(10,4)     null,
    amtship        number(10,2)     null,
    qtyrcvd        number(10)       null,
    weightrcvd     number(13,4)     null,
    cubercvd       number(10,4)     null,
    amtrcvd        number(10,2)     null,
    comment1       long             null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    statususer     varchar2(12)     null,
    statusupdate   date             null,
    facility       varchar2(3)      null,
    delpointtype   char(1)          null,
    delappt        date             null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.loadstopbolcomments
(
    loadno     number(7)    not null,
    stopno     number(7)    not null,
    bolcomment long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.loadstopship
(
    loadno      number(7)        null,
    stopno      number(7)        null,
    shipno      number(7)        null,
    entrydate   date             null,
    qtyorder    number(10)       null,
    weightorder number(13,4)     null,
    cubeorder   number(10,4)     null,
    amtorder    number(10,2)     null,
    qtyship     number(10)       null,
    weightship  number(13,4)     null,
    cubeship    number(10,4)     null,
    amtship     number(10,2)     null,
    qtyrcvd     number(10)       null,
    weightrcvd  number(13,4)     null,
    cubercvd    number(10,4)     null,
    amtrcvd     number(10,2)     null,
    comment1    long             null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null,
    carrier     varchar2(4)      null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.loadstopshipbolcomments
(
    loadno     number(7)    not null,
    stopno     number(7)    not null,
    shipno     number(7)    not null,
    bolcomment long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.loadtypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.location
(
    locid           varchar2(10) not null,
    facility        varchar2(3)  not null,
    custid          varchar2(10)     null,
    loctype         varchar2(3)      null,
    storagetype     varchar2(2)      null,
    section         varchar2(10)     null,
    checkdigit      varchar2(2)      null,
    status          varchar2(2)      null,
    pickingseq      number(7)        null,
    pickingzone     varchar2(10)     null,
    putawayseq      number(7)        null,
    putawayzone     varchar2(10)     null,
    inboundzone     varchar2(10)     null,
    outboundzone    varchar2(10)     null,
    panddlocation   varchar2(10)     null,
    equipprof       varchar2(2)      null,
    velocity        varchar2(1)      null,
    mixeditemsok    varchar2(1)      null,
    mixedlotsok     varchar2(1)      null,
    mixeduomok      varchar2(1)      null,
    dropcount       number(9)        null,
    pickcount       number(9)        null,
    dedicateditem   varchar2(20)     null,
    lastcounted     date             null,
    countinterval   number(4)        null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    unitofstorage   varchar2(4)      null,
    descr           varchar2(36)     null,
    weightlimit     number(13,4)     null,
    lpcount         number(7)        null,
    aisle           varchar2(5)      null,
    stackheight     number(3)        null,
    lastpickedfrom  date             null,
    lastputawayto   date             null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.locationattributes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.locationstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.locationtypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.lotreceiptcapture
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.ltlfreightclass
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.mass_manifest_ctn
(
   ctnid     varchar2(15)  null,
   orderid   number(9)     null,
   shipid    number(2)     null,
   item      varchar2(20)  null,
   lotnumber varchar2(30)  null,
   seq       number(7)     null,
   seqof     number(7)     null,
   used      char(1)       null,
   wave      number(9)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.messageauthors
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.messagestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.messagetypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.movementchangereasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.multishipdtl
(
    orderid              number(9)     not null,
    shipid               number(2)     not null,
    cartonid             varchar2(15)  not null,
    estweight            number(13,4)      null,
    actweight            number(13,4)      null,
    trackid              varchar2(20)      null,
    status               varchar2(10)      null,
    shipdatetime         varchar2(14)      null,
    carrierused          varchar2(10)      null,
    reason               varchar2(100)     null,
    cost                 number(10,2)      null,
    termid               varchar2(4)       null,
    satdeliveryused      varchar2(1)       null,
    packlistshipdatetime varchar2(14)      null,
    length               number(10,4)      null,
    width                number(10,4)      null,
    height               number(10,4)      null,
    dtlpassthruchar01    varchar2(255)     null,
    dtlpassthruchar02    varchar2(255)     null,
    dtlpassthruchar03    varchar2(255)     null,
    dtlpassthruchar04    varchar2(255)     null,
    dtlpassthruchar05    varchar2(255)     null,
    dtlpassthruchar06    varchar2(255)     null,
    dtlpassthruchar07    varchar2(255)     null,
    dtlpassthruchar08    varchar2(255)     null,
    dtlpassthruchar09    varchar2(255)     null,
    dtlpassthruchar10    varchar2(255)     null,
    dtlpassthruchar11    varchar2(255)     null,
    dtlpassthruchar12    varchar2(255)     null,
    dtlpassthruchar13    varchar2(255)     null,
    dtlpassthruchar14    varchar2(255)     null,
    dtlpassthruchar15    varchar2(255)     null,
    dtlpassthruchar16    varchar2(255)     null,
    dtlpassthruchar17    varchar2(255)     null,
    dtlpassthruchar18    varchar2(255)     null,
    dtlpassthruchar19    varchar2(255)     null,
    dtlpassthruchar20    varchar2(255)     null,
    dtlpassthrunum01     number(16,4)      null,
    dtlpassthrunum02     number(16,4)      null,
    dtlpassthrunum03     number(16,4)      null,
    dtlpassthrunum04     number(16,4)      null,
    dtlpassthrunum05     number(16,4)      null,
    dtlpassthrunum06     number(16,4)      null,
    dtlpassthrunum07     number(16,4)      null,
    dtlpassthrunum08     number(16,4)      null,
    dtlpassthrunum09     number(16,4)      null,
    dtlpassthrunum10     number(16,4)      null,
    rmatrackingno        varchar2(20)      null,
    actualcarrier        varchar2(4)       null,
    dtlpassthrudate01    date              null,
    dtlpassthrudate02    date              null,
    dtlpassthrudate03    date              null,
    dtlpassthrudate04    date              null,
    dtlpassthrudoll01    number(10,2)      null,
    dtlpassthrudoll02    number(10,2)      null,
	 datetimeshipped      date
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.multishiphdr
(
    orderid           number(9)     not null,
    shipid            number(2)     not null,
    custid            varchar2(10)  not null,
    shiptoname        varchar2(40)      null,
    shiptocontact     varchar2(40)      null,
    shiptoaddr1       varchar2(40)      null,
    shiptoaddr2       varchar2(40)      null,
    shiptocity        varchar2(30)      null,
    shiptostate       varchar2(2)       null,
    shiptopostalcode  varchar2(12)      null,
    shiptocountrycode varchar2(3)       null,
    shiptophone       varchar2(25)      null,
    carrier           varchar2(10)      null,
    carriercode       varchar2(4)       null,
    specialservice1   varchar2(30)      null,
    specialservice2   varchar2(30)      null,
    specialservice3   varchar2(30)      null,
    specialservice4   varchar2(30)      null,
    terms             varchar2(3)       null,
    satdelivery       varchar2(1)       null,
    orderstatus       varchar2(1)       null,
    orderpriority     varchar2(1)       null,
    ordercomments     varchar2(80)      null,
    reference         varchar2(20)      null,
    cod               varchar2(1)       null,
    amtcod            number(10,2)      null,
    hdrpassthruchar20 varchar2(255)     null,
    hdrpassthruchar19 varchar2(255)     null,
    shipdate          date              null,
    po                varchar2(20)      null,
    hdrpassthruchar01 varchar2(255)     null,
    hdrpassthruchar02 varchar2(255)     null,
    hdrpassthruchar03 varchar2(255)     null,
    hdrpassthruchar04 varchar2(255)     null,
    hdrpassthruchar05 varchar2(255)     null,
    hdrpassthruchar06 varchar2(255)     null,
    hdrpassthruchar07 varchar2(255)     null,
    hdrpassthruchar08 varchar2(255)     null,
    hdrpassthruchar09 varchar2(255)     null,
    hdrpassthruchar10 varchar2(255)     null,
    hdrpassthruchar11 varchar2(255)     null,
    hdrpassthruchar12 varchar2(255)     null,
    hdrpassthruchar13 varchar2(255)     null,
    hdrpassthruchar14 varchar2(255)     null,
    hdrpassthruchar15 varchar2(255)     null,
    hdrpassthruchar16 varchar2(255)     null,
    hdrpassthruchar17 varchar2(255)     null,
    hdrpassthruchar18 varchar2(255)     null,
    hdrpassthrunum01  number(16,4)      null,
    hdrpassthrunum02  number(16,4)      null,
    hdrpassthrunum03  number(16,4)      null,
    hdrpassthrunum04  number(16,4)      null,
    hdrpassthrunum05  number(16,4)      null,
    hdrpassthrunum06  number(16,4)      null,
    hdrpassthrunum07  number(16,4)      null,
    hdrpassthrunum08  number(16,4)      null,
    hdrpassthrunum09  number(16,4)      null,
    hdrpassthrunum10  number(16,4)      null,
    hdrpassthrudate01 date              null,
    hdrpassthrudate02 date              null,
    hdrpassthrudate03 date              null,
    hdrpassthrudate04 date              null,
    hdrpassthrudoll01 number(10,2)      null,
    hdrpassthrudoll02 number(10,2)      null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.multishipterminal
(
    facility    varchar2(3)   not null,
    termid      varchar2(4)   not null,
    descr       varchar2(200)     null,
    packprinter varchar2(255)     null,
    lastuser    varchar2(12)      null,
    lastupdate  date              null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.nationalmotorfreightclass
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.neworderdtl
(
    chgdate           date              null,
    chguser           varchar2(12)      null,
    chgrowid          varchar2(20)      null,
    orderid           number(9)     not null,
    shipid            number(2)     not null,
    item              varchar2(20)      null,
    uom               varchar2(4)       null,
    linestatus        varchar2(1)       null,
    qtyentered        number(10)        null,
    itementered       varchar2(20)      null,
    uomentered        varchar2(4)       null,
    qtyorder          number(10)        null,
    weightorder       number(13,4)      null,
    cubeorder         number(10,4)      null,
    amtorder          number(10,2)      null,
    lastuser          varchar2(12)      null,
    lastupdate        date              null,
    priority          varchar2(1)       null,
    lotnumber         varchar2(30)      null,
    backorder         varchar2(1)       null,
    allowsub          varchar2(1)       null,
    qtytype           varchar2(1)       null,
    invstatusind      varchar2(1)       null,
    invstatus         varchar2(255)     null,
    invclassind       varchar2(1)       null,
    inventoryclass    varchar2(255)     null,
    consigneesku      varchar2(20)      null,
    dtlpassthruchar01 varchar2(255)     null,
    dtlpassthruchar02 varchar2(255)     null,
    dtlpassthruchar03 varchar2(255)     null,
    dtlpassthruchar04 varchar2(255)     null,
    dtlpassthruchar05 varchar2(255)     null,
    dtlpassthruchar06 varchar2(255)     null,
    dtlpassthruchar07 varchar2(255)     null,
    dtlpassthruchar08 varchar2(255)     null,
    dtlpassthruchar09 varchar2(255)     null,
    dtlpassthruchar10 varchar2(255)     null,
    dtlpassthruchar11 varchar2(255)     null,
    dtlpassthruchar12 varchar2(255)     null,
    dtlpassthruchar13 varchar2(255)     null,
    dtlpassthruchar14 varchar2(255)     null,
    dtlpassthruchar15 varchar2(255)     null,
    dtlpassthruchar16 varchar2(255)     null,
    dtlpassthruchar17 varchar2(255)     null,
    dtlpassthruchar18 varchar2(255)     null,
    dtlpassthruchar19 varchar2(255)     null,
    dtlpassthruchar20 varchar2(255)     null,
    dtlpassthrunum01  number(16,4)      null,
    dtlpassthrunum02  number(16,4)      null,
    dtlpassthrunum03  number(16,4)      null,
    dtlpassthrunum04  number(16,4)      null,
    dtlpassthrunum05  number(16,4)      null,
    dtlpassthrunum06  number(16,4)      null,
    dtlpassthrunum07  number(16,4)      null,
    dtlpassthrunum08  number(16,4)      null,
    dtlpassthrunum09  number(16,4)      null,
    dtlpassthrunum10  number(16,4)      null,
    dtlpassthrudate01 date              null,
    dtlpassthrudate02 date              null,
    dtlpassthrudate03 date              null,
    dtlpassthrudate04 date              null,
    dtlpassthrudoll01 number(10,2)      null,
    dtlpassthrudoll02 number(10,2)      null
)
tablespace synapse_ohis_data
pctfree 10
pctused 70
/

create table alps.neworderhdr
(
    chgdate             date              null,
    chguser             varchar2(12)      null,
    orderid             number(9)     not null,
    shipid              number(2)     not null,
    custid              varchar2(10)      null,
    ordertype           varchar2(1)       null,
    entrydate           date              null,
    apptdate            date              null,
    shipdate            date              null,
    po                  varchar2(20)      null,
    rma                 varchar2(20)      null,
    orderstatus         varchar2(1)       null,
    commitstatus        varchar2(1)       null,
    fromfacility        varchar2(3)       null,
    tofacility          varchar2(3)       null,
    loadno              number(7)         null,
    stopno              number(7)         null,
    shipno              number(7)         null,
    shipto              varchar2(10)      null,
    delarea             varchar2(3)       null,
    qtyorder            number(10)        null,
    weightorder         number(13,4)      null,
    cubeorder           number(10,4)      null,
    amtorder            number(10,2)      null,
    lastuser            varchar2(12)      null,
    lastupdate          date              null,
    billoflading        varchar2(40)      null,
    priority            varchar2(1)       null,
    shipper             varchar2(10)      null,
    arrivaldate         date              null,
    consignee           varchar2(10)      null,
    shiptype            varchar2(1)       null,
    carrier             varchar2(10)      null,
    reference           varchar2(20)      null,
    shipterms           varchar2(3)       null,
    wave                number(9)         null,
    stageloc            varchar2(10)      null,
    shiptoname          varchar2(40)      null,
    shiptocontact       varchar2(40)      null,
    shiptoaddr1         varchar2(40)      null,
    shiptoaddr2         varchar2(40)      null,
    shiptocity          varchar2(30)      null,
    shiptostate         varchar2(2)       null,
    shiptopostalcode    varchar2(12)      null,
    shiptocountrycode   varchar2(3)       null,
    shiptophone         varchar2(25)      null,
    shiptofax           varchar2(25)      null,
    shiptoemail         varchar2(255)     null,
    billtoname          varchar2(40)      null,
    billtocontact       varchar2(40)      null,
    billtoaddr1         varchar2(40)      null,
    billtoaddr2         varchar2(40)      null,
    billtocity          varchar2(30)      null,
    billtostate         varchar2(2)       null,
    billtopostalcode    varchar2(12)      null,
    billtocountrycode   varchar2(3)       null,
    billtophone         varchar2(25)      null,
    billtofax           varchar2(25)      null,
    billtoemail         varchar2(255)     null,
    deliveryservice     varchar2(4)       null,
    saturdaydelivery    char(1)           null,
    specialservice1     varchar2(4)       null,
    specialservice2     varchar2(4)       null,
    specialservice3     varchar2(4)       null,
    specialservice4     varchar2(4)       null,
    cod                 char(1)           null,
    amtcod              number(10,2)      null,
    hdrpassthruchar01   varchar2(255)     null,
    hdrpassthruchar02   varchar2(255)     null,
    hdrpassthruchar03   varchar2(255)     null,
    hdrpassthruchar04   varchar2(255)     null,
    hdrpassthruchar05   varchar2(255)     null,
    hdrpassthruchar06   varchar2(255)     null,
    hdrpassthruchar07   varchar2(255)     null,
    hdrpassthruchar08   varchar2(255)     null,
    hdrpassthruchar09   varchar2(255)     null,
    hdrpassthruchar10   varchar2(255)     null,
    hdrpassthruchar11   varchar2(255)     null,
    hdrpassthruchar12   varchar2(255)     null,
    hdrpassthruchar13   varchar2(255)     null,
    hdrpassthruchar14   varchar2(255)     null,
    hdrpassthruchar15   varchar2(255)     null,
    hdrpassthruchar16   varchar2(255)     null,
    hdrpassthruchar17   varchar2(255)     null,
    hdrpassthruchar18   varchar2(255)     null,
    hdrpassthruchar19   varchar2(255)     null,
    hdrpassthruchar20   varchar2(255)     null,
    hdrpassthrunum01    number(16,4)      null,
    hdrpassthrunum02    number(16,4)      null,
    hdrpassthrunum03    number(16,4)      null,
    hdrpassthrunum04    number(16,4)      null,
    hdrpassthrunum05    number(16,4)      null,
    hdrpassthrunum06    number(16,4)      null,
    hdrpassthrunum07    number(16,4)      null,
    hdrpassthrunum08    number(16,4)      null,
    hdrpassthrunum09    number(16,4)      null,
    hdrpassthrunum10    number(16,4)      null,
    ftz216authorization varchar2(20)      null,
    shippername         varchar2(40)      null,
    shippercontact      varchar2(40)      null,
    shipperaddr1        varchar2(40)      null,
    shipperaddr2        varchar2(40)      null,
    shippercity         varchar2(30)      null,
    shipperstate        varchar2(2)       null,
    shipperpostalcode   varchar2(12)      null,
    shippercountrycode  varchar2(3)       null,
    shipperphone        varchar2(15)      null,
    shipperfax          varchar2(15)      null,
    shipperemail        varchar2(255)     null,
    hdrpassthrudate01   date              null,
    hdrpassthrudate02   date              null,
    hdrpassthrudate03   date              null,
    hdrpassthrudate04   date              null,
    hdrpassthrudoll01   number(10,2)      null,
    hdrpassthrudoll02   number(10,2)      null
)
tablespace synapse_ohis_data
pctfree 10
pctused 70
/

create table alps.nixedpickloc
(
    nameid   varchar2(12) not null,
    facility varchar2(3)  not null,
    location varchar2(10) not null,
    nixedat  date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.nixedputloc
(
    lpid     varchar2(15) not null,
    nameid   varchar2(12) not null,
    facility varchar2(10) not null,
    location varchar2(10) not null,
    nixedat  date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.nmfclasscodes
(
    nmfc       varchar2(12)  not null,
    descr      varchar2(255) not null,
    abbrev     varchar2(12)  not null,
    lastuser   varchar2(12)      null,
    lastupdate date              null,
    class      number(4,1)       null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.nontaskactivities
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.notify_type
(
    type varchar2(10) not null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.oldexp_afterprocessprocparams
(
    definc    number(4)    not null,
    lineinc   number(4)    not null,
    paramname varchar2(25) not null,
    chunkinc  number(4)        null,
    defvalue  varchar2(35)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.oldexp_chunks
(
    definc             number(4)    not null,
    lineinc            number(4)    not null,
    chunkinc           number(4)    not null,
    chunktype          number(2)        null,
    paramname          varchar2(35)     null,
    offset             number(8)        null,
    length             number(8)        null,
    defvalue           varchar2(35)     null,
    description        varchar2(35)     null,
    lktable            varchar2(35)     null,
    lkfield            varchar2(35)     null,
    lkkey              varchar2(35)     null,
    mappings           long             null,
    parentlineparam    varchar2(35)     null,
    chunkdecimals      char(1)          null,
    fieldprefix        varchar2(255)    null,
    substring_position number(7)        null,
    substring_length   number(7)        null,
    no_fieldprefix_on_null_value char(1) null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.oldexp_definitions
(
    definc                  number(4)      not null,
    name                    varchar2(35)   not null,
    targetalias             varchar2(35)   not null,
    deffilename             varchar2(200)      null,
    dateformat              varchar2(20)       null,
    deftype                 char(1)            null,
    floatdecimals           number(4)          null,
    amountdecimals          number(4)          null,
    linelength              number(8)          null,
    afterprocessproc        varchar2(35)       null,
    beforeprocessproc       varchar2(35)       null,
    afterprocessprocparams  varchar2(1000)     null,
    beforeprocessprocparams varchar2(1000)     null,
    timeformat              varchar2(20)       null,
    includecrlf             char(1)            null,
    separatefiles           char(1)            null,
    sip_format_yn           char(1)            null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.oldexp_lines
(
    definc               number(4)     not null,
    lineinc              number(4)     not null,
    parent               number(2)         null,
    type                 number(2)         null,
    identifier           varchar2(15)      null,
    delimiter            varchar2(1)       null,
    linealias            varchar2(35)      null,
    procname             varchar2(35)      null,
    delimiteroffset      number(4)         null,
    afterprocessprocname varchar2(35)      null,
    headertrailerflag    char(1)           null,
    orderbycolumns       varchar2(255)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.oldorderdtl
(
    chgdate           date              null,
    chguser           varchar2(12)      null,
    chgrowid          varchar2(20)      null,
    orderid           number(9)     not null,
    shipid            number(2)     not null,
    item              varchar2(20)      null,
    uom               varchar2(4)       null,
    linestatus        varchar2(1)       null,
    qtyentered        number(10)        null,
    itementered       varchar2(20)      null,
    uomentered        varchar2(4)       null,
    qtyorder          number(10)        null,
    weightorder       number(13,4)      null,
    cubeorder         number(10,4)      null,
    amtorder          number(10,2)      null,
    lastuser          varchar2(12)      null,
    lastupdate        date              null,
    priority          varchar2(1)       null,
    lotnumber         varchar2(30)      null,
    backorder         varchar2(1)       null,
    allowsub          varchar2(1)       null,
    qtytype           varchar2(1)       null,
    invstatusind      varchar2(1)       null,
    invstatus         varchar2(255)     null,
    invclassind       varchar2(1)       null,
    inventoryclass    varchar2(255)     null,
    consigneesku      varchar2(20)      null,
    dtlpassthruchar01 varchar2(255)     null,
    dtlpassthruchar02 varchar2(255)     null,
    dtlpassthruchar03 varchar2(255)     null,
    dtlpassthruchar04 varchar2(255)     null,
    dtlpassthruchar05 varchar2(255)     null,
    dtlpassthruchar06 varchar2(255)     null,
    dtlpassthruchar07 varchar2(255)     null,
    dtlpassthruchar08 varchar2(255)     null,
    dtlpassthruchar09 varchar2(255)     null,
    dtlpassthruchar10 varchar2(255)     null,
    dtlpassthruchar11 varchar2(255)     null,
    dtlpassthruchar12 varchar2(255)     null,
    dtlpassthruchar13 varchar2(255)     null,
    dtlpassthruchar14 varchar2(255)     null,
    dtlpassthruchar15 varchar2(255)     null,
    dtlpassthruchar16 varchar2(255)     null,
    dtlpassthruchar17 varchar2(255)     null,
    dtlpassthruchar18 varchar2(255)     null,
    dtlpassthruchar19 varchar2(255)     null,
    dtlpassthruchar20 varchar2(255)     null,
    dtlpassthrunum01  number(16,4)      null,
    dtlpassthrunum02  number(16,4)      null,
    dtlpassthrunum03  number(16,4)      null,
    dtlpassthrunum04  number(16,4)      null,
    dtlpassthrunum05  number(16,4)      null,
    dtlpassthrunum06  number(16,4)      null,
    dtlpassthrunum07  number(16,4)      null,
    dtlpassthrunum08  number(16,4)      null,
    dtlpassthrunum09  number(16,4)      null,
    dtlpassthrunum10  number(16,4)      null,
    dtlpassthrudate01 date              null,
    dtlpassthrudate02 date              null,
    dtlpassthrudate03 date              null,
    dtlpassthrudate04 date              null,
    dtlpassthrudoll01 number(10,2)      null,
    dtlpassthrudoll02 number(10,2)      null
)
tablespace synapse_ohis_data
pctfree 10
pctused 70
/

create table alps.oldorderhdr
(
    chgdate             date              null,
    chguser             varchar2(12)      null,
    orderid             number(9)     not null,
    shipid              number(2)     not null,
    custid              varchar2(10)      null,
    ordertype           varchar2(1)       null,
    entrydate           date              null,
    apptdate            date              null,
    shipdate            date              null,
    po                  varchar2(20)      null,
    rma                 varchar2(20)      null,
    orderstatus         varchar2(1)       null,
    commitstatus        varchar2(1)       null,
    fromfacility        varchar2(3)       null,
    tofacility          varchar2(3)       null,
    loadno              number(7)         null,
    stopno              number(7)         null,
    shipno              number(7)         null,
    shipto              varchar2(10)      null,
    delarea             varchar2(3)       null,
    qtyorder            number(10)        null,
    weightorder         number(13,4)      null,
    cubeorder           number(10,4)      null,
    amtorder            number(10,2)      null,
    lastuser            varchar2(12)      null,
    lastupdate          date              null,
    billoflading        varchar2(40)      null,
    priority            varchar2(1)       null,
    shipper             varchar2(10)      null,
    arrivaldate         date              null,
    consignee           varchar2(10)      null,
    shiptype            varchar2(1)       null,
    carrier             varchar2(10)      null,
    reference           varchar2(20)      null,
    shipterms           varchar2(3)       null,
    wave                number(9)         null,
    stageloc            varchar2(10)      null,
    shiptoname          varchar2(40)      null,
    shiptocontact       varchar2(40)      null,
    shiptoaddr1         varchar2(40)      null,
    shiptoaddr2         varchar2(40)      null,
    shiptocity          varchar2(30)      null,
    shiptostate         varchar2(2)       null,
    shiptopostalcode    varchar2(12)      null,
    shiptocountrycode   varchar2(3)       null,
    shiptophone         varchar2(25)      null,
    shiptofax           varchar2(25)      null,
    shiptoemail         varchar2(255)     null,
    billtoname          varchar2(40)      null,
    billtocontact       varchar2(40)      null,
    billtoaddr1         varchar2(40)      null,
    billtoaddr2         varchar2(40)      null,
    billtocity          varchar2(30)      null,
    billtostate         varchar2(2)       null,
    billtopostalcode    varchar2(12)      null,
    billtocountrycode   varchar2(3)       null,
    billtophone         varchar2(25)      null,
    billtofax           varchar2(25)      null,
    billtoemail         varchar2(255)     null,
    deliveryservice     varchar2(4)       null,
    saturdaydelivery    char(1)           null,
    specialservice1     varchar2(4)       null,
    specialservice2     varchar2(4)       null,
    specialservice3     varchar2(4)       null,
    specialservice4     varchar2(4)       null,
    cod                 char(1)           null,
    amtcod              number(10,2)      null,
    hdrpassthruchar01   varchar2(255)     null,
    hdrpassthruchar02   varchar2(255)     null,
    hdrpassthruchar03   varchar2(255)     null,
    hdrpassthruchar04   varchar2(255)     null,
    hdrpassthruchar05   varchar2(255)     null,
    hdrpassthruchar06   varchar2(255)     null,
    hdrpassthruchar07   varchar2(255)     null,
    hdrpassthruchar08   varchar2(255)     null,
    hdrpassthruchar09   varchar2(255)     null,
    hdrpassthruchar10   varchar2(255)     null,
    hdrpassthruchar11   varchar2(255)     null,
    hdrpassthruchar12   varchar2(255)     null,
    hdrpassthruchar13   varchar2(255)     null,
    hdrpassthruchar14   varchar2(255)     null,
    hdrpassthruchar15   varchar2(255)     null,
    hdrpassthruchar16   varchar2(255)     null,
    hdrpassthruchar17   varchar2(255)     null,
    hdrpassthruchar18   varchar2(255)     null,
    hdrpassthruchar19   varchar2(255)     null,
    hdrpassthruchar20   varchar2(255)     null,
    hdrpassthrunum01    number(16,4)      null,
    hdrpassthrunum02    number(16,4)      null,
    hdrpassthrunum03    number(16,4)      null,
    hdrpassthrunum04    number(16,4)      null,
    hdrpassthrunum05    number(16,4)      null,
    hdrpassthrunum06    number(16,4)      null,
    hdrpassthrunum07    number(16,4)      null,
    hdrpassthrunum08    number(16,4)      null,
    hdrpassthrunum09    number(16,4)      null,
    hdrpassthrunum10    number(16,4)      null,
    ftz216authorization varchar2(20)      null,
    shippername         varchar2(40)      null,
    shippercontact      varchar2(40)      null,
    shipperaddr1        varchar2(40)      null,
    shipperaddr2        varchar2(40)      null,
    shippercity         varchar2(30)      null,
    shipperstate        varchar2(2)       null,
    shipperpostalcode   varchar2(12)      null,
    shippercountrycode  varchar2(3)       null,
    shipperphone        varchar2(15)      null,
    shipperfax          varchar2(15)      null,
    shipperemail        varchar2(255)     null,
    hdrpassthrudate01   date              null,
    hdrpassthrudate02   date              null,
    hdrpassthrudate03   date              null,
    hdrpassthrudate04   date              null,
    hdrpassthrudoll01   number(10,2)      null,
    hdrpassthrudoll02   number(10,2)      null
)
tablespace synapse_ohis_data
pctfree 10
pctused 70
/

create table alps.ordercancellationreasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.ordercheck
(
    facility   varchar2(3)      null,
    location   varchar2(10)     null,
    orderid    number(9)        null,
    shipid     number(2)        null,
    lpid       varchar2(15)     null,
    lpitem     varchar2(20)     null,
    lplot      varchar2(30)     null,
    lpqty      number(7)        null,
    lpuom      varchar2(4)      null,
    entlpid    varchar2(15)     null,
    entitem    varchar2(20)     null,
    entlot     varchar2(30)     null,
    entqty     number(7)        null,
    entuom     varchar2(4)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    complete   varchar2(1)      null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderdtl
(
    orderid           number(9)     not null,
    shipid            number(2)     not null,
    item              varchar2(20)  not null,
    custid            varchar2(10)      null,
    fromfacility      varchar2(3)       null,
    uom               varchar2(4)       null,
    linestatus        varchar2(1)       null,
    commitstatus      varchar2(1)       null,
    qtyentered        number(10)        null,
    itementered       varchar2(20)      null,
    uomentered        varchar2(4)       null,
    qtyorder          number(10)        null,
    weightorder       number(13,4)      null,
    cubeorder         number(10,4)      null,
    amtorder          number(10,2)      null,
    qtycommit         number(10)        null,
    weightcommit      number(13,4)      null,
    cubecommit        number(10,4)      null,
    amtcommit         number(10,2)      null,
    qtyship           number(10)        null,
    weightship        number(13,4)      null,
    cubeship          number(10,4)      null,
    amtship           number(10,2)      null,
    qtytotcommit      number(10)        null,
    weighttotcommit   number(13,4)      null,
    cubetotcommit     number(10,4)      null,
    amttotcommit      number(10,2)      null,
    qtyrcvd           number(10)        null,
    weightrcvd        number(13,4)      null,
    cubercvd          number(10,4)      null,
    amtrcvd           number(10,2)      null,
    qtyrcvdgood       number(10)        null,
    weightrcvdgood    number(13,4)      null,
    cubercvdgood      number(10,4)      null,
    amtrcvdgood       number(10,2)      null,
    qtyrcvddmgd       number(10)        null,
    weightrcvddmgd    number(13,4)      null,
    cubercvddmgd      number(10,4)      null,
    amtrcvddmgd       number(10,2)      null,
    comment1          long              null,
    statususer        varchar2(12)      null,
    statusupdate      date              null,
    lastuser          varchar2(12)      null,
    lastupdate        date              null,
    priority          varchar2(1)       null,
    lotnumber         varchar2(30)      null,
    backorder         varchar2(2)       null,
    allowsub          varchar2(1)       null,
    qtytype           varchar2(1)       null,
    invstatusind      varchar2(1)       null,
    invstatus         varchar2(255)     null,
    invclassind       varchar2(1)       null,
    inventoryclass    varchar2(255)     null,
    qtypick           number(10)        null,
    weightpick        number(13,4)      null,
    cubepick          number(10,4)      null,
    amtpick           number(10,2)      null,
    consigneesku      varchar2(20)      null,
    childorderid      number(9)         null,
    childshipid       number(2)         null,
    staffhrs          number(10,4)      null,
    qty2sort          number(10)        null,
    weight2sort       number(13,4)      null,
    cube2sort         number(10,4)      null,
    amt2sort          number(10,2)      null,
    qty2pack          number(10)        null,
    weight2pack       number(13,4)      null,
    cube2pack         number(10,4)      null,
    amt2pack          number(10,2)      null,
    qty2check         number(10)        null,
    weight2check      number(13,4)      null,
    cube2check        number(10,4)      null,
    amt2check         number(10,2)      null,
    dtlpassthruchar01 varchar2(255)     null,
    dtlpassthruchar02 varchar2(255)     null,
    dtlpassthruchar03 varchar2(255)     null,
    dtlpassthruchar04 varchar2(255)     null,
    dtlpassthruchar05 varchar2(255)     null,
    dtlpassthruchar06 varchar2(255)     null,
    dtlpassthruchar07 varchar2(255)     null,
    dtlpassthruchar08 varchar2(255)     null,
    dtlpassthruchar09 varchar2(255)     null,
    dtlpassthruchar10 varchar2(255)     null,
    dtlpassthruchar11 varchar2(255)     null,
    dtlpassthruchar12 varchar2(255)     null,
    dtlpassthruchar13 varchar2(255)     null,
    dtlpassthruchar14 varchar2(255)     null,
    dtlpassthruchar15 varchar2(255)     null,
    dtlpassthruchar16 varchar2(255)     null,
    dtlpassthruchar17 varchar2(255)     null,
    dtlpassthruchar18 varchar2(255)     null,
    dtlpassthruchar19 varchar2(255)     null,
    dtlpassthruchar20 varchar2(255)     null,
    dtlpassthrunum01  number(16,4)      null,
    dtlpassthrunum02  number(16,4)      null,
    dtlpassthrunum03  number(16,4)      null,
    dtlpassthrunum04  number(16,4)      null,
    dtlpassthrunum05  number(16,4)      null,
    dtlpassthrunum06  number(16,4)      null,
    dtlpassthrunum07  number(16,4)      null,
    dtlpassthrunum08  number(16,4)      null,
    dtlpassthrunum09  number(16,4)      null,
    dtlpassthrunum10  number(16,4)      null,
    asnvariance       char(1)           null,
    cancelreason      varchar2(12)      null,
    rfautodisplay     varchar2(1)       null,
    xdockorderid      number(9)         null,
    xdockshipid       number(2)         null,
    xdocklocid        varchar2(10)      null,
    qtyoverpick       number(10)        null,
    dtlpassthrudate01 date              null,
    dtlpassthrudate02 date              null,
    dtlpassthrudate03 date              null,
    dtlpassthrudate04 date              null,
    dtlpassthrudoll01 number(10,2)      null,
    dtlpassthrudoll02 number(10,2)      null,
    shipshortreason   varchar2(12)      null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderdtlbolcomments
(
    orderid    number(9)    not null,
    shipid     number(7)    not null,
    item       varchar2(20) not null,
    lotnumber  varchar2(30)     null,
    bolcomment long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderdtlline
(
    orderid           number(9)     not null,
    shipid            number(2)     not null,
    item              varchar2(20)  not null,
    lotnumber         varchar2(30)      null,
    linenumber        number(11)    not null,
    qty               number(10)        null,
    dtlpassthruchar01 varchar2(255)     null,
    dtlpassthruchar02 varchar2(255)     null,
    dtlpassthruchar03 varchar2(255)     null,
    dtlpassthruchar04 varchar2(255)     null,
    dtlpassthruchar05 varchar2(255)     null,
    dtlpassthruchar06 varchar2(255)     null,
    dtlpassthruchar07 varchar2(255)     null,
    dtlpassthruchar08 varchar2(255)     null,
    dtlpassthruchar09 varchar2(255)     null,
    dtlpassthruchar10 varchar2(255)     null,
    dtlpassthruchar11 varchar2(255)     null,
    dtlpassthruchar12 varchar2(255)     null,
    dtlpassthruchar13 varchar2(255)     null,
    dtlpassthruchar14 varchar2(255)     null,
    dtlpassthruchar15 varchar2(255)     null,
    dtlpassthruchar16 varchar2(255)     null,
    dtlpassthruchar17 varchar2(255)     null,
    dtlpassthruchar18 varchar2(255)     null,
    dtlpassthruchar19 varchar2(255)     null,
    dtlpassthruchar20 varchar2(255)     null,
    dtlpassthrunum01  number(16,4)      null,
    dtlpassthrunum02  number(16,4)      null,
    dtlpassthrunum03  number(16,4)      null,
    dtlpassthrunum04  number(16,4)      null,
    dtlpassthrunum05  number(16,4)      null,
    dtlpassthrunum06  number(16,4)      null,
    dtlpassthrunum07  number(16,4)      null,
    dtlpassthrunum08  number(16,4)      null,
    dtlpassthrunum09  number(16,4)      null,
    dtlpassthrunum10  number(16,4)      null,
    lastuser          varchar2(12)      null,
    lastupdate        date              null,
    dtlpassthrudate01 date              null,
    dtlpassthrudate02 date              null,
    dtlpassthrudate03 date              null,
    dtlpassthrudate04 date              null,
    dtlpassthrudoll01 number(10,2)      null,
    dtlpassthrudoll02 number(10,2)      null,
    qtyapproved       number(10)        null,
    uomentered        varchar2(4)       null,
    qtyentered        number(10)        null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderdtlrcpt
(
    orderid        number(9)    not null,
    shipid         number(2)    not null,
    orderitem      varchar2(20) not null,
    orderlot       varchar2(30)     null,
    facility       varchar2(3)      null,
    custid         varchar2(10)     null,
    item           varchar2(20)     null,
    lotnumber      varchar2(30)     null,
    uom            varchar2(4)      null,
    inventoryclass varchar2(2)      null,
    invstatus      varchar2(2)      null,
    lpid           varchar2(15)     null,
    qtyrcvd        number(10)       null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    qtyrcvdgood    number(10)       null,
    qtyrcvddmgd    number(10)       null,
    serialnumber   varchar2(30)     null,
    useritem1      varchar2(20)     null,
    useritem2      varchar2(20)     null,
    useritem3      varchar2(20)     null,
    deleteflag     char(1)          null,
	 weight         number(13,4)     null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderhdr
(
    orderid                    number(9)     not null,
    shipid                     number(2)     not null,
    custid                     varchar2(10)  not null,
    ordertype                  varchar2(1)   not null,
    entrydate                  date              null,
    apptdate                   date              null,
    shipdate                   date              null,
    po                         varchar2(20)      null,
    rma                        varchar2(20)      null,
    orderstatus                varchar2(1)       null,
    commitstatus               varchar2(1)       null,
    fromfacility               varchar2(3)       null,
    tofacility                 varchar2(3)       null,
    loadno                     number(7)         null,
    stopno                     number(7)         null,
    shipno                     number(7)         null,
    shipto                     varchar2(10)      null,
    delarea                    varchar2(3)       null,
    qtyorder                   number(10)        null,
    weightorder                number(13,4)      null,
    cubeorder                  number(10,4)      null,
    amtorder                   number(10,2)      null,
    qtycommit                  number(10)        null,
    weightcommit               number(13,4)      null,
    cubecommit                 number(10,4)      null,
    amtcommit                  number(10,2)      null,
    qtyship                    number(10)        null,
    weightship                 number(13,4)      null,
    cubeship                   number(10,4)      null,
    amtship                    number(10,2)      null,
    qtytotcommit               number(10)        null,
    weighttotcommit            number(13,4)      null,
    cubetotcommit              number(10,4)      null,
    amttotcommit               number(10,2)      null,
    qtyrcvd                    number(10)        null,
    weightrcvd                 number(13,4)      null,
    cubercvd                   number(10,4)      null,
    amtrcvd                    number(10,2)      null,
    comment1                   long              null,
    statususer                 varchar2(12)      null,
    statusupdate               date              null,
    lastuser                   varchar2(12)      null,
    lastupdate                 date              null,
    billoflading               varchar2(40)      null,
    priority                   varchar2(1)       null,
    shipper                    varchar2(10)      null,
    arrivaldate                date              null,
    consignee                  varchar2(10)      null,
    shiptype                   varchar2(1)       null,
    carrier                    varchar2(10)      null,
    reference                  varchar2(20)      null,
    shipterms                  varchar2(3)       null,
    wave                       number(9)         null,
    stageloc                   varchar2(10)      null,
    qtypick                    number(10)        null,
    weightpick                 number(13,4)      null,
    cubepick                   number(10,4)      null,
    amtpick                    number(10,2)      null,
    shiptoname                 varchar2(40)      null,
    shiptocontact              varchar2(40)      null,
    shiptoaddr1                varchar2(40)      null,
    shiptoaddr2                varchar2(40)      null,
    shiptocity                 varchar2(30)      null,
    shiptostate                varchar2(2)       null,
    shiptopostalcode           varchar2(12)      null,
    shiptocountrycode          varchar2(3)       null,
    shiptophone                varchar2(25)      null,
    shiptofax                  varchar2(25)      null,
    shiptoemail                varchar2(255)     null,
    billtoname                 varchar2(40)      null,
    billtocontact              varchar2(40)      null,
    billtoaddr1                varchar2(40)      null,
    billtoaddr2                varchar2(40)      null,
    billtocity                 varchar2(30)      null,
    billtostate                varchar2(2)       null,
    billtopostalcode           varchar2(12)      null,
    billtocountrycode          varchar2(3)       null,
    billtophone                varchar2(25)      null,
    billtofax                  varchar2(25)      null,
    billtoemail                varchar2(255)     null,
    parentorderid              number(9)         null,
    parentshipid               number(2)         null,
    parentorderitem            varchar2(20)      null,
    parentorderlot             varchar2(30)      null,
    workorderseq               number(8)         null,
    staffhrs                   number(10,4)      null,
    qty2sort                   number(10)        null,
    weight2sort                number(13,4)      null,
    cube2sort                  number(10,4)      null,
    amt2sort                   number(10,2)      null,
    qty2pack                   number(10)        null,
    weight2pack                number(13,4)      null,
    cube2pack                  number(10,4)      null,
    amt2pack                   number(10,2)      null,
    qty2check                  number(10)        null,
    weight2check               number(13,4)      null,
    cube2check                 number(10,4)      null,
    amt2check                  number(10,2)      null,
    importfileid               varchar2(255)     null,
    hdrpassthruchar01          varchar2(255)     null,
    hdrpassthruchar02          varchar2(255)     null,
    hdrpassthruchar03          varchar2(255)     null,
    hdrpassthruchar04          varchar2(255)     null,
    hdrpassthruchar05          varchar2(255)     null,
    hdrpassthruchar06          varchar2(255)     null,
    hdrpassthruchar07          varchar2(255)     null,
    hdrpassthruchar08          varchar2(255)     null,
    hdrpassthruchar09          varchar2(255)     null,
    hdrpassthruchar10          varchar2(255)     null,
    hdrpassthruchar11          varchar2(255)     null,
    hdrpassthruchar12          varchar2(255)     null,
    hdrpassthruchar13          varchar2(255)     null,
    hdrpassthruchar14          varchar2(255)     null,
    hdrpassthruchar15          varchar2(255)     null,
    hdrpassthruchar16          varchar2(255)     null,
    hdrpassthruchar17          varchar2(255)     null,
    hdrpassthruchar18          varchar2(255)     null,
    hdrpassthruchar19          varchar2(255)     null,
    hdrpassthruchar20          varchar2(255)     null,
    hdrpassthrunum01           number(16,4)      null,
    hdrpassthrunum02           number(16,4)      null,
    hdrpassthrunum03           number(16,4)      null,
    hdrpassthrunum04           number(16,4)      null,
    hdrpassthrunum05           number(16,4)      null,
    hdrpassthrunum06           number(16,4)      null,
    hdrpassthrunum07           number(16,4)      null,
    hdrpassthrunum08           number(16,4)      null,
    hdrpassthrunum09           number(16,4)      null,
    hdrpassthrunum10           number(16,4)      null,
    confirmed                  date              null,
    rejectcode                 number(6)         null,
    rejecttext                 varchar2(255)     null,
    dateshipped                date              null,
    origorderid                number(9)         null,
    origshipid                 number(2)         null,
    bulkretorderid             number(9)         null,
    bulkretshipid              number(2)         null,
    returntrackingno           varchar2(20)      null,
    packlistshipdate           date              null,
    edicancelpending           char(1)           null,
    deliveryservice            varchar2(4)       null,
    saturdaydelivery           char(1)           null,
    specialservice1            varchar2(4)       null,
    specialservice2            varchar2(4)       null,
    specialservice3            varchar2(4)       null,
    specialservice4            varchar2(4)       null,
    cod                        char(1)           null,
    amtcod                     number(10,2)      null,
    asnvariance                char(1)           null,
    backorderyn                char(1)           null,
    cancelreason               varchar2(12)      null,
    rfautodisplay              varchar2(1)       null,
    source                     varchar2(3)       null,
    transapptdate              date              null,
    deliveryaptconfname        varchar2(20)      null,
    interlinecarrier           varchar2(4)       null,
    companycheckok             char(1)           null,
    ftz216authorization        varchar2(20)      null,
    cancel_id                  varchar2(30)      null,
    cancelled_date             date              null,
    cancel_user_id             varchar2(12)      null,
    shippername                varchar2(40)      null,
    shippercontact             varchar2(40)      null,
    shipperaddr1               varchar2(40)      null,
    shipperaddr2               varchar2(40)      null,
    shippercity                varchar2(30)      null,
    shipperstate               varchar2(2)       null,
    shipperpostalcode          varchar2(12)      null,
    shippercountrycode         varchar2(3)       null,
    shipperphone               varchar2(15)      null,
    shipperfax                 varchar2(15)      null,
    shipperemail               varchar2(255)     null,
    prono                      varchar2(20)      null,
    componenttemplate          varchar2(20)      null,
    cancel_after               date              null,
    delivery_requested         date              null,
    requested_ship             date              null,
    ship_not_before            date              null,
    ship_no_later              date              null,
    cancel_if_not_delivered_by date              null,
    do_not_deliver_after       date              null,
    do_not_deliver_before      date              null,
    hdrpassthrudate01          date              null,
    hdrpassthrudate02          date              null,
    hdrpassthrudate03          date              null,
    hdrpassthrudate04          date              null,
    hdrpassthrudoll01          number(10,2)      null,
    hdrpassthrudoll02          number(10,2)      null,
    appointmentid              number(7)         null,
    tms_status                 varchar2(1)       null,
    tms_status_update          date              null,
    tms_shipment_id            varchar2(20)      null,
    tms_release_id             varchar2(20)      null,
    recent_order_id            varchar2(11)      null,
    shippingcost               number(10,2)
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderhdrbolcomments
(
    orderid    number(9)        null,
    shipid     number(7)        null,
    bolcomment long             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderhistory
(
    chgdate date           not null,
    orderid number(9)      not null,
    shipid  number(2)      not null,
    userid  varchar2(12)   not null,
    action  varchar2(20)   not null,
    lpid    varchar2(15)       null,
    item    varchar2(20)       null,
    lot     varchar2(30)       null,
    msg     varchar2(2000)     null
)
tablespace synapse_ohis_data
pctfree 10
pctused 40
/

create table alps.orderitemstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.orderlabor
(
    wave       number(9)        null,
    orderid    number(9)        null,
    shipid     number(2)        null,
    item       varchar2(20)     null,
    lotnumber  varchar2(30)     null,
    category   varchar2(4)      null,
    zoneid     varchar2(10)     null,
    uom        varchar2(4)      null,
    qty        number(10,4)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    custid     varchar2(10)     null,
    staffhrs   number(10,4)     null,
    facility   varchar2(3)      null
)
tablespace synapse_ord_data
pctfree 30
pctused 40
/

create table alps.orderpriority
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.orderquantitytypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.orderstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.ordertypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.ordervalidationerrors
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.p1pkcaselabels
(
    orderid number           null,
    shipid  number           null,
    custid  varchar2(10)     null,
    item    varchar2(20)     null,
    seq     number           null,
    seqof   number           null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.pallethistory
(
    custid     varchar2(10) not null,
    facility   varchar2(3)  not null,
    pallettype varchar2(12) not null,
    adjreason  varchar2(12)     null,
    loadno     number(7)        null,
    lastuser   varchar2(12) not null,
    lastupdate date         not null,
    carrier    varchar2(4)      null,
    comment1   varchar2(80)     null,
    orderid    number(9)        null,
    shipid     number(2)        null,
    inpallets  number(7)        null,
    outpallets number(7)        null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.palletinvadjreason
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.palletinventory
(
    custid     varchar2(10) not null,
    facility   varchar2(3)  not null,
    pallettype varchar2(12) not null,
    cnt        number(7)    not null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.pallettypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.parseentryfield
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.parserule
(
    ruleid       varchar2(10) not null,
    descr        varchar2(32)     null,
    serialnomask varchar2(30)     null,
    lotmask      varchar2(30)     null,
    user1mask    varchar2(30)     null,
    user2mask    varchar2(30)     null,
    user3mask    varchar2(30)     null,
    mfgdatemask  varchar2(30)     null,
    expdatemask  varchar2(30)     null,
    countrymask  varchar2(30)     null,
    lastuser     varchar2(12)     null,
    lastupdate   date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.physicalinventorydtl
(
    id                 number(7)    not null,
    facility           varchar2(3)  not null,
    custid             varchar2(10)     null,
    taskid             number(15)   not null,
    lpid               varchar2(15)     null,
    status             varchar2(2)      null,
    location           varchar2(10)     null,
    item               varchar2(20)     null,
    lotnumber          varchar2(30)     null,
    uom                varchar2(4)      null,
    systemcount        number(7)        null,
    usercount          number(7)        null,
    countby            varchar2(12)     null,
    countdate          date             null,
    countcount         number(3)        null,
    countlocation      varchar2(10)     null,
    countitem          varchar2(20)     null,
    countcustid        varchar2(10)     null,
    countlot           varchar2(30)     null,
    prev1countby       varchar2(12)     null,
    prev1countdate     date             null,
    prev1usercount     number(7)        null,
    prev1countlocation varchar2(10)     null,
    prev1countitem     varchar2(20)     null,
    prev1countcustid   varchar2(10)     null,
    prev1countlot      varchar2(30)     null,
    prev2countby       varchar2(12)     null,
    prev2countdate     date             null,
    prev2usercount     number(7)        null,
    prev2countlocation varchar2(10)     null,
    prev2countitem     varchar2(20)     null,
    prev2countcustid   varchar2(10)     null,
    prev2countlot      varchar2(30)     null,
    lastuser           varchar2(12)     null,
    lastupdate         date             null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.physicalinventoryhdr
(
    id         number(7)    not null,
    facility   varchar2(3)  not null,
    paper      varchar2(1)      null,
    status     varchar2(2)      null,
    zone       varchar2(10)     null,
    fromloc    varchar2(10)     null,
    toloc      varchar2(10)     null,
    requester  varchar2(12)     null,
    requested  date             null,
    lastuser   varchar2(12)     null,
    lastupdate date             null,
    custid     varchar2(10)     null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.physicalinventorystatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.pickdirections
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.pickrequestqueues
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.picktotypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.picktypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.plan_table
(
    statement_id    varchar2(30)      null,
    timestamp       date              null,
    remarks         varchar2(80)      null,
    operation       varchar2(30)      null,
    options         varchar2(30)      null,
    object_node     varchar2(128)     null,
    object_owner    varchar2(30)      null,
    object_name     varchar2(30)      null,
    object_instance number            null,
    object_type     varchar2(30)      null,
    optimizer       varchar2(255)     null,
    search_columns  number            null,
    id              number            null,
    parent_id       number            null,
    position        number            null,
    cost            number            null,
    cardinality     number            null,
    bytes           number            null,
    other_tag       varchar2(255)     null,
    partition_start varchar2(255)     null,
    partition_stop  varchar2(255)     null,
    partition_id    number            null,
    other           long              null,
    distribution    varchar2(30)      null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.plate
(
    lpid             varchar2(15) not null,
    item             varchar2(20)     null,
    custid           varchar2(10)     null,
    facility         varchar2(3)      null,
    location         varchar2(10)     null,
    status           varchar2(2)      null,
    holdreason       varchar2(2)      null,
    unitofmeasure    varchar2(4)      null,
    quantity         number(7)        null,
    type             varchar2(2)      null,
    serialnumber     varchar2(30)     null,
    lotnumber        varchar2(30)     null,
    creationdate     date             null,
    manufacturedate  date             null,
    expirationdate   date             null,
    expiryaction     varchar2(2)      null,
    lastcountdate    date             null,
    po               varchar2(20)     null,
    recmethod        varchar2(2)      null,
    condition        varchar2(2)      null,
    lastoperator     varchar2(12)     null,
    lasttask         varchar2(2)      null,
    fifodate         date             null,
    destlocation     varchar2(10)     null,
    destfacility     varchar2(3)      null,
    countryof        varchar2(3)      null,
    parentlpid       varchar2(15)     null,
    useritem1        varchar2(20)     null,
    useritem2        varchar2(20)     null,
    useritem3        varchar2(20)     null,
    disposition      varchar2(4)      null,
    lastuser         varchar2(12)     null,
    lastupdate       date             null,
    invstatus        varchar2(2)      null,
    qtyentered       number(7)        null,
    itementered      varchar2(20)     null,
    uomentered       varchar2(4)      null,
    inventoryclass   varchar2(2)      null,
    loadno           number(7)        null,
    stopno           number(7)        null,
    shipno           number(7)        null,
    orderid          number(9)        null,
    shipid           number(2)        null,
    weight           number(13,4)     null,
    adjreason        varchar2(2)      null,
    qtyrcvd          number(7)        null,
    controlnumber    varchar2(10)     null,
    qcdisposition    varchar2(2)      null,
    fromlpid         varchar2(15)     null,
    taskid           number(15)       null,
    dropseq          number(5)        null,
    fromshippinglpid varchar2(15)     null,
    workorderseq     number(8)        null,
    workordersubseq  number(8)        null,
    qtytasked        number(7)        null,
    childfacility    varchar2(3)      null,
    childitem        varchar2(20)     null,
    parentfacility   varchar2(3)      null,
    parentitem       varchar2(20)     null,
    prevlocation     varchar2(10)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.platehistory
(
    lpid            varchar2(15)     null,
    whenoccurred    date             null,
    item            varchar2(20)     null,
    custid          varchar2(10)     null,
    facility        varchar2(3)      null,
    location        varchar2(10)     null,
    status          varchar2(2)      null,
    holdreason      varchar2(2)      null,
    unitofmeasure   varchar2(4)      null,
    quantity        number(7)        null,
    type            varchar2(2)      null,
    serialnumber    varchar2(30)     null,
    lotnumber       varchar2(30)     null,
    manufacturedate date             null,
    expirationdate  date             null,
    expiryaction    varchar2(2)      null,
    po              varchar2(20)     null,
    recmethod       varchar2(2)      null,
    condition       varchar2(2)      null,
    lastoperator    varchar2(12)     null,
    lasttask        varchar2(2)      null,
    countryof       varchar2(3)      null,
    parentlpid      varchar2(15)     null,
    useritem1       varchar2(20)     null,
    useritem2       varchar2(20)     null,
    useritem3       varchar2(20)     null,
    disposition     varchar2(4)      null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    invstatus       varchar2(2)      null,
    qtyentered      number(7)        null,
    itementered     varchar2(20)     null,
    uomentered      varchar2(4)      null,
    inventoryclass  varchar2(2)      null,
    adjreason       varchar2(2)      null,
    weight          number(13,4)     null
)
tablespace synapse_his_data
pctfree 10
pctused 70
/

create table alps.postalcodes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.postdtl
(
    invoice   number(8)    not null,
    account   varchar2(75) not null,
    debit     number           null,
    credit    number           null,
    reference varchar2(30)     null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.posthdr
(
    type         char(1)          null,
    invoice      number(8)    not null,
    poststatus   char(1)          null,
    description  varchar2(30)     null,
    invdate      date         not null,
    postdate     date             null,
    transmitdate date             null,
    custid       varchar2(10) not null,
    amount       number           null,
    lastuser     varchar2(12)     null,
    lastupdate   date             null,
    facility     varchar2(3)      null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.printer
(
    prtid       varchar2(5)  not null,
    description varchar2(30)     null,
    type        varchar2(2)      null,
    queue       varchar2(20)     null,
    stock       varchar2(2)      null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null,
    facility    varchar2(3)      null,
    lpsprintno  number(7)        null,
    lpshost     varchar2(50)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.printerstock
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.printertypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.prodactivity852dtlex
(
    sessionid        varchar2(12)     null,
    custid           varchar2(10)     null,
    warehouse_id     varchar2(3)      null,
    item             varchar2(20)     null,
    activity_code    varchar2(2)      null,
    sequence         number           null,
    quantity         number           null,
    uom              varchar2(4)      null,
    ref_id_qualifier varchar2(2)      null,
    ref_id           varchar2(30)     null,
    qty_qualifier    varchar2(2)      null,
    assigned_number  varchar2(30)     null,
    dt_qualifier     varchar2(3)      null,
    activity_date    varchar2(8)      null,
    activity_time    varchar2(8)      null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.prodactivity852hdrex
(
    sessionid      varchar2(12)     null,
    custid         varchar2(10)     null,
    start_date     date             null,
    end_date       date             null,
    warehouse_name varchar2(40)     null,
    warehouse_id   varchar2(3)      null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.productgroups
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.pronostatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 10
pctused 40
/

create table alps.purgerules
(
    tablename     varchar2(30)  not null,
    rule1field    varchar2(30)      null,
    rule1operator varchar2(2)       null,
    rule1value    varchar2(100)     null,
    rule2field    varchar2(30)      null,
    rule2operator varchar2(2)       null,
    rule2value    varchar2(100)     null,
    rule3field    varchar2(30)      null,
    rule3operator varchar2(2)       null,
    rule3value    varchar2(100)     null,
    basedonfield  varchar2(30)      null,
    functionname  varchar2(30)      null,
    facilityfield varchar2(30)      null,
    custidfield   varchar2(30)      null,
    descr         varchar2(255)     null,
    lastuser      varchar2(12)      null,
    lastupdate    date              null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.purgerulesdtl
(
    tablename     varchar2(30)  not null,
    rule1field    varchar2(30)      null,
    rule1operator varchar2(2)       null,
    rule1value    varchar2(100)     null,
    rule2field    varchar2(30)      null,
    rule2operator varchar2(2)       null,
    rule2value    varchar2(100)     null,
    rule3field    varchar2(30)      null,
    rule3operator varchar2(2)       null,
    rule3value    varchar2(100)     null,
    custid        varchar2(10)      null,
    facility      varchar2(4)       null,
    daystokeep    number            null,
    lastuser      varchar2(12)      null,
    lastupdate    date              null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.purgetablelist
(
    parenttable varchar2(30)  not null,
    childtable  varchar2(30)      null,
    keyfield1   varchar2(30)      null,
    keyfield2   varchar2(30)      null,
    keyfield3   varchar2(30)      null,
    descr       varchar2(255)     null,
    lastuser    varchar2(12)      null,
    lastupdate  date              null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.putawaychangereasons
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.putawayconfirmations
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.putawayprof
(
    facility    varchar2(3)  not null,
    profid      varchar2(2)  not null,
    descr       varchar2(30)     null,
    abbrev      varchar2(12)     null,
    disposition varchar2(4)      null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.putawayprofline
(
    facility                  varchar2(3)   not null,
    profid                    varchar2(2)   not null,
    priority                  number(4)     not null,
    minuom                    number(12)        null,
    maxuom                    number(12)        null,
    uom                       varchar2(4)       null,
    invstatus                 varchar2(50)      null,
    inventoryclass            varchar2(50)      null,
    zoneid                    varchar2(10)  not null,
    locattribute              varchar2(2)       null,
    usevelocity               varchar2(1)       null,
    fitmethod                 varchar2(2)       null,
    lastuser                  varchar2(12)      null,
    lastupdate                date              null,
    productgroup              varchar2(255)     null,
    primaryhazardclass        varchar2(255)     null,
    putaway_during_picking_ok varchar2(1)       null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.putawayqueues
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.putawayunitdispositions
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.qcconditions
(
    code       varchar2(4)  not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.qcdispositions
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.qcrequest
(
    id             number(7)    not null,
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    status         varchar2(2)      null,
    item           varchar2(20)     null,
    lotnumber      varchar2(30)     null,
    supplier       varchar2(10)     null,
    type           varchar2(4)      null,
    orderid        number(9)        null,
    shipid         number(2)        null,
    begindate      date             null,
    enddate        date             null,
    sampletype     varchar2(4)      null,
    samplesize     number(7)        null,
    sampleuom      varchar2(4)      null,
    passpercent    number(3)        null,
    inspectrouting varchar2(3)      null,
    instructions   long             null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.qcrequesttype
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.qcresult
(
    id            number(7)    not null,
    orderid       number(9)    not null,
    shipid        number(2)    not null,
    supplier      varchar2(10)     null,
    receiptdate   date             null,
    inspectdate   date             null,
    qtyexpected   number(7)        null,
    qtytoinspect  number(7)        null,
    qtyreceived   number(7)        null,
    qtychecked    number(7)        null,
    qtypassed     number(7)        null,
    qtyfailed     number(7)        null,
    status        varchar2(2)      null,
    controlnumber varchar2(10)     null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    custid        varchar2(10)     null,
    item          varchar2(20)     null,
    lotnumber     varchar2(30)     null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.qcresultdtl
(
    id          number(7)    not null,
    orderid     number(9)    not null,
    shipid      number(2)    not null,
    lpid        varchar2(15) not null,
    qtyreceived number(7)        null,
    qtychecked  number(7)        null,
    qtypassed   number(7)        null,
    qtyfailed   number(7)        null,
    inspectdate date             null,
    inspector   varchar2(12)     null,
    disposition varchar2(2)      null,
    notes       long             null,
    condition   varchar2(4)      null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null,
    custid      varchar2(10)     null,
    item        varchar2(20)     null,
    lotnumber   varchar2(30)     null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.qcsampletype
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.qcstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.ratecalculationtypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.ratestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.rcptnote944ideex
(
    sessionid         varchar2(12)      null,
    custid            varchar2(10)      null,
    orderid           number(9)         null,
    shipid            number(2)         null,
    item              varchar2(20)      null,
    lotnumber         varchar2(30)      null,
    qty               number(7)         null,
    uom               varchar2(4)       null,
    condition         varchar2(2)       null,
    damagereason      varchar2(2)       null,
    line_number       varchar2(255)     null,
    origtrackingno    varchar2(20)      null,
    serialnumber      varchar2(30)      null,
    useritem1         varchar2(20)      null,
    useritem2         varchar2(20)      null,
    useritem3         varchar2(20)      null,
    qtyrcvd_invstatus varchar2(2)       null,
    orig_line_number  number(11)        null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.rcptnote944noteex
(
    sessionid varchar2(12)     null,
    custid    varchar2(10)     null,
    orderid   number(9)        null,
    shipid    number(2)        null,
    sequence  number(6)        null,
    qualifier varchar2(4)      null,
    note      varchar2(80)     null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.receiptcondition
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.renewalstoragemethod
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.replenishrequestqueues
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.report_security
(
    nameid      varchar2(12)  not null,
    report_name varchar2(255) not null,
    lastuser    varchar2(12)  not null,
    lastupdate  date              null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.requests
(
    facility   varchar2(3)   not null,
    reqtype    varchar2(12)  not null,
    descr      varchar2(36)  not null,
    str01      varchar2(255)     null,
    str02      varchar2(255)     null,
    str03      varchar2(255)     null,
    str04      varchar2(255)     null,
    str05      varchar2(255)     null,
    str06      varchar2(255)     null,
    str07      varchar2(255)     null,
    str08      varchar2(255)     null,
    str09      varchar2(255)     null,
    str10      varchar2(255)     null,
    flag01     varchar2(1)       null,
    flag02     varchar2(1)       null,
    flag03     varchar2(1)       null,
    flag04     varchar2(1)       null,
    flag05     varchar2(1)       null,
    flag06     varchar2(1)       null,
    flag07     varchar2(1)       null,
    flag08     varchar2(1)       null,
    flag09     varchar2(1)       null,
    flag10     varchar2(1)       null,
    num01      number(12,2)      null,
    num02      number(12,2)      null,
    num03      number(12,2)      null,
    num04      number(12,2)      null,
    num05      number(12,2)      null,
    date01     date              null,
    date02     date              null,
    date03     date              null,
    date04     date              null,
    date05     date              null,
    option01   varchar2(12)      null,
    option02   varchar2(12)      null,
    option03   varchar2(12)      null,
    option04   varchar2(12)      null,
    option05   varchar2(12)      null,
    text1      long              null,
    lastuser   varchar2(12)      null,
    lastupdate date              null,
    str11      varchar2(255)     null,
    str12      varchar2(255)     null,
    str13      varchar2(255)     null,
    num06      number(12,2)      null,
    str14      varchar2(255)     null,
    str15      varchar2(255)     null,
    num07      number(12,2)      null,
    num08      number(12,2)      null,
    date06     date              null,
    idx01      number(3)         null,
    idx02      number(4)         null,
    idx03      number(5)         null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.returnsdisposition
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.revenuereportgroups
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.rfoperatingmodes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.scd_batches
(
    batchid     varchar2(10) not null,
    description varchar2(35)     null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.scd_items
(
    batchid          varchar2(10)  not null,
    iteminc          number(10)    not null,
    description      varchar2(35)  not null,
    enabled          char(1)           null,
    eventtype        char(9)           null,
    starttime        date              null,
    endtime          date              null,
    frequency        number(5)         null,
    filename         varchar2(120)     null,
    params           varchar2(200)     null,
    exetype          char(3)           null,
    retries          number(5)         null,
    retrydelay       number(5)         null,
    startdateoffset  number(5)         null,
    enddateoffset    number(5)         null,
    adjusttobusdates char(1)           null,
    monday           char(1)           null,
    tuesday          char(1)           null,
    wednesday        char(1)           null,
    thursday         char(1)           null,
    friday           char(1)           null,
    saturday         char(1)           null,
    sunday           char(1)           null,
    onfailure        number(10)        null,
    onsuccess        number(10)        null,
    onnorecords      number(10)        null,
    onesc            number(10)        null,
    gwparams         long              null,
    waitstarttime    char(1)           null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.section
(
    sectionid  varchar2(10) not null,
    facility   varchar2(3)      null,
    sectionn   varchar2(10)     null,
    sectionne  varchar2(10)     null,
    sectione   varchar2(10)     null,
    sectionse  varchar2(10)     null,
    sections   varchar2(10)     null,
    sectionsw  varchar2(10)     null,
    sectionw   varchar2(10)     null,
    sectionnw  varchar2(10)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.sectionsearch
(
    sectionid varchar2(10)   not null,
    facility  varchar2(3)    not null,
    searchstr varchar2(4000)     null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.shipdays
(
    facility   varchar2(3)      null,
    postalkey  varchar2(12)     null,
    shipdays   number(3)        null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.shipmentterms
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.shipmenttypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.shipnote856hdrex
(
    sessionid   varchar2(12)     null,
    asnnumber   varchar2(30)     null,
    structure   varchar2(4)      null,
    status      varchar2(2)      null,
    bol         varchar2(30)     null,
    custid      varchar2(10)     null,
    facility    varchar2(3)      null,
    loadno      number(7)        null,
    consignee   varchar2(10)     null,
    shiptype    varchar2(1)      null,
    appointment varchar2(8)      null,
    shipunits   number(8)        null,
    weight      number(13,4)     null,
    orderid     number(9)        null,
    shipid      number(2)        null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.shipnote856itmex
(
    sessionid varchar2(12)     null,
    asnnumber varchar2(30)     null,
    loadno    number(7)        null,
    orderid   number(9)        null,
    shipid    number(2)        null,
    custid    varchar2(10)     null,
    ucc128    varchar2(20)     null,
    item      varchar2(20)     null,
    venditem  varchar2(49)     null,
    upc       varchar2(20)     null,
    shipped   number(7)        null,
    shipuom   varchar2(4)      null,
    ordered   number(7)        null,
    orderuom  varchar2(4)      null,
    orderlot  varchar2(30)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.shipnote856ordex
(
    sessionid varchar2(12)     null,
    asnnumber varchar2(30)     null,
    loadno    number(7)        null,
    orderid   number(9)        null,
    shipid    number(2)        null,
    custid    varchar2(10)     null,
    shipunits number(8)        null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.shipnote856tarex
(
    sessionid varchar2(12)     null,
    asnnumber varchar2(30)     null,
    loadno    number(7)        null,
    orderid   number(9)        null,
    shipid    number(2)        null,
    ucc128    varchar2(20)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.shipper
(
    shipper       varchar2(10)  not null,
    name          varchar2(40)      null,
    contact       varchar2(40)      null,
    addr1         varchar2(40)      null,
    addr2         varchar2(40)      null,
    city          varchar2(30)      null,
    state         varchar2(2)       null,
    postalcode    varchar2(12)      null,
    countrycode   varchar2(3)       null,
    phone         varchar2(25)      null,
    fax           varchar2(25)      null,
    email         varchar2(255)     null,
    shipperstatus varchar2(1)       null,
    lastuser      varchar2(12)      null,
    lastupdate    date              null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.shipperstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.shippingaudit
(
    lpid         varchar2(15)     null,
    facility     varchar2(3)      null,
    location     varchar2(10)     null,
    custid       varchar2(10)     null,
    item         varchar2(20)     null,
    qty          number(7)        null,
    lotnumber    varchar2(30)     null,
    serialnumber varchar2(30)     null,
    useritem1    varchar2(20)     null,
    useritem2    varchar2(20)     null,
    useritem3    varchar2(20)     null,
    audituser    varchar2(12)     null,
    auditdate    date             null,
    toplpid      varchar2(15)     null,
    itementered  varchar2(20)     null,
    results      varchar2(4)      null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.shippingplate
(
    lpid            varchar2(15) not null,
    item            varchar2(20)     null,
    custid          varchar2(10)     null,
    facility        varchar2(3)  not null,
    location        varchar2(10)     null,
    status          varchar2(2)      null,
    holdreason      varchar2(2)      null,
    unitofmeasure   varchar2(4)      null,
    quantity        number(7)        null,
    type            varchar2(2)      null,
    fromlpid        varchar2(15)     null,
    serialnumber    varchar2(30)     null,
    lotnumber       varchar2(30)     null,
    parentlpid      varchar2(15)     null,
    useritem1       varchar2(20)     null,
    useritem2       varchar2(20)     null,
    useritem3       varchar2(20)     null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    invstatus       varchar2(2)      null,
    qtyentered      number(7)        null,
    orderitem       varchar2(20)     null,
    uomentered      varchar2(4)      null,
    inventoryclass  varchar2(2)      null,
    loadno          number(7)        null,
    stopno          number(7)        null,
    shipno          number(7)        null,
    orderid         number(9)        null,
    shipid          number(2)        null,
    weight          number(13,4)     null,
    ucc128          varchar2(20)     null,
    labelformat     varchar2(10)     null,
    taskid          number(15)       null,
    dropseq         number(5)        null,
    orderlot        varchar2(30)     null,
    pickuom         varchar2(4)      null,
    pickqty         number(7)        null,
    trackingno      varchar2(20)     null,
    cartonseq       number(4)        null,
    checked         varchar2(1)      null,
    totelpid        varchar2(15)     null,
    cartontype      varchar2(4)      null,
    pickedfromloc   varchar2(10)     null,
    shippingcost    number(10,2)     null,
    carriercodeused varchar2(10)     null,
    satdeliveryused varchar2(1)      null,
    openfacility    varchar2(3)      null,
    audited         varchar2(1)      null,
    prevlocation    varchar2(10)     null,
    fromlpidparent  varchar2(15)     null,
    rmatrackingno   varchar2(20)     null,
    actualcarrier   varchar2(4)      null
)
tablespace synapse_inv_data
pctfree 30
pctused 40
/

create table alps.shippingplatehistory
(
    lpid            varchar2(15)     null,
    whenoccurred    date             null,
    item            varchar2(20)     null,
    custid          varchar2(10)     null,
    facility        varchar2(3)      null,
    location        varchar2(10)     null,
    status          varchar2(2)      null,
    holdreason      varchar2(2)      null,
    unitofmeasure   varchar2(4)      null,
    quantity        number(7)        null,
    type            varchar2(2)      null,
    fromlpid        varchar2(15)     null,
    serialnumber    varchar2(30)     null,
    lotnumber       varchar2(30)     null,
    parentlpid      varchar2(15)     null,
    useritem1       varchar2(20)     null,
    useritem2       varchar2(20)     null,
    useritem3       varchar2(20)     null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    invstatus       varchar2(2)      null,
    qtyentered      number(7)        null,
    orderitem       varchar2(20)     null,
    uomentered      varchar2(4)      null,
    inventoryclass  varchar2(2)      null,
    loadno          number(7)        null,
    stopno          number(7)        null,
    shipno          number(7)        null,
    orderid         number(9)        null,
    shipid          number(2)        null,
    weight          number(13,4)     null,
    ucc128          varchar2(20)     null,
    taskid          number(15)       null,
    orderlot        varchar2(30)     null,
    pickuom         varchar2(4)      null,
    pickqty         number(7)        null,
    trackingno      varchar2(20)     null,
    cartonseq       number(4)        null,
    totelpid        varchar2(15)     null,
    cartontype      varchar2(4)      null,
    pickedfromloc   varchar2(10)     null,
    shippingcost    number(10,2)     null,
    carriercodeused varchar2(10)     null,
    satdeliveryused varchar2(1)      null,
    openfacility    varchar2(3)      null
)
tablespace synapse_his_data
pctfree 10
pctused 70
/

create table alps.shippingplatestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.shippingplatetypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table shipshortreasons
(
  code        varchar2(12),
  descr       varchar2(32),
  abbrev      varchar2(12),
  dtlupdate   varchar2(1),
  lastuser    varchar2(12),
  lastupdate  date
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.sip_parameters
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.spoolerqueues
(
    prtqueue   varchar2(20)     null,
    descr      varchar2(32)     null,
    oraclepipe varchar2(12)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.stateorprovince
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.storageparms
(
    objectclass varchar2(10) not null,
    descr       varchar2(80)     null,
    storageparm long             null,
    lastuser    varchar2(12)     null,
    lastupdate  date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.storagetypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.subtasks
(
    taskid         number(15)   not null,
    tasktype       varchar2(2)      null,
    facility       varchar2(3)      null,
    fromsection    varchar2(10)     null,
    fromloc        varchar2(10)     null,
    fromprofile    varchar2(2)      null,
    tosection      varchar2(10)     null,
    toloc          varchar2(10)     null,
    toprofile      varchar2(2)      null,
    touserid       varchar2(10)     null,
    custid         varchar2(10)     null,
    item           varchar2(20)     null,
    lpid           varchar2(15)     null,
    uom            varchar2(4)      null,
    qty            number(7)        null,
    locseq         number(7)        null,
    loadno         number(7)        null,
    stopno         number(7)        null,
    shipno         number(7)        null,
    orderid        number(9)        null,
    shipid         number(2)        null,
    orderitem      varchar2(20)     null,
    orderlot       varchar2(30)     null,
    priority       varchar2(1)      null,
    prevpriority   varchar2(1)      null,
    curruserid     varchar2(10)     null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null,
    pickuom        varchar2(4)      null,
    pickqty        number(7)        null,
    picktotype     varchar2(4)      null,
    wave           number(9)        null,
    pickingzone    varchar2(10)     null,
    cartontype     varchar2(4)      null,
    weight         number(13,4)     null,
    cube           number(10,4)     null,
    staffhrs       number(10,4)     null,
    cartonseq      number(4)        null,
    shippinglpid   varchar2(15)     null,
    shippingtype   varchar2(2)      null,
    cartongroup    varchar2(4)      null,
    qtypicked      number(7)        null,
    labeluom       varchar2(4)      null,
    step1_complete char(1)          null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.systemdefaults
(
    defaultid    varchar2(36)      null,
    defaultvalue varchar2(255)     null,
    lastuser     varchar2(12)      null,
    lastupdate   date              null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.tabledefs
(
    tableid    varchar2(32) not null,
    hdrupdate  varchar2(1)      null,
    dtlupdate  varchar2(1)      null,
    codemask   varchar2(20)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.taskpriorities
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.taskrequestqueues
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.tasks
(
    taskid          number(15)   not null,
    tasktype        varchar2(2)      null,
    facility        varchar2(3)      null,
    fromsection     varchar2(10)     null,
    fromloc         varchar2(10)     null,
    fromprofile     varchar2(2)      null,
    tosection       varchar2(10)     null,
    toloc           varchar2(10)     null,
    toprofile       varchar2(2)      null,
    touserid        varchar2(10)     null,
    custid          varchar2(10)     null,
    item            varchar2(20)     null,
    lpid            varchar2(15)     null,
    uom             varchar2(4)      null,
    qty             number(7)        null,
    locseq          number(7)        null,
    loadno          number(7)        null,
    stopno          number(7)        null,
    shipno          number(7)        null,
    orderid         number(9)        null,
    shipid          number(2)        null,
    orderitem       varchar2(20)     null,
    orderlot        varchar2(30)     null,
    priority        varchar2(1)      null,
    prevpriority    varchar2(1)      null,
    curruserid      varchar2(10)     null,
    lastuser        varchar2(12)     null,
    lastupdate      date             null,
    pickuom         varchar2(4)      null,
    pickqty         number(7)        null,
    picktotype      varchar2(4)      null,
    wave            number(9)        null,
    pickingzone     varchar2(10)     null,
    cartontype      varchar2(4)      null,
    weight          number(13,4)     null,
    cube            number(10,4)     null,
    staffhrs        number(10,4)     null,
    cartonseq       number(4)        null,
    clusterposition varchar2(6)      null,
    convpickloc     varchar2(10)     null,
    step1_complete  char(1)          null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.tasktypes
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.tbl_companies
(
    company_id      number        not null,
    company_name    varchar2(100) not null,
    synapse_profile varchar2(20)      null,
    constraint tbl_companies_uk
    unique (company_name)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_global_label_repository
(
    label_id            number(4)     not null,
    label_type_id       number(4)     default 1 not null,
    label_display_order number(2)     default 1     null,
    en                  varchar2(150) not null,
    fr                  varchar2(150)     null,
    fr_verified         number(1)     default 0 not null,
    constraint cons_tbl_glbl_lbl_rpstry_1
    primary key (label_id)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_groups
(
    group_id    number        not null,
    group_name  varchar2(100) not null,
    company_id  number        not null,
    status      number        default 0 not null,
    delete_flag number        default 0 not null,
    constraint tbl_groups_uk11009853010396_1
    unique (group_name)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_lkup_label_types
(
    label_type_id          number(4)    not null,
    label_type_description varchar2(50) not null,
    rec_add_date           date             null,
    site_related           number(4)    default 0     null,
    constraint cons_tbl_lkup_lbtyp_1
    primary key (label_type_id)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_lkup_permissions
(
    action_id       number(4) not null,
    action_label_id number(4) not null,
    constraint action_key_1
    primary key (action_id)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_message_body
(
    message_id number         not null,
    language   varchar2(200)  not null,
    verified   number         not null,
    message    varchar2(1000) not null,
    constraint pk_msg_body_1
    primary key (message_id,language)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_message_header
(
    message_id    number        not null,
    message_type  number        not null,
    sort_order    number            null,
    base_language varchar2(200)     null,
    constraint pk_msg_id_1
    primary key (message_id)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_message_types
(
    message_type      number        not null,
    message_type_desc varchar2(200) not null,
    site_related      number            null,
    constraint pk_msg_types_1
    primary key (message_type)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_report_types
(
    report_type_id  varchar2(20) not null,
    report_label_id number       not null,
    action          number           null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_rights_access
(
    rights_id number       not null,
    users_id  varchar2(10) not null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_transaction_logs
(
    nameid     varchar2(15)  not null,
    event      varchar2(200) not null,
    event_time varchar2(25)  default to_char(sysdate, 'MM-DD-YYYY HH24:MI:SS') not null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_user_facilities
(
    nameid      varchar2(12) not null,
    facility_id varchar2(3)  not null,
    last_user   varchar2(12) not null,
    last_update date         default sysdate not null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_user_permissions
(
    nameid varchar2(12) not null,
    action number(4)    not null,
    domain varchar2(20) not null,
    constraint primary_key_1_1
    primary key (nameid,action,domain)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_user_preferences
(
    nameid         varchar2(12)  not null,
    inventory_sort varchar2(200)     null,
    order_columns  varchar2(200)     null,
    order_sort     varchar2(200)     null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tbl_user_profile
(
    nameid            varchar2(12) not null,
    first_name        varchar2(50) not null,
    last_name         varchar2(50) not null,
    email_address     varchar2(50) not null,
    cellphone_area    varchar2(10)     null,
    cellphone_number  varchar2(10)     null,
    fax_area          varchar2(10) not null,
    fax_number        varchar2(10) not null,
    phone_area        varchar2(10) not null,
    phone_number      varchar2(10) not null,
    user_type         number(10)   default 0 not null,
    group_id          number(10)   not null,
    assigned_customer varchar2(10) not null,
    delete_flag       number(10)   default 0 not null,
    user_status       number(10)   default 1 not null,
    password          varchar2(25) not null,
    login_attempts    varchar2(10) default 0 not null,
    dob               varchar2(25)     null,
    language          varchar2(25)     null,
    constraint tbl_user_prof_uk
    unique (nameid)
        using index pctfree 10
                    tablespace synapse_temp_index
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.tempcustitem
(
    sno        number(3)         null,
    nameid     varchar2(12)      null,
    facility   varchar2(3)       null,
    custid     varchar2(10)      null,
    item       varchar2(20)      null,
    descr      varchar2(32)      null,
    lotnumber  varchar2(30)      null,
    quantity   number(7)         null,
    qntentered number(7)         null,
    uom        varchar2(4)       null,
    comments   varchar2(255)     null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.tempcustitemout
(
    sno        number(3)         null,
    nameid     varchar2(12)      null,
    facility   varchar2(3)       null,
    custid     varchar2(10)      null,
    item       varchar2(20)      null,
    descr      varchar2(32)      null,
    lotnumber  varchar2(30)      null,
    quantity   number(7)         null,
    qntentered number(7)         null,
    uom        varchar2(4)       null,
    baseuom    varchar2(4)       null,
    comments   varchar2(255)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tempuserheader
(
    nameid varchar2(255)     null,
    desc1  varchar2(255)     null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_billfreight_to
(
    nameid  varchar2(12)  not null,
    name    varchar2(40)  not null,
    addr1   varchar2(40)  not null,
    addr2   varchar2(40)      null,
    city    varchar2(30)  not null,
    state   varchar2(2)   not null,
    country varchar2(3)   not null,
    zip     varchar2(12)      null,
    phone   varchar2(15)      null,
    fax     varchar2(15)      null,
    email   varchar2(255)     null,
    contact varchar2(40)      null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_data
(
    column_name varchar2(30)     null,
    table_name  varchar2(30)     null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_delete
(
    s date     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.temp_inbound_entry
(
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    customer_po    varchar2(20)     null,
    appointment    varchar2(30)     null,
    priority       varchar2(1)      null,
    reference      varchar2(20)     null,
    supplier       varchar2(10)     null,
    bill_of_lading varchar2(20)     null,
    comments       long             null,
    nameid         varchar2(12) not null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_outbound_billfreight
(
    billfreightto   varchar2(40)     null,
    deliveryservice varchar2(4)      null,
    nameid          varchar2(12) not null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_outbound_entry
(
    fromfac      varchar2(10) not null,
    custid       varchar2(10) not null,
    customer_po  varchar2(20)     null,
    priority     varchar2(1)      null,
    reference    varchar2(20) not null,
    nameid       varchar2(12) not null,
    instructions varchar2(60)     null,
    bolcomments  long             null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_outbound_otship
(
    shiptoname        varchar2(40)      null,
    shiptoaddr1       varchar2(40)      null,
    shiptoaddr2       varchar2(40)      null,
    shiptocity        varchar2(30)      null,
    shiptostate       varchar2(2)       null,
    shiptopostalcode  varchar2(12)      null,
    shiptocountrycode varchar2(3)       null,
    shiptocontact     varchar2(40)      null,
    shiptophone       varchar2(15)      null,
    shiptofax         varchar2(15)      null,
    shiptoemail       varchar2(255)     null,
    specialservice1   varchar2(4)       null,
    specialservice2   varchar2(4)       null,
    specialservice3   varchar2(4)       null,
    specialservice4   varchar2(4)       null,
    cod               char(1)           null,
    amtcod            number(10,2)      null,
    nameid            varchar2(12)  not null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.temp_outbound_ship
(
    consignee   varchar2(10)     null,
    oneship     varchar2(8)      null,
    carrier     varchar2(20)     null,
    satcarrier  varchar2(8)      null,
    shiptype    varchar2(4)      null,
    shipterms   varchar2(4)      null,
    shipdate    varchar2(15)     null,
    arrivaldate varchar2(15)     null,
    nameid      varchar2(12) not null
)
tablespace synapse_temp_data
pctfree 30
pctused 40
/

create table alps.tmsarea
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.tmscarriers
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.tmsexport
(
    bol         char(10)           null,
    seq         char(2)            null,
    linetype    char(1)            null,
    pieces      number             null,
    weight      number             null,
    hazflag     char(1)            null,
    ltlclass    char(4)            null,
    description varchar2(4000)     null,
    suffix      varchar2(32)       null,
    orderid     number             null,
    shipid      number             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsfacilitygroup
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.tmsorderstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.tmsplanship_bolcomments
(
    sendertransmissionno       number           null,
    shipto                     varchar2(10)     null,
    bolcomment                 long             null,
    addr                       varchar2(40)     null,
    city                       varchar2(30)     null,
    state                      varchar2(2)      null,
    postalcode                 varchar2(12)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_hdr
(
    transmissioncreatedatetime date             null,
    transactioncount           number           null,
    senderhostname             varchar2(40)     null,
    username                   varchar2(10)     null,
    password                   varchar2(20)     null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    status                     number           null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_rel
(
    transmissioncreatedatetime    date             null,
    sendertransmissionno          number           null,
    referencetransmissionno       number           null,
    releasedomainname             varchar2(20)     null,
    release                       varchar2(40)     null,
    transorderheaderdomainname    varchar2(20)     null,
    transorderheader              varchar2(40)     null,
    transordertransactioncode     varchar2(20)     null,
    paymentmethodcodedomainname   varchar2(20)     null,
    paymentmethodcode             varchar2(40)     null,
    planninggroupdomainname       varchar2(20)     null,
    planninggroup                 varchar2(40)     null,
    ordertypedomainname           varchar2(20)     null,
    ordertype                     varchar2(40)     null,
    timewindowemphasis            varchar2(20)     null,
    shipfromlocationrefdomainname varchar2(20)     null,
    shipfromlocationref           varchar2(40)     null,
    shiptolocationrefdomainname   varchar2(20)     null,
    shiptolocationref             varchar2(40)     null,
    earlydeliverydate             date             null,
    latedeliverydate              date             null,
    declaredvaluecurrencycode     varchar2(20)     null,
    declaredvaluemonetaryamount   float(5)         null,
    mustshipalone                 varchar2(1)      null,
    bulkplandomainname            varchar2(20)     null,
    bulkplan                      varchar2(40)     null,
    bestdirectbuycurrencycode     varchar2(20)     null,
    bestdirectbuymonetaryamount   float(5)         null,
    bestdirectbuyratedomainname   varchar2(20)     null,
    bestdirectbuyrate             varchar2(40)     null,
    bestdirectsellcurrencycode    varchar2(20)     null,
    bestdirectsellmonetaryamount  float(5)         null,
    bestdirectsellratedomainname  varchar2(20)     null,
    bestdirectsellrate            varchar2(40)     null,
    totalweightvalue              float(5)         null,
    totalweightuom                varchar2(20)     null,
    totalvolumevalue              float(5)         null,
    totalvolumeuom                varchar2(20)     null,
    totalnetweightvalue           float(5)         null,
    totalnetweightuom             varchar2(20)     null,
    totalnetvolumevalue           float(5)         null,
    totalnetvolumeuom             varchar2(20)     null,
    totalpackageditemspeccount    number           null,
    totalpackageditemcount        number           null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_relline
(
    transmissioncreatedatetime  date             null,
    sendertransmissionno        number           null,
    referencetransmissionno     number           null,
    release                     varchar2(40)     null,
    releaselinedomainname       varchar2(20)     null,
    releaseline                 varchar2(40)     null,
    packageditemdomainname      varchar2(20)     null,
    packageditem                varchar2(40)     null,
    packagetype                 varchar2(20)     null,
    packagingdescription        varchar2(40)     null,
    packageshipunitweightvalue  float(5)         null,
    packageshipunitweightuom    varchar2(20)     null,
    isdefaultpackaging          varchar2(1)      null,
    ishazardous                 varchar2(1)      null,
    itemtransactioncode         varchar2(20)     null,
    itemdomainname              varchar2(20)     null,
    item                        varchar2(40)     null,
    itemname                    varchar2(40)     null,
    itemdescription             varchar2(40)     null,
    commoditydomainname         varchar2(20)     null,
    commodity                   varchar2(40)     null,
    nmfcarticledomainname       varchar2(20)     null,
    nmfcarticle                 varchar2(40)     null,
    nmfcclass                   varchar2(40)     null,
    refnumqualifierdomainname   varchar2(20)     null,
    refnumqualifier             varchar2(40)     null,
    itemweightvalue             float(5)         null,
    itemweightuom               varchar2(20)     null,
    itemvolumevalue             float(5)         null,
    itemvolumeuom               varchar2(20)     null,
    packageditemcount           number           null,
    declaredvaluecurrencycode   varchar2(20)     null,
    declaredvaluemonetaryamount float(5)         null,
    shipunitspecrefdomainname   varchar2(20)     null,
    shipunitspecref             varchar2(40)     null,
    shipunitspecdomainname      varchar2(20)     null,
    shipunitspec                varchar2(40)     null,
    tareweightvalue             float(5)         null,
    tareweightuom               varchar2(20)     null,
    maxweightvalue              float(5)         null,
    maxweightuom                varchar2(20)     null,
    volumevalue                 float(5)         null,
    volumeuom                   varchar2(20)     null,
    lengthvalue                 float(5)         null,
    lengthuom                   varchar2(20)     null,
    widthvalue                  float(5)         null,
    widthuom                    varchar2(20)     null,
    heightvalue                 float(5)         null,
    heightuom                   varchar2(20)     null,
    packageditemspeccount       number           null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_relrefnum
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    release                    varchar2(40)     null,
    releaserefnumdomainname    varchar2(20)     null,
    releaserefnum              varchar2(40)     null,
    releaserefnumvalue         varchar2(40)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_relstat
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    release                    varchar2(40)     null,
    statustypedomainname       varchar2(20)     null,
    statustype                 varchar2(60)     null,
    statusvaluedomainname      varchar2(20)     null,
    statusvalue                varchar2(60)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_relsu
(
    transmissioncreatedatetime     date             null,
    sendertransmissionno           number           null,
    referencetransmissionno        number           null,
    release                        varchar2(40)     null,
    shipunitdomainname             varchar2(20)     null,
    shipunit                       varchar2(40)     null,
    shipunitspecdomainname         varchar2(20)     null,
    shipunitspec                   varchar2(40)     null,
    weightvalue                    float(5)         null,
    weightuom                      varchar2(20)     null,
    volumevalue                    float(5)         null,
    volumeuom                      varchar2(20)     null,
    unitnetweightvalue             float(5)         null,
    unitnetweightuom               varchar2(20)     null,
    unitnetvolumevalue             float(5)         null,
    unitnetvolumeuom               varchar2(20)     null,
    lengthvalue                    float(5)         null,
    lengthuom                      varchar2(20)     null,
    widthvalue                     float(5)         null,
    widthuom                       varchar2(20)     null,
    heightvalue                    float(5)         null,
    heightuom                      varchar2(20)     null,
    packageditemdomainname         varchar2(20)     null,
    packageditem                   varchar2(40)     null,
    packagetype                    varchar2(40)     null,
    packageshipunitweightvalue     float(5)         null,
    packageshipunitweightuom       varchar2(20)     null,
    isdefaultpacking               varchar2(1)      null,
    ishazardous                    varchar2(1)      null,
    itemtransactioncode            varchar2(20)     null,
    itemdomainname                 varchar2(20)     null,
    item                           varchar2(40)     null,
    itemname                       varchar2(40)     null,
    itemdescription                varchar2(40)     null,
    commoditydomainname            varchar2(20)     null,
    commodity                      varchar2(40)     null,
    nmfcarticledomainname          varchar2(20)     null,
    nmfcarticle                    varchar2(40)     null,
    nmfcclass                      varchar2(40)     null,
    refnumqualifierdomainname      varchar2(20)     null,
    refnumqualifier                varchar2(40)     null,
    refnumvalue                    number           null,
    linenumber                     number           null,
    itemissplitallowed             varchar2(1)      null,
    itemweightvalue                float(5)         null,
    itemweightuom                  varchar2(20)     null,
    itemvolumevalue                float(5)         null,
    itemvolumeuom                  varchar2(20)     null,
    packageditemcount              number           null,
    packageitemsuspecrefdomainname varchar2(20)     null,
    packageitemsuspecref           varchar2(40)     null,
    packageitemsuspecdomainname    varchar2(20)     null,
    packageitemsuspec              varchar2(40)     null,
    packageditemtareweightvalue    float(5)         null,
    packageditemtareweightuom      varchar2(20)     null,
    packageditemmaxweightvalue     float(5)         null,
    packageditemmaxweightuom       varchar2(20)     null,
    packageditemvolumevalue        float(5)         null,
    packageditemvolumeuom          varchar2(20)     null,
    packageditemlengthvalue        float(5)         null,
    packageditemlengthuom          varchar2(20)     null,
    packageditemwidthvalue         float(5)         null,
    packageditemwidthuom           varchar2(20)     null,
    packageditemheightvalue        float(5)         null,
    packageditemheightuom          varchar2(20)     null,
    packageditemspeccount          number           null,
    weightpershipunitvalue         float(5)         null,
    weightpershipunituom           varchar2(20)     null,
    volumepershipunitvalue         float(5)         null,
    volumepershipunituom           varchar2(20)     null,
    countpershipunit               number           null,
    shipunitreleasedomainname      varchar2(20)     null,
    shipunitrelease                varchar2(40)     null,
    shipunitreleaselinedomainname  varchar2(20)     null,
    shipunitreleaseline            varchar2(40)     null,
    issplitallowed                 varchar2(1)      null,
    shipunitcount                  number           null,
    transordershipunitdomainname   varchar2(20)     null,
    transordershipunit             varchar2(40)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_reltoip
(
    transmissioncreatedatetime    date             null,
    sendertransmissionno          number           null,
    referencetransmissionno       number           null,
    release                       varchar2(40)     null,
    involvedpartyqualifier        varchar2(40)     null,
    locationrefdomainname         varchar2(20)     null,
    locationref                   varchar2(40)     null,
    contactrefdomainname          varchar2(20)     null,
    contactref                    varchar2(40)     null,
    contacttransactioncode        varchar2(40)     null,
    contactemailaddress           varchar2(40)     null,
    contactlanguagespoken         varchar2(40)     null,
    isprimarycontact              varchar2(1)      null,
    commethodrank                 number           null,
    contactrefcommethod           varchar2(40)     null,
    expectedresponsedurationvalue number           null,
    expectedresponsedurationuom   varchar2(20)     null,
    commethod                     varchar2(40)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_reltorem
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    release                    varchar2(40)     null,
    remarksequence             number           null,
    remarkqualifier            varchar2(40)     null,
    remarklevel                number           null,
    remarktext                 varchar2(60)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_reltorn
(
    tranmissioncreatedatetime date             null,
    sendertransmissionno      number           null,
    referencetransmissionno   number           null,
    release                   varchar2(40)     null,
    refnumqualifierdomainname varchar2(20)     null,
    refnumqualifier           varchar2(40)     null,
    refnumvalue               varchar2(40)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shiphdr
(
    transmissioncreatedatetime     date             null,
    sendertransmissionno           number           null,
    referencetransmissionno        number           null,
    remarksequence                 number           null,
    remarkqualifier                varchar2(20)     null,
    sendreason                     varchar2(30)     null,
    shipmentdomainname             varchar2(20)     null,
    shipment                       varchar2(40)     null,
    transactioncode                varchar2(20)     null,
    serviceproviderdomainname      varchar2(20)     null,
    serviceprovider                varchar2(40)     null,
    serviceprovideraliasqualifier  varchar2(20)     null,
    serviceprovideraliasvalue      varchar2(40)     null,
    serviceproviderdeliveryservice varchar2(40)     null,
    isserviceproviderfixed         varchar2(1)      null,
    contactdomainname              varchar2(20)     null,
    contact                        varchar2(40)     null,
    istendercontactfixed           varchar2(1)      null,
    rateofferingdomainname         varchar2(20)     null,
    rateoffering                   varchar2(40)     null,
    israteofferingfixed            varchar2(1)      null,
    rategeodomainname              varchar2(20)     null,
    rategeo                        varchar2(40)     null,
    isrategeofixed                 varchar2(1)      null,
    totalplannedcostcurrencycode   varchar2(10)     null,
    totalplannedcostmonetaryamount float(5)         null,
    totalactualcostcurrencycode    varchar2(10)     null,
    totalactualcostmonetaryamount  float(5)         null,
    totalweightedcostcurrencycode  varchar2(10)     null,
    totalweightedcostmonetaryamoun float(5)         null,
    iscostfixed                    varchar2(1)      null,
    isservicetimefixed             varchar2(1)      null,
    itransactionno                 number           null,
    ishazardous                    varchar2(1)      null,
    transportmode                  varchar2(10)     null,
    totalweightvalue               float(5)         null,
    totalweightuom                 varchar2(10)     null,
    totalvolumevalue               float(5)         null,
    totalvolumeuom                 varchar2(10)     null,
    totalnetweightvalue            float(5)         null,
    totalnetweightuom              varchar2(10)     null,
    totalnetvolumevalue            float(5)         null,
    totalnetvolumeuom              varchar2(10)     null,
    totalshipunitcount             number           null,
    totalpackageditemspeccount     number           null,
    totalpackageditemcount         number           null,
    startdate                      date             null,
    enddate                        date             null,
    commercialtermsdomainname      varchar2(20)     null,
    commercialterms                varchar2(40)     null,
    stopcount                      number           null,
    numorderreleases               number           null,
    totalshippingspaces            number           null,
    istemperaturecontrol           varchar2(1)      null,
    earlieststarttime              date             null,
    lateststarttime                date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shiphdr2
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    isautomergeconsolidate     varchar2(1)      null,
    perspective                varchar2(10)     null,
    itinerarydomainname        varchar2(20)     null,
    itinerary                  varchar2(40)     null,
    parentlegdomainname        varchar2(20)     null,
    parentleg                  varchar2(40)     null,
    shipmentaswork             varchar2(1)      null,
    feasibility                varchar2(20)     null,
    checktimeconstraint        varchar2(1)      null,
    checkcostconstraint        varchar2(1)      null,
    checkcapacityconstraint    varchar2(1)      null,
    weightcode                 varchar2(1)      null,
    rule7                      varchar2(1)      null,
    shipmentreleased           varchar2(1)      null,
    dimweightvalue             float(5)         null,
    dimweightuom               varchar2(10)     null,
    ispreload                  varchar2(1)      null,
    bulkplandomainname         varchar2(20)     null,
    bulkplan                   varchar2(40)     null,
    intrailerbuild             varchar2(1)      null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shipstop
(
    transmissioncreatedatetime    date             null,
    sendertransmissionno          number           null,
    referencetransmissionno       number           null,
    stopsequence                  number           null,
    stopdurationvalue             number           null,
    stopdurationuom               varchar2(20)     null,
    isappointment                 varchar2(1)      null,
    locationrefdomainname         varchar2(20)     null,
    locationref                   varchar2(40)     null,
    distfromprevstopvalue         number           null,
    distfromprevstopuom           varchar2(20)     null,
    stopreason                    varchar2(40)     null,
    arrivaltimeplanned            date             null,
    arrivaltimeestimated          date             null,
    isarrivalplannedtimefixed     varchar2(1)      null,
    departureplannedtime          date             null,
    departureestimatedtime        date             null,
    isdepartureestimatedtimefixed varchar2(1)      null,
    ispermanent                   varchar2(1)      null,
    isdepot                       varchar2(1)      null,
    accessorialtimedurationvalue  number           null,
    accessorialtimedurationuom    varchar2(20)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shipstopdtl
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    stopsequence               number           null,
    shipmentstopactivity       varchar2(20)     null,
    activitydurationvalue      number           null,
    activitydurationuom        varchar2(20)     null,
    shipunitdomainname         varchar2(20)     null,
    shipunit                   varchar2(40)     null,
    isshipstoppermanent        varchar2(1)      null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shipunit
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    shipunitdomainname         varchar2(20)     null,
    shipunit                   varchar2(40)     null,
    shipunitspecdomainname     varchar2(20)     null,
    shipunitspec               varchar2(40)     null,
    shiptolocationdomainname   varchar2(20)     null,
    shiptolocation             varchar2(40)     null,
    weightvalue                float(5)         null,
    weightuom                  varchar2(20)     null,
    volumevalue                float(5)         null,
    volumeuom                  varchar2(20)     null,
    unitnetweightvalue         float(5)         null,
    unitnetweightuom           varchar2(20)     null,
    unitnetvolumevalue         float(5)         null,
    unitnetvolumeuom           varchar2(20)     null,
    lengthvalue                float(5)         null,
    lengthuom                  varchar2(20)     null,
    widthvalue                 float(5)         null,
    widthuom                   varchar2(20)     null,
    heightvalue                float(5)         null,
    heightuom                  varchar2(20)     null,
    shipunitcount              number           null,
    releaseshipunitdomainname  varchar2(20)     null,
    releaseshipunit            varchar2(40)     null,
    receivednetweightvalue     float(5)         null,
    receivednetweightuom       varchar2(20)     null,
    receivednetvolumevalue     float(5)         null,
    receivednetvolumeuom       varchar2(20)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_shipunitspec
(
    transmissioncreatedatetime date             null,
    sendertransmissionno       number           null,
    referencetransmissionno    number           null,
    shipunitspecdomainname     varchar2(20)     null,
    shipunitspec               varchar2(40)     null,
    shipunitspecname           varchar2(40)     null,
    tareweightvalue            float(5)         null,
    tareweightuom              varchar2(20)     null,
    maxweightvalue             float(5)         null,
    maxweightuom               varchar2(20)     null,
    volumevalue                float(5)         null,
    volumeuom                  varchar2(20)     null,
    lengthvalue                float(5)         null,
    lengthuom                  varchar2(20)     null,
    widthvalue                 float(5)         null,
    widthuom                   varchar2(20)     null,
    heightvalue                float(5)         null,
    heightuom                  varchar2(20)     null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsplanship_tail
(
    sendertransmissionno number null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsroute
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.tmsserviceroute
(
    facilitygroup  varchar2(4)  not null,
    area           varchar2(5)  not null,
    servicedays    number       not null,
    route          varchar2(5)  not null,
    defaultcarrier varchar2(4)  not null,
    lastuser       varchar2(12)     null,
    lastupdate     date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.tmsservicezip
(
    begzip     char(5)      not null,
    endzip     char(5)      not null,
    area       varchar2(5)  not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.tmsstatecode
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.tms_status
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 10
pctused 40
/

create table alps.unitofstorage
(
    unitofstorage varchar2(4)  not null,
    description   varchar2(30)     null,
    depth         number(7,2)      null,
    width         number(7,2)      null,
    height        number(7,2)      null,
    weightlimit   number(13,4)     null,
    stdpallets    number(6,2)      null,
    lastuser      varchar2(12)     null,
    lastupdate    date             null,
    abbrev        varchar2(12)     null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.unitsofmeasure
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.ursa
(
    zipcode      varchar2(5)       null,
    state        varchar2(2)       null,
    cityprefixes varchar2(255)     null,
    lastuser     varchar2(12)      null,
    lastupdate   date              null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.usercertificates
(
    guid      char(32)     not null,
    nameid    varchar2(12)     null,
    ipaddress char(15)         null,
    timestamp date             null,
    constraint pk_usercertificates
    primary key (guid)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.usercustomer
(
    nameid     varchar2(12) not null,
    custid     varchar2(10) not null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.userdetail
(
    nameid     varchar2(12) not null,
    formid     varchar2(32) not null,
    facility   varchar2(3)      null,
    setting    varchar2(12)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.userfacility
(
    nameid     varchar2(12) not null,
    facility   varchar2(3)  not null,
    groupid    varchar2(12)     null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.userforms
(
    nameid varchar2(12) not null,
    formid varchar2(32)     null,
    top    number(10)       null,
    left   number(10)       null,
    height number(10)       null,
    width  number(10)       null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.usergrids
(
    nameid    varchar2(12) not null,
    formid    varchar2(32)     null,
    gridid    varchar2(32)     null,
    fieldid0  varchar2(32)     null,
    width0    number(10)       null,
    fieldid1  varchar2(32)     null,
    width1    number(10)       null,
    fieldid2  varchar2(32)     null,
    width2    number(10)       null,
    fieldid3  varchar2(32)     null,
    width3    number(10)       null,
    fieldid4  varchar2(32)     null,
    width4    number(10)       null,
    fieldid5  varchar2(32)     null,
    width5    number(10)       null,
    fieldid6  varchar2(32)     null,
    width6    number(10)       null,
    fieldid7  varchar2(32)     null,
    width7    number(10)       null,
    fieldid8  varchar2(32)     null,
    width8    number(10)       null,
    fieldid9  varchar2(32)     null,
    width9    number(10)       null,
    fieldid10 varchar2(32)     null,
    width10   number(10)       null,
    fieldid11 varchar2(32)     null,
    width11   number(10)       null,
    fieldid12 varchar2(32)     null,
    width12   number(10)       null,
    fieldid13 varchar2(32)     null,
    width13   number(10)       null,
    fieldid14 varchar2(32)     null,
    width14   number(10)       null,
    fieldid15 varchar2(32)     null,
    width15   number(10)       null,
    fieldid16 varchar2(32)     null,
    width16   number(10)       null,
    fieldid17 varchar2(32)     null,
    width17   number(10)       null,
    fieldid18 varchar2(32)     null,
    width18   number(10)       null,
    fieldid19 varchar2(32)     null,
    width19   number(10)       null,
    fieldid20 varchar2(32)     null,
    width20   number(10)       null,
    fieldid21 varchar2(32)     null,
    width21   number(10)       null,
    fieldid22 varchar2(32)     null,
    width22   number(10)       null,
    fieldid23 varchar2(32)     null,
    width23   number(10)       null,
    fieldid24 varchar2(32)     null,
    width24   number(10)       null,
    fieldid25 varchar2(32)     null,
    width25   number(10)       null,
    fieldid26 varchar2(32)     null,
    width26   number(10)       null,
    fieldid27 varchar2(32)     null,
    width27   number(10)       null,
    fieldid28 varchar2(32)     null,
    width28   number(10)       null,
    fieldid29 varchar2(32)     null,
    width29   number(10)       null,
    fieldid30 varchar2(32)     null,
    width30   number(10)       null,
    fieldid31 varchar2(32)     null,
    width31   number(10)       null,
    fieldid32 varchar2(32)     null,
    width32   number(10)       null,
    fieldid33 varchar2(32)     null,
    width33   number(10)       null,
    fieldid34 varchar2(32)     null,
    width34   number(10)       null,
    fieldid35 varchar2(32)     null,
    width35   number(10)       null,
    fieldid36 varchar2(32)     null,
    width36   number(10)       null,
    fieldid37 varchar2(32)     null,
    width37   number(10)       null,
    fieldid38 varchar2(32)     null,
    width38   number(10)       null,
    fieldid39 varchar2(32)     null,
    width39   number(10)       null,
    fieldid40 varchar2(32)     null,
    width40   number(10)       null,
    fieldid41 varchar2(32)     null,
    width41   number(10)       null,
    fieldid42 varchar2(32)     null,
    width42   number(10)       null,
    fieldid43 varchar2(32)     null,
    width43   number(10)       null,
    fieldid44 varchar2(32)     null,
    width44   number(10)       null,
    fieldid45 varchar2(32)     null,
    width45   number(10)       null,
    fieldid46 varchar2(32)     null,
    width46   number(10)       null,
    fieldid47 varchar2(32)     null,
    width47   number(10)       null,
    fieldid48 varchar2(32)     null,
    width48   number(10)       null,
    fieldid49 varchar2(32)     null,
    width49   number(10)       null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.userheader
(
    nameid            varchar2(12)  not null,
    username          varchar2(32)      null,
    usertype          varchar2(1)       null,
    facility          varchar2(3)       null,
    groupid           varchar2(12)      null,
    chgfacility       varchar2(1)       null,
    desc1             varchar2(40)      null,
    desc2             varchar2(40)      null,
    lastuser          varchar2(12)      null,
    lastupdate        date              null,
    lblprinter        varchar2(5)       null,
    rptprinter        varchar2(5)       null,
    lastlocation      varchar2(10)      null,
    custid            varchar2(10)      null,
    equipment         varchar2(2)       null,
    opmode            varchar2(1)       null,
    pickmode          varchar2(1)       null,
    allcusts          varchar2(1)       null,
    mblprinter        varchar2(5)       null,
    sblprinter        varchar2(5)       null,
    defaultprinter    varchar2(255)     null,
    poconfirmprinter  varchar2(255)     null,
    bolprinter        varchar2(255)     null,
    title             varchar2(40)      null,
    addr1             varchar2(40)      null,
    addr2             varchar2(40)      null,
    city              varchar2(30)      null,
    state             varchar2(2)       null,
    postalcode        varchar2(12)      null,
    countrycode       varchar2(3)       null,
    phone             varchar2(25)      null,
    fax               varchar2(25)      null,
    email             varchar2(255)     null,
    tasktypeindicator varchar2(1)       null,
    tasktypes         varchar2(255)     null,
    userstatus        varchar2(1)       null,
    zoneindicator     char(1)           null,
    zones             varchar2(255)     null,
    cleanlogout       varchar2(1)       null,
    vicsbolprinter    varchar2(255)     null,
    fullpicklimit     number(3)         null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.userhistory
(
    nameid    varchar2(12)  not null,
    begtime   date          not null,
    event     varchar2(4)   not null,
    endtime   date              null,
    facility  varchar2(3)       null,
    custid    varchar2(10)      null,
    equipment varchar2(2)       null,
    units     number(7)         null,
    etc       varchar2(255)     null,
    orderid   number(9)         null,
    shipid    number(2)         null,
    location  varchar2(10)      null,
    lpid      varchar2(15)      null,
    item      varchar2(20)      null,
    uom       varchar2(4)       null
)
tablespace synapse_his_data
pctfree 10
pctused 70
/

create table alps.userstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.usertoolbar
(
    userid  varchar2(12) not null,
    hidden  char(1)          null,
    buttons long             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.vics_bol_types
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_temp_data
pctfree 10
pctused 40
/

create table alps.waves
(
    wave               number(9)        null,
    descr              varchar2(80)     null,
    wavestatus         varchar2(1)      null,
    schedrelease       date             null,
    actualrelease      date             null,
    facility           varchar2(3)      null,
    lastuser           varchar2(12)     null,
    lastupdate         date             null,
    stageloc           varchar2(10)     null,
    picktype           varchar2(4)      null,
    taskpriority       char(1)          null,
    sortloc            varchar2(10)     null,
    job                number           null,
    childwave          number(9)        null,
    batchcartontype    varchar2(4)      null,
    fromlot            varchar2(30)     null,
    tolot              varchar2(30)     null,
    orderlimit         number(5)        null,
    openfacility       varchar2(3)      null,
    cntorder           number(7)        null,
    qtyorder           number(10)       null,
    weightorder        number(13,4)     null,
    cubeorder          number(12,4)     null,
    qtycommit          number(10)       null,
    weightcommit       number(13,4)     null,
    cubecommit         number(12,4)     null,
    staffhrs           number(12,4)     null,
    qtyhazardousorders number(7)        null,
    qtyhotorders       number(7)        null,
    replanned          varchar2(1)      null,
    consolidated       varchar2(1)      null,
    shiptype           varchar2(1)      null,
    carrier            varchar2(4)      null,
    servicelevel       varchar2(4)      null,
    shipcost           number(10,2)     null,
    weight             number(13,4)     null,
    tms_status         varchar2(1)      null,
    tms_status_update  date             null,
	 mass_manifest      char(1) default 'N' null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.wavestatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.webconsignee
(
    consignee       varchar2(10)  not null,
    name            varchar2(40)      null,
    contact         varchar2(40)      null,
    addr1           varchar2(40)      null,
    addr2           varchar2(40)      null,
    city            varchar2(30)      null,
    state           varchar2(2)       null,
    postalcode      varchar2(12)      null,
    countrycode     varchar2(3)       null,
    phone           varchar2(25)      null,
    fax             varchar2(25)      null,
    email           varchar2(255)     null,
    consigneestatus varchar2(1)       null,
    lastuser        varchar2(12)      null,
    lastupdate      date              null,
    ltlcarrier      varchar2(4)       null,
    tlcarrier       varchar2(4)       null,
    spscarrier      varchar2(4)       null,
    billto          varchar2(1)       null,
    shipto          varchar2(1)       null,
    railcarrier     varchar2(4)       null,
    billtoconsignee varchar2(10)      null,
    shiptype        varchar2(1)       null,
    shipterms       varchar2(3)       null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.weblog
(
    nameid      varchar2(40)  not null,
    url         varchar2(120)     null,
    accesscount varchar2(15)      null,
    sessionid   varchar2(25)      null,
    logintime   date              null,
    logouttime  date              null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.webuserheader
(
    nameid   varchar2(12)  not null,
    username varchar2(32)      null,
    usertype varchar2(1)       null,
    desc1    varchar2(255)     null,
    desc2    varchar2(255)     null,
    status   varchar2(1)       null,
    invinq   varchar2(1)       null,
    inq      varchar2(1)       null,
    orders   varchar2(1)       null,
    reports  varchar2(1)       null,
    inb_inq  varchar2(1)       null,
    out_inq  varchar2(1)       null,
    ret_inq  varchar2(1)       null,
    tran_inq varchar2(1)       null,
    misc_inq varchar2(1)       null,
    inb_ord  varchar2(1)       null,
    out_ord  varchar2(1)       null,
    edit_ord varchar2(1)       null,
    can_ord  varchar2(1)       null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.web_disable_log
(
    nameid      varchar2(40) not null,
    accesscount varchar2(15)     null,
    sessionid   varchar2(25)     null,
    disabletime date             null
)
tablespace synapse_act2_data
pctfree 30
pctused 40
/

create table alps.web_trans_log
(
    nameid         varchar2(40)  not null,
    transcount     varchar2(15)      null,
    url            varchar2(120)     null,
    transcountdate date              null
)
tablespace synapse_act_data
pctfree 30
pctused 40
/

create table alps.whentoverifyporeceipts
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.workordercomponents
(
    custid    varchar2(10) not null,
    item      varchar2(20) not null,
    component varchar2(20) not null,
    qty       number(16)       null,
    constraint pk_workordercomponents
    primary key (custid,item,component)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.workorderinstructions
(
    seq          number(8)    not null,
    parent       number(8)        null,
    action       varchar2(2)      null,
    notes        long             null,
    custid       varchar2(10) not null,
    item         varchar2(20) not null,
    title        varchar2(35)     null,
    qty          number(8)        null,
    component    varchar2(20)     null,
    destfacility varchar2(3)      null,
    destlocation varchar2(10)     null,
    destloctype  varchar2(12)     null,
    constraint pk_workorderinstructions
    primary key (custid,item,seq)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.workordersstatus
(
    status char(1)      not null,
    descr  varchar2(35)     null,
    constraint pk_workordersstatus
    primary key (status)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.worldshipdtl
(
    orderid              number(9)         null,
    shipid               number(2)         null,
    cartonid             varchar2(15)  not null,
    estweight            number(13,4)      null,
    actweight            number(13,4)      null,
    trackid              varchar2(20)      null,
    status               varchar2(10)      null,
    shipdatetime         varchar2(14)      null,
    carrierused          varchar2(10)      null,
    reason               varchar2(100)     null,
    cost                 number(10,2)      null,
    termid               varchar2(4)       null,
    satdeliveryused      varchar2(1)       null,
    packlistshipdatetime varchar2(14)      null,
    length               number(10,4)      null,
    width                number(10,4)      null,
    height               number(10,4)      null,
    rmatrackingno        varchar2(20)      null,
    actualcarrier        varchar2(4)       null
)
tablespace synapse_user_data
pctfree 10
pctused 40
/

create table alps.xferfiles
(
    oservername varchar2(30) not null,
    ofilename   varchar2(30) not null,
    odirname    varchar2(30) not null,
    dservername varchar2(30)     null,
    dfilename   varchar2(30)     null,
    ddirname    varchar2(30)     null,
    dtrigproc   varchar2(30)     null,
    freqday     number(5)        null,
    freqhour    number(5)        null,
    attempts    number(5)        null,
    interval    number(5)        null,
    constraint pk_xferfiles
    primary key (oservername,ofilename,odirname)
        using index pctfree 10
                    tablespace synapse_lod_index
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.xfernodes
(
    server  varchar2(30) not null,
    userid  varchar2(30) not null,
    userpwd varchar2(30) not null,
    constraint pk_xfernodes
    primary key (server)
        using index pctfree 10
                    tablespace synapse_lod2_index
)
tablespace synapse_lod2_data
pctfree 20
pctused 60
/

create table alps.zone
(
    zoneid               varchar2(10) not null,
    description          varchar2(30)     null,
    panddlocation        varchar2(10)     null,
    lastuser             varchar2(12)     null,
    lastupdate           date             null,
    facility             varchar2(3)      null,
    abbrev               varchar2(12)     null,
    picktype             varchar2(4)      null,
    pickdirection        char(1)          null,
    pickconfirmlocation  char(1)          null,
    pickconfirmitem      char(1)          null,
    pickconfirmcontainer char(1)          null,
    nextlinepickby       char(1)          null,
    convlocation         varchar2(10)     null,
    convdirection        char(1)          null
)
tablespace synapse_lod_data
pctfree 20
pctused 60
/

create table alps.zseq
(
    seq number(5) not null,
    constraint zseq_pk
    primary key (seq)
)
organization index
tablespace synapse_user_data
pctfree 0
storage(pctincrease 0)
/


--
--add referential constraints
--
alter table alps.impexp_chunks add constraint fk_impexp_chunks_lines
foreign key (definc,lineinc)
references alps.impexp_lines (definc,lineinc)

/
alter table alps.impexp_definitions add constraint fk_definitions
foreign key (definc)
references alps.impexp_definitions (definc)
/

exit;
