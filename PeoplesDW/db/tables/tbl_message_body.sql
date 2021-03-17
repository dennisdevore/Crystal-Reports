--
-- $Id$
--

DROP TABLE TBL_MESSAGE_BODY CASCADE CONSTRAINTS ; 

CREATE TABLE TBL_MESSAGE_BODY ( 
  MESSAGE_ID  NUMBER        NOT NULL, 
  LANGUAGE    VARCHAR2 (200)  NOT NULL, 
  VERIFIED    NUMBER        NOT NULL, 
  MESSAGE     VARCHAR2 (1000)  NOT NULL, 
  CONSTRAINT pk_msg_body_1
  PRIMARY KEY ( MESSAGE_ID, LANGUAGE ) ) ; 

exit;