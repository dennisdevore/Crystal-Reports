--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_SHIPSTOPDTL
(
    TRANSMISSIONCREATEDATETIME    DATE             NULL,
    SENDERTRANSMISSIONNO          NUMBER           NULL,
    REFERENCETRANSMISSIONNO       NUMBER           NULL,
    STOPSEQUENCE                  NUMBER           NULL,
    SHIPMENTSTOPACTIVITY          VARCHAR2(20)     NULL,
    ACTIVITYDURATIONVALUE         NUMBER           NULL,
    ACTIVITYDURATIONUOM           VARCHAR2(20)     NULL,
    SHIPUNITDOMAINNAME            VARCHAR2(20)     NULL,
    SHIPUNIT                      VARCHAR2(40)     NULL,
    ISSHIPSTOPPERMANENT           VARCHAR2(1)      NULL
);
exit;