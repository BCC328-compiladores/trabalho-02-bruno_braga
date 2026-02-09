{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use when" #-}
{-# HLINT ignore "Redundant bracket" #-}
module Sl.Semantics.TypeChecker.TypeChecker where

import Sl.Semantics.TypeChecker.EnvManipulation
import Sl.Semantics.TypeChecker.TypeDefinitions
import Control.Monad.State
import Control.Monad.Except
import Sl.Syntax.Syntax
import qualified Data.Map as M
import Debug.Trace


checkProgram :: Program -> Either String ()
checkProgram p =
  evalState (runExceptT (checkProgramTC p)) emptyState

checkProgramTC :: Program -> InterpM ()
checkProgramTC (Program defs) = do
  mapM_ collectDef defs
  mapM_ checkDef defs


collectDef :: Def -> InterpM ()
collectDef (StructDef (Struct name fields)) = do
  senv <- gets structEnv
  if (M.member name senv) 
    then throwError ("Struct " ++ show name ++ " não definida")
    else return ()

  let fs = [(f, t) | Field f t <- fields]
  modify $ \st -> st { structEnv = M.insert name fs senv }


collectDef (FuncDef f) = do
  let name = funcName f
      params = [t | Param _ (Just t) <- funcParams f]
      ret = maybe TVoid id (funcReturn f)

  fenv <- gets funEnv
  if (M.member name fenv) 
    then throwError ("Função " ++ show name ++ " não definida")
    else return ()

  modify $ \s -> s { funEnv = M.insert name (params, ret) fenv }



checkDef :: Def -> InterpM ()
checkDef (StructDef _) = return ()

checkDef (FuncDef f) = do
  enterScope
  modify $ \s -> s { returnType = Just (maybe TVoid id (funcReturn f)) }

  mapM_ declareParam (funcParams f)
  checkBlock (funcBody f)

  exitScope



declareParam :: Param -> InterpM ()
declareParam (Param x (Just t)) = declareVar x t
declareParam (Param x Nothing) = error "Parâmetros sem tipo não suportados"



checkBlock :: Block -> InterpM ()
checkBlock (Block stmts) = do
  enterScope
  mapM_ checkStmt stmts
  exitScope


checkStmt :: Stmt -> InterpM ()
checkStmt (VarDecl t x me) = do
  case me of
    Nothing -> return ()
    Just e  -> do
      t' <- inferExp e
      if t == t' 
        then return ()
        else throwError ("Incompatibilidade de tipos entre: " ++ show t ++ " e " ++ show t')
  declareVar x t

checkStmt (Assign lv e) = do
  t1 <- inferLValue lv
  t2 <- inferExp e
  if t1 == t2
    then return()
    else throwError ("Incompatibilidade de tipos entre: " ++ show t1 ++ " e " ++ show t2)

checkStmt (Let x t me) = do
  case me of
    Nothing -> return ()
    Just e  -> do
      t' <- inferExp e
      if t == t'
        then return ()
        else throwError ("Incompatibilidade de tipos entre: " ++ show t ++ " e " ++ show t')
  declareVar x t

checkStmt (Print e) = do
  _ <- inferExp e
  return ()

checkStmt (For init cond step body) = do
  enterScope
  checkStmt init
  t <- inferExp cond
  if t == TBool
    then return ()
    else throwError "A expressão condicional do For deve ser booleana"
  checkStmt step
  checkBlock body
  exitScope

checkStmt (If cond th el) = do
  t <- inferExp cond
  if t == TBool 
    then return ()
    else throwError ("A expressão condicional do If deve ser do tipo booleano " ++ show t)
  checkBlock th
  maybe (return ()) checkBlock el

checkStmt (While cond b) = do
  t <- inferExp cond
  if t == TBool
    then return ()
    else throwError ("A expressão condicional do While deve ser do tipo booleano " ++ show t)
  checkBlock b

checkStmt (Return me) = do
  expected <- gets returnType
  case (expected, me) of
    (Just TVoid, Nothing) -> return ()
    (Just t, Just e) -> do
      t' <- inferExp e
      if t == t'
        then return ()
        else throwError ("Tipo de retorno inválido, esperava " ++ show t ++ " e foi recebido " ++ show t')
    _ -> throwError "Tipo de retorno inválido"

checkStmt (ExpStmt e) = do
  _ <- inferExp e
  return ()

checkStmt (BlockStmt b) =
  checkBlock b

inferExp :: Exp -> InterpM Type
inferExp (ExpLit (LInt _))    = return TInt
inferExp (ExpLit (LFloat _))  = return TFloat
inferExp (ExpVar x)           = lookupVar x
inferExp (ExpLit (LBool _))   = return TBool
inferExp (ExpLit (LString _)) = return TString
inferExp (ExpParens e) = inferExp e
inferExp (ExpIndex e i) = do
  t <- inferExp e
  ti <- inferExp i
  if ti /= TInt
    then throwError ("Tipo inválido para indexação, esperado Int, mas recebeu " ++ show ti)
    else case t of
      TArray et _ -> return et
      _ -> throwError ("Tentativa de indexar um valor que não é vetor: " ++ show t)
inferExp (ExpField e f) = do
  t <- inferExp e
  case t of
    TStruct s -> do
      senv <- gets structEnv
      case M.lookup s senv >>= lookup f of
        Just ft -> return ft
        Nothing -> throwError ("Campo " ++ show f ++ " não existe na struct " ++ s)
    _ ->
      throwError ("Tentativa de acesso a campo em um valor que não é struct: " ++ show t)
inferExp (ExpNew t e) = do
  te <- inferExp e
  if te == TInt
    then return (TArray t Nothing)
    else throwError ("Tamanho do vetor deve ser inteiro, mas recebeu " ++ show te)
inferExp (ExpArray es) =
  case es of
    [] -> throwError "Array literal não pode ser vazio"
    (e:rest) -> do
      t <- inferExp e
      ts <- mapM inferExp rest
      if all (== t) ts
        then return (TArray t (Just (length es)))
        else throwError "Todos os elementos do array devem ter o mesmo tipo"
inferExp (ExpStruct s args) = do
  senv <- gets structEnv
  case M.lookup s senv of
    Nothing ->
      throwError ("Struct " ++ s ++ " não definida")

    Just fields -> do
      let fieldTypes = map snd fields
      argTypes <- mapM inferExp args

      if length fieldTypes /= length argTypes
        then throwError ("Número incorreto de argumentos para struct " ++ s)
        else if and (zipWith (==) fieldTypes argTypes)
          then return (TStruct s)
          else throwError ("Tipos incompatíveis na construção da struct " ++ s)

inferExp (ExpCall e args) = do
  case e of
    ExpVar f -> do
      fenv <- gets funEnv
      case M.lookup f fenv of
        Nothing ->
          throwError ("Função " ++ show f ++ " não definida")

        Just (paramTypes, retType) -> do
          argTypes <- mapM inferExp args
          if length paramTypes /= length argTypes
            then throwError ("Número incorreto de argumentos na chamada de " ++ show f)
            else if and (zipWith compatible paramTypes argTypes)
              then return retType
              else throwError ("Tipos incompatíveis na chamada da função " ++ show f)

    _ -> throwError "Expressão chamada não é uma função"

inferExp (ExpBinary op e1 e2) = do
  t1 <- inferExp e1
  t2 <- inferExp e2
  case op of
    Add -> aritOp t1 t2
    Sub -> aritOp t1 t2
    Mul -> aritOp t1 t2
    Div -> aritOp t1 t2
    And -> boolOp t1 t2
    Eq  -> comp t1 t2
    _   -> comp t1 t2 -- Todas as outras são operações de comparação, então não precisa do casamento exato


aritOp :: Type -> Type -> InterpM Type
aritOp t1 t2
  | t1 == TInt && t2 == TInt = return TInt
  | t1 == TFloat && t2 == TFloat = return TFloat
  | t1 == TFloat && t2 == TInt = return TFloat
  | t1 == TInt && t2 == TFloat = return TFloat
  | otherwise = throwError ("Tipos inválidos para operação aritmética entre " ++ show t1 ++ " e " ++ show t2)

boolOp :: Type -> Type -> InterpM Type
boolOp t1 t2
  | t1 == TBool && t2 == TBool = return TBool
  | otherwise = throwError ("Tipos inválidos para operação booleana entre " ++ show t1 ++ " e " ++ show t2)

comp :: Type -> Type -> InterpM Type
comp t1 t2
  | t1 == t2 = return TBool
  | otherwise = throwError ("Tipos inválidos para comparação entre " ++ show t1 ++ " e " ++ show t2 ++ "\n Os tipos devem ser iguais")


-- Só para consertar o problema de comparação de tipos de vetor para o zip
compatible :: Type -> Type -> Bool
compatible expected actual =
  case (expected, actual) of
    (TArray t1 Nothing, TArray t2 _) ->
      t1 == t2

    (TArray t1 (Just n), TArray t2 (Just m)) ->
      t1 == t2 && n == m

    _ ->
      expected == actual

inferLValue :: LValue -> InterpM Type
inferLValue (LVar x) = lookupVar x

inferLValue (Lindex lv e) = do
  t <- inferLValue lv
  i <- inferExp e
  if i == TInt 
    then return ()
    else throwError ("Tipo inválido, tipo da indexação deve ser inteiro, mas recebeu: " ++ show i)
  case t of
    TArray et _ -> return et
    _ -> throwError ("Tipo inválido, não é um vetor. " ++ show t)

inferLValue (LField lv f) = do
  t <- inferLValue lv
  case t of
    TStruct s -> do
      senv <- gets structEnv
      case M.lookup s senv >>= lookup f of
        Just ft -> return ft
        Nothing -> throwError ("O campo " ++ show f ++ " acessado na struct " ++ s ++ "não está definido")
    _ -> throwError ("Tipo inválido, esperava struct, mas recebeu: " ++ show t)
