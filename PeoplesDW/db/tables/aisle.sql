--
-- $Id$
--
create table aisle (
	facility			varchar2(3) not null,
	aisleid        varchar2(5) not null,
	aislen         varchar2(5),
	aislene        varchar2(5),
	aislee         varchar2(5),
	aislese        varchar2(5),
	aisles         varchar2(5),
	aislesw        varchar2(5),
	aislew         varchar2(5),
	aislenw        varchar2(5),
	lastuser       varchar2(12),
	lastupdate     date
);
exit;
