create or replace package body pkg_manage_reports as
--
-- $Id: pkg_manage_reports_body.sql 5114 2010-06-14 15:55:21Z eric $
--

procedure usp_add_report(
  in_report_filename VARCHAR2,
  in_report_label VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is

CURSOR C_REPORT(in_report VARCHAR2)
IS
    select report_label_id
      from tbl_report_types
     where report_type_id = in_report;
report C_REPORT%rowtype;

CURSOR C_LABEL
IS
    select max(label_id) as label_id
      from tbl_global_label_repository;
label C_LABEL%rowtype;

CURSOR C_ACTION
IS
    select max(action_id) as action_id
      from tbl_lkup_permissions;
action C_ACTION%rowtype;

label_id integer;
action_id integer;
s_report varchar2(200);
iIndex integer;

begin
   return_status := 1;
   return_msg := 'OKAY';

   iIndex := INSTR(UPPER(in_report_filename), '.RPT', 1, 1);

   if (iIndex = 0) then
   	 s_report := trim(in_report_filename);
   else
   	 s_report := trim(SUBSTR(in_report_filename,1,iIndex-1));
   end if;

   if length(s_report) = 0 then
     return_status := -1;
     return_msg := 'Invalid report filename "'||in_report_filename||'".';
     return;
   end if;

   report := null;
   OPEN C_REPORT(s_report);
   FETCH C_REPORT into report;
   CLOSE C_REPORT;

   if report.report_label_id is not null then
     return_status := -2;
     return_msg := 'Report '||in_report_filename||' already added.';
     return;
   end if;
   
   if length(trim(in_report_label)) = 0 then
     return_status := -3;
     return_msg := 'Invalid report label "'||in_report_label||'".';
     return;
   end if;

   label := null;
   OPEN C_LABEL;
   FETCH C_LABEL into label;
   CLOSE C_LABEL;

   label_id := label.label_id + 1;

   action := null;
   OPEN C_ACTION;
   FETCH C_ACTION into action;
   CLOSE C_ACTION;

   action_id := action.action_id + 1;

   insert into tbl_global_label_repository values(label_id,12,1,trim(in_report_label),null,0);
   insert into tbl_lkup_permissions values(action_id,label_id);
   insert into tbl_report_types values(s_report,label_id,action_id);

exception WHEN OTHERS THEN
   return_status := 0;
   return_msg := sqlerrm;
end  usp_add_report;

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

procedure usp_delete_report(
  in_label_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is
begin
   return_status := 1;
   return_msg := 'OKAY';

   delete from tbl_report_types
     where report_label_id = in_label_id;
   delete from tbl_lkup_permissions
     where action_label_id = in_label_id;
   delete from tbl_global_label_repository
     where label_id = in_label_id;

exception WHEN OTHERS THEN
   return_status := 0;
   return_msg := sqlerrm;
end usp_delete_report;

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

procedure usp_update_report_label(
  in_label_id NUMBER,
  in_report_label VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is 
begin
   return_status := 1;
   return_msg := 'OKAY';

   if length(trim(in_report_label)) = 0 then
     return_status := -1;
     return_msg := 'Invalid report label "'||in_report_label||'".';
     return;
   end if;

  update tbl_global_label_repository
     set en = trim(in_report_label)
   where label_id=in_label_id;

exception WHEN OTHERS THEN
   return_status := 0;
   return_msg := sqlerrm;
end usp_update_report_label;

end pkg_manage_reports;
/
exit;

