:- module(booking_codes,
          [ booking_code/4,
            booking_column/1,
            column_name/2,
            premium_economy_code/2,
            business_alternate_code/2,
            first_alternate_code/1,
            middle_east_business_code/2,
            carrier_has_codes/1
          ]).

/** <module> Section 5(b) booking codes.

    The class an Explorer fare books into, per carrier and cabin. Like every
    other table here it carries no logic; src/rules/r05_booking.pl decides what
    a code being present or absent means.

    Two columns for business, because section 5(b) publishes two. DONE* is the
    fare basis this validator reports (see data/limits.pl: IONE3 is offered from
    select markets only), and IONE3 is the other one; a ticket in either column
    is booked in a code the rule names, so both are the applicable code for a
    business fare and the report says which is which.

    Scope is `any` unless the carrier publishes separate domestic rows, which
    only AY, JL and NU do. It is decided by whether a sector stays inside one
    country -- deliberately not by annotate.pl's `international` field, which
    carries 4(f)'s "travel between USA and Canada is not counted as
    international" exception and would read a Helsinki-Stockholm sector as
    domestic for no reason connected to this rule.
*/

%! booking_column(?Column) is nondet.
%  In fare order, worst-cabin last, which is the order the alternates below
%  fall back through.
booking_column(first).
booking_column(business_done).
booking_column(business_ione3).
booking_column(economy).

%! column_name(?Column, ?Name) is nondet.
%  How a column is written in a sentence. The atoms are table keys; nobody
%  says "business_done" out loud.
column_name(first,          'First').
column_name(business_done,  'Business on a DONE fare').
column_name(business_ione3, 'Business on an IONE3 fare').
column_name(economy,        'Economy').

% "| Carrier / service | First | Business — DONE* | Business — IONE3 | Economy |"
%
% Written a row at a time rather than as a group of carriers sharing a row, so
% that a carrier moving column is a one-line diff and a reader can check any
% single carrier against the rule text without unpicking a grouping.
term_expansion(row(Carriers, Scope, First, DoneB, IoneB, Economy), Facts) :-
    findall(booking_code(C, Scope, Column, Code),
            ( member(C, Carriers),
              member(Column-Code, [ first-First, business_done-DoneB,
                                    business_ione3-IoneB, economy-Economy ]) ),
            Facts).

:- discontiguous booking_code/4.

row([aa, ba, cx, mh, qf, qr], any,           a, d, i, l).
row([as, at, fj, ib, rj, ul], any,           d, d, i, l).
row([ay],                     international, d, d, i, l).
row([ay],                     domestic,      y, y, y, l).
row([jl],                     international, a, d, i, l).
row([nu],                     international, e, e, e, l).
row([jl, nu],                 domestic,      a, d, i, l).
row([wy],                     any,           a, d, i, l).

%! carrier_has_codes(?Carrier) is nondet.
%  True when 5(b) publishes a row for this carrier at all. Every 4(j) eligible
%  carrier has one; an affiliate flying under its parent's code does not, and
%  neither does JQ or QQ.
carrier_has_codes(C) :- booking_code(C, _, _, _), !.

%! premium_economy_code(?Carrier, ?Code) is nondet.
%  The second table in 5(b). Premium economy is not a fare basis of its own --
%  section 12 sells it as a per-sector surcharge over an economy fare, which is
%  what src/pricing.pl prices -- so these are the codes an economy Explorer fare
%  books into when that surcharge is paid.
premium_economy_code(aa, p).   % AA Premium Economy
premium_economy_code(ba, t).   % BA World Traveller Plus
premium_economy_code(ib, t).   % IB Premium Economy
premium_economy_code(cx, r).   % CX Premium Economy
premium_economy_code(qf, r).   % QF Premium Economy
premium_economy_code(jl, e).   % JL Premium Economy
premium_economy_code(nu, e).   % NU Premium Economy
premium_economy_code(rj, w).   % RJ Premium Economy

%! business_alternate_code(?Carrier, ?Code) is nondet.
%  "Passengers travelling on DONE* Business Class fares may book B Class
%  (except AA) or H Class on AA."
business_alternate_code(aa, h) :- !.
business_alternate_code(C, b) :- carrier_has_codes(C).

%! first_alternate_code(?Code) is nondet.
%  "Where the applicable booking class for the lower class is not available,
%  passengers travelling on First Class fares may book Y Class."
first_alternate_code(y).

%! middle_east_business_code(?Carrier, ?Code) is nondet.
%  "EXCEPTION: For services within the Middle East, where no Business Class is
%  offered, Business Class passengers may book and travel in A Class on QR,
%  subject to availability. This provision does not apply on any flight where
%  Business Class exists but is unavailable for booking."
%
%  The second sentence is why this is a flag and not a pass: the itinerary can
%  show a sector inside the Middle East and cannot show whether that particular
%  flight has a business cabin.
middle_east_business_code(qr, a).
