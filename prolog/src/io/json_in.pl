:- module(json_in, [itinerary_from_json/2, parse_dt/2]).

/** <module> JSON itinerary -> canonical itinerary term.

    Malformed input throws input_error(Message); the caller turns that into an
    HTTP 400 or a CLI exit code. Input that is well-formed but references
    something unresolvable is *not* thrown -- itinerary.pl turns that into an
    ordinary violation so it appears in the report alongside the rule
    violations.
*/

:- use_module('../itinerary').
:- use_module('../../data/limits').
:- use_module(library(apply)).

%! itinerary_from_json(+Dict, -Itin) is det.
%
%   { "origin": "LHR", "cabin": "business",
%     "passengers": [{"type": "adult"}],
%     "segments": [ { "n": 1, "type": "flight", "from": "LHR", "to": "JFK",
%                     "marketingCarrier": "BA", "operatingCarrier": "BA",
%                     "flight": "BA117",
%                     "dep": "2026-09-01T10:25", "arr": "2026-09-01T13:30" } ] }
%
%  Only `from`, `to` and `segments` are required. `cabin` defaults to economy,
%  `origin` to the departure point of segment 1, `type` to flight, and
%  `carrier` is accepted as shorthand for both carrier fields.
itinerary_from_json(Dict, Itin) :-
    (   is_dict(Dict) -> true
    ;   throw(input_error('Request body must be a JSON object.'))
    ),
    (   get_dict(segments, Dict, SegsJson), is_list(SegsJson)
    ->  true
    ;   throw(input_error('Missing or non-list "segments".'))
    ),
    (   SegsJson == []
    ->  throw(input_error('"segments" must not be empty.'))
    ;   true
    ),
    length(SegsJson, SegCount),
    limit(max_input_segments, MaxSegs),
    (   SegCount > MaxSegs
    ->  format(atom(TooMany),
               'Itinerary has ~w segments; this service accepts at most ~w.',
               [SegCount, MaxSegs]),
        throw(input_error(TooMany))
    ;   true
    ),
    atom_field(Dict, origin, unknown, Origin),
    cabin(Dict, Cabin),
    passengers(Dict, Passengers),
    maplist(segment, SegsJson, RawSegs),
    build_itinerary(Origin, Cabin, Passengers, RawSegs, Itin).

segment(J, rseg(N, Type, From, To, Mkt, Op, Flight, Dep, Arr)) :-
    (   is_dict(J) -> true
    ;   throw(input_error('Each entry of "segments" must be a JSON object.'))
    ),
    int_field(J, n, unknown, N),
    segment_type(J, Type),
    required_atom(J, from, From),
    required_atom(J, to, To),
    % `carrier` is shorthand for "same carrier both ways" and so fills both
    % fields. `marketingCarrier` on its own leaves the operator unknown rather
    % than assuming there is no codeshare -- 4(j) turns on who actually
    % operates, and quietly guessing would report a clean 4(j) it never checked.
    atom_field(J, carrier, unknown, Shared),
    atom_field(J, marketingCarrier, Shared, Mkt),
    atom_field(J, operatingCarrier, Shared, Op),
    verbatim_field(J, flight, unknown, Flight),
    time_field(J, dep, Dep),
    time_field(J, arr, Arr).

segment_type(J, Type) :-
    atom_field(J, type, flight, T),
    (   memberchk(T, [flight, surface])
    ->  Type = T
    ;   format(atom(M), 'Segment type must be "flight" or "surface", not "~w".', [T]),
        throw(input_error(M))
    ).

cabin(Dict, Cabin) :-
    atom_field(Dict, cabin, economy, C),
    (   memberchk(C, [economy, business, first])
    ->  Cabin = C
    ;   format(atom(M), 'Cabin must be "economy", "business" or "first", not "~w".', [C]),
        throw(input_error(M))
    ).

passengers(Dict, Passengers) :-
    (   get_dict(passengers, Dict, L), is_list(L)
    ->  maplist(passenger, L, Passengers)
    ;   get_dict(passengers, Dict, _)
    ->  throw(input_error('"passengers" must be a list.'))
    ;   Passengers = [pax{type: adult, age: unknown}]
    ).

