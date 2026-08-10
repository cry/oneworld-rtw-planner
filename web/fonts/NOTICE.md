# Embedded fonts

Both faces are bundled rather than fetched from a CDN: the validator is meant to run
offline and in a read-only container, and a font request would be the only outbound call
the page makes. Each file is the Latin subset of the variable font as published by
Google Fonts.

| File | Family | Axes | Copyright |
|---|---|---|---|
| `archivo-latin-var.woff2` | Archivo | `wght` 100–900, `wdth` 62–125 | Copyright 2020 The Archivo Project Authors (https://github.com/Omnibus-Type/Archivo) |
| `martianmono-latin-var.woff2` | Martian Mono | `wght` 100–800, `wdth` 75–112.5 | Copyright 2021 The Martian Mono Project Authors (https://github.com/evilmartians/mono) |

Both are licensed under the SIL Open Font License, Version 1.1, reproduced in `OFL.txt`.
The licence requires that notice and text travel with the font files; `web/` is copied
into the image whole, so they do.
