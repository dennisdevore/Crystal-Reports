--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_SHIPSTOP 
(
    TRANSMISSIONCREATEDATETIME    DATE             NULL,
    SENDERTRANSMISSIONNO          NUMBER           NULL,
    REFERENCETRANSMISSIONNO       NUMBER           NULL,
    STOPSEQUENCE                  NUMBER           NULL,
    STOPDURATIONVALUE             NUMBER           NULL,
    STOPDURATIONUOM               VARCHAR2(20)     NULL,
    ISAPPOINTMENT                 VARCHAR2(1)      NULL,
    LOCATIONREFDOMAINNAME         VARCHAR2(20)     NULL,
    LOCATIONREF                   VARCHAR2(40)     NULL,
    DISTFROMPREVSTOPVALUE         NUMBER           NULL,
    DISTFROMPREVSTOPUOM           VARCHAR2(20)     NULL,
    STOPREASON                    VARCHAR2(40)     NULL,
    ARRIVALTIMEPLANNED            DATE             NULL,
    ARRIVALTIMEESTIMATED          DATE             NULL,
    ISARRIVALPLANNEDTIMEFIXED     VARCHAR2(1)      NULL,
    DEPARTUREPLANNEDTIME          DATE             NULL,
    DEPARTUREESTIMATEDTIME        DATE             NULL,
    ISDEPARTUREESTIMATEDTIMEFIXED VARCHAR2(1)      NULL,
    ISPERMANENT                   VARCHAR2(1)      NULL,
    ISDEPOT                       VARCHAR2(1)      NULL,
    ACCESSORIALTIMEDURATIONVALUE  NUMBER           NULL,
    ACCESSORIALTIMEDURATIONUOM    VARCHAR2(20)     NULL
);
exit;