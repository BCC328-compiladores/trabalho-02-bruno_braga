-- Bruno ALves Braga 22.1.4029
{
{-# OPTIONS_GHC -Wno-name-shadowing #-}
module Sl.Lexer.Lexer (Alex, runAlex, alexMonadScan, alexError, Token (..), Lexeme (..), lexer, runLexer) where
}

%wrapper "monadUserState"
%encoding "utf8"


$digit = 0-9            
$alpha = [a-zA-Z]       
$alphalowercase = [a-z]
$alphauppercase = [A-Z]            

@comment           = "//".* 
@identifier        = $alphalowercase[$alpha $digit _]* 
@dataStructures    = $alphauppercase[$alpha $digit _]*
@float             = $digit+ "." $digit+
@number            = $digit+
@character         = \'([^\\\']|\\.)\'


tokens :-
     <0> $white+       ;
     <0> @comment      ;
     <0> @dataStructures  {mkDataStructures}
     <0> @float           {mkFloatNumber}
     <0> @number          {mkIntNumber}
     <0> @character       {mkCharacter}

     <0> \"                  { begin string }
     <string> [^\"]+         { mkString }
     <string> \"             { begin 0 }           

     <0> "func"        {simpleToken TFunc}
     <0> "let"         {simpleToken TLet}
     <0> "struct"      {simpleToken TStruct}
     <0> "="           {simpleToken TAssign}
     <0> "print"       {simpleToken TPrint}
     <0> "if"          {simpleToken TIf}
     <0> "else"        {simpleToken TElse}
     <0> "while"       {simpleToken TWhile}
     <0> "for"         {simpleToken TFor}
     <0> ";"           {simpleToken TSemi}
     <0> "::"          {simpleToken TDoubleColon}
     <0> ":"           {simpleToken TColon}
     <0> "."           {simpleToken TDot}
     <0> ","           {simpleToken TComma}
     <0> "("           {simpleToken TLParen}
     <0> ")"           {simpleToken TRParen}
     <0> "{"           {simpleToken TLBrace}
     <0> "}"           {simpleToken TRBrace}
     <0> "["           {simpleToken TLBracket}
     <0> "]"           {simpleToken TRBracket}
     <0> "+"           {simpleToken TPlus}
     <0> "*"           {simpleToken TTimes}
     <0> "-"           {simpleToken TMinus}
     <0> "/"           {simpleToken TDiv}
     <0> "%"           {simpleToken TMod}
     <0> "=="          {simpleToken TEq}
     <0> "!="          {simpleToken TNeq}
     <0> "<"           {simpleToken TLt}
     <0> ">"           {simpleToken TGt}
     <0> "<="          {simpleToken TLeq}
     <0> ">="          {simpleToken TGeq}
     <0> "!"           {simpleToken TNot}
     <0> "&&"          {simpleToken TAnd}
     <0> "int"         {mkType}
     <0> "float"       {mkType}
     <0> "char"        {mkType}
     <0> "bool"        {mkType}
     <0> "string"        {mkType}
     <0> "true"        {simpleToken TTrue}
     <0> "false"       {simpleToken TFalse}
     <0> "void"        {mkType}
     <0> "return"      {simpleToken TReturn}
     <0> "new"         {simpleToken TNew}
     <0> @identifier   {mkIdent}
     
{


data AlexUserState 
  = AlexUserState {
      nestLevel :: Int 
    }

alexInitUserState :: AlexUserState 
alexInitUserState 
  = AlexUserState 0 

get :: Alex AlexUserState
get = Alex $ \s -> Right (s, alex_ust s)

put :: AlexUserState -> Alex ()
put s' = Alex $ \s -> Right (s{alex_ust = s'}, ())

modify :: (AlexUserState -> AlexUserState) -> Alex ()
modify f 
  = Alex $ \s -> Right (s{alex_ust = f (alex_ust s)}, ())

alexEOF :: Alex Token
alexEOF = do
  (pos, _, _, _) <- alexGetInput
--   startCode <- alexGetStartCode
--   when (startCode == state_comment) $
--     alexError "Error: unclosed comment"
  pure $ Token (position pos) TEOF



data Token
  = Token {
      pos :: (Int, Int)
    , lexeme :: Lexeme 
    } deriving (Eq, Ord, Show)

data Lexeme    
  = TIdent String
  | TDataStructures String
  | TType String
  | TString String
  | TIntNumber Int
  | TFloatNumber Float
  | TCharacter Char
  | TFunc 
  | TLet 
  | TStruct 
  | TAssign 
  | TPrint 
  | TIf 
  | TElse 
  | TWhile 
  | TFor 
  | TSemi 
  | TColon
  | TDoubleColon
  | TDot
  | TComma
  | TLParen 
  | TRParen 
  | TLBrace 
  | TRBrace 
  | TLBracket
  | TRBracket
  | TPlus 
  | TTimes 
  | TMinus 
  | TDiv 
  | TMod
  | TEq 
  | TNeq
  | TLt 
  | TGt
  | TLeq
  | TGeq
  | TNot 
  | TAnd 
  | TTrue 
  | TFalse 
  | TVoid
  | TReturn
  | TNew
  | TEOF
  deriving (Eq, Ord)

position :: AlexPosn -> (Int, Int)
position (AlexPn _ x y) = (x,y)

mkIdent :: AlexAction Token 
mkIdent (st, _, _, str) len =
  pure $ Token (position st) (TIdent (take len str))



mkDataStructures :: AlexAction Token
mkDataStructures (st, _, _, str) len = pure $ Token (position st) (TDataStructures $ take len str)

mkType :: AlexAction Token
mkType (st, _, _, str) len = pure $ Token (position st) (TType $ take len str)

mkString :: AlexAction Token
mkString (st, _, _, str) len = pure $ Token (position st) (TString $ take len str)

mkIntNumber :: AlexAction Token
mkIntNumber (st, _, _, str) len = pure $ Token (position st) (TIntNumber $ read $ take len str)


mkFloatNumber :: AlexAction Token
mkFloatNumber (st, _, _, ('.' : xs)) len = pure $ Token (position st) (TFloatNumber $ read $ "0." ++ (take (len-1) xs))
mkFloatNumber (st, _, _, str) len = pure $ Token (position st) (TFloatNumber $ read $ take len str)


mkCharacter :: AlexAction Token
mkCharacter (st, _, _, str) _ = 
    case str of
        [] -> pure $ Token (position st) (TCharacter ' ')  
        [c] -> pure $ Token (position st) (TCharacter c)
        (_ : c : _) -> pure $ Token (position st) (TCharacter c)



simpleToken :: Lexeme -> AlexAction Token
simpleToken lx (st, _, _, _) _ = return $ Token (position st) lx


lexer :: String -> Either String [Token]
lexer s = runAlex s go 
  where 
    go = do 
      output <- alexMonadScan 
      if lexeme output == TEOF then 
        pure [output]
      else (output :) <$> go


instance Show Lexeme where
    show (TIdent id) = "ID:" ++ id
    show (TDataStructures name) = "STRUCTNAME:" ++ name
    show (TType string) = "TYPE:" ++ string
    show (TString string) = "STRING:" ++ string
    show (TIntNumber value) = "INT:" ++ (show value)
    show (TFloatNumber value) = "FLOAT:" ++ (show value)
    show (TCharacter c) = "CHAR:" ++ [c]
    show (TAssign) = "="
    show (TPrint) = "PRINT"
    show (TIf) = "IF"
    show (TElse) = "ELSE"
    show (TWhile) = "WHILE"
    show (TFor) = "FOR"
    show (TSemi) = ";" 
    show (TColon) = ":" 
    show (TDoubleColon) = "::" 
    show (TDot) = "." 
    show (TComma) = "," 
    show (TLParen) = "(" 
    show (TRParen) = ")" 
    show (TLBrace) = "{" 
    show (TRBrace) = "}" 
    show (TLBracket) = "[" 
    show (TRBracket) = "]" 
    show (TPlus) = "+" 
    show (TTimes) = "*" 
    show (TMinus) = "-" 
    show (TDiv) = "/" 
    show (TMod) = "%" 
    show (TEq) = "==" 
    show (TNeq) = "!=" 
    show (TLt) = "<" 
    show (TGt) = ">" 
    show (TGeq) = ">=" 
    show (TLeq) = "<=" 
    show (TNot) = "!" 
    show (TAnd) = "&&" 
    show (TTrue) = "true"
    show (TFalse) = "false"
    show (TVoid) = "void"
    show (TReturn) = "RETURN"
    show (TNew) = "NEW"
    show (TFunc) = "FUNC"
    show (TLet) = "LET"
    show (TStruct) = "STRUCT"
    show (TEOF) = "TEOF"


runLexer :: String -> IO ()
runLexer input = do
    case lexer input of
        Left err -> putStrLn $ "Lexer error: " ++ err
        Right tokens -> mapM_ (putStrLn . showLexeme) tokens
  where
    showLexeme (Token _ lexeme) = show lexeme

}