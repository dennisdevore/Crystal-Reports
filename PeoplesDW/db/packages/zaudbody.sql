create or replace package body alps.zaudit as
--
-- $Id$
--


-- Public procedures

function which_unique_index(in_table_name varchar2)
return varchar2

is

l_unique_index_count pls_integer;
l_index_name user_tables.table_name%type;

begin

l_index_name := 'Null';

select count(1)
  into l_unique_index_count
  from user_indexes
 where table_name = in_table_name
   and uniqueness = 'UNIQUE'
   and (index_name not like 'SYS%' or
        index_name = 'SYSTEMDEFAULTS_UNIQUE');
if l_unique_index_count = 0 then
  l_index_name := 'None';
elsif l_unique_index_count = 1 then
  select index_name
    into l_index_name
    from user_indexes
   where table_name = in_table_name
     and uniqueness = 'UNIQUE'
     and (index_name not like 'SYS%' or
          index_name = 'SYSTEMDEFAULTS_UNIQUE');
elsif in_table_name = 'CARRIERPRONO' then
  l_index_name := 'CARRIERPRONO_PRONO_IDX';
elsif in_table_name = 'CUSTAUDITSTAGELOC' then
  l_index_name := 'CUSTAUDITSTAGELOC_CUSTID';
elsif in_table_name = 'CUSTITEMALIAS' then
  l_index_name := 'CUSTITEMALIAS_IDX';
elsif in_table_name = 'CUSTITEMBOLCOMMENTS' then
  l_index_name := 'CUSTITEMBOLCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMOUTCOMMENTS' then
  l_index_name := 'CUSTITEMOUTCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMINCOMMENTS' then
  l_index_name := 'CUSTITEMINCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMSUBS' then
  l_index_name := 'CUSTITEMSUBS_UNIQUE';
elsif in_table_name = 'CUSTITEMLOT' then
  l_index_name := 'CUSTITEMLOT_UNIQUE';
elsif in_table_name = 'CUSTITEMTOT' then
  l_index_name := 'CUSTITEMTOT_UNIQUE_CUSTID';
elsif in_table_name = 'CUSTOMER' then
  l_index_name := 'CUSTOMER_UNIQUE';
elsif in_table_name = 'IMPEXP_CHUNKS_MAPPINGS' then
  l_index_name := 'PK_IMPEXP_CHUNKS_MAPPINGS';
elsif in_table_name = 'IMPEXP_DEFINITIONS' then
  l_index_name := 'PK_IMPEXP_DEFINITIONS';
elsif in_table_name = 'LOADS' then
  l_index_name := 'LOADS_IDX';
elsif in_table_name = 'MULTISHIPDTL' then
  l_index_name := 'IX_MULTISHIPDTL_CARTONID';
elsif in_table_name = 'ORDERDTLLINE' then
  l_index_name := 'ORDERDTLLINE_LINENUMBER';
elsif in_table_name = 'ORDERHDR' then
  l_index_name := 'ORDERHDR_IDX';
elsif in_table_name = 'ORDERDTL' then
  l_index_name := 'ORDERDTL_UNIQUE';
elsif in_table_name = 'ORDERDTLBOLCOMMENTS' then
  l_index_name := 'ORDERDTLBOLCOMMENTS_UNIQUE';
elsif in_table_name = 'WAVES' then
  l_index_name := 'WAVES_UNIQUE';
elsif in_table_name = 'PIMEVENTS' then
  l_index_name := 'PIMEVENTS_START';
elsif in_table_name = 'ALERT_CONTACTS' then
  l_index_name := 'ALERT_CONTACTS_PK';
elsif in_table_name = 'TARIFFBREAKS' then
  l_index_name := 'TARIFFBREAKS_UNIQUE';
elsif in_table_name = 'FREIGHT_BILL_RESULTS' then
  l_index_name := 'FREIGHT_BILL_RESULTS_UNIQUE_AC';
else
  l_index_name := 'Multiple';
end if;

return l_index_name;

exception when others then
  return 'Unknown';
end which_unique_index;

procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in varchar2,
    in_old_value in varchar2,
    in_origin    in varchar2)
is
begin
   if (in_new_value <> in_old_value
   or  (in_new_value is null and in_old_value is not null)
   or  (in_new_value is not null and in_old_value is null)) then
      insert into audit_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name, in_old_value, in_new_value );
   end if;
end check_val;


procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in number,
    in_old_value in number,
    in_origin    in varchar2)
is
begin
   if (in_new_value <> in_old_value
   or  (in_new_value is null and in_old_value is not null)
   or  (in_new_value is not null and in_old_value is null)) then
      insert into audit_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name, in_old_value, in_new_value );
   end if;
end check_val;


procedure check_val
   (in_tbl_name  in varchar2,
    in_col_name  in varchar2,
    in_userid    in varchar2,
    in_new_value in date,
    in_old_value in date,
    in_origin    in varchar2)
is
begin
   if (in_new_value <> in_old_value
   or  (in_new_value is null and in_old_value is not null)
   or  (in_new_value is not null and in_old_value is null)) then
      insert into audit_table
         (origin, occurred, userid, tbl_name, col_name, old_value, new_value)
      values
         (in_origin, sysdate, in_userid, in_tbl_name, in_col_name,
          to_char(in_old_value, 'dd-mon-yyyy hh24:mi:ss'),
          to_char(in_new_value, 'dd-mon-yyyy hh24:mi:ss'));
   end if;
end check_val;

PROCEDURE get_next_modseq
(in_table_name_old varchar2
,in_table_name_new varchar2
,out_modseq OUT number
,out_msg IN OUT varchar2
)
is

l_modseq_found boolean;
l_row_count pls_integer;

begin

l_modseq_found := False;

while not l_modseq_found
loop

  select modseq.nextval
    into out_modseq
    from dual;
  
  execute immediate 'select count(1) from ' ||
           in_table_name_old || ' where mod_seq = :p_mod_seq'
           into l_row_count using out_modseq;
  
  if l_row_count != 0 then
    goto continue_loop;
  end if;    

  execute immediate 'select count(1) from ' ||
           in_table_name_new || ' where mod_seq = :p_mod_seq'
           into l_row_count using out_modseq;
  
  if l_row_count != 0 then
    goto continue_loop;
  end if;    

  l_modseq_found := True;
  
<< continue_loop >>
  null;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_modseq;

function table_name
(in_table_name varchar2
) return varchar2

is

l_out_table_name varchar2(255);

begin

  l_out_table_name := in_table_name;
  
  while (length(l_out_table_name)) > 30
  loop
    l_out_table_name := substr(l_out_table_name,2,255);
  end loop;

  return l_out_table_name;
  
exception when others then
  return null;
end table_name;

end zaudit;
/

show errors package body zaudit;
exit;
