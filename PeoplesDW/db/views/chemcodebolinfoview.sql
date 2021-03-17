create or replace view chemcodebolinfoview
(
    chemcode,
    bolinfo,
    dotbolcomment,
    iatabolcomment,
    imobolcomment,
    donotprintBOL,
    otherdescr,
    vicsbolinfo
)
as
select
    chemcode,
    propershippingname1
        || decode(nvl(propershippingname2,'<NONE>'),
                '<NONE>',null,chr(10)||propershippingname2)
        || chr(10) || chemicalconstituents ||', '
        || primaryhazardclass || ', '
        || decode(nvl(secondaryhazardclass,'NONE'), 'NONE',null,
             '('||secondaryhazardclass
           || decode(nvl(tertiaryhazardclass,'NONE'), 'NONE',null,
              ','||tertiaryhazardclass)
           ||'), ') 
        || packinggroup
        || decode(nvl(naergnumber,'NONE'), 'NONE',null,
             ', ' || naergnumber),
	dotbolcomment,
    	iatabolcomment,
    	imobolcomment,
	donotprintBOL,
    otherdescr,
    unnum
     || decode(nvl(unnum, 'NONE'), 'NONE', null,  ', ' || propershippingname1)
     || decode(nvl(propershippingname2, '<NONE>'), '<NONE>', null, propershippingname2)
     || decode(nvl(chemicalconstituents, '<NONE>'), '<NONE>', null, chemicalconstituents)
     || decode(nvl(primaryhazardclass, 'NONE'), 'NONE', null, ', ' || primaryhazardclass)
     || decode(nvl(packinggroup, 'NONE'), 'NONE', null,  ', ' || packinggroup)
     || decode(nvl(secondaryhazardclass, 'NONE'), 'NONE', null,  ', (' || secondaryhazardclass
              || decode(nvl (tertiaryhazardclass, 'NONE'), 'NONE', null, ',' || tertiaryhazardclass)
              || ')')
 from chemicalcodes;

comment on table chemcodebolinfoview is '$Id$';

exit;
