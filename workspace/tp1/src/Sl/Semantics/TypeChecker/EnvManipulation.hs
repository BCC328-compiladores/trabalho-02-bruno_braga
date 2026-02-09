module Sl.Semantics.TypeChecker.EnvManipulation where

import Sl.Semantics.TypeChecker.TypeDefinitions
import qualified Data.Map as M
import Sl.Syntax.Syntax
import Control.Monad.State
import Control.Monad.Except
import Control.Applicative ((<|>))

-- inicialização do ambiente
emptyState :: Env
emptyState = Env { 
    varEnv    = [M.empty],
    funEnv    = M.empty,
    structEnv = M.empty,
    returnType   = Nothing
}

-- "Entra dentro do escopo", colocando o escopo do bloco no ambiente, para ser utilizado dentro do bloco
enterScope :: InterpM ()
enterScope = modify $ \s -> s { varEnv = M.empty : varEnv s }

-- Ao sair do escopo, remove o escopo do ambiente
exitScope :: InterpM ()
exitScope = modify $ \s -> s { varEnv = tail (varEnv s) }

declareVar :: String -> Type -> InterpM ()
declareVar x t = do
  envs <- gets varEnv
  case envs of
    (e:es)
      | M.member x e -> throwError ("Variável " ++ show x ++ " já foi declarada")
      | otherwise -> modify $ \s -> s { varEnv = M.insert x t e : es }
    _ -> error "Não foi possível declarar variável"

lookupVar :: String -> InterpM Type
lookupVar x = do
  envs <- gets varEnv
  case foldr (\e acc -> acc <|> M.lookup x e) Nothing envs of
    Just t  -> return t
    Nothing -> throwError ("Variável " ++ show x ++ " não definida")
