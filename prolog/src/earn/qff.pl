:- module(earn_qff, []).

/** <module> Qantas Frequent Flyer, as a kernel plugin.

    Resolvers only. Every number is in data/earn/qff/, every decision about
    sequencing is in kernel.pl, and this file is what joins the two.

    Phase 1 resolves the mileage-band fallback and nothing else. The region-pair
    table -- thirteen groups of named endpoints, which take precedence over the
    bands -- arrives in phase 2 as a second clause of route_basis/5 and needs no
    change here or in the kernel. That is the property the plugin interface was
    built for, so it is worth being explicit that phase 2 is meant to be a data
    change plus one clause.

    Two things about the categories are worth reading before the code.

    *A category depends on the route as well as the class.* Five carriers
    publish different class-to-category rows for different parts of their
    network -- Fiji Airways inside Fiji, Japan Airlines inside Japan, Malaysia
    on its long-haul markets, SriLankan on named routes, and Qantas between its
    own domestic and international networks. Two of those five are decided by
    the endpoints alone and are decided here; two need the region tables and
    cannot be until phase 2. Where a class falls in the same category on both
    candidate rows, the answer is the same either way and is given. Where it
    does not, the segment is undecided and says which two categories it is
    between -- which is a smaller and more useful claim than picking one.

    *A published row can be empty.* Japan Airlines' within-Japan row says points
    are awarded on information Japan Airlines provides, and does not tabulate
    them. That is not an absence of earn. It reaches the reader as undecided,
    carrying the table's own words.
*/

:- use_module('../geo').
:- use_module('../carriers').
:- use_module('../../data/earn/qff/categories').
:- use_module('../../data/earn/qff/bands').
:- use_module('../../data/earn/qff/source').
:- use_module(library(apply)).
:- use_module(library(lists)).

:- multifile earn_kernel:earn_program/3.
:- multifile earn_kernel:currency/4.
:- multifile earn_kernel:eligible/4.
:- multifile earn_kernel:fare_bucket/4.
:- multifile earn_kernel:route_basis/5.
:- multifile earn_kernel:route_basis_edges/2.
:- multifile earn_kernel:accrual/5.
:- multifile earn_kernel:program_source/3.
:- multifile earn_kernel:program_note/2.
:- multifile earn_kernel:term_label/2.

earn_kernel:earn_program(qff, 'Qantas Frequent Flyer', qff).

% Points take the tier bonus and Status Credits do not, which is a fact about
% the programme and so lives here rather than in the kernel.
earn_kernel:currency(qff, points, 'Qantas Points',
                     [ rounding(nearest), scope(per_segment), bonus_applies(true) ]).
earn_kernel:currency(qff, status_credits, 'Status Credits',
                     [ rounding(nearest), scope(per_segment), bonus_applies(false) ]).

% --- eligibility -----------------------------------------------------------

% "Qantas Points and Status Credits are earned on all eligible booking classes,
% except on codeshare flights operated by an airline other than Qantas or a
% oneworld member airline."
%
% So the marketing carrier selects the table and the *operating* carrier decides
% whether anything is earned at all. An unnamed operator is therefore undecided
% rather than zero -- the same field 4(j) treats as a warning, treated here as
% the thing it actually blocks.
earn_kernel:eligible(qff, S, _A, Outcome) :-
    Marketing = S.marketing,
    Operating = S.operating,
    (   Marketing == unknown
    ->  Outcome = indeterminate('No marketing carrier, so there is no earning table to read this segment against.')
    ;   \+ earn_category(Marketing, _, _, _),
        \+ earn_category_unpublished(Marketing, _, _)
    ->  iata(Marketing, U),
        format(atom(Why), 'Qantas Frequent Flyer publishes no earning table for ~w.', [U]),
        Outcome = ineligible(Why)
    ;   Operating == unknown
    ->  Outcome = indeterminate('No operating carrier. Earn is refused on a codeshare flown outside oneworld, so this cannot be settled until the operator is named.')
    ;   \+ oneworld_operator(Operating)
    ->  iata(Operating, U),
        format(atom(Why),
               'The flight is operated by ~w, which is outside oneworld, so a codeshare on it earns nothing.',
               [U]),
        Outcome = ineligible(Why)
    ;   Outcome = eligible
    ).

oneworld_operator(C) :- eligible_carrier(C), !.
oneworld_operator(C) :- affiliate(_, C, _), !.
oneworld_operator(C) :- memberchk(C, [jq, qq]).

% --- which category ---------------------------------------------------------

earn_kernel:fare_bucket(qff, S, Bucket, Basis) :-
    Carrier = S.marketing,
    Carrier \== unknown,
    Class = S.booking_class,
    (   Class == unknown
    ->  Bucket = indeterminate('The class this segment is sold in is not given, and the earn category is read from it.'),
        Basis = null
    ;   candidate_scopes(Carrier, S, Scopes),
        category_hits(Carrier, Scopes, Class, Categories),
        resolve(Carrier, S, Scopes, Class, Categories, Bucket, Basis)
    ).

