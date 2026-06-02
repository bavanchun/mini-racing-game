// Money formatting helpers shared across screens so currency renders
// consistently (single source of truth for the `$` prefix and sign rules).

/// Formats a wallet/stake amount, e.g. `formatMoney(50)` → `"$50"`.
String formatMoney(int v) => '\$$v';

/// Formats a net change with an explicit sign and the `$` after it, e.g.
/// `formatSigned(30)` → `"+$30"`, `formatSigned(-50)` → `"-$50"`.
String formatSigned(int v) => v < 0 ? '-\$${-v}' : '+\$$v';
