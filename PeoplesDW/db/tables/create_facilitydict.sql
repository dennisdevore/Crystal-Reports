create table alps.facilitydict
(
	facility       varchar2(10) not null,
	fieldname      varchar2(36) not null,
	in_labelvalue  varchar2(36) not null,
	out_labelvalue varchar2(36) not null,
	lastuser       varchar2(12)     null,
	lastupdate     date             null
);
create unique index facilitydict_idx on facilitydict(facility,fieldname);

commit;

exit;
