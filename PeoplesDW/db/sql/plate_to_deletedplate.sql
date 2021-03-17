--
-- $Id: plate_to_deleted_plate.sql 1 2005-05-26 12:20:03Z ed $
--
set serveroutput on
declare
msg varchar2(80) := null;

begin

   zlp.plate_to_deletedplate('123456789012345',  -- LiP number
                             'SYNAPSE',  -- Last User
                             null, -- lip task type (defaults to 'DE')
                             msg); -- resulting message from delete routine
   zut.prt(msg);   
end;
/
exit;
