module HW.Template.PodcastFeed
  ( podcastFeedTemplate
  )
where

import qualified Data.Text
import qualified Data.XML.Types
import qualified HW.Type.Audio
import qualified HW.Type.BaseUrl
import qualified HW.Type.Date
import qualified HW.Type.Duration
import qualified HW.Type.Episode
import qualified HW.Type.Guid
import qualified HW.Type.Number
import qualified HW.Type.Route
import qualified HW.Type.Size
import qualified HW.Type.Title
import qualified Text.Feed.Constructor
import qualified Text.Feed.Types
import qualified Text.RSS.Syntax

podcastFeedTemplate
  :: HW.Type.BaseUrl.BaseUrl
  -> [HW.Type.Episode.Episode]
  -> Text.Feed.Types.Feed
podcastFeedTemplate baseUrl episodes =
  Text.Feed.Constructor.feedFromRSS $ Text.RSS.Syntax.RSS
    "2.0"
    [ ( "xmlns:atom"
      , [Data.XML.Types.ContentText "http://www.w3.org/2005/Atom"]
      )
    , ( "xmlns:itunes"
      , [ Data.XML.Types.ContentText
            "http://www.itunes.com/dtds/podcast-1.0.dtd"
        ]
      )
    ]
    (makeChannel baseUrl episodes)
    []

makeChannel
  :: HW.Type.BaseUrl.BaseUrl
  -> [HW.Type.Episode.Episode]
  -> Text.RSS.Syntax.RSSChannel
makeChannel baseUrl episodes =
  let
    channel =
      Text.RSS.Syntax.nullChannel "Haskell Weekly" $ channelLink baseUrl
    items = fmap (episodeToItem baseUrl) episodes
  in channel
    { Text.RSS.Syntax.rssCopyright = channelCopyright
    , Text.RSS.Syntax.rssDescription = channelDescription
    , Text.RSS.Syntax.rssImage = channelImage baseUrl
    , Text.RSS.Syntax.rssItems = items
    , Text.RSS.Syntax.rssLanguage = channelLanguage
    , Text.RSS.Syntax.rssChannelOther = channelOther baseUrl
    }

channelCopyright :: Maybe Data.Text.Text
channelCopyright = Just "\xa9 2019 Taylor Fausak"

channelDescription :: Data.Text.Text
channelDescription = Data.Text.unwords
  [ "Haskell Weekly covers the Haskell progamming language. Listen to"
  , "professional software developers discuss using functional programming to"
  , "solve real-world business problems. Each episode uses a conversational"
  , "two-host format and runs for about 15 minutes."
  ]

channelImage :: HW.Type.BaseUrl.BaseUrl -> Maybe Text.RSS.Syntax.RSSImage
channelImage baseUrl = Just $ Text.RSS.Syntax.nullImage
  (HW.Type.Route.routeToTextWith baseUrl HW.Type.Route.RouteLogo)
  "Haskell Weekly"
  (channelLink baseUrl)

channelLanguage :: Maybe Data.Text.Text
channelLanguage = Just "en-US"

channelLink :: HW.Type.BaseUrl.BaseUrl -> Text.RSS.Syntax.URLString
channelLink baseUrl =
  HW.Type.Route.routeToTextWith baseUrl HW.Type.Route.RoutePodcast

