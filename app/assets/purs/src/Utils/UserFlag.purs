module Utils.UserFlag
  ( UserFlag(..)
  , set

  , dismissedCollaborationWelcomeMessage
  , dismissedCommunityAcceptanceBanner
  , dismissedCommunityEarnKarmaBanner
  , dismissedCommunityGiveRocketAwardBanner
  , dismissedCommunityReceiveRocketAwardBanner
  , dismissedCommunityFeedWelcomeBanner
  , dismissedHubFiltersPreferencesCTA
  , scheduledWithServiceProvider
  ) where

import Prelude

import Effect.Aff (Aff)
import Elmish.Foreign (class CanReceiveFromJavaScript)
import Utils.API as API

newtype UserFlag = UserFlag String
derive newtype instance Eq UserFlag
derive newtype instance Ord UserFlag
derive newtype instance CanReceiveFromJavaScript UserFlag

set :: UserFlag -> Aff Unit
set = API.post "flag_set_path" \call flag ->
  call { flag_name: flag } >>= API.ignoreResponse

----
-- These flag names are duplicated in Ruby, in user.rb
--

dismissedCollaborationWelcomeMessage = UserFlag "has-dismissed-collaboration-welcome-message" :: UserFlag
dismissedCommunityAcceptanceBanner = UserFlag "has-dismissed-community-acceptance-banner" :: UserFlag
dismissedCommunityEarnKarmaBanner = UserFlag "has-dismissed-community-earn-karma-banner" :: UserFlag
dismissedCommunityGiveRocketAwardBanner = UserFlag "has-dismissed-community-give-rocket-award-banner" :: UserFlag
dismissedCommunityReceiveRocketAwardBanner = UserFlag "has-dismissed-community-receive-rocket-award-banner" :: UserFlag
dismissedCommunityFeedWelcomeBanner = UserFlag "has-dismissed-community-feed-welcome-banner" :: UserFlag
dismissedHubFiltersPreferencesCTA = UserFlag "has-dismissed-hub-filters-preferences-cta" :: UserFlag

-- APP-7558 Service Provider MVP
scheduledWithServiceProvider = UserFlag "app-7558-has-scheduled-with-service-provider" :: UserFlag
