set serveroutput on;

declare
l_totcount pls_integer := 0;
l_okycount pls_integer := 0;
l_ntfcount pls_integer := 0;
l_in_errcount pls_integer := 0;
l_out_errcount pls_integer := 0;
l_inpallets pls_integer := 0;
l_outpallets pls_integer := 0;
l_count pls_integer := 0;
l_updflag varchar2(1);
l_out_msg varchar2(255);

begin

l_updflag := upper('&&1');

zut.prt('Comparing history rows to cust_sum rows...');

for ph in (select custid,
                  facility,
                  pallettype,
                  trunc(lastupdate) as trunc_lastupdate,
                  sum(nvl(inpallets,0)) as inpallets,
                  sum(nvl(outpallets,0)) as outpallets
             from pallethistory
            group by custid,facility,pallettype,trunc(lastupdate))
loop

  l_totcount := l_totcount + 1;
  
  begin
    select inpallets, outpallets
      into l_inpallets, l_outpallets
      from pallethistory_sum_cust
     where custid = ph.custid
       and facility = ph.facility
       and pallettype = ph.pallettype
       and trunc_lastupdate = ph.trunc_lastupdate;
  exception when no_data_found then
    l_inpallets := null;
  end;
  
  if l_inpallets is null then
    l_ntfcount := l_ntfcount + 1;
    zut.prt(ph.custid || '/' ||
            ph.facility || '/' ||
            ph.trunc_lastupdate || '/' ||
            ph.inpallets || '/' ||
            ph.outpallets || ' not found in sum_cust');
    if l_updflag = 'Y' then         
      insert into pallethistory_sum_cust
        (custid, facility, pallettype, trunc_lastupdate, inpallets, outpallets)
        values
        (ph.custid, ph.facility, ph.pallettype, ph.trunc_lastupdate,
         ph.inpallets, ph.outpallets);
      commit;
    end if;
  elsif (l_inpallets != ph.inpallets) or
        (l_outpallets != ph.outpallets) then
    if (l_inpallets != ph.inpallets) then
      l_in_errcount := l_in_errcount + 1;
      zut.prt(ph.custid || '/' ||
              ph.facility || '/' ||
              ph.trunc_lastupdate || '/history in ' ||
              ph.inpallets || '/sum_cust in ' ||
              l_inpallets);
    end if;
    if (l_outpallets != ph.outpallets) then
      l_out_errcount := l_out_errcount + 1;
      zut.prt(ph.custid || '/' ||
              ph.facility || '/' ||
              ph.trunc_lastupdate || '/history out ' ||
              ph.outpallets || '/sum_cust out ' ||
              l_outpallets);
    end if;
    if l_updflag = 'Y' then
      update pallethistory_sum_cust
         set inpallets = ph.inpallets,
             outpallets = ph.outpallets
       where custid = ph.custid
         and facility = ph.facility
         and pallettype = ph.pallettype
         and trunc_lastupdate = ph.trunc_lastupdate;
      commit;
    end if;
  else
    l_okycount := l_okycount + 1;
  end if;
  
end loop;
             
zut.prt('totcount: ' || l_totcount);
zut.prt('okycount: ' || l_okycount);
zut.prt('ntfcount: ' || l_ntfcount);
zut.prt('in_errcount: ' || l_in_errcount);
zut.prt('out_errcount: ' || l_out_errcount);

zut.prt('Comparing cust_sum to history rows...');

l_totcount := 0;
l_okycount := 0;
l_ntfcount := 0;
l_in_errcount := 0;
l_out_errcount := 0;

for sc in (select custid,
                  facility,
                  pallettype,
                  trunc_lastupdate,
                  inpallets,
                  outpallets
             from pallethistory_sum_cust)
loop

  l_totcount := l_totcount + 1;

  l_inpallets := 0;
  l_outpallets := 0;
  l_count := 0;
  
  select sum(nvl(inpallets,0)), sum(nvl(outpallets,0)), count(1)
    into l_inpallets, l_outpallets, l_count
    from pallethistory
   where custid = sc.custid
     and facility = sc.facility
     and pallettype = sc.pallettype
     and trunc(lastupdate) = sc.trunc_lastupdate;
 
  if (l_count = 0) then
    zut.prt(sc.custid || '/' ||
            sc.facility || '/' ||
            sc.trunc_lastupdate || '/' ||
            sc.inpallets || '/' ||
            sc.outpallets || ' no pallethistory found');
    if l_updflag = 'Y' then
      delete
        from pallethistory_sum_cust
       where custid = sc.custid
         and facility = sc.facility
         and trunc_lastupdate = sc.trunc_lastupdate;
    end if;         
  elsif (l_inpallets != sc.inpallets) or
        (l_outpallets != sc.outpallets) then
    if (l_inpallets != sc.inpallets) then
      l_in_errcount := l_in_errcount + 1;
      zut.prt(sc.custid || '/' ||
              sc.facility || '/' ||
              sc.trunc_lastupdate || '/sum_cust in ' ||
              sc.inpallets || '/history in ' ||
              l_inpallets);
    end if;
    if (l_outpallets != sc.outpallets) then
      l_out_errcount := l_out_errcount + 1;
      zut.prt(sc.custid || '/' ||
              sc.facility || '/' ||
              sc.trunc_lastupdate || '/sum_cust out ' ||
              sc.outpallets || '/history out ' ||
              l_outpallets);
    end if;
    if l_updflag = 'Y' then
      update pallethistory_sum_cust
         set inpallets = l_inpallets,
             outpallets = l_outpallets
       where custid = sc.custid
         and facility = sc.facility
         and pallettype = sc.pallettype
         and trunc_lastupdate = sc.trunc_lastupdate;
      commit;
    end if;
  else
    l_okycount := l_okycount + 1;
  end if;
  
end loop;
             
zut.prt('totcount: ' || l_totcount);
zut.prt('okycount: ' || l_okycount);
zut.prt('ntfcount: ' || l_ntfcount);
zut.prt('in_errcount: ' || l_in_errcount);
zut.prt('out_errcount: ' || l_out_errcount);

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
