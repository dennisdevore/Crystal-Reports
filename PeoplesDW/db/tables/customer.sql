--
-- $Id$
--
drop table customer;

create table customer (
CUSTID                                   VARCHAR2(10) not null
,NAME                                     VARCHAR2(40) not null
,LOOKUP                                   VARCHAR2(40)
,CONTACT                                  VARCHAR2(40)
,ADDR1                                    VARCHAR2(40)
,ADDR2                                    VARCHAR2(40)
,CITY                                     VARCHAR2(30)
,STATE                                    VARCHAR2(2)
,POSTALCODE                               VARCHAR2(12)
,COUNTRYCODE                              VARCHAR2(3)
,PHONE                                    VARCHAR2(15)
,FAX                                      VARCHAR2(15)
,EMAIL                                    VARCHAR2(255)
,RNEWNAME                                 VARCHAR2(40)
,RNEWCONTACT                              VARCHAR2(40)
,RNEWADDR1                                VARCHAR2(40)
,RNEWADDR2                                VARCHAR2(40)
,RNEWCITY                                 VARCHAR2(30)
,RNEWSTATE                                VARCHAR2(2)
,RNEWPOSTALCODE                           VARCHAR2(12)
,RNEWCOUNTRYCODE                          VARCHAR2(3)
,RNEWPHONE                                VARCHAR2(15)
,RNEWFAX                                  VARCHAR2(15)
,RNEWEMAIL                                VARCHAR2(255)
,RNEWBILLTYPE                             VARCHAR2(1)
,RNEWBILLFREQ                             VARCHAR2(1)
,RNEWBILLDAY                              NUMBER(2)
,RNEWAUTOBILL                             VARCHAR2(1)
,RCPTNAME                                 VARCHAR2(40)
,RCPTCONTACT                              VARCHAR2(40)
,RCPTADDR1                                VARCHAR2(40)
,RCPTADDR2                                VARCHAR2(40)
,RCPTCITY                                 VARCHAR2(30)
,RCPTSTATE                                VARCHAR2(2)
,RCPTPOSTALCODE                           VARCHAR2(12)
,RCPTCOUNTRYCODE                          VARCHAR2(3)
,RCPTPHONE                                VARCHAR2(15)
,RCPTFAX                                  VARCHAR2(15)
,RCPTEMAIL                                VARCHAR2(255)
,RCPTBILLTYPE                             VARCHAR2(1)
,RCPTBILLFREQ                             VARCHAR2(1)
,RCPTBILLDAY                              NUMBER(2)
,RCPTAUTOBILL                             VARCHAR2(1)
,MISCNAME                                 VARCHAR2(40)
,MISCCONTACT                              VARCHAR2(40)
,MISCADDR1                                VARCHAR2(40)
,MISCADDR2                                VARCHAR2(40)
,MISCCITY                                 VARCHAR2(30)
,MISCSTATE                                VARCHAR2(2)
,MISCPOSTALCODE                           VARCHAR2(12)
,MISCCOUNTRYCODE                          VARCHAR2(3)
,MISCPHONE                                VARCHAR2(15)
,MISCFAX                                  VARCHAR2(15)
,MISCEMAIL                                VARCHAR2(255)
,MISCBILLTYPE                             VARCHAR2(1)
,MISCBILLFREQ                             VARCHAR2(1)
,MISCBILLDAY                              NUMBER(2)
,MISCAUTOBILL                             VARCHAR2(1)
,OUTBNAME                                 VARCHAR2(40)
,OUTBCONTACT                              VARCHAR2(40)
,OUTBADDR1                                VARCHAR2(40)
,OUTBADDR2                                VARCHAR2(40)
,OUTBCITY                                 VARCHAR2(30)
,OUTBSTATE                                VARCHAR2(2)
,OUTBPOSTALCODE                           VARCHAR2(12)
,OUTBCOUNTRYCODE                          VARCHAR2(3)
,OUTBPHONE                                VARCHAR2(15)
,OUTBFAX                                  VARCHAR2(15)
,OUTBEMAIL                                VARCHAR2(255)
,OUTBBILLTYPE                             VARCHAR2(1)
,OUTBBILLFREQ                             VARCHAR2(1)
,OUTBBILLDAY                              NUMBER(2)
,OUTBAUTOBILL                             VARCHAR2(1)
,STATUS                                   VARCHAR2(4)
,POVERIFY                                 VARCHAR2(1)
,SPLITRECVSTORAGE                         VARCHAR2(1)
,CREDITHOLD                               VARCHAR2(1)
,SQFT                                     NUMBER(7)
,LOTREQUIRED                              VARCHAR2(1)
,LOTRFTAG                                 VARCHAR2(3)
,SERIALREQUIRED                           VARCHAR2(1)
,SERIALRFTAG                              VARCHAR2(3)
,USER1REQUIRED                            VARCHAR2(1)
,USER1RFTAG                               VARCHAR2(5)
,USER2REQUIRED                            VARCHAR2(1)
,USER2RFTAG                               VARCHAR2(5)
,USER3REQUIRED                            VARCHAR2(1)
,USER3RFTAG                               VARCHAR2(5)
,LASTUSER                                 VARCHAR2(12)
,LASTUPDATE                               DATE
,MFGDATEREQUIRED                          VARCHAR2(1)
,EXPDATEREQUIRED                          VARCHAR2(1)
,NODAMAGED                                VARCHAR2(1)
,COUNTRYREQUIRED                          VARCHAR2(1)
,POWHENVERIFY                             VARCHAR2(1)
,POMAPFILE                                VARCHAR2(255)
,PORPTFILE                                VARCHAR2(255)
,POVERIFYEMAIL                            VARCHAR2(1)
,POVERIFYFAX                              VARCHAR2(1)
,POVERIFYONLINE                           VARCHAR2(1)
,POVERIFYBATCH                            VARCHAR2(1)
,POMAPONLINE                              VARCHAR2(255)
,POEMAILFILE                              VARCHAR2(255)
,POFAXFILE                                VARCHAR2(255)
,POWHENFAX                                VARCHAR2(1)
,POWHENEMAIL                              VARCHAR2(1)
,POWHENBATCH                              VARCHAR2(1)
,POWHENONLINE                             VARCHAR2(1)
);

create unique index customer_unique on customer(custid);