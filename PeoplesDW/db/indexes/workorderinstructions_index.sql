--
-- $Id$
--
ALTER TABLE WORKORDERINSTRUCTIONS ADD CONSTRAINT PK_WORKORDERINSTRUCTIONS
PRIMARY KEY (custid,item,SEQ);
exit;