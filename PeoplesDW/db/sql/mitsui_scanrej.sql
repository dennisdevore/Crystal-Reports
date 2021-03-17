--
-- $Id$
--
break on lp on tsk skip 1
select 'Deleted', D.lpid lp, D.lasttask tsk, H.whenoccurred, H.lasttask, H.quantity
	from ed_rejlps R, deletedplate D, platehistory H
	where D.lpid = R.lpid
     and H.lpid = D.lpid
union
select 'Exists', P.lpid lp, P.lasttask tsk, H.whenoccurred, H.lasttask, H.quantity
	from ed_rejlps R, plate P, platehistory H
   where P.lpid = R.lpid
     and H.lpid = P.lpid
order by 2, 4;
