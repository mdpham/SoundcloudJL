using Requests
import Requests: get

using JSON

clientid = "da6d5e5415582a69b4dc18c5f8d58e2e"
baseapi = "http://api.soundcloud.com"

# Get scraping config from JSON file
function getconfig()
  config = Dict()
  open("config.json", "r") do f
    global config
    config = JSON.parse(readall(f))
  end
  return config
end

# Get Soundcloud user id given user url
function resolveuser(url::AbstractString)
  req = get(baseapi*"/resolve?", query = Dict("client_id" => clientid,"url" => url))
  res = Requests.json(req)
  userid = res["id"]
  return userid
end

# Recursively call through Soundcloud API linked partition data
function getlinkedpartition(res::Dict, collection::Array)
  nextcollection = res["collection"]
  push!(collection, nextcollection...)
  if haskey(res, "next_href")
    println("...")
    req = get(res["next_href"])
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
      artwork = get(highres)
      save(artwork, "$(track["title"]).jpg")
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
  println("Getting user favourites")
  req = get(baseapi*"/users/"*string(userid)*"/favorites", query = Dict("client_id" => clientid, "linked_partitioning" => "1"))
  res = Requests.json(req)
  favorites = getlinkedpartition(res, [])
  return favorites
end

# Return an array of playlist objects representing all playlists by user
function userplaylists(userid::Integer)
  println("Getting user playlists")
  req = get(baseapi*"/users/"*string(userid)*"/playlists", query = Dict("client_id" => clientid, "linked_partitioning" => "1"))
  res = Requests.json(req)
  playlists = getlinkedpartition(res, [])
  return playlists
end
# Given an array of playlist objects, return playlists that match some format
function sortplaylists(playlists::Array, format::Regex)
  weeklyplaylists = filter(pl -> ismatch(format, pl["title"]), playlists)
  duration = mapreduce(pl -> pl["duration"], +, 0, weeklyplaylists)
  println("Total playlists: $(length(weeklyplaylists))")
  println("Total number of hours: $(duration/1000/60/60)")
  return weeklyplaylists
end
# Given a playlist object, downloads all track artwork
function downloadplaylistartwork(playlist::Dict)
  title = playlist["title"]
  playlisttracks = playlist["tracks"]
  println("Downloading $(length(playlisttracks)) artwork from $(title)")
  downloadtracks(playlisttracks)
end

# PUT IT ALL TOGETHER TO SCRAPE SOUNDCLOUD
function scrapefavorites(userid::Integer)
  favorites = userfavorites(userid)
  downloadtracks(favorites)
end
function scrapeplaylists(userid::Integer, format::Regex=r"")
  playlists = userplaylists(userid)
  if isequal(userid, 49699208)
    println("Downloading phamartin ($(userid)) formatted weekly playlists")
    format = r"\[[0-9]{2}\.[0-9]{2}\.[0-9]{2}\]"
  end
  weeklyplaylists = sortplaylists(playlists, format)
  for p in weeklyplaylists
    downloadplaylistartwork(p)
  end
end
function runscrape()
  cwd = pwd()
  config = getconfig()
  userurl = config["userurl"]
  dlfavorites = config["favorites"]
  dlplaylists = config["playlists"]
  userid = resolveuser(userurl)
  println("Scraping Soundcloud userurl: $(userurl)\n Resolved userid: $(userid)")
  rm("temp", recursive=true)
  mkdir("temp")
  cd("temp")
  if dlfavorites
    mkdir("favorites")
    cd("favorites")
    scrapefavorites(userid)
    cd("..")
  end
  if dlplaylists
    mkdir("playlists")
    cd("playlists")
    scrapeplaylists(userid)
    cd("..")
  end
  cd(cwd)
end

runscrape()
