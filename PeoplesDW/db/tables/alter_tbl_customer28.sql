--
-- $Id$
--
alter table customer add
(
   sendsmallpkgemail    char(1) default 'N',
   smallpkgbody         clob default empty_clob(),
   smallpkgfrom         varchar2(255),
   sendnonsmallpkgemail char(1) default 'N',
   nonsmallpkgbody      clob default empty_clob(),
   nonsmallpkgfrom      varchar2(255)
);

exit;