category_hits(Carrier, Scopes, Class, Categories) :-
    findall(Category-Scope,
            ( member(Scope, Scopes), earn_category(Carrier, Scope, Class, Category) ),
            Categories).

resolve(Carrier, S, Scopes, Class, [], Bucket, null) :-
    !,
    (   member(Scope, Scopes),
        earn_category_unpublished(Carrier, Scope, Reason)
    ->  Bucket = indeterminate(Reason)
    ;   upcase_atom(Class, U),
        iata(Carrier, C),
        iata(S.from, F), iata(S.to, T),
        format(atom(Why),
               'Qantas Frequent Flyer lists no earn category for ~w in ~w on ~w-~w.',
               [C, U, F, T]),
        Bucket = indeterminate(Why)
    ).
resolve(_, _, _, _, Categories, category(Category), Basis) :-
    findall(C, member(C-_, Categories), Cs),
    sort(Cs, [Category]),
    !,
    memberchk(Category-Scope, Categories),
    scope_label(Scope, Basis).
% The candidate rows disagree, which can only happen where one of them is
% decided by a region table this phase does not have. Naming both categories is
% a smaller claim than choosing one, and it is also the exact thing phase 2
% makes go away.
resolve(_, _, _, _, Categories, indeterminate(Why), null) :-
    findall(Name, ( member(C-_, Categories), category_label(C, Name) ), Names0),
    sort(Names0, Names),
    atomic_list_concat(Names, ' or ', List),
    format(atom(Why),
           'This class earns in ~w depending on the route, and the route tables that decide which are not loaded.',
           [List]).

% Which rows of the table could describe this segment. `always` rows always can;
% a row scoped to a pair of endpoints can when the endpoints match; the residual
% "all other flights" row can when no endpoint-scoped row did; and a row scoped
% to a region cannot be ruled in or out at all until phase 2, so it stays a
% candidate and resolve/7 above decides what its presence means.
candidate_scopes(Carrier, S, Scopes) :-
    findall(Scope,
            (   earn_category(Carrier, Scope, _, _)
            ;   earn_category_unpublished(Carrier, Scope, _)
            ),
            All0),
    sort(All0, All),
    include(scope_applies(S, All), All, Scopes).

scope_applies(_, _, Scope) :- earn_scope(Scope, always), !.
scope_applies(_, _, Scope) :- earn_scope(Scope, region), !.
scope_applies(S, _, Scope) :- earn_scope(Scope, sector), !, sector_scope(Scope, S).
scope_applies(S, All, Scope) :-
    earn_scope(Scope, residual),
    \+ ( member(Other, All), earn_scope(Other, sector), sector_scope(Other, S) ).

sector_scope(international, S) :- both_countries(S, F, T), F \== T.
sector_scope(domestic,      S) :- both_countries(S, F, F).
sector_scope(within_fiji,   S) :- both_countries(S, 'FJ', 'FJ').
sector_scope(within_japan,  S) :- both_countries(S, 'JP', 'JP').

both_countries(S, F, T) :-
    F = S.from_country, T = S.to_country,
    F \== unknown, T \== unknown.

scope_label(all,           'all flights').
scope_label(all_other,     'all other flights').
scope_label(international, 'international flights').
scope_label(domestic,      'domestic flights').
scope_label(within_fiji,   'flights within Fiji').
scope_label(within_japan,  'flights within Japan').
scope_label(long_haul,     'the long-haul markets row').
scope_label(named_routes,  'the named-routes row').

% How this programme's own terms are written in the register. The kernel treats
% a bucket and a basis as opaque and would otherwise print the raw term.
earn_kernel:term_label(category(Category), Label) :- category_label(Category, Label).
earn_kernel:term_label(mileage_band(_, Label), Label).

category_label(discount_economy, 'Discount Economy').
category_label(economy,          'Economy').
category_label(flexible_economy, 'Flexible Economy').
category_label(premium_economy,  'Premium Economy').
category_label(business,         'Business').
category_label(first,            'First').

% --- which route basis ------------------------------------------------------

% Phase 1: the "All other flights" mileage bands. Phase 2 adds a clause above
% this one for the thirteen region-pair groups, which take precedence; the
% endpoints are already in the signature for it.
earn_kernel:route_basis(qff, _From, _To, Miles, Basis) :-
    (   partner_band(Band, Low, High),
        Miles >= Low,
        ( High == inf -> true ; Miles =< High )
    ->  band_label(Band, Label),
        Basis = mileage_band(Band, Label)
    ;   format(atom(Why), 'No mileage band covers ~w miles.', [Miles]),
        Basis = indeterminate(Why)
    ).

earn_kernel:route_basis_edges(qff, Edges) :- band_edges(Edges).

earn_kernel:accrual(qff, category(Category), mileage_band(Band, _), _Carrier, Rates) :-
    band_accrual(Band, Category, Rates).

% --- provenance -------------------------------------------------------------

earn_kernel:program_source(qff, Table, Source) :- qff_source(Table, Source).
earn_kernel:program_note(qff, Note) :- qff_note(Note).
