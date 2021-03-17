--
-- $Id$
--
set serveroutput on;
declare
out_reqtype varchar2(32);
out_msg varchar2(255);
out_facility varchar2(3);
out_userid varchar2(12);
out_orderid number(7);
out_shipid number(7);
out_item varchar2(36);
out_lotnumber varchar2(30);
out_qty number(10,2);
out_errorno number(7);
cnt integer;


begin

out_msg := '';

zgp.pick_request(
'GENLIP',     -- request type of "generate line-item pick" (required)
'HPL',        -- facility (required)
'BRIANB',     -- userid (required)
0,            -- wave (n/a)
48371,        -- orderid (required)
1,            -- shipid (required)
'C47#23A',    -- ordered item [not actual item] (required)
'10293829',   -- ordered lot [not actual lot] (required)
0,            -- quantity (n/a)
'2',          -- task priority (optional)
'',         -- pick type (n/a)
out_errorno,
out_msg);

        FilFindReturnStatus := FindFirst('*.*', faAnyFile, FilSearchRec);
        while FilFindReturnStatus = 0 do
        begin
          if ((FilSearchRec.attr and faHidden <> faHidden) and
              (FilSearchRec.attr and faReadOnly <> faReadOnly) and
              (FilSearchRec.name <> '.') and (FilSearchRec.name <> '..')) then
            DeleteFile(FilSearchRec.name);
          FilFindReturnStatus := FindNext(FilSearchRec);
        end;

end;
/
--exit;