drop table zinvsumrpt;

create table zinvsumrpt (
   sessionid      number,
   item           varchar2(50),
   descr          varchar2(255),
   baseuom        varchar2(4),
   weight         number(17,8),
   cube           number(10,4),
   lotnumber      varchar2(30),
   qtyavailable   number(16),
   qtycommitted   number(16),
   qtydamaged     number(16),
   qtyhold        number(16),
   qtyinprocess   number(16),
   qtyqchold      number(16),
   qtyexpired     number(16),
   qtyinspection  number(16),
   qtymandefect   number(16),
   qtyqahold      number(16),
   qtyholdrepair  number(16),
   qtyaspense     number(16),
   qtyspecial     number(16),
   qtysuspense    number(16),
   qtyunavailable number(16),
   qtytotal       number(16),
   cubetotal      number(16,4),
   weighttotal    number(20,8),
   lastupdate     date
);

create index zinvsumrpt_sessionid_idx
   on zinvsumrpt(sessionid);

create index zinvsumrpt_lastupdate_idx
   on zinvsumrpt(lastupdate);


create or replace package zinvsumrptpkg
   as type isr_type is ref cursor return zinvsumrpt%rowtype;
end zinvsumrptpkg;
/


create or replace procedure zinvsumrptproc2
   (isr_cursor in out zinvsumrptpkg.isr_type,
    in_custid in varchar2,
    in_facility in varchar2,
    in_qchold in varchar2)
is
--
-- $Id$
--
  cursor c_inv is
    select ci.item,
           ci.descr,
           ci.baseuom,
           ci.cube,
           ci.weight,
           cit.invstatus,
           cit.status,
           cit.lotnumber,
           nvl(cit.qty,0) as quantity
      from custitem ci, custitemtotview cit
     where ci.custid=in_custid
       and ci.custid=cit.custid
       and ci.item=cit.item
       and instr(','||in_facility||',',','||cit.facility||',',1,1) > 0
       and cit.status not in ('D', 'P')
       and cit.qty<>0;

  l_sessionid number;
  l_count number;
  l_qtyavailable number;
  l_qtycommitted number;
  l_qtydamaged number;
  l_qtyhold number;
  l_qtyinprocess number;
  l_qtyqchold number;
  l_qtyexpired number;
  l_qtyinspection number;
  l_qtymandefect number;
  l_qtyqahold number;
  l_qtyholdrepair number;
  l_qtyaspense number;
  l_qtyspecial number;
  l_qtysuspense number;
  l_qtyunavailable number;
  
