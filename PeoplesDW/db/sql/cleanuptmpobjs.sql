set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on

spool cleanuptmpobjs.out

declare
l_length pls_integer;
l_cust_count pls_integer;
l_updflag char(1);
l_cmd varchar2(4000);
l_tot pls_integer := 0;

begin

l_updflag := substr(upper('&1'),1,1);

for obj in (select object_name,
                   object_type,
                   substr(object_name,instr(object_name,'_',-1)+1,32) as suffix,
                   last_ddl_time
    from user_objects
   where object_type in ('TABLE','VIEW')
     and object_name not like 'AQ$%'
     and object_name not in (select queue_table from user_queues)
     and instr(object_name,'_') != 0
     and substr(object_name,length(object_name),1) >= '0'
     and substr(object_name,length(object_name),1) <= '9'
     and object_name not like 'BAR%' -- ignore barrett objects
     and object_name not like 'LAST%' -- ignore 'last' validation tables
     and object_name not in
         ('DRE_AGGRPICKLISTVIEW2'
         ,'DRE_AGGRPICKLISTVIEW3'
         ,'DRE_BOLITMCMTV1'
         ,'DRE_BOLITMCMTV2'
         ,'DRE_BOLITMCMTV3'
         ,'DRE_BOLNMFC_PRELIM2'
         ,'DRE_BOLRPT_PRELIM2'
         ,'FREIGHT_AIMS_AT1'
         ,'FREIGHT_AIMS_AT2'
         ,'FREIGHT_AIMS_G62'
         ,'FREIGHT_AIMS_K1'
         ,'FREIGHT_AIMS_N1'
         ,'FREIGHT_AIMS_N4'
         ,'TMSPLANSHIP_SHIPHDR2'
         ,'SHIP_NOTE_945_S18'
         ,'SHIP_NT_945_S18'
         ,'SIP_ASN_856_LI2'
         ,'SIP_ASN_856_PO2'
        )
	   and last_ddl_time < sysdate - .035
     and substr(object_name,instr(object_name,'_',-1)+1,32) != object_name
   order by last_ddl_time)
loop

  l_length := length(obj.suffix) - 1;
  while l_length > 1
  loop
    if substr(obj.suffix,1,l_length) = 'ALL' then
     l_cust_count := 1;
    else
      select count(1)
        into l_cust_count
        from customer
       where custid = substr(obj.suffix,1,l_length);
    end if;
    if l_cust_count != 0 then    
      l_cmd := 'drop ' || obj.object_type || ' ' || obj.object_name;
      if l_updflag != 'Y' then
        l_cmd := l_cmd || ' (' || to_char(obj.last_ddl_time, 'mm/dd/yy hh24:mi:ss') || ')';
      end if;
      l_tot := l_tot + 1;
      zut.prt(l_cmd);
      if l_updflag = 'Y' then
        execute immediate l_cmd;
      end if;
      exit;
    else 
      l_length := l_length - 1;
    end if;
  end loop;

end loop;

--look for objects where the custid has a dash in the custid
--(the dash is replaced by an underscore because oracle doesn't
--allow dashes in an object name)
for obj in (select object_name,
                   object_type,
                   substr(object_name,instr(object_name,'_',-1,2)+1,32) as suffix,
                   last_ddl_time
    from user_objects
   where object_type in ('TABLE','VIEW')
     and object_name not like 'AQ$%'
     and object_name not in (select queue_table from user_queues)
     and instr(object_name,'_') != 0
     and substr(object_name,length(object_name),1) >= '0'
     and substr(object_name,length(object_name),1) <= '9'
     and object_name not like 'BAR%' -- ignore barrett objects
     and object_name not like 'LAST%' -- ignore 'last' validation tables
     and object_name not in
         ('DRE_AGGRPICKLISTVIEW2'
         ,'DRE_AGGRPICKLISTVIEW3'
         ,'DRE_BOLITMCMTV1'
         ,'DRE_BOLITMCMTV2'
         ,'DRE_BOLITMCMTV3'
         ,'DRE_BOLNMFC_PRELIM2'
         ,'DRE_BOLRPT_PRELIM2'
         ,'FREIGHT_AIMS_AT1'
         ,'FREIGHT_AIMS_AT2'
         ,'FREIGHT_AIMS_G62'
         ,'FREIGHT_AIMS_K1'
         ,'FREIGHT_AIMS_N1'
         ,'FREIGHT_AIMS_N4'
         ,'TMSPLANSHIP_SHIPHDR2'
         ,'SHIP_NOTE_945_S18'
         ,'SHIP_NT_945_S18'
         ,'SIP_ASN_856_LI2'
         ,'SIP_ASN_856_PO2'
        )
	   and last_ddl_time < sysdate - .035
     and substr(object_name,instr(object_name,'_',-1,2)+1,32) != object_name
   order by last_ddl_time)
loop
  obj.suffix := replace(obj.suffix,'_','-');
  l_length := length(obj.suffix) - 1;
  while l_length > 1
  loop
    if substr(obj.suffix,1,l_length) = 'ALL' then
     l_cust_count := 1;
    else
      select count(1)
        into l_cust_count
        from customer
       where custid = substr(obj.suffix,1,l_length);
    end if;
    if l_cust_count != 0 then    
      l_cmd := 'drop ' || obj.object_type || ' ' || obj.object_name;
      if l_updflag != 'Y' then
        l_cmd := l_cmd || ' (' || to_char(obj.last_ddl_time, 'mm/dd/yy hh24:mi:ss') || ')';
      end if;
      l_tot := l_tot + 1;
      zut.prt(l_cmd);
      if l_updflag = 'Y' then
        execute immediate l_cmd;
      end if;
      exit;
    else 
      l_length := l_length - 1;
    end if;
  end loop;

end loop;

zut.prt('Object count: ' || l_tot);

end;
/
spool off;
exit;
