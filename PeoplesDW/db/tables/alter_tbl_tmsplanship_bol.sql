--
-- $Id$
--
CREATE TABLE ALPS.TMSPLANSHIP_BOLCOMMENTS 
(
    SENDERTRANSMISSIONNO       NUMBER           NULL,
    SHIPTO                     VARCHAR2(10)     NULL,
    BOLCOMMENT                 LONG             NULL,
    ADDR                       VARCHAR2(40)     NULL,
    CITY                       VARCHAR2(30)     NULL,
    STATE                      VARCHAR2(2)      NULL,
    POSTALCODE                 VARCHAR2(12)     NULL
)
;
exit;
