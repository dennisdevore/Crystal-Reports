create or replace package body alps.zloadhistory as
--
-- $Id: zlhbody.sql 1 2005-05-26 12:20:03Z ed $
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--

--
-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************



----------------------------------------------------------------------
--
-- add_loadhistory_item
--
----------------------------------------------------------------------
PROCEDURE add_loadhistory
(
    in_loadno       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS

chgdate date;
ldn loads.loadno%type;
l_out_msg varchar2(256);

BEGIN
   out_errmsg := 'OKAY';
   chgdate := sysdate;

   begin
      select loadno into ldn
         from loads
         where loadno = in_loadno;
   exception when no_data_found then
      out_errmsg := 'Invalid load';
      return;
   end;

   insert into loadhistory
     (chgdate, loadno, userid, action, msg)
   values
     (chgdate, in_loadno, in_user, in_action, in_msg);

EXCEPTION when others then
    out_errmsg := 'zlh: ' || sqlerrm;
    zms.log_autonomous_msg('SYNAPSE', null, null, out_errmsg, 'E', 'SYNAPSE', l_out_msg);

END add_loadhistory;


PROCEDURE add_loadhistory_autonomous
(
    in_loadno       IN      number,
    in_action       IN      varchar2,
    in_msg          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
is PRAGMA AUTONOMOUS_TRANSACTION;
chgdate date;
l_out_msg varchar2(255);
begin
   out_errmsg := 'OKAY';
   chgdate := sysdate;
   insert into loadhistory
     (chgdate, loadno, userid, action, msg)
   values
     (chgdate, in_loadno, in_user, in_action, in_msg);
   commit;
exception when others then
   out_errmsg := 'zlha: ' || sqlerrm;
   rollback;
   zms.log_autonomous_msg('SYNAPSE', null, null, out_errmsg, 'E', 'SYNAPSE', l_out_msg);
end add_loadhistory_autonomous;

end zloadhistory;
/
show errors package body zloadhistory;
exit;
