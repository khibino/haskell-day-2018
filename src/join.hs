{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedLabels #-}

import Data.Int
import Data.Time
import Data.Functor.ProductIsomorphic
import Database.Relational
import Database.Relational.OverloadedInstances ()
import Database.Relational.TH
import Database.Relational.Monad.Trans.Ordering (Orderings)

import Person (Person (Person), person)
import Birthday (Birthday, birthday)
import Composed


personAndBirthday :: Relation () (Person, Birthday)
personAndBirthday = relation $ do
  p <- query person    -- Join product accumulated
  b <- query birthday
  on $ #name p .=. #name b
  return $ (,) |$| p |*| b

personAndBirthdayL :: Relation () (Person, Maybe Birthday)
personAndBirthdayL = relation $ do
  p <- query person
  b <- queryMaybe birthday  -- Maybe not match
  on $ just (#name p) .=. (? #name) b
  return $ (,) |$| p |*| b

sameBirthdayHeisei' :: Relation () (Day, Int64)
sameBirthdayHeisei' = aggregateRelation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  wheres $ #day b .>=. value (fromGregorian 1989 1 8)
  gbd <- groupBy $ #day b
  having $ count (#name p) .>. value (1 :: Int64)
  return $ (,) |$| gbd |*| count (#name p)

sameBirthdayHeisei :: Relation () (Day, Int64)
sameBirthdayHeisei = aggregateRelation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  let birthDay = #day b
  wheres $ birthDay .>=. value (fromGregorian 1989 1 8)
  gbd <- groupBy birthDay
  let personCount = count $ #name p
  having $ personCount .>. value (1 :: Int64)
  return $ (,) |$| gbd |*| personCount
  -- return $ (,) |$| gbd |*| birthDay

birthdayHeiseiDesc :: Relation () (Day, Int64)
birthdayHeiseiDesc = aggregateRelation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  let birthDay = #day b
  wheres $ birthDay .>=. value (fromGregorian 1989 1 8)
  gbd <- groupBy birthDay
  let personCount = count $ #name p
  orderBy personCount Desc
  return $ (,) |$| gbd |*| personCount

personAndBirthdayO :: Relation () (Person, Birthday)
personAndBirthdayO = relation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  orderBy (#day b) Asc  -- Specify ordering key
  orderBy (#name p) Asc
  return $ (,) |$| p |*| b

specifyPerson :: Relation String (Person, Birthday)
specifyPerson = relation' $ do
  pb <- query personAndBirthday
  (ph, ()) <- placeholder (\ph' -> wheres $ #name ((! #fst) pb) .=. ph')
  return (ph, pb)


personAndBirthdayT :: Relation () PersonAndBirthday
personAndBirthdayT = relation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  return $ PersonAndBirthday |$| p |*| b  -- Build record phantom type

uncurryPB :: Pi (Person, Birthday) PersonAndBirthday
uncurryPB =  PersonAndBirthday |$| fst' |*| snd'

personAndBirthdayP :: Relation Person PersonAndBirthday
personAndBirthdayP = relation' $ do
  p <- query person
  b <- query birthday
  (ph, ()) <- placeholder (\ph' -> on $ p .=. ph')
  return $ (ph, PersonAndBirthday |$| p |*| b)

personAndBirthdayP2 :: Relation Person PersonAndBirthday
personAndBirthdayP2 = relation' $ do
  p <- query person
  b <- query birthday
  (ph0, ()) <- placeholder (\ph0' -> on $ #name   p   .=. ph0')
  (ph1, ()) <- placeholder (\ph1' -> on $ #age    p   .=. ph1')
  (ph2, ()) <- placeholder (\ph2' -> on $ #family p   .=. ph2')

  return (Person |$| ph0 |*| ph1 |*| ph2, PersonAndBirthday |$| p |*| b)

agesOfFamilies :: Relation () (String, Maybe Int32)
agesOfFamilies = aggregateRelation $ do
  p <- query person
  gFam <- groupBy $ #family p    -- Specify grouping key
  return $ (,) |$| gFam |*| sum' (#age p) -- Aggregated results

agesOfFamiliesO :: Relation () (String, Maybe Int32)
agesOfFamiliesO = aggregateRelation $ do
  p <- query person
  gFam <- groupBy $ #family p
  let s = sum' (#age p)
  orderBy s Desc    -- Only aggregated value is allowed to pass
  orderBy gFam Asc
  return $ (,) |$| gFam |*| s

ageRankOfFamilies :: Relation () (Int64, String, Int32)
ageRankOfFamilies = relation $ do
  p <- query person
  return $
    (,,)
    |$| rank `over` do
          partitionBy $ (! #family) p  -- Monad to build window
          orderBy (#age p) Desc
    |*| #family p
    |*| #age p

nonsense :: Relation () (Person, Birthday)
nonsense = personAndBirthday `union` personAndBirthdayO

heiseiBirthday :: MonadRestrict Flat m
               => Record Flat Birthday -> m ()
heiseiBirthday b = wheres $ #day b .>=. value (fromGregorian 1989 1 8)

orderByName :: Monad m
            => Record c Person
            -> Orderings c m ()
orderByName p = orderBy (#name p) Asc
