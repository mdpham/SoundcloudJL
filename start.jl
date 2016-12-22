include("scrape.jl")
include("collage.jl")

cwd = pwd()



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

if config["favorites"]
  @printf("Building favorites collage\n")
  mkdir("favorites")
  @printf("\tDownloading artwork\n")
  scrapefavorites(userid)
  favoritesimages = gettempartwork("favorites")
  @printf("\t...total downloaded: %i\n", length(favoritesimages))
  @printf("\tConcatenating images into collage\n")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, favoritesimages)
  output = Image(collage.data')
  Images.save("$(cwd)/favorites.jpg", output)
  cd("..")
end
if config["playlists"]
  @printf("Building playlists collage\n")
  mkdir("playlists")
  @printf("\tDownloading artwork\n")
  scrapeplaylists(userid)
  playlistsimages = gettempartwork("playlists")
  @printf("\t...total downloaded: %i\n", length(playlistsimages))
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, playlistsimages) # Don't need to assign to collage variable...
  output = Image(collage.data')
  Images.save("$(cwd)/playlist.jpg", output)
  cd("..")
end
