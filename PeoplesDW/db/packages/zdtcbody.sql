create or replace package body alps.zdatecalcs
is
--
-- $Id$
--


function firstOfMonth(theDate date)
return date
is
begin
	return add_months(last_day(theDate),-1)+1;
end firstOfMonth;

function lastOfMonth(theDate date)
return date
is
begin
	return last_day(theDate);
end;


function firstOfYear(theDate date)
return date
is
begin
	return add_months(firstOfMonth(theDate), -1 * to_number(to_char(theDate,'MM')) + 1);
end firstOfYear;


function firstOfWeekSunToSat(theDate date)
return date
is
begin
	return trunc(theDate,'W');
end firstOfWeekSunToSat;


function firstOfWeekOneToSeven(theDate date)
return date
is
begin
	return theDate - mod(theDate - firstOfYear(theDate),7);
end firstOfWeekOneToSeven;

function lastOfWeekSunToSat(theDate date)
return date
is
begin
	return firstOfWeekSunToSat(theDate) + 6;
end;

end zdatecalcs;

/
show error package body zdatecalcs;
exit;

