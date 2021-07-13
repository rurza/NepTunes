
script SpotifyScript
	property parent : class "NSObject"
	
	to isRunning() -- () -> NSNumber (Bool)
		-- AppleScript will automatically launch apps before sending Apple events;
		-- if that is undesirable, check the app object's `running` property first
		return running of application "Spotify"
	end isRunning
	
	to playPause()
		tell application "Spotify" to playpause
	end playPause
	
	to playerState() -- () -> NSNumber (PlayerState)
		tell application "Spotify"
			if running then
				set currentState to player state
				-- ASOC does not bridge AppleScript's 'type class' and 'constant' values
				set i to 1
				repeat with stateEnumRef in {stopped, playing, paused}
					if currentState is equal to contents of stateEnumRef then return i
					set i to i + 1
				end repeat
			end if
			return 0 -- 'unknown'
		end tell
	end playerState
	
	to previousTrack()
		tell application "Spotify" to previous track
	end previousTrack
	
	to nextTrack()
		tell application "Spotify" to next track
	end nextTrack
	
	to soundVolume() -- () -> NSNumber (Int, 0...100)
		tell application "Spotify"
			return sound volume -- ASOC will convert returned integer to NSNumber
		end tell
	end soundVolume
	
	to setSoundVolume:newVolume -- (NSNumber) -> ()
		-- ASOC does not convert NSObject parameters to AS types automatically…
		tell application "Spotify"
			-- …so be sure to coerce NSNumber to native integer before using it in Apple event
			set sound volume to newVolume as integer
		end tell
	end setSoundVolume:
	
	to trackInfo()
		tell application "Spotify"
			set dur to duration of current track
			set nam to name of current track
			set tar to artist of current track
			set aar to album artist of current track
			if aar is equal to "" then
				set aar to missing value
			end if
			set alb to album of current track
			if alb is equal to "" then
				set alb to missing value
			end if
            set art to artwork url of current track
			return {trackDuration:dur, trackName:nam, trackArtworkURL:art, trackArtist:tar, albumArtist:aar, trackAlbum:alb}
		end tell
	end trackInfo
	
end script
