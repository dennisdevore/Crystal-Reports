--
-- $Id$
--
create or replace package pkg_manage_companies  is

procedure usp_insert_company(
  company_name VARCHAR2,
  synapse_profile VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_delete_company(
	companyid number,
	return_status out number,
	return_msg out varchar2
);

end pkg_manage_companies;
/
exit;
