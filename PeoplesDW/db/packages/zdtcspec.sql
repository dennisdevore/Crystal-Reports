--
-- $Id$
--

create or replace package alps.zdatecalcs
is


/*
Given a date returns the date of the first
day of the month, of the given date.
Example: Given 12/7/2002 returns 12/1/2002
*/

function firstOfMonth(
theDate date)
return date;

function lastOfMonth(
theDate date)
return date;


/*
Given a date returns 1/1 of the year of the given date.
Example: Given 12/7/2002 returns 1/1/2002
*/

function firstOfYear(
theDate date)
return date;


function firstOfWeekSunToSat(
theDate date)
return date;

function firstOfWeekOneToSeven(
theDate date)
return date;

function lastOfWeekSunToSat(
theDate date)
return date;

end zdatecalcs;
/
exit;
