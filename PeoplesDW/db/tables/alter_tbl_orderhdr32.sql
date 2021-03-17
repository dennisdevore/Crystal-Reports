alter table ORDERHDR add
(
  seal_verification_attempts  number(2),
  seal_verified               char(1)
);

exit;