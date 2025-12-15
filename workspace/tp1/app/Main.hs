-- Bruno Alves Braga 22.1.4029
module Main where

import qualified Sl.Lexer.Lexer as Lex
import System.Environment (getArgs)

main :: IO ()
main = do
  options <- getOptions
  either putStrLn runOptions options

data Option = Option {
  flag :: Flag,
  file :: FilePath
} deriving Show

data Flag = Lexer
  | Parser
  | Help
  deriving Show

getOptions :: IO (Either String Option)
getOptions = do
  arguments <- getArgs
  case arguments of 
    [flags, filepath] -> buildOption flags filepath
    _ -> printError

buildOption :: String -> String -> IO (Either String Option)
buildOption flags filepath =
  case flags of
    "--lexer" -> return $ Right (Option Lexer filepath)
    "--parser" -> return $ Right (Option Parser filepath)
    "--help" -> return $ Right (Option Help filepath)
    _ -> printError


printError :: IO (Either String Option)
printError 
  = return $ Left errorString 
    where
      errorString = unlines ["\n\nInvalid parameters when trying to run!",
                            "Sl Compiler - How to use:",
                            "cabal run sl -- <flag> <file>",
                            "flag options:",
                            " --lexer: lexical analysis - prints the tokens",
                            " --parser: syntactic analysis - prints the syntatic data tree of the given code",
                            " --help: shows the options suppoted by the compiler"]

help :: String
help = unlines ["This is the sl compiler!",
                "you can do a lexical or a syntatic analysis of a given code!",
                "Sl Compiler - How to use:",
                "cabal run sl -- <flag> <file>",
                "flag options:",
                " --lexer: lexical analysis - prints the tokens",
                " --parser: syntactic analysis - prints the syntatic data tree of the given code",
                " --help: shows the options suppoted by the compiler"]

runOptions :: Option -> IO ()
runOptions options = do
  case flag options of
    Lexer -> lexFile (file options)
    Parser -> putStrLn $ "Work in Progress"
    Help -> putStrLn help



lexFile :: FilePath -> IO ()
lexFile filepath = readFile filepath >>= Lex.runLexer 

-- parseFile :: FilePath -> IO ()
-- parseFile filepath = do
--   input <- readFile filepath
--   case parseProgram input of
--     Left err  -> putStrLn $ "Parser error:\n" ++ err
--     Right ast -> print ast




