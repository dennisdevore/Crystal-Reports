--
-- $Id$
--
create table custbolrptbyfield
(
  custid  varchar2(10) not null,
  bolrpt_field1  varchar2(30) not null,
  bolrpt_field2  varchar2(30),
  bolrpt_field1_value  varchar2(40) not null,
  bolrpt_field2_value  varchar2(40),
  bolrpt_format varchar2(255),
  mbolrpt_format varchar2(255),
  lastuser  varchar2(12),
  lastupdate  date,
  bolemail char(1),
  pdfbol char(1),
  vics_shipto_preference char(1),
  mastbolemail char(1),
  pdfmbol char(1)
);

create unique index custbolrptbyfield_unique on custbolrptbyfield(custid, bolrpt_field1, bolrpt_field2, bolrpt_field1_value, bolrpt_field2_value);

exit;