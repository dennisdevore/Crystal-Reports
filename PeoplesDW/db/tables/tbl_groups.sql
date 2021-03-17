--
-- $Id$
--

DROP TABLE TBL_GROUPS CASCADE CONSTRAINTS ; 

CREATE TABLE TBL_GROUPS ( 
  GROUP_ID     NUMBER        NOT NULL, 
  GROUP_NAME   VARCHAR2 (100)  NOT NULL, 
  COMPANY_ID   NUMBER        NOT NULL, 
  STATUS       NUMBER        DEFAULT 0 NOT NULL, 
  DELETE_FLAG  NUMBER        DEFAULT 0 NOT NULL ) ; 

ALTER TABLE TBL_GROUPS ADD  CONSTRAINT TBL_GROUPS_UK11009853010396_1
 UNIQUE (GROUP_NAME) ;



exit;