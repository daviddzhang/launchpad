module Utils.Diff
  ( diff, Diff(..)
  ) where

import Prelude

import Control.Monad.State (execState, gets, modify_)
import Data.Array (catMaybes, concat, elem, fromFoldable, nub, null, reverse, (!!))
import Data.Array as A
import Data.Int (even)
import Data.List (List(..), (:))
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Traversable (sequence, traverse)
import Data.Tuple (Tuple(..))
import Data.Unfoldable (unfoldr)

data Diff a = NoDiff a | Added a | Removed a | Replaced { old :: a, new :: a }

instance sDiff :: Show a => Show (Diff a) where
  show = case _ of
    NoDiff a -> "NoDiff " <> show a
    Added a -> "Added " <> show a
    Removed a -> "Removed " <> show a
    Replaced { old, new } -> "Replaced " <> show old <> " " <> show new

-- | Myers (grid-path-based) diff algorithm.
--
-- This is an implementation of the Myers diffing algorithm. See tutorials
-- https://www.nathaniel.ai/myers-diff/ and
-- https://blog.jcoglan.com/2017/02/12/the-myers-diff-algorithm-part-1/, and the
-- original paper here: http://www.xmailserver.org/diff2.pdf
--
-- The algorithm is based on representing the problem as a rectangular grid,
-- with rows labeled after the characters in the source string, and columns -
-- after the destination string. The algorithm works by "stepping" between nodes
-- of the grid. A step to the right means inserting an element of the
-- destination string. As step down means deleting an element of the source
-- string. When a cell's row and column are labeled by equal elements, that cell
-- has a diagonal edge going through it, meaning that a "free" step is possible
-- from top-left to bottom-right node across the cell (see illustrations in
-- links above).
--
-- With this representation in mind, it's easy to see that the top-left corner
-- of the grid represents the source string, and the bottom-right corner - the
-- destination string. Any path along the edges from top-left to bottom-right
-- will represent a sequence of insertions and deletions ("edit sequence") that
-- morph the source string into the destination string. Then, the _shortest_
-- path from corner to corner will give us the shortest edit sequence.
--
-- This implementation employs the "expanding wave" search algorithm in
-- `pathSearch` to find the shortest path: the "wave front" starts as a single
-- node in the top-left corner and with each step expands to neighbouring nodes,
-- while jumping across diagonals within the same step. The whole thing runs in
-- the State monad, with state being a Map, which keeps a record of
-- already-visited nodes and links each node back to its _preceding_ node (i.e.
-- from where the wave came to it).
--
-- After running the wave all the way to the bottom-right corner, the result
-- `backTraces` is a Map of visited nodes, each linked to its preceding node.
-- After that I restore the `steps` list by following the preceding-node links
-- from bottom-right corner all the way back.
--
-- Finally, I make sure to collapse the Added->Removed and Removed->Added pairs
-- into a single Replaced step, because we need those in the consuming UI.
diff :: forall a. Eq a => Array a -> Array a -> Array (Diff a)
diff xs ys = reverse $ fromFoldable $ collapseReplacements steps
  where
    collapseReplacements Nil = Nil
    collapseReplacements (Added new : Removed old : ss) = Replaced { old, new } : collapseReplacements ss
    collapseReplacements (Removed old : Added new : ss) = Replaced { old, new } : collapseReplacements ss
    collapseReplacements (x:ss) = x : collapseReplacements ss

    steps =
      bottomRight # unfoldr \toCell ->
        Map.lookup toCell backTraces >>= \fromCell ->
          Tuple <$> stepToDiff fromCell toCell <@> fromCell

    stepToDiff fromCell toCell
      | fromCell.i == toCell.i = Added <$> ys !! fromCell.j
      | fromCell.j == toCell.j = Removed <$> xs !! fromCell.i
      | otherwise = NoDiff <$> xs !! fromCell.i

    backTraces = execState (pathSearch [{ i: 0, j: 0 }]) Map.empty

    pathSearch waveFront = do
      newFront <- nub <<< concat <$> traverse moveFromCell waveFront
      when (not null newFront && not elem bottomRight newFront) $
        pathSearch newFront

    moveFromCell { i, j } = catMaybes <$> sequence moves
      where
        moves = diagonal <> orthogonal

        diagonal
          | hasDiagonal { i, j } = [moveToCell { i, j } { i: i+1, j: j+1 }]
          | otherwise = []

        orthogonal
          | even (i + j) = [down, right]
          | otherwise = [right, down]

        down = moveToCell { i, j } { i, j: j+1 }
        right = moveToCell { i, j } { i: i+1, j }

    moveToCell fromCell { i, j }
      | i > A.length xs || j > A.length ys =
          pure Nothing
      | otherwise = do
          alreadyVisited <- gets $ Map.member { i, j }
          if alreadyVisited then
            pure Nothing
          else do
            modify_ $ Map.insert { i, j } fromCell
            if hasDiagonal { i, j } then
              moveToCell { i, j } { i: i+1, j: j+1 }
            else
              pure $ Just { i, j }

    hasDiagonal { i, j } =
      { i, j } /= bottomRight && xs !! i == ys !! j

    bottomRight = { i: A.length xs, j: A.length ys }
