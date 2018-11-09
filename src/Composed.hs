{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}

module Composed where

import GHC.Generics (Generic)
import Database.Relational.TH

import Person
import Birthday


data PersonAndBirthday =
  PersonAndBirthday
  { pbPerson :: Person
  , pbBirthday :: Birthday
  } deriving (Show, Generic)

$(makeRelationalRecordDefault ''PersonAndBirthday)
