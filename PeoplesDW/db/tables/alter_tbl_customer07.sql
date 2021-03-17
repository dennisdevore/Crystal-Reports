--
-- $Id$
--
alter table customer add
(
	invbaserptfile varchar2(255),
	invmstrrptfile varchar2(255),
	invsummrptfile varchar2(255)
);

exit;
