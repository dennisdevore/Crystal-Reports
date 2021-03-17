--
-- $Id$
--
create table carrierprono
(CARRIER                                  VARCHAR2(4) not null
,SEQ                                      NUMBER(12)
,PRONO                                    VARCHAR2(20)
,ASSIGN_STATUS                            CHAR(1)
,ASSIGN_TIME                              DATE
,ASSIGN_ORDERID                           NUMBER(7)
,ASSIGN_SHIPID                            NUMBER(2)
,LASTUSER                                 VARCHAR2(12)
,LASTUPDATE                               DATE
);
--exit;