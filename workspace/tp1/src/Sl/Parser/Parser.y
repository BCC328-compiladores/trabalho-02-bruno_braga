{
{-# OPTIONS_GHC -Wno-name-shadowing #-}
module Sl.Parser.Parser
  ( parseProgram
  ) where

import qualified Sl.Lexer.Lexer as Lex
import Sl.Syntax.Syntax
}


%name parseProgram
%tokentype { Lex.Token }
%error { parseError }

%monad {Lex.Alex}{(>>=)}{return}
%lexer { lexer } { Lex.Token _ Lex.TEOF }


%token
    ident        { Lex.Token _ (Lex.TIdent $$) }
    structName   { Lex.Token _ (Lex.TDataStructures $$) }

    intLit       { Lex.Token _ (Lex.TIntNumber $$) }
    floatLit     { Lex.Token _ (Lex.TFloatNumber $$) }
    charLit      { Lex.Token _ (Lex.TCharacter $$) }
    stringLit    { Lex.Token _ (Lex.TString $$) }

    'TYPE'       { $$ }

    'true'       { Lex.Token _ Lex.TTrue }
    'false'      { Lex.Token _ Lex.TFalse }

    'func'       { Lex.Token _ Lex.TFunc }
    'return'     { Lex.Token _ Lex.TReturn }
    'print'      { Lex.Token _ Lex.TPrint }
    'new'        { Lex.Token _ Lex.TNew }

    'if'         { Lex.Token _ Lex.TIf }
    'else'       { Lex.Token _ Lex.TElse }
    'while'      { Lex.Token _ Lex.TWhile }
    'for'        { Lex.Token _ Lex.TFor }

    '('          { Lex.Token _ Lex.TLParen }
    ')'          { Lex.Token _ Lex.TRParen }
    '{'          { Lex.Token _ Lex.TLBrace }
    '}'          { Lex.Token _ Lex.TRBrace }
    '['          { Lex.Token _ Lex.TLBracket }
    ']'          { Lex.Token _ Lex.TRBracket }

    ','          { Lex.Token _ Lex.TComma }
    ';'          { Lex.Token _ Lex.TSemi }
    ':'          { Lex.Token _ Lex.TColon }
    '.'          { Lex.Token _ Lex.TDot }

    '='          { Lex.Token _ Lex.TAssign }

    '+'          { Lex.Token _ Lex.TPlus }
    '-'          { Lex.Token _ Lex.TMinus }
    '*'          { Lex.Token _ Lex.TTimes }
    '/'          { Lex.Token _ Lex.TDiv }

    '=='         { Lex.Token _ Lex.TEq }
    '!='         { Lex.Token _ Lex.TNeq }
    '<'          { Lex.Token _ Lex.TLt }
    '>'          { Lex.Token _ Lex.TGt }
    '<='         { Lex.Token _ Lex.TLeq }
    '>='         { Lex.Token _ Lex.TGeq }

    '&&'         { Lex.Token _ Lex.TAnd }


%right '='
%left '&&'
%left '==' '!=' '<' '>' '<=' '>='
%left '+' '-'
%left '*' '/'
%left '.' '[' ']'

%%


Program
    : Defs                { Program $1 }

Defs
    : Def Defs            { $1 : $2 }
    |                     { [] }

Def
    : Function            { FuncDef $1 }
    | Struct              { StructDef $1 }


Struct
    : structName '{' Fields '}' { Struct (tokenString $1) $3 }

Fields
    : Field Fields        { $1 : $2 }
    |                     { [] }

Field
    : ident ':' Type ';'  { Field (tokenString $1) $3 }


Function
    : 'func' ident '(' Params ')' ReturnType Block
    { Function (tokenString $2) [] $4 $6 $7 }

ReturnType
    : ':' Type            { Just $2 }
    |                     { Nothing }

Params
    : Param ',' Params    { $1 : $3 }
    | Param               { [$1] }
    |                     { [] }

Param
    : ident ':' Type      { Param (tokenString $1) (Just $3) }
    | ident               { Param (tokenString $1) Nothing }


Type
    : BaseType TypeSuffix { applySuffix $1 $2 }

TypeSuffix
    : ArrayNonEmpty       { Just $1 }
    |                     { Nothing }

ArrayNonEmpty 
    : '[' ']'             { Nothing }
    | '[' intLit ']'      { Just $2 }

BaseType
  : 'TYPE'       { baseType $1 }
  | structName   { Lex.TDataStructures (tokenString $1) }


Block
    : '{' Stmts '}'       { Block $2 }

Stmts
    : Stmt Stmts          { $1 : $2 }
    |                     { [] }

Stmt
    : ident '=' Exp ';'           { Assign (tokenString $1) $3 }
    | LValue '=' Exp ';'          { AssignLValue $1 $3 }
    | 'print' '(' Exp ')' ';'     { Print $3 }
    | 'return' Exp ';'            { Return (Just $2) }
    | 'return' ';'                { Return Nothing }
    | 'if' '(' Exp ')' Block 'else' Block { If $3 $5 (Just $7) }
    | 'if' '(' Exp ')' Block      { If $3 $5 Nothing }
    | 'while' '(' Exp ')' Block   { While $3 $5 }
    | 'for' '(' ForInit ';' Exp ';' ForStep ')' Block
        { For $3 $5 $7 $9 }
    | Exp ';'                     { ExpStmt $1 }

ForInit
    : ident '=' Exp        { ForInitAssign (tokenString $1) $3 }
    |                     { ForInitEmpty }

ForStep
    : ident '=' Exp        { ForStepAssign (tokenString $1) $3 }
    | Exp                 { ForStepExp $1 }
    |                     { ForStepEmpty }


LValue
    : LValue '[' Exp ']'  { LIndex $1 $3 }
    | LValue '.' ident    { LField $1 (tokenString $3) }


Exp
    : intLit              { ExpLit (LInt $1) }
    | floatLit            { ExpLit (LFloat $1) }
    | charLit             { ExpLit (LChar $1) }
    | stringLit           { ExpLit (LString $1) }
    | 'true'              { ExpLit (LBool True) }
    | 'false'             { ExpLit (LBool False) }
    | ident               { ExpVar (tokenString $1) }

    | Exp '+' Exp         { ExpBinary Add $1 $3 }
    | Exp '-' Exp         { ExpBinary Sub $1 $3 }
    | Exp '*' Exp         { ExpBinary Mul $1 $3 }
    | Exp '/' Exp         { ExpBinary Div $1 $3 }

    | Exp '==' Exp        { ExpBinary Eq $1 $3 }
    | Exp '!=' Exp        { ExpBinary Neq $1 $3 }
    | Exp '<' Exp         { ExpBinary Lt $1 $3 }
    | Exp '>' Exp         { ExpBinary Gt $1 $3 }
    | Exp '<=' Exp        { ExpBinary Leq $1 $3 }
    | Exp '>=' Exp        { ExpBinary Geq $1 $3 }

    | Exp '&&' Exp        { ExpBinary And $1 $3 }

    | ident '(' Args ')'  { ExpCall (tokenString $1) $3 }
    | Exp '[' Exp ']'     { ExpIndex $1 $3 }
    | Exp '.' ident       { ExpField $1 (tokenString $3) }

    | 'new' Type '[' Exp ']' { ExpNew (TArray $2 Nothing) $4 }

    | '[' Args ']'        { ExpArray $2 }
    | structName '{' Args '}' { ExpStruct (tokenString $1) $3 }

    | '(' Exp ')'         { ExpParens $2 }

Args
    : Exp ',' Args        { $1 : $3 }
    | Exp                 { [$1] }
    |                     { [] }


{

tokenString :: Lex.Token -> String
tokenString (Lex.Token _ (Lex.TIdent s))          = s
tokenString (Lex.Token _ (Lex.TDataStructures s)) = s
tokenString _ = error "Unexpected token"
    
baseType :: String -> Type
baseType "int"    = TInt
baseType "float"  = TFloat
baseType "char"   = TChar
baseType "string" = TString
baseType other    = TUnknown other

applySuffix :: Type -> Maybe (Maybe Int) -> Type
applySuffix base Nothing        = base
applySuffix base (Just sizeOpt) = TArray base sizeOpt

parserTest :: String -> IO ()
parserTest s = do
  r <- expParser s
  print r

parseError :: Lex.Token -> Lex.Alex a
parseError (Lex.Token (line, col) lexeme) =
  Lex.alexError $
    "Parse error while processing lexeme: " ++ show lexeme
    ++ "\n at line " ++ show line ++ ", column " ++ show col

lexer :: (Lex.Token -> Lex.Alex a) -> Lex.Alex a
lexer = (=<< Lex.alexMonadScan)

expParser :: String -> IO (Either String Exp)
expParser content = do
  pure $ Lex.runAlex content parseProgram

}