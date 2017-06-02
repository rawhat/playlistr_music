defmodule Song do
    def init(info, isVideo, url, length, streamUrl, songIndex) do
        %{ "info" => info, "isVideo" => isVideo, "url" => url, "length" => length, "streamUrl" => streamUrl, "songIndex" => songIndex }
    end
end