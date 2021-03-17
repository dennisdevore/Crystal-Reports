--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_SHIPUNITSPEC 
(
    TRANSMISSIONCREATEDATETIME  DATE             NULL,
    SENDERTRANSMISSIONNO        NUMBER           NULL,
    REFERENCETRANSMISSIONNO     NUMBER           NULL,
    SHIPUNITSPECDOMAINNAME      VARCHAR2(20)     NULL,
    SHIPUNITSPEC                VARCHAR2(40)     NULL,
    SHIPUNITSPECNAME            VARCHAR2(40)     NULL,
    TAREWEIGHTVALUE             FLOAT(5)         NULL,
    TAREWEIGHTUOM               VARCHAR2(20)     NULL,
    MAXWEIGHTVALUE              FLOAT(5)         NULL,
    MAXWEIGHTUOM                VARCHAR2(20)     NULL,
    VOLUMEVALUE                 FLOAT(5)         NULL,
    VOLUMEUOM                   VARCHAR2(20)     NULL,
    LENGTHVALUE                 FLOAT(5)         NULL,
    LENGTHUOM                   VARCHAR2(20)     NULL,
    WIDTHVALUE                  FLOAT(5)         NULL,
    WIDTHUOM                    VARCHAR2(20)     NULL,
    HEIGHTVALUE                 FLOAT(5)         NULL,
    HEIGHTUOM                   VARCHAR2(20)     NULL
);
exit;
