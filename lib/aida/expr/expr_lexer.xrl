Definitions.

Integer  = -?[0-9]+
WhiteSpace = [\s\t]
Ident = [a-z_]+

Rules.

{Integer} : {token, {integer, erlang:list_to_integer(TokenChars)}}.
'[^']*' : {token, {string, parse_string(TokenChars)}}.
"[^"]*" : {token, {string, parse_string(TokenChars)}}.
\x{201c}[^\x{201d}]*\x{201d} : {token, {string, parse_string(TokenChars)}}.
\x{2018}[^\x{2019}]*\x{2019} : {token, {string, parse_string(TokenChars)}}.
= : {token, {'=', TokenLine}}.
< : {token, {'<', TokenLine}}.
<= : {token, {'<=', TokenLine}}.
> : {token, {'>', TokenLine}}.
>= : {token, {'>=', TokenLine}}.
!= : {token, {'!=', TokenLine}}.
and : {token, {'and', TokenLine}}.
or : {token, {'or', TokenLine}}.
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
\+ : {token, {'+', TokenLine}}.
- : {token, {'-', TokenLine}}.
\* : {token, {'*', TokenLine}}.
div : {token, {'div', TokenLine}}.
mod : {token, {'mod', TokenLine}}.
, : {token, {',', TokenLine}}.
{Ident} : {token, {ident, erlang:list_to_binary(TokenChars)}}.
\${ : {token, {'${', TokenLine}}.
} : {token, {'}', TokenLine}}.
\. : {token, {self, TokenLine}}.
{WhiteSpace}+ : skip_token.

Erlang code.

parse_string(Chars) ->
  erlang:list_to_binary(lists:droplast(tl(Chars))).
