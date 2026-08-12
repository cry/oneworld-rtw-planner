:- module(earn_qff, []).

/** <module> Qantas Frequent Flyer, as a kernel plugin.

    Resolvers only. Every number is in data/earn/qff/, every decision about
    sequencing is in kernel.pl, and this file is what joins the two.

    Three route bases, in the order the published table means them to be read:
    the named region pairs, then Intra-USA Short Haul, which is a region group
    that is itself banded on distance, then the "All other flights" mileage
    bands. That third case is the fallback and the second is the reason
    route_basis/5 returns an opaque basis rather than "a region pair, else a
    band".

    Two things about the categories are worth reading before the code.

    *A category depends on the route as well as the class.* Five carriers
    publish different class-to-category rows for different parts of their
    network -- Fiji Airways inside Fiji, Japan Airlines inside Japan, Malaysia
    on its long-haul markets, SriLankan on named routes, and Qantas between its
    own domestic and international networks. Three of those are decided by the
    endpoints alone and are decided here. Malaysia's and SriLankan's are not,
    and cannot be from the tables in this repository: they are scoped to
    "Australia", "the UK" and "the Middle East", which the earning-table region
    page does not define, and inventing definitions for them would be a fifth
    geography taxonomy made up rather than read. Where a class falls in the same
    category on both candidate rows the answer is the same either way and is
    given; where it does not, the segment is undecided and says which two
    categories it is between, which is a smaller and more useful claim than
    picking one.

    *A published row can be empty.* Japan Airlines' within-Japan row says points
    are awarded on information Japan Airlines provides, and does not tabulate
    them. That is not an absence of earn. It reaches the reader as undecided,
    carrying the table's own words.
*/

:- use_module('../geo').
:- use_module('../carriers').
:- use_module('../../data/earn/qff/categories').
:- use_module('../../data/earn/qff/bands').
:- use_module('../../data/earn/qff/regions').
:- use_module('../../data/earn/qff/source').
:- use_module(library(apply)).
:- use_module(library(lists)).

