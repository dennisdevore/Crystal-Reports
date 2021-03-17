--
-- Master list of Websynapse Order Columns. To add a column to the OrderSummary.js or 
-- InventorySummary.js tables, add an insert statement for it. see: sql/define-websynapse-columns.sql
--
create table ws_columns
(query_type varchar2(20) not null      -- "orders", "inventory", etc
,col_db_name varchar2(50) not null     -- The column name returned by the query
,col_user_descr varchar2(50)         -- The column name the user will see      
,col_order_num number not null       -- 'sql order by' on this to get default col order preference      
,col_type varchar2(20) not null      -- "number", "boolean", "string"
,hide_types varchar2(1)              -- "R", "O", or "" - used to hide the column by order type
,target_width number                 -- qooxdoo width property to use (default 60)
,disappear_order number              -- -1 (default), or 2,3, etc
,visible_by_default varchar2(1)      -- 'Y', 'N' - used when no user prefs are set
,lastuser varchar2(12)
,lastupdate date
);
create unique index ws_columns_idx 
	on ws_columns(query_type,col_db_name);
	
--
-- User's Websynapse Column preferences. OrderSummary.js/InventorySummary.js saves these as requested by user. 
--
create table ws_user_columns
(nameid varchar2(50) not null
,query_type varchar2(20) not null    -- joins to ws_columns.query_type
,query_subtype varchar2(20) not null -- for Orders, is order type
,col_order_num number not null       -- 'sql order by' on this to get user's col order preference      
,col_db_name varchar2(50) not null   -- joins to ws_columns.col_db_name
,col_visible varchar2(1)             -- 'Y' (visible), 'N' (hidden), per user 
,col_width number                    -- width of column at time of preferences save 
,lastuser varchar2(12)
,lastupdate date
);
create unique index ws_user_columns_idx 
	on ws_user_columns(nameid,query_type,query_subtype,col_order_num);
	
--
-- User's Websynapse Report Privileges, as assigned by their superuser. This list filters the 
-- Report List they see in ReportList.js. Basically this would be a subset of the applicationobjects
-- 'R' objecttypes. 
--
create table ws_user_reports
(nameid varchar2(50) not null
,report_name varchar2(255) not null    -- joins to applicationobjects.objectname
,lastuser varchar2(12)
,lastupdate date
);
create unique index ws_user_reports_idx 
	on ws_user_reports(nameid,report_name);
	
exit;
