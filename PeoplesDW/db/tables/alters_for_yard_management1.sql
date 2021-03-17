--
-- $Id  alters_for_yard_management.sql 466 2005-12-13 16:09:52Z ed $
--

alter table carrier add
(
default_trailer_type varchar2(3),
default_trailer_style varchar2(3)
);

/* no longer used
alter table facility add
(
facility_type varchar2(4)
);

update facility
   set facility_type = 'DC'
 where facility_type is null;

create table facility_types
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_facility_types
   primary key(code)
);

insert into tabledefs
   values('Facility_Types', 'N', 'N', '>Cccc;0;_', 'SYNAPSE', sysdate);

insert into facility_types
   values('DC', 'Distribution Center', 'Dist Center', 'N', 'SYNAPSE', sysdate);

insert into facility_types
   values('YARD', 'Yard', 'Yard', 'N', 'SYNAPSE', sysdate);

commit;
*/

create table trailer_activity_types
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_trailer_activity_types
   primary key(code)
);

insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('ADC', 'Arrived at DC', 'ArriveDC', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('ADD', 'Trailer record added', 'Add', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('ATI', 'Assigned To Inbound Load', 'AssignToIn', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('ATO', 'Assigned To Outbound Load', 'AssignToOut', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('DFL', 'Deassign from Load', 'Deassign', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('EPT', 'Empty Trailer', 'Empty', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('IN', 'Arrived In Yard', 'Gate In', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('LDN', 'Trailer Loading', 'Loading', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('LFA', 'Late for Arrival', 'Late', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('LFF', 'Left Facility', 'Left Fac', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('LOD', 'Trailer Loaded', 'Loaded', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('MVD', 'Moved to another yard location', 'Moved', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('OUT', 'Trailer Out', 'Gate Out', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('REL', 'Release Trailer', 'Released', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('UDC', 'Unarrived at DC', 'UnarriveDC', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('UET', 'Un-Empty Trailer', 'Unempty', 'N', 'SYNAPSE', sysdate);
insert into trailer_activity_types (code, descr, abbrev, dtlupdate, lastuser, lastupdate) values
('UPD', 'Trailer record updated', 'Update', 'N', 'SYNAPSE', sysdate);

commit;

create table trailer_status
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_trailer_status
   primary key(code)
);

insert into tabledefs
   values('Trailer_Status', 'N', 'N', '>Aaa;0;_', 'SYNAPSE', sysdate);

insert into trailer_status
   values('OK', 'Okay', 'Okay', 'N', 'SYNAPSE', sysdate);

insert into trailer_status
   values('LFA', 'Late for Appointment', 'Late', 'N', 'SYNAPSE', sysdate);

commit;

create table contents_status
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_contents_status
   primary key(code)
);

insert into tabledefs
   values('Contents_Status', 'N', 'N', '>Aaa;0;_', 'SYNAPSE', sysdate);

insert into contents_status
   values('E', 'Empty', 'Empty', 'N', 'SYNAPSE', sysdate);

insert into contents_status
   values('H', 'Has Stock', 'Has Stock', 'N', 'SYNAPSE', sysdate);

commit;

create table trailer_types
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_trailer_types
   primary key(code)
);

insert into tabledefs
   values('Trailer_Types', 'N', 'Y', '>Aaa;0;_', 'SYNAPSE', sysdate);

insert into trailer_types
   values('45', '45 foot Van', '45 footer', 'N', 'SYNAPSE', sysdate);

commit;

create table trailer_styles
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_trailer_styles
   primary key(code)
);

insert into tabledefs
   values('Trailer_Styles', 'N', 'Y', '>Aaa;0;_', 'SYNAPSE', sysdate);

insert into trailer_styles
   values('VAN', 'Van', 'Van', 'N', 'SYNAPSE', sysdate);

insert into trailer_styles
   values('???', 'Unknown', 'Unknown', 'N', 'SYNAPSE', sysdate);

commit;

create table trailer_dispositions
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date,
   constraint  pk_trailer_dispositions
   primary key(code)
);

insert into tabledefs
   values('Trailer_Dispositions', 'N', 'Y', '>Aaa;0;_', 'SYNAPSE', sysdate);

insert into trailer_dispositions
   values('INY', 'In Yard', 'In Yard', 'N', 'SYNAPSE', sysdate);

insert into trailer_dispositions
   values('INT', 'In Transit', 'In Transit', 'N', 'SYNAPSE', sysdate);

insert into trailer_dispositions
   values('SHP', 'Shipped', 'Shipped', 'N', 'SYNAPSE', sysdate);

insert into trailer_dispositions
   values('DC', 'At Distribution Center', 'At DC', 'N', 'SYNAPSE', sysdate);

commit;

create table facilities_for_yard
(yard_facility varchar2(3) not null
,dc_facility   varchar2(3) not null
,lastuser      varchar2(12) not null
,lastupdate    date not null
,constraint    pk_facilities_for_yard
 primary key (yard_facility,dc_facility)
);

create index facilities_for_yard_dc_idx on
  facilities_for_yard(dc_facility);

create table trailer
(trailer_number varchar2(12) not null
,trailer_lpid varchar2(15)
,facility varchar2(3)
,location varchar2(10)
,carrier varchar2(4) not null
,contents_status varchar2(1)
,trailer_status varchar2(3)
,loadno number(9)
,style varchar2(3)
,trailer_type varchar2(3)
,disposition varchar2(3)
,activity_type varchar2(3)
,expected_time_in date
,gate_time_in date
,expected_time_out date
,gate_time_out date
,put_on_water date
,eta_to_port date
,arrived_at_port date
,last_free_date date
,carrier_contact_date date
,arrived_in_yard date
,appointment_date date
,due_back date
,returned_to_port date
,lastuser varchar2(12)
,lastupdate date
,constraint pk_trailer
 primary key(trailer_number)
);

create index trailer_trailer_status_idx on trailer(trailer_status);
create index trailer_disposition_idx on trailer(disposition);
create index trailer_location_idx on trailer(facility,location);
create index trailer_loadno_idx on trailer(loadno);
create unique index trailer_lpid_idx on trailer(trailer_lpid);

create table trailer_history
(trailer_number varchar2(12)
,activity_time timestamp
,activity_type varchar2(3)
,trailer_lpid varchar2(15)
,facility varchar2(3)
,location varchar2(10)
,carrier varchar2(4)
,contents_status varchar2(1)
,trailer_status varchar2(3)
,loadno number(9)
,style varchar2(3)
,trailer_type varchar2(3)
,disposition varchar2(3)
,expected_time_in date
,gate_time_in date
,expected_time_out date
,gate_time_out date
,put_on_water date
,eta_to_port date
,arrived_at_port date
,last_free_date date
,carrier_contact_date date
,arrived_in_yard date
,appointment_date date
,due_back date
,returned_to_port date
,lastuser varchar2(12)
,lastupdate date
,constraint pk_trailer_history
 primary key(trailer_number, activity_time, activity_type)
);

create table trailer_notes
(trailer_number varchar2(12)
,note_added timestamp
,trailer_note clob
,lastuser varchar2(12)
,lastupdate date
,constraint pk_trailer_notes
 primary key(trailer_number, note_added, lastuser)
);

insert into applicationobjects values('TrailerForm','F','YARD','SYNAPSE',sysdate);

insert into systemdefaults
values ('TRAILERLOOKUPDATE1','EXPECTED_TIME_IN', 'SYNAPSE', sysdate);
insert into systemdefaults
values ('TRAILERLOOKUPDATE2','GATE_TIME_IN', 'SYNAPSE', sysdate);
insert into systemdefaults
values ('TRAILERLOOKUPDATE3','EXPECTED_TIME_OUT', 'SYNAPSE', sysdate);
insert into systemdefaults
values ('TRAILERLOOKUPDATE4','GATE_TIME_OUT', 'SYNAPSE', sysdate);

commit;

exit;

