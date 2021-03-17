--
-- $Id$
--

update tabledefs set codemask = '>Cccccccccccc;0;_' where tableid = 'PickRequestQueues';

update PickRequestQueues
set code='*/'||code
where instr(code,'/') = 0;

exit;
