:- module(geo,
          [ airport/6,
            airport_known/1,
            airport_country/2,
            airport_region/2,
            airport_city/2,
            airport_coords/3,
            airport_continent/2,
            airport_zone/2,
            airport_tc/2,
            airport_fare_region/2,
            continent_tc/2,
            same_country/2,
            domestic_us_canada/2,
            is_hawaii/1,
            is_alaska/1,
            is_transcontinental_us/2,
            ocean_crossing/3,
            airport_search/3,
            resolve_place/2,
            place_code_known/1,
            place_key/2,
            same_place/2,
            place_name/2,
            iata/2
          ]).

/** <module> Airport -> country -> continent -> traffic conference.

    The generated fact base is *included* rather than imported so that
    airport/6 lives in this module and gets first-argument indexing on the
    IATA code without an extra layer of indirection.
*/

:- use_module(fold).
:- use_module('../data/limits').
:- use_module('../data/cities').
:- use_module('../data/countries').
:- use_module('../data/overrides').
:- use_module('../data/transcon').
:- use_module('../data/surcharges').

:- include('../data/generated/airports').

%! airport_known(+Iata) is semidet.
airport_known(A) :- airport(A, _, _, _, _, _), !.

%! resolve_place(+Code, -Airport) is det.
%  Metropolitan city codes are what routings are written in, so they are
%  resolved to a representative airport before anything else sees them. An
%  unrecognised code is passed through untouched and fails airport_known/1
%  later, which is what turns it into an input_error violation.
resolve_place(Code, Airport) :-
    (   city_code(Code, A)
    ->  Airport = A
    ;   Airport = Code
    ).

%! place_code_known(+Code) is semidet.
%  True when a code names an airport or a metropolitan city -- that is, when a
%  routing token would be read as a place. io/route_in and io/route_out both
%  ask this about three-letter carrier designators, which are the only tokens
%  the notation cannot tell apart by shape.
place_code_known(Code) :- airport_known(Code), !.
place_code_known(Code) :- city_code(Code, _).

%! place_key(+Airport, -Key) is det.
%  The identity a fare rule compares on. Rule 4 is written in cities -- 4(i)
%  says "the same city pairs/sectors", 4(c) and 4(d) say "point" -- so LHR and
%  LGW are one place to it and two places to the airport table. Airports
%  outside any metropolitan area are their own key, which is the common case.
%
%  Deliberately not applied at parse time: an itinerary that says LGW must keep
%  saying LGW in the report, on the map, and in the routing it round-trips to.
%  Only the rules that ask "is this the same point" fold the two together.
place_key(Airport, Key) :-
    (   city_of(Airport, City)
    ->  Key = City
    ;   Key = Airport
    ).

%! same_place(+A, +B) is semidet.
same_place(A, B) :- place_key(A, K), place_key(B, K).

%! place_name(+Airport, -Display) is det.
%  How a place is named once two airports have been folded into one: the
%  metropolitan code where there is one, so a 4(i) message about LHR-JFK and
%  LGW-JFK reads "LON-NYC" rather than picking one airport and looking wrong.
place_name(Airport, Display) :-
    place_key(Airport, Key),
    iata(Key, Display).

%! iata(+Code, -Display) is det.
%  Codes are held lower-case internally so they can be table keys; every
%  message and every JSON field shows them the way a traveller writes them.
iata(unknown, unknown) :- !.
iata(A, U) :- upcase_atom(A, U).

airport_country(A, C) :- airport(A, C, _, _, _, _).
airport_region(A, R)  :- airport(A, _, R, _, _, _).
airport_city(A, City) :- airport(A, _, _, City, _, _).
airport_coords(A, Lat, Lon) :- airport(A, _, _, _, Lat, Lon).

%! airport_continent(+Iata, -Continent) is semidet.
airport_continent(A, Cont) :-
    airport(A, Country, Region, _, _, Lon),
    (   continent_override(Country, Region, Lon, C0)
    ->  Cont = C0
    ;   country_continent(Country, Cont)
    ).

