include("scrape.jl")
include("collage.jl")

cwd = pwd()

function setup()
  config = getconfig()
  xdim = config["xdim"]
  ydim = config["ydim"]
  imgwidth = 100
  userurl = config["userurl"]

  @printf("Starting Soundcloud artwork collage:\n")
  @printf("\t%s\n", userurl)

  userid = resolveuser(userurl)

  @printf("\t...resolved userid: %i\n", userid)
  @printf("\t%i wide %i tall collage with tile size %s\n", xdim, ydim, imgwidth)

  try
    mkdir("temp")
  catch
    rm("temp", recursive=true)
    mkdir("temp")
  end
  cd("temp")
end

setup()

function buildfavoritescollage()
  @printf("Building favorites collage\n")
  mkdir("favorites")
  scrapefavorites(userid)
  favoritesimages = gettempartwork("favorites")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, favoritesimages)
  output = Image(collage.data')
  Images.save("$(cwd)/favorites.jpg", output)
  @printf("\tDone\n")
end

function buildplaylistscollage()
  @printf("Building playlists collage\n")
  mkdir("playlists")
  scrapeplaylists(userid)
  playlistsimages = gettempartwork("playlists")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, playlistsimages) # Don't need to assign to collage variable...
  output = Image(collage.data')
  Images.save("$(cwd)/playlist.jpg", output)
  @printf("\tDone\n")
end

if config["favorites"]
  buildfavoritescollage()
end
if config["playlists"]
  buildplaylistscollage(
end
