--
-- $Id$
--

DROP TABLE TBL_MESSAGE_HEADER CASCADE CONSTRAINTS ; 

CREATE TABLE TBL_MESSAGE_HEADER ( 
  MESSAGE_ID     NUMBER        NOT NULL, 
  MESSAGE_TYPE   NUMBER        NOT NULL, 
  SORT_ORDER     NUMBER, 
  BASE_LANGUAGE  VARCHAR2 (200), 
  CONSTRAINT PK_MSG_ID_1
  PRIMARY KEY ( MESSAGE_ID ) ) ; 

exit;