defmodule Playlist do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, :ok, [])
    end

    def init(:ok) do
        {:ok, %{ 
            :title => "", 
            :category => "", 
            :password => "", 
            :openSubmissions => true, 
            :type => "", 
            :creator => "",
            :length => 0,
            :isPaused => true,
            :startDate => 0,
            :currentTime => 0,
            :songs => [],
            :hasPlayed => false,
            :driver => nil,
            :conn => nil,
            :playbackTimer => nil
        }}
    end

    def handle_call({ :getSongs }, _from, playlist) do
        {:reply, playlist.songs, playlist}
    end

    def getSongs(pid) do
        GenServer.call(pid, { :getSongs })
    end

end


    # def loop(state) do
    #         { :getCurrentPlaytime } -> state
    #         { :addSong } -> state
    #         { :removeSong } -> state
    #         { :getSongs } -> state
    #         { :getCurrentSongAndTime } -> state
    #         { :getNextSong } -> state
    #         { :updateLength } -> state
    #         { :playSong, song } -> state
    #         { :playSongs } -> state
    #     end