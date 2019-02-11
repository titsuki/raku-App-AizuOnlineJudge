use DateTime::Parse;

my regex cookie-name { <[\x1F..\xFF] - [() \< \> @,;: \\ \x22 /\[\] ?={} \x20 \x1F \x7F]>+ };
subset CookieName of Str where /^ <cookie-name> $/;

my regex octet { <[\x21
                  \x23..\x2B
                  \x2D..\x3A
                  \x3C..\x5B
                  \x5D..\x7E]>*};
my regex cookie-value { [ <octet> || '("' <octet> '")' ] };
subset CookieValue of Str where /^ <cookie-value> $/;
my regex name  { <[\w\d]> (<[\w\d-]>* <[\w\d]>)* };
# In Domain regex first dot comes from
# RFC 6265 and is intended to be ignored.
my regex domain { '.'? (<name> ['.'<name>]*) }
subset Domain of Str where /^ <domain> $/;

my regex path { <[\x1F..\xFF] - [;]>+ }
subset Path of Str where /^ <path> $/;

grammar CookieString {
    token TOP          { <cookie-pair> [';' <cookie-av> ]* }
    token cookie-pair  { <cookie-name> '=' <cookie-value> }
    proto token cookie-av {*}
          token cookie-av:sym<expires>   { :i 'Expires=' [ <dt=DateTime::Parse::Grammar::rfc1123-date>    |
                                                           <dt=DateTime::Parse::Grammar::rfc850-date>     |
                                                           <dt=DateTime::Parse::Grammar::rfc850-var-date> |
                                                           <dt=DateTime::Parse::Grammar::asctime-date>    ] }
          token cookie-av:sym<max-age>   { :i 'Max-Age=' '-'? <[1..9]> <[0..9]>* }
          token cookie-av:sym<domain>    { :i 'Domain=' <domain> }
          token cookie-av:sym<path>      { :i 'Path=' <path> }
          token cookie-av:sym<secure>    { :i 'Secure' }
          token cookie-av:sym<httponly>  { :i 'HttpOnly' }
          token cookie-av:sym<extension> { :i <path> }
}

# JSESSIONID=716247A09F2455E9CEA30F16FF282DCA;path=\/;HttpOnly' ~~ cookie-name;
say "abc" ~~ /<[x1F..\xFF] - [() \< \> @,;: \\ \x22 /\[\] ?={} \x20 \x1F \x7F]>+/;
say "abc" ~~ CookieName;
say "JSESSIONID" ~~ CookieName;

say "716247A09F2455E9CEA30F16FF282DCA" ~~ CookieValue;
CookieString.parse("JSESSIONID=716247A09F2455E9CEA30F16FF282DCA;path=\/;HttpOnly").say;
