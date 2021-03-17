create or replace package whutilizationrptpkg as
	function location_footprint
		(in_facility IN varchar2
		,in_location IN varchar2)
  return number;
	function location_hazmat
		(in_facility IN varchar2
		,in_location IN varchar2)
  return varchar2;
	function location_tempcontrolled
		(in_facility IN varchar2
		,in_location IN varchar2)
  return varchar2;
end whutilizationrptpkg;
/

create or replace package body whutilizationrptpkg as
--
-- $Id:$
--

function location_footprint
	(in_facility IN varchar2
	,in_location IN varchar2)
return number
is
  cursor curLocation is
  select lo.unitofstorage,
         lo.putawayzone,
         nvl(lo.status,'E') status,
         nvl(lo.weightlimit,nvl(uos.weightlimit,0)) weightlimit,
         nvl((uos.depth*uos.width*uos.height)/1728,0) cubelimit,
         nvl(lo.stackheight,0) stackheight,
         nvl(uos.stdpallets,0) stdpallets,
         nvl(lo.lpcount,0) lpcount
    from location lo, unitofstorage uos
   where lo.facility = in_facility
     and lo.locid = in_location
     and lo.unitofstorage = uos.unitofstorage(+);
  lo curLocation%rowtype;

  cursor curFitMethod(in_zone IN varchar2) is
  select distinct (nvl(fitmethod,'U')) fitmethod
    from (select /*+ INDEX (putawayprofline putawayprofline_idx)*/
                 distinct fitmethod,
                 zoneid
            from putawayprofline
           where facility = in_facility
             and (profid,uom) in
            (select /*+ INDEX (plate plate_location)*/
                    substr (zcf.profid (in_facility, custid, item), 1, 2) profid,
                    unitofmeasure
               from plate
              where facility = in_facility
                and location = in_location))
   where zoneid = 'ANY ZONE!'
      or zoneid = in_zone
      or in_zone is null;
  fm curFitMethod%rowtype;

  cursor curItems is
  select distinct custid, item, unitofmeasure
    from plate pl
   where pl.facility = in_facility
     and pl.location = in_location
     and type = 'PA'
     and item is not null
     and unitofmeasure is not null;
  cit curItems%rowtype;

  l_count integer;
  l_fitmethod char(1);
  l_footprint integer;
  l_palhere integer;
  l_weighthere integer;
  l_cubehere integer;
  l_palcoming integer;
  l_weightcoming integer;
  l_cubecoming integer;
  
  l_uomsinuos number;
  l_uosused number;
  l_err varchar2(1);
  l_msg varchar2(80);
  
begin
  l_footprint := 100.0;

  open curLocation;
  fetch curLocation into lo;
  close curLocation;
  
  if (lo.status = 'E') or (lo.lpcount = 0) then
    return 0.0;
  end if;
  
  l_fitmethod := 'U';
  l_count := 0;
  for fm in curFitMethod(lo.putawayzone)
  loop
    l_fitmethod := fm.fitmethod;
    l_count := l_count + 1;
  end loop;

  if l_count > 1 then
    l_fitmethod := 'U';
  end if;
  
  if (l_fitmethod in ('S','P','H','C','W','B')) then
    select count(lpid),
           sum(weight),
           sum(quantity * zci.item_cube(custid, item, unitofmeasure))
      into l_palhere,
           l_weighthere,
           l_cubehere
      from plate
     where facility = in_facility
       and location = in_location
       and parentlpid is null;
  
    select count(lpid),
           sum(weight),
           sum(quantity * zci.item_cube(custid, item, unitofmeasure))
      into l_palcoming,
           l_weightcoming,
           l_cubecoming
      from plate
     where destfacility = in_facility
       and destlocation = in_location
       and parentlpid is null;
    
    if (l_fitmethod in ('S','P','H')) and (lo.stdpallets > 0) then
      if (lo.stackheight > 0) and (l_fitmethod = 'H') then
        l_footprint := 100 * (l_palhere + l_palcoming) / (lo.stdpallets * lo.stackheight);
      else
        l_footprint := 100 * (l_palhere + l_palcoming) / lo.stdpallets;
      end if;
    elsif (l_fitmethod = 'C') and (lo.cubelimit > 0) then
      l_footprint := 100 * (l_cubehere + l_cubecoming) / lo.cubelimit;
    elsif (l_fitmethod = 'W') and (lo.weightlimit > 0) then
      l_footprint := 100 * (l_weighthere + l_weightcoming) / lo.weightlimit;
    elsif (l_fitmethod = 'B') and (lo.cubelimit > 0) and (lo.weightlimit > 0) then
      if ((l_cubehere + l_cubecoming) / lo.cubelimit) >= ((l_weighthere + l_weightcoming) / lo.weightlimit) then
        l_footprint := 100 * (l_cubehere + l_cubecoming) / lo.cubelimit;
      else
        l_footprint := 100 * (l_weighthere + l_weightcoming) / lo.weightlimit;
      end if;
    end if;
  else
    l_count := 0;
    for cit in curItems
    loop
      l_uomsinuos := 0;
      l_err := '';
      l_msg := '';
      
      zput.get_uoms_in_uos(cit.custid, cit.item, cit.unitofmeasure, lo.unitofstorage,
        l_uomsinuos, l_err, l_msg);
        
      if (l_err != 'N') then
        return 100.0;
      end if;

      l_uosused := 0;
      l_err := '';
      l_msg := '';
      
      zput.get_used_uos(in_facility, in_location, lo.unitofstorage, null,
        l_uosused, l_err, l_msg);

      if (l_err != 'N') then
        return 100.0;
      end if;

      if (l_uomsinuos > 0) then
        l_footprint := (l_uosused / l_uomsinuos) * 100.0;
      end if;
      
      l_count := l_count + 1;
    end loop;

    if l_count > 1 then
      l_footprint := 100.0;
    end if;
  end if;

  if l_footprint >= 100.0 then
    l_footprint := 100.0;
  end if;
  
  return l_footprint;
exception when others then
  return 100.0;
end location_footprint;

function location_hazmat
	(in_facility IN varchar2
	,in_location IN varchar2)
return varchar2
is
  l_count integer;
begin
  l_count := 0;
  
  select count(1)
    into l_count
    from plate pl
   where pl.facility = in_facility
     and pl.location = in_location
     and exists(
       select 1
         from custitemview ci
        where ci.custid = pl.custid
          and ci.item = pl.item
          and nvl(ci.hazardous,'N') = 'Y');
  
  if l_count = 0 then
    return 'N';
  else
    return 'Y';
  end if;
exception when others then
  return 'N';
end location_hazmat;

function location_tempcontrolled
	(in_facility IN varchar2
	,in_location IN varchar2)
return varchar2
is
  l_count integer;
begin
  l_count := 0;
  
  select count(1)
    into l_count
    from plate pl
   where pl.facility = in_facility
     and pl.location = in_location
     and exists(
       select 1
         from customer_aux ca
        where ca.custid = pl.custid
          and nvl(ca.trackoutboundtemps,'N') = 'Y');
  
  if l_count = 0 then
    return 'N';
  else
    return 'Y';
  end if;
exception when others then
  return 'N';
end location_tempcontrolled;

end whutilizationrptpkg;
/

show errors package whutilizationrptpkg;
show errors package body whutilizationrptpkg;
exit;
