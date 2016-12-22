using Requests
import Requests: get

using JSON

include("util.jl")

clientid = "da6d5e5415582a69b4dc18c5f8d58e2e"
baseapi = "http://api.soundcloud.com"

# Get Soundcloud user id given user url
function resolveuser(url::AbstractString)
  req = Requests.get(baseapi*"/resolve?", query = Dict("client_id" => clientid,"url" => url))
  res = Requests.json(req)
  userid = res["id"]
  return userid
end

# Recursively call through Soundcloud API linked partition data
function getlinkedpartition(res::Dict, collection::Array)
  nextcollection = res["collection"]
  push!(collection, nextcollection...)
  # if haskey(res, "next_href")
  if false
    println("...")
    req = Requests.get(res["next_href"])
    res = Requests.json(req)
    return getlinkedpartition(res, collection)
  else
    return collection
  end
end

# Download artwork to jpg from track object
function downloadartwork(track::Dict, size::AbstractString)
  if !isequal(track["artwork_url"], Void())
    try
      highres = replace(track["artwork_url"], "large", size)
      artwork = Requests.get(highres)
      Requests.save(artwork, "$(track["title"]).jpg")
    catch
    end
  end
end
# Recursively download each track in an array
function downloadtracks(tracks::Array)
  if !isempty(tracks)
    track = pop!(tracks)
    downloadartwork(track, "large")
    downloadtracks(tracks)
  end
end

# Return an array of track objects representing all favorites by user
function userfavorites(userid::Integer)
  # println("Getting user favourites")
  req = Requests.get(baseapi*"/users/"*string(userid)*"/favorites", query = Dict("client_id" => clientid, "linked_partitioning" => "1"))
  res = Requests.json(req)
  favorites = getlinkedpartition(res, [])
  return favorites
end

# Return an array of playlist objects representing all playlists by user
function userplaylists(userid::Integer)
  # println("Getting user playlists")
  req = Requests.get(baseapi*"/users/"*string(userid)*"/playlists", query = Dict("client_id" => clientid, "linked_partitioning" => "1"))
  res = Requests.json(req)
  playlists = getlinkedpartition(res, [])
  return playlists
end
# Given an array of playlist objects, return playlists that match some format
function sortplaylists(playlists::Array, format::Regex)
  weeklyplaylists = filter(pl -> ismatch(format, pl["title"]), playlists)
  duration = mapreduce(pl -> pl["duration"], +, 0, weeklyplaylists)
  # println("Total playlists: $(length(weeklyplaylists))")
  # println("Total number of hours: $(duration/1000/60/60)")
  return weeklyplaylists
end

# PUT IT ALL TOGETHER
function scrapefavorites(userid::Integer)
  favorites = userfavorites(userid)
  cd(() -> downloadtracks(favorites), "favorites")
end
function scrapeplaylists(userid::Integer, format::Regex=r"")
  playlists = userplaylists(userid)
  if isequal(userid, 49699208)
    # println("Downloading phamartin ($(userid)) formatted weekly playlists")
    format = r"\[[0-9]{2}\.[0-9]{2}\.[0-9]{2}\]"
  end
  weeklyplaylists = sortplaylists(playlists, format)
  cd("playlists")
  for playlist in weeklyplaylists
    title = playlist["title"]
    playlisttracks = playlist["tracks"]
    # println("Downloading $(length(playlisttracks)) artwork from $(title)")
    # cd(() -> downloadtracks(playlisttracks), "playlists")
    downloadtracks(playlisttracks)
  end
  cd("..")
end
