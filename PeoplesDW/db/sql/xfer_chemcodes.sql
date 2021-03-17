--
-- $Id$
--
insert into chemicalcodes
   (chemcode, abbrev, propershippingname1, propershippingname2,
    chemicalconstituents, primaryhazardclass, secondaryhazardclass,
    tertiaryhazardclass, naergnumber, dotbolcomment, iatabolcomment,
    imobolcomment, otherdescr, unnum, packinggroup, donotprintbol,
    lastuser, lastupdate)
select
   chemcode, abbrev, descr, propershippingname,
   chemicalconstituents, primaryhazardclass, secondaryhazardclass,
   tertiaryhazardclass, naergnumber, dotbolcomment, iatabolcomment,
   imobolcomment, null, unnum, packinggroup, null,
   lastuser, lastupdate from chemicalcodes_old;
