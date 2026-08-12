:- module(route_in, [route_segments/2, route_help/1]).

/** <module> Fare-construction routing string -> raw segments.

    A routing is how a fare is actually written down:

        NYC-X/LON-SIN-X/HKG-NYC

    The notation carries exactly the thing timestamps were being used to infer.
    `X/` marks a transit point; a point without it is a stopover. So a routing
    string is a complete input for every rule that does not need a calendar --
    which is all of them except 6 and 7.

    The grammar, with the extensions this validator needs:

        NYC-X/LON-SIN-NYC          points separated by `-`, `X/` (or bare `X`)
                                   prefixes a transfer, anything else is a
                                   stopover
        LON-BA-X/JFK-AA-LAX        a two-character token is the carrier of the
                                   leg that follows it
        BKK//SIN                   `//` in place of `-` makes that leg a
                                   surface sector (4(g)), which the traveller
                                   covers themselves
        LON X/PAR SIN              whitespace and commas separate as well as
                                   `-`, so pasted routings parse unchanged

    Airport codes and metropolitan city codes are both accepted; data/cities.pl
    resolves the latter. Length is what tells the token kinds apart -- airline
    designators are two characters and place codes are three -- so `XIY` is
    Xi'an rather than a transfer at `IY`, and no escaping is needed.
*/

:- use_module('../geo').
:- use_module('../carriers').
:- use_module(library(apply)).

%! route_help(-Text) is det.
%  One-line grammar summary, used by the CLI usage message and served to the
%  web UI so the syntax is documented in exactly one place.
route_help('NYC-X/LON-SIN-NYC — points separated by "-", "X/" marks a transfer (anything else is a stopover), "//" makes a leg a surface sector, and a two-letter token between points is that leg\'s carrier.').

%! route_segments(+Text, -RawSegs) is det.
%
%  Produces the same rseg/12 terms io/json_in.pl builds from a `segments`
%  array, so both front ends meet at build_itinerary/6 and no rule knows which
%  was used. Throws input_error(Message) on anything unparseable.
route_segments(Text, RawSegs) :-
    text_to_string(Text, S0),
    string_upper(S0, S1),
    tokens(S1, Tokens),
    (   Tokens == []
    ->  throw(input_error('Route is empty.'))
    ;   true
    ),
    walk(Tokens, flight, unknown, Points),
    (   Points = [_, _|_]
    ->  true
    ;   throw(input_error('A route needs at least two points, such as "LHR-X/JFK-LHR".'))
    ),
    segments(Points, 1, RawSegs).

% --- tokenizing ------------------------------------------------------------

% `//` becomes a token of its own first, so it survives the split whether it
% was written as `BKK//SIN` or as `BKK-//-SIN`.
tokens(S0, Tokens) :-
    replace_surface(S0, S1),
    split_string(S1, "- \t\n,", "- \t\n,", Parts),
    exclude(==(""), Parts, Kept),
    maplist([P, A]>>atom_string(A, P), Kept, Tokens).

replace_surface(In, Out) :-
    atomic_list_concat(Chunks, '//', In),
    atomic_list_concat(Chunks, ' // ', Out).

% --- walking ---------------------------------------------------------------

% Each point records the leg that *arrives* at it, because that is the leg the
% point's own declaration belongs to: `X/LON` says the point at the end of the
% leg into London is a transfer.
walk([], _, _, []).
walk(['//'|T], _, Carrier, Points) :- !,
    walk(T, surface, Carrier, Points).
walk([Token|T], Type, Carrier, Points) :-
    carrier_token(Token, Code), !,
    (   Carrier == unknown
    ->  walk(T, Type, Code, Points)
    ;   iata(Carrier, Shown),
        format(atom(M), 'Two carriers (~w and ~w) given for one leg.', [Shown, Token]),
        throw(input_error(M))
    ).
walk([Token|T], Type, Carrier, [point(Code, Declared, Type, Carrier)|Points]) :-
    point_token(Token, Code, Declared), !,
    walk(T, flight, unknown, Points).
walk([Token|_], _, _, _) :-
    format(atom(M),
           'Cannot read "~w" in the route. Expected a three-letter place code (optionally prefixed "X/"), a two-letter carrier, or "//" for a surface sector.',
           [Token]),
    throw(input_error(M)).

% Codes are held lower-case internally throughout, matching io/json_in.pl, so
% they meet the carrier and airport tables in the form those tables use.
carrier_token(T, Code) :-
    atom_length(T, 2),
    atom_chars(T, Cs),
    maplist([C]>>char_type(C, alnum), Cs),
    downcase_atom(T, Code).
% A few 4(j) affiliates carry three-letter designators, so length alone no
% longer separates carriers from places. A three-letter token is read as a
% carrier only when it is one and no airport or city answers to it -- which
% leaves HAC the airport at Hachijojima rather than Hokkaido Air System, since
% a routing that names a place is the far likelier reading and the notation has
% no way to say which was meant. io/route_out refuses to compose the other one.
carrier_token(T, Code) :-
    atom_length(T, 3),
    atom_chars(T, Cs),
    maplist([C]>>char_type(C, alnum), Cs),
    downcase_atom(T, Code),
    carrier_code(Code),
    \+ place_code_known(Code).

point_token(T, Code, transfer) :-
    ( atom_concat('X/', Code0, T) ; atom_concat('X', Code0, T) ),
    atom_length(Code0, 3), !,
    place_code(Code0, Code).
point_token(T, Code, stopover) :-
    atom_length(T, 3),
    place_code(T, Code).

place_code(T, Code) :-
    atom_chars(T, Cs),
    maplist([C]>>char_type(C, alnum), Cs),
    downcase_atom(T, Code).

% --- assembling ------------------------------------------------------------

% The declaration on a point describes the point, so it lands on the segment
% that arrives there. The final point is the end of the journey rather than an
% intermediate point, so its declaration is dropped rather than carried on a
% segment where nothing would ever read it.
segments([_], _, []) :- !.
segments([point(From, _, _, _), Next|Rest], N, [Seg|Segs]) :-
    Next = point(To, Declared, Type, Carrier),
    (   Rest == []
    ->  Stop = unknown
    ;   Stop = Declared
    ),
    % No booking class and no fare family: a routing is a fare notation and has
    % no place to write either. Section 5(b) and the earning programmes report
    % that they had nothing to read -- see PLANS/05.
    Seg = rseg(N, Type, From, To, Carrier, Carrier, unknown, unknown, unknown, Stop, unknown, unknown),
    N1 is N + 1,
    segments([Next|Rest], N1, Segs).
