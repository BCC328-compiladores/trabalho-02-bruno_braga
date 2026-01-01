module Sl.Pretty.SlPretty where

import Prelude hiding ((<>))
import Sl.Syntax.Syntax
import Utils.Pretty



instance Pretty Literal where
  ppr (LInt n)     = int n
  ppr (LFloat f)   = text (show f)
  ppr (LChar c)    = quotes (char c)
  ppr (LString s)  = doubleQuotes (text s)
  ppr (LBool True)  = text "true"
  ppr (LBool False) = text "false"


instance Pretty Program where
  ppr (Program defs) =
    vcat (map ppr defs)


instance Pretty Def where
  ppr (StructDef s) = ppr s
  ppr (FuncDef f)   = ppr f


instance Pretty Struct where
  ppr (Struct name fields) =
    vcat
      [ text "struct" <+> text name <+> lbrace
      , nest 2 (vcat (map ppr fields))
      , rbrace
      ]

instance Pretty Field where
  ppr (Field name ty) =
    (text name <> colon) <+> (ppr ty <> semi)


instance Pretty Function where
  ppr (Function name _ params ret body) =
    vcat
      [ (text "func" <+> text name)
          <> parens (commaSep (map ppr params))
          <> pprReturn ret
      , ppr body
      ]

pprReturn :: Maybe Type -> Doc
pprReturn Nothing  = empty
pprReturn (Just t) =
  space <> (colon <+> ppr t)


instance Pretty Param where
  ppr (Param name Nothing) =
    text name
  ppr (Param name (Just ty)) =
    (text name <> colon) <+> ppr ty




instance Pretty Type where
  ppr TInt        = text "int"
  ppr TFloat      = text "float"
  ppr TChar       = text "char"
  ppr TBool       = text "bool"
  ppr TString     = text "string"
  ppr TVoid       = text "void"
  ppr (TStruct s) = text s
  ppr (TVar s)    = text s
  ppr (TArray t s) =
    ppr t <> brackets (maybe empty int s)





instance Pretty Block where
  ppr (Block stmts) =
    vcat
      [ nest 2 (vcat (map ppr stmts))
      , rbrace
      ]


instance Pretty Stmt where
  ppr (Let x t Nothing) =
    (text "let" <+> text x <> colon) <+> (ppr t <> semi)
  ppr (Let x t (Just e)) =
    (text "let" <+> text x <> colon) <+> ppr t
      <+> text "=" <+> (ppr e <> semi)
  ppr (VarDecl t x Nothing) =
    ppr t <+> (text x <> semi)
  ppr (VarDecl t x (Just e)) =
    ppr t <+> text x <+> text "=" <+> (ppr e <> semi)
  ppr (Assign lv e) =
    ppr lv <+> text "=" <+> (ppr e <> semi)
  ppr (Print e) =
    text "print" <+> (ppr e <> semi)
  ppr (Return Nothing) =
    text "return" <> semi
  ppr (Return (Just e)) =
    text "return" <+> (ppr e <> semi)
  ppr (While c b) =
    vcat
    [
      text "while" <+> parens (ppr c) <+> lbrace
      , ppr b
    ]
  ppr (If c t Nothing) =
    text "if" <+> parens (ppr c) <+> ppr t
  ppr (If c t (Just e)) =
    vcat
      [ text "if" <+> parens (ppr c) <+> lbrace
      , ppr t
      , text "else" <+> ppr e
      ]
  ppr (For i c s b) =
    vcat
      [ text "for" <+>
        parens ((ppr i <+> ppr c <> semi) <+> ppr s)
        <+> lbrace
        , ppr b
      ]
  ppr (BlockStmt b) =
    ppr b





instance Pretty LValue where
  ppr (LVar x)      = text x
  ppr (Lindex l e)  = ppr l <> brackets (ppr e)
  ppr (LField l f)  = ppr l <> dot <> text f




instance Pretty Exp where
    ppr = pprAnd


pprAnd :: Exp -> Doc
pprAnd (ExpBinary And e1 e2) = hsep [pprAnd e1, text "&&", pprEq e2]
pprAnd e                     = pprEq e


pprEq :: Exp -> Doc
pprEq (ExpBinary Eq  e1 e2) = hsep [pprEq e1, text "==", pprRel e2]
pprEq (ExpBinary Neq e1 e2) = hsep [pprEq e1, text "!=", pprRel e2]
pprEq e                      = pprRel e


pprRel :: Exp -> Doc
pprRel (ExpBinary Lt  e1 e2) = hsep [pprRel e1, text "<",  pprAdd e2]
pprRel (ExpBinary Gt  e1 e2) = hsep [pprRel e1, text ">",  pprAdd e2]
pprRel (ExpBinary Leq e1 e2) = hsep [pprRel e1, text "<=", pprAdd e2]
pprRel (ExpBinary Geq e1 e2) = hsep [pprRel e1, text ">=", pprAdd e2]
pprRel e                      = pprAdd e


pprAdd :: Exp -> Doc
pprAdd (ExpBinary Add e1 e2) = hsep [pprAdd e1, text "+", pprMul e2]
pprAdd (ExpBinary Sub e1 e2) = hsep [pprAdd e1, text "-", pprMul e2]
pprAdd e                      = pprMul e


pprMul :: Exp -> Doc
pprMul (ExpBinary Mul e1 e2) = hsep [pprMul e1, text "*", pprPostfix e2]
pprMul (ExpBinary Div e1 e2) = hsep [pprMul e1, text "/", pprPostfix e2]
pprMul e                      = pprPostfix e


pprPostfix :: Exp -> Doc
pprPostfix (ExpCall f args)      = pprPostfix f <> parens (commaSep (map ppr args))
pprPostfix (ExpIndex e i)        = pprPostfix e <> brackets (ppr i)
pprPostfix (ExpField e f)        = pprPostfix e <> text "." <> text f
pprPostfix (ExpNew t e)          = text "new" <+> ppr t <> parens (ppr e)
pprPostfix e                      = pprPrimary e


pprPrimary :: Exp -> Doc
pprPrimary (ExpVar x)           = text x
pprPrimary (ExpLit l)           = ppr l
pprPrimary (ExpParens e)        = parens (ppr e)
pprPrimary (ExpStruct s es)     = text s <> braces (commaSep (map ppr es))
pprPrimary (ExpArray es)        = brackets (commaSep (map ppr es))

