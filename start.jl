include("scrape.jl")
include("collage.jl")

cwd = pwd()
config = getconfig()
xdim = config["xdim"]
ydim = config["ydim"]
imgwidth = 100
userurl = config["userurl"]
userid = resolveuser(userurl)

@printf("Building Soundcloud artwork collage:\n")
@printf("\t%s\n...Resolved userid: %i\n", userurl, userid)
@printf("\t%i wide %i tall collage with tile size %s\n", xdim, ydim, imgwidth)

try
  mkdir("temp")
catch
  rm("temp", recursive=true)
  mkdir("temp")
end
cd("temp")

if config["favorites"]
  mkdir("favorites")
  cd(() -> scrapefavorites(userid), "favorites")
  favoritesimages = gettempartwork("favorites")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, favoritesimages)
  output = Image(collage.data')
  Images.save("$(cwd)/favorites.jpg", output)
  cd("..")
end
if config["playlists"]
  mkdir("playlists")
  cd(() -> scrapeplaylists(userid), "playlists")
  playlistsimages = gettempartwork("playlists")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, playlistsimages) # Don't need to assign to collage variable...
  output = Image(collage.data')
  Images.save("$(cwd)/playlist.jpg", output)
  cd("..")
end
