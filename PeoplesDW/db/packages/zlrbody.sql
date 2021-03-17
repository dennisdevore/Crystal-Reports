create or replace package body alps.zlicensereport as
--
-- $Id: zlicbody.sql 6147 2011-02-17 21:20:49Z ed $
--


-- constants


QUEUENAME   CONSTANT    varchar2(7) := 'license';

procedure populate_usersessions
   (in_crt	       in number,
    in_legacyrf    in number,
    in_webrf       in number,
    out_msg        out varchar2)
as
	v_count number;
	v_date date := sysdate;
	
	procedure update_table(p_program in varchar2, 
		p_usercount in number, 
		p_date in date)
	as
		v_count number := 0;
		v_insert number := 0;
	begin
		begin
			select total into v_count
			from usersessions
			where lower(program) = lower(p_program);
		exception
			when no_data_found then
				v_insert := 1;
				v_count := 0;
			when others then	
				v_count := 0;
		end;
		
		if (nvl(p_usercount,0) > v_count or v_insert = 1) then
			if (v_insert = 0) then
				update usersessions
				set total = p_usercount, occurred = p_date
				where lower(program) = lower(p_program);
			else	
				insert into usersessions (program, total, occurred)
				values (lower(p_program), p_usercount, p_date);
			end if;
		end if;
	end update_table;
begin
	out_msg := 'OKAY';
	update_table('synapse', nvl(in_crt,0), v_date);
	update_table('rfwhse', nvl(in_legacyrf,0), v_date);
	update_table('webrf', nvl(in_webrf,0), v_date);
	update_table('rfwhse+synapse', nvl(in_crt,0) + nvl(in_legacyrf,0) + nvl(in_webrf,0), v_date);
	
	populate_fac_usersessions('ZZZ', in_crt, in_legacyrf, in_webrf, out_msg);
exception	
	when others then	
		out_msg := 'Error: ' || sqlerrm(sqlcode);
end populate_usersessions;

procedure populate_fac_usersessions
   (in_facility    in varchar2,
	in_crt	       in number,
    in_legacyrf    in number,
    in_webrf       in number,
    out_msg        out varchar2)
as
	v_count number;
	v_date date := trunc(sysdate, 'HH24');
begin
	out_msg := 'OKAY';
	
	select count(1) into v_count
	from fac_usersessions
	where time_period = v_date;
	
	if (v_count = 0) then
		for rec in (select distinct facility from fac_usersessions)
		loop
			insert into fac_usersessions (facility, time_period)
			values (rec.facility, v_date);
		end loop;
	end if;
	
	select count(1) into v_count
	from fac_usersessions
	where facility = in_facility and time_period = v_date;
	
	if (v_count > 0) then
		update fac_usersessions
		set crt = greatest(crt, nvl(in_crt,0)),
			legacyrf = greatest(legacyrf, nvl(in_legacyrf,0)),
			webrf = greatest(webrf, nvl(in_webrf,0)),
			total = greatest(total, nvl(in_crt,0) + nvl(in_legacyrf,0) + nvl(in_webrf,0))
		where facility = in_facility and time_period = v_date;
	else
		insert into fac_usersessions (facility, time_period, crt, legacyrf, webrf, total)
		values (in_facility, v_date, nvl(in_crt,0), nvl(in_legacyrf,0), nvl(in_webrf,0), nvl(in_crt,0) + nvl(in_legacyrf,0) + nvl(in_webrf,0));
	end if;
exception	
	when others then	
		out_msg := 'Error: ' || sqlerrm(sqlcode);
end populate_fac_usersessions;

end zlicensereport;
/

show errors package body zlicensereport;
exit;