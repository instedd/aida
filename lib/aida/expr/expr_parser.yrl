Nonterminals
  Literal
  Expr
  Call
  CallArgs
  Variable
  Self
  BinaryOp
  UnaryOp
  Attribute
  .

Terminals
  integer
  string
  ident
  self
  '(' ')' ',' '${' '}'
  '=' '<' '<=' '>' '>=' '!=' 'and' 'or' '+' '-' '*' 'div' 'mod'
  .

Rootsymbol Expr.

Expr -> Literal : '$1'.
Expr -> BinaryOp : '$1'.
Expr -> UnaryOp : '$1'.
Expr -> Call : '$1'.
Expr -> Variable : '$1'.
Expr -> Attribute : '$1'.
Expr -> Self : '$1'.
Expr -> '(' Expr ')' : '$2'.

Literal -> integer : build_literal('$1').
Literal -> string : build_literal('$1').

BinaryOp -> Expr '=' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '<' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '<=' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '>' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '>=' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '!=' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr 'and' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr 'or' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '+' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '-' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr '*' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr 'div' Expr : build_binary_Op('$1', '$2', '$3').
BinaryOp -> Expr 'mod' Expr : build_binary_Op('$1', '$2', '$3').

UnaryOp -> '-' Expr : build_unary_op('$1', '$2').

CallArgs -> '$empty' : [].
CallArgs -> Expr : ['$1'].
CallArgs -> Expr ',' CallArgs : ['$1' | '$3'].
Call -> ident '(' CallArgs ')' : build_call('$1', '$3').

Variable -> '${' ident '}' : build_variable('$2').
Attribute -> ident : build_attribute('$1').
Self -> self : build_self().

Left 1 'and' 'or'.
Nonassoc 2 '=' '!=' '<' '<=' '>' '>='.
Left 3 '+' '-'.
Left 4 '*' 'div' 'mod'.

Erlang code.

build_literal({Type, Value}) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Literal', type => Type, value => Value}.

build_binary_Op(Left, {Op, _}, Right) ->
  #{'__struct__' => 'Elixir.Aida.Expr.BinaryOp', left => Left, op => Op, right => Right}.

build_unary_op({Op, _}, Value) ->
  #{'__struct__' => 'Elixir.Aida.Expr.UnaryOp', op => Op, value => Value}.

build_call({ident, Id}, Args) ->
  Name = erlang:binary_to_atom(Id, utf8),
  #{'__struct__' => 'Elixir.Aida.Expr.Call', name => Name, args => Args}.

build_variable({ident, Id}) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Variable', name => Id}.

build_attribute({ident, Id}) ->
  #{'__struct__' => 'Elixir.Aida.Expr.Attribute', name => Id}.

build_self() ->
  #{'__struct__' => 'Elixir.Aida.Expr.Self'}.
