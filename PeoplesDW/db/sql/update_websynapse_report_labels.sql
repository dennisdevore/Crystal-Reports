--
-- $Id$
--
set serveroutput on
set verify off

declare

   label_cnt integer;

begin
   
   select count(1)
     into label_cnt
     from tbl_global_label_repository
    where label_id >= 500
      and label_id < 600
      and label_type_id = 12;

   if (label_cnt > 0) then
      update tbl_global_label_repository
         set label_id = label_id + 100
       where label_id >= 500
         and label_type_id = 12;
      
      update tbl_lkup_permissions
         set action_label_id = action_label_id + 100
       where action_label_id >= 500;
      
      update tbl_report_types
         set report_label_id = report_label_id + 100
       where report_label_id >= 500;
   end if;

end;
/

exit;
