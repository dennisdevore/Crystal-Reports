--
-- $Id: zuccspec.sql 753 2007-03-22 21:32:29Z ed $
--
create or replace package zucclabels as


procedure targetstores
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure shopko
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure burlingtoncoat
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure buybuybaby
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwbuybuybaby
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure targetcom
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure kohls
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure macys
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure walgreens
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure walmart
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure stagestores
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure kmart
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure rossstores
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure searsroebuck
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure mervyns
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure aafes
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure amazoncom
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure boscovs
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bedbathandbeyond
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure cato
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure jcpenney
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure valuecity
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bontonsaks
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure belk
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure pamida
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure stienmart
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure peebles
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);


procedure niemanmarcus
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure alloy
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);


procedure anthropologie
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure charmingshops
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure cititrends
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure filinesbasement
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bobsstores
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure forever21
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure glicks
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure gordmans
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure internationalmail
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure maurices
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure number7
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure gabrialbrothers
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure rainbow
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure hamricks
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure olympia
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure dunhams
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure gottshalks
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure modells
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure nordstroms
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lanebryant
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure dawahares
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure winners
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure kaybee
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure formanmills
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure fredmeyer
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure rue21
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure tjmaxx
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure marshalls
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure toysrus
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure toysruscanada
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure vonmaur
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bealls
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure genericucc
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure amazongen
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwkmart
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwaafes
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwbestbuy
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwfingerhut
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwsears
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwstaples
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwofficedepot
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bbbsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure belksgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bontonsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure boscovssgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure jockeysgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure kgsgfoo
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure basspro
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lwpack
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure bluestem
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure micro
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure lazybonezz
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure walmartcom
   (in_lpid   in varchar2,
    in_func   in varchar2,       -- Q - query, X - execute
    in_action in varchar2,       -- A - all, P - print only, C - changes
    out_stmt  out varchar2);

procedure filtersscc
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure filterpallet
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure filtersscccntnt
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure filtersscc14
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure dwcfiltersscc
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure dwffiltersscc
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure dwfiltersscc14
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure filtersscccons
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

function casepack
(in_custid custitem.custid%type,
 in_item custitem.item%type)
return integer;
end zucclabels;
/

show error package zucclabels;
exit;
