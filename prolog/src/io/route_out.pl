:- module(route_out, [annotated_route/2, route_undecidable/2,
                      route_ambiguous_carrier/2]).

/** <module> Annotated itinerary -> fare-construction routing string.

    The inverse of io/route_in.pl, and the reason it lives here rather than in
    the browser: a routing composed in JavaScript would be a second definition
    of the grammar, and the one nothing tests. With both directions in Prolog
    the round trip is a property the suite can assert -- parse a routing,
    annotate it, compose it again, and get the same string back.

    It composes from the *annotated* itinerary rather than the raw one, because
    the notation records what each point counts as and that is a conclusion
    rather than an input. A point declared `X/` and a point inferred to be a
    transfer from a two-hour connection both come out as `X/`; the routing
    describes how the itinerary was classified, which is exactly what makes it
    round-trip to the same verdict.

    Three things do not survive the trip, all of them limits of the notation
    rather than of this module:

      * A city code resolves to its airport on the way in and stays an airport
        on the way out, so `LON-BA-NYC` composes back as `LHR-BA-JFK`. That is
        canonicalisation, not loss -- both name the same journey.
      * A routing carries one carrier per leg. A codeshare with different
        marketing and operating carriers keeps only the marketing one, which is
        the one 4(j) is written against.
      * A three-letter carrier designator that is also a place code cannot be
        written at all -- see route_ambiguous_carrier/2. HAC is the only one in
        the 4(j) table, and it is Hachijojima as well as Hokkaido Air System.
      * Dates and times have no notation at all. Composing a dated itinerary
        gives a routing that answers every rule except 6 and 7.

    A point that is neither a transfer nor a stopover -- no ground time and no
    declaration -- cannot be written down at all: every non-final point in a
    routing is one or the other, and a bare code means stopover. Rather than
    silently promoting those to stopovers and changing the itinerary's meaning,
    annotated_route/2 fails and route_undecidable/2 names the segments.
*/

:- use_module('../geo').
:- use_module(library(apply)).
:- use_module(library(lists)).

%! annotated_route(+A, -Route) is semidet.
%
%  Fails if any intermediate point is undecided; use route_undecidable/2 to
%  find out which, and say so, rather than guessing on the user's behalf.
annotated_route(A, Route) :-
    A.segments = [First|_],
    route_undecidable(A, []),
    route_ambiguous_carrier(A, []),
    last(A.segments, Last),
    LastN = Last.n,
    upcase_atom(First.from, Origin),
    maplist(segment_part(A, LastN), A.segments, Parts),
    atomic_list_concat([Origin|Parts], Route).

%! route_undecidable(+A, -Segments) is det.
%
%  The segment numbers whose arrival point has no classification. Empty when
%  the itinerary can be written as a routing.
route_undecidable(A, Segments) :-
    findall(N,
            ( member(P, A.points),
              N = P.after,
              Kind = P.kind,
              \+ decided(Kind)
            ),
            Segments).

decided(transfer).
decided(stopover).

%! route_ambiguous_carrier(+A, -Segments) is det.
%
%  The segment numbers whose carrier cannot be written in a routing because the
%  code would be read back as a place. Only three-letter designators can
%  collide, and of the 4(j) affiliates only HAC does -- it is also the airport
%  at Hachijojima -- but composing it anyway would emit a string that parses to
%  a different itinerary than the one it was composed from, which is the one
%  failure a round-trippable notation must not have.
route_ambiguous_carrier(A, Segments) :-
    findall(N,
            ( member(S, A.segments),
              S.type == flight,
              carrier_of(S, Upper),
              downcase_atom(Upper, Code),
              atom_length(Code, 3),
              place_code_known(Code),
              N = S.n
            ),
            Segments).

% Each segment contributes the separator that precedes it and the token for the
% point it arrives at. The origin is emitted by the caller because it is the one
% point no segment arrives at.
segment_part(A, LastN, S, Part) :-
    arrival_token(A, LastN, S, Token),
    (   S.type == surface
    ->  atomic_list_concat(['//', Token], Part)
    ;   carrier_of(S, Carrier)
    ->  atomic_list_concat(['-', Carrier, '-', Token], Part)
    ;   atomic_list_concat(['-', Token], Part)
    ).

% `//` replaces the separator *and* the carrier: a surface sector is one the
% traveller arranges, so there is no carrier to name.
carrier_of(S, Upper) :-
    (   S.marketing \== unknown
    ->  Code = S.marketing
    ;   S.operating \== unknown
    ->  Code = S.operating
    ),
    upcase_atom(Code, Upper).

% The final point ends the journey rather than interrupting it, so it never
% takes an `X/` -- matching route_in.pl, which drops the last point's
% declaration for the same reason.
arrival_token(A, LastN, S, Token) :-
    upcase_atom(S.to, Code),
    (   S.n == LastN
    ->  Token = Code
    ;   point_kind(A, S.n, transfer)
    ->  atom_concat('X/', Code, Token)
    ;   Token = Code
    ).

point_kind(A, N, Kind) :-
    once(( member(P, A.points), P.after == N )),
    Kind = P.kind.