passenger(J, pax{type: Type, age: Age}) :-
    atom_field(J, type, adult, Type),
    (   memberchk(Type, [adult, child, infant])
    ->  true
    ;   format(atom(M), 'Passenger type must be "adult", "child" or "infant", not "~w".', [Type]),
        throw(input_error(M))
    ),
    int_field(J, age, unknown, Age).

% --- field readers ---------------------------------------------------------

atom_field(J, Key, Default, Value) :-
    (   get_dict(Key, J, Raw), Raw \== null
    ->  to_atom(Key, Raw, Value)
    ;   Value = Default
    ).

% Airport codes, carriers and cabins are matched against lower-case tables, so
% they are folded; a flight number is only ever displayed, so it is not.
verbatim_field(J, Key, Default, Value) :-
    (   get_dict(Key, J, Raw), Raw \== null
    ->  (   atom(Raw)   -> Value = Raw
        ;   string(Raw) -> atom_string(Value, Raw)
        ;   format(atom(M), 'Field "~w" must be a string.', [Key]),
            throw(input_error(M))
        )
    ;   Value = Default
    ).

required_atom(J, Key, Value) :-
    (   get_dict(Key, J, Raw), Raw \== null
    ->  to_atom(Key, Raw, Value)
    ;   format(atom(M), 'Missing required field "~w".', [Key]),
        throw(input_error(M))
    ).

to_atom(_, Raw, A) :- atom(Raw),   !, downcase_atom(Raw, A).
to_atom(_, Raw, A) :- string(Raw), !, atom_string(A0, Raw), downcase_atom(A0, A).
to_atom(Key, Raw, _) :-
    format(atom(M), 'Field "~w" must be a string, not ~q.', [Key, Raw]),
    throw(input_error(M)).

int_field(J, Key, Default, Value) :-
    (   get_dict(Key, J, Raw), Raw \== null
    ->  (   integer(Raw)
        ->  Value = Raw
        ;   format(atom(M), 'Field "~w" must be an integer.', [Key]),
            throw(input_error(M))
        )
    ;   Value = Default
    ).

time_field(J, Key, Dt) :-
    (   get_dict(Key, J, Raw), Raw \== null
    ->  (   parse_dt(Raw, Dt)
        ->  true
        ;   format(atom(M),
                   'Field "~w" must be an ISO 8601 local date-time such as "2026-09-01T10:25", not ~q.',
                   [Key, Raw]),
            throw(input_error(M))
        )
    ;   Dt = unknown
    ).

%! parse_dt(+Text, -Dt) is semidet.
%
%  Accepts YYYY-MM-DD, YYYY-MM-DDThh:mm and YYYY-MM-DDThh:mm:ss, with a space
%  in place of the T. A trailing zone designator is accepted and *discarded*:
%  these are local wall-clock times by definition (see the timezone note in
%  itinerary.pl), so honouring an offset here would corrupt ground times.
parse_dt(Raw, dt(Y, Mo, D, H, Mi)) :-
    text_to_string(Raw, S0),
    split_string(S0, "Tt ", "", Parts),
    Parts = [DateS|Rest],
    split_string(DateS, "-", "", [Ys, Ms, Ds]),
    number_string(Y, Ys), number_string(Mo, Ms), number_string(D, Ds),
    integer(Y), integer(Mo), integer(D),
    between(1, 12, Mo), between(1, 31, D),
    (   Rest = [TimeS0|_]
    ->  clock_prefix(TimeS0, TimeS),
        split_string(TimeS, ":", "", [Hs, Mis|_]),
        number_string(H, Hs), number_string(Mi, Mis),
        integer(H), integer(Mi),
        between(0, 23, H), between(0, 59, Mi)
    ;   H = 0, Mi = 0
    ).

% Keep the leading digits and colons and drop whatever zone designator
% follows, so "10:25Z", "10:25:00" and "10:25-05:00" all read as 10:25.
clock_prefix(S0, S) :-
    string_codes(S0, Cs),
    clock_codes(Cs, Kept),
    string_codes(S, Kept).

clock_codes([C|T], [C|R]) :-
    ( code_type(C, digit) ; C == 0': ), !,
    clock_codes(T, R).
clock_codes(_, []).