:- multifile earn_kernel:earn_program/3.
:- multifile earn_kernel:currency/4.
:- multifile earn_kernel:eligible/4.
:- multifile earn_kernel:fare_bucket/4.
:- multifile earn_kernel:route_basis/5.
:- multifile earn_kernel:route_basis_edges/3.
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
% The candidate rows disagree, which happens only where one of them is scoped to
% a region nothing in this repository defines -- see the module comment. Naming
% both categories is a smaller claim than choosing one.
resolve(_, _, _, _, Categories, indeterminate(Why), null) :-
    findall(Name, ( member(C-_, Categories), category_label(C, Name) ), Names0),
    sort(Names0, Names),
    atomic_list_concat(Names, ' or ', List),
    format(atom(Why),
           'This class earns in ~w depending on the route, and the carrier scopes its rows to regions the published tables do not define.',
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
earn_kernel:term_label(region_band(_, _, Label), Label).
earn_kernel:term_label(region_pair(_, _, Label), Label).

category_label(discount_economy, 'Discount Economy').
category_label(economy,          'Economy').
category_label(flexible_economy, 'Flexible Economy').
category_label(premium_economy,  'Premium Economy').
category_label(business,         'Business').
category_label(first,            'First').

% --- which route basis ------------------------------------------------------

% Three bases, in the order the published table is meant to be read: the named
% region pairs first, then the one region group that is itself banded on
% distance, then the "All other flights" mileage bands as the fallback. This is
% why route_basis/5 returns an opaque basis rather than "a region pair, else a
% band" -- Intra-USA Short Haul is both at once.
earn_kernel:route_basis(qff, From, To, Miles, Basis) :-
    (   region_basis(From, To, Miles, Found)
    ->  Basis = Found
    ;   mileage_basis(Miles, Basis)
    ).

mileage_basis(Miles, Basis) :-
    (   partner_band(Band, Low, High),
        Miles >= Low,
        ( High == inf -> true ; Miles =< High )
    ->  band_label(Band, Label),
        Basis = mileage_band(Band, Label)
    ;   format(atom(Why), 'No mileage band covers ~w miles.', [Miles]),
        Basis = indeterminate(Why)
    ).

% Both endpoints inside one banded region -- Intra-USA Short Haul, and only up
% to 750 miles. A longer intra-USA sector has no row here and falls through to
% a named pair or to the global bands, which is what the published table does.
region_basis(From, To, Miles, region_band(Region, Band, Label)) :-
    region_pair_band(Region, Band, _, _),
    in_region(From, Region),
    in_region(To, Region),
    Band = band(Low, High),
    Miles >= Low, Miles =< High,
    !,
    region_label(Region, RegionLabel),
    format(atom(Label), '~w, ~D to ~D miles', [RegionLabel, Low, High]).
% A named pair. "Between X and Y" is symmetric, so both orders are tried.
region_basis(From, To, _Miles, Basis) :-
    candidate_pairs(From, To, Pairs),
    Pairs \== [],
    maplist(pair_rates, Pairs, RateSets),
    sort(RateSets, Distinct),
    (   Distinct = [_]
    ->  Pairs = [Pair|_],
        % Named the way the table names it -- group heading first, row second --
        % rather than in the direction of travel, so an outbound sector and its
        % return read as the one row they are.
        published_order(Pair, RF-RT),
        pair_name(RF, RT, Label),
        Basis = region_pair(RF, RT, Label)
    ;   % Two published rows could describe this sector and they disagree. Both
        % are named rather than one being chosen, because choosing would be a
        % guess wearing the same clothes as an answer.
        findall(Name,
                (   member(Pair, Pairs),
                    published_order(Pair, RF-RT),
                    pair_name(RF, RT, Name)
                ),
                Names0),
        sort(Names0, Names),
        atomic_list_concat(Names, '; ', List),
        format(atom(Why),
               'More than one row of the region table covers this sector and they do not agree: ~w.',
               [List]),
        Basis = indeterminate(Why)
    ).

published_order(RF-RT, Ordered) :-
    (   region_pair(RF, RT, _, _)
    ->  Ordered = RF-RT
    ;   Ordered = RT-RF
    ).

pair_name(RF, RT, Name) :-
    region_label(RF, LF),
    region_label(RT, LT),
    format(atom(Name), '~w and ~w', [LF, LT]).

candidate_pairs(From, To, Pairs) :-
    findall(RF-RT,
            (   in_region(From, RF),
                in_region(To, RT),
                (   region_pair(RF, RT, _, _)
                ;   region_pair(RT, RF, _, _)
                )
            ),
            Pairs0),
    sort(Pairs0, Pairs).

% Every rate the pair publishes, so two candidate pairs can be compared as
% wholes. Comparing one category would call two rows equal that differ in
% another cabin.
pair_rates(RF-RT, Rates) :-
    earn_categories(Categories),
    findall(Category-R,
            (   member(Category, Categories),
                (   region_pair(RF, RT, Category, R)
                ->  true
                ;   region_pair(RT, RF, Category, R)
                )
            ),
            Rates).

%! in_region(+Airport, ?Region) is nondet.
%  Places are matched on place_key/2, so a region naming New York covers JFK,
%  LGA, EWR and SWF -- which is what the published table means by a city, and
%  the same folding 4(i) and 4(c) are written in.
in_region(Airport, Region) :-
    region_places(Region, Places),
    place_key(Airport, Key),
    memberchk(Key, Places).
in_region(Airport, Region) :-
    region_countries(Region, Countries),
    airport_country(Airport, Country),
    memberchk(Country, Countries).

% Only a basis that read the distance has an edge to be near.
earn_kernel:route_basis_edges(qff, mileage_band(_, _), Edges) :- band_edges(Edges).
earn_kernel:route_basis_edges(qff, region_band(_, _, _), Edges) :- region_pair_edges(Edges).

earn_kernel:accrual(qff, category(Category), mileage_band(Band, _), _Carrier, Rates) :-
    band_accrual(Band, Category, Rates).
earn_kernel:accrual(qff, category(Category), region_band(Region, Band, _), _Carrier, Rates) :-
    region_pair_band(Region, Band, Category, Rates).
earn_kernel:accrual(qff, category(Category), region_pair(RF, RT, _), _Carrier, Rates) :-
    (   region_pair(RF, RT, Category, Rates)
    ->  true
    ;   region_pair(RT, RF, Category, Rates)
    ).

% --- provenance -------------------------------------------------------------

earn_kernel:program_source(qff, Table, Source) :- qff_source(Table, Source).
earn_kernel:program_note(qff, Note) :- qff_note(Note).
