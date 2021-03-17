--
-- Table to hold the user's selected choices for the Order Item Mass Entry screen.  
--
create table ws_user_settings
(nameid varchar2(50) not null
,include_status varchar2(1)    
,include_class varchar2(1)    
,display_ic varchar2(1)    
,lastupdate date
);
	
exit;
