--
-- $Id$
--

alter table customer_aux add
(bbb_generate_p_and_c_waves_by char(1)  -- 'L'oad; 'S'hip-to
);

update customer_aux
set bbb_generate_p_and_c_waves_by = 'L'
where bbb_generate_p_and_c_waves_by is null;

commit;
exit;
