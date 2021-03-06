'**********************************************************
'**  Video Player Example Application - Show Feed
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'******************************************************
'** Set up the show feed connection object
'** This feed provides the detailed list of shows for
'** each subcategory (categoryLeaf) in the category
'** category feed. Given a category leaf node for the
'** desired show list, we'll hit the url and get the
'** results.
'******************************************************

Function InitShowFeedConnection(category As Object) As Object

    if validateParam(category, "roAssociativeArray", "initShowFeedConnection") = false return invalid

    m.api_key = loadRegistrationToken()
    if len(m.api_key) = 0 then
        'Use default API key
        m.api_key = "0ada3036d1cf0ee0e52fb83ba8a06f3aac967243"
    endif

    conn = CreateObject("roAssociativeArray")
    conn.UrlShowFeed  = category.feed

    conn.Timer = CreateObject("roTimespan")

    conn.LoadShowFeed    = load_show_feed
    conn.ParseShowFeed   = parse_show_feed
    conn.InitFeedItem    = init_show_feed_item

    print "created feed connection for " + conn.UrlShowFeed
    return conn

End Function


'******************************************************
'Initialize a new feed object
'******************************************************
Function newShowFeed() As Object

    o = CreateObject("roArray", 5, true)
    return o

End Function


'***********************************************************
' Initialize a ShowFeedItem. This sets the default values
' for everything.  The data in the actual feed is sometimes
' sparse, so these will be the default values unless they
' are overridden while parsing the actual game data
'***********************************************************
Function init_show_feed_item() As Object
    o = CreateObject("roAssociativeArray")

    o.ContentId        = ""
    o.Title            = ""
    o.ContentType      = ""
    o.ContentQuality   = ""
    o.Synopsis         = ""
    o.Genre            = ""
    o.Runtime          = ""
    o.StreamQualities  = CreateObject("roArray", 5, true)
    o.StreamBitrates   = CreateObject("roArray", 5, true)
    o.StreamUrls       = CreateObject("roArray", 5, true)

    return o
End Function


'*************************************************************
'** Grab and load a show detail feed. The url we are fetching
'** is specified as part of the category provided during
'** initialization. This feed provides a list of all shows
'** with details for the given category feed.
'*********************************************************
Function load_show_feed(conn As Object) As Dynamic

    if validateParam(conn, "roAssociativeArray", "load_show_feed") = false return invalid

    print "url: " + conn.UrlShowFeed
    http = NewHttp(conn.UrlShowFeed)

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    print "Request Time: " + itostr(m.Timer.TotalMilliseconds())

    feed = newShowFeed()
    xml=CreateObject("roXMLElement")
    if not xml.Parse(rsp) then
        print "Can't parse feed"
        return feed
    endif

    if xml.results.video[0].GetName() <> "video" then
        print "no feed tag found"
        return feed
    endif

    if islist(xml.results) = false then
        print "no feed body found"
        return feed
    endif

    m.Timer.Mark()
    m.ParseShowFeed(xml, feed)
    print "Show Feed Parse Took : " + itostr(m.Timer.TotalMilliseconds())

    return feed

End Function


'**************************************************************************
'**************************************************************************
Function parse_show_feed(xml As Object, feed As Object) As Void

    url = ""
    showCount = 0
    showList = xml.results.GetChildElements()

    api_key = loadRegistrationToken()
    if len(api_key) = 0 then
        'Use default API key
        api_key = "4eac034cacb290fba9a5335f1e34e298d2a0d07b"
    endif

    for each curShow in showList

        'for now, don't process meta info about the feed size
        if curShow.GetName() = "resultLength" or curShow.GetName() = "endIndex" then
            goto skipitem
        endif

        item = init_show_feed_item()

        'fetch all values from the xml for the current show
        item.hdImg            = validstr(curShow.image.screen_url.GetText())
        item.sdImg            = validstr(curShow.image.screen_url.GetText())
        item.ContentId        = validstr(curShow.id.GetText())
        item.Title            = validstr(curShow.name.GetText())
        item.Description      = validstr(curShow.deck.GetText())
        'item.ContentType      = validstr(curShow.contentType.GetText())
        'item.ContentQuality   = validstr(curShow.contentQuality.GetText())
        item.Synopsis         = validstr(curShow.deck.GetText())
        'item.Genre            = validstr(curShow.genres.GetText())
        'item.Runtime          = validstr(curShow.runtime.GetText())
        'item.HDBifUrl         = validstr(curShow.hd_url.GetText())
        'item.SDBifUrl         = validstr(curShow.sdBifUrl.GetText())
        item.StreamFormat     = validstr(curShow.streamFormat.GetText())
        if item.StreamFormat  = "" then  'set default streamFormat to mp4 if doesn't exist in xml
            item.StreamFormat = "mp4"
        endif

        isHD = false
        if len(validstr(curShow.hd_url.GetText())) > 0 then
            isHD = true
        endif

        date = validstr(curShow.publish_date.GetText())
        month = mid(date, 6,2)
        day = mid(date, 9,2)
        year = left(date, 4)
        item.ReleaseDate = month + "/" + day + "/" + year

        'map xml attributes into screen specific variables
        item.ShortDescriptionLine1 = item.Title
        item.ShortDescriptionLine2 = item.Description
        item.HDPosterUrl           = item.hdImg
        item.SDPosterUrl           = item.sdImg

        item.Length = validstr(curShow.length_seconds.GetText())
        'item.Categories = CreateObject("roArray", 5, true)
        'item.Categories.Push(item.Genre)
        'item.Actors = CreateObject("roArray", 5, true)
        'item.Actors.Push(item.Genre)
        'item.Description = item.Synopsis

        'Set Default screen values for items not in feed
        item.HDBranded = isHD
        item.IsHD = isHD
        'item.StarRating = "90"
        item.ContentType = "episode"

        'media may be at multiple bitrates, so parse and build arrays
        'for idx = 0 to 4
            'e = curShow.media[idx]
            'if e  <> invalid then
                'item.StreamBitrates.Push(strtoi(validstr(e.streamBitrate.GetText())))
                'item.StreamQualities.Push(validstr(e.streamQuality.GetText()))
                'item.StreamUrls.Push(validstr(e.streamUrl.GetText()))
            'endif
        'next idx

        if isHD = true then
            item.StreamBitrates.Push(3500)
            item.StreamQualities.Push("HD")
            item.StreamUrls.Push(validstr(curShow.hd_url.GetText()) + "&api_key=" + api_key)
        endif

        item.StreamBitrates.Push(1500)
        item.StreamQualities.Push("SD")
        item.StreamUrls.Push(validstr(curShow.high_url.GetText()))

        item.StreamBitrates.Push(700)
        item.StreamQualities.Push("SD")
        item.StreamUrls.Push(validstr(curShow.low_url.GetText()))

        showCount = showCount + 1
        feed.Push(item)

        skipitem:

    next

End Function
