-- This component implements debouncing for multiple items.
--
-- The logic is the following:
--
-- 1. When an item is in need of "saving" (or, perhaps, "committing"), the
--    consumer calls the `enqueue` function, which issues an `EnqueueItem`
--    message, which includes the item itself, plus the time at which it needs
--    to be committed, which is calculated as "now + some delay".
-- 2. When this message is handled, the item is put on the queue, replacing the
--    same item if it was already there. At the same time, the
--    `PushEligibleItems` message is issued with a delay.
-- 3. When this message is handled, the handler picks all items in the queue
--    whose saving time is less than "now", and sends them all to server, then
--    removed committed items from the queue.
-- 4. Finally, if after dequeueing, the queue is not empty, the
--    `PushEligibleItems` message is issued again.
--
module Utils.Debouncer
  ( Args
  , Message(..)
  , State
  , enqueue
  , init
  , update

  -- Back door for testing
  , mockSkipDebounceDelay
  ) where

import Prelude

import Data.Array (cons, filter, null, partition)
import Data.DateTime (DateTime, adjust)
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Time.Duration (Milliseconds(..))
import Effect.Aff (Aff, delay)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Now (nowDateTime)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Elmish (Transition, fork, forkMaybe)
import Test.Cleanup (class MonadCleanup, CleanupT, cleanupAction)

data Message item
  = EnqueueItem DateTime item
  | PushItemsOlderThan DateTime
  | ItemsCommitted (Array item) -- Intended to be intercepted by the consumer

type Args item =
  { isSameItem :: item -> item -> Boolean
  , commitItem :: item -> Aff Unit
  }

type State item = Array { when :: DateTime, item :: item }

init :: forall item. State item
init = []

update :: forall item
   . Args item
  -> State item
  -> Message item
  -> Transition (Message item) (State item)
update _ state (ItemsCommitted _) =
  pure state

update args state (EnqueueItem when item) = do
  pushEligibleItems
  pure $
    state
    # filter (\q -> not $ args.isSameItem q.item item) -- Remove this item from the queue
    # cons { when, item } -- then re-add it with new time of delivery

update args state (PushItemsOlderThan now) = do
  let { yes: eligible, no: remaining } = state # partition \q -> q.when <= now
  forkMaybe do
    for_ eligible \{ item } -> args.commitItem item
    if null eligible
      then pure Nothing
      else pure $ Just $ ItemsCommitted $ _.item <$> eligible
  when (not $ null remaining)
    pushEligibleItems
  pure remaining

enqueue :: forall item. item -> Transition (Message item) Unit
enqueue item = fork do
  now <- liftEffect nowDateTime
  let when = adjust (delayToCommit unit) now # fromMaybe now
  pure $ EnqueueItem when item

pushEligibleItems :: forall item. Transition (Message item) Unit
pushEligibleItems = fork do
  delay (delayToCommit unit)
  PushItemsOlderThan <$> liftEffect nowDateTime

delayToCommit :: Unit -> Milliseconds
delayToCommit _
  | unsafePerformEffect (Ref.read skipDelay__) = Milliseconds 0.0
  | otherwise = Milliseconds 500.0



---------------------------------
-- Mockability API for testing --
---------------------------------

-- | For the duration of the given test spec, makes the Debouncer commit items
-- | immediately, rather than after a delay.
mockSkipDebounceDelay :: forall m. MonadEffect m => MonadCleanup m => CleanupT m Unit
mockSkipDebounceDelay = do
  liftEffect $ Ref.write true skipDelay__
  cleanupAction $ liftEffect $ Ref.write false skipDelay__

skipDelay__ :: Ref Boolean
skipDelay__ = unsafePerformEffect $ Ref.new false
