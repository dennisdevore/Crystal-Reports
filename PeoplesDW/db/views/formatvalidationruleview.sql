create or replace view formatvalidationruleview
(
   ruleid,
   descr,
   minlength,
   maxlength,
   mask,
   lastuser,
   lastupdate,
   datatype,
   datatypeabbrev,
   dupesok,
   mod10check
)
as
select
   formatvalidationrule.ruleid,
   formatvalidationrule.descr,
   formatvalidationrule.minlength,
   formatvalidationrule.maxlength,
   formatvalidationrule.mask,
   formatvalidationrule.lastuser,
   formatvalidationrule.lastupdate,
   formatvalidationrule.datatype,
   formatvalidationdatatypes.abbrev,
   formatvalidationrule.dupesok,
   formatvalidationrule.mod10check
   from formatvalidationrule, formatvalidationdatatypes
   where formatvalidationrule.datatype = formatvalidationdatatypes.code(+);
   
comment on table formatvalidationruleview is '$Id$';
   
exit;
