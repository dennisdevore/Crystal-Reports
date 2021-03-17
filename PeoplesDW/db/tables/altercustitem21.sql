--
-- $Id$
--
alter table custitem add(
      imoprimarychemcode    varchar2(12),
      imosecondarychemcode  varchar2(12),
      imotertiarychemcode   varchar2(12),
      imoquaternarychemcode  varchar2(12),
      iataprimarychemcode   varchar2(12),
      iatasecondarychemcode varchar2(12),
      iatatertiarychemcode  varchar2(12),
      iataquaternarychemcode varchar2(12)
);

-- exit;
