--
-- $Id$
--

DROP TABLE TBL_REPORT_TYPES CASCADE CONSTRAINTS ; 

CREATE TABLE TBL_REPORT_TYPES ( 
  REPORT_TYPE_ID   VARCHAR2 (20)  NOT NULL, 
  REPORT_LABEL_ID  NUMBER        NOT NULL, 
  ACTION           NUMBER ) ; 

exit;