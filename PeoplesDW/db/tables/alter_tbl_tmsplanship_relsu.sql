--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_RELSU 
(
    TRANSMISSIONCREATEDATETIME     DATE             NULL,
    SENDERTRANSMISSIONNO           NUMBER           NULL,
    REFERENCETRANSMISSIONNO        NUMBER           NULL,
    RELEASE                        VARCHAR2(40)     NULL,
    SHIPUNITDOMAINNAME             VARCHAR2(20)     NULL,
    SHIPUNIT                       VARCHAR2(40)     NULL,
    SHIPUNITSPECDOMAINNAME         VARCHAR2(20)     NULL,
    SHIPUNITSPEC                   VARCHAR2(40)     NULL,
    WEIGHTVALUE                    FLOAT(5)         NULL,
    WEIGHTUOM                      VARCHAR2(20)     NULL,
    VOLUMEVALUE                    FLOAT(5)         NULL,
    VOLUMEUOM                      VARCHAR2(20)     NULL,
    UNITNETWEIGHTVALUE             FLOAT(5)         NULL,
    UNITNETWEIGHTUOM               VARCHAR2(20)     NULL,
    UNITNETVOLUMEVALUE             FLOAT(5)         NULL,
    UNITNETVOLUMEUOM               VARCHAR2(20)     NULL,
    LENGTHVALUE                    FLOAT(5)         NULL,
    LENGTHUOM                      VARCHAR2(20)     NULL,
    WIDTHVALUE                     FLOAT(5)         NULL,
    WIDTHUOM                       VARCHAR2(20)     NULL,
    HEIGHTVALUE                    FLOAT(5)         NULL,
    HEIGHTUOM                      VARCHAR2(20)     NULL,
    PACKAGEDITEMDOMAINNAME         VARCHAR2(20)     NULL,
    PACKAGEDITEM                   VARCHAR2(40)     NULL,
    PACKAGETYPE                    VARCHAR2(40)     NULL,
    PACKAGESHIPUNITWEIGHTVALUE     FLOAT(5)         NULL,
    PACKAGESHIPUNITWEIGHTUOM       VARCHAR2(20)     NULL,
    ISDEFAULTPACKING               VARCHAR2(1)      NULL,
    ISHAZARDOUS                    VARCHAR2(1)      NULL,
    ITEMTRANSACTIONCODE            VARCHAR2(20)     NULL,
    ITEMDOMAINNAME                 VARCHAR2(20)     NULL,
    ITEM                           VARCHAR2(40)     NULL,
    ITEMNAME                       VARCHAR2(40)     NULL,
    ITEMDESCRIPTION                VARCHAR2(40)     NULL,
    COMMODITYDOMAINNAME            VARCHAR2(20)     NULL,
    COMMODITY                      VARCHAR2(40)     NULL,
    NMFCARTICLEDOMAINNAME          VARCHAR2(20)     NULL,
    NMFCARTICLE                    VARCHAR2(40)     NULL,
    NMFCCLASS                      VARCHAR2(40)     NULL,
    REFNUMQUALIFIERDOMAINNAME      VARCHAR2(20)     NULL,
    REFNUMQUALIFIER                VARCHAR2(40)     NULL,
    REFNUMVALUE                    NUMBER           NULL,
    LINENUMBER                     NUMBER           NULL,
    ITEMISSPLITALLOWED             VARCHAR2(1)      NULL,
    ITEMWEIGHTVALUE                FLOAT(5)         NULL,
    ITEMWEIGHTUOM                  VARCHAR2(20)     NULL,
    ITEMVOLUMEVALUE                FLOAT(5)         NULL,
    ITEMVOLUMEUOM                  VARCHAR2(20)     NULL,
    PACKAGEDITEMCOUNT              NUMBER           NULL,
    PACKAGEITEMSUSPECREFDOMAINNAME VARCHAR2(20)     NULL,
    PACKAGEITEMSUSPECREF           VARCHAR2(40)     NULL,
    PACKAGEITEMSUSPECDOMAINNAME    VARCHAR2(20)     NULL,
    PACKAGEITEMSUSPEC              VARCHAR2(40)     NULL,
    PACKAGEDITEMTAREWEIGHTVALUE    FLOAT(5)         NULL,
    PACKAGEDITEMTAREWEIGHTUOM      VARCHAR2(20)     NULL,
    PACKAGEDITEMMAXWEIGHTVALUE     FLOAT(5)         NULL,
    PACKAGEDITEMMAXWEIGHTUOM       VARCHAR2(20)     NULL,
    PACKAGEDITEMVOLUMEVALUE        FLOAT(5)         NULL,
    PACKAGEDITEMVOLUMEUOM          VARCHAR2(20)     NULL,
    PACKAGEDITEMLENGTHVALUE        FLOAT(5)         NULL,
    PACKAGEDITEMLENGTHUOM          VARCHAR2(20)     NULL,
    PACKAGEDITEMWIDTHVALUE         FLOAT(5)         NULL,
    PACKAGEDITEMWIDTHUOM           VARCHAR2(20)     NULL,
    PACKAGEDITEMHEIGHTVALUE        FLOAT(5)         NULL,
    PACKAGEDITEMHEIGHTUOM          VARCHAR2(20)     NULL,
    PACKAGEDITEMSPECCOUNT          NUMBER           NULL,
    WEIGHTPERSHIPUNITVALUE         FLOAT(5)         NULL,
    WEIGHTPERSHIPUNITUOM           VARCHAR2(20)     NULL,
    VOLUMEPERSHIPUNITVALUE         FLOAT(5)         NULL,
    VOLUMEPERSHIPUNITUOM           VARCHAR2(20)     NULL,
    COUNTPERSHIPUNIT               NUMBER           NULL,
    SHIPUNITRELEASEDOMAINNAME      VARCHAR2(20)     NULL,
    SHIPUNITRELEASE                VARCHAR2(40)     NULL,
    SHIPUNITRELEASELINEDOMAINNAME  VARCHAR2(20)     NULL,
    SHIPUNITRELEASELINE            VARCHAR2(40)     NULL,
    ISSPLITALLOWED                 VARCHAR2(1)      NULL,
    SHIPUNITCOUNT                  NUMBER           NULL,
    TRANSORDERSHIPUNITDOMAINNAME   VARCHAR2(20)     NULL,
    TRANSORDERSHIPUNIT             VARCHAR2(40)     NULL
);
exit;
