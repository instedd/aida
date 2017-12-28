Nonterminals
  Literal
  Expr
  Comparison
  Boolean
  Arith
  Call
  CallArgs
  Variable
  Self
  .

Terminals
  integer
  string
  cmp
  bool
  arith
  ident
  self
  '('
  ')'
  ','
  '${'
  '}'
  .

Rootsymbol Expr.

Expr -> Literal : '$1'.
Expr -> Comparison : '$1'.
Expr -> Boolean : '$1'.
Expr -> Arith : '$1'.
Expr -> Call : '$1'.
Expr -> Variable : '$1'.
Expr -> Self : '$1'.
Expr -> '(' Expr ')' : '$2'.

Literal -> integer : build_literal('$1').
Literal -> string : build_literal('$1').

Comparison -> Expr cmp Expr : build_comparison('$1', '$2', '$3').
Boolean -> Expr bool Expr : build_boolean('$1', '$2', '$3').
Arith -> Expr arith Expr : build_arith('$1', '$2', '$3').

CallArgs -> '$empty' : [].
CallArgs -> Expr : ['$1'].
CallArgs -> Expr ',' CallArgs : ['$1' | '$3'].
Call -> ident '(' CallArgs ')' : build_call('$1', '$3').

Variable -> '${' ident '}' : build_variable('$2').
Self -> self : build_self().

Left 1 bool.
Nonassoc 2 cmp.
Left 3 arith.

Erlang code.

build_literal({Type, Value}) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Literal', type => Type, value => Value}.

build_comparison(Left, {cmp, Op}, Right) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Comparison', op => Op, left => Left, right => Right}.

build_boolean(Left, {bool, Op}, Right) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Boolean', op => Op, left => Left, right => Right}.

build_arith(Left, {arith, Op}, Right) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Arith', op => Op, left => Left, right => Right}.

build_call({ident, Id}, Args) ->
  Name = erlang:binary_to_atom(Id, utf8),
  #{'__struct__' => 'Elixir.Aida.Expr.Call', name => Name, args => Args}.

build_variable({ident, Id}) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Variable', name => Id}.

build_self() ->
  #{'__struct__' => 'Elixir.Aida.Expr.Self'}.
