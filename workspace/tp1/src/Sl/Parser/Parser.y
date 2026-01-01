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


%nonassoc IFX
%nonassoc ELSE

%left '&&'
%nonassoc '==' '!=' '<' '>' '<=' '>='
%left '+' '-'
%left '*' '/' '%'


%token
ident       { Lex.Token _ (Lex.TIdent $$) }
structid    { Lex.Token _ (Lex.TDataStructures $$) }
typelit      { Lex.Token _ (Lex.TType $$) }

intlit     { Lex.Token _ (Lex.TIntNumber $$) }
floatlit   { Lex.Token _ (Lex.TFloatNumber $$) }
charlit    { Lex.Token _ (Lex.TCharacter $$) }
stringlit  { Lex.Token _ (Lex.TString $$) }

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




%%

Program
  : DefList                         { Program $1 }

DefList
  : Def DefList                     { $1 : $2 }
  |                                 { [] }

Def
  : Function                        { FuncDef $1 }
  | Struct                          { StructDef $1 }


Struct
  : STRUCT structid '{' FieldList '}'      { Struct  $2 $4 }

FieldList
  : Field FieldList                 { $1 : $2 }
  |                                 { [] }

Field
  : ident ':' Type ';'              { Field $1 $3 }



Function
  : FUNC ident '(' ParamList ')' ReturnType Block
                                    { Function $2 [] $4 $6 $7 }

ReturnType
  : ':' Type                       { Just $2 }
  |                                { Nothing }

ParamList
  : Param ',' ParamList             { $1 : $3 }
  | Param                           { [$1] }
  |                                 { [] }

Param
  : ident ':' Type                  { Param $1 (Just $3) }
  | ident                           { Param $1 Nothing }


Type
  : BaseType TypeSuffix             { applyTypeSuffix $1 $2 }

BaseType
  : typelit                         { parseType $1 }
  | structid                        { TStruct $1 }

TypeSuffix
  : '[' ']' TypeSuffix              { Nothing : $3 }
  | '[' intlit ']' TypeSuffix       { Just $2 : $4 }
  |                                 { [] }



Block
  : '{' StmtList '}'                { Block $2 }

StmtList
  : Stmt StmtList                   { $1 : $2 }
  |                                 { [] }

Stmt

  : LValue '=' Exp ';'              { Assign $1 $3 }

  | typelit ident '=' Exp ';'
                                    { VarDecl (parseType $1) $2 (Just $4) }

  | typelit ident ';'
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

  --| Exp ';'                         { ExpStmt $1 }
  | Block                           { BlockStmt $1 }


LValue
  : ident                          { LVar $1 }
  | LValue '[' Exp ']'             { Lindex $1 $3 }
  | LValue '.' ident               { LField $1 $3 }


Exp
  : NewExp                          { $1 }


NewExp
  : NEW BaseType '[' Exp ']'        { ExpNew $2 $4 }
  | NEW BaseType '(' Exp ')'        { ExpNew $2 $4 }
  | AndExp                          { $1 }



AndExp
  : AndExp '&&' EqExp               { ExpBinary And $1 $3 }
  | EqExp                           { $1 }


EqExp
  : EqExp '==' RelExp               { ExpBinary Eq  $1 $3 }
  | EqExp '!=' RelExp               { ExpBinary Neq $1 $3 }
  | RelExp                          { $1 }


RelExp
  : RelExp '<'  AddExp              { ExpBinary Lt  $1 $3 }
  | RelExp '>'  AddExp              { ExpBinary Gt  $1 $3 }
  | RelExp '<=' AddExp              { ExpBinary Leq $1 $3 }
  | RelExp '>=' AddExp              { ExpBinary Geq $1 $3 }
  | AddExp                          { $1 }


AddExp
  : AddExp '+' MulExp               { ExpBinary Add $1 $3 }
  | AddExp '-' MulExp               { ExpBinary Sub $1 $3 }
  | MulExp                          { $1 }


MulExp
  : MulExp '*' Postfix              { ExpBinary Mul $1 $3 }
  | MulExp '/' Postfix              { ExpBinary Div $1 $3 }
  | MulExp '%' Postfix              { ExpBinary Div $1 $3 }
  | Postfix                         { $1 }



Postfix
  : Primary                         { $1 }
  | Postfix '(' ArgList ')'         { ExpCall  $1 $3 }
  | Postfix '[' Exp ']'             { ExpIndex $1 $3 }
  | Postfix '.' ident               { ExpField $1 $3 }


Primary
  : '(' Exp ')'                     { ExpParens $2 }
  | ident                           { ExpVar $1 }
  | Literal                         { ExpLit $1 }
  | '[' ArgList ']'                 { ExpArray $2 }
  | structid '(' ArgList ')'        { ExpStruct $1 $3 }
  | structid '{' ArgList '}'        { ExpStruct $1 $3 }

ArgList
  : Exp ',' ArgList                 { $1 : $3 }
  | Exp                             { [$1] }
  |                                 { [] }

Literal
  : intlit                         { LInt $1 }
  | floatlit                       { LFloat $1 }
  | charlit                        { LChar $1 }
  | stringlit                      { LString $1 }
  | TRUE                           { LBool True }
  | FALSE                          { LBool False }

{


parseError :: Lex.Token -> Lex.Alex a
parseError (Lex.Token (l,c) lx) =
  Lex.alexError $
    unlines
      [ "Parse error"
      , "  line:   " ++ show l
      , "  column: " ++ show c
      , "  token:  " ++ show lx
      ]

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
