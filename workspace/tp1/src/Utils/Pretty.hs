module Utils.Pretty ( Pretty(..)
                    , pretty
                    , commaSep
                    , dot
                    , module Text.PrettyPrint.HughesPJ
                    ) where

import Text.PrettyPrint.HughesPJ

-- definition of a type class for pretty-print

class Pretty a where
  ppr :: a -> Doc

pretty :: Pretty a => a -> String
pretty = render . ppr

commaSep :: [Doc] -> Doc
commaSep = hsep . punctuate comma

dot :: Doc
dot = text "."
