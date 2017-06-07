defmodule PlaylistrMusic do
    use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, %{
            :conn => Bolt.Sips.conn(),
            :playlists => []
        })
    end

    # util functions
    def get_current_epoch_time do
        DateTime.utc_now() 
        |> DateTime.to_unix(:millisecond)
    end

    def convertTime(timeString) do
        IO.puts(timeString)
        segments = timeString
            |> String.split(":")
            |> Enum.map(fn elem -> String.to_integer(elem) end)

        case length(segments) do
            1 ->
                hd segments
            2 ->
                segments[0] * 60 + segments[1]
            3 ->
                segments[0] * 3600 + segments[1] * 60 + segments[2]
            _ ->
                0
        end
    end

    def get_best_quality(formats, isVideo) do
        case isVideo do
            true ->
                formats
                    |> Enum.filter(fn format -> 
                        Map.has_key?(format, "vcodec") && format["vcodec"] != "none" && Map.has_key?(format, "resolution")
                    end)
                    |> Enum.sort(fn(video1, video2) ->
                        (video1["width"] * video1["height"]) > (video2["width"] * video2["height"])
                    end)
            false ->
                formats
                    |> Enum.filter(fn format ->
                        Enum.member?(["opus", "mp3", "vorbis"], String.trim(format["acodec"]))
                    end)
                    |> Enum.sort(fn(audio1, audio2) ->
                        audio1["abr"] > audio2["abr"]
                    end)
        end
            |> hd
            |> Map.get("url")
    end

    def parse_video(pid, url) do
        case System.cmd("youtube-dl", ["-j", url]) do
            ({ data, res }) ->
                info = Poison.Parser.parse!(data)

                {:ok, %{
                    "title" => info["fulltitle"],
                    "url" => url,
                    "length" => info["duration"] |> Integer.to_string |> convertTime,
                    "streamUrl" => info["formats"] |> get_best_quality(true)
                }}

            _ ->
                { :err, "Error in processing" }
        end
    end

    def parse_audio(pid, url) do
        case System.cmd("youtube-dl", ["-j", url]) do
            ({ data, res }) ->
                info = Poison.Parser.parse!(data)

                {:ok, %{
                    "title" => info["fulltitle"],
                    "url" => url,
                    "length" => info["duration"] |> Integer.to_string |> convertTime,
                    "streamUrl" => info["formats"] |> get_best_quality(false)
                }}
            _ ->
                { :err, "Error in processing" }
        end
    end

    # Calls
    def add_playlist(pid, title, category, password, open_submissions, type, creator) do
        playlist = Playlist.init(title, category, password, open_submissions, type, creator)
        GenServer.call(pid, {:add_playlist, playlist, creator})
    end

    def add_song(pid, title, info, isVideo, url, length, streamUrl) do
        song = Song.init(info, isVideo, url, length, streamUrl)
        GenServer.call(pid, {:add_song, song, title})
    end

    def get_songs(pid, title) do
        GenServer.call(pid, {:get_songs, title})
    end

    def get_current_playtime(pid, title) do
        GenServer.call(pid, {:get_current_playtime, title})
    end

    def get_current_song_and_playtime(pid, title) do
        GenServer.call(pid, {:get_current_song_and_playtime, title})
    end

    def get_next_song(pid, title) do
        GenServer.call(pid, {:get_next_song, title})
    end

    def start_playlist(pid, title) do
        GenServer.call(pid, {:start_playlist, title})
    end

    # Call handlers
    def handle_call({:add_playlist, playlist, creator}, _from, state) do
        response = case Bolt.Sips.query(
            state.conn,
            """
                MATCH (u:User) WHERE u.username = "#{creator}"
				CREATE (u)-[:CREATED { createdAt: "#{get_current_epoch_time()}" }]->(p:Playlist {
					title: "#{playlist.title}",
					category: "#{playlist.category}",
					password: "#{playlist.password}",
					openSubmissions: "#{playlist.open_submissions}",
					type: "#{playlist.type}",
					length: "#{playlist.length}",
					isPaused: "#{playlist.is_paused}",
					startDate: "#{playlist.start_date}",
					currentTime: "#{playlist.current_time}",
					hasPlayed: "#{playlist.has_played}"
				}) RETURN p AS playlist
            """
        ) do
            {:ok, _} ->
                :ok
            {:err, _} ->
                :err
        end

        {:reply, response, state}
    end

    def handle_call({:add_song, song, title}, _from, state) do
        case Bolt.Sips.query(
                state.conn, 
                "MATCH (p:Playlist)-[:HAS]-(s:Song) WHERE p.title = '#{title}' RETURN s"
            ) do
                {:ok, results} -> 
                    index = length(results)

                    case Bolt.Sips.query(
                        state.conn,
                        """
                            MATCH (p:Playlist) WHERE p.title = '#{title}'
                            CREATE UNIQUE (p)-[:HAS { addedAt: '#{get_current_epoch_time()}"}' }]->(s:Song {
                                info: '#{Map.get(song, "info")}',
                                isVideo: '#{Map.get(song, "isVideo")}',
                                url: '#{Map.get(song, "url")}',
                                length: '#{Map.get(song, "length")}',
                                streamUrl: '#{Map.get(song, "streamUrl")}',
                                index: '#{index}'
                            })
                            RETURN p as playlist, s AS song
                        """
                    ) do
                        {:ok, _ } ->
                            { :reply, :ok, state }
                        {:err, _ } ->
                            { :reply, :err, state }
                    end
                _ ->
                    { :reply, :err, state }
            end
    end

    def handle_call({:get_songs, title}, _from, state) do
        songs = case Bolt.Sips.query(
                state.conn, 
                "MATCH (p:Playlist)-[:HAS]-(s:Song) WHERE p.title = '#{title}' RETURN s"
            ) do
                {:ok, results} -> 
                    results |> Enum.map(&(&1["s"].properties))
            
                _ -> []
            end

        { :reply, songs, state }
    end

    def handle_call({:get_current_playtime, title}, _from, state) do
        case Bolt.Sips.query(
            state.conn,
            """
                MATCH (p:Playlist) WHERE p.title = '#{title}'
                RETURN p
            """
        ) do
            {:ok, results} ->
                playlist = (hd results)["p"].properties

                time = playlist |> Map.get("currentTime", 0)
                startDate = playlist 
                    |> Map.get("startDate", get_current_epoch_time() |> Integer.to_string)
                    |> String.to_integer

                {:reply, time + (get_current_epoch_time() - startDate) / 1000, state}

            {:err, _} ->
                {:reply, :err, state}
        end
    end

    def handle_call({:start_playlist, title}, _from, state) do
        case Bolt.Sips.query(
            state.conn,
            """
                MATCH (p:Playlist) WHERE p.title = '#{title}'
                SET p.startDate = '#{get_current_epoch_time()}'
                RETURN p
            """
        ) do
            {:ok, _} ->
                {:reply, :ok, state}
                
            {:err, _} ->
                {:reply, :err, state}
        end
    end
end
