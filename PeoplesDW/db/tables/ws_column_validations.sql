create table ws_column_validations (
  validation_type varchar2(255),
  column_name varchar2(255),
  is_required varchar2(1) not null,
  primary key (validation_type, column_name)
);