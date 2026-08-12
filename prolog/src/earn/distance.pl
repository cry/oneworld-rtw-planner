:- module(earn_distance, [sector_distance/3, near_boundary/3, boundary_tolerance/1]).

/** <module> Great-circle distance between two airports, in statute miles.

    Shared by every earning programme, because every one of them bands or zones
    on distance and none of them publishes the distances it uses.

    That last point is the whole reason this module carries a warning with its
    answer. What an airline bands on is *ticketed mileage*, which comes from a
    published table and is not a great-circle distance: it rounds, it sometimes
    follows a routing rather than the shortest path, and on a few city pairs it
    differs from the great circle by enough to change the band. Everywhere else
    the two agree to well within the width of a band, so a great circle is a
    good answer -- and near an edge it is exactly where a good answer is not
    good enough. So near_boundary/3 flags a sector sitting within
    boundary_tolerance/1 of a band or zone edge, the kernel carries the flag
    into the register, and the reader is told which number to go and check.

    The module name is `earn_distance` rather than `distance` because SWI module
    names are global and this file has no claim on a word that general. Its
    three siblings under src/earn/ are named the same way.
*/

:- use_module('../geo').

% The mean Earth radius, in statute miles. IUGG's R1 (6,371.0088 km) converted
% at the international mile of exactly 1,609.344 m. A sphere is the right model
% here: the ellipsoidal correction is under 0.3%, which is an order of magnitude
% inside the tolerance below, and the tables being read are themselves rounded
% to the nearest published mile.
earth_radius_miles(3958.7613).

%! boundary_tolerance(-Fraction) is det.
%  How close to a band or zone edge counts as too close to trust. 1.5% of the
%  distance -- wide enough to cover the gap between a great circle and a
%  ticketed mileage on the pairs where they disagree, narrow enough that it
%  fires on a handful of sectors rather than on most of them.
boundary_tolerance(0.015).

%! sector_distance(+From, +To, -Miles) is semidet.
%  Fails when either endpoint has no coordinates, which is what makes an
%  unresolvable airport an `indeterminate` earn rather than a zero.
sector_distance(From, To, Miles) :-
    airport_coords(From, Lat1, Lon1),
    airport_coords(To, Lat2, Lon2),
    haversine(Lat1, Lon1, Lat2, Lon2, Miles0),
    Miles is round(Miles0).

haversine(Lat1, Lon1, Lat2, Lon2, Miles) :-
    Phi1 is Lat1 * pi / 180,
    Phi2 is Lat2 * pi / 180,
    DPhi is (Lat2 - Lat1) * pi / 180,
    DLambda is (Lon2 - Lon1) * pi / 180,
    A is sin(DPhi / 2) ** 2 + cos(Phi1) * cos(Phi2) * sin(DLambda / 2) ** 2,
    % atan2 rather than asin: asin loses precision on antipodal pairs, and a
    % round-the-world itinerary is the one input that reliably contains some.
    C is 2 * atan2(sqrt(A), sqrt(max(0, 1 - A))),
    earth_radius_miles(R),
    Miles is R * C.

%! near_boundary(+Miles, +Edges, -Edge) is semidet.
%  True when the distance sits within the tolerance of one of the given band or
%  zone edges. Edges is a list of numbers; `inf` and `0` are ignored, since the
%  open ends of a table are not edges anything can fall the wrong side of.
near_boundary(Miles, Edges, Edge) :-
    boundary_tolerance(Fraction),
    Window is Miles * Fraction,
    member(Edge, Edges),
    number(Edge),
    Edge > 0,
    abs(Miles - Edge) =< Window,
    !.
