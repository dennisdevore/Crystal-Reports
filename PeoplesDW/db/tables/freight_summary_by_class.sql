--
-- $Id: freight_summary_by_class.sql $
--

--drop table freight_summary_by_class cascade constraints;

create table freight_summary_by_class
(	loadno			number(7) not null,
	stopno			number(7) not null,
	tariff			varchar2(12),
	freight_class	varchar2(12) not null,
	cwt_qty			number(12,2), 
	lastuser		varchar2(12),
	lastupdate		date
);

exit;
