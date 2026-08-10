:- module(surcharges,
          [ fare_region/4,
            special_region/2,
            sector_surcharge/3,
            surcharge_bands/1,
            premium_cabin_code/2
          ]).

/** <module> Section 12 premium-economy surcharge matrix.

    A third taxonomy again -- section 12 needs regions the section 0 continent
    list does not have at all (South East Asia, South Asian Subcontinent,
    Japan/Korea, French Polynesia, Australia as distinct from the rest of the
    South West Pacific), so it gets its own table rather than being bolted onto
    countries.pl.
*/

term_expansion(special_group(Region, List), Facts) :-
    findall(special_region(C, Region), member(C, List), Facts).

:- discontiguous special_region/2.

special_group(australia,               ['AU','CC','CX']).
special_group(new_zealand,             ['NZ']).
special_group(french_polynesia,        ['PF']).
special_group(south_east_asia,         ['BN','ID','KH','LA','MM','MY','PH','SG','TH','TL','VN']).
special_group(south_asian_subcontinent,['AF','BD','BT','IN','LK','MV','NP','PK']).
special_group(japan_korea,             ['JP','KP','KR']).

%! fare_region(+Country, +Continent, +Zone, -Region) is det.
%  Falls back to the continent where section 12 needs no finer split.
fare_region(Country, _Continent, _Zone, Region) :-
    special_region(Country, Region), !.
fare_region(_Country, europe_middle_east, Zone, Zone) :- !.
fare_region(_Country, south_west_pacific, _, swp_other) :- !.
fare_region(_Country, asia, _, asia_other) :- !.
fare_region(_Country, Continent, _, Continent).

swp_region(australia).
swp_region(new_zealand).
swp_region(french_polynesia).
swp_region(swp_other).

%! sector_surcharge(+FromRegion, +ToRegion, -Usd) is det.
%  Clause order is significant -- the bands overlap and the rule resolves them
%  by specificity, so the narrower band must be listed first. In particular
%  New Zealand-French Polynesia must precede "sectors within SWP", and French
%  Polynesia-Americas must precede "SWP other than Australia"-Americas.
sector_surcharge(A, B, Usd) :- once(band(A, B, Usd)).

band(A, B, 1900) :- pair(A, B, X, Y), swp_region(X), memberchk(Y, [africa, europe, middle_east]).
band(A, B, 1700) :- pair(A, B, australia, Y), memberchk(Y, [north_america, south_america]).
band(A, B,  845) :- pair(A, B, french_polynesia, Y), memberchk(Y, [north_america, south_america]).
band(A, B, 1450) :- pair(A, B, X, Y), swp_region(X), X \== australia,
                    memberchk(Y, [north_america, south_america]).
band(A, B,  605) :- pair(A, B, new_zealand, french_polynesia).
band(A, B,  350) :- pair(A, B, south_east_asia, Y),
                    memberchk(Y, [south_asian_subcontinent, japan_korea]).
band(A, A,  250) :- memberchk(A, [south_east_asia, australia, middle_east]).
band(A, B,  250) :- swp_region(A), swp_region(B).
band(_, _,  950).

%! pair(+A, +B, ?X, ?Y) is nondet.
%  Every band is direction-independent.
pair(A, B, A, B).
pair(A, B, B, A).

%! surcharge_bands(-Rows) is det.
%  Human-readable band list for the /api/ruleset endpoint.
surcharge_bands(
    [ band('SWP <-> Africa; SWP <-> Europe/Middle East',        1900),
      band('Australia <-> North America / South America',       1700),
      band('SWP excl. Australia <-> North / South America',     1450),
      band('South East Asia <-> South Asian Subcontinent / Japan-Korea', 350),
      band('Within South East Asia / Australia / SWP / Middle East',      250),
      band('New Zealand <-> French Polynesia',                   605),
      band('French Polynesia <-> North America / South America',  845),
      band('All other sectors',                                   950)
    ]).

%! premium_cabin_code(?Carrier, ?BookingClass) is nondet.
%  Section 12: the class the surcharged premium cabin must be booked in.
premium_cabin_code(aa, 'P').
premium_cabin_code(ba, 'T').
premium_cabin_code(ib, 'T').
premium_cabin_code(jl, 'E').
premium_cabin_code(nu, 'E').
premium_cabin_code(cx, 'R').
premium_cabin_code(qf, 'R').
premium_cabin_code(rj, 'W').
