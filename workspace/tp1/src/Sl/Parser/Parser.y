{
{-# OPTIONS_GHC -Wno-name-shadowing #-}
module Sl.Parser.Parser
  ( parseProgram
  ) where

import qualified Sl.Lexer.Lexer as Lex hiding (lexer)
import Sl.Syntax.Syntax
}

%name parseProgram Program
%monad {Lex.Alex}{(>>=)}{return}
%tokentype { Lex.Token }
%error     { parseError }
%lexer {lexer}{Lex.Token _ Lex.TEOF}

--------------------------------------------------
-- PRECEDÊNCIA E ASSOCIATIVIDADE
--------------------------------------------------

%nonassoc IFX
%nonassoc ELSE

%left '&&'
%nonassoc '==' '!=' '<' '>' '<=' '>='
%left '+' '-'
%left '*' '/' '%'

--------------------------------------------------
-- TOKENS
--------------------------------------------------

%token
ident       { Lex.Token _ (Lex.TIdent $$) }
structid    { Lex.Token _ (Lex.TDataStructures $$) }
typekw      { Lex.Token _ (Lex.TType $$) }

int_lit     { Lex.Token _ (Lex.TIntNumber $$) }
float_lit   { Lex.Token _ (Lex.TFloatNumber $$) }
char_lit    { Lex.Token _ (Lex.TCharacter $$) }
string_lit  { Lex.Token _ (Lex.TString $$) }

STRUCT      { Lex.Token _ Lex.TStruct }
FUNC        { Lex.Token _ Lex.TFunc }
LET         { Lex.Token _ Lex.TLet }
PRINT       { Lex.Token _ Lex.TPrint }
IF          { Lex.Token _ Lex.TIf }
ELSE        { Lex.Token _ Lex.TElse }
WHILE       { Lex.Token _ Lex.TWhile }
FOR         { Lex.Token _ Lex.TFor }
RETURN      { Lex.Token _ Lex.TReturn }
NEW         { Lex.Token _ Lex.TNew }
TRUE        { Lex.Token _ Lex.TTrue }
FALSE       { Lex.Token _ Lex.TFalse }

'='         { Lex.Token _ Lex.TAssign }
'+'         { Lex.Token _ Lex.TPlus }
'-'         { Lex.Token _ Lex.TMinus }
'*'         { Lex.Token _ Lex.TTimes }
'/'         { Lex.Token _ Lex.TDiv }
'%'         { Lex.Token _ Lex.TMod }

'=='        { Lex.Token _ Lex.TEq }
'!='        { Lex.Token _ Lex.TNeq }
'<'         { Lex.Token _ Lex.TLt }
'>'         { Lex.Token _ Lex.TGt }
'<='        { Lex.Token _ Lex.TLeq }
'>='        { Lex.Token _ Lex.TGeq }
'&&'        { Lex.Token _ Lex.TAnd }

'('         { Lex.Token _ Lex.TLParen }
')'         { Lex.Token _ Lex.TRParen }
'{'         { Lex.Token _ Lex.TLBrace }
'}'         { Lex.Token _ Lex.TRBrace }
'['         { Lex.Token _ Lex.TLBracket }
']'         { Lex.Token _ Lex.TRBracket }

','         { Lex.Token _ Lex.TComma }
';'         { Lex.Token _ Lex.TSemi }
':'         { Lex.Token _ Lex.TColon }
'::'        { Lex.Token _ Lex.TDoubleColon }
'.'         { Lex.Token _ Lex.TDot }


--------------------------------------------------
-- GRAMÁTICA
--------------------------------------------------

%%

Program
  : DefList                         { Program $1 }

DefList
  : Def DefList                     { $1 : $2 }
  |                                 { [] }

Def
  : Function                        { FuncDef $1 }
  | Struct                          { StructDef $1 }

--------------------------------------------------
-- STRUCT
--------------------------------------------------

Struct
  : STRUCT structid '{' FieldList '}'      { Struct  $2 $4 }

FieldList
  : Field FieldList                 { $1 : $2 }
  |                                 { [] }

Field
  : ident ':' Type ';'              { Field $1 $3 }

--------------------------------------------------
-- FUNÇÃO
--------------------------------------------------

Function
  : FUNC ident '(' ParamList ')' ReturnType Block
                                    { Function $2 [] $4 $6 $7 }

ReturnType
  : ':' Type                      { Just $2 }
  |                                { Nothing }

ParamList
  : Param ',' ParamList             { $1 : $3 }
  | Param                           { [$1] }
  |                                 { [] }

Param
  : ident ':' Type                  { Param $1 (Just $3) }
  | ident                           { Param $1 Nothing }

--------------------------------------------------
-- TIPOS
--------------------------------------------------

Type
  : BaseType TypeSuffix
      { applyTypeSuffix $1 $2 }

BaseType
  : typekw
      { parseType $1 }
  | structid
      { TStruct $1 }

TypeSuffix
  : '[' ']' TypeSuffix
      { Nothing : $3 }
  | '[' int_lit ']' TypeSuffix
      { Just $2 : $4 }
  | 
      { [] }


--------------------------------------------------
-- BLOCO E STATEMENTS
--------------------------------------------------

Block
  : '{' StmtList '}'                { Block $2 }

StmtList
  : Stmt StmtList                   { $1 : $2 }
  |                                 { [] }

Stmt
  : ident '=' Exp ';'               { Assign $1 $3 }

  | typekw ident '=' Exp ';'
                                    { VarDecl (parseType $1) $2 (Just $4) }

  | typekw ident ';'
                                    { VarDecl (parseType $1) $2 Nothing }

  | PRINT Exp ';'                   { Print $2 }

  | LET ident ':' Type ';'          { Let $2 $4 Nothing }

  | LET ident ':' Type '=' Exp ';'  { Let $2 $4 (Just $6) }

  | IF '(' Exp ')' Block %prec IFX
                                    { If $3 $5 Nothing }

  | IF '(' Exp ')' Block ELSE Block
                                    { If $3 $5 (Just $7) }
  | FOR '(' Stmt Exp ';' Stmt ')' Block { For $3 $4 $6 $8 }

  | WHILE '(' Exp ')' Block         { While $3 $5 }

  | RETURN Exp ';'                  { Return (Just $2) }
  | RETURN ';'                      { Return Nothing }

  | Exp ';'                         { ExpStmt $1 }
  | Block                           { BlockStmt $1 }

--------------------------------------------------
-- EXPRESSÕES
--------------------------------------------------

Exp
  : AndExp                          { $1 }

--------------------------------------------------
-- AND LÓGICO
--------------------------------------------------

AndExp
  : AndExp '&&' EqExp               { ExpBinary And $1 $3 }
  | EqExp                           { $1 }

--------------------------------------------------
-- IGUALDADE
--------------------------------------------------

EqExp
  : EqExp '==' RelExp               { ExpBinary Eq  $1 $3 }
  | EqExp '!=' RelExp               { ExpBinary Neq $1 $3 }
  | RelExp                          { $1 }

--------------------------------------------------
-- RELACIONAIS
--------------------------------------------------

RelExp
  : RelExp '<'  AddExp              { ExpBinary Lt  $1 $3 }
  | RelExp '>'  AddExp              { ExpBinary Gt  $1 $3 }
  | RelExp '<=' AddExp              { ExpBinary Leq $1 $3 }
  | RelExp '>=' AddExp              { ExpBinary Geq $1 $3 }
  | AddExp                          { $1 }

--------------------------------------------------
-- ADITIVOS
--------------------------------------------------

AddExp
  : AddExp '+' MulExp               { ExpBinary Add $1 $3 }
  | AddExp '-' MulExp               { ExpBinary Sub $1 $3 }
  | MulExp                          { $1 }

--------------------------------------------------
-- MULTIPLICATIVOS
--------------------------------------------------

MulExp
  : MulExp '*' Postfix              { ExpBinary Mul $1 $3 }
  | MulExp '/' Postfix              { ExpBinary Div $1 $3 }
  | MulExp '%' Postfix              { ExpBinary Div $1 $3 }
  | Postfix                         { $1 }

--------------------------------------------------
-- PÓS-FIXOS (CHAMADA / INDEX / CAMPO)
--------------------------------------------------

Postfix
  : Primary                         { $1 }
  | Postfix '(' ArgList ')'         { ExpCall  $1 $3 }
  | Postfix '[' Exp ']'             { ExpIndex $1 $3 }
  | Postfix '.' ident               { ExpField $1 $3 }

--------------------------------------------------
-- PRIMÁRIOS
--------------------------------------------------

Primary
  : '(' Exp ')'                     { ExpParens $2 }
  | ident                           { ExpVar $1 }
  | Literal                         { ExpLit $1 }
  | NEW Type '(' Exp ')'            { ExpNew $2 $4 }
  | '[' ArgList ']'                 { ExpArray $2 }
  | structid '(' ArgList ')'        { ExpStruct $1 $3 }
  | structid '{' ArgList '}'        { ExpStruct $1 $3 }

ArgList
  : Exp ',' ArgList                 { $1 : $3 }
  | Exp                             { [$1] }
  |                                 { [] }

Literal
  : int_lit                         { LInt $1 }
  | float_lit                       { LFloat $1 }
  | char_lit                        { LChar $1 }
  | string_lit                      { LString $1 }
  | TRUE                            { LBool True }
  | FALSE                           { LBool False }

{

--------------------------------------------------
-- CÓDIGO HASKELL AUXILIAR
--------------------------------------------------

parseError :: Lex.Token -> Lex.Alex a
parseError (Lex.Token (l,c) lx) =
  Lex.alexError $
    "Parse error at line " ++ show l ++
    ", column " ++ show c ++
    ", token: " ++ show lx

parseType :: String -> Type
parseType "int"   = TInt
parseType "float" = TFloat
parseType "char"  = TChar
parseType "bool"  = TBool
parseType "void"  = TVoid
parseType x       = TVar x

applyTypeSuffix :: Type -> [Maybe Int] -> Type
applyTypeSuffix = foldl TArray

lexer :: (Lex.Token -> Lex.Alex a) -> Lex.Alex a
lexer = (=<< Lex.alexMonadScan)


}
