CREATE OR REPLACE package body  pkg_manage_companies as
--
-- $Id$
--

procedure usp_insert_company(
  company_name VARCHAR2,
  synapse_profile VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

)is

companyid NUMBER;

begin

  begin
    select nvl(max(company_id),0) + 1 into companyid from tbl_companies;
    exception when others then
      return_status := 0;
      return_msg := sqlerrm;
      return;
  end;

  insert into tbl_companies(company_id, company_name, synapse_profile)
         values(companyid, company_name, synapse_profile);

   return_status := 1;
   return_msg := 'OKAY';

  exception when others then
      return_status := 0;
      return_msg := sqlerrm;
      return;

end usp_insert_company;

procedure usp_delete_company(
  companyid in number,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

)is

cntGroups number;

begin

	 select count(1) into cntGroups 
	 		from tbl_groups
			where company_id = companyid;
			
	if cntGroups = 0 then
	
	   	delete from tbl_companies
			   where company_id = companyid;
			
		return_status := 1;
		return_msg := 'OKAY';

	else
		return_status := 2;
   		return_msg := 'INUSE';
	end if;


  exception when others then
      return_status := 0;
      return_msg := sqlerrm;
      return;
	 		
end usp_delete_company;

end pkg_manage_companies;
/

exit;
