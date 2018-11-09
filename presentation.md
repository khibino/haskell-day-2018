% Haskell 導入から HRR まで
% 日比野 啓
% 2018-11-10

自己紹介
=====

* 日比野 啓 / @khibino
* ここ 8年ぐらいは職業 Haskell プログラマ
* とある ISP で契約管理、認証バックエンドのシステム開発の仕事をしていた

Haskell を導入した話
=====

Glue言語の置き換え検討
=====

* Perl に代わる Glue言語を検討したくなった - 2008年ぐらいから
    * 気がついたら他にメンテナンスする人がいない
    * 実行前の検査が弱いのがつらい
    * Java のバッチプログラムを呼び出す大量の Perl script
        * ISP の会員管理、契約管理、請求処理等のデータベーストランザクションを行なうバッチ処理プログラムが Java で記述される
        * 当時、 Perl だと Java より Linux (UNIX系) との親和性が高い
    * ファイル連携の通信とかもやってる

Glue言語の置き換え検討
=====

* Perl に代わる Glue言語を検討したくなった - 2008年ぐらいから
* 欲しかった特徴
    * 実行前の検査
    * unix との親和性
    * (スクリプト実行)

検討した言語
=====

* Common Lisp
    * マクロでコンパイル時(実行前)の検査を柔軟に記述できる
    * やっぱり型が欲しい
* OCaml
    * 試しているときに Haskell に興味
* Haskell
    * unix package よくできていそう
    * template-haskell でコンパイル時検査もできる

Haskell 導入前の検討
=====

* Linux と親和性の高い処理系 - unix
* ファイル操作 - filepath, directory
    * プロセス制御 - process

Haskell 導入
=====

* 2010.04 くらいから (当時は debian lenny, GHC 6.8)
* 新たに開発するものについては、perl で記述していたレイヤーを Haskell で開発
* ファイル操作、プロセス制御中心
* Haskell のプログラムはあまり大きくない
   * 1年後 アプリ数 16, 2700行
   * 2年後 アプリ数 22, 5800行

書きやすかったもの - テキスト処理
=====

* Parser Combinator が使いやすいのでテキスト処理が書きやすい
    * トラフィックデータ加工
    * 全文検索システム向けに IRC ログを加工
    * 接続ログの集計
    * トラブル対象者のログからの抽出
    * 認証データの加工処理、データ移行

書きやすかったもの - プロセス制御
=====

* Parser Combinator でプログラムの出力の解釈も書きやすい
    * ビルドシステム
        * Debianizing IBM DB2
	* 内製 Haskell Package

書きやすかったもの - マルチスレッド
=====

* STM があるので、状態のあるマルチスレッドプログラムが書きやすい
    * オープンリゾルバ検出システム
    * バックエンド接続認証サーバー

書きやすかったもの - DSL
=====

* Monad があるので Domain Specific Language (DSL) が定義しやすい
    * Haskell Relational Record
        * 債権データの集計処理
        * 認証データ管理システム

Haskell Relational Record の紹介
=====


Haskell Relational Record の紹介
=====

ここからは SQL の知識が必要です

Haskell Relational Record
=====

* SQL を組み立てる Haskell 内 DSL
    * http://khibino.github.io/haskell-relational-record/
* 部品化と型安全
    * SQL の誤りをコンパイル時に発見
* コンパイル時に Database Schema を読み込んで型定義を生成
* 2013.03 くらいから開発


SQLの結合と集合演算
=====

<!-- When building joined query: -->
次のような結合クエリを考える:

~~~~~ {.sql}
SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
           T1.name AS f3, T1.day AS f4
      FROM EXAMPLE.person T0 INNER JOIN EXAMPLE.birthday T1
	ON (T0.name = T1.name)
~~~~~

<!-- Like the following set operation: -->
次のような集合演算:

$$\{ (p, b) | p \in P, b \in B, \pi_{P.name}(p) = \pi_{B.name}(b) \}$$


集合演算とリストモナド
=====

$$\{ (p, b) | p \in P, b \in B, \pi_{P.name}(p) = \pi_{B.name}(b) \}$$

* ` <- ` と $\in$

~~~~~ {.haskell}
   [ (p, b)
   | p <- person, b <- birthday , P.name p == B.name b ]
   -- List 内包表記

do { p <- person; b <- birthday; guard (P.name p == B.name b)
   ; return (p, b) }  -- List モナド
~~~~~

2つは同じ意味


DSL using Haskell!
=====

~~~~~ {.haskell}
  do { p <- person; b <- birthday; guard (P.name p == B.name b)
     ; return (p, b) } -- List モナド
~~~~~

<!-- Building a joined query like list monad: -->
結合クエリをリストモナド風に組み上げる:

~~~~~ {.haskell}
personAndBirthday :: Relation () (Person, Birthday)
personAndBirthday = relation $ do
  p <- query person
  b <- query birthday
  on $ p ! Person.name' .=. b ! Birthday.name'
  return $ (,) |$| p |*| b
~~~~~

=====

Haskell のコードは
SQL との対応が雰囲気で分かれば
細かいところは気にしなくて大丈夫です


組み上がった結合クエリ
=====

~~~~~ {.haskell}
personAndBirthday :: Relation () (Person, Birthday)
personAndBirthday =  relation $ do
  p <- query person
  b <- query birthday  -- 結合の積が蓄積される
  on $ p ! Person.name' .=. b ! Birthday.name'
  return $ (,) |$| p |*| b
~~~~~

~~~~~ {.sql}
SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
           T1.name AS f3, T1.day AS f4
      FROM EXAMPLE.person T0 INNER JOIN EXAMPLE.birthday T1
        ON (T0.name = T1.name)
~~~~~

組み上がった結合クエリ - 列多相
=====

