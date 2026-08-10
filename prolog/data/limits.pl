:- module(limits,
          [ ruleset_version/1,
            limit/2,
            free_segments/2,
            fare_basis/3,
            continent/1,
            traffic_conference/2,
            all_limits/1
          ]).

/** <module> Versioned numeric caps and tables from Rule 3015.

    No rule clause anywhere may hardcode a number; each one reads it from here.
    A future edition of the fare is then a change to this file plus tests
    rather than a rewrite. Citations point at parsed-rules-aug-2026.md.
*/

ruleset_version('27FEB26').

%! limit(?Name, ?Value) is nondet.
limit(min_segments,                     3).   % 4(h)
limit(max_segments,                    16).   % 4(h)
limit(min_stopovers,                    2).   % 8 note 1
limit(max_stopovers_origin_continent,   2).   % 8 note 2
limit(max_intl_dep_origin_country,      1).   % 4(f)
limit(max_intl_dep_origin_country_usa,  2).   % 4(f) exception
limit(max_intl_transfers_per_country,   4).   % 4(f)
limit(max_intercont_per_continent,      1).   % 4(e)
limit(max_intercont_relaxed,            2).   % 4(e) 1-3
limit(max_transcontinental_us,          1).   % 4(k)
limit(max_flights_to_alaska,            1).   % 4(k)
limit(max_flights_from_alaska,          1).   % 4(k)
limit(max_au_city_pair_flights,         1).   % 4(l)
limit(max_transoceanic_surface,         0).   % 4(g)
limit(max_transoceanic_surface_swp,     1).   % 4(g) exception
limit(min_continents,                   3).   % section 0 fare table
limit(max_continents,                   6).   % section 0 fare table
limit(min_stay_days_tc1,               10).   % 6
limit(max_stay_months,                 12).   % 7
limit(child_discount_percent,          75).   % 19
limit(infant_discount_percent,         10).   % 19
limit(child_min_age,                    2).   % 19
limit(child_max_age,                   11).   % 19

% Service limits. Not from the fare rule: these bound the work a single request
% can cause. Several rules are quadratic in the segment count (4(i) compares
% every pair), so the input is capped well above the 16 the fare permits but far
% below anything that could be used to make the validator spin.
limit(max_input_segments,             100).
limit(max_request_bytes,           131072).
limit(request_time_limit_seconds,      10).

% Validation runs in its own thread pool so that slow requests cannot starve
% the cheap endpoints -- see the note in server.pl. A full backlog is refused
% with 503 rather than queued without bound.
limit(validate_workers,                 8).
limit(validate_backlog,                64).

% Local wall-clock arithmetic: see the date line note in src/itinerary.pl. The
% span from UTC+14 to UTC-12 is 26 hours, so a sector whose arrival clock time
% precedes its departure by more than that cannot be a date line crossing.
limit(max_local_time_regression_hours, 26).

% Stopover thresholds. The fare rule never defines stopover-vs-transfer; these
% are the industry convention and are declared here so they are auditable and
% adjustable rather than buried in annotate.pl.
limit(stopover_hours_international,    24).
limit(stopover_hours_domestic_us_ca,    4).

%! free_segments(?Continent, ?Max) is nondet.
%  4(h) free flight segments permitted within each continent.
free_segments(africa,              4).
free_segments(asia,                4).
free_segments(europe_middle_east,  4).
free_segments(north_america,       6).
free_segments(south_america,       4).
free_segments(south_west_pacific,  4).

%! fare_basis(?Cabin, ?Continents, ?Basis) is nondet.
%  Section 0. IONE3 is offered from select markets only, so DONE3 is the
%  fare basis reported for 3-continent business.
fare_basis(economy,  3, 'LONE3').
fare_basis(economy,  4, 'LONE4').
fare_basis(economy,  5, 'LONE5').
fare_basis(economy,  6, 'LONE6').
fare_basis(business, 3, 'DONE3').
fare_basis(business, 4, 'DONE4').
fare_basis(business, 5, 'DONE5').
fare_basis(business, 6, 'DONE6').
fare_basis(first,    3, 'AONE3').
fare_basis(first,    4, 'AONE4').
fare_basis(first,    5, 'AONE5').
fare_basis(first,    6, 'AONE6').

%! continent(?Continent) is nondet.
continent(C) :- free_segments(C, _).

%! traffic_conference(?Continent, ?TC) is nondet.
%  Section 0. This mapping is why 4(b) (a TC-level rule) and 4(e) (a
%  continent-level rule) must not be conflated -- see src/rules/r04_routing.pl.
traffic_conference(north_america,      tc1).
traffic_conference(south_america,      tc1).
traffic_conference(europe_middle_east, tc2).
traffic_conference(africa,             tc2).
traffic_conference(asia,               tc3).
traffic_conference(south_west_pacific, tc3).

%! all_limits(-Pairs) is det.
%  Every limit as Name-Value, for the /api/ruleset endpoint.
all_limits(Pairs) :-
    findall(N-V, limit(N, V), Pairs0),
    msort(Pairs0, Pairs).
