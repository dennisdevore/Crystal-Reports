alter table waves add
(combined_wave char(1)
);
alter table orderhdr add
(original_wave_before_combine number(9)
);
exit;
