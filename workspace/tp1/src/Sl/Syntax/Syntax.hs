-- Bruno Alves Braga 22.1.4029
module Sl.Syntax.Syntax where

data Program = Program [Def]
    deriving(Show, Eq)

data Def = FuncDef Function
    | StructDef Struct
    deriving (Show, Eq)

data Function = Function {
    funcName :: String,
    funcTypeVars :: [String],
    funcParams :: [Param],
    funcReturn :: Maybe Type,
    funcBody :: Block
} deriving(Show,Eq)

data Param = Param String (Maybe Type)
    deriving (Show, Eq)

data Struct = Struct{
    structName :: String,
    structFields :: [Field]
} deriving (Show, Eq)

data Field = Field String Type deriving (Show, Eq)

data Type = TInt
    | TFloat
    | TChar
    | TBool
    | TVoid
    | TArray Type (Maybe Int)
    | TStruct String
    | TFunc [Type] Type
    | TVar String
    deriving (Show, Eq)

data Stmt = Assign String Exp
    | Let String (Maybe Type) (Maybe Exp)
    | VarDecl Type String (Maybe Exp)
    | Print Exp
    | If Exp Block (Maybe Block)
    | While Exp Block
    | For Stmt Exp Stmt Block
    | Return (Maybe Exp)
    | ExpStmt Exp
    | BlockStmt Block
    deriving (Show, Eq)

newtype Block = Block [Stmt]
    deriving (Show, Eq)

data Exp = ExpLit Literal
    | ExpVar String
    | ExpBinary BinOp Exp Exp
    | ExpCall Exp [Exp]
    | ExpIndex Exp Exp
    | ExpField Exp String
    | ExpNew Type Exp
    | ExpArray [Exp]
    | ExpStruct String [Exp] 
    | ExpParens Exp
    deriving (Show, Eq)

data Literal = LInt Int
    | LFloat Float
    | LChar Char
    | LString String
    | LBool Bool
    deriving (Show, Eq)

data LValue = --LVar String
     Lindex LValue Exp
    | LField LValue String
    deriving (Show, Eq) 

data BinOp = Add | Sub | Mul | Div
    | Eq | Neq | Lt | Gt | Leq | Geq | And
    deriving (Show, Eq)

