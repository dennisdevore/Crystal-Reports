set serveroutput on;
declare
cnt_custid integer := 0;
cnt_converted integer := 0;
cvt_custid varchar2(10) := '660450';

begin
  for xx in (select rowid, custid, serialnumber, useritem1 from plate where custid = cvt_custid)
	loop
		cnt_custid := cnt_custid + 1;
		if (xx.useritem1 is null and xx.serialnumber is not null) then
			if (length(xx.serialnumber) < 21) then
				update plate 
					set useritem1 = xx.serialnumber,
						serialnumber = null,
						lastuser = 'SYNAPSE',
						lastupdate = sysdate
				where rowid = xx.rowid;
				cnt_converted := cnt_converted + 1;
			end if;
		end if;
	end loop;

  dbms_output.put_line('Total Plates for Custid ' || cvt_custid || ': ' || cnt_custid);
  dbms_output.put_line('Total Plates Converted: ' || cnt_converted);

end;
/

exit;
