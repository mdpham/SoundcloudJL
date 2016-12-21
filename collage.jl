using Images, Colors, FixedPointNumbers
type Collage
  xdim
  ydim
  tilewidth
  data
end

# Initialize a Collage type to be filled
function init_collage(xdim,ydim,tilewidth)
  canvas = Array(RGB{U8}, ydim*tilewidth, xdim*tilewidth)
  return Collage(xdim,ydim,tilewidth,canvas)
end
# Fill a Collage with an image at y,x coordinate
function fill_tile(collage::Collage, y, x, tile::Array)
  xstart = (x-1)*collage.tilewidth + 1
  xend = x*collage.tilewidth
  ystart = (y-1)*collage.tilewidth + 1
  yend = y*collage.tilewidth
  collage.data[ystart:yend, xstart:xend] = tile'
  return collage
end
# Given an array of images (should be Collage.tilewidth length), fills an empty Collage
# Number of images in array should be more than Collage.xdim*Collage.ydim
# If not, repeats tiles (idea: fill with colors once Hilbert path figured out)
function fill_collage(collage::Collage, tiles::Array)
  while collage.xdim*collage.ydim < length(tiles)
    tiles = tiles[1:(collage.xdim*collage.ydim)]
  end
  while length(tiles) < collage.xdim*collage.ydim
    push!(tiles, rand(tiles))
  end
  for idx in 1:length(tiles)
    # Snake pattern through tiles top left to bottom right
    i = rem(idx-1, collage.ydim)+1
    j = div(idx-1, collage.ydim)+1
    collage = fill_tile(collage, i, j, tiles[idx])
  end
  return collage
end

# Takes an image and returns the RGB colorspace coordinate that corresponds
# to the color with the highest count in the image (for most images..black)
# Also returns red, blue, green histograms
function rgbbin(image::Array) # Sort pixels of an image into 256x256x256 RGB space histogram
  rgbbins = zeros(256,256,256)
  for px in image
    r = convert(Integer, floor(255red(px))+1)
    g = convert(Integer, floor(255green(px))+1)
    b = convert(Integer, floor(255blue(px))+1)
    rgbbins[r,g,b] += 1
  end
  return rgbbins
end
function rgbchannels(rgbbin::Array) # Returns 3x256 matrix, each entry is
  rchannel = collect(sum(sum(rgbbin,2),3))
  gchannel = collect(sum(sum(rgbbin,1),3))
  bchannel = collect(sum(sum(rgbbin,1),2))
  return [rchannel'; gchannel'; bchannel']
end
function rgbmaxcoord(rgbbin::Array) # Returns RGB index of color with most pixels
  maxcandidate = 0
  iposn = 0; jposn = 0; kposn = 0
  for i in 1:256
    for j in 1:256
      for k in 1:256
        if maxcandidate < rgbbin[i,j,k]
          iposn = i; jposn = j; kposn = k
        end
      end
    end
  end
  return [iposn jposn kposn]
end
function histogram(image::Array)
  bins = rgbbin(image)
  rgbch = rgbchannels(bins)
  rgbcoord = rgbmaxcoord(bins)
end


# Get artwork to make into collage
function sortartwork() # Return array of artwork data
  images = []
  currdir = pwd()
  cd("temp")
  for playlist in readdir()
    println("Adding playlist $(playlist)")
    cd("$(playlist)")
    for fl in readdir()
      try
        img = data(convert(Image{RGB}, load(fl)))
        # histogram(img)
        push!(images, img)
      catch
      end
    end
    cd("..")
  end
  cd(currdir)
  return images
end

function gettempartwork(dir::AbstractString)
  images = []
  cwd = pwd()
  cd(dir)
  for fl in readdir()
    try
      img = data(convert(Image{RGB}, load(fl)))
      push!(images, img)
    catch
    end
  end
  cd(cwd)
  shuffle!(images)
  return images
end

function runcollage(xdim::Integer, ydim::Integer, imgwidth::Integer)
  # playlistsimages = gettempartwork("temp/playlists")
  # collage = init_collage(xdim, ydim, imgwidth)
  # fill_collage(collage, playlistsimages) # Don't need to assign to collage variable...
  # output = Image(collage.data')
  # save("playlist.jpg", output)

  favoritesimages = gettempartwork("temp/favorites")
  collage = init_collage(xdim, ydim, imgwidth)
  fill_collage(collage, favoritesimages)
  output = Image(collage.data')
  save("favorites.jpg", output)
end

runcollage(8, 8, 100)