%! airport_zone(+Iata, -Zone) is semidet.
%  Only Europe/Middle East has zones; fails elsewhere.
airport_zone(A, Zone) :-
    airport(A, Country, Region, _, _, Lon),
    (   zone_override(Country, Region, Lon, Z0)
    ->  Zone = Z0
    ;   country_zone(Country, Zone)
    ).

%! airport_tc(+Iata, -TC) is semidet.
airport_tc(A, TC) :-
    airport_continent(A, Cont),
    traffic_conference(Cont, TC).

continent_tc(Cont, TC) :- traffic_conference(Cont, TC).

%! airport_fare_region(+Iata, -Region) is semidet.
%  The section 12 taxonomy, which is finer than the continent list.
airport_fare_region(A, Region) :-
    airport(A, Country, _, _, _, _),
    airport_continent(A, Cont),
    (   airport_zone(A, Zone) -> true ; Zone = none ),
    fare_region(Country, Cont, Zone, Region).

same_country(A, B) :-
    airport_country(A, C),
    airport_country(B, C).

%! domestic_us_canada(+A, +B) is semidet.
%  4(f) NOTE: "Travel between USA and Canada is not counted as international."
domestic_us_canada(A, B) :-
    airport_country(A, CA0),
    airport_country(B, CB0),
    memberchk(CA0, ['US', 'CA']),
    memberchk(CB0, ['US', 'CA']).

is_hawaii(A) :- airport_region(A, R), hawaii_region(R).
is_alaska(A) :- airport_region(A, R), alaska_region(R).

%! is_transcontinental_us(+From, +To) is semidet.
%  4(k). Both endpoints must be US states in opposite columns.
is_transcontinental_us(From, To) :-
    airport_region(From, RF),
    airport_region(To, RT),
    transcontinental_pair(RF, RT).

%! ocean_crossing(+From, +To, -Ocean) is det.
%  4(a): travel must be via the Atlantic and Pacific, one crossing each.
%
%  A crossing is identified by which traffic conferences a sector joins, not
%  by geometry: TC1<->TC2 is the Atlantic and TC1<->TC3 is the Pacific. TC2<->TC3
%  is the land/Indian-Ocean boundary and crosses neither. This is what makes
%  the collapsed-TC-sequence invariant in r04_routing.pl equivalent to 4(a).
ocean_crossing(From, To, Ocean) :-
    airport_tc(From, TF),
    airport_tc(To, TT),
    (   tc_ocean(TF, TT, O) -> Ocean = O ; Ocean = none ).

tc_ocean(tc1, tc2, atlantic).
tc_ocean(tc2, tc1, atlantic).
tc_ocean(tc1, tc3, pacific).
tc_ocean(tc3, tc1, pacific).

%! airport_search(+Query, +Limit, -Results) is det.
%  Typeahead for the web UI. Exact IATA match first, then IATA prefix, then
%  city prefix, then city substring. Case and accents are folded on both sides,
%  so `belem` finds Belém and `sao paulo` finds São Paulo: the cities whose
%  spelling is hardest to reproduce are the ones the search is most needed for.
airport_search(Query, Limit, Results) :-
    fold_diacritics(Query, Q),
    findall(Rank-A,
            ( airport(A, _, _, City, _, _),
              fold_diacritics(City, LC),
              (   A == Q                       -> Rank = 0
              ;   sub_atom(A, 0, _, _, Q)      -> Rank = 1
              ;   sub_atom(LC, 0, _, _, Q)     -> Rank = 2
              ;   sub_atom(LC, _, _, _, Q)     -> Rank = 3
              )
            ),
            Hits0),
    keysort(Hits0, Hits),
    length(Hits, N),
    Take is min(Limit, N),
    length(Prefix, Take),
    append(Prefix, _, Hits),
    findall(A, member(_-A, Prefix), Results).
