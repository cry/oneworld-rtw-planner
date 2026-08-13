:- module(test_network, []).

/** <module> The flown-network table.

    The first thing to say about this suite is what it deliberately does
    *not* assert.

    The obvious test to write here is that every sector in every fixture under
    test/fixtures/ exists in the table -- those are known-good itineraries, so
    surely they are flyable. They are not. They are rule-exercising
    constructions: `mut_input_errors` routes to an airport that is not in
    airports.pl at all, `mut_carrier` names a carrier 4(j) excludes precisely
    so that it can be rejected, six sectors across the surface fixtures name no
    carrier, and several pairs were invented to reach a rule rather than to be
    bought. Such a test fails on the first run, acquires an exclusion list, and
    the exclusion list then quietly absorbs every extraction regression it was
    written to catch.

    So the coverage question is asked two honest ways instead: a floor that
    every eligible carrier must clear, and a small sample verified by hand in
    test/flyable.json. Between them they fail loudly if a refresh drops a hub's
    table, which is the regression actually worth catching.
*/

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module('../src/network').
:- use_module('../src/geo').
:- use_module('../src/carriers').

% SWI 10 moved JSON out of the HTTP package; test/support.pl explains why this
% is the only spelling silent on both.
:- if(exists_source(library(json))).
:- use_module(library(json)).
:- else.
:- use_module(library(http/json)).
:- endif.

:- begin_tests(network_table).

% --- referential integrity -------------------------------------------------
%
% The two ways the table can be internally wrong. Both would otherwise show up
% as a query that silently answers nothing: an unknown code or a stray carrier
% does not raise, it just fails to join.

test(every_code_is_a_known_airport) :-
    findall(F-T,
            ( flown_network:service(_, F, T, _),
              \+ ( airport_known(F), airport_known(T) ) ),
            Unknown),
    assertion(Unknown == []).

test(every_carrier_is_in_the_4j_vocabulary) :-
    findall(C, ( flown_network:service(C, _, _, _), \+ carrier_code(C) ), Bad0),
    sort(Bad0, Bad),
    assertion(Bad == []).

test(window_subjects_are_known_too) :-
    findall(C-F-T,
            ( flown_network:service_window(C, F, T, _),
              \+ ( carrier_code(C), airport_known(F), airport_known(T) ) ),
            Bad),
    assertion(Bad == []).

% --- the coverage floor ----------------------------------------------------
%
% Deliberately conservative. This is a smoke alarm for a parser that stopped
% emitting, not a measurement of the network -- a threshold set near the true
% count would fail every time an airline trimmed a route, and would then be
% raised or deleted rather than investigated.

test(every_eligible_carrier_flies_something) :-
    eligible_carriers(Cs),
    findall(C, ( member(C, Cs), \+ flown_network:service(C, _, _, _) ), Silent),
    assertion(Silent == []).

test(the_large_networks_are_not_a_handful_of_sectors) :-
    forall(member(C, [aa, ba, qf, cx, qr]),
           ( aggregate_all(count, flown_network:service(C, _, _, _), N),
             assertion(N >= 50) )).

test(the_table_is_a_network_rather_than_a_sample) :-
    aggregate_all(count, flown_network:service(_, _, _, _), N),
    assertion(N >= 2000).

% --- the hand-verified sample ----------------------------------------------
%
% Asserted in either direction. The table is directed and built from the
% articles at both ends, so a real sector normally yields two facts -- but one
% malformed article should surface as an asymmetry count below, not as a
% failure here, or this test stops being about extraction and starts being
% about a single Wikipedia edit.

test(the_hand_verified_sectors_are_all_present) :-
    flyable_sectors(Sectors),
    assertion(Sectors \== []),
    findall(C-F-T,
            ( member(C-F-T, Sectors),
              \+ flown_network:service(C, F, T, _),
              \+ flown_network:service(C, T, F, _) ),
            Missing),
    assertion(Missing == []).

% A test of the sample rather than of the table. The sample is only a coverage
% floor while it still names every carrier; if a member is added to 4(j) and
% nobody adds a sector for it here, the floor silently stops covering it and the
% suite would go on passing while one sixteenth of the alliance went unchecked.
test(the_sample_names_every_eligible_carrier) :-
    flyable_sectors(Sectors),
    findall(C, member(C-_-_, Sectors), Cs0),
    sort(Cs0, Sampled),
    eligible_carriers(Eligible),
    subtract(Eligible, Sampled, Unsampled),
    assertion(Unsampled == []).

% And the codes must be real, or a failure above would point at the extractor
% when the fault was a typo in the fixture.
test(the_sample_names_only_known_airports) :-
    flyable_sectors(Sectors),
    findall(F-T,
            ( member(_-F-T, Sectors),
              \+ ( airport_known(F), airport_known(T) ) ),
            Bad),
    assertion(Bad == []).

