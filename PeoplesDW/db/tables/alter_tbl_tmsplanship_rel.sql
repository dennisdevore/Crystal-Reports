--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_REL 
(
    TRANSMISSIONCREATEDATETIME    DATE             NULL,
    SENDERTRANSMISSIONNO          NUMBER           NULL,
    REFERENCETRANSMISSIONNO       NUMBER           NULL,
    RELEASEDOMAINNAME             VARCHAR2(20)     NULL,
    RELEASE                       VARCHAR2(40)     NULL,
    TRANSORDERHEADERDOMAINNAME    VARCHAR2(20)     NULL,
    TRANSORDERHEADER              VARCHAR2(40)     NULL,
    TRANSORDERTRANSACTIONCODE     VARCHAR2(20)     NULL,
    PAYMENTMETHODCODEDOMAINNAME   VARCHAR2(20)     NULL,
    PAYMENTMETHODCODE             VARCHAR2(40)     NULL,
    PLANNINGGROUPDOMAINNAME       VARCHAR2(20)     NULL,
    PLANNINGGROUP                 VARCHAR2(40)     NULL,
    ORDERTYPEDOMAINNAME           VARCHAR2(20)     NULL,
    ORDERTYPE                     VARCHAR2(40)     NULL,
    TIMEWINDOWEMPHASIS            VARCHAR2(20)     NULL,
    SHIPFROMLOCATIONREFDOMAINNAME VARCHAR2(20)     NULL,
    SHIPFROMLOCATIONREF           VARCHAR2(40)     NULL,
    SHIPTOLOCATIONREFDOMAINNAME   VARCHAR2(20)     NULL,
    SHIPTOLOCATIONREF             VARCHAR2(40)     NULL,
    EARLYDELIVERYDATE             DATE             NULL,
    LATEDELIVERYDATE              DATE             NULL,
    DECLAREDVALUECURRENCYCODE     VARCHAR2(20)     NULL,
    DECLAREDVALUEMONETARYAMOUNT   FLOAT(5)         NULL,
    MUSTSHIPALONE                 VARCHAR2(1)      NULL,
    BULKPLANDOMAINNAME            VARCHAR2(20)     NULL,
    BULKPLAN                      VARCHAR2(40)     NULL,
    BESTDIRECTBUYCURRENCYCODE     VARCHAR2(20)     NULL,
    BESTDIRECTBUYMONETARYAMOUNT   FLOAT(5)         NULL,
    BESTDIRECTBUYRATEDOMAINNAME   VARCHAR2(20)     NULL,
    BESTDIRECTBUYRATE             VARCHAR2(40)     NULL,
    BESTDIRECTSELLCURRENCYCODE    VARCHAR2(20)     NULL,
    BESTDIRECTSELLMONETARYAMOUNT  FLOAT(5)         NULL,
    BESTDIRECTSELLRATEDOMAINNAME  VARCHAR2(20)     NULL,
    BESTDIRECTSELLRATE            VARCHAR2(40)     NULL,
    TOTALWEIGHTVALUE              FLOAT(5)         NULL,
    TOTALWEIGHTUOM                VARCHAR2(20)     NULL,
    TOTALVOLUMEVALUE              FLOAT(5)         NULL,
    TOTALVOLUMEUOM                VARCHAR2(20)     NULL,
    TOTALNETWEIGHTVALUE           FLOAT(5)         NULL,
    TOTALNETWEIGHTUOM             VARCHAR2(20)     NULL,
    TOTALNETVOLUMEVALUE           FLOAT(5)         NULL,
    TOTALNETVOLUMEUOM             VARCHAR2(20)     NULL,
    TOTALPACKAGEDITEMSPECCOUNT    NUMBER           NULL,
    TOTALPACKAGEDITEMCOUNT        NUMBER           NULL
);
exit;