~~~~~ {.haskell}
personAndBirthday :: Relation () (Person, Birthday)
personAndBirthday =  relation $ do
  p <- query person
  b <- query birthday  -- 結合の積が蓄積される
  on $ #name p .=. #name b
  return $ (,) |$| p |*| b
~~~~~

~~~~~ {.sql}
SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
           T1.name AS f3, T1.day AS f4
      FROM EXAMPLE.person T0 INNER JOIN EXAMPLE.birthday T1
        ON (T0.name = T1.name)
~~~~~


=====

Haskell のコードは
SQL との対応が雰囲気で分かれば
細かいところは気にしなくて大丈夫です。


例 / 左外部結合
=====

~~~~~ {.haskell}
personAndBirthdayL :: Relation () (Person, Maybe Birthday)
personAndBirthdayL =  relation $ do
  p <- query person
  b <- queryMaybe birthday
  on $ just (#name p) .=. (? #name) b
  return $ (,) |$| p |*| b
~~~~~

<!-- generates left-joined SQL: -->
左結合クエリの生成:

~~~~~ {.sql}
SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
           T1.name AS f3, T1.day AS f4
      FROM EXAMPLE.person T0 LEFT JOIN EXAMPLE.birthday T1
        ON (T0.name = T1.name)
~~~~~

例 / 集約
=====

~~~~~ {.haskell}
agesOfFamilies :: Relation () (String, Maybe Int32)
agesOfFamilies = aggregateRelation $ do
  p <- query person
  gFam <- groupBy $ #family p    -- Specify grouping key
  return $ (,) |$| gFam |*| sum' (#age p) -- Aggregated results
~~~~~

家族ごとの年齢の合計

生成された SQL:

~~~~~ {.sql}
SELECT ALL T0.family AS f0, SUM(T0.age) AS f1
      FROM EXAMPLE.person T0
  GROUP BY T0.family
~~~~~

例 / 絞り込み
=====

~~~~~ {.haskell}
sameBirthdayHeisei' :: Relation () (Day, Int64)
sameBirthdayHeisei' =  aggregateRelation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  wheres $
    b ! Birthday.day' .>=. value (fromGregorian 1989 1 8)
  gbd <- groupBy $ b ! Birthday.day'
  having $ count (#name p) .>. value (1 :: Int64)
  return $ (,) |$| gbd |*| count (#name p)
~~~~~

<!-- counts people with the same birthday, who were born in the Heisei period. -->
平成生まれで同じ誕生日の人を数える


例 / 絞り込み / SQL
=====

生成された SQL:

~~~~~ {.sql}
SELECT ALL T1.day AS f0, COUNT(T0.name) AS f1
      FROM EXAMPLE.person T0 INNER JOIN EXAMPLE.birthday T1
        ON (T0.name = T1.name)
     WHERE (T1.day >= DATE '1989-01-08')
  GROUP BY T1.day
    HAVING (COUNT(T0.name) > 1)
~~~~~

例 / 絞り込み - let
=====

~~~~~ {.haskell}
sameBirthdayHeisei :: Relation () (Day, Int64)
sameBirthdayHeisei =  aggregateRelation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  let birthDay = #day b
  wheres $ birthDay .>=. value (fromGregorian 1989 1 8)
  gbd <- groupBy birthDay
  let personCount = count $ #name p
  having $ personCount .>. value 1
  return $ (,) |$| gbd |*| personCount
~~~~~

`#name b` や `count $ #name p` を変数に割り当てて再利用できている


例 / 結果の順序
=====

~~~~~ {.haskell}
personAndBirthdayO :: Relation () (Person, Birthday)
personAndBirthdayO = relation $ do
  p <- query person
  b <- query birthday
  on $ #name p .=. #name b
  orderBy (#day b) Asc  -- Specify ordering key
  orderBy (#name p) Asc
  return $ (,) |$| p |*| b
~~~~~

<!-- orders by birthday and then name: -->
誕生日と名前で順番を付ける:

~~~~~ {.sql}
SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
           T1.name AS f3, T1.day AS f4
      FROM EXAMPLE.person T0 INNER JOIN EXAMPLE.birthday T1
        ON (T0.name = T1.name)
  ORDER BY T1.day ASC, T0.name ASC
~~~~~

例 / プレースフォルダー
=====

~~~~~ {.haskell}
specifyPerson :: Relation String (Person, Birthday)
specifyPerson = relation' $ do
  pb <- query personAndBirthday
  (ph, ()) <- placeholder (\ph' -> wheres $ #name ((! #fst) pb) .=. ph')
  return (ph, pb)
~~~~~

<!-- specifies a person name using a placeholder: -->
プレースフォルダーを使って名前を指定:

~~~~~ {.sql}
SELECT ALL T2.f0 AS f0, T2.f1 AS f1, T2.f2 AS f2,
           T2.f3 AS f3, T2.f4 AS f4
  FROM (SELECT ALL T0.name AS f0, T0.age AS f1, T0.family AS f2,
	           T1.name AS f3, T1.day AS f4
              FROM EXAMPLE.person T0 INNER JOIN
                   EXAMPLE.birthday T1
                ON (T0.name = T1.name)) T2
 WHERE (T2.f0 = ?)
~~~~~

例 / Window 関数
=====

<!-- Building windows: -->
window の組み立て:

~~~~~ {.haskell}
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
~~~~~

<!-- age ranking per family: -->
家族ごとの年齢の順位:

~~~~~ {.sql}
SELECT ALL
       RANK() OVER (PARTITION BY T0.family
                    ORDER BY T0.age DESC) AS f0,
       T0.family AS f1, T0.age AS f2
  FROM PUBLIC.my_table T0
~~~~~

Demo
=====



まとめ
=====



Question
=====
