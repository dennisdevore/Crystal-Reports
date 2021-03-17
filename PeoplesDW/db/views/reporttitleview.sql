
CREATE OR REPLACE VIEW REPORTTITLEVIEW ( REPORTTITLE,
TRUELINK ) AS
select defaultvalue as reporttitle, 1 as truelink
	from systemdefaults
where defaultid = 'REPORTTITLE';

comment on table REPORTTITLEVIEW is '$Id$';

exit;
