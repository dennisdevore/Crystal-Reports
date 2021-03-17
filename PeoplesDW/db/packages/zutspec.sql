--
-- $Id$
--
-- general UTility package

create or replace package alps.zutility
is

function data_type(in_table_name varchar2, in_column_name varchar2)
return varchar2;

procedure prt(in_text in varchar2 := null);

procedure show_index(in_table_name varchar2);

procedure drop_index(in_table_name varchar2);

procedure show_constraints(in_table_name varchar2);

function is_active_customer(in_custid IN varchar2)
return char;

function is_active_facility(in_facility IN varchar2)
return char;

function is_purgable(in_loadno int, in_orderid int, in_shipid int, in_lastupdate date)
return char;

function custid_in_object_name(in_object_name varchar2)
return varchar2;

procedure check_data_file_usage;
end zutility;
/
exit;
