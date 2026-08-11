:- module(pricing,
          [ fare/2,
            continent_count/3,
            via_asia_sector/2,
            premium_economy_rows/2
          ]).

/** <module> Section 0 fare basis and section 12 surcharges.

    Informational output rather than validation, with one exception: fewer
    than three continents has no published fare basis at all, which is why
    rules/r00_continents.pl raises it as an error.
*/

:- use_module(geo).
:- use_module(annotate).
:- use_module('../data/limits').
:- use_module('../data/surcharges').
:- use_module(library(apply)).

%! fare(+A, -Fare) is det.
fare(A, fare{ continents: N,
              continent_list: Continents,
              cabin: Cabin,
              basis: Basis,
              premium_economy_upgrade_usd: Total,
              premium_economy_segments: Rows,
              discounts: Discounts }) :-
    Cabin = A.cabin,
    continent_count(A, Continents, N),
    (   fare_basis(Cabin, N, B) -> Basis = B ; Basis = none ),
    premium_economy_rows(A, Rows),
    foldl([R, Acc0, Acc]>>( get_dict(usd, R, U), Acc is Acc0 + U ), Rows, 0, Total),
    discounts(A, Discounts).

%! continent_count(+A, -Continents, -N) is det.
%
%  Section 0: "Travel between South West Pacific and Europe/Middle East on a
%  single flight number or by surface ... is considered travelling via Asia.
%  Continents South West Pacific, Asia and Europe/Middle East must each be
%  counted." So a nonstop LON-PER adds Asia to the count even though the
%  itinerary never touches an Asian airport.
continent_count(A, Continents, N) :-
    exclude(==(unknown), A.visited, Base),
    (   via_asia_sector(A, _)
    ->  sort([asia|Base], Continents)
    ;   Continents = Base
    ),
    length(Continents, N).

%! via_asia_sector(+A, -SegmentNumber) is nondet.
%  A single segment, flight or surface, joining the South West Pacific
%  directly to Europe/Middle East.
%
%  This feeds the continent count and nothing else. It deliberately does not
%  feed 4(e), even though "considered travelling via Asia" could be read as
%  putting an arrival into Asia and a departure from it on the itinerary, and
%  some experienced bookers do read it that way.
%
%  Two things hold it here. The sentence sits in section 0 under how the fare
%  is determined, and what it says must be counted is continents -- the input
%  to the fare basis, which is the paragraph above it. And the reading is
%  nearly inert: the deemed pair would consume one of Asia's two allowed
%  arrivals and one of its two departures, so it only ever bites an itinerary
%  that already enters Asia twice by air *and* flies a nonstop between the
%  South West Pacific and Europe. A traveller who has flown LON-SYD through
%  and never met an Asia problem is what that predicts, and the one itinerary
%  on record of the biting shape is already invalid five other ways -- so
%  adopting it would have changed no verdict anyone has produced, while
%  putting a new way to fail in front of journeys that price today.
via_asia_sector(A, N) :-
    ann_seg(A, S),
    sort([S.from_cont, S.to_cont], [europe_middle_east, south_west_pacific]),
    N = S.n.

%! premium_economy_rows(+A, -Rows) is det.
%  Section 12 charges are per flight segment; surface sectors carry none.
premium_economy_rows(A, Rows) :-
    findall(row{ segment: N, from: From, to: To,
                 from_region: RF, to_region: RT, usd: Usd },
            ( ann_seg(A, S),
              S.type == flight,
              N = S.n, From = S.from, To = S.to,
              airport_fare_region(From, RF),
              airport_fare_region(To, RT),
              sector_surcharge(RF, RT, Usd)
            ),
            Rows).

%! discounts(+A, -Rows) is det.
%  Rule 19. Unaccompanied children are not accepted at all, and an infant
%  turning two mid-journey must hold a full child fare; both are stated in the
%  message rather than computed.
discounts(A, Rows) :-
    findall(row{ type: T, percent: P, fare_code_suffix: Suffix },
            ( member(Pax, A.passengers),
              get_dict(type, Pax, T),
              discount_for(T, P, Suffix)
            ),
            Rows).

discount_for(child,  P, 'CH') :- limit(child_discount_percent, P).
discount_for(infant, P, 'IN') :- limit(infant_discount_percent, P).
