function nbsPlay(song, repeatSong)
    if not song then
        error("Song not found")
    else
        load(nbsFreqtab)()
        ticks, currenttick, tempo = load(nbsParser)(song)
 
        drone.setStatusText("Playing")
        repeat
            load(nbsPlayer)(ticks, currenttick, tempo)
           
            if repeatSong then
                drone.setStatusText("Replay")
                sleep(2)
            end
        until not repeatSong
    end
end
