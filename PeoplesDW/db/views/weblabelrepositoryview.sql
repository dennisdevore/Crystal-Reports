CREATE OR REPLACE VIEW WEBLABELREPOSITORYVIEW (
LANGUAGE, LABEL_ID, LABEL_TYPE_ID, LABEL_DISPLAY_ORDER, LABEL) as
select
'EN',
label_id,
label_type_id,
label_display_order,
en
from tbl_global_label_repository
union all
select
'FR',
label_id,
label_type_id,
label_display_order,
nvl(fr, 'nt - '||en)
from tbl_global_label_repository;

comment on table WEBLABELREPOSITORYVIEW is '$Id';

exit;