flyable_sectors(Sectors) :-
    module_property(test_network, file(Here)),
    file_directory_name(Here, Dir),
    atomic_list_concat([Dir, '/flyable.json'], Path),
    setup_call_cleanup(
        open(Path, read, S, [encoding(utf8)]),
        json_read_dict(S, Dict, [end_of_file(error)]),
        close(S)),
    findall(C-F-T,
            ( member(Row, Dict.sectors),
              downcase_code(Row.carrier, C),
              downcase_code(Row.from, F),
              downcase_code(Row.to, T) ),
            Sectors).

downcase_code(Text, Atom) :- atom_string(A, Text), downcase_atom(A, Atom).

% --- the shape of a fact ---------------------------------------------------

test(season_is_one_of_three) :-
    findall(S, ( flown_network:service(_, _, _, S),
                 \+ memberchk(S, [year_round, seasonal, unknown]) ), Bad0),
    sort(Bad0, Bad),
    assertion(Bad == []).

% Seasonal marking is incomplete upstream, which is the whole reason there are
% three values rather than two. If the table were entirely `year_round` the
% extractor would be defaulting rather than reading, and every unmarked
% seasonal route would have been quietly promoted to year-round service.
test(the_season_field_is_read_rather_than_defaulted) :-
    aggregate_all(count, flown_network:service(_, _, _, year_round), Y),
    aggregate_all(count, flown_network:service(_, _, _, seasonal), S),
    assertion(Y > 0),
    assertion(S > 0).

% --- directedness ----------------------------------------------------------

% Reported, never repaired. Symmetrising would manufacture edges nothing
% sourced; the threshold is here so that a handful of genuine one-way sectors
% pass and a section that stopped parsing does not.
test(asymmetry_is_within_threshold) :-
    aggregate_all(count, flown_network:service(_, _, _, _), Total),
    Total > 0,
    findall(C-F-T,
            ( flown_network:service(C, F, T, _), \+ flown_network:service(C, T, F, _) ),
            OneWay),
    length(OneWay, N),
    Ratio is N / Total,
    assertion(Ratio < 0.25).

% A future or terminated route is recorded so the diff shows it, and excluded
% from the current network so nothing proposes a sector that cannot be
% ticketed today.
test(windowed_service_is_not_current_service) :-
    findall(C-F-T,
            ( flown_network:service_window(C, F, T, _), flown_network:service(C, F, T, _) ),
            Both),
    assertion(Both == []).

% --- provenance ------------------------------------------------------------

test(the_generated_table_declares_its_encoding) :-
    module_property(test_network, file(Here)),
    file_directory_name(Here, Dir),
    atomic_list_concat([Dir, '/../data/generated/services.pl'], Path),
    read_file_to_string(Path, Text, [encoding(utf8)]),
    assertion(sub_string(Text, _, _, _, ":- encoding(utf8).")).

% The snapshot has a stated age or the reader cannot weigh what it says: a
% table with no date is a claim about the world with no way to check how old it
% is. network_manifest/1 must answer, and must answer with something.
test(the_table_carries_a_manifest) :-
    assertion(network_manifest(_)),
    network_manifest(M),
    assertion(nonvar(M)),
    assertion(M \== []).

:- end_tests(network_table).

:- begin_tests(network_vocabulary).

% The alias file exists to cover Wikipedia spellings that carrier_name/2 and
% affiliate/3 do not. Every designator it can produce must still be one 4(j)
% names, or the extractor and the validator would disagree about the same
% flight -- the constructor proposing sectors the validator then flags.
test(alias_designators_are_all_4j_carriers) :-
    alias_designators(Codes),
    findall(C, ( member(C, Codes), \+ carrier_code(C) ), Bad),
    assertion(Bad == []).

alias_designators(Codes) :-
    module_property(test_network, file(Here)),
    file_directory_name(Here, Dir),
    atomic_list_concat([Dir, '/../data/network/carrier_aliases.json'], Path),
    (   exists_file(Path)
    ->  setup_call_cleanup(
            open(Path, read, S, [encoding(utf8)]),
            json_read_dict(S, Dict, [end_of_file(error)]),
            close(S)),
        findall(C, alias_code(Dict, C), Codes0),
        sort(Codes0, Codes)
    ;   Codes = []
    ).

alias_code(Dict, Code) :-
    get_dict(aliases, Dict, Aliases),
    dict_pairs(Aliases, _, Pairs),
    member(_-V, Pairs),
    atom_string(A, V), downcase_atom(A, Code).
alias_code(Dict, Code) :-
    get_dict(brands, Dict, Brands),
    dict_pairs(Brands, _, Pairs),
    member(_-List, Pairs),
    member(V, List),
    atom_string(A, V), downcase_atom(A, Code).

:- end_tests(network_vocabulary).