begin
  select sys_context('USERENV','SESSIONID')
    into l_sessionid
    from dual;

  delete from zinvsumrpt
   where sessionid = l_sessionid;
  commit;

  delete from zinvsumrpt
   where lastupdate < trunc(sysdate);
  commit;

  for c in c_inv loop
    l_qtyavailable := 0;
    l_qtycommitted := 0;
    l_qtydamaged := 0;
    l_qtyhold := 0;
    l_qtyinprocess := 0;
    l_qtyqchold := 0;
    l_qtyexpired := 0;
    l_qtyinspection := 0;
    l_qtymandefect := 0;
    l_qtyqahold := 0;
    l_qtyholdrepair := 0;
    l_qtyaspense := 0;
    l_qtyspecial := 0;
    l_qtysuspense := 0;
    l_qtyunavailable := 0;
    
    if (((c.invstatus = 'AV' or (in_qchold <> 'Y' and c.invstatus = 'SU')) and (c.status = 'A' or (in_qchold = 'Y' and c.status = 'CM')))) then
    	l_qtyavailable := c.quantity;
    end if;
    
    if (in_qchold <> 'Y') and ((c.invstatus = 'AV' and (c.status <> 'A' and c.status <> 'U')) or c.invstatus = 'CM' or c.status = 'PN' or c.status = 'CM') then
    	  l_qtycommitted := c.quantity;
    end if;
    
    if ((in_qchold = 'Y') and ((c.status <> 'A' and c.status <> 'U') or c.invstatus = 'CM')) then
      if (c.quantity >= 0) then
    	  l_qtycommitted := c.quantity;
    	else
    	  l_qtycommitted := c.quantity * -1;
      end if;
    end if;
    
    if (c.invstatus  = 'DM' and (c.status = 'A' or (in_qchold = 'Y' and c.status = 'CM'))) then
    	l_qtydamaged := c.quantity;
    end if;
    
    if (c.invstatus  = 'OH' and (c.status = 'A' or (in_qchold = 'Y' and c.status = 'CM'))) then
    	l_qtyhold := c.quantity;
    end if;
    
    if (c.invstatus  = 'AV'  and c.status = 'U') then
    	l_qtyinprocess := c.quantity;
    end if;
    
    if (in_qchold = 'Y') then
      if (c.invstatus  = 'EX' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyexpired := c.quantity;
      end if;

      if (c.invstatus  = 'IN' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyinspection := c.quantity;
      end if;

      if (c.invstatus  = 'MD' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtymandefect := c.quantity;
      end if;

      if (c.invstatus  = 'QA' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyqahold := c.quantity;
      end if;

      if (c.invstatus  = 'QC' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyqchold := c.quantity;
      end if;

      if (c.invstatus  = 'RP' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyholdrepair := c.quantity;
      end if;

      if (c.invstatus  = 'SE' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyaspense := c.quantity;
      end if;

      if (c.invstatus  = 'SP' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyspecial := c.quantity;
      end if;

      if (c.invstatus  = 'SU' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtysuspense := c.quantity;
      end if;

      if (c.invstatus  = 'UN' and (c.status = 'A' or c.status = 'CM')) then
    	  l_qtyunavailable := c.quantity;
      end if;
    end if;
    
    select count(1)
      into l_count
      from zinvsumrpt
     where sessionid = l_sessionid
       and item = c.item
       and nvl(lotnumber,'(none)') = nvl(c.lotnumber,'(none)');
       
    if (l_count = 0) then
    	insert into zinvsumrpt values(l_sessionid, c.item, c.descr, c.baseuom,
    	  c.weight, c.cube, c.lotnumber, l_qtyavailable, l_qtycommitted,
    	  l_qtydamaged, l_qtyhold, l_qtyinprocess, l_qtyqchold, l_qtyexpired,
    	  l_qtyinspection, l_qtymandefect, l_qtyqahold, l_qtyholdrepair,
    	  l_qtyaspense, l_qtyspecial, l_qtysuspense, l_qtyunavailable, 0, 0.0,
    	  0.0, sysdate);
    else
    	update zinvsumrpt
    	   set qtyavailable = qtyavailable + l_qtyavailable,
    	       qtycommitted = qtycommitted + l_qtycommitted,
    	       qtydamaged = qtydamaged + l_qtydamaged,
    	       qtyhold = qtyhold + l_qtyhold,
    	       qtyinprocess = qtyinprocess + l_qtyinprocess,
    	       qtyqchold = qtyqchold + l_qtyqchold,
    	       qtyexpired = qtyexpired + l_qtyexpired,
    	       qtyinspection = qtyinspection + l_qtyinspection,
    	       qtymandefect = qtymandefect + l_qtymandefect,
    	       qtyqahold = qtyqahold + l_qtyqahold,
    	       qtyholdrepair = qtyholdrepair + l_qtyholdrepair,
    	       qtyaspense = qtyaspense + l_qtyaspense,
    	       qtyspecial = qtyspecial + l_qtyspecial,
    	       qtysuspense = qtysuspense + l_qtysuspense,
    	       qtyunavailable = qtyunavailable + l_qtyunavailable
    	 where sessionid = l_sessionid
         and item = c.item
         and nvl(lotnumber,'(none)') = nvl(c.lotnumber,'(none)');
    end if;
  end loop;
  commit;
  
  update zinvsumrpt
     set qtyavailable = 0
   where sessionid = l_sessionid
     and qtyavailable < 0;
  commit;

  update zinvsumrpt
     set qtytotal = qtyavailable + qtycommitted + qtydamaged + qtyhold + qtyinprocess + qtyqchold +
           qtyexpired + qtyinspection + qtymandefect + qtyqahold + qtyholdrepair + qtyaspense +
           qtyspecial + qtysuspense + qtyunavailable,
         weighttotal = (qtyavailable + qtycommitted + qtydamaged + qtyhold + qtyinprocess + qtyqchold +
           qtyexpired + qtyinspection + qtymandefect + qtyqahold + qtyholdrepair + qtyaspense +
           qtyspecial + qtysuspense + qtyunavailable) * weight,
         cubetotal = (qtyavailable + qtycommitted + qtydamaged + qtyhold + qtyinprocess + qtyqchold +
           qtyexpired + qtyinspection + qtymandefect + qtyqahold + qtyholdrepair + qtyaspense +
           qtyspecial + qtysuspense + qtyunavailable) * cube / 1728
   where sessionid = l_sessionid;
  commit;

  open isr_cursor for
     select *
        from zinvsumrpt
        where sessionid = l_sessionid
        order by item, lotnumber;

end zinvsumrptproc2;
/

create or replace procedure zinvsumrptproc
   (isr_cursor in out zinvsumrptpkg.isr_type,
    in_custid in varchar2,
    in_facility in varchar2)
as
begin
	zinvsumrptproc2(isr_cursor, in_custid, in_facility, 'N');
end zinvsumrptproc;
/

create or replace procedure zinvsumfacrptproc
(isr_cursor in out zinvsumrptpkg.isr_type,
 in_custid in varchar2,
 in_fac in varchar2)
as
begin
	zinvsumrptproc2(isr_cursor, in_custid, in_fac, 'Y');
end zinvsumfacrptproc;
/

create or replace procedure zinvsumfacilityrptproc
(isr_cursor in out zinvsumrptpkg.isr_type,
 in_custid in varchar2,
 in_facility in varchar2)
as
begin
	zinvsumrptproc2(isr_cursor, in_custid, in_facility, 'Y');
end zinvsumfacilityrptproc;
/

show errors package zinvsumrptpkg;
show errors procedure zinvsumrptproc;
show errors procedure zinvsumfacrptproc;
show errors procedure zinvsumfacilityrptproc;
exit;
