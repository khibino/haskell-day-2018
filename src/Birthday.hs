{-# LANGUAGE TemplateHaskell, MultiParamTypeClasses, FlexibleInstances, DataKinds, DeriveGeneric #-}

module Birthday where

import GHC.Generics (Generic)
import DataSource (definePgConTable)

$(definePgConTable "EXAMPLE" "birthday"
  [''Eq, ''Show, ''Generic])
