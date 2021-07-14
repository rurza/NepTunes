

script MusicScript
	property parent : class "NSObject"
	
	to isRunning() -- () -> NSNumber (Bool)
		-- AppleScript will automatically launch apps before sending Apple events;
		-- if that is undesirable, check the app object's `running` property first
		return running of application "Music"
	end isRunning
	
	to playPause()
		tell application "Music" to playpause
	end playPause
	
	to playerState() -- () -> NSNumber (PlayerState)
		tell application "Music"
			if running then
				set currentState to player state
				-- ASOC does not bridge AppleScript's 'type class' and 'constant' values
				set i to 1
				repeat with stateEnumRef in {stopped, playing, paused, fast forwarding, rewinding}
					if currentState is equal to contents of stateEnumRef then return i
					set i to i + 1
				end repeat
			end if
			return 0 -- 'unknown'
		end tell
	end playerState
	
	to backTrack()
		tell application "Music" to back track
	end backTrack
	
	to nextTrack()
		tell application "Music" to next track
	end nextTrack
	
	to soundVolume() -- () -> NSNumber (Int, 0...100)
		tell application "Music"
			return sound volume -- ASOC will convert returned integer to NSNumber
		end tell
	end soundVolume
	
	to setSoundVolume:newVolume -- (NSNumber) -> ()
		-- ASOC does not convert NSObject parameters to AS types automatically…
		tell application "Music"
			-- …so be sure to coerce NSNumber to native integer before using it in Apple event
			set sound volume to newVolume as integer
		end tell
	end setSoundVolume:
	
	to trackInfo()
		tell application "Music"
			if running then
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
				try
					set art to raw data of artwork 1 of artworks of current track
				on error
					set art to missing value
				end try
				return {trackDuration:dur, trackName:nam, trackArtworkData:art, trackArtist:tar, albumArtist:aar, trackAlbum:alb}
			end if
		end tell
	end trackInfo
	
	
	to trackLoved()
		tell application "Music"
			return loved of current track
		end tell
	end trackLoved
	
	
end script
