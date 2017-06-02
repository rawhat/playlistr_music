defmodule PlaylistrMusic do
    def init do
        manager = PlaylistManager.init(false, false)
        newPlaylist = Playlist.init(
            "tester",
            "testing",
            "",
            true,
            "video",
            "rawhat"
        )
    end
end
