{-# LANGUAGE TemplateHaskell, MultiParamTypeClasses, FlexibleInstances, DataKinds, DeriveGeneric #-}

module Person where

import GHC.Generics (Generic)
import DataSource (definePgConTable)

$(definePgConTable "EXAMPLE" "person"
  [''Eq, ''Show, ''Generic])
