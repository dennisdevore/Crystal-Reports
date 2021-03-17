--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_HDR 
(
    TRANSMISSIONCREATEDATETIME DATE             NULL,
    TRANSACTIONCOUNT           NUMBER           NULL,
    SENDERHOSTNAME             VARCHAR2(40)     NULL,
    USERNAME                   VARCHAR2(10)     NULL,
    PASSWORD                   VARCHAR2(20)     NULL,
    SENDERTRANSMISSIONNO       NUMBER           NULL,
    REFERENCETRANSMISSIONNO    NUMBER           NULL,
    STATUS                     NUMBER           NULL
)
;
exit;
