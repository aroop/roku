'**********************************************************
'**  Video Player Example Application - Video Playback
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'***********************************************************
'** Create and show the video screen.  The video screen is
'** a special full screen video playback component.  It
'** handles most of the keypresses automatically and our
'** job is primarily to make sure it has the correct data
'** at startup. We will receive event back on progress and
'** error conditions so it's important to monitor these to
'** understand what's going on, especially in the case of errors
'***********************************************************
Function showVideoScreen(episode As Object)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    if episode.isHD = true and instr(1, episode.streamurls[0], "smedia") = 0 then
        hd_url = strReplace(episode.streamurls[0], "download=1", "format=xml")
        hd_http = NewHttp(hd_url)
        hd_rsp = hd_http.GetToStringWithRetry()
        hd_xml = CreateObject("roXMLElement")
        hd_xml.Parse(hd_rsp)
        episode.streamurls[0] = validstr(hd_xml.url.GetText())
    endif

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetMessagePort(port)

    screen.Show()
    screen.SetPositionNotificationPeriod(5)

    screen.SetContent(episode)
    screen.Show()

    'Uncomment this line to dump the contents of the episode to be played
    'PrintAA(episode)

    while true
        msg = wait(0, port)

        if type(msg) = "roVideoScreenEvent" then
            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            elseif msg.isRequestFailed()
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isStatusMessage()
                print "Video status: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                RegWrite(episode.ContentId, nowpos.toStr())
            else
                print "Unexpected event type: "; msg.GetType()
            end if
        else
            print "Unexpected message class: "; type(msg)
        end if
    end while

End Function
