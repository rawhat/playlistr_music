defmodule PlaylistManager do
    def loop(state \\ %{ "playlists" => [], "driver" => false, "conn" => false}) do
        receive do
            { :addPlaylist, playlist } -> state
            { :addExistingPlaylist, playlist } -> state
            { :startPlaylist, title, song } -> state
            { :togglePausePlaylist, title } -> state
            { :getPlaylist, title } -> state
        end
    end
end