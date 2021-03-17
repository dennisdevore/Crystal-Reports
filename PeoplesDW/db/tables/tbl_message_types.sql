--
-- $Id$
--

DROP TABLE TBL_MESSAGE_TYPES CASCADE CONSTRAINTS ; 

CREATE TABLE TBL_MESSAGE_TYPES ( 
  MESSAGE_TYPE       NUMBER        NOT NULL, 
  MESSAGE_TYPE_DESC  VARCHAR2 (200)  NOT NULL, 
  SITE_RELATED       NUMBER, 
  CONSTRAINT pk_msg_types_1
  PRIMARY KEY ( MESSAGE_TYPE ) ) ; 

exit;