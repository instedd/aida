Definitions.

Integer  = [0-9]+
WhiteSpace = [\s\t]
Ident = [a-z_]+

Rules.

{Integer} : {token, {integer, erlang:list_to_integer(TokenChars)}}.
\'[^\']*\' : {token, {string, parse_string(TokenChars)}}.
\= : {token, {cmp, '='}}.
\< : {token, {cmp, '<'}}.
\<= : {token, {cmp, '<='}}.
\> : {token, {cmp, '>'}}.
\>= : {token, {cmp, '>='}}.
\!= : {token, {cmp, '!='}}.
and : {token, {bool, 'and'}}.
or : {token, {bool, 'or'}}.
{WhiteSpace}+ : skip_token.
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
\+ : {token, {arith, '+'}}.
\- : {token, {arith, '-'}}.
\* : {token, {arith, '*'}}.
div : {token, {arith, 'div'}}.
mod : {token, {arith, 'mod'}}.
\, : {token, {',', TokenLine}}.
{Ident} : {token, {ident, erlang:list_to_binary(TokenChars)}}.
\$\{ : {token, {'${', TokenLine}}.
\} : {token, {'}', TokenLine}}.
\. : {token, {self, TokenLine}}.


Erlang code.

parse_string(Chars) ->
  Bytes = erlang:list_to_binary(Chars),
  Length = size(Bytes) - 2,
  <<_, String:Length/binary, _>> = Bytes,
  String.
