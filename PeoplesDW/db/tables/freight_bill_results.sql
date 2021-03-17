--
-- $Id: freight_bill_results.sql $
--

--drop table freight_bill_results cascade constraints;

create table freight_bill_results
(	orderseq				varchar2(12),
	loadno					number(7) not null,
	stopno					number(7) not null,
	tariff					varchar2(12),
	chargestype				varchar2(32),
	activitycode			varchar2(4) not null,
	freight_class			varchar2(12) not null,
	cwt_qty					number(12,2),
	rate					number(12,6),
	charges_by_class		number(10,2),
	gross_charges			number(10,2),
	discount_percent		number(4,2),
	discount_amount			number(10,2),
	net_charges				number(10,2),
	descr					varchar2(60),
	ratetype				varchar2(4),
	lastuser				varchar2(12),
	lastupdate				date
);

exit;


