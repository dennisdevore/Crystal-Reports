CREATE OR REPLACE FUNCTION STRLPID (in_lpid varchar2)
return varchar2 is
strLpid varchar2(15);
intLength integer;
begin
strLpid := substr(upper(ltrim(rtrim(in_lpid))),1,15);
if strLpid is null then
  intLength := 0;
else
  intLength := Length(strLpid);
end if;
if intLength < 15 then
  strLpid := substr('000000000000000',1,15-intLength) || strLpid;
end if;
return strLpid;
exception when others then
  return in_lpid;
end strlpid;
/
exit;
