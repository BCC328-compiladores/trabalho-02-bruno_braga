module Main where

import System.Directory (listDirectory)
import System.FilePath ((</>), takeExtension)
import Sl.Lexer.Lexer (runAlex)
import Sl.Parser.Parser (parseProgram)
import Sl.Pretty.SlPretty
import Sl.Syntax.Syntax
import Utils.Pretty (render, ppr)
import Control.Monad (forM_)

main :: IO ()
main = do
    let folder = "testfiles"
    files <- listDirectory folder
    let slFiles = filter (\f -> takeExtension f == ".sl") files
    forM_ slFiles $ \file -> do
        let path = folder </> file
        putStrLn $ "\n\n===== " ++ file ++ " ====="
        content <- readFile path
        case runAlex content parseProgram of
            Left err  -> putStrLn $ "Parse error:\n" ++ err
            Right ast -> putStrLn $ render (ppr ast)
