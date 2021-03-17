--
-- $Id$
--
drop table formatvalidationrule;

create table formatvalidationrule
(
	ruleid				varchar2(10) not null,
	descr 				varchar2(32),
	minlength			number(3),
	maxlength			number(3),
	datatype 			varchar2(1),
   mask              varchar2(30),
   lastuser          varchar2(12),
   lastupdate        date
);

exit;