channelOther :: HW.Type.BaseUrl.BaseUrl -> [Data.XML.Types.Element]
channelOther baseUrl =
  [ Data.XML.Types.Element
    "atom:link"
    [ ( "href"
      , [ Data.XML.Types.ContentText $ HW.Type.Route.routeToTextWith
            baseUrl
            HW.Type.Route.RoutePodcastFeed
        ]
      )
    , ("rel", [Data.XML.Types.ContentText "self"])
    , ("type", [Data.XML.Types.ContentText "application/rss+xml"])
    ]
    []
  , Data.XML.Types.Element
    "itunes:author"
    []
    [Data.XML.Types.NodeContent $ Data.XML.Types.ContentText "Taylor Fausak"]
  , Data.XML.Types.Element
    "itunes:category"
    [("text", [Data.XML.Types.ContentText "Technology"])]
    []
  , Data.XML.Types.Element
    "itunes:explicit"
    []
    [Data.XML.Types.NodeContent $ Data.XML.Types.ContentText "clean"]
  , Data.XML.Types.Element "itunes:owner" [] $ fmap
    Data.XML.Types.NodeElement
    [ Data.XML.Types.Element
      "itunes:email"
      []
      [ Data.XML.Types.NodeContent
          $ Data.XML.Types.ContentText "taylor@fausak.me"
      ]
    , Data.XML.Types.Element
      "itunes:name"
      []
      [Data.XML.Types.NodeContent $ Data.XML.Types.ContentText "Taylor Fausak"]
    ]
  ]

episodeToItem
  :: HW.Type.BaseUrl.BaseUrl
  -> HW.Type.Episode.Episode
  -> Text.RSS.Syntax.RSSItem
episodeToItem baseUrl episode =
  let item = Text.RSS.Syntax.nullItem $ itemTitle episode
  in
    item
      { Text.RSS.Syntax.rssItemDescription = Nothing
      , Text.RSS.Syntax.rssItemEnclosure = itemEnclosure episode
      , Text.RSS.Syntax.rssItemGuid = itemGuid episode
      , Text.RSS.Syntax.rssItemLink = itemLink baseUrl episode
      , Text.RSS.Syntax.rssItemOther = itemOther episode
      , Text.RSS.Syntax.rssItemPubDate = itemPubDate episode
      }

itemEnclosure :: HW.Type.Episode.Episode -> Maybe Text.RSS.Syntax.RSSEnclosure
itemEnclosure episode = Just $ Text.RSS.Syntax.nullEnclosure
  (HW.Type.Audio.audioToText $ HW.Type.Episode.episodeAudio episode)
  (Just . HW.Type.Size.sizeToInteger $ HW.Type.Episode.episodeSize episode)
  "audio/mpeg"

itemGuid :: HW.Type.Episode.Episode -> Maybe Text.RSS.Syntax.RSSGuid
itemGuid =
  Just
    . (\guid -> guid { Text.RSS.Syntax.rssGuidPermanentURL = Just False })
    . Text.RSS.Syntax.nullGuid
    . HW.Type.Guid.guidToText
    . HW.Type.Episode.episodeGuid

itemLink
  :: HW.Type.BaseUrl.BaseUrl
  -> HW.Type.Episode.Episode
  -> Maybe Text.RSS.Syntax.URLString
itemLink baseUrl =
  Just
    . HW.Type.Route.routeToTextWith baseUrl
    . HW.Type.Route.RouteEpisode
    . HW.Type.Episode.episodeNumber

itemOther :: HW.Type.Episode.Episode -> [Data.XML.Types.Element]
itemOther episode =
  [ Data.XML.Types.Element
    "itunes:author"
    []
    [Data.XML.Types.NodeContent $ Data.XML.Types.ContentText "Taylor Fausak"]
  , Data.XML.Types.Element
    "itunes:duration"
    []
    [ Data.XML.Types.NodeContent
      . Data.XML.Types.ContentText
      . HW.Type.Duration.durationToText
      $ HW.Type.Episode.episodeDuration episode
    ]
  , Data.XML.Types.Element
    "itunes:episode"
    []
    [ Data.XML.Types.NodeContent
      . Data.XML.Types.ContentText
      . HW.Type.Number.numberToText
      $ HW.Type.Episode.episodeNumber episode
    ]
  ]

itemPubDate :: HW.Type.Episode.Episode -> Maybe Text.RSS.Syntax.DateString
itemPubDate = Just . HW.Type.Date.dateToRfc2822 . HW.Type.Episode.episodeDate

itemTitle :: HW.Type.Episode.Episode -> Data.Text.Text
itemTitle = HW.Type.Title.titleToText . HW.Type.Episode.episodeTitle
