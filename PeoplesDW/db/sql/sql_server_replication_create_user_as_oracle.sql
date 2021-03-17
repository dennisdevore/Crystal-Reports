--***************************************************************************
--
-- File:
--  original script from Copyright (c) 2003 Microsoft Corporation: oracleadmin.sql
--
-- Notes:
--  run the sql_server_replication_create_tablespace_as_oracle.sh first
--***************************************************************************


-- Create the replication user account
CREATE USER sqlsrvrepl IDENTIFIED BY sq15rvr3pl DEFAULT TABLESPACE sqlsrvrepl QUOTA UNLIMITED ON sqlsrvrepl;

-- It is recommended that only the required grants be granted to this user.
--
-- The following 5 privileges are granted explicitly, but could be granted through a role.
GRANT CREATE PUBLIC SYNONYM TO sqlsrvrepl;
GRANT DROP PUBLIC SYNONYM TO sqlsrvrepl;
GRANT CREATE SEQUENCE TO sqlsrvrepl;
GRANT CREATE PROCEDURE TO sqlsrvrepl;
GRANT CREATE SESSION TO sqlsrvrepl;

-- The following privileges must be granted explicitly to the replication user.
GRANT CREATE TABLE TO sqlsrvrepl;
GRANT CREATE VIEW TO sqlsrvrepl;

-- The replication user login needs to be able to create a tracking trigger on any table that is
-- to be published in a transactional publication. The CREATE ANY privilege is used to
-- obtain the authorization to create these triggers.  To replicate a table, the table 
-- owner must additionally explicitly grant select authorization on the table to the
-- replication user.
--
-- NOTE: CREATE ANY TRIGGER is not required for snapshot publications.
GRANT CREATE ANY TRIGGER TO sqlsrvrepl;

EXIT
