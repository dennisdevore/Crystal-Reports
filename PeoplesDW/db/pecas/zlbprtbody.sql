create or replace package body zlbprt as
--
-- $Id$
--


-- Private procedures


procedure parse_db_object
   (in_object       in varchar2,
    out_schema      out varchar2,
    out_object_name out varchar2)
is
   l_pos number;
   l_obj varchar2(255) := upper(rtrim(ltrim(in_object)));
begin

	l_pos := instr(l_obj, '.');
	if l_pos = 0 then
		select user into out_schema from dual;
   	out_object_name := l_obj;
   else
   	out_schema := substr(l_obj, 1, l_pos-1);
   	out_object_name := substr(l_obj, l_pos+1);
   end if;
end parse_db_object;


-- Public procedures


procedure print_load_flags
	(in_printno  in number,
    in_profid	 in varchar2,
	 in_event    in varchar2,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_prt is
      select queue
         from alps.printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from alps.spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from alps.spoolerqueues
         order by oraclepipe;
   queuename varchar2(32) := 'LBLSPOOL';
   status number;
begin
   out_message := null;

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := queuename || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := queuename || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   dbms_pipe.pack_message('LOADFLAGS');
   dbms_pipe.pack_message(in_printno);
   dbms_pipe.pack_message(in_profid);
   dbms_pipe.pack_message(in_event);
   dbms_pipe.pack_message(in_printer);
   dbms_pipe.pack_message(in_facility);
   dbms_pipe.pack_message(in_user);
   status := dbms_pipe.send_message(queuename);
   if (status != 0) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_load_flags;


procedure print_carton_labels
	(in_printno  in number,
	 in_event    in varchar2,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_prt is
      select queue
         from alps.printer
         where facility = in_facility
           and prtid = in_printer;
   prt c_prt%rowtype;
   cursor c_Q is
      select oraclepipe
         from alps.spoolerqueues
         where prtqueue = prt.queue;
   q c_Q%rowtype;
   cursor c_defQ is
      select oraclepipe
         from alps.spoolerqueues
         order by oraclepipe;
   queuename varchar2(32) := 'LBLSPOOL';
   status number;
begin
   out_message := null;

   open c_prt;
   fetch c_prt into prt;
   close c_prt;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      queuename := queuename || q.oraclepipe;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         queuename := queuename || q.oraclepipe;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   dbms_pipe.pack_message('CTNLABEL');
   dbms_pipe.pack_message(in_printno);
   dbms_pipe.pack_message(in_event);
   dbms_pipe.pack_message(in_printer);
   dbms_pipe.pack_message(in_facility);
   dbms_pipe.pack_message(in_user);
   status := dbms_pipe.send_message(queuename);
   if (status != 0) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end print_carton_labels;


procedure get_lpid_profid
   (in_event	  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_consignee in varchar2,
    in_lpid      in varchar2,
    out_uom      out varchar2,
    out_profid   out varchar2)
is
   cursor c_lbl_all(p_custid varchar2, p_item varchar2, p_consignee varchar2) is
		select profid
     		from alps.custitemlabelprofiles
			where custid = p_custid
           and item = p_item
           and consignee = p_consignee;
   cursor c_lbl_cus_cons(p_custid varchar2, p_consignee varchar2) is
		select profid
     		from alps.custitemlabelprofiles
			where custid = p_custid
           and item is null
           and consignee = p_consignee;
   cursor c_lbl_cus_item(p_custid varchar2, p_item varchar2) is
		select profid
     		from alps.custitemlabelprofiles
			where custid = p_custid
           and item = p_item
           and consignee is null;
   cursor c_lbl_cus(p_custid varchar2) is
		select profid
     		from alps.custitemlabelprofiles
			where custid = p_custid
           and item is null
           and consignee is null;
	lbl c_lbl_all%rowtype;
   l_found boolean;

   function any_key_data
   	(in_view   in varchar2,
       in_keycol in varchar2,
       in_key    in varchar2)
  	return boolean
   is
   	cursor c_tab_cols(p_owner varchar2, p_table varchar2, p_column varchar2) is
      	select data_type, data_length
         	from all_tab_columns
            where owner = p_owner
              and table_name = p_table
              and column_name = p_column;
		tc c_tab_cols%rowtype;
      l_found boolean;
      l_cnt pls_integer;
      l_schema varchar2(255);
      l_obj varchar2(255);
   begin
   	parse_db_object(in_view, l_schema, l_obj);
		open c_tab_cols(l_schema, l_obj, in_keycol);
   	fetch c_tab_cols into tc;
	   l_found := c_tab_cols%found;
   	close c_tab_cols;
      if l_found then
			if (tc.data_length != 15) or (substr(upper(tc.data_type),1,7) != 'VARCHAR') then
      		l_found := false;				-- keycol not of "type" lpid
       	else
		   	execute immediate 'select count(1) from ' || l_schema || '.' || l_obj ||
            		' where ' || in_keycol || ' = ''' || in_key || ''''
					into l_cnt;
         	if l_cnt = 0 then
            	l_found := false;
           	end if;
       	end if;
   	end if;
      return l_found;
   exception
      when OTHERS then
         return false;
   end any_key_data;

   procedure any_proflines
   	(in_profid in varchar2,
       in_event  in varchar2,
       in_uom    in varchar2,
       in_lpid   in varchar2,
       out_uom   out varchar2,
       out_found out boolean)
   is
   	cursor c_pf is
			select viewname, viewkeycol, uom
   			from alps.labelprofileline
            where profid = in_profid
              and businessevent = in_event
              and (uom = in_uom or uom is null)
           	order by uom;								-- uom appears before null
		pf c_pf%rowtype;
   	l_found boolean := false;
   begin
		out_uom := null;
   	open c_pf;
      loop
      	fetch c_pf into pf;
         exit when c_pf%notfound;
   		l_found := any_key_data(pf.viewname, pf.viewkeycol, in_lpid);
         if l_found then
         	out_uom := pf.uom;
            exit;
        	end if;
		end loop;
   	close c_pf;
      out_found := l_found;
   exception
      when OTHERS then
      	out_found := false;
   end any_proflines;
begin
   out_uom := null;
	out_profid := null;

   if in_consignee is not null then		-- try all 3 first if there is a consignee
	   open c_lbl_all(in_custid, in_item, in_consignee);
      fetch c_lbl_all into lbl;
      l_found := c_lbl_all%found;
      close c_lbl_all;
   	if l_found then
			any_proflines(lbl.profid, in_event, in_uom, in_lpid, out_uom, l_found);
      	if l_found then
            out_profid := lbl.profid;
            return;
        	end if;
     	end if;

	   open c_lbl_cus_cons(in_custid, in_consignee);	-- cust / consignee
      fetch c_lbl_cus_cons into lbl;
      l_found := c_lbl_cus_cons%found;
      close c_lbl_cus_cons;
   	if l_found then
			any_proflines(lbl.profid, in_event, in_uom, in_lpid, out_uom, l_found);
      	if l_found then
            out_profid := lbl.profid;
            return;
        	end if;
     	end if;
	end if;

	open c_lbl_cus_item(in_custid, in_item);				-- cust / item
   fetch c_lbl_cus_item into lbl;
   l_found := c_lbl_cus_item%found;
   close c_lbl_cus_item;
   if l_found then
		any_proflines(lbl.profid, in_event, in_uom, in_lpid, out_uom, l_found);
      if l_found then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

	open c_lbl_cus(in_custid);									-- cust only
   fetch c_lbl_cus into lbl;
   l_found := c_lbl_cus%found;
   close c_lbl_cus;
   if l_found then
		any_proflines(lbl.profid, in_event, in_uom, in_lpid, out_uom, l_found);
      if l_found then
         out_profid := lbl.profid;
         return;
      end if;
   end if;

exception
   when OTHERS then
		out_profid := null;
end get_lpid_profid;


end zlbprt;
/

show errors package body zlbprt;
exit;
