module Sl.Semantics.TypeChecker.TypeDefinitions where


import Sl.Syntax.Syntax
import qualified Data.Map as M
import Control.Monad.State
import Control.Monad.Except

type VarEnv    = [M.Map String Type] 
type FunEnv    = M.Map String ([Type], Type)
type StructEnv = M.Map String [(String, Type)]

data Env = Env {
    varEnv    :: VarEnv,
    funEnv    :: FunEnv,
    structEnv :: StructEnv,
    returnType   :: Maybe Type
} 


type InterpM a = ExceptT String (State Env) a