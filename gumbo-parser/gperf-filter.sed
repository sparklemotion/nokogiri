#!/usr/bin/sed -f

4{/^$/i\
/* Filtered by: gperf-filter.sed */
}

/^#ifdef __GNUC__$/,/^static unsigned int$/ {
    /^static/i\
static inline unsigned int
    d
}

/^#if \!((' ' == 32) &&/,/^#endif/d
/^#ifndef GPERF_DOWNCASE/,/^#endif/d
/^#ifndef GPERF_CASE_MEMCMP/,/^#endif/d
/^\#line/d
4,31 {/^$/d}

s/!gperf_case_memcmp *(/!gumbo_ascii_strncasecmp(/
